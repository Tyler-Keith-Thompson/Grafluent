# Centrality: case catalog (CE-001 – CE-206, 162 cases)

Cases for the Centrality module (api.md): degree, in- and out-degree, closeness, harmonic and
betweenness centrality, eigenvector and Katz centrality, PageRank and HITS, on `Graph` and
`DirectedGraph`, unweighted and weighted. Harvested from NetworkX 3.7 (`test_degree_centrality`,
`test_closeness_centrality`, `test_harmonic_centrality`, `test_betweenness_centrality`,
`test_eigenvector_centrality`, `test_katz_centrality`, `test_pagerank`, `test_hits` and their
docstrings), python-igraph 1.0 (`probe.py`, `probe2.py` here), Brandes 2001 / 2008 and the edge
cases api.md calls out. Every Expected cell is recomputed by `ref.py`, which also checks it
against the definition (Floyd–Warshall distances; betweenness as Σ σ_sv·σ_vt/σ_st over edge
sequences), dense numpy / scipy linear algebra for the iterative measures, and NetworkX 3.7
wherever NetworkX shares the semantics (see its docstring). `uv run --quiet --no-project --with
networkx==3.7 --with scipy==1.18.1 python3 ref.py` prints "all values agree".

## Notation

**Graph** (as in the Distances catalog; read by `ref.py`): `U:` undirected, `D:` directed. An
optional vertex list in brackets comes first, then edges in **position order**. `vertices` is the
listed vertices, then vertices from generators, then endpoints by first appearance. Rows are in
position order, an undirected self-loop twice.

| Token | Edges |
|---|---|
| `u-v`, `u>v` | one edge, or one arc (in a `D:` graph `-` also writes an arc) |
| `P(a,b,…)`, `C(a,b,…,z)` | the path a–b, b–c, …; the cycle a–b, …, z–a (arcs in a `D:` graph) |
| `S(c;a..b)` | the star c–a, …, c–b |
| `K(n)`, `K(a..b)` | every pair i < j, lexicographic |
| `KB(a..b;c..d)` | each of the first list to each of the second, row-major |
| `nx(name)` | `networkx.<name>_graph()`: its `nodes` listed, then `edges()` in NetworkX's order (attributes dropped: karate's `weight` is not used) |
| `a..b` | every integer from a to b inclusive |

**Op**: the API call with its arguments; omitted arguments take api.md's defaults. `weight: [w0, …]`
is `{ w[$0] }` by edge position (`weight: e%k+c`: edge e weighs e mod k + c); `personalization:
[p0, …]` is `{ p[vertexIndex($0)] }`. `directed > op` runs op on `graph.directed` (each edge two
arcs, a self-loop two loop arcs). `hits.hubs` / `hits.authorities` read the two members of
`hits()`'s result; `of: v` is the one-vertex form, returning a scalar.

**Expected**: per-vertex scores in `vertices` order, printed to 12 significant digits
(`score(ofIndex: i)` for each i); `#x` a scalar; `nil` (an iterative method did not converge
within `maxIterations`); `trap` a precondition failure.

**Tol**: how far the Swift result may lie from Expected, per score, relative to max(1, |Expected|).
`exact` means 1e-12: non-iterative values are a fixed sequence of floating-point operations, and
the tests compare to that bound rather than bit for bit, because Expected is rounded to 12 digits.
For the iterative measures Expected is the **limit** of the iteration (the model run to tolerance
1e-15, cross-checked by a dense solve), and Tol bounds the distance of the result computed with the
row's parameters from that limit; `ref.py` checks that the model with those parameters, and
NetworkX where it applies, land within Tol.

## A. Degenerate graphs

| ID | Graph | Op | Expected | Tol | Notes |
|---|---|---|---|---|---|
| CE-001 | `U: []` | `degreeCentrality` | `[]` | exact | Empty graph: every measure gives an empty result |
| CE-002 | `U: []` | `closenessCentrality` | `[]` | exact | |
| CE-003 | `U: []` | `harmonicCentrality` | `[]` | exact | |
| CE-004 | `U: []` | `betweennessCentrality` | `[]` | exact | |
| CE-005 | `U: []` | `eigenvectorCentrality` | `[]` | 1e-4 | Not nil: there is nothing to iterate. NetworkX raises `NetworkXPointlessConcept` |
| CE-006 | `U: []` | `katzCentrality` | `[]` | 1e-4 | NetworkX `{}` |
| CE-007 | `U: []` | `pageRank` | `[]` | 1e-4 | NetworkX `{}` |
| CE-008 | `D: []` | `hits.hubs` | `[]` | 1e-4 | NetworkX `({}, {})` |
| CE-009 | `U: [0]` | `degreeCentrality` | `[1]` | exact | NetworkX's rule: one vertex scores 1 (no n − 1 to divide by) |
| CE-010 | `U: [0]` | `closenessCentrality` | `[0]` | exact | |
| CE-011 | `U: [0]` | `harmonicCentrality` | `[0]` | exact | |
| CE-012 | `U: [0]` | `betweennessCentrality` | `[0]` | exact | |
| CE-013 | `U: [0]` | `betweennessCentrality(endpoints: true)` | `[0]` | exact | No pair, so no endpoint credit; scale skipped for n < 2 |
| CE-014 | `U: [0]` | `eigenvectorCentrality` | `[1]` | 1e-4 | |
| CE-015 | `U: [0]` | `katzCentrality` | `[1]` | 1e-4 | |
| CE-016 | `U: [0]` | `pageRank` | `[1]` | 1e-4 | |
| CE-017 | `D: [0]` | `hits.hubs` | `[1]` | 1e-4 | No edge: uniform by rule (api.md) |
| CE-018 | `U: [0..2]` | `degreeCentrality` | `[0, 0, 0]` | exact | Edgeless |
| CE-019 | `U: [0..2]` | `eigenvectorCentrality` | `[0.57735026919, 0.57735026919, 0.57735026919]` | 1e-4 | (A + I)x = x: uniform, converged on the first iteration |
| CE-020 | `U: [0..2]` | `katzCentrality` | `[0.57735026919, 0.57735026919, 0.57735026919]` | 1e-4 | |
| CE-021 | `U: [0..2]` | `katzCentrality(normalized: false)` | `[1, 1, 1]` | 1e-4 | β everywhere |
| CE-022 | `U: [0..2]` | `pageRank` | `[0.333333333333, 0.333333333333, 0.333333333333]` | 1e-4 | Every vertex dangling |
| CE-023 | `D: [0..2]` | `hits.authorities` | `[0.333333333333, 0.333333333333, 0.333333333333]` | 1e-4 | NetworkX's svds gives NaN here; igraph all-equal. Ours uniform |
| CE-024 | `U: 0-1` | `degreeCentrality` | `[1, 1]` | exact | |
| CE-025 | `U: 0-1` | `betweennessCentrality` | `[0, 0]` | exact | n ≤ 2: scale skipped (NetworkX) |
| CE-026 | `U: 0-1` | `betweennessCentrality(endpoints: true)` | `[1, 1]` | exact | Each ordered pair credits both ends, scaled by 1/(n(n − 1)) |
| CE-027 | `U: 0-1` | `closenessCentrality` | `[1, 1]` | exact | |

