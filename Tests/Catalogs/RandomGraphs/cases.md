# RandomGraphs: case catalog

Generated and checked by `ref.py` (`uv run --quiet --no-project --with networkx==3.7 --with igraph==1.0.0
python3 Tests/Catalogs/RandomGraphs/ref.py`; `--write` regenerates this file, `--stress` re-checks the
NetworkX equivalences over many seeds). `ref.py` ports the pinned procedures of `api.md` and the
generator; igraph checks simplicity, `is_tree` and `is_dag` on every exact row.

Conventions:

* `using: &Xoshiro256StarStar(seed: s)` stands for `var g = Xoshiro256StarStar(seed: s)` and `using: &g`.
  `using: &…` rows make no draws, so any generator gives them.
* `E [...]` is `edges` in order. Every factory but `Tree.random` emits sorted edges: undirected
  `UndirectedEdge(u, v)` with `u < v` in lexicographic order, directed edges in row-major order.
  `Tree.random` keeps `Tree(pruferSequence:)`'s order: edge k joins the k-th leaf removed to the k-th
  code element. `pos` lists positions as shortest round-trip doubles (Python `repr`, Swift `description`),
  so they compare exactly.
* `draws` is how many `next()` calls the factory made: a later draw from the same generator continues
  from there, so the count is part of the pinned procedure. A test checks it with `Equatable`: the
  generator equals a fresh one with the same seed advanced `draws` times.
* `= NetworkX` marks rows that NetworkX 3.7 reproduces edge for edge when it runs on the same stream
  (`StreamRandom` in `ref.py`). Barabási–Albert rows match when CPython's set iteration happens to be
  ascending; G(n, m) rows when 2m ≤ N.
* Statistical rows give the exact aggregate over the listed seeds, which the Swift suite asserts
  exactly, and the law it satisfies, which a reimplementation must also satisfy.
* `**trap**` rows are preconditions, run as exit tests (`#expect(processExitsWith:)`).

| ID | Group | Case | Call | Expected |
|---|---|---|---|---|
| RG-001 | Generator | xoshiro256** reference vector (rand_xoshiro's test) | `Xoshiro256StarStar(state: (1, 2, 3, 4)); next() × 4` | [11520, 0, 1509978240, 1215971899390074240] |
| RG-002 | Generator | the all-zero state never leaves zero | `Xoshiro256StarStar(state: (0, 0, 0, 0))` | **trap**: the state must not be all zero |
| RG-003 | Generator | seed 0: SplitMix64 fills the state | `Xoshiro256StarStar(seed: 0); next() × 4` | [11091344671253066420, 13793997310169335082, 1900383378846508768, 7684712102626143532] |
| RG-004 | Generator | seed 1: SplitMix64 fills the state | `Xoshiro256StarStar(seed: 1); next() × 4` | [12966619160104079557, 9600361134598540522, 10590380919521690900, 7218738570589545383] |
| RG-005 | Generator | seed 42: SplitMix64 fills the state | `Xoshiro256StarStar(seed: 42); next() × 4` | [1546998764402558742, 6990951692964543102, 12544586762248559009, 17057574109182124193] |
| RG-006 | Generator | seed 18446744073709551615: SplitMix64 fills the state | `Xoshiro256StarStar(seed: 18446744073709551615); next() × 4` | [10328197420357168392, 14156678507024973869, 9357971779955476126, 13791585006304312367] |
| RG-007 | Generator | a copy replays the stream (value semantics) | `var a = Xoshiro256StarStar(seed: 5); var b = a; a.next() × 3; b.next() × 3` | both [5320248114040590185, 11106458710588138716, 11982022302389484462] |
| RG-008 | Generator | works with any RandomNumberGenerator API (values not pinned) | `Int.random(in: 1...6, using: &g)` | in 1...6; not compared: the standard library's algorithm is not ours to pin |
| RG-009 | ErdosRenyiGnp | G(10, 0.3) undirected | `UndirectedAdjacencyList<Int>.erdosRenyi(vertexCount: 10, edgeProbability: 0.3, using: &Xoshiro256StarStar(seed: 0))` | n 10; m 8; E [0–4, 1–2, 1–4, 1–9, 3–4, 3–5, 3–9, 6–9]; draws 9; = NetworkX |
| RG-010 | ErdosRenyiGnp | G(10, 0.3) undirected | `UndirectedAdjacencyList<Int>.erdosRenyi(vertexCount: 10, edgeProbability: 0.3, using: &Xoshiro256StarStar(seed: 1))` | n 10; m 11; E [0–3, 0–4, 0–6, 0–8, 0–9, 1–5, 1–6, 2–6, 3–4, 4–6, 4–7]; draws 12; = NetworkX |
| RG-011 | ErdosRenyiGnp | G(10, 0.3) undirected | `UndirectedAdjacencyList<Int>.erdosRenyi(vertexCount: 10, edgeProbability: 0.3, using: &Xoshiro256StarStar(seed: 42))` | n 10; m 8; E [0–1, 0–4, 0–8, 1–2, 1–9, 4–5, 5–8, 7–9]; draws 9; = NetworkX |
| RG-012 | ErdosRenyiGnp | G(6, 0.5) undirected | `UndirectedAdjacencyList<Int>.erdosRenyi(vertexCount: 6, edgeProbability: 0.5, using: &Xoshiro256StarStar(seed: 0))` | n 6; m 5; E [0–2, 0–3, 1–3, 1–4, 2–3]; draws 6; = NetworkX |
| RG-013 | ErdosRenyiGnp | G(1, 0.5) undirected | `UndirectedAdjacencyList<Int>.erdosRenyi(vertexCount: 1, edgeProbability: 0.5, using: &Xoshiro256StarStar(seed: 0))` | n 1; m 0; E []; draws 0; = NetworkX |
| RG-014 | ErdosRenyiGnp | G(0, 0.5) undirected | `UndirectedAdjacencyList<Int>.erdosRenyi(vertexCount: 0, edgeProbability: 0.5, using: &Xoshiro256StarStar(seed: 0))` | n 0; m 0; E []; draws 0; = NetworkX |
| RG-015 | ErdosRenyiGnp | G(6, 0.3) directed: lower→higher pass, then higher→lower | `CompressedSparseRow.erdosRenyi(vertexCount: 6, edgeProbability: 0.3, using: &Xoshiro256StarStar(seed: 0))` | n 6; m 8; E [0→4, 1→2, 1→4, 2→0, 3→1, 3→4, 3→5, 5→0]; draws 10; = NetworkX |
| RG-016 | ErdosRenyiGnp | G(6, 0.3) directed: lower→higher pass, then higher→lower | `CompressedSparseRow.erdosRenyi(vertexCount: 6, edgeProbability: 0.3, using: &Xoshiro256StarStar(seed: 1))` | n 6; m 9; E [0→3, 0→4, 1→0, 1→5, 2→0, 3→0, 3→4, 4→3, 5→2]; draws 11; = NetworkX |
| RG-017 | ErdosRenyiGnp | p = 0: no draws | `UndirectedAdjacencyList<Int>.erdosRenyi(vertexCount: 5, edgeProbability: 0.0, using: &…)` | n 5; m 0; E []; draws 0; = NetworkX |
| RG-018 | ErdosRenyiGnp | p = 1: complete, no draws | `UndirectedAdjacencyList<Int>.erdosRenyi(vertexCount: 4, edgeProbability: 1.0, using: &…)` | n 4; m 6; E [0–1, 0–2, 0–3, 1–2, 1–3, 2–3]; draws 0; = NetworkX |
| RG-019 | ErdosRenyiGnp | p = 1 directed | `CompressedSparseRow.erdosRenyi(vertexCount: 3, edgeProbability: 1.0, using: &…)` | n 3; m 6; E [0→1, 0→2, 1→0, 1→2, 2→0, 2→1]; draws 0; = NetworkX |
| RG-020 | ErdosRenyiGnp | p = 1e-300: 1 − p rounds to 1, empty, no draws | `UndirectedAdjacencyList<Int>.erdosRenyi(vertexCount: 1000, edgeProbability: 1e-300, using: &…)` | n 1000; m 0; E []; draws 0 |
| RG-021 | ErdosRenyiGnp | a skip past every remaining pair ends the sweep before any Int conversion | `UndirectedAdjacencyList<Int>.erdosRenyi(vertexCount: 20000, edgeProbability: 1e-12, using: &Xoshiro256StarStar(seed: 3))` | n 20000; m 0; E [] |
| RG-022 | ErdosRenyiGnp | negative vertex count | `UndirectedAdjacencyList<Int>.erdosRenyi(…)` | **trap**: vertexCount -1 is negative |
| RG-023 | ErdosRenyiGnp | p > 1 | `UndirectedAdjacencyList<Int>.erdosRenyi(…)` | **trap**: edgeProbability 1.5 is not in 0...1 |
| RG-024 | ErdosRenyiGnp | p < 0 | `UndirectedAdjacencyList<Int>.erdosRenyi(…)` | **trap**: edgeProbability -0.1 is not in 0...1 |
| RG-025 | ErdosRenyiGnp | p NaN | `UndirectedAdjacencyList<Int>.erdosRenyi(…)` | **trap**: edgeProbability nan is not in 0...1 |
| RG-026 | ErdosRenyiGnp | law: E[m] = p·C(n, 2) | `G(100, 0.05) undirected` | Σ 49295 over seeds 0..<200 (mean 246.4750; expected 247.5000; |z| 0.95 ≤ 4) |
| RG-027 | ErdosRenyiGnp | law: E[m] = p·n(n − 1) | `G(100, 0.05) directed` | Σ 99021 over seeds 0..<200 (mean 495.1050; expected 495.0000; |z| 0.07 ≤ 4) |
| RG-028 | ErdosRenyiGnp | law: degree variance (n − 1)p(1 − p) | `G(100, 0.05), degrees pooled over seeds 0..<200` | variance 4.6802; expected 4.7025; within 5% |
| RG-029 | ErdosRenyiGnp | law: each labeled graph on 3 vertices with probability p^m (1 − p)^(3 − m) | `G(3, 0.3) undirected` | 8 outcomes over seeds 0..<4000; χ² 6.85 ≤ 24.322 (df 7, 0.999) |
| RG-030 | ErdosRenyiGnm | G(10, 8) undirected | `UndirectedAdjacencyList<Int>.erdosRenyi(vertexCount: 10, edgeCount: 8, using: &Xoshiro256StarStar(seed: 0))` | n 10; m 8; E [0–4, 1–8, 1–9, 2–3, 2–4, 3–8, 4–7, 5–7]; draws 39; = NetworkX |
| RG-031 | ErdosRenyiGnm | G(10, 8) undirected | `UndirectedAdjacencyList<Int>.erdosRenyi(vertexCount: 10, edgeCount: 8, using: &Xoshiro256StarStar(seed: 1))` | n 10; m 8; E [0–1, 0–6, 1–6, 1–7, 2–6, 3–6, 5–9, 8–9]; draws 31; = NetworkX |
| RG-032 | ErdosRenyiGnm | G(10, 8) undirected | `UndirectedAdjacencyList<Int>.erdosRenyi(vertexCount: 10, edgeCount: 8, using: &Xoshiro256StarStar(seed: 42))` | n 10; m 8; E [0–7, 1–2, 1–6, 3–6, 4–9, 5–7, 5–9, 6–9]; draws 39; = NetworkX |
| RG-033 | ErdosRenyiGnm | G(6, 12) undirected (2m > N = 15: the loop picks the 3 pairs left out) | `UndirectedAdjacencyList<Int>.erdosRenyi(vertexCount: 6, edgeCount: 12, using: &Xoshiro256StarStar(seed: 0))` | n 6; m 12; E [0–1, 0–2, 0–4, 0–5, 1–2, 1–3, 1–4, 1–5, 2–3, 2–4, 2–5, 3–4]; draws 7 |
| RG-034 | ErdosRenyiGnm | G(6, 15) undirected (2m > N = 15: the loop picks the 0 pairs left out) | `UndirectedAdjacencyList<Int>.erdosRenyi(vertexCount: 6, edgeCount: 15, using: &Xoshiro256StarStar(seed: 0))` | n 6; m 15; E [0–1, 0–2, 0–3, 0–4, 0–5, 1–2, 1–3, 1–4, 1–5, 2–3, 2–4, 2–5, 3–4, 3–5, 4–5]; draws 0; = NetworkX |
| RG-035 | ErdosRenyiGnm | G(5, 6) directed | `CompressedSparseRow.erdosRenyi(vertexCount: 5, edgeCount: 6, using: &Xoshiro256StarStar(seed: 0))` | n 5; m 6; E [0→2, 1→4, 2→1, 3→0, 3→2, 4→0]; draws 43; = NetworkX |
| RG-036 | ErdosRenyiGnm | G(5, 6) directed | `CompressedSparseRow.erdosRenyi(vertexCount: 5, edgeCount: 6, using: &Xoshiro256StarStar(seed: 1))` | n 5; m 6; E [0→3, 3→0, 3→1, 3→2, 3→4, 4→2]; draws 47; = NetworkX |
| RG-037 | ErdosRenyiGnm | G(4, 10) directed (2m > N = 12: the loop picks the 2 pairs left out) | `CompressedSparseRow.erdosRenyi(vertexCount: 4, edgeCount: 10, using: &Xoshiro256StarStar(seed: 0))` | n 4; m 10; E [0→1, 0→2, 1→0, 1→2, 1→3, 2→0, 2→1, 2→3, 3→1, 3→2]; draws 11 |
| RG-038 | ErdosRenyiGnm | G(0, 0) undirected | `UndirectedAdjacencyList<Int>.erdosRenyi(vertexCount: 0, edgeCount: 0, using: &Xoshiro256StarStar(seed: 0))` | n 0; m 0; E []; draws 0; = NetworkX |
| RG-039 | ErdosRenyiGnm | G(1, 0) undirected | `UndirectedAdjacencyList<Int>.erdosRenyi(vertexCount: 1, edgeCount: 0, using: &Xoshiro256StarStar(seed: 0))` | n 1; m 0; E []; draws 0; = NetworkX |
| RG-040 | ErdosRenyiGnm | m > N | `UndirectedAdjacencyList<Int>.erdosRenyi(vertexCount:edgeCount:using:)` | **trap**: edgeCount 7 is not in 0...6 |
| RG-041 | ErdosRenyiGnm | m > N directed | `CompressedSparseRow.erdosRenyi(vertexCount:edgeCount:using:)` | **trap**: edgeCount 7 is not in 0...6 |
| RG-042 | ErdosRenyiGnm | negative m | `UndirectedAdjacencyList<Int>.erdosRenyi(vertexCount:edgeCount:using:)` | **trap**: edgeCount -1 is not in 0...6 |
| RG-043 | ErdosRenyiGnm | n = 1, m = 1 | `UndirectedAdjacencyList<Int>.erdosRenyi(vertexCount:edgeCount:using:)` | **trap**: edgeCount 1 is not in 0...0 |
| RG-044 | ErdosRenyiGnm | law: uniform over the C(N, m) graphs | `G(4, 3) undirected` | 20 outcomes over seeds 0..<4000; χ² 18.25 ≤ 43.82 (df 19, 0.999) |
| RG-045 | ErdosRenyiGnm | law: uniform over the C(N, m) graphs (complement branch) | `G(4, 5) undirected` | 6 outcomes over seeds 0..<1200; χ² 4.98 ≤ 20.515 (df 5, 0.999) |
| RG-046 | ErdosRenyiGnm | law: uniform over the C(N, m) graphs | `G(3, 2) directed` | 15 outcomes over seeds 0..<3000; χ² 12.76 ≤ 36.123 (df 14, 0.999) |
| RG-047 | BarabasiAlbert | n 10, m 1: star on 0…1, then each new vertex to 1 distinct targets | `UndirectedAdjacencyList<Int>.barabasiAlbert(vertexCount: 10, edgesPerVertex: 1, using: &Xoshiro256StarStar(seed: 0))` | n 10; m 9; E [0–1, 0–2, 1–7, 1–8, 2–3, 2–9, 3–4, 3–5, 3–6]; draws 13; = NetworkX |
| RG-048 | BarabasiAlbert | n 10, m 1: star on 0…1, then each new vertex to 1 distinct targets | `UndirectedAdjacencyList<Int>.barabasiAlbert(vertexCount: 10, edgesPerVertex: 1, using: &Xoshiro256StarStar(seed: 1))` | n 10; m 9; E [0–1, 0–4, 0–5, 0–6, 0–7, 1–2, 1–3, 1–9, 5–8]; draws 17; = NetworkX |
| RG-049 | BarabasiAlbert | n 10, m 2: star on 0…2, then each new vertex to 2 distinct targets | `UndirectedAdjacencyList<Int>.barabasiAlbert(vertexCount: 10, edgesPerVertex: 2, using: &Xoshiro256StarStar(seed: 0))` | n 10; m 16; E [0–1, 0–2, 0–3, 0–4, 0–5, 0–8, 2–3, 3–4, 3–6, 3–7, 3–8, 4–5, 4–9, 5–6, 5–7, 5–9]; draws 23; = NetworkX |
| RG-050 | BarabasiAlbert | n 10, m 2: star on 0…2, then each new vertex to 2 distinct targets | `UndirectedAdjacencyList<Int>.barabasiAlbert(vertexCount: 10, edgesPerVertex: 2, using: &Xoshiro256StarStar(seed: 1))` | n 10; m 16; E [0–1, 0–2, 0–3, 0–4, 0–5, 0–7, 0–9, 1–6, 1–7, 2–3, 3–4, 4–5, 4–9, 5–6, 5–8, 6–8]; draws 25; = NetworkX |
| RG-051 | BarabasiAlbert | n 10, m 2: star on 0…2, then each new vertex to 2 distinct targets | `UndirectedAdjacencyList<Int>.barabasiAlbert(vertexCount: 10, edgesPerVertex: 2, using: &Xoshiro256StarStar(seed: 42))` | n 10; m 16; E [0–1, 0–2, 0–3, 0–4, 1–6, 2–3, 2–4, 2–5, 2–6, 2–9, 4–5, 4–7, 4–8, 5–8, 5–9, 6–7]; draws 28; = NetworkX |
| RG-052 | BarabasiAlbert | n 12, m 3: star on 0…3, then each new vertex to 3 distinct targets | `UndirectedAdjacencyList<Int>.barabasiAlbert(vertexCount: 12, edgesPerVertex: 3, using: &Xoshiro256StarStar(seed: 0))` | n 12; m 27; E [0–1, 0–2, 0–3, 0–4, 0–5, 0–6, 0–7, 0–8, 0–10, 1–6, 1–9, 2–4, 3–4, 3–5, 3–10, 4–5, 4–7, 4–8, 4–9, 4–11, 5–6, 5–8, 5–9, 5–11, 6–7, 6–11, 9–10]; draws 40 |
| RG-053 | BarabasiAlbert | n 2, m 1: star on 0…1, then each new vertex to 1 distinct targets | `UndirectedAdjacencyList<Int>.barabasiAlbert(vertexCount: 2, edgesPerVertex: 1, using: &Xoshiro256StarStar(seed: 0))` | n 2; m 1; E [0–1]; draws 0; = NetworkX |
| RG-054 | BarabasiAlbert | directed: new vertex → older vertex (igraph) | `CompressedSparseRow.barabasiAlbert(vertexCount: 8, edgesPerVertex: 2, using: &Xoshiro256StarStar(seed: 0))` | n 8; m 12; E [1→0, 2→0, 3→0, 3→2, 4→0, 4→3, 5→0, 5→4, 6→3, 6→5, 7→3, 7→5]; draws 19; = NetworkX |
| RG-055 | BarabasiAlbert | m = 0 | `UndirectedAdjacencyList<Int>.barabasiAlbert(…)` | **trap**: edgesPerVertex 0 is not in 1..<5 |
| RG-056 | BarabasiAlbert | m = n | `UndirectedAdjacencyList<Int>.barabasiAlbert(…)` | **trap**: edgesPerVertex 5 is not in 1..<5 |
| RG-057 | BarabasiAlbert | n = 1 | `UndirectedAdjacencyList<Int>.barabasiAlbert(…)` | **trap**: edgesPerVertex 1 is not in 1..<1 |
| RG-058 | BarabasiAlbert | laws: m(n − m) edges, degree sum 2m(n − m), every new vertex has degree ≥ m | `n 1000, m 2, seeds 0..<50` | hold for every seed |
| RG-059 | BarabasiAlbert | law: share of degree-m vertices → 2/(m + 2) (Bollobás et al. 2001) | `n 1000, m 2, pooled over seeds 0..<50` | 24936 of 50000 (0.4987); expected 0.5000 ± 0.02 |
| RG-060 | WattsStrogatz | n 10, k 4, p 0.0: p = 0: the ring lattice (draws still made) | `UndirectedAdjacencyList<Int>.wattsStrogatz(vertexCount: 10, nearestNeighborCount: 4, rewiringProbability: 0.0, using: &Xoshiro256StarStar(seed: 0))` | n 10; m 20; E [0–1, 0–2, 0–8, 0–9, 1–2, 1–3, 1–9, 2–3, 2–4, 3–4, 3–5, 4–5, 4–6, 5–6, 5–7, 6–7, 6–8, 7–8, 7–9, 8–9]; draws 20; = NetworkX |
| RG-061 | WattsStrogatz | n 10, k 4, p 0.3 | `UndirectedAdjacencyList<Int>.wattsStrogatz(vertexCount: 10, nearestNeighborCount: 4, rewiringProbability: 0.3, using: &Xoshiro256StarStar(seed: 0))` | n 10; m 20; E [0–1, 0–2, 0–8, 1–2, 1–8, 1–9, 2–6, 2–7, 3–4, 3–5, 4–5, 4–6, 4–9, 5–6, 5–7, 6–7, 6–8, 7–8, 7–9, 8–9]; draws 29; = NetworkX |
| RG-062 | WattsStrogatz | n 10, k 4, p 0.3 | `UndirectedAdjacencyList<Int>.wattsStrogatz(vertexCount: 10, nearestNeighborCount: 4, rewiringProbability: 0.3, using: &Xoshiro256StarStar(seed: 1))` | n 10; m 20; E [0–1, 0–2, 0–5, 0–8, 0–9, 1–2, 1–3, 1–5, 2–3, 2–4, 3–4, 3–5, 3–9, 4–5, 4–6, 6–7, 6–9, 7–8, 7–9, 8–9]; draws 36; = NetworkX |
| RG-063 | WattsStrogatz | n 10, k 4, p 0.3 | `UndirectedAdjacencyList<Int>.wattsStrogatz(vertexCount: 10, nearestNeighborCount: 4, rewiringProbability: 0.3, using: &Xoshiro256StarStar(seed: 42))` | n 10; m 20; E [0–5, 0–6, 0–8, 0–9, 1–2, 1–3, 1–9, 2–3, 2–4, 2–7, 3–4, 3–5, 4–5, 4–6, 5–6, 5–7, 6–7, 6–8, 7–8, 8–9]; draws 24; = NetworkX |
| RG-064 | WattsStrogatz | n 10, k 4, p 1.0: p = 1: every edge rewired where possible | `UndirectedAdjacencyList<Int>.wattsStrogatz(vertexCount: 10, nearestNeighborCount: 4, rewiringProbability: 1.0, using: &Xoshiro256StarStar(seed: 0))` | n 10; m 20; E [0–1, 0–3, 0–5, 0–6, 0–9, 1–2, 1–6, 2–3, 2–8, 2–9, 3–4, 3–7, 3–8, 4–7, 4–8, 5–6, 5–7, 5–9, 6–7, 8–9]; draws 81; = NetworkX |
| RG-065 | WattsStrogatz | n 8, k 2, p 0.5 | `UndirectedAdjacencyList<Int>.wattsStrogatz(vertexCount: 8, nearestNeighborCount: 2, rewiringProbability: 0.5, using: &Xoshiro256StarStar(seed: 0))` | n 8; m 8; E [0–1, 0–7, 1–2, 1–5, 1–6, 2–6, 3–4, 4–5]; draws 14; = NetworkX |
| RG-066 | WattsStrogatz | n 6, k 6, p 0.5: k = n: complete, no draws (NetworkX) | `UndirectedAdjacencyList<Int>.wattsStrogatz(vertexCount: 6, nearestNeighborCount: 6, rewiringProbability: 0.5, using: &Xoshiro256StarStar(seed: 0))` | n 6; m 15; E [0–1, 0–2, 0–3, 0–4, 0–5, 1–2, 1–3, 1–4, 1–5, 2–3, 2–4, 2–5, 3–4, 3–5, 4–5]; draws 0; = NetworkX |
| RG-067 | WattsStrogatz | n 7, k 6, p 0.5: k = n − 1: every rewiring hits a full vertex and is skipped | `UndirectedAdjacencyList<Int>.wattsStrogatz(vertexCount: 7, nearestNeighborCount: 6, rewiringProbability: 0.5, using: &Xoshiro256StarStar(seed: 0))` | n 7; m 21; E [0–1, 0–2, 0–3, 0–4, 0–5, 0–6, 1–2, 1–3, 1–4, 1–5, 1–6, 2–3, 2–4, 2–5, 2–6, 3–4, 3–5, 3–6, 4–5, 4–6, 5–6]; draws 42; = NetworkX |
| RG-068 | WattsStrogatz | n 5, k 0, p 0.5: k = 0: no edges, no draws | `UndirectedAdjacencyList<Int>.wattsStrogatz(vertexCount: 5, nearestNeighborCount: 0, rewiringProbability: 0.5, using: &Xoshiro256StarStar(seed: 0))` | n 5; m 0; E []; draws 0; = NetworkX |
| RG-069 | WattsStrogatz | odd k (NetworkX floors it) | `UndirectedAdjacencyList<Int>.wattsStrogatz(…)` | **trap**: nearestNeighborCount 3 is not even |
| RG-070 | WattsStrogatz | k > n | `UndirectedAdjacencyList<Int>.wattsStrogatz(…)` | **trap**: nearestNeighborCount 6 > vertexCount 4 |
| RG-071 | WattsStrogatz | p > 1 | `UndirectedAdjacencyList<Int>.wattsStrogatz(…)` | **trap**: rewiringProbability 1.5 is not in 0...1 |
| RG-072 | WattsStrogatz | laws: nk/2 edges for every p, every vertex keeps degree ≥ k/2 | `n 200, k 6, p 0.2, seeds 0..<100` | hold for every seed |
| RG-073 | WattsStrogatz | law: share of ring edges gone ≈ p | `n 200, k 6, p 0.2, pooled over seeds 0..<100` | 12165 of 60000 (0.2028); expected 0.2 ± 0.01 |
| RG-074 | RandomGeometric | n 8, radius 0.4, dimension 2 | `UndirectedAdjacencyList<Int>.randomGeometric(vertexCount: 8, radius: 0.4, dimension: 2, using: &Xoshiro256StarStar(seed: 0))` | n 8; m 9; E [0–2, 0–3, 0–4, 1–3, 1–5, 1–6, 2–4, 3–6, 3–7]; draws 16; = NetworkX |
| RG-075 | RandomGeometric | n 8, radius 0.4, dimension 2 | `UndirectedAdjacencyList<Int>.randomGeometric(vertexCount: 8, radius: 0.4, dimension: 2, using: &Xoshiro256StarStar(seed: 1))` | n 8; m 11; E [0–1, 0–2, 0–4, 0–6, 0–7, 1–2, 1–4, 4–6, 5–6, 5–7, 6–7]; draws 16; = NetworkX |
| RG-076 | RandomGeometric | n 6, radius 0.5, dimension 1 | `UndirectedAdjacencyList<Int>.randomGeometric(vertexCount: 6, radius: 0.5, dimension: 1, using: &Xoshiro256StarStar(seed: 0))` | n 6; m 11; E [0–1, 0–2, 0–3, 0–4, 0–5, 1–3, 1–4, 1–5, 2–3, 3–4, 4–5]; pos [(0.6012629994179048), (0.7477740925472398), (0.10301998939503632), (0.4165890778296456), (0.7329967790569901), (0.9997484362337864)]; draws 6; = NetworkX |
| RG-077 | RandomGeometric | n 5, radius 0.7, dimension 3 | `UndirectedAdjacencyList<Int>.randomGeometric(vertexCount: 5, radius: 0.7, dimension: 3, using: &Xoshiro256StarStar(seed: 0))` | n 5; m 4; E [0–4, 1–2, 1–4, 2–4]; pos [(0.6012629994179048, 0.7477740925472398, 0.10301998939503632), (0.4165890778296456, 0.7329967790569901, 0.9997484362337864), (0.42221152382531557, 0.5356548662673611, 0.8555171516848772), (0.9188580127069649, 0.11429746440648769, 0.06723189101342542), (0.10667465014124933, 0.6548331676545119, 0.49605814120183556)]; draws 15; = NetworkX |
| RG-078 | RandomGeometric | n 6, radius 0.0, dimension 2 | `UndirectedAdjacencyList<Int>.randomGeometric(vertexCount: 6, radius: 0.0, dimension: 2, using: &Xoshiro256StarStar(seed: 0))` | n 6; m 0; E []; pos [(0.6012629994179048, 0.7477740925472398), (0.10301998939503632, 0.4165890778296456), (0.7329967790569901, 0.9997484362337864), (0.42221152382531557, 0.5356548662673611), (0.8555171516848772, 0.9188580127069649), (0.11429746440648769, 0.06723189101342542)]; draws 12; = NetworkX |
| RG-079 | RandomGeometric | n 5, radius 2.0, dimension 2 | `UndirectedAdjacencyList<Int>.randomGeometric(vertexCount: 5, radius: 2.0, dimension: 2, using: &Xoshiro256StarStar(seed: 0))` | n 5; m 10; E [0–1, 0–2, 0–3, 0–4, 1–2, 1–3, 1–4, 2–3, 2–4, 3–4]; pos [(0.6012629994179048, 0.7477740925472398), (0.10301998939503632, 0.4165890778296456), (0.7329967790569901, 0.9997484362337864), (0.42221152382531557, 0.5356548662673611), (0.8555171516848772, 0.9188580127069649)]; draws 10; = NetworkX |
| RG-080 | RandomGeometric | negative radius | `UndirectedAdjacencyList<Int>.randomGeometric(…)` | **trap**: radius -0.1 is negative or NaN |
| RG-081 | RandomGeometric | NaN radius | `UndirectedAdjacencyList<Int>.randomGeometric(…)` | **trap**: radius nan is negative or NaN |
| RG-082 | RandomGeometric | dimension 0 | `UndirectedAdjacencyList<Int>.randomGeometric(…)` | **trap**: dimension 0 < 1 |
| RG-083 | RandomGeometric | law: E[m] = C(n, 2)(πr² − 8r³/3 + r⁴/2) in the unit square | `n 100, radius 0.1` | Σ 14142 over seeds 0..<100 (mean 141.4200; expected 142.5563; |z| 0.37 ≤ 4) |
| RG-084 | StochasticBlockModel | sizes [3, 3] | `UndirectedAdjacencyList<Int>.stochasticBlockModel(blockSizes: [3, 3], edgeProbabilities: [[0.9, 0.1], [0.1, 0.9]], using: &Xoshiro256StarStar(seed: 0))` | n 6; m 8; E [0–1, 0–2, 0–5, 1–2, 1–3, 3–4, 3–5, 4–5]; draws 11; = NetworkX |
| RG-085 | StochasticBlockModel | sizes [3, 3] | `UndirectedAdjacencyList<Int>.stochasticBlockModel(blockSizes: [3, 3], edgeProbabilities: [[0.9, 0.1], [0.1, 0.9]], using: &Xoshiro256StarStar(seed: 1))` | n 6; m 6; E [0–1, 0–2, 1–2, 1–3, 3–5, 4–5]; draws 9; = NetworkX |
| RG-086 | StochasticBlockModel | sizes [2, 3, 2] | `UndirectedAdjacencyList<Int>.stochasticBlockModel(blockSizes: [2, 3, 2], edgeProbabilities: [[1.0, 0.0, 0.5], [0.0, 0.5, 0.2], [0.5, 0.2, 0.0]], using: &Xoshiro256StarStar(seed: 0))` | n 7; m 6; E [0–1, 0–5, 0–6, 2–4, 3–4, 3–6]; draws 8; = NetworkX |
| RG-087 | StochasticBlockModel | sizes [3, 2] directed | `CompressedSparseRow.stochasticBlockModel(blockSizes: [3, 2], edgeProbabilities: [[0.5, 0.3], [0.1, 0.8]], using: &Xoshiro256StarStar(seed: 0))` | n 5; m 9; E [0→1, 0→2, 0→3, 0→4, 2→1, 2→3, 3→1, 3→2, 4→3]; draws 13; = NetworkX |
| RG-088 | StochasticBlockModel | sizes [0, 4] | `UndirectedAdjacencyList<Int>.stochasticBlockModel(blockSizes: [0, 4], edgeProbabilities: [[0.5, 0.5], [0.5, 0.5]], using: &Xoshiro256StarStar(seed: 0))` | n 4; m 2; E [1–2, 2–3]; draws 5; = NetworkX |
| RG-089 | StochasticBlockModel | asymmetric undirected | `UndirectedAdjacencyList<Int>.stochasticBlockModel(…)` | **trap**: edgeProbabilities is not symmetric |
| RG-090 | StochasticBlockModel | not square | `UndirectedAdjacencyList<Int>.stochasticBlockModel(…)` | **trap**: edgeProbabilities is not blockSizes.count square |
| RG-091 | StochasticBlockModel | probability > 1 | `UndirectedAdjacencyList<Int>.stochasticBlockModel(…)` | **trap**: edge probability 1.5 is not in 0...1 |
| RG-092 | StochasticBlockModel | negative block size | `UndirectedAdjacencyList<Int>.stochasticBlockModel(…)` | **trap**: block size -1 is negative |
| RG-093 | StochasticBlockModel | law: E[m] = Σ pairs(i, j)·p(i, j) | `sizes [30, 20, 50], P [[0.2, 0.01, 0.02], [0.01, 0.3, 0.005], [0.02, 0.005, 0.1]]` | Σ 61462 over seeds 0..<200 (mean 307.3100; expected 307.5000; |z| 0.17 ≤ 4) |
| RG-094 | StochasticBlockModel | p = 0 / 1 blocks need no draws: K5,5 | `UndirectedAdjacencyList<Int>.stochasticBlockModel(blockSizes: [5, 5], edgeProbabilities: [[0, 1], [1, 0]], using: &…)` | m 25; equals completeBipartite(leftCount: 5, rightCount: 5) |
| RG-095 | RandomTree | n 1: Prüfer code of n − 2 draws, decoded by Tree(pruferSequence:) | `Tree<Int>.random(vertexCount: 1, using: &Xoshiro256StarStar(seed: 0))` | n 1; m 0; code []; E []; draws 0; = NetworkX |
| RG-096 | RandomTree | n 2: Prüfer code of n − 2 draws, decoded by Tree(pruferSequence:) | `Tree<Int>.random(vertexCount: 2, using: &Xoshiro256StarStar(seed: 0))` | n 2; m 1; code []; E [0–1]; draws 0; = NetworkX |
| RG-097 | RandomTree | n 6: Prüfer code of n − 2 draws, decoded by Tree(pruferSequence:) | `Tree<Int>.random(vertexCount: 6, using: &Xoshiro256StarStar(seed: 0))` | n 6; m 5; code [4, 5, 0, 3]; E [1–4, 2–5, 4–0, 0–3, 3–5]; draws 4; = NetworkX |
| RG-098 | RandomTree | n 6: Prüfer code of n − 2 draws, decoded by Tree(pruferSequence:) | `Tree<Int>.random(vertexCount: 6, using: &Xoshiro256StarStar(seed: 1))` | n 6; m 5; code [5, 4, 4, 3]; E [0–5, 1–4, 2–4, 4–3, 3–5]; draws 4; = NetworkX |
| RG-099 | RandomTree | n 6: Prüfer code of n − 2 draws, decoded by Tree(pruferSequence:) | `Tree<Int>.random(vertexCount: 6, using: &Xoshiro256StarStar(seed: 42))` | n 6; m 5; code [0, 3, 5, 5]; E [1–0, 0–3, 2–5, 3–5, 4–5]; draws 7; = NetworkX |
| RG-100 | RandomTree | n 10: Prüfer code of n − 2 draws, decoded by Tree(pruferSequence:) | `Tree<Int>.random(vertexCount: 10, using: &Xoshiro256StarStar(seed: 0))` | n 10; m 9; code [9, 1, 6, 6, 8, 1, 1, 1]; E [0–9, 2–1, 3–6, 4–6, 5–8, 6–1, 7–1, 8–1, 1–9]; draws 13; = NetworkX |
| RG-101 | RandomTree | n = 0: a tree is never empty | `Tree<Int>.random(vertexCount: 0, using: &…)` | **trap**: a Tree has at least one vertex |
| RG-102 | RandomTree | law: uniform over the n^(n − 2) labeled trees (Cayley) | `n 4` | 16 outcomes over seeds 0..<3200; χ² 15.80 ≤ 37.697 (df 15, 0.999) |
| RG-103 | RandomTree | laws: n − 1 edges, connected, degree(v) = 1 + occurrences of v in the code | `n 200, seeds 0..<50` | hold for every seed (igraph is_tree) |
| RG-104 | RandomDAG | G(8, 0.4) on pairs u < v, oriented u → v (Barak–Erdős); the order 0..<n is topological | `DirectedAcyclicGraph<AdjacencyList<Int>>.erdosRenyi(vertexCount: 8, edgeProbability: 0.4, using: &Xoshiro256StarStar(seed: 0))` | n 8; m 6; E [0→2, 0→5, 1→3, 1→4, 2→3, 6→7]; draws 7; = NetworkX |
| RG-105 | RandomDAG | G(8, 0.4) on pairs u < v, oriented u → v (Barak–Erdős); the order 0..<n is topological | `DirectedAcyclicGraph<AdjacencyList<Int>>.erdosRenyi(vertexCount: 8, edgeProbability: 0.4, using: &Xoshiro256StarStar(seed: 1))` | n 8; m 11; E [0→4, 0→5, 1→2, 1→3, 1→4, 1→5, 2→5, 2→6, 3→5, 4→6, 4→7]; draws 12; = NetworkX |
| RG-106 | RandomDAG | G(6, 5) on pairs u < v | `DirectedAcyclicGraph<AdjacencyList<Int>>.erdosRenyi(vertexCount: 6, edgeCount: 5, using: &Xoshiro256StarStar(seed: 0))` | n 6; m 5; E [0→3, 0→4, 2→5, 3→5, 4→5]; draws 17; = NetworkX |
| RG-107 | RandomDAG | m > C(n, 2) | `DirectedAcyclicGraph<AdjacencyList<Int>>.erdosRenyi(vertexCount: 4, edgeCount: 7, using: &…)` | **trap**: edgeCount 7 is not in 0...6 |
| RG-108 | RandomDAG | law: E[m] = p·C(n, 2); topologicalOrder == 0..<n | `G(60, 0.1)` | Σ 35309 over seeds 0..<200 (mean 176.5450; expected 177.0000; |z| 0.51 ≤ 4) |