## B. Degree

| ID | Graph | Op | Expected | Tol | Notes |
|---|---|---|---|---|---|
| CE-030 | `U: S(0;1..4)` | `degreeCentrality` | `[1, 0.25, 0.25, 0.25, 0.25]` | exact | |
| CE-031 | `U: P(0,1,2), 1-1` | `degreeCentrality` | `[0.5, 2, 0.5]` | exact | A self-loop counts 2, as `degree(of:)`; the score can exceed 1 (NetworkX agrees) |
| CE-032 | `U: 0-1, 0-1, 1-2` | `degreeCentrality` | `[1, 1.5, 0.5]` | exact | Parallel copies each count (NetworkX MultiGraph agrees) |
| CE-033 | `D: P(0,1,2)` | `degreeCentrality` | `[0.5, 1, 0.5]` | exact | Directed: in + out |
| CE-034 | `D: P(0,1,2)` | `inDegreeCentrality` | `[0, 0.5, 0.5]` | exact | |
| CE-035 | `D: P(0,1,2)` | `outDegreeCentrality` | `[0.5, 0.5, 0]` | exact | |
| CE-036 | `D: 0>0, 0>1` | `inDegreeCentrality` | `[1, 1]` | exact | A directed loop is one in-arc and one out-arc |
| CE-037 | `D: 0>0, 0>1` | `outDegreeCentrality` | `[2, 0]` | exact | |
| CE-038 | `D: [0..3] C(0,1,2)` | `degreeCentrality` | `[0.666666666667, 0.666666666667, 0.666666666667, 0]` | exact | Isolated vertex |
| CE-039 | `U: nx(karate_club)` | `degreeCentrality` | `[0.484848484848, 0.272727272727, 0.30303030303, 0.181818181818, 0.0909090909091, 0.121212121212, 0.121212121212, 0.121212121212, 0.151515151515, 0.0606060606061, 0.0909090909091, 0.030303030303, 0.0606060606061, 0.151515151515, 0.0606060606061, 0.0606060606061, 0.0606060606061, 0.0606060606061, 0.0606060606061, 0.0909090909091, 0.0606060606061, 0.0606060606061, 0.0606060606061, 0.151515151515, 0.0909090909091, 0.0909090909091, 0.0606060606061, 0.121212121212, 0.0909090909091, 0.121212121212, 0.121212121212, 0.181818181818, 0.363636363636, 0.515151515152]` | exact | |
| CE-040 | `U: P(0,1,2)` | `directed > degreeCentrality` | `[1, 2, 1]` | exact | Twice the undirected degree centrality ([0.5, 1, 0.5]): in + out over two arcs per edge |
| CE-041 | `D: [0]` | `inDegreeCentrality` | `[1]` | exact | One vertex: 1 (NetworkX) |

## C. Closeness and harmonic

| ID | Graph | Op | Expected | Tol | Notes |
|---|---|---|---|---|---|
| CE-050 | `U: P(0..4)` | `closenessCentrality` | `[0.4, 0.571428571429, 0.666666666667, 0.571428571429, 0.4]` | exact | (n − 1)/Σd |
| CE-051 | `U: P(0,1,2), 3-4` | `closenessCentrality` | `[0.333333333333, 0.5, 0.333333333333, 0.25, 0.25]` | exact | Wasserman–Faust (default): (r − 1)/Σd · (r − 1)/(n − 1), r = vertices reached, itself included |
| CE-052 | `U: P(0,1,2), 3-4` | `closenessCentrality(wfImproved: false)` | `[0.666666666667, 1, 0.666666666667, 1, 1]` | exact | Per component: K₂ scores 1, as P₃'s middle. igraph's default (`normalized=True`) |
| CE-053 | `U: [0..3] P(0,1,2)` | `closenessCentrality` | `[0.444444444444, 0.666666666667, 0.444444444444, 0]` | exact | Isolated vertex: Σd = 0 gives 0 |
| CE-054 | `D: P(0,1,2)` | `closenessCentrality` | `[0, 0.5, 0.666666666667]` | exact | Incoming distances d(v, u) (NetworkX): the source scores 0. igraph's default mode is "all" ([⅔, 1, ⅔]); JGraphT's default outgoing |
| CE-055 | `D: P(0,1,2)` | `closenessCentrality(wfImproved: false)` | `[0, 1, 0.666666666667]` | exact | |
| CE-056 | `D: S(0;1..3)` | `closenessCentrality` | `[0, 0.333333333333, 0.333333333333, 0.333333333333]` | exact | Arcs out of the hub: the leaves are reached, the hub is not |
| CE-057 | `U: nx(krackhardt_kite)` | `closenessCentrality` | `[0.529411764706, 0.529411764706, 0.5, 0.6, 0.5, 0.642857142857, 0.642857142857, 0.6, 0.428571428571, 0.310344827586]` | exact | Krackhardt 1990's kite, the standard closeness/betweenness contrast |
| CE-058 | `U: nx(florentine_families)` | `closenessCentrality` | `[0.368421052632, 0.56, 0.388888888889, 0.368421052632, 0.4375, 0.4375, 0.5, 0.48275862069, 0.48275862069, 0.388888888889, 0.285714285714, 0.4, 0.466666666667, 0.333333333333, 0.325581395349]` | exact | NetworkX test values |
| CE-059 | `U: nx(karate_club)` | `closenessCentrality` | `[0.568965517241, 0.485294117647, 0.559322033898, 0.464788732394, 0.379310344828, 0.383720930233, 0.383720930233, 0.44, 0.515625, 0.434210526316, 0.379310344828, 0.366666666667, 0.370786516854, 0.515625, 0.370786516854, 0.370786516854, 0.284482758621, 0.375, 0.370786516854, 0.5, 0.370786516854, 0.375, 0.370786516854, 0.392857142857, 0.375, 0.375, 0.362637362637, 0.458333333333, 0.452054794521, 0.383720930233, 0.458333333333, 0.540983606557, 0.515625, 0.55]` | exact | |
| CE-060 | `U: P(0,1,2,3)` | `closenessCentrality(weight: [1, 2, 3])` | `[0.3, 0.375, 0.375, 0.214285714286]` | exact | Integer weights, sums converted to `Double` after the search |
| CE-061 | `U: C(0,1,2,3)` | `closenessCentrality(weight: [1.5, 0.5, 2.0, 1.0])` | `[0.666666666667, 0.666666666667, 0.666666666667, 0.545454545455]` | exact | |
| CE-062 | `U: P(0,1,2)` | `closenessCentrality(weight: [0, 1])` | `[2, 2, 1]` | exact | Zero weights allowed: d(0, 1) = 0 adds nothing to Σd; vertex 0 scores 2 |
| CE-063 | `U: P(0,1,2)` | `closenessCentrality(weight: [-1, 1])` | `trap` | exact | Precondition: weight ≥ 0 and not NaN |
| CE-064 | `U: P(0,1,2)` | `closenessCentrality(weight: [1.0, nan])` | `trap` | exact | |
| CE-065 | `U: P(0..4)` | `closenessCentrality(of: 2)` | `#0.666666666667` | exact | One search; equals CE-050's entry |
| CE-066 | `D: P(0,1,2)` | `closenessCentrality(of: 0)` | `#0` | exact | Nothing reaches the source |
| CE-067 | `U: 0-1, 0-1, 1-1, 1-2` | `closenessCentrality` | `[0.666666666667, 1, 0.666666666667]` | exact | Loops and parallel copies change no distance: as P₃ |
| CE-068 | `U: P(0,1,2)` | `directed > closenessCentrality` | `[0.666666666667, 1, 0.666666666667]` | exact | Same as undirected |
| CE-070 | `U: P(0..4)` | `harmonicCentrality` | `[2.08333333333, 2.83333333333, 3, 2.83333333333, 2.08333333333]` | exact | Σ 1/d, not normalized (NetworkX; igraph divides by n − 1 by default) |
| CE-071 | `U: P(0,1,2), 3-4` | `harmonicCentrality` | `[1.5, 2, 1.5, 1, 1]` | exact | Unreachable vertices contribute 0: no Wasserman–Faust needed |
| CE-072 | `D: P(0,1,2)` | `harmonicCentrality` | `[0, 1, 1.5]` | exact | Incoming, as closeness (NetworkX) |
| CE-073 | `D: C(0,1,2), 2>3` | `harmonicCentrality` | `[1.5, 1.5, 1.5, 1.83333333333]` | exact | |
| CE-074 | `U: nx(karate_club)` | `harmonicCentrality` | `[23.1666666667, 19.1666666667, 21, 17.6666666667, 14.6666666667, 15.1666666667, 15.1666666667, 16.4166666667, 18.5, 15.5833333333, 14.6666666667, 13.5, 14, 18.5, 14.2, 14.2, 11.1, 14.1666666667, 14.2, 17.5, 14.2, 14.1666666667, 14.2, 16.0333333333, 13.9166666667, 13.9166666667, 13.95, 16.9166666667, 16.4166666667, 15.3666666667, 16.9166666667, 19.3333333333, 20.9166666667, 23.25]` | exact | |
| CE-075 | `U: nx(florentine_families)` | `harmonicCentrality` | `[5.91666666667, 9.5, 6.91666666667, 6.78333333333, 7.83333333333, 7.08333333333, 8, 7.83333333333, 7.83333333333, 6.58333333333, 4.76666666667, 7.2, 8.08333333333, 5.33333333333, 5.36666666667]` | exact | |
| CE-076 | `U: P(0,1,2)` | `harmonicCentrality(weight: [0, 1])` | `[1, 1, 2]` | exact | A zero distance to another vertex is skipped (NetworkX), not 1/0 |
| CE-077 | `U: C(0,1,2,3)` | `harmonicCentrality(weight: [1.5, 0.5, 2.0, 1.0])` | `[2.16666666667, 3.06666666667, 3, 1.9]` | exact | |
| CE-078 | `U: P(0..4)` | `harmonicCentrality(of: 0)` | `#2.08333333333` | exact | |
| CE-079 | `D: C(0,1,2), 2>3` | `harmonicCentrality(of: 3)` | `#1.83333333333` | exact | |
| CE-080 | `U: P(0,1,2)` | `harmonicCentrality(weight: [1, -2])` | `trap` | exact | |

## D. Betweenness

| ID | Graph | Op | Expected | Tol | Notes |
|---|---|---|---|---|---|
| CE-090 | `U: P(0..4)` | `betweennessCentrality` | `[0, 0.5, 0.666666666667, 0.5, 0]` | exact | Normalized (default): ÷ (n − 1)(n − 2)/2 pairs |
| CE-091 | `U: P(0..4)` | `betweennessCentrality(normalized: false)` | `[0, 3, 4, 3, 0]` | exact | Unordered pairs (NetworkX halves) |
| CE-092 | `U: P(0..4)` | `betweennessCentrality(endpoints: true)` | `[0.4, 0.7, 0.8, 0.7, 0.4]` | exact | |
| CE-093 | `U: P(0..4)` | `betweennessCentrality(normalized: false, endpoints: true)` | `[4, 7, 8, 7, 4]` | exact | |
| CE-094 | `U: S(0;1..4)` | `betweennessCentrality` | `[1, 0, 0, 0, 0]` | exact | The hub: 1 |
| CE-095 | `U: C(0..4)` | `betweennessCentrality(normalized: false)` | `[1, 1, 1, 1, 1]` | exact | |
| CE-096 | `U: C(0,1,2,3)` | `betweennessCentrality(normalized: false)` | `[0.5, 0.5, 0.5, 0.5]` | exact | Each opposite pair has two shortest paths: ½ each |
| CE-097 | `U: nx(krackhardt_kite)` | `betweennessCentrality` | `[0.0231481481481, 0.0231481481481, 0, 0.101851851852, 0, 0.231481481481, 0.231481481481, 0.388888888889, 0.222222222222, 0]` | exact | NetworkX test values |
| CE-098 | `U: nx(florentine_families)` | `betweennessCentrality` | `[0, 0.521978021978, 0.0549450549451, 0.021978021978, 0.102564102564, 0.0934065934066, 0.113553113553, 0.0915750915751, 0.212454212454, 0.142857142857, 0, 0.104395604396, 0.254578754579, 0, 0]` | exact | NetworkX test values |
| CE-099 | `U: nx(karate_club)` | `betweennessCentrality` | `[0.437635281385, 0.0539366883117, 0.143656806157, 0.0119092712843, 0.000631313131313, 0.0299873737374, 0.0299873737374, 0, 0.0559268278018, 0.000847763347763, 0.000631313131313, 0, 0, 0.0458633958634, 0, 0, 0, 0, 0, 0.0324750481, 0, 0, 0, 0.0176136363636, 0.0022095959596, 0.00384048821549, 0, 0.0223334535835, 0.00179473304473, 0.00292207792208, 0.014411976912, 0.138275613276, 0.145247113997, 0.30407497595]` | exact | |
| CE-100 | `U: nx(petersen)` | `betweennessCentrality` | `[0.0833333333333, 0.0833333333333, 0.0833333333333, 0.0833333333333, 0.0833333333333, 0.0833333333333, 0.0833333333333, 0.0833333333333, 0.0833333333333, 0.0833333333333]` | exact | Vertex-transitive: all equal |
| CE-101 | `U: P(0,1,2), 3-4` | `betweennessCentrality` | `[0, 0.166666666667, 0, 0, 0]` | exact | Unreachable pairs contribute nothing; n is the whole graph's |
| CE-102 | `D: P(0,1,2)` | `betweennessCentrality` | `[0, 0.5, 0]` | exact | Directed normalized: ÷ (n − 1)(n − 2) ordered pairs |
| CE-103 | `D: P(0,1,2)` | `betweennessCentrality(normalized: false)` | `[0, 1, 0]` | exact | Ordered pairs, not halved |
| CE-104 | `D: C(0,1,2,3)` | `betweennessCentrality(normalized: false)` | `[3, 3, 3, 3]` | exact | |
| CE-105 | `D: S(0;1..3), 1>0` | `betweennessCentrality(normalized: false)` | `[2, 0, 0, 0]` | exact | |
| CE-106 | `U: P(0,1,2)` | `directed > betweennessCentrality` | `[0, 1, 0]` | exact | Normalized values agree with undirected |
| CE-107 | `U: P(0,1,2)` | `directed > betweennessCentrality(normalized: false)` | `[0, 2, 0]` | exact | Unnormalized: twice the undirected value (ordered pairs, not halved) |
| CE-108 | `U: 0-1, 0-1, 1-2, 0-3, 3-2` | `betweennessCentrality(normalized: false)` | `[0.666666666667, 0.666666666667, 0.333333333333, 0.333333333333]` | exact | Parallel edges are distinct shortest paths (edge sequences): 0 → 2 has three, two through 1. igraph agrees ([⅔, ⅔, ⅓, ⅓]); NetworkX counts neighbours once ([½, ½, ½, ½]) |
| CE-109 | `U: P(0,1,2), 1-1` | `betweennessCentrality` | `[0, 1, 0]` | exact | A self-loop is on no shortest path |
| CE-110 | `U: K(5)` | `betweennessCentrality` | `[0, 0, 0, 0, 0]` | exact | |
| CE-111 | `U: KB(0..1;2..4)` | `betweennessCentrality` | `[0.25, 0.0555555555556, 0.0555555555556, 0.0555555555556, 0.25]` | exact | |
| CE-112 | `U: P(0,1,2,3)` | `betweennessCentrality(weight: [1, 2, 3])` | `[0, 0.666666666667, 0.666666666667, 0]` | exact | |
| CE-113 | `U: C(0,1,2,3)` | `betweennessCentrality(normalized: false, weight: [1, 1, 1, 3])` | `[0, 1.5, 1.5, 0]` | exact | 0 → 3 ties at 3: direct, and through 1, 2 |
| CE-114 | `U: 0-1, 1-2, 0-3, 3-2` | `betweennessCentrality(normalized: false, weight: [0.1, 0.2, 0.15, 0.15])` | `[1, 0, 0, 1]` | exact | Exact equality of sums (NetworkX, Boost): 0.1 + 0.2 = 0.30000000000000004 > 0.15 + 0.15, so 0 → 2 has one shortest path. igraph compares with a relative epsilon and splits it ([1, ½, 0, ½]) |
| CE-115 | `U: P(0,1,2)` | `betweennessCentrality(weight: [0, 1])` | `trap` | exact | Precondition: weight > 0 (igraph: "Edge weights must be positive for betweenness"). NetworkX accepts zero and miscounts (CE-117) |
| CE-116 | `U: P(0,1,2)` | `betweennessCentrality(weight: [1.0, nan])` | `trap` | exact | |
| CE-117 | `U: P(0,1,2), 1-1` | `betweennessCentrality(weight: [1, 1, 0])` | `trap` | exact | Every weight is checked, loops included. NetworkX gives vertex 1 the value 3.0 here (unnormalized; 1.0 is right): the zero-weight loop makes 1 its own predecessor and doubles σ |
| CE-118 | `D: C(0,1,2,3)` | `betweennessCentrality(normalized: false, weight: [1, 1, 1, 1])` | `[3, 3, 3, 3]` | exact | Unit weights: CE-104 |
| CE-119 | `U: nx(karate_club)` | `betweennessCentrality(weight: e%3+1)` | `[0.458333333333, 0.0915404040404, 0.100220959596, 0.0249368686869, 0.0568181818182, 0.0587121212121, 0, 0, 0.000694444444444, 0, 0, 0, 0.00505050505051, 0.0363005050505, 0, 0.000694444444444, 0, 0, 0, 0.0126262626263, 0, 0, 0, 0.0578282828283, 0.021148989899, 0, 0, 0.0104166666667, 0.0132575757576, 0.0318813131313, 0, 0.32077020202, 0.228851010101, 0.253314393939]` | exact | |
| CE-120 | `U: nx(florentine_families)` | `betweennessCentrality(endpoints: true)` | `[0.133333333333, 0.585714285714, 0.180952380952, 0.152380952381, 0.222222222222, 0.214285714286, 0.231746031746, 0.212698412698, 0.31746031746, 0.257142857143, 0.133333333333, 0.22380952381, 0.353968253968, 0.133333333333, 0.133333333333]` | exact | |
| CE-121 | `D: 0>1, 0>2, 1>3, 2>3, 3>4` | `betweennessCentrality(normalized: false)` | `[0, 1, 1, 3, 0]` | exact | Diamond then tail: σ(0, 3) = 2 |

## E. Eigenvector

| ID | Graph | Op | Expected | Tol | Notes |
|---|---|---|---|---|---|
| CE-130 | `U: K(4)` | `eigenvectorCentrality` | `[0.5, 0.5, 0.5, 0.5]` | 1e-4 | Euclidean norm 1 (NetworkX); igraph scales the greatest to 1 |
| CE-131 | `U: P(0,1,2)` | `eigenvectorCentrality` | `[0.5, 0.707106781187, 0.5]` | 1e-4 | Bipartite: plain power iteration oscillates, the A + I shift (NetworkX) converges |
| CE-132 | `U: S(0;1..4)` | `eigenvectorCentrality` | `[0.707106781187, 0.353553390593, 0.353553390593, 0.353553390593, 0.353553390593]` | 1e-4 | |
| CE-133 | `U: P(0,1,2,3)` | `eigenvectorCentrality` | `[0.37174803446, 0.601500955008, 0.601500955008, 0.37174803446]` | 1e-4 | |
| CE-134 | `U: nx(krackhardt_kite)` | `eigenvectorCentrality` | `[0.352209396817, 0.352209396817, 0.285834991391, 0.481020858273, 0.285834991391, 0.39769063647, 0.39769063647, 0.195860583028, 0.0480734850263, 0.0111632553098]` | 1e-4 | |
| CE-135 | `U: nx(karate_club)` | `eigenvectorCentrality` | `[0.355491444525, 0.265959919552, 0.317192504486, 0.211179720378, 0.0759688181831, 0.0794830451171, 0.0794830451171, 0.170959748045, 0.227403907125, 0.102674250724, 0.0759688181831, 0.0528556974935, 0.0842546287167, 0.226472720142, 0.10140326219, 0.10140326219, 0.0236356281046, 0.0923995381957, 0.10140326219, 0.147912510293, 0.10140326219, 0.0923995381957, 0.10140326219, 0.150118571861, 0.0570524405412, 0.0592064749168, 0.0755794134883, 0.13347715338, 0.131077822984, 0.134960819262, 0.174758302314, 0.191033841407, 0.308644219791, 0.373363470291]` | 1e-4 | |
| CE-136 | `U: nx(florentine_families)` | `eigenvectorCentrality` | `[0.132154294729, 0.430308094041, 0.25902616719, 0.275730373581, 0.355980448411, 0.211705251161, 0.341552644057, 0.325842301124, 0.243956109159, 0.145917196466, 0.0448134358959, 0.282800086544, 0.289115599012, 0.0749227076997, 0.088791887979]` | 1e-4 | |
| CE-137 | `U: K(3), 3-4` | `eigenvectorCentrality` | `[0.57735026919, 0.57735026919, 0.57735026919, 0, 0]` | 1e-4 | Disconnected: the limit puts 0 on K₂ (NetworkX returns 4.5e-6 there, within Tol). `eigenvector_centrality_numpy` raises `AmbiguousSolution` |
| CE-138 | `U: K(3), C(3,4,5)` | `eigenvectorCentrality` | `[0.408248290464, 0.408248290464, 0.408248290464, 0.408248290464, 0.408248290464, 0.408248290464]` | 1e-4 | Two equal components: the dominant eigenvalue is double, and the limit from the uniform start is uniform |
| CE-139 | `U: P(0,1,2), 1-1` | `eigenvectorCentrality` | `[0.325057583672, 0.888073833977, 0.325057583672]` | 1e-4 | A_11 = 2 (the loop twice, as `degree(of:)`): λ = 1 + √3. igraph agrees ([0.366, 1, 0.366] scaled to max 1); NetworkX counts the loop once ([0.408, 0.816, 0.408]) |
| CE-140 | `U: 0-1, 0-1, 1-2, 0-3, 3-2` | `eigenvectorCentrality` | `[0.601500955008, 0.601500955008, 0.37174803446, 0.37174803446]` | 1e-4 | Parallel edges add: igraph agrees, `eigenvector_centrality_numpy` agrees; `eigenvector_centrality` refuses multigraphs |
| CE-141 | `D: C(0,1,2)` | `eigenvectorCentrality` | `[0.57735026919, 0.57735026919, 0.57735026919]` | 1e-4 | |
| CE-142 | `D: P(0,1,2)` | `eigenvectorCentrality` | `nil` | 1e-4 | A DAG: A + I has only eigenvalue 1 with a Jordan block, so the iterates creep toward the sink and never meet the stop rule in 100 iterations. NetworkX raises `PowerIterationFailedConvergence`; igraph special-cases DAGs ([0, 0, 1]) |
| CE-143 | `D: C(0,1,2), 0>3` | `eigenvectorCentrality` | `[0.5, 0.5, 0.5, 0.5]` | 1e-4 | In-edges (left eigenvector): 3 inherits 0's score |
| CE-144 | `U: P(0,1,2)` | `eigenvectorCentrality(weight: [1.0, 2.0])` | `[0.316227766017, 0.707106781187, 0.632455532034]` | 1e-4 | |
| CE-145 | `U: nx(karate_club)` | `eigenvectorCentrality(maxIterations: 5)` | `nil` | 1e-4 | NetworkX raises with `max_iter=5` too |
| CE-146 | `U: nx(karate_club)` | `eigenvectorCentrality(tolerance: 1e-10)` | `[0.355491444525, 0.265959919552, 0.317192504486, 0.211179720378, 0.0759688181831, 0.0794830451171, 0.0794830451171, 0.170959748045, 0.227403907125, 0.102674250724, 0.0759688181831, 0.0528556974935, 0.0842546287167, 0.226472720142, 0.10140326219, 0.10140326219, 0.0236356281046, 0.0923995381957, 0.10140326219, 0.147912510293, 0.10140326219, 0.0923995381957, 0.10140326219, 0.150118571861, 0.0570524405412, 0.0592064749168, 0.0755794134883, 0.13347715338, 0.131077822984, 0.134960819262, 0.174758302314, 0.191033841407, 0.308644219791, 0.373363470291]` | 1e-8 | |
| CE-147 | `U: P(0,1,2)` | `directed > eigenvectorCentrality` | `[0.5, 0.707106781187, 0.5]` | 1e-4 | Same as undirected |
| CE-148 | `D: C(0,1,2), 2>0` | `eigenvectorCentrality` | `[0.702414383919, 0.557506665976, 0.442493334024]` | 1e-4 | A parallel arc counts twice |
| CE-149 | `U: P(0,1,2)` | `eigenvectorCentrality(weight: [1.0, inf])` | `trap` | 1e-4 | Iterative weights: finite and ≥ 0 |

## F. Katz

| ID | Graph | Op | Expected | Tol | Notes |
|---|---|---|---|---|---|
| CE-160 | `U: P(0,1,2)` | `katzCentrality` | `[0.559885258415, 0.610783918271, 0.559885258415]` | 1e-4 | α = 0.1, β = 1, Euclidean norm 1 (NetworkX defaults) |
| CE-161 | `U: K(4)` | `katzCentrality` | `[0.5, 0.5, 0.5, 0.5]` | 1e-4 | |
| CE-162 | `U: nx(karate_club)` | `katzCentrality` | `[0.321324621912, 0.235484274833, 0.265765919737, 0.194913214879, 0.121904378806, 0.130972249171, 0.130972249171, 0.166233056953, 0.200717829848, 0.124201488531, 0.121904378806, 0.0966167160081, 0.116108037496, 0.199373699693, 0.125133413305, 0.125133413305, 0.090678703651, 0.120165143491, 0.125133413305, 0.153305786231, 0.125133413305, 0.120165143491, 0.125133413305, 0.166790639839, 0.110211037863, 0.111564581821, 0.112935499279, 0.151901656301, 0.143581648765, 0.153106027217, 0.168753623773, 0.193801602341, 0.275085167485, 0.3314064274]` | 1e-4 | |
| CE-163 | `U: nx(karate_club)` | `katzCentrality(alpha: 0.2)` | `nil` | 1e-4 | α > 1/λ_max ≈ 0.149: the series diverges. NetworkX raises |
| CE-164 | `U: P(0,1,2)` | `katzCentrality(normalized: false)` | `[1.12244897959, 1.22448979592, 1.12244897959]` | 1e-4 | (I − αAᵀ)⁻¹β1 |
| CE-165 | `U: P(0,1,2)` | `katzCentrality(alpha: 0.5, beta: 2.0, normalized: false)` | `[6, 8, 6]` | 1e-4 | |
| CE-166 | `D: P(0,1,2)` | `katzCentrality` | `[0.538999370961, 0.592899308057, 0.598289301767]` | 1e-4 | In-edges: β, β + αβ, β + α(β + αβ), normalized |
| CE-167 | `D: C(0,1,2)` | `katzCentrality` | `[0.57735026919, 0.57735026919, 0.57735026919]` | 1e-4 | |
| CE-168 | `U: P(0,1,2), 1-1` | `katzCentrality` | `[0.514495755428, 0.68599434057, 0.514495755428]` | 1e-4 | Loop twice in A. NetworkX counts it once |
| CE-169 | `U: 0-1, 0-1, 1-2` | `katzCentrality` | `[0.582127834454, 0.625426599, 0.519585174554]` | 1e-4 | NetworkX refuses multigraphs |
| CE-170 | `U: P(0,1,2)` | `katzCentrality(weight: [1.0, 2.0])` | `[0.519585174554, 0.625426599, 0.582127834454]` | 1e-4 | |
| CE-171 | `U: K(4)` | `katzCentrality(alpha: 0.4)` | `nil` | 1e-4 | α·λ_max = 1.2 |

## G. PageRank

| ID | Graph | Op | Expected | Tol | Notes |
|---|---|---|---|---|---|
| CE-175 | `D: P(0,1,2)` | `pageRank` | `[0.184416781927, 0.341171046565, 0.474412171508]` | 1e-4 | Dangling vertex 2 spreads its rank by the personalization (uniform). igraph (PRPACK) agrees to 1e-6 |
| CE-176 | `D: C(0,1,2)` | `pageRank` | `[0.333333333333, 0.333333333333, 0.333333333333]` | 1e-4 | |
| CE-177 | `D: 0>1, 0>2, 1>2, 2>0, 3>2` | `pageRank` | `[0.372526851328, 0.195823911815, 0.394149236857, 0.0375]` | 1e-4 | |
| CE-178 | `D: P(0,1,2)` | `pageRank(personalization: [1, 0, 0])` | `[0.388726919339, 0.330417881438, 0.280855199223]` | 1e-4 | igraph `personalized_pagerank(reset=)` agrees |
| CE-179 | `D: P(0,1,2)` | `pageRank(dampingFactor: 0.5)` | `[0.235294117647, 0.352941176471, 0.411764705882]` | 1e-4 | |
| CE-180 | `U: nx(karate_club)` | `pageRank` | `[0.0969972853883, 0.0528769240611, 0.0570785094885, 0.0358598577864, 0.0219779523646, 0.0291111546784, 0.0291111546784, 0.0244904970353, 0.029766056081, 0.014309397129, 0.0219779523646, 0.00956474549214, 0.0146448920119, 0.0295364561519, 0.0145359939979, 0.0145359939979, 0.0167840054442, 0.014558677209, 0.0145359939979, 0.0196046363257, 0.0145359939979, 0.014558677209, 0.0145359939979, 0.0315225147767, 0.0210760335592, 0.0210061973945, 0.0150440380827, 0.0256397674828, 0.0195734594638, 0.0262885376951, 0.0245901552486, 0.0371580870691, 0.0716932260057, 0.100919182333]` | 1e-4 | Undirected: each edge two arcs |
| CE-181 | `U: S(0;1..4)` | `pageRank` | `[0.475675675676, 0.131081081081, 0.131081081081, 0.131081081081, 0.131081081081]` | 1e-4 | |
| CE-182 | `U: P(0,1,2), 1-1` | `pageRank` | `[0.184210526316, 0.631578947368, 0.184210526316]` | 1e-4 | The loop is two arcs 1 → 1 (`graph.directed`'s reading). igraph agrees ([0.1842, 0.6316, 0.1842]); NetworkX makes it one arc ([0.2128, 0.5745, 0.2128]) |
| CE-183 | `D: 0>1, 0>1, 0>2, 2>0, 1>0` | `pageRank` | `[0.486486486486, 0.325675675676, 0.187837837838]` | 1e-4 | Parallel arcs add (NetworkX MultiDiGraph and igraph agree) |
| CE-184 | `D: 0>1, 0>2, 1>0, 2>0` | `pageRank(weight: [1.0, 3.0, 1.0, 1.0])` | `[0.486486486486, 0.153378378378, 0.360135135135]` | 1e-4 | Out-weights normalized per row |
| CE-185 | `D: 0>1, 1>2` | `pageRank(weight: [0.0, 1.0])` | `[0.25974025974, 0.25974025974, 0.480519480519]` | 1e-4 | Zero out-weight: vertex 0 is dangling |
| CE-186 | `U: nx(karate_club)` | `pageRank(maxIterations: 3)` | `nil` | 1e-4 | NetworkX raises with `max_iter=3` too |
| CE-187 | `D: P(0,1,2)` | `pageRank(personalization: [0, 0, 0])` | `trap` | 1e-4 | Precondition: personalization ≥ 0, finite, positive sum |
| CE-188 | `D: P(0,1,2)` | `pageRank(personalization: [-1, 1, 1])` | `trap` | 1e-4 | |
| CE-189 | `D: [0..2]` | `pageRank(personalization: [1, 2, 1])` | `[0.25, 0.5, 0.25]` | 1e-4 | No arcs: the personalization itself |
| CE-190 | `U: P(0,1,2)` | `directed > pageRank` | `[0.256756756757, 0.486486486486, 0.256756756757]` | 1e-4 | Same as undirected |
| CE-191 | `D: P(0,1,2)` | `pageRank(weight: [1.0, -1.0])` | `trap` | 1e-4 | |

## H. HITS

| ID | Graph | Op | Expected | Tol | Notes |
|---|---|---|---|---|---|
| CE-195 | `D: P(0,1,2)` | `hits.hubs` | `[0.5, 0.5, 0]` | 1e-4 | σ₁ is double, so the vectors are the limit from the uniform start, not unique (NetworkX's svds gives the same here) |
| CE-196 | `D: P(0,1,2)` | `hits.authorities` | `[0, 0.5, 0.5]` | 1e-4 | |
| CE-197 | `D: 0>1, 0>2, 3>1` | `hits.hubs` | `[0.61803398875, 0, 0, 0.38196601125]` | 1e-4 | Sum 1 (NetworkX `normalized=True`); igraph scales the greatest to 1 |
| CE-198 | `D: 0>1, 0>2, 3>1` | `hits.authorities` | `[0, 0.61803398875, 0.38196601125, 0]` | 1e-4 | |
| CE-199 | `D: C(0,1,2)` | `hits.hubs` | `[0.333333333333, 0.333333333333, 0.333333333333]` | 1e-4 | |
| CE-200 | `D: 0>1, 0>2, 1>2, 2>0, 3>2` | `hits.hubs` | `[0.414213562373, 0.292893218813, 4.01180205256e-16, 0.292893218813]` | 1e-4 | |
| CE-201 | `D: 0>1, 0>2, 1>2, 2>0, 3>2` | `hits.authorities` | `[9.68534692485e-16, 0.292893218813, 0.707106781187, 0]` | 1e-4 | |
| CE-202 | `D: 0>1, 0>1, 0>2, 2>0, 1>0` | `hits.hubs` | `[1, 7.55578637259e-16, 7.55578637259e-16]` | 1e-4 | Parallel arcs add |
| CE-203 | `D: 0>1, 0>2, 3>1` | `hits(weight: [2.0, 1.0, 1.0]).hubs` | `[0.707106781187, 0, 0, 0.292893218813]` | 1e-4 | |
| CE-204 | `U: nx(karate_club)` | `directed > hits.hubs` | `[0.0714127288083, 0.0534272312355, 0.0637190645564, 0.0424227371247, 0.0152609597062, 0.0159669135031, 0.0159669135031, 0.0343431672191, 0.0456819251198, 0.0206256677494, 0.0152609597062, 0.0106178915111, 0.0169254507923, 0.0454948640681, 0.0203703458256, 0.0203703458256, 0.0047480318473, 0.0185616370374, 0.0203703458256, 0.0297133338864, 0.0203703458256, 0.0185616370374, 0.0203703458256, 0.0301564975094, 0.011460952231, 0.0118936643963, 0.0151827343303, 0.0268134941171, 0.026331505778, 0.0271115396282, 0.0351062379767, 0.038375741863, 0.0620018464738, 0.0750029421566]` | 1e-4 | Symmetric A: hubs = authorities = eigenvector centrality rescaled to sum 1 |
| CE-205 | `U: nx(karate_club)` | `directed > hits.authorities` | `[0.0714127288083, 0.0534272312355, 0.0637190645564, 0.0424227371247, 0.0152609597062, 0.0159669135031, 0.0159669135031, 0.0343431672191, 0.0456819251198, 0.0206256677494, 0.0152609597062, 0.0106178915111, 0.0169254507923, 0.0454948640681, 0.0203703458256, 0.0203703458256, 0.0047480318473, 0.0185616370374, 0.0203703458256, 0.0297133338864, 0.0203703458256, 0.0185616370374, 0.0203703458256, 0.0301564975094, 0.011460952231, 0.0118936643963, 0.0151827343303, 0.0268134941171, 0.026331505778, 0.0271115396282, 0.0351062379767, 0.038375741863, 0.0620018464738, 0.0750029421566]` | 1e-4 | |
| CE-206 | `D: 0>1, 0>2, 3>1` | `hits(maxIterations: 1).hubs` | `nil` | 1e-4 | |
