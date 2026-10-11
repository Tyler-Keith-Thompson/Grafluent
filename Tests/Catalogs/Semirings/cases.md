# Semirings: case catalog (SR-001 – SR-369, 369 rows)

Generated and checked by `ref.py` (`uv run --quiet --no-project --with networkx==3.7 --with
scipy==1.18.1 --with numpy==2.3.4 python3 Tests/Catalogs/Semirings/ref.py`; `--write` regenerates
this file, `--stress` adds random multigraphs). The model implements the definitions in api.md:
the semiring operations with Swift's `Int` (trapping) and `Double` arithmetic, and Dijkstra,
Bellman–Ford, DAG paths, Mohri's DAG shortest distances, Floyd–Warshall and (phase 2) Lehmann's
closure over any semiring. Every algorithm row is recomputed another way: tropical rows against
NetworkX 3.7 and scipy 1.18.1 (`shortest_path` 'D', 'BF', 'FW', `NegativeCycleError`;
`floyd_warshall`, `negative_edge_cycle`), bottleneck and Boolean rows against brute force over
simple paths (and NetworkX `descendants`, `transitive_closure(reflexive=True)`), counting rows
against NetworkX `all_simple_edge_paths` (closed forms 2^k and C(r+c−2, r−1) for the big ones).
Law rows evaluate both sides; the model asserts they are equal. Rows SR-341 – SR-369
are phase 2.

## Notation

**Semiring** is the weight type `S`; the test passes `weight: { S(w[$0]) }` with `w` the raw
values written in the graph, by edge position.

**Graph**: `D[n]:` directed, `U[n]:` undirected (read through `.directed`, each edge u–v giving
arcs u>v and v>u with the edge's position), vertices `0..<n` listed first, then edges in
**position order** as `u>v:w` (`u-v:w`). Weights are raw values of the semiring's scalar:
`Int.max`, `.infinity`, `true`. `Z` / `O` stand for the semiring's `zero` / `one` written out.

| Token | Edges (weights) |
|---|---|
| `ladder(k)` | vertices 0..2k; for i in 0..<k: 2i>2i+1, 2i>2i+2, 2i+1>2i+2 (all 1); 2^k paths from 0 to 2k |
| `grid(r,c)` | vertices `i*c + j`; for each vertex in order the arc right, then down (all 1) |
| `lcg(n,m,s;lo..hi)` | m non-loop pairs over 0..<n from the 64-bit LCG of the Distances catalog seeded s (x ← 6364136223846793005·x + 1442695040888963407 mod 2^64, value x >> 33; u then v, pairs with u == v skipped), then, continuing the same LCG, one weight per pair: lo + value mod (hi − lo + 1); `/q` divides each weight by q (Double rows, exact binary fractions) |
| `dlcg(n,m,s;lo..hi)` | as `lcg`, each pair written low>high (acyclic) |

**Op**: the call on the graph (`DirectedAcyclicGraph(g).` wraps it first). Laws: `a`, `b`, `c` are
`S(value)`; `Int.max - 3` is computed in `Int`. `x ⊕ y` and `x ⊗ y` are the operators, which call
the requirements `x.plus(y)` and `x.times(y)`: the law rows hold for both spellings.

**Expected.** A list is per vertex in `vertices` order: `distance(to:)` for a tree, `—` where it
is `nil` (not reached); `dagShortestDistances` lists `distance(to:)` for every vertex (0̄ where no
path). A matrix lists rows by source, `—` where `distance(from:to:)` is `nil`. `nil` is the
optional result. A path is pinned only when it is the only best path; otherwise its distance and
the number of best simple paths (the test checks the path by the definition). `both X` means both
sides of the law evaluate to X. `≈` values compare within 1e-12 relative. `**trap**` rows are
preconditions; "does not compile" rows are type checks (a `#if false` snippet, or none).

| ID | Group | Case | Semiring | Input | Op | Expected |
|---|---|---|---|---|---|---|
| SR-001 | Constants | zero and one | `TropicalSemiring<Int>` | — | `(.zero, .one)` | (Int.max, 0) |
| SR-002 | Constants | zero and one | `TropicalSemiring<Double>` | — | `(.zero, .one)` | (.infinity, 0.0) |
| SR-003 | Constants | zero and one | `BottleneckSemiring<Int>` | — | `(.zero, .one)` | (Int.min, Int.max) |
| SR-004 | Constants | zero and one | `BottleneckSemiring<Double>` | — | `(.zero, .one)` | (-.infinity, .infinity) |
| SR-005 | Constants | zero and one | `BooleanSemiring` | — | `(.zero, .one)` | (false, true) |
| SR-006 | Constants | zero and one | `CountingSemiring<Int>` | — | `(.zero, .one)` | (0, 1) |
| SR-007 | Constants | zero and one | `CountingSemiring<Double>` | — | `(.zero, .one)` | (0.0, 1.0) |
| SR-008 | Laws | ⊕ is associative | `TropicalSemiring<Int>` | `a = 3, b = -2, c = 7` | `(a ⊕ b) ⊕ c == a ⊕ (b ⊕ c)` | both -2 |
| SR-009 | Laws | ⊕ is associative | `TropicalSemiring<Int>` | `a = 5, b = Int.max, c = 0` | `(a ⊕ b) ⊕ c == a ⊕ (b ⊕ c)` | both 0 |
| SR-010 | Laws | ⊕ is associative | `TropicalSemiring<Int>` | `a = -4, b = -4, c = Int.max` | `(a ⊕ b) ⊕ c == a ⊕ (b ⊕ c)` | both -4 |
| SR-011 | Laws | ⊕ is commutative | `TropicalSemiring<Int>` | `a = 3, b = -2, c = 7` | `a ⊕ b == b ⊕ a` | both -2 |
| SR-012 | Laws | ⊕ is commutative | `TropicalSemiring<Int>` | `a = 5, b = Int.max, c = 0` | `a ⊕ b == b ⊕ a` | both 5 |
| SR-013 | Laws | ⊕ is commutative | `TropicalSemiring<Int>` | `a = -4, b = -4, c = Int.max` | `a ⊕ b == b ⊕ a` | both -4 |
| SR-014 | Laws | zero is ⊕'s identity | `TropicalSemiring<Int>` | `a = 3, b = -2, c = 7` | `a ⊕ .zero == a` | both 3 |
| SR-015 | Laws | zero is ⊕'s identity | `TropicalSemiring<Int>` | `a = 5, b = Int.max, c = 0` | `a ⊕ .zero == a` | both 5 |
| SR-016 | Laws | zero is ⊕'s identity | `TropicalSemiring<Int>` | `a = -4, b = -4, c = Int.max` | `a ⊕ .zero == a` | both -4 |
| SR-017 | Laws | ⊗ is associative | `TropicalSemiring<Int>` | `a = 3, b = -2, c = 7` | `(a ⊗ b) ⊗ c == a ⊗ (b ⊗ c)` | both 8 |
| SR-018 | Laws | ⊗ is associative | `TropicalSemiring<Int>` | `a = 5, b = Int.max, c = 0` | `(a ⊗ b) ⊗ c == a ⊗ (b ⊗ c)` | both Int.max |
| SR-019 | Laws | ⊗ is associative | `TropicalSemiring<Int>` | `a = -4, b = -4, c = Int.max` | `(a ⊗ b) ⊗ c == a ⊗ (b ⊗ c)` | both Int.max |
| SR-020 | Laws | one is ⊗'s identity | `TropicalSemiring<Int>` | `a = 3, b = -2, c = 7` | `.one ⊗ a == a ⊗ .one` | both 3 |
| SR-021 | Laws | one is ⊗'s identity | `TropicalSemiring<Int>` | `a = 5, b = Int.max, c = 0` | `.one ⊗ a == a ⊗ .one` | both 5 |
| SR-022 | Laws | one is ⊗'s identity | `TropicalSemiring<Int>` | `a = -4, b = -4, c = Int.max` | `.one ⊗ a == a ⊗ .one` | both -4 |
| SR-023 | Laws | zero annihilates | `TropicalSemiring<Int>` | `a = 3, b = -2, c = 7` | `.zero ⊗ a == a ⊗ .zero` | both Int.max |
| SR-024 | Laws | zero annihilates | `TropicalSemiring<Int>` | `a = 5, b = Int.max, c = 0` | `.zero ⊗ a == a ⊗ .zero` | both Int.max |
| SR-025 | Laws | zero annihilates | `TropicalSemiring<Int>` | `a = -4, b = -4, c = Int.max` | `.zero ⊗ a == a ⊗ .zero` | both Int.max |
| SR-026 | Laws | ⊗ distributes over ⊕ from the left | `TropicalSemiring<Int>` | `a = 3, b = -2, c = 7` | `a ⊗ (b ⊕ c) == (a ⊗ b) ⊕ (a ⊗ c)` | both 1 |
| SR-027 | Laws | ⊗ distributes over ⊕ from the left | `TropicalSemiring<Int>` | `a = 5, b = Int.max, c = 0` | `a ⊗ (b ⊕ c) == (a ⊗ b) ⊕ (a ⊗ c)` | both 5 |
| SR-028 | Laws | ⊗ distributes over ⊕ from the left | `TropicalSemiring<Int>` | `a = -4, b = -4, c = Int.max` | `a ⊗ (b ⊕ c) == (a ⊗ b) ⊕ (a ⊗ c)` | both -8 |
| SR-029 | Laws | ⊗ distributes over ⊕ from the right | `TropicalSemiring<Int>` | `a = 3, b = -2, c = 7` | `(a ⊕ b) ⊗ c == (a ⊗ c) ⊕ (b ⊗ c)` | both 5 |
| SR-030 | Laws | ⊗ distributes over ⊕ from the right | `TropicalSemiring<Int>` | `a = 5, b = Int.max, c = 0` | `(a ⊕ b) ⊗ c == (a ⊗ c) ⊕ (b ⊗ c)` | both 5 |
| SR-031 | Laws | ⊗ distributes over ⊕ from the right | `TropicalSemiring<Int>` | `a = -4, b = -4, c = Int.max` | `(a ⊕ b) ⊗ c == (a ⊗ c) ⊕ (b ⊗ c)` | both Int.max |
| SR-032 | Laws | ⊗ is commutative (not a requirement) | `TropicalSemiring<Int>` | `a = 3, b = -2, c = 7` | `a ⊗ b == b ⊗ a` | both 1 |
| SR-033 | Laws | ⊗ is commutative (not a requirement) | `TropicalSemiring<Int>` | `a = 5, b = Int.max, c = 0` | `a ⊗ b == b ⊗ a` | both Int.max |
| SR-034 | Laws | ⊗ is commutative (not a requirement) | `TropicalSemiring<Int>` | `a = -4, b = -4, c = Int.max` | `a ⊗ b == b ⊗ a` | both -8 |
| SR-035 | Laws | selective: a ⊕ b is the better by < | `TropicalSemiring<Int>` | `a = 3, b = -2` | `a ⊕ b == (b < a ? b : a)` | true (-2) |
| SR-036 | Laws | idempotent | `TropicalSemiring<Int>` | `a = 3` | `a ⊕ a == a` | true (a ⊕ a = 3) |
| SR-037 | Laws | selective: a ⊕ b is the better by < | `TropicalSemiring<Int>` | `a = 5, b = Int.max` | `a ⊕ b == (b < a ? b : a)` | true (5) |
| SR-038 | Laws | idempotent | `TropicalSemiring<Int>` | `a = 5` | `a ⊕ a == a` | true (a ⊕ a = 5) |
| SR-039 | Laws | selective: a ⊕ b is the better by < | `TropicalSemiring<Int>` | `a = -4, b = -4` | `a ⊕ b == (b < a ? b : a)` | true (-4) |
| SR-040 | Laws | idempotent | `TropicalSemiring<Int>` | `a = -4` | `a ⊕ a == a` | true (a ⊕ a = -4) |
| SR-041 | Order | the natural order: < is ‘better’ | `TropicalSemiring<Int>` | `a = 3, b = -2` | `a < b` | false |
| SR-042 | Order | zero is the greatest (worst) element | `TropicalSemiring<Int>` | `a = 3` | `a < .zero \|\| a == .zero` | true |
| SR-043 | Laws | ⊕ is associative | `TropicalSemiring<Double>` | `a = 1.5, b = -2.25, c = 4.0` | `(a ⊕ b) ⊕ c == a ⊕ (b ⊕ c)` | both -2.25 |
| SR-044 | Laws | ⊕ is associative | `TropicalSemiring<Double>` | `a = .infinity, b = 0.5, c = -3.0` | `(a ⊕ b) ⊕ c == a ⊕ (b ⊕ c)` | both -3.0 |
| SR-045 | Laws | ⊕ is associative | `TropicalSemiring<Double>` | `a = 2.0, b = 2.0, c = .infinity` | `(a ⊕ b) ⊕ c == a ⊕ (b ⊕ c)` | both 2.0 |
| SR-046 | Laws | ⊕ is commutative | `TropicalSemiring<Double>` | `a = 1.5, b = -2.25, c = 4.0` | `a ⊕ b == b ⊕ a` | both -2.25 |
| SR-047 | Laws | ⊕ is commutative | `TropicalSemiring<Double>` | `a = .infinity, b = 0.5, c = -3.0` | `a ⊕ b == b ⊕ a` | both 0.5 |
| SR-048 | Laws | ⊕ is commutative | `TropicalSemiring<Double>` | `a = 2.0, b = 2.0, c = .infinity` | `a ⊕ b == b ⊕ a` | both 2.0 |
| SR-049 | Laws | zero is ⊕'s identity | `TropicalSemiring<Double>` | `a = 1.5, b = -2.25, c = 4.0` | `a ⊕ .zero == a` | both 1.5 |
| SR-050 | Laws | zero is ⊕'s identity | `TropicalSemiring<Double>` | `a = .infinity, b = 0.5, c = -3.0` | `a ⊕ .zero == a` | both .infinity |
| SR-051 | Laws | zero is ⊕'s identity | `TropicalSemiring<Double>` | `a = 2.0, b = 2.0, c = .infinity` | `a ⊕ .zero == a` | both 2.0 |
| SR-052 | Laws | ⊗ is associative | `TropicalSemiring<Double>` | `a = 1.5, b = -2.25, c = 4.0` | `(a ⊗ b) ⊗ c == a ⊗ (b ⊗ c)` | both 3.25 |
| SR-053 | Laws | ⊗ is associative | `TropicalSemiring<Double>` | `a = .infinity, b = 0.5, c = -3.0` | `(a ⊗ b) ⊗ c == a ⊗ (b ⊗ c)` | both .infinity |
| SR-054 | Laws | ⊗ is associative | `TropicalSemiring<Double>` | `a = 2.0, b = 2.0, c = .infinity` | `(a ⊗ b) ⊗ c == a ⊗ (b ⊗ c)` | both .infinity |
| SR-055 | Laws | one is ⊗'s identity | `TropicalSemiring<Double>` | `a = 1.5, b = -2.25, c = 4.0` | `.one ⊗ a == a ⊗ .one` | both 1.5 |
| SR-056 | Laws | one is ⊗'s identity | `TropicalSemiring<Double>` | `a = .infinity, b = 0.5, c = -3.0` | `.one ⊗ a == a ⊗ .one` | both .infinity |
| SR-057 | Laws | one is ⊗'s identity | `TropicalSemiring<Double>` | `a = 2.0, b = 2.0, c = .infinity` | `.one ⊗ a == a ⊗ .one` | both 2.0 |
| SR-058 | Laws | zero annihilates | `TropicalSemiring<Double>` | `a = 1.5, b = -2.25, c = 4.0` | `.zero ⊗ a == a ⊗ .zero` | both .infinity |
| SR-059 | Laws | zero annihilates | `TropicalSemiring<Double>` | `a = .infinity, b = 0.5, c = -3.0` | `.zero ⊗ a == a ⊗ .zero` | both .infinity |
| SR-060 | Laws | zero annihilates | `TropicalSemiring<Double>` | `a = 2.0, b = 2.0, c = .infinity` | `.zero ⊗ a == a ⊗ .zero` | both .infinity |
| SR-061 | Laws | ⊗ distributes over ⊕ from the left | `TropicalSemiring<Double>` | `a = 1.5, b = -2.25, c = 4.0` | `a ⊗ (b ⊕ c) == (a ⊗ b) ⊕ (a ⊗ c)` | both -0.75 |
| SR-062 | Laws | ⊗ distributes over ⊕ from the left | `TropicalSemiring<Double>` | `a = .infinity, b = 0.5, c = -3.0` | `a ⊗ (b ⊕ c) == (a ⊗ b) ⊕ (a ⊗ c)` | both .infinity |
| SR-063 | Laws | ⊗ distributes over ⊕ from the left | `TropicalSemiring<Double>` | `a = 2.0, b = 2.0, c = .infinity` | `a ⊗ (b ⊕ c) == (a ⊗ b) ⊕ (a ⊗ c)` | both 4.0 |
| SR-064 | Laws | ⊗ distributes over ⊕ from the right | `TropicalSemiring<Double>` | `a = 1.5, b = -2.25, c = 4.0` | `(a ⊕ b) ⊗ c == (a ⊗ c) ⊕ (b ⊗ c)` | both 1.75 |
| SR-065 | Laws | ⊗ distributes over ⊕ from the right | `TropicalSemiring<Double>` | `a = .infinity, b = 0.5, c = -3.0` | `(a ⊕ b) ⊗ c == (a ⊗ c) ⊕ (b ⊗ c)` | both -2.5 |
| SR-066 | Laws | ⊗ distributes over ⊕ from the right | `TropicalSemiring<Double>` | `a = 2.0, b = 2.0, c = .infinity` | `(a ⊕ b) ⊗ c == (a ⊗ c) ⊕ (b ⊗ c)` | both .infinity |
| SR-067 | Laws | ⊗ is commutative (not a requirement) | `TropicalSemiring<Double>` | `a = 1.5, b = -2.25, c = 4.0` | `a ⊗ b == b ⊗ a` | both -0.75 |
| SR-068 | Laws | ⊗ is commutative (not a requirement) | `TropicalSemiring<Double>` | `a = .infinity, b = 0.5, c = -3.0` | `a ⊗ b == b ⊗ a` | both .infinity |
| SR-069 | Laws | ⊗ is commutative (not a requirement) | `TropicalSemiring<Double>` | `a = 2.0, b = 2.0, c = .infinity` | `a ⊗ b == b ⊗ a` | both 4.0 |
| SR-070 | Laws | selective: a ⊕ b is the better by < | `TropicalSemiring<Double>` | `a = 1.5, b = -2.25` | `a ⊕ b == (b < a ? b : a)` | true (-2.25) |
| SR-071 | Laws | idempotent | `TropicalSemiring<Double>` | `a = 1.5` | `a ⊕ a == a` | true (a ⊕ a = 1.5) |
| SR-072 | Laws | selective: a ⊕ b is the better by < | `TropicalSemiring<Double>` | `a = .infinity, b = 0.5` | `a ⊕ b == (b < a ? b : a)` | true (0.5) |
| SR-073 | Laws | idempotent | `TropicalSemiring<Double>` | `a = .infinity` | `a ⊕ a == a` | true (a ⊕ a = .infinity) |
| SR-074 | Laws | selective: a ⊕ b is the better by < | `TropicalSemiring<Double>` | `a = 2.0, b = 2.0` | `a ⊕ b == (b < a ? b : a)` | true (2.0) |
| SR-075 | Laws | idempotent | `TropicalSemiring<Double>` | `a = 2.0` | `a ⊕ a == a` | true (a ⊕ a = 2.0) |
| SR-076 | Order | the natural order: < is ‘better’ | `TropicalSemiring<Double>` | `a = 1.5, b = -2.25` | `a < b` | false |
| SR-077 | Order | zero is the greatest (worst) element | `TropicalSemiring<Double>` | `a = 1.5` | `a < .zero \|\| a == .zero` | true |
| SR-078 | Laws | ⊕ is associative | `BottleneckSemiring<Int>` | `a = 3, b = -2, c = 7` | `(a ⊕ b) ⊕ c == a ⊕ (b ⊕ c)` | both 7 |
| SR-079 | Laws | ⊕ is associative | `BottleneckSemiring<Int>` | `a = Int.min, b = Int.max, c = 5` | `(a ⊕ b) ⊕ c == a ⊕ (b ⊕ c)` | both Int.max |
| SR-080 | Laws | ⊕ is associative | `BottleneckSemiring<Int>` | `a = 4, b = 4, c = Int.min` | `(a ⊕ b) ⊕ c == a ⊕ (b ⊕ c)` | both 4 |
| SR-081 | Laws | ⊕ is commutative | `BottleneckSemiring<Int>` | `a = 3, b = -2, c = 7` | `a ⊕ b == b ⊕ a` | both 3 |
| SR-082 | Laws | ⊕ is commutative | `BottleneckSemiring<Int>` | `a = Int.min, b = Int.max, c = 5` | `a ⊕ b == b ⊕ a` | both Int.max |
| SR-083 | Laws | ⊕ is commutative | `BottleneckSemiring<Int>` | `a = 4, b = 4, c = Int.min` | `a ⊕ b == b ⊕ a` | both 4 |
| SR-084 | Laws | zero is ⊕'s identity | `BottleneckSemiring<Int>` | `a = 3, b = -2, c = 7` | `a ⊕ .zero == a` | both 3 |
| SR-085 | Laws | zero is ⊕'s identity | `BottleneckSemiring<Int>` | `a = Int.min, b = Int.max, c = 5` | `a ⊕ .zero == a` | both Int.min |
| SR-086 | Laws | zero is ⊕'s identity | `BottleneckSemiring<Int>` | `a = 4, b = 4, c = Int.min` | `a ⊕ .zero == a` | both 4 |
| SR-087 | Laws | ⊗ is associative | `BottleneckSemiring<Int>` | `a = 3, b = -2, c = 7` | `(a ⊗ b) ⊗ c == a ⊗ (b ⊗ c)` | both -2 |
| SR-088 | Laws | ⊗ is associative | `BottleneckSemiring<Int>` | `a = Int.min, b = Int.max, c = 5` | `(a ⊗ b) ⊗ c == a ⊗ (b ⊗ c)` | both Int.min |
| SR-089 | Laws | ⊗ is associative | `BottleneckSemiring<Int>` | `a = 4, b = 4, c = Int.min` | `(a ⊗ b) ⊗ c == a ⊗ (b ⊗ c)` | both Int.min |
| SR-090 | Laws | one is ⊗'s identity | `BottleneckSemiring<Int>` | `a = 3, b = -2, c = 7` | `.one ⊗ a == a ⊗ .one` | both 3 |
| SR-091 | Laws | one is ⊗'s identity | `BottleneckSemiring<Int>` | `a = Int.min, b = Int.max, c = 5` | `.one ⊗ a == a ⊗ .one` | both Int.min |
| SR-092 | Laws | one is ⊗'s identity | `BottleneckSemiring<Int>` | `a = 4, b = 4, c = Int.min` | `.one ⊗ a == a ⊗ .one` | both 4 |
| SR-093 | Laws | zero annihilates | `BottleneckSemiring<Int>` | `a = 3, b = -2, c = 7` | `.zero ⊗ a == a ⊗ .zero` | both Int.min |
| SR-094 | Laws | zero annihilates | `BottleneckSemiring<Int>` | `a = Int.min, b = Int.max, c = 5` | `.zero ⊗ a == a ⊗ .zero` | both Int.min |
| SR-095 | Laws | zero annihilates | `BottleneckSemiring<Int>` | `a = 4, b = 4, c = Int.min` | `.zero ⊗ a == a ⊗ .zero` | both Int.min |
| SR-096 | Laws | ⊗ distributes over ⊕ from the left | `BottleneckSemiring<Int>` | `a = 3, b = -2, c = 7` | `a ⊗ (b ⊕ c) == (a ⊗ b) ⊕ (a ⊗ c)` | both 3 |
| SR-097 | Laws | ⊗ distributes over ⊕ from the left | `BottleneckSemiring<Int>` | `a = Int.min, b = Int.max, c = 5` | `a ⊗ (b ⊕ c) == (a ⊗ b) ⊕ (a ⊗ c)` | both Int.min |
| SR-098 | Laws | ⊗ distributes over ⊕ from the left | `BottleneckSemiring<Int>` | `a = 4, b = 4, c = Int.min` | `a ⊗ (b ⊕ c) == (a ⊗ b) ⊕ (a ⊗ c)` | both 4 |
| SR-099 | Laws | ⊗ distributes over ⊕ from the right | `BottleneckSemiring<Int>` | `a = 3, b = -2, c = 7` | `(a ⊕ b) ⊗ c == (a ⊗ c) ⊕ (b ⊗ c)` | both 3 |
| SR-100 | Laws | ⊗ distributes over ⊕ from the right | `BottleneckSemiring<Int>` | `a = Int.min, b = Int.max, c = 5` | `(a ⊕ b) ⊗ c == (a ⊗ c) ⊕ (b ⊗ c)` | both 5 |
| SR-101 | Laws | ⊗ distributes over ⊕ from the right | `BottleneckSemiring<Int>` | `a = 4, b = 4, c = Int.min` | `(a ⊕ b) ⊗ c == (a ⊗ c) ⊕ (b ⊗ c)` | both Int.min |
| SR-102 | Laws | ⊗ is commutative (not a requirement) | `BottleneckSemiring<Int>` | `a = 3, b = -2, c = 7` | `a ⊗ b == b ⊗ a` | both -2 |
| SR-103 | Laws | ⊗ is commutative (not a requirement) | `BottleneckSemiring<Int>` | `a = Int.min, b = Int.max, c = 5` | `a ⊗ b == b ⊗ a` | both Int.min |
| SR-104 | Laws | ⊗ is commutative (not a requirement) | `BottleneckSemiring<Int>` | `a = 4, b = 4, c = Int.min` | `a ⊗ b == b ⊗ a` | both 4 |
| SR-105 | Laws | selective: a ⊕ b is the better by < | `BottleneckSemiring<Int>` | `a = 3, b = -2` | `a ⊕ b == (b < a ? b : a)` | true (3) |
| SR-106 | Laws | idempotent | `BottleneckSemiring<Int>` | `a = 3` | `a ⊕ a == a` | true (a ⊕ a = 3) |
| SR-107 | Laws | selective: a ⊕ b is the better by < | `BottleneckSemiring<Int>` | `a = Int.min, b = Int.max` | `a ⊕ b == (b < a ? b : a)` | true (Int.max) |
| SR-108 | Laws | idempotent | `BottleneckSemiring<Int>` | `a = Int.min` | `a ⊕ a == a` | true (a ⊕ a = Int.min) |
| SR-109 | Laws | selective: a ⊕ b is the better by < | `BottleneckSemiring<Int>` | `a = 4, b = 4` | `a ⊕ b == (b < a ? b : a)` | true (4) |
| SR-110 | Laws | idempotent | `BottleneckSemiring<Int>` | `a = 4` | `a ⊕ a == a` | true (a ⊕ a = 4) |
| SR-111 | Order | the natural order: < is ‘better’ | `BottleneckSemiring<Int>` | `a = 3, b = -2` | `a < b` | true |
| SR-112 | Order | zero is the greatest (worst) element | `BottleneckSemiring<Int>` | `a = 3` | `a < .zero \|\| a == .zero` | true |
| SR-113 | Laws | ⊕ is associative | `BottleneckSemiring<Double>` | `a = 1.5, b = -2.25, c = 4.0` | `(a ⊕ b) ⊕ c == a ⊕ (b ⊕ c)` | both 4.0 |
| SR-114 | Laws | ⊕ is associative | `BottleneckSemiring<Double>` | `a = -.infinity, b = .infinity, c = 0.5` | `(a ⊕ b) ⊕ c == a ⊕ (b ⊕ c)` | both .infinity |
| SR-115 | Laws | ⊕ is commutative | `BottleneckSemiring<Double>` | `a = 1.5, b = -2.25, c = 4.0` | `a ⊕ b == b ⊕ a` | both 1.5 |
| SR-116 | Laws | ⊕ is commutative | `BottleneckSemiring<Double>` | `a = -.infinity, b = .infinity, c = 0.5` | `a ⊕ b == b ⊕ a` | both .infinity |
| SR-117 | Laws | zero is ⊕'s identity | `BottleneckSemiring<Double>` | `a = 1.5, b = -2.25, c = 4.0` | `a ⊕ .zero == a` | both 1.5 |
| SR-118 | Laws | zero is ⊕'s identity | `BottleneckSemiring<Double>` | `a = -.infinity, b = .infinity, c = 0.5` | `a ⊕ .zero == a` | both -.infinity |
| SR-119 | Laws | ⊗ is associative | `BottleneckSemiring<Double>` | `a = 1.5, b = -2.25, c = 4.0` | `(a ⊗ b) ⊗ c == a ⊗ (b ⊗ c)` | both -2.25 |
| SR-120 | Laws | ⊗ is associative | `BottleneckSemiring<Double>` | `a = -.infinity, b = .infinity, c = 0.5` | `(a ⊗ b) ⊗ c == a ⊗ (b ⊗ c)` | both -.infinity |
| SR-121 | Laws | one is ⊗'s identity | `BottleneckSemiring<Double>` | `a = 1.5, b = -2.25, c = 4.0` | `.one ⊗ a == a ⊗ .one` | both 1.5 |
| SR-122 | Laws | one is ⊗'s identity | `BottleneckSemiring<Double>` | `a = -.infinity, b = .infinity, c = 0.5` | `.one ⊗ a == a ⊗ .one` | both -.infinity |
| SR-123 | Laws | zero annihilates | `BottleneckSemiring<Double>` | `a = 1.5, b = -2.25, c = 4.0` | `.zero ⊗ a == a ⊗ .zero` | both -.infinity |
| SR-124 | Laws | zero annihilates | `BottleneckSemiring<Double>` | `a = -.infinity, b = .infinity, c = 0.5` | `.zero ⊗ a == a ⊗ .zero` | both -.infinity |
| SR-125 | Laws | ⊗ distributes over ⊕ from the left | `BottleneckSemiring<Double>` | `a = 1.5, b = -2.25, c = 4.0` | `a ⊗ (b ⊕ c) == (a ⊗ b) ⊕ (a ⊗ c)` | both 1.5 |
| SR-126 | Laws | ⊗ distributes over ⊕ from the left | `BottleneckSemiring<Double>` | `a = -.infinity, b = .infinity, c = 0.5` | `a ⊗ (b ⊕ c) == (a ⊗ b) ⊕ (a ⊗ c)` | both -.infinity |
| SR-127 | Laws | ⊗ distributes over ⊕ from the right | `BottleneckSemiring<Double>` | `a = 1.5, b = -2.25, c = 4.0` | `(a ⊕ b) ⊗ c == (a ⊗ c) ⊕ (b ⊗ c)` | both 1.5 |
| SR-128 | Laws | ⊗ distributes over ⊕ from the right | `BottleneckSemiring<Double>` | `a = -.infinity, b = .infinity, c = 0.5` | `(a ⊕ b) ⊗ c == (a ⊗ c) ⊕ (b ⊗ c)` | both 0.5 |
| SR-129 | Laws | ⊗ is commutative (not a requirement) | `BottleneckSemiring<Double>` | `a = 1.5, b = -2.25, c = 4.0` | `a ⊗ b == b ⊗ a` | both -2.25 |
| SR-130 | Laws | ⊗ is commutative (not a requirement) | `BottleneckSemiring<Double>` | `a = -.infinity, b = .infinity, c = 0.5` | `a ⊗ b == b ⊗ a` | both -.infinity |
| SR-131 | Laws | selective: a ⊕ b is the better by < | `BottleneckSemiring<Double>` | `a = 1.5, b = -2.25` | `a ⊕ b == (b < a ? b : a)` | true (1.5) |
| SR-132 | Laws | idempotent | `BottleneckSemiring<Double>` | `a = 1.5` | `a ⊕ a == a` | true (a ⊕ a = 1.5) |
| SR-133 | Laws | selective: a ⊕ b is the better by < | `BottleneckSemiring<Double>` | `a = -.infinity, b = .infinity` | `a ⊕ b == (b < a ? b : a)` | true (.infinity) |
| SR-134 | Laws | idempotent | `BottleneckSemiring<Double>` | `a = -.infinity` | `a ⊕ a == a` | true (a ⊕ a = -.infinity) |
| SR-135 | Order | the natural order: < is ‘better’ | `BottleneckSemiring<Double>` | `a = 1.5, b = -2.25` | `a < b` | true |
| SR-136 | Order | zero is the greatest (worst) element | `BottleneckSemiring<Double>` | `a = 1.5` | `a < .zero \|\| a == .zero` | true |
| SR-137 | Laws | ⊕ is associative | `BooleanSemiring` | `a = true, b = false, c = true` | `(a ⊕ b) ⊕ c == a ⊕ (b ⊕ c)` | both true |
| SR-138 | Laws | ⊕ is associative | `BooleanSemiring` | `a = false, b = false, c = true` | `(a ⊕ b) ⊕ c == a ⊕ (b ⊕ c)` | both true |
| SR-139 | Laws | ⊕ is commutative | `BooleanSemiring` | `a = true, b = false, c = true` | `a ⊕ b == b ⊕ a` | both true |
| SR-140 | Laws | ⊕ is commutative | `BooleanSemiring` | `a = false, b = false, c = true` | `a ⊕ b == b ⊕ a` | both false |
| SR-141 | Laws | zero is ⊕'s identity | `BooleanSemiring` | `a = true, b = false, c = true` | `a ⊕ .zero == a` | both true |
| SR-142 | Laws | zero is ⊕'s identity | `BooleanSemiring` | `a = false, b = false, c = true` | `a ⊕ .zero == a` | both false |
| SR-143 | Laws | ⊗ is associative | `BooleanSemiring` | `a = true, b = false, c = true` | `(a ⊗ b) ⊗ c == a ⊗ (b ⊗ c)` | both false |
| SR-144 | Laws | ⊗ is associative | `BooleanSemiring` | `a = false, b = false, c = true` | `(a ⊗ b) ⊗ c == a ⊗ (b ⊗ c)` | both false |
| SR-145 | Laws | one is ⊗'s identity | `BooleanSemiring` | `a = true, b = false, c = true` | `.one ⊗ a == a ⊗ .one` | both true |
| SR-146 | Laws | one is ⊗'s identity | `BooleanSemiring` | `a = false, b = false, c = true` | `.one ⊗ a == a ⊗ .one` | both false |
| SR-147 | Laws | zero annihilates | `BooleanSemiring` | `a = true, b = false, c = true` | `.zero ⊗ a == a ⊗ .zero` | both false |
| SR-148 | Laws | zero annihilates | `BooleanSemiring` | `a = false, b = false, c = true` | `.zero ⊗ a == a ⊗ .zero` | both false |
| SR-149 | Laws | ⊗ distributes over ⊕ from the left | `BooleanSemiring` | `a = true, b = false, c = true` | `a ⊗ (b ⊕ c) == (a ⊗ b) ⊕ (a ⊗ c)` | both true |
| SR-150 | Laws | ⊗ distributes over ⊕ from the left | `BooleanSemiring` | `a = false, b = false, c = true` | `a ⊗ (b ⊕ c) == (a ⊗ b) ⊕ (a ⊗ c)` | both false |
| SR-151 | Laws | ⊗ distributes over ⊕ from the right | `BooleanSemiring` | `a = true, b = false, c = true` | `(a ⊕ b) ⊗ c == (a ⊗ c) ⊕ (b ⊗ c)` | both true |
| SR-152 | Laws | ⊗ distributes over ⊕ from the right | `BooleanSemiring` | `a = false, b = false, c = true` | `(a ⊕ b) ⊗ c == (a ⊗ c) ⊕ (b ⊗ c)` | both false |
| SR-153 | Laws | ⊗ is commutative (not a requirement) | `BooleanSemiring` | `a = true, b = false, c = true` | `a ⊗ b == b ⊗ a` | both false |
| SR-154 | Laws | ⊗ is commutative (not a requirement) | `BooleanSemiring` | `a = false, b = false, c = true` | `a ⊗ b == b ⊗ a` | both false |
| SR-155 | Laws | selective: a ⊕ b is the better by < | `BooleanSemiring` | `a = true, b = false` | `a ⊕ b == (b < a ? b : a)` | true (true) |
| SR-156 | Laws | idempotent | `BooleanSemiring` | `a = true` | `a ⊕ a == a` | true (a ⊕ a = true) |
| SR-157 | Laws | selective: a ⊕ b is the better by < | `BooleanSemiring` | `a = false, b = false` | `a ⊕ b == (b < a ? b : a)` | true (false) |
| SR-158 | Laws | idempotent | `BooleanSemiring` | `a = false` | `a ⊕ a == a` | true (a ⊕ a = false) |
| SR-159 | Order | the natural order: < is ‘better’ | `BooleanSemiring` | `a = true, b = false` | `a < b` | true |
| SR-160 | Order | zero is the greatest (worst) element | `BooleanSemiring` | `a = true` | `a < .zero \|\| a == .zero` | true |
| SR-161 | Laws | ⊕ is associative | `CountingSemiring<Int>` | `a = 3, b = -2, c = 7` | `(a ⊕ b) ⊕ c == a ⊕ (b ⊕ c)` | both 8 |
| SR-162 | Laws | ⊕ is associative | `CountingSemiring<Int>` | `a = 0, b = 1, c = 5` | `(a ⊕ b) ⊕ c == a ⊕ (b ⊕ c)` | both 6 |
| SR-163 | Laws | ⊕ is associative | `CountingSemiring<Int>` | `a = 6, b = 6, c = -1` | `(a ⊕ b) ⊕ c == a ⊕ (b ⊕ c)` | both 11 |
| SR-164 | Laws | ⊕ is commutative | `CountingSemiring<Int>` | `a = 3, b = -2, c = 7` | `a ⊕ b == b ⊕ a` | both 1 |
| SR-165 | Laws | ⊕ is commutative | `CountingSemiring<Int>` | `a = 0, b = 1, c = 5` | `a ⊕ b == b ⊕ a` | both 1 |
| SR-166 | Laws | ⊕ is commutative | `CountingSemiring<Int>` | `a = 6, b = 6, c = -1` | `a ⊕ b == b ⊕ a` | both 12 |
| SR-167 | Laws | zero is ⊕'s identity | `CountingSemiring<Int>` | `a = 3, b = -2, c = 7` | `a ⊕ .zero == a` | both 3 |
| SR-168 | Laws | zero is ⊕'s identity | `CountingSemiring<Int>` | `a = 0, b = 1, c = 5` | `a ⊕ .zero == a` | both 0 |
| SR-169 | Laws | zero is ⊕'s identity | `CountingSemiring<Int>` | `a = 6, b = 6, c = -1` | `a ⊕ .zero == a` | both 6 |
| SR-170 | Laws | ⊗ is associative | `CountingSemiring<Int>` | `a = 3, b = -2, c = 7` | `(a ⊗ b) ⊗ c == a ⊗ (b ⊗ c)` | both -42 |
| SR-171 | Laws | ⊗ is associative | `CountingSemiring<Int>` | `a = 0, b = 1, c = 5` | `(a ⊗ b) ⊗ c == a ⊗ (b ⊗ c)` | both 0 |
| SR-172 | Laws | ⊗ is associative | `CountingSemiring<Int>` | `a = 6, b = 6, c = -1` | `(a ⊗ b) ⊗ c == a ⊗ (b ⊗ c)` | both -36 |
| SR-173 | Laws | one is ⊗'s identity | `CountingSemiring<Int>` | `a = 3, b = -2, c = 7` | `.one ⊗ a == a ⊗ .one` | both 3 |
| SR-174 | Laws | one is ⊗'s identity | `CountingSemiring<Int>` | `a = 0, b = 1, c = 5` | `.one ⊗ a == a ⊗ .one` | both 0 |
| SR-175 | Laws | one is ⊗'s identity | `CountingSemiring<Int>` | `a = 6, b = 6, c = -1` | `.one ⊗ a == a ⊗ .one` | both 6 |
| SR-176 | Laws | zero annihilates | `CountingSemiring<Int>` | `a = 3, b = -2, c = 7` | `.zero ⊗ a == a ⊗ .zero` | both 0 |
| SR-177 | Laws | zero annihilates | `CountingSemiring<Int>` | `a = 0, b = 1, c = 5` | `.zero ⊗ a == a ⊗ .zero` | both 0 |
| SR-178 | Laws | zero annihilates | `CountingSemiring<Int>` | `a = 6, b = 6, c = -1` | `.zero ⊗ a == a ⊗ .zero` | both 0 |
| SR-179 | Laws | ⊗ distributes over ⊕ from the left | `CountingSemiring<Int>` | `a = 3, b = -2, c = 7` | `a ⊗ (b ⊕ c) == (a ⊗ b) ⊕ (a ⊗ c)` | both 15 |
| SR-180 | Laws | ⊗ distributes over ⊕ from the left | `CountingSemiring<Int>` | `a = 0, b = 1, c = 5` | `a ⊗ (b ⊕ c) == (a ⊗ b) ⊕ (a ⊗ c)` | both 0 |
| SR-181 | Laws | ⊗ distributes over ⊕ from the left | `CountingSemiring<Int>` | `a = 6, b = 6, c = -1` | `a ⊗ (b ⊕ c) == (a ⊗ b) ⊕ (a ⊗ c)` | both 30 |
| SR-182 | Laws | ⊗ distributes over ⊕ from the right | `CountingSemiring<Int>` | `a = 3, b = -2, c = 7` | `(a ⊕ b) ⊗ c == (a ⊗ c) ⊕ (b ⊗ c)` | both 7 |
| SR-183 | Laws | ⊗ distributes over ⊕ from the right | `CountingSemiring<Int>` | `a = 0, b = 1, c = 5` | `(a ⊕ b) ⊗ c == (a ⊗ c) ⊕ (b ⊗ c)` | both 5 |
| SR-184 | Laws | ⊗ distributes over ⊕ from the right | `CountingSemiring<Int>` | `a = 6, b = 6, c = -1` | `(a ⊕ b) ⊗ c == (a ⊗ c) ⊕ (b ⊗ c)` | both -12 |
| SR-185 | Laws | ⊗ is commutative (not a requirement) | `CountingSemiring<Int>` | `a = 3, b = -2, c = 7` | `a ⊗ b == b ⊗ a` | both -6 |
| SR-186 | Laws | ⊗ is commutative (not a requirement) | `CountingSemiring<Int>` | `a = 0, b = 1, c = 5` | `a ⊗ b == b ⊗ a` | both 0 |
| SR-187 | Laws | ⊗ is commutative (not a requirement) | `CountingSemiring<Int>` | `a = 6, b = 6, c = -1` | `a ⊗ b == b ⊗ a` | both 36 |
| SR-188 | Laws | not idempotent | `CountingSemiring<Int>` | `a = 3` | `a ⊕ a == a` | false (a ⊕ a = 6) |
| SR-189 | Laws | ⊕ is associative | `CountingSemiring<Double>` | `a = 1.5, b = -2.25, c = 4.0` | `(a ⊕ b) ⊕ c == a ⊕ (b ⊕ c)` | both 3.25 |
| SR-190 | Laws | ⊕ is associative | `CountingSemiring<Double>` | `a = 0.0, b = 1.0, c = 0.5` | `(a ⊕ b) ⊕ c == a ⊕ (b ⊕ c)` | both 1.5 |
| SR-191 | Laws | ⊕ is commutative | `CountingSemiring<Double>` | `a = 1.5, b = -2.25, c = 4.0` | `a ⊕ b == b ⊕ a` | both -0.75 |
| SR-192 | Laws | ⊕ is commutative | `CountingSemiring<Double>` | `a = 0.0, b = 1.0, c = 0.5` | `a ⊕ b == b ⊕ a` | both 1.0 |
| SR-193 | Laws | zero is ⊕'s identity | `CountingSemiring<Double>` | `a = 1.5, b = -2.25, c = 4.0` | `a ⊕ .zero == a` | both 1.5 |
| SR-194 | Laws | zero is ⊕'s identity | `CountingSemiring<Double>` | `a = 0.0, b = 1.0, c = 0.5` | `a ⊕ .zero == a` | both 0.0 |
| SR-195 | Laws | ⊗ is associative | `CountingSemiring<Double>` | `a = 1.5, b = -2.25, c = 4.0` | `(a ⊗ b) ⊗ c == a ⊗ (b ⊗ c)` | both -13.5 |
| SR-196 | Laws | ⊗ is associative | `CountingSemiring<Double>` | `a = 0.0, b = 1.0, c = 0.5` | `(a ⊗ b) ⊗ c == a ⊗ (b ⊗ c)` | both 0.0 |
| SR-197 | Laws | one is ⊗'s identity | `CountingSemiring<Double>` | `a = 1.5, b = -2.25, c = 4.0` | `.one ⊗ a == a ⊗ .one` | both 1.5 |
| SR-198 | Laws | one is ⊗'s identity | `CountingSemiring<Double>` | `a = 0.0, b = 1.0, c = 0.5` | `.one ⊗ a == a ⊗ .one` | both 0.0 |
| SR-199 | Laws | zero annihilates | `CountingSemiring<Double>` | `a = 1.5, b = -2.25, c = 4.0` | `.zero ⊗ a == a ⊗ .zero` | both 0.0 |
| SR-200 | Laws | zero annihilates | `CountingSemiring<Double>` | `a = 0.0, b = 1.0, c = 0.5` | `.zero ⊗ a == a ⊗ .zero` | both 0.0 |
| SR-201 | Laws | ⊗ distributes over ⊕ from the left | `CountingSemiring<Double>` | `a = 1.5, b = -2.25, c = 4.0` | `a ⊗ (b ⊕ c) == (a ⊗ b) ⊕ (a ⊗ c)` | both 2.625 |
| SR-202 | Laws | ⊗ distributes over ⊕ from the left | `CountingSemiring<Double>` | `a = 0.0, b = 1.0, c = 0.5` | `a ⊗ (b ⊕ c) == (a ⊗ b) ⊕ (a ⊗ c)` | both 0.0 |
| SR-203 | Laws | ⊗ distributes over ⊕ from the right | `CountingSemiring<Double>` | `a = 1.5, b = -2.25, c = 4.0` | `(a ⊕ b) ⊗ c == (a ⊗ c) ⊕ (b ⊗ c)` | both -3.0 |
| SR-204 | Laws | ⊗ distributes over ⊕ from the right | `CountingSemiring<Double>` | `a = 0.0, b = 1.0, c = 0.5` | `(a ⊕ b) ⊗ c == (a ⊗ c) ⊕ (b ⊗ c)` | both 0.5 |
| SR-205 | Laws | ⊗ is commutative (not a requirement) | `CountingSemiring<Double>` | `a = 1.5, b = -2.25, c = 4.0` | `a ⊗ b == b ⊗ a` | both -3.375 |
| SR-206 | Laws | ⊗ is commutative (not a requirement) | `CountingSemiring<Double>` | `a = 0.0, b = 1.0, c = 0.5` | `a ⊗ b == b ⊗ a` | both 0.0 |
| SR-207 | Laws | not idempotent | `CountingSemiring<Double>` | `a = 1.5` | `a ⊕ a == a` | false (a ⊕ a = 3.0) |
| SR-208 | Arithmetic | Int.max is zero: absorbing, never added | `TropicalSemiring<Int>` | `a = Int.max, b = -5` | `a ⊗ b` | Int.max |
| SR-209 | Arithmetic | a finite sum reaching Int.max is zero (Boost's closed_plus) | `TropicalSemiring<Int>` | `a = Int.max - 3, b = 3` | `a ⊗ b` | Int.max |
| SR-210 | Arithmetic | overflow traps | `TropicalSemiring<Int>` | `a = Int.max - 3, b = 4` | `a ⊗ b` | **trap** (overflow) |
| SR-211 | Arithmetic | negative overflow traps | `TropicalSemiring<Int>` | `a = Int.min + 3, b = -4` | `a ⊗ b` | **trap** (overflow) |
| SR-212 | Arithmetic | infinity absorbs | `TropicalSemiring<Double>` | `a = .infinity, b = -1e308` | `a ⊗ b` | .infinity |
| SR-213 | Arithmetic | no overflow: min of extremes | `BottleneckSemiring<Int>` | `a = Int.min, b = Int.max` | `a ⊗ b` | Int.min |
| SR-214 | Arithmetic | ⊕ overflow traps | `CountingSemiring<Int>` | `a = Int.max, b = 1` | `a ⊕ b` | **trap** (overflow) |
| SR-215 | Arithmetic | ⊗ overflow traps | `CountingSemiring<Int>` | `a = 4294967296, b = 2147483648` | `a ⊗ b` | **trap** (overflow) |
| SR-216 | Arithmetic | the largest product that fits | `CountingSemiring<Int>` | `a = 4294967296, b = 2147483647` | `a ⊗ b` | 9223372032559808512 |
| SR-217 | Arithmetic | Double counts round instead | `CountingSemiring<Double>` | `a = 9007199254740992.0, b = 1.0` | `a ⊕ b` | 9007199254740992.0 |
| SR-218 | Dijkstra | small digraph, an isolated vertex | `TropicalSemiring<Int>` | `D[5]: 0>1:4, 0>2:1, 2>1:2, 1>3:1, 2>3:5` | `dijkstraShortestPaths(from: 0)` | [0, 3, 1, 4, —] |
| SR-219 | Dijkstra | parallel edges, a loop and a cycle | `TropicalSemiring<Int>` | `D[3]: 0>1:5, 0>1:2, 1>1:3, 1>2:4, 2>0:1` | `dijkstraShortestPaths(from: 0)` | [0, 2, 6] |
| SR-220 | Dijkstra | undirected through .directed | `TropicalSemiring<Int>` | `U[4]: 0-1:2, 1-2:7, 2-3:1, 0-3:9` | `dijkstraShortestPaths(from: 0)` | [0, 2, 9, 9] |
| SR-221 | Dijkstra | several sources | `TropicalSemiring<Int>` | `D[5]: 0>1:4, 0>2:1, 2>1:2, 1>3:1, 2>3:5` | `dijkstraShortestPaths(from: [3, 2])` | [—, 2, 0, 0, —] |
| SR-222 | Dijkstra | cutoff (not worse than) | `TropicalSemiring<Int>` | `D[5]: 0>1:4, 0>2:1, 2>1:2, 1>3:1, 2>3:5` | `dijkstraShortestPaths(from: 0, cutoff: 3)` | [0, 3, 1, —, —] |
| SR-223 | Dijkstra | a negative examined weight traps | `TropicalSemiring<Int>` | `D[4]: 0>1:-2, 0>2:3, 1>2:4, 1>3:-1, 2>3:-6` | `dijkstraShortestPaths(from: 0)` | **trap** (a weight is better than one) |
| SR-224 | Dijkstra | an edge of weight zero reaches nothing | `TropicalSemiring<Int>` | `D[3]: 0>1:Z, 1>2:O` | `dijkstraShortestPaths(from: 0)` | [0, —, —] |
| SR-225 | Dijkstra | one path | `TropicalSemiring<Int>` | `D[5]: 0>1:4, 0>2:1, 2>1:2, 1>3:1, 2>3:5` | `dijkstraShortestPath(from: 0, to: 3)` | vertices [0, 2, 1, 3], edges [1, 2, 3], distance 4 |
| SR-226 | Dijkstra | no path | `TropicalSemiring<Int>` | `D[5]: 0>1:4, 0>2:1, 2>1:2, 1>3:1, 2>3:5` | `dijkstraShortestPath(from: 0, to: 4)` | nil |
| SR-227 | Bellman–Ford | negative weights | `TropicalSemiring<Int>` | `D[4]: 0>1:-2, 0>2:3, 1>2:4, 1>3:-1, 2>3:-6` | `bellmanFordShortestPaths(from: 0)` | [0, -2, 2, -4] |
| SR-228 | Bellman–Ford | a reachable negative cycle | `TropicalSemiring<Int>` | `D[4]: 0>1:1, 1>2:-3, 2>1:1, 2>3:2` | `bellmanFordShortestPaths(from: 0)` | nil |
| SR-229 | Bellman–Ford | a negative cycle not reachable | `TropicalSemiring<Int>` | `D[4]: 0>1:1, 1>2:-3, 2>1:1, 2>3:2` | `bellmanFordShortestPaths(from: 3)` | [—, —, —, 0] |
| SR-230 | Bellman–Ford | parallel edges, a loop and a cycle | `TropicalSemiring<Int>` | `D[3]: 0>1:5, 0>1:2, 1>1:3, 1>2:4, 2>0:1` | `bellmanFordShortestPaths(from: 0)` | [0, 2, 6] |
| SR-231 | DAG | negative weights | `TropicalSemiring<Int>` | `D[4]: 0>1:-2, 0>2:3, 1>2:4, 1>3:-1, 2>3:-6` | `dagShortestPaths(from: 0)` | [0, -2, 2, -4] |
| SR-232 | DAG | a reachable cycle | `TropicalSemiring<Int>` | `D[3]: 0>1:5, 0>1:2, 1>1:3, 1>2:4, 2>0:1` | `dagShortestPaths(from: 0)` | nil |
| SR-233 | DAG | the maintained order (DirectedAcyclicGraph) | `TropicalSemiring<Int>` | `D[4]: 0>1:-2, 0>2:3, 1>2:4, 1>3:-1, 2>3:-6` | `DirectedAcyclicGraph(g).dagShortestPaths(from: 1)` | [—, 0, 4, -2] |
| SR-234 | DAG distances | a selective semiring: the same as dagShortestPaths, zero where unreached | `TropicalSemiring<Int>` | `D[4]: 0>1:-2, 0>2:3, 1>2:4, 1>3:-1, 2>3:-6` | `dagShortestDistances(from: 1)` | [Int.max, 0, 4, -2] |
| SR-235 | Floyd–Warshall | small digraph | `TropicalSemiring<Int>` | `D[5]: 0>1:4, 0>2:1, 2>1:2, 1>3:1, 2>3:5` | `floydWarshallShortestPaths()` | [0, 3, 1, 4, —; —, 0, —, 1, —; —, 2, 0, 3, —; —, —, —, 0, —; —, —, —, —, 0] |
| SR-236 | Floyd–Warshall | parallel edges, a loop and a cycle | `TropicalSemiring<Int>` | `D[3]: 0>1:5, 0>1:2, 1>1:3, 1>2:4, 2>0:1` | `floydWarshallShortestPaths()` | [0, 2, 6; 5, 0, 4; 1, 3, 0] |
| SR-237 | Floyd–Warshall | negative weights | `TropicalSemiring<Int>` | `D[4]: 0>1:-2, 0>2:3, 1>2:4, 1>3:-1, 2>3:-6` | `floydWarshallShortestPaths()` | [0, -2, 2, -4; —, 0, 4, -2; —, —, 0, -6; —, —, —, 0] |
| SR-238 | Floyd–Warshall | a negative cycle | `TropicalSemiring<Int>` | `D[4]: 0>1:1, 1>2:-3, 2>1:1, 2>3:2` | `floydWarshallShortestPaths()` | nil |
| SR-239 | Floyd–Warshall | undirected through .directed | `TropicalSemiring<Int>` | `U[4]: 0-1:2, 1-2:7, 2-3:1, 0-3:9` | `floydWarshallShortestPaths()` | [0, 2, 9, 9; 2, 0, 7, 8; 9, 7, 0, 1; 9, 8, 1, 0] |
| SR-240 | Floyd–Warshall | a negative loop | `TropicalSemiring<Int>` | `D[3]: 0>0:-1, 1>2:3` | `floydWarshallShortestPaths()` | nil |
| SR-241 | Dijkstra | small digraph, an isolated vertex | `TropicalSemiring<Double>` | `D[5]: 0>1:4, 0>2:1, 2>1:2, 1>3:1, 2>3:5` | `dijkstraShortestPaths(from: 0)` | [0.0, 3.0, 1.0, 4.0, —] |
| SR-242 | Dijkstra | parallel edges, a loop and a cycle | `TropicalSemiring<Double>` | `D[3]: 0>1:5, 0>1:2, 1>1:3, 1>2:4, 2>0:1` | `dijkstraShortestPaths(from: 0)` | [0.0, 2.0, 6.0] |
| SR-243 | Dijkstra | undirected through .directed | `TropicalSemiring<Double>` | `U[4]: 0-1:2, 1-2:7, 2-3:1, 0-3:9` | `dijkstraShortestPaths(from: 0)` | [0.0, 2.0, 9.0, 9.0] |
| SR-244 | Dijkstra | several sources | `TropicalSemiring<Double>` | `D[5]: 0>1:4, 0>2:1, 2>1:2, 1>3:1, 2>3:5` | `dijkstraShortestPaths(from: [3, 2])` | [—, 2.0, 0.0, 0.0, —] |
| SR-245 | Dijkstra | cutoff (not worse than) | `TropicalSemiring<Double>` | `D[5]: 0>1:4, 0>2:1, 2>1:2, 1>3:1, 2>3:5` | `dijkstraShortestPaths(from: 0, cutoff: 3)` | [0.0, 3.0, 1.0, —, —] |
| SR-246 | Dijkstra | a negative examined weight traps | `TropicalSemiring<Double>` | `D[4]: 0>1:-2, 0>2:3, 1>2:4, 1>3:-1, 2>3:-6` | `dijkstraShortestPaths(from: 0)` | **trap** (a weight is better than one) |
| SR-247 | Dijkstra | an edge of weight zero reaches nothing | `TropicalSemiring<Double>` | `D[3]: 0>1:Z, 1>2:O` | `dijkstraShortestPaths(from: 0)` | [0.0, —, —] |
| SR-248 | Dijkstra | one path | `TropicalSemiring<Double>` | `D[5]: 0>1:4, 0>2:1, 2>1:2, 1>3:1, 2>3:5` | `dijkstraShortestPath(from: 0, to: 3)` | vertices [0, 2, 1, 3], edges [1, 2, 3], distance 4.0 |
| SR-249 | Dijkstra | no path | `TropicalSemiring<Double>` | `D[5]: 0>1:4, 0>2:1, 2>1:2, 1>3:1, 2>3:5` | `dijkstraShortestPath(from: 0, to: 4)` | nil |
| SR-250 | Bellman–Ford | negative weights | `TropicalSemiring<Double>` | `D[4]: 0>1:-2, 0>2:3, 1>2:4, 1>3:-1, 2>3:-6` | `bellmanFordShortestPaths(from: 0)` | [0.0, -2.0, 2.0, -4.0] |
| SR-251 | Bellman–Ford | a reachable negative cycle | `TropicalSemiring<Double>` | `D[4]: 0>1:1, 1>2:-3, 2>1:1, 2>3:2` | `bellmanFordShortestPaths(from: 0)` | nil |
| SR-252 | Bellman–Ford | a negative cycle not reachable | `TropicalSemiring<Double>` | `D[4]: 0>1:1, 1>2:-3, 2>1:1, 2>3:2` | `bellmanFordShortestPaths(from: 3)` | [—, —, —, 0.0] |
| SR-253 | Bellman–Ford | parallel edges, a loop and a cycle | `TropicalSemiring<Double>` | `D[3]: 0>1:5, 0>1:2, 1>1:3, 1>2:4, 2>0:1` | `bellmanFordShortestPaths(from: 0)` | [0.0, 2.0, 6.0] |
| SR-254 | DAG | negative weights | `TropicalSemiring<Double>` | `D[4]: 0>1:-2, 0>2:3, 1>2:4, 1>3:-1, 2>3:-6` | `dagShortestPaths(from: 0)` | [0.0, -2.0, 2.0, -4.0] |
| SR-255 | DAG | a reachable cycle | `TropicalSemiring<Double>` | `D[3]: 0>1:5, 0>1:2, 1>1:3, 1>2:4, 2>0:1` | `dagShortestPaths(from: 0)` | nil |
| SR-256 | DAG | the maintained order (DirectedAcyclicGraph) | `TropicalSemiring<Double>` | `D[4]: 0>1:-2, 0>2:3, 1>2:4, 1>3:-1, 2>3:-6` | `DirectedAcyclicGraph(g).dagShortestPaths(from: 1)` | [—, 0.0, 4.0, -2.0] |
| SR-257 | DAG distances | a selective semiring: the same as dagShortestPaths, zero where unreached | `TropicalSemiring<Double>` | `D[4]: 0>1:-2, 0>2:3, 1>2:4, 1>3:-1, 2>3:-6` | `dagShortestDistances(from: 1)` | [.infinity, 0.0, 4.0, -2.0] |
| SR-258 | Floyd–Warshall | small digraph | `TropicalSemiring<Double>` | `D[5]: 0>1:4, 0>2:1, 2>1:2, 1>3:1, 2>3:5` | `floydWarshallShortestPaths()` | [0.0, 3.0, 1.0, 4.0, —; —, 0.0, —, 1.0, —; —, 2.0, 0.0, 3.0, —; —, —, —, 0.0, —; —, —, —, —, 0.0] |
| SR-259 | Floyd–Warshall | parallel edges, a loop and a cycle | `TropicalSemiring<Double>` | `D[3]: 0>1:5, 0>1:2, 1>1:3, 1>2:4, 2>0:1` | `floydWarshallShortestPaths()` | [0.0, 2.0, 6.0; 5.0, 0.0, 4.0; 1.0, 3.0, 0.0] |
| SR-260 | Floyd–Warshall | negative weights | `TropicalSemiring<Double>` | `D[4]: 0>1:-2, 0>2:3, 1>2:4, 1>3:-1, 2>3:-6` | `floydWarshallShortestPaths()` | [0.0, -2.0, 2.0, -4.0; —, 0.0, 4.0, -2.0; —, —, 0.0, -6.0; —, —, —, 0.0] |
| SR-261 | Floyd–Warshall | a negative cycle | `TropicalSemiring<Double>` | `D[4]: 0>1:1, 1>2:-3, 2>1:1, 2>3:2` | `floydWarshallShortestPaths()` | nil |
| SR-262 | Floyd–Warshall | undirected through .directed | `TropicalSemiring<Double>` | `U[4]: 0-1:2, 1-2:7, 2-3:1, 0-3:9` | `floydWarshallShortestPaths()` | [0.0, 2.0, 9.0, 9.0; 2.0, 0.0, 7.0, 8.0; 9.0, 7.0, 0.0, 1.0; 9.0, 8.0, 1.0, 0.0] |
| SR-263 | Floyd–Warshall | a negative loop | `TropicalSemiring<Double>` | `D[3]: 0>0:-1, 1>2:3` | `floydWarshallShortestPaths()` | nil |
| SR-264 | Agreement | the W overload gives the same distances | `TropicalSemiring<Int>` | `D[30]: lcg(30,120,1;0..20)` | `dijkstraShortestPaths(from: 0)` | [0, 18, 31, 19, 10, 16, 21, 23, 18, 11, 40, 19, 21, 7, 35, 31, 10, 22, 11, 19, 23, 9, 19, 27, 22, 28, 26, 19, 13, 23] |
| SR-265 | Agreement | the W overload gives the same distances | `TropicalSemiring<Int>` | `D[30]: lcg(30,120,1;-3..20)` | `bellmanFordShortestPaths(from: 0)` | nil |
| SR-266 | Agreement | the W overload gives the same distances | `TropicalSemiring<Int>` | `D[30]: lcg(30,120,2;0..20)` | `dijkstraShortestPaths(from: 0)` | [0, 34, 16, 39, 2, 11, 32, 16, 11, 29, 43, 38, 23, 22, 26, 15, 25, 36, 34, 18, 25, 33, 19, 18, 32, 14, 13, 29, 7, 23] |
| SR-267 | Agreement | the W overload gives the same distances | `TropicalSemiring<Int>` | `D[30]: lcg(30,120,2;-3..20)` | `bellmanFordShortestPaths(from: 0)` | [0, 7, 13, 14, -1, -4, 4, -2, 8, 20, 18, 8, 16, 1, 8, 9, 8, -2, 13, 15, 10, 14, 12, 10, 1, -2, 1, 16, -5, -1] |
| SR-268 | Agreement | the W overload gives the same distances | `TropicalSemiring<Int>` | `D[30]: lcg(30,120,3;0..20)` | `dijkstraShortestPaths(from: 0)` | [0, 15, 16, 18, 19, 11, 14, 14, 16, 16, 25, 11, 20, 12, 2, 10, 7, 8, 8, 8, 29, 11, 18, 0, 3, 25, 10, 24, 4, 5] |
| SR-269 | Agreement | the W overload gives the same distances | `TropicalSemiring<Int>` | `D[30]: lcg(30,120,3;-3..20)` | `bellmanFordShortestPaths(from: 0)` | [0, 6, 9, 23, 23, 18, 7, 9, 5, 7, 35, 9, 17, 21, 15, 8, 13, 7, 12, 6, 17, 24, 13, 9, 11, 11, 5, 14, 10, 11] |
| SR-270 | Agreement | the W overload gives the same matrix | `TropicalSemiring<Int>` | `D[12]: lcg(12,40,4;0..9)` | `floydWarshallShortestPaths()` | [0, 2, 4, 1, 3, 5, 3, 4, 4, 2, 4, 6; 3, 0, 7, 4, 6, 8, 6, 7, 7, 5, 7, 9; 8, 7, 0, 2, 4, 6, 4, 5, 0, 3, 8, 10; 6, 5, 3, 0, 2, 4, 2, 3, 3, 1, 6, 8; 8, 5, 6, 6, 0, 4, 5, 6, 4, 7, 9, 11; 4, 1, 8, 5, 7, 0, 7, 8, 8, 6, 8, 9; 6, 3, 1, 3, 5, 2, 0, 1, 1, 4, 4, 6; 5, 7, 0, 2, 4, 6, 4, 0, 0, 3, 8, 6; 8, 7, 5, 2, 4, 6, 4, 5, 0, 3, 8, 10; 5, 7, 7, 6, 2, 6, 7, 8, 6, 0, 9, 11; 13, 12, 5, 7, 9, 11, 9, 10, 5, 8, 0, 2; 13, 15, 8, 10, 12, 14, 12, 8, 8, 11, 16, 0] |
| SR-271 | Agreement | the W overload gives the same distances | `TropicalSemiring<Double>` | `D[30]: lcg(30,120,5;0..80/4)` | `dijkstraShortestPaths(from: 0)` | [0.0, 38.5, 19.5, 23.0, 30.75, 5.0, 27.75, 37.75, 34.75, 20.5, 13.5, 17.0, 25.25, 14.5, 15.0, 35.0, 18.25, 24.0, 14.5, 32.75, 30.75, 20.5, 29.25, 17.25, 35.25, 14.75, 47.25, 17.75, 40.5, 28.75] |
| SR-272 | Agreement | the W overload gives the same distances | `TropicalSemiring<Double>` | `D[30]: lcg(30,120,6;0..80/4)` | `dijkstraShortestPaths(from: 0)` | [0.0, 6.25, 23.75, 25.75, 14.0, 20.5, 10.5, —, 33.5, 18.75, 33.75, 13.5, 21.25, 15.0, 13.75, 26.75, 37.75, 31.75, 32.25, 27.25, 28.0, 13.75, 14.0, 37.25, 17.25, 10.5, 28.0, 22.25, 13.5, 35.5] |
| SR-273 | Overflow | the sum overflows: traps | `TropicalSemiring<Int>` | `D[3]: 0>1:4611686018427387904, 1>2:4611686018427387904` | `dijkstraShortestPaths(from: 0)` | **trap** (overflow) |
| SR-274 | Overflow | Int.max weight is zero: no trap, not reached | `TropicalSemiring<Int>` | `D[3]: 0>1:5, 1>2:Int.max` | `dijkstraShortestPaths(from: 0)` | [0, 5, —] |
| SR-275 | Dijkstra | widest paths | `BottleneckSemiring<Int>` | `D[5]: 0>1:5, 0>2:3, 1>2:4, 1>3:2, 2>3:6, 3>4:7, 2>4:1` | `dijkstraShortestPaths(from: 0)` | [Int.max, 5, 4, 4, 4] |
| SR-276 | Dijkstra | parallel widths and a cycle | `BottleneckSemiring<Int>` | `D[4]: 0>1:3, 0>1:8, 1>2:2, 2>1:9, 1>3:5` | `dijkstraShortestPaths(from: 0)` | [Int.max, 8, 2, 5] |
| SR-277 | Dijkstra | undirected through .directed | `BottleneckSemiring<Int>` | `U[4]: 0-1:2, 1-2:7, 2-3:1, 0-3:9` | `dijkstraShortestPaths(from: 0)` | [Int.max, 2, 2, 9] |
| SR-278 | Dijkstra | an isolated vertex | `BottleneckSemiring<Int>` | `D[5]: 0>1:4, 0>2:1, 2>1:2, 1>3:1, 2>3:5` | `dijkstraShortestPaths(from: 0)` | [Int.max, 4, 1, 1, —] |
| SR-279 | Dijkstra | cutoff: only paths at least this wide | `BottleneckSemiring<Int>` | `D[5]: 0>1:5, 0>2:3, 1>2:4, 1>3:2, 2>3:6, 3>4:7, 2>4:1` | `dijkstraShortestPaths(from: 0, cutoff: 5)` | [Int.max, 5, —, —, —] |
| SR-280 | Dijkstra | negative widths are fine (one is +∞) | `BottleneckSemiring<Int>` | `D[4]: 0>1:-2, 0>2:3, 1>2:4, 1>3:-1, 2>3:-6` | `dijkstraShortestPaths(from: 0)` | [Int.max, -2, 3, -2] |
| SR-281 | Dijkstra | the widest path | `BottleneckSemiring<Int>` | `D[5]: 0>1:5, 0>2:3, 1>2:4, 1>3:2, 2>3:6, 3>4:7, 2>4:1` | `dijkstraShortestPath(from: 0, to: 4)` | vertices [0, 1, 2, 3, 4], edges [0, 2, 4, 5], distance 4 |
| SR-282 | Bellman–Ford | cycles never improve | `BottleneckSemiring<Int>` | `D[4]: 0>1:3, 0>1:8, 1>2:2, 2>1:9, 1>3:5` | `bellmanFordShortestPaths(from: 0)` | [Int.max, 8, 2, 5] |
| SR-283 | Bellman–Ford | the 'negative' cycle of the tropical rows is harmless | `BottleneckSemiring<Int>` | `D[4]: 0>1:1, 1>2:-3, 2>1:1, 2>3:2` | `bellmanFordShortestPaths(from: 0)` | [Int.max, 1, -3, -3] |
| SR-284 | DAG | widest paths in a DAG | `BottleneckSemiring<Int>` | `D[4]: 0>1:-2, 0>2:3, 1>2:4, 1>3:-1, 2>3:-6` | `dagShortestPaths(from: 0)` | [Int.max, -2, 3, -2] |
| SR-285 | Floyd–Warshall | all-pairs widest paths | `BottleneckSemiring<Int>` | `D[5]: 0>1:5, 0>2:3, 1>2:4, 1>3:2, 2>3:6, 3>4:7, 2>4:1` | `floydWarshallShortestPaths()` | [Int.max, 5, 4, 4, 4; —, Int.max, 4, 4, 4; —, —, Int.max, 6, 6; —, —, —, Int.max, 7; —, —, —, —, Int.max] |
| SR-286 | Floyd–Warshall | parallel widths and a cycle | `BottleneckSemiring<Int>` | `D[4]: 0>1:3, 0>1:8, 1>2:2, 2>1:9, 1>3:5` | `floydWarshallShortestPaths()` | [Int.max, 8, 2, 5; —, Int.max, 2, 5; —, 9, Int.max, 5; —, —, —, Int.max] |
| SR-287 | Floyd–Warshall | a 'negative' cycle is harmless | `BottleneckSemiring<Int>` | `D[4]: 0>1:1, 1>2:-3, 2>1:1, 2>3:2` | `floydWarshallShortestPaths()` | [Int.max, 1, -3, -3; —, Int.max, -3, -3; —, 1, Int.max, 2; —, —, —, Int.max] |
| SR-288 | Dijkstra | widest paths | `BottleneckSemiring<Double>` | `D[5]: 0>1:5, 0>2:3, 1>2:4, 1>3:2, 2>3:6, 3>4:7, 2>4:1` | `dijkstraShortestPaths(from: 0)` | [.infinity, 5.0, 4.0, 4.0, 4.0] |
| SR-289 | Dijkstra | parallel widths and a cycle | `BottleneckSemiring<Double>` | `D[4]: 0>1:3, 0>1:8, 1>2:2, 2>1:9, 1>3:5` | `dijkstraShortestPaths(from: 0)` | [.infinity, 8.0, 2.0, 5.0] |
| SR-290 | Dijkstra | undirected through .directed | `BottleneckSemiring<Double>` | `U[4]: 0-1:2, 1-2:7, 2-3:1, 0-3:9` | `dijkstraShortestPaths(from: 0)` | [.infinity, 2.0, 2.0, 9.0] |
| SR-291 | Dijkstra | an isolated vertex | `BottleneckSemiring<Double>` | `D[5]: 0>1:4, 0>2:1, 2>1:2, 1>3:1, 2>3:5` | `dijkstraShortestPaths(from: 0)` | [.infinity, 4.0, 1.0, 1.0, —] |
| SR-292 | Dijkstra | cutoff: only paths at least this wide | `BottleneckSemiring<Double>` | `D[5]: 0>1:5, 0>2:3, 1>2:4, 1>3:2, 2>3:6, 3>4:7, 2>4:1` | `dijkstraShortestPaths(from: 0, cutoff: 5)` | [.infinity, 5.0, —, —, —] |
| SR-293 | Dijkstra | negative widths are fine (one is +∞) | `BottleneckSemiring<Double>` | `D[4]: 0>1:-2, 0>2:3, 1>2:4, 1>3:-1, 2>3:-6` | `dijkstraShortestPaths(from: 0)` | [.infinity, -2.0, 3.0, -2.0] |
| SR-294 | Dijkstra | the widest path | `BottleneckSemiring<Double>` | `D[5]: 0>1:5, 0>2:3, 1>2:4, 1>3:2, 2>3:6, 3>4:7, 2>4:1` | `dijkstraShortestPath(from: 0, to: 4)` | vertices [0, 1, 2, 3, 4], edges [0, 2, 4, 5], distance 4.0 |
| SR-295 | Bellman–Ford | cycles never improve | `BottleneckSemiring<Double>` | `D[4]: 0>1:3, 0>1:8, 1>2:2, 2>1:9, 1>3:5` | `bellmanFordShortestPaths(from: 0)` | [.infinity, 8.0, 2.0, 5.0] |
| SR-296 | Bellman–Ford | the 'negative' cycle of the tropical rows is harmless | `BottleneckSemiring<Double>` | `D[4]: 0>1:1, 1>2:-3, 2>1:1, 2>3:2` | `bellmanFordShortestPaths(from: 0)` | [.infinity, 1.0, -3.0, -3.0] |
| SR-297 | DAG | widest paths in a DAG | `BottleneckSemiring<Double>` | `D[4]: 0>1:-2, 0>2:3, 1>2:4, 1>3:-1, 2>3:-6` | `dagShortestPaths(from: 0)` | [.infinity, -2.0, 3.0, -2.0] |
| SR-298 | Floyd–Warshall | all-pairs widest paths | `BottleneckSemiring<Double>` | `D[5]: 0>1:5, 0>2:3, 1>2:4, 1>3:2, 2>3:6, 3>4:7, 2>4:1` | `floydWarshallShortestPaths()` | [.infinity, 5.0, 4.0, 4.0, 4.0; —, .infinity, 4.0, 4.0, 4.0; —, —, .infinity, 6.0, 6.0; —, —, —, .infinity, 7.0; —, —, —, —, .infinity] |
| SR-299 | Floyd–Warshall | parallel widths and a cycle | `BottleneckSemiring<Double>` | `D[4]: 0>1:3, 0>1:8, 1>2:2, 2>1:9, 1>3:5` | `floydWarshallShortestPaths()` | [.infinity, 8.0, 2.0, 5.0; —, .infinity, 2.0, 5.0; —, 9.0, .infinity, 5.0; —, —, —, .infinity] |
| SR-300 | Floyd–Warshall | a 'negative' cycle is harmless | `BottleneckSemiring<Double>` | `D[4]: 0>1:1, 1>2:-3, 2>1:1, 2>3:2` | `floydWarshallShortestPaths()` | [.infinity, 1.0, -3.0, -3.0; —, .infinity, -3.0, -3.0; —, 1.0, .infinity, 2.0; —, —, —, .infinity] |
| SR-301 | Agreement | against brute force over simple paths | `BottleneckSemiring<Int>` | `D[9]: lcg(9,24,7;-5..30)` | `dijkstraShortestPaths(from: 0)` | [Int.max, -3, 7, 7, -3, 26, -3, 6, -3] |
| SR-302 | Agreement | against brute force over simple paths | `BottleneckSemiring<Int>` | `D[9]: lcg(9,24,7;-5..30)` | `floydWarshallShortestPaths()` | [Int.max, -3, 7, 7, -3, 26, -3, 6, -3; 30, Int.max, 7, 8, -1, 26, -1, 6, 8; -5, -5, Int.max, 25, -5, -5, -5, -5, -5; -5, -5, -5, Int.max, -5, -5, -5, -5, -5; 7, -3, 7, 30, Int.max, 7, -3, 7, 28; 6, -3, 7, 7, -3, Int.max, -3, 6, -3; 16, 16, 18, 18, 14, 16, Int.max, 7, 14; 27, -3, 7, 7, -3, 26, -3, Int.max, -3; -3, -3, -3, 25, -3, -3, -3, -3, Int.max] |
| SR-303 | Agreement | against brute force over simple paths | `BottleneckSemiring<Int>` | `D[9]: lcg(9,24,8;-5..30)` | `dijkstraShortestPaths(from: 0)` | [Int.max, 23, 0, 23, 22, 23, 23, 22, -5] |
| SR-304 | Agreement | against brute force over simple paths | `BottleneckSemiring<Int>` | `D[9]: lcg(9,24,8;-5..30)` | `floydWarshallShortestPaths()` | [Int.max, 23, 0, 23, 22, 23, 23, 22, -5; 0, Int.max, 0, 0, 0, 0, 0, 0, -5; 14, 14, Int.max, 14, 14, 14, 14, 14, -5; 18, 24, 0, Int.max, 22, 27, 25, 22, -5; 18, 18, 0, 18, Int.max, 18, 28, 24, -5; -2, -2, -2, -2, -2, Int.max, -2, -2, -5; 18, 18, 0, 18, 22, 18, Int.max, 22, -5; 18, 18, 0, 18, 22, 18, 28, Int.max, -5; -5, -5, -5, -5, -5, -5, -5, -5, Int.max] |
| SR-305 | Dijkstra | reachability; a false edge is absent | `BooleanSemiring` | `D[6]: 0>1:true, 1>2:true, 2>0:true, 2>3:false, 3>4:true, 5>5:true` | `dijkstraShortestPaths(from: 0)` | [true, true, true, —, —, —] |
| SR-306 | Bellman–Ford | reachability; a false edge is absent | `BooleanSemiring` | `D[6]: 0>1:true, 1>2:true, 2>0:true, 2>3:false, 3>4:true, 5>5:true` | `bellmanFordShortestPaths(from: 0)` | [true, true, true, —, —, —] |
| SR-307 | Floyd–Warshall | reflexive transitive closure (Warshall) | `BooleanSemiring` | `D[6]: 0>1:true, 1>2:true, 2>0:true, 2>3:false, 3>4:true, 5>5:true` | `floydWarshallShortestPaths()` | [true, true, true, —, —, —; true, true, true, —, —, —; true, true, true, —, —, —; —, —, —, true, true, —; —, —, —, —, true, —; —, —, —, —, —, true] |
| SR-308 | Dijkstra | parallel edges, a loop | `BooleanSemiring` | `D[3]: 0>1:true, 0>1:false, 1>1:true, 1>2:true, 2>0:true` | `dijkstraShortestPaths(from: 0)` | [true, true, true] |
| SR-309 | Bellman–Ford | parallel edges, a loop | `BooleanSemiring` | `D[3]: 0>1:true, 0>1:false, 1>1:true, 1>2:true, 2>0:true` | `bellmanFordShortestPaths(from: 0)` | [true, true, true] |
| SR-310 | Floyd–Warshall | reflexive transitive closure (Warshall) | `BooleanSemiring` | `D[3]: 0>1:true, 0>1:false, 1>1:true, 1>2:true, 2>0:true` | `floydWarshallShortestPaths()` | [true, true, true; true, true, true; true, true, true] |
| SR-311 | Dijkstra | several sources | `BooleanSemiring` | `D[6]: 0>1:true, 1>2:true, 2>0:true, 2>3:false, 3>4:true, 5>5:true` | `dijkstraShortestPaths(from: [3, 5])` | [—, —, —, true, true, true] |
| SR-312 | DAG | reachability in a DAG | `BooleanSemiring` | `D[5]: 0>1:true, 0>2:true, 1>3:true, 2>3:false, 4>3:true` | `dagShortestPaths(from: 0)` | [true, true, true, true, —] |
| SR-313 | DAG distances | reachability in a DAG, false where unreached | `BooleanSemiring` | `D[5]: 0>1:true, 0>2:true, 1>3:true, 2>3:false, 4>3:true` | `dagShortestDistances(from: 0)` | [true, true, true, true, false] |
| SR-314 | Agreement | the same set as Traversal's descendants(of:) | `BooleanSemiring` | `D[12]: lcg(12,20,9;1..1)` | `dijkstraShortestPaths(from: 0)` | [true, —, —, —, —, —, true, —, —, —, true, —] |
| SR-315 | Agreement | NetworkX transitive_closure(reflexive=True) | `BooleanSemiring` | `D[10]: lcg(10,14,10;1..1)` | `floydWarshallShortestPaths()` | [true, —, —, —, —, —, —, —, —, —; true, true, true, true, true, true, true, true, true, true; true, —, true, —, true, true, true, true, true, true; true, —, true, true, true, true, true, true, true, true; true, —, true, —, true, true, true, true, true, true; true, —, true, —, true, true, true, true, true, true; true, —, true, —, true, true, true, true, true, true; true, —, true, —, true, true, true, true, true, true; true, —, true, —, true, true, true, true, true, true; true, —, true, —, true, true, true, true, true, true] |
| SR-316 | DAG distances | paths in a diamond chain: 2^k | `CountingSemiring<Int>` | `D: ladder(10)` | `dagShortestDistances(from: 0)` | [1, 1, 2, 2, 4, 4, 8, 8, 16, 16, 32, 32, 64, 64, 128, 128, 256, 256, 512, 512, 1024] |
| SR-317 | DAG distances | lattice paths: C(r+c−2, r−1) | `CountingSemiring<Int>` | `D: grid(4,5)` | `dagShortestDistances(from: 0)` | [1, 1, 1, 1, 1, 1, 2, 3, 4, 5, 1, 3, 6, 10, 15, 1, 4, 10, 20, 35] |
| SR-318 | DAG distances | parallel edges count separately | `CountingSemiring<Int>` | `D[3]: 0>1:1, 0>1:1, 1>2:1, 0>2:1` | `dagShortestDistances(from: 0)` | [1, 2, 3] |
| SR-319 | DAG distances | weights multiply along a path and add across paths | `CountingSemiring<Int>` | `D[4]: 0>1:2, 0>2:3, 1>3:5, 2>3:7, 0>3:1` | `dagShortestDistances(from: 0)` | [1, 2, 3, 32] |
| SR-320 | DAG distances | a reachable cycle: nil | `CountingSemiring<Int>` | `D[3]: 0>1:1, 1>2:1, 2>1:1` | `dagShortestDistances(from: 0)` | nil |
| SR-321 | DAG distances | a cycle not reachable is fine | `CountingSemiring<Int>` | `D[4]: 0>1:1, 2>3:1, 3>2:1` | `dagShortestDistances(from: 0)` | [1, 1, 0, 0] |
| SR-322 | DAG distances | several sources add (a source reached from another counts both) | `CountingSemiring<Int>` | `D[4]: 0>1:1, 1>2:1, 0>2:1, 2>3:1` | `dagShortestDistances(from: [0, 2])` | [1, 1, 3, 3] |
| SR-323 | DAG distances | the maintained order (DirectedAcyclicGraph) | `CountingSemiring<Int>` | `D[4]: 0>1:1, 0>2:1, 1>3:1, 2>3:1` | `DirectedAcyclicGraph(g).dagShortestDistances(from: 0)` | [1, 1, 1, 2] |
| SR-324 | Not available | Dijkstra needs a SelectiveSemiring | `CountingSemiring<Int>` | `D[2]: 0>1:1` | `dijkstraShortestPaths(from: 0)` | does not compile (CountingSemiring<Int> is not a SelectiveSemiring) |
| SR-325 | DAG distances | paths in a diamond chain: 2^k | `CountingSemiring<Double>` | `D: ladder(10)` | `dagShortestDistances(from: 0)` | [1.0, 1.0, 2.0, 2.0, 4.0, 4.0, 8.0, 8.0, 16.0, 16.0, 32.0, 32.0, 64.0, 64.0, 128.0, 128.0, 256.0, 256.0, 512.0, 512.0, 1024.0] |
| SR-326 | DAG distances | lattice paths: C(r+c−2, r−1) | `CountingSemiring<Double>` | `D: grid(4,5)` | `dagShortestDistances(from: 0)` | [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 2.0, 3.0, 4.0, 5.0, 1.0, 3.0, 6.0, 10.0, 15.0, 1.0, 4.0, 10.0, 20.0, 35.0] |
| SR-327 | DAG distances | parallel edges count separately | `CountingSemiring<Double>` | `D[3]: 0>1:1, 0>1:1, 1>2:1, 0>2:1` | `dagShortestDistances(from: 0)` | [1.0, 2.0, 3.0] |
| SR-328 | DAG distances | weights multiply along a path and add across paths | `CountingSemiring<Double>` | `D[4]: 0>1:2, 0>2:3, 1>3:5, 2>3:7, 0>3:1` | `dagShortestDistances(from: 0)` | [1.0, 2.0, 3.0, 32.0] |
| SR-329 | DAG distances | a reachable cycle: nil | `CountingSemiring<Double>` | `D[3]: 0>1:1, 1>2:1, 2>1:1` | `dagShortestDistances(from: 0)` | nil |
| SR-330 | DAG distances | a cycle not reachable is fine | `CountingSemiring<Double>` | `D[4]: 0>1:1, 2>3:1, 3>2:1` | `dagShortestDistances(from: 0)` | [1.0, 1.0, 0.0, 0.0] |
| SR-331 | DAG distances | several sources add (a source reached from another counts both) | `CountingSemiring<Double>` | `D[4]: 0>1:1, 1>2:1, 0>2:1, 2>3:1` | `dagShortestDistances(from: [0, 2])` | [1.0, 1.0, 3.0, 3.0] |
| SR-332 | DAG distances | the maintained order (DirectedAcyclicGraph) | `CountingSemiring<Double>` | `D[4]: 0>1:1, 0>2:1, 1>3:1, 2>3:1` | `DirectedAcyclicGraph(g).dagShortestDistances(from: 0)` | [1.0, 1.0, 1.0, 2.0] |
| SR-333 | Not available | Dijkstra needs a SelectiveSemiring | `CountingSemiring<Double>` | `D[2]: 0>1:1` | `dijkstraShortestPaths(from: 0)` | does not compile (CountingSemiring<Double> is not a SelectiveSemiring) |
| SR-334 | DAG distances | the largest diamond chain that fits: 2^62 | `CountingSemiring<Int>` | `D: ladder(62)` | `dagShortestDistances(from: 0)` | [1, 1, 2, 2, 4, 4, 8, 8, 16, 16, 32, 32, 64, 64, 128, 128, 256, 256, 512, 512, 1024, 1024, 2048, 2048, 4096, 4096, 8192, 8192, 16384, 16384, 32768, 32768, 65536, 65536, 131072, 131072, 262144, 262144, 524288, 524288, 1048576, 1048576, 2097152, 2097152, 4194304, 4194304, 8388608, 8388608, 16777216, 16777216, 33554432, 33554432, 67108864, 67108864, 134217728, 134217728, 268435456, 268435456, 536870912, 536870912, 1073741824, 1073741824, 2147483648, 2147483648, 4294967296, 4294967296, 8589934592, 8589934592, 17179869184, 17179869184, 34359738368, 34359738368, 68719476736, 68719476736, 137438953472, 137438953472, 274877906944, 274877906944, 549755813888, 549755813888, 1099511627776, 1099511627776, 2199023255552, 2199023255552, 4398046511104, 4398046511104, 8796093022208, 8796093022208, 17592186044416, 17592186044416, 35184372088832, 35184372088832, 70368744177664, 70368744177664, 140737488355328, 140737488355328, 281474976710656, 281474976710656, 562949953421312, 562949953421312, 1125899906842624, 1125899906842624, 2251799813685248, 2251799813685248, 4503599627370496, 4503599627370496, 9007199254740992, 9007199254740992, 18014398509481984, 18014398509481984, 36028797018963968, 36028797018963968, 72057594037927936, 72057594037927936, 144115188075855872, 144115188075855872, 288230376151711744, 288230376151711744, 576460752303423488, 576460752303423488, 1152921504606846976, 1152921504606846976, 2305843009213693952, 2305843009213693952, 4611686018427387904] |
| SR-335 | DAG distances | 2^63 overflows: traps | `CountingSemiring<Int>` | `D: ladder(63)` | `dagShortestDistances(from: 0)` | **trap** (overflow) |
| SR-336 | DAG distances | C(66,33) fits | `CountingSemiring<Int>` | `D: grid(34,34)` | `dagShortestDistances(from: 0)` | [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 1, 3, 6, 10, 15, 21, 28, 36, 45, 55, 66, 78, 91, 105, 120, 136, 153, 171, 190, 210, 231, 253, 276, 300, 325, 351, 378, 406, 435, 465, 496, 528, 561, 595, 1, 4, 10, 20, 35, 56, 84, 120, 165, 220, 286, 364, 455, 560, 680, 816, 969, 1140, 1330, 1540, 1771, 2024, 2300, 2600, 2925, 3276, 3654, 4060, 4495, 4960, 5456, 5984, 6545, 7140, 1, 5, 15, 35, 70, 126, 210, 330, 495, 715, 1001, 1365, 1820, 2380, 3060, 3876, 4845, 5985, 7315, 8855, 10626, 12650, 14950, 17550, 20475, 23751, 27405, 31465, 35960, 40920, 46376, 52360, 58905, 66045, 1, 6, 21, 56, 126, 252, 462, 792, 1287, 2002, 3003, 4368, 6188, 8568, 11628, 15504, 20349, 26334, 33649, 42504, 53130, 65780, 80730, 98280, 118755, 142506, 169911, 201376, 237336, 278256, 324632, 376992, 435897, 501942, 1, 7, 28, 84, 210, 462, 924, 1716, 3003, 5005, 8008, 12376, 18564, 27132, 38760, 54264, 74613, 100947, 134596, 177100, 230230, 296010, 376740, 475020, 593775, 736281, 906192, 1107568, 1344904, 1623160, 1947792, 2324784, 2760681, 3262623, 1, 8, 36, 120, 330, 792, 1716, 3432, 6435, 11440, 19448, 31824, 50388, 77520, 116280, 170544, 245157, 346104, 480700, 657800, 888030, 1184040, 1560780, 2035800, 2629575, 3365856, 4272048, 5379616, 6724520, 8347680, 10295472, 12620256, 15380937, 18643560, 1, 9, 45, 165, 495, 1287, 3003, 6435, 12870, 24310, 43758, 75582, 125970, 203490, 319770, 490314, 735471, 1081575, 1562275, 2220075, 3108105, 4292145, 5852925, 7888725, 10518300, 13884156, 18156204, 23535820, 30260340, 38608020, 48903492, 61523748, 76904685, 95548245, 1, 10, 55, 220, 715, 2002, 5005, 11440, 24310, 48620, 92378, 167960, 293930, 497420, 817190, 1307504, 2042975, 3124550, 4686825, 6906900, 10015005, 14307150, 20160075, 28048800, 38567100, 52451256, 70607460, 94143280, 124403620, 163011640, 211915132, 273438880, 350343565, 445891810, 1, 11, 66, 286, 1001, 3003, 8008, 19448, 43758, 92378, 184756, 352716, 646646, 1144066, 1961256, 3268760, 5311735, 8436285, 13123110, 20030010, 30045015, 44352165, 64512240, 92561040, 131128140, 183579396, 254186856, 348330136, 472733756, 635745396, 847660528, 1121099408, 1471442973, 1917334783, 1, 12, 78, 364, 1365, 4368, 12376, 31824, 75582, 167960, 352716, 705432, 1352078, 2496144, 4457400, 7726160, 13037895, 21474180, 34597290, 54627300, 84672315, 129024480, 193536720, 286097760, 417225900, 600805296, 854992152, 1203322288, 1676056044, 2311801440, 3159461968, 4280561376, 5752004349, 7669339132, 1, 13, 91, 455, 1820, 6188, 18564, 50388, 125970, 293930, 646646, 1352078, 2704156, 5200300, 9657700, 17383860, 30421755, 51895935, 86493225, 141120525, 225792840, 354817320, 548354040, 834451800, 1251677700, 1852482996, 2707475148, 3910797436, 5586853480, 7898654920, 11058116888, 15338678264, 21090682613, 28760021745, 1, 14, 105, 560, 2380, 8568, 27132, 77520, 203490, 497420, 1144066, 2496144, 5200300, 10400600, 20058300, 37442160, 67863915, 119759850, 206253075, 347373600, 573166440, 927983760, 1476337800, 2310789600, 3562467300, 5414950296, 8122425444, 12033222880, 17620076360, 25518731280, 36576848168, 51915526432, 73006209045, 101766230790, 1, 15, 120, 680, 3060, 11628, 38760, 116280, 319770, 817190, 1961256, 4457400, 9657700, 20058300, 40116600, 77558760, 145422675, 265182525, 471435600, 818809200, 1391975640, 2319959400, 3796297200, 6107086800, 9669554100, 15084504396, 23206929840, 35240152720, 52860229080, 78378960360, 114955808528, 166871334960, 239877544005, 341643774795, 1, 16, 136, 816, 3876, 15504, 54264, 170544, 490314, 1307504, 3268760, 7726160, 17383860, 37442160, 77558760, 155117520, 300540195, 565722720, 1037158320, 1855967520, 3247943160, 5567902560, 9364199760, 15471286560, 25140840660, 40225345056, 63432274896, 98672427616, 151532656696, 229911617056, 344867425584, 511738760544, 751616304549, 1093260079344, 1, 17, 153, 969, 4845, 20349, 74613, 245157, 735471, 2042975, 5311735, 13037895, 30421755, 67863915, 145422675, 300540195, 601080390, 1166803110, 2203961430, 4059928950, 7307872110, 12875774670, 22239974430, 37711260990, 62852101650, 103077446706, 166509721602, 265182149218, 416714805914, 646626422970, 991493848554, 1503232609098, 2254848913647, 3348108992991, 1, 18, 171, 1140, 5985, 26334, 100947, 346104, 1081575, 3124550, 8436285, 21474180, 51895935, 119759850, 265182525, 565722720, 1166803110, 2333606220, 4537567650, 8597496600, 15905368710, 28781143380, 51021117810, 88732378800, 151584480450, 254661927156, 421171648758, 686353797976, 1103068603890, 1749695026860, 2741188875414, 4244421484512, 6499270398159, 9847379391150, 1, 19, 190, 1330, 7315, 33649, 134596, 480700, 1562275, 4686825, 13123110, 34597290, 86493225, 206253075, 471435600, 1037158320, 2203961430, 4537567650, 9075135300, 17672631900, 33578000610, 62359143990, 113380261800, 202112640600, 353697121050, 608359048206, 1029530696964, 1715884494940, 2818953098830, 4568648125690, 7309837001104, 11554258485616, 18053528883775, 27900908274925, 1, 20, 210, 1540, 8855, 42504, 177100, 657800, 2220075, 6906900, 20030010, 54627300, 141120525, 347373600, 818809200, 1855967520, 4059928950, 8597496600, 17672631900, 35345263800, 68923264410, 131282408400, 244662670200, 446775310800, 800472431850, 1408831480056, 2438362177020, 4154246671960, 6973199770790, 11541847896480, 18851684897584, 30405943383200, 48459472266975, 76360380541900, 1, 21, 231, 1771, 10626, 53130, 230230, 888030, 3108105, 10015005, 30045015, 84672315, 225792840, 573166440, 1391975640, 3247943160, 7307872110, 15905368710, 33578000610, 68923264410, 137846528820, 269128937220, 513791607420, 960566918220, 1761039350070, 3169870830126, 5608233007146, 9762479679106, 16735679449896, 28277527346376, 47129212243960, 77535155627160, 125994627894135, 202355008436035, 1, 22, 253, 2024, 12650, 65780, 296010, 1184040, 4292145, 14307150, 44352165, 129024480, 354817320, 927983760, 2319959400, 5567902560, 12875774670, 28781143380, 62359143990, 131282408400, 269128937220, 538257874440, 1052049481860, 2012616400080, 3773655750150, 6943526580276, 12551759587422, 22314239266528, 39049918716424, 67327446062800, 114456658306760, 191991813933920, 317986441828055, 520341450264090, 1, 23, 276, 2300, 14950, 80730, 376740, 1560780, 5852925, 20160075, 64512240, 193536720, 548354040, 1476337800, 3796297200, 9364199760, 22239974430, 51021117810, 113380261800, 244662670200, 513791607420, 1052049481860, 2104098963720, 4116715363800, 7890371113950, 14833897694226, 27385657281648, 49699896548176, 88749815264600, 156077261327400, 270533919634160, 462525733568080, 780512175396135, 1300853625660225, 1, 24, 300, 2600, 17550, 98280, 475020, 2035800, 7888725, 28048800, 92561040, 286097760, 834451800, 2310789600, 6107086800, 15471286560, 37711260990, 88732378800, 202112640600, 446775310800, 960566918220, 2012616400080, 4116715363800, 8233430727600, 16123801841550, 30957699535776, 58343356817424, 108043253365600, 196793068630200, 352870329957600, 623404249591760, 1085929983159840, 1866442158555975, 3167295784216200, 1, 25, 325, 2925, 20475, 118755, 593775, 2629575, 10518300, 38567100, 131128140, 417225900, 1251677700, 3562467300, 9669554100, 25140840660, 62852101650, 151584480450, 353697121050, 800472431850, 1761039350070, 3773655750150, 7890371113950, 16123801841550, 32247603683100, 63205303218876, 121548660036300, 229591913401900, 426384982032100, 779255311989700, 1402659561581460, 2488589544741300, 4355031703297275, 7522327487513475, 1, 26, 351, 3276, 23751, 142506, 736281, 3365856, 13884156, 52451256, 183579396, 600805296, 1852482996, 5414950296, 15084504396, 40225345056, 103077446706, 254661927156, 608359048206, 1408831480056, 3169870830126, 6943526580276, 14833897694226, 30957699535776, 63205303218876, 126410606437752, 247959266474052, 477551179875952, 903936161908052, 1683191473897752, 3085851035479212, 5574440580220512, 9929472283517787, 17451799771031262, 1, 27, 378, 3654, 27405, 169911, 906192, 4272048, 18156204, 70607460, 254186856, 854992152, 2707475148, 8122425444, 23206929840, 63432274896, 166509721602, 421171648758, 1029530696964, 2438362177020, 5608233007146, 12551759587422, 27385657281648, 58343356817424, 121548660036300, 247959266474052, 495918532948104, 973469712824056, 1877405874732108, 3560597348629860, 6646448384109072, 12220888964329584, 22150361247847371, 39602161018878633, 1, 28, 406, 4060, 31465, 201376, 1107568, 5379616, 23535820, 94143280, 348330136, 1203322288, 3910797436, 12033222880, 35240152720, 98672427616, 265182149218, 686353797976, 1715884494940, 4154246671960, 9762479679106, 22314239266528, 49699896548176, 108043253365600, 229591913401900, 477551179875952, 973469712824056, 1946939425648112, 3824345300380220, 7384942649010080, 14031391033119152, 26252279997448736, 48402641245296107, 88004802264174740, 1, 29, 435, 4495, 35960, 237336, 1344904, 6724520, 30260340, 124403620, 472733756, 1676056044, 5586853480, 17620076360, 52860229080, 151532656696, 416714805914, 1103068603890, 2818953098830, 6973199770790, 16735679449896, 39049918716424, 88749815264600, 196793068630200, 426384982032100, 903936161908052, 1877405874732108, 3824345300380220, 7648690600760440, 15033633249770520, 29065024282889672, 55317304280338408, 103719945525634515, 191724747789809255, 1, 30, 465, 4960, 40920, 278256, 1623160, 8347680, 38608020, 163011640, 635745396, 2311801440, 7898654920, 25518731280, 78378960360, 229911617056, 646626422970, 1749695026860, 4568648125690, 11541847896480, 28277527346376, 67327446062800, 156077261327400, 352870329957600, 779255311989700, 1683191473897752, 3560597348629860, 7384942649010080, 15033633249770520, 30067266499541040, 59132290782430712, 114449595062769120, 218169540588403635, 409894288378212890, 1, 31, 496, 5456, 46376, 324632, 1947792, 10295472, 48903492, 211915132, 847660528, 3159461968, 11058116888, 36576848168, 114955808528, 344867425584, 991493848554, 2741188875414, 7309837001104, 18851684897584, 47129212243960, 114456658306760, 270533919634160, 623404249591760, 1402659561581460, 3085851035479212, 6646448384109072, 14031391033119152, 29065024282889672, 59132290782430712, 118264581564861424, 232714176627630544, 450883717216034179, 860778005594247069, 1, 32, 528, 5984, 52360, 376992, 2324784, 12620256, 61523748, 273438880, 1121099408, 4280561376, 15338678264, 51915526432, 166871334960, 511738760544, 1503232609098, 4244421484512, 11554258485616, 30405943383200, 77535155627160, 191991813933920, 462525733568080, 1085929983159840, 2488589544741300, 5574440580220512, 12220888964329584, 26252279997448736, 55317304280338408, 114449595062769120, 232714176627630544, 465428353255261088, 916312070471295267, 1777090076065542336, 1, 33, 561, 6545, 58905, 435897, 2760681, 15380937, 76904685, 350343565, 1471442973, 5752004349, 21090682613, 73006209045, 239877544005, 751616304549, 2254848913647, 6499270398159, 18053528883775, 48459472266975, 125994627894135, 317986441828055, 780512175396135, 1866442158555975, 4355031703297275, 9929472283517787, 22150361247847371, 48402641245296107, 103719945525634515, 218169540588403635, 450883717216034179, 916312070471295267, 1832624140942590534, 3609714217008132870, 1, 34, 595, 7140, 66045, 501942, 3262623, 18643560, 95548245, 445891810, 1917334783, 7669339132, 28760021745, 101766230790, 341643774795, 1093260079344, 3348108992991, 9847379391150, 27900908274925, 76360380541900, 202355008436035, 520341450264090, 1300853625660225, 3167295784216200, 7522327487513475, 17451799771031262, 39602161018878633, 88004802264174740, 191724747789809255, 409894288378212890, 860778005594247069, 1777090076065542336, 3609714217008132870, 7219428434016265740] |
| SR-337 | DAG distances | C(68,34) overflows: traps | `CountingSemiring<Int>` | `D: grid(35,35)` | `dagShortestDistances(from: 0)` | **trap** (overflow) |
| SR-338 | Agreement | against NetworkX all_simple_edge_paths | `CountingSemiring<Int>` | `D[10]: dlcg(10,25,11;1..3)` | `dagShortestDistances(from: 0)` | [1, 2, 4, 19, 40, 80, 46, 436, 189, 1044] |
| SR-339 | Agreement | against NetworkX all_simple_edge_paths | `CountingSemiring<Int>` | `D[10]: dlcg(10,25,12;1..3)` | `dagShortestDistances(from: 0)` | [1, 0, 0, 0, 0, 1, 0, 5, 16, 49] |
| SR-340 | Agreement | against NetworkX all_simple_edge_paths | `CountingSemiring<Int>` | `D[10]: dlcg(10,25,13;1..3)` | `dagShortestDistances(from: 0)` | [1, 2, 0, 2, 9, 6, 27, 91, 64, 198] |
| SR-341 | Phase 2: star | a.star (Lehmann) | `TropicalSemiring<Int>` | `a = 5` | `a.star` | 0 |
| SR-342 | Phase 2: star | a.star (Lehmann) | `TropicalSemiring<Int>` | `a = 0` | `a.star` | 0 |
| SR-343 | Phase 2: star | a.star (Lehmann) | `TropicalSemiring<Int>` | `a = -1` | `a.star` | Int.min |
| SR-344 | Phase 2: star | a.star (Lehmann) | `TropicalSemiring<Int>` | `a = Int.max` | `a.star` | 0 |
| SR-345 | Phase 2: star | a.star (Lehmann) | `TropicalSemiring<Double>` | `a = 2.5` | `a.star` | 0.0 |
| SR-346 | Phase 2: star | a.star (Lehmann) | `TropicalSemiring<Double>` | `a = 0.0` | `a.star` | 0.0 |
| SR-347 | Phase 2: star | a.star (Lehmann) | `TropicalSemiring<Double>` | `a = -0.5` | `a.star` | -.infinity |
| SR-348 | Phase 2: star | a.star (Lehmann) | `TropicalSemiring<Double>` | `a = .infinity` | `a.star` | 0.0 |
| SR-349 | Phase 2: star | a.star (Lehmann) | `BottleneckSemiring<Int>` | `a = 5` | `a.star` | Int.max |
| SR-350 | Phase 2: star | a.star (Lehmann) | `BottleneckSemiring<Int>` | `a = Int.min` | `a.star` | Int.max |
| SR-351 | Phase 2: star | a.star (Lehmann) | `BooleanSemiring` | `a = true` | `a.star` | true |
| SR-352 | Phase 2: star | a.star (Lehmann) | `BooleanSemiring` | `a = false` | `a.star` | true |
| SR-353 | Phase 2: Kleene closure | no negative cycle: Floyd–Warshall's matrix | `TropicalSemiring<Int>` | `D[5]: 0>1:4, 0>2:1, 2>1:2, 1>3:1, 2>3:5` | `kleeneClosure()` | [0, 3, 1, 4, —; —, 0, —, 1, —; —, 2, 0, 3, —; —, —, —, 0, —; —, —, —, —, 0] |
| SR-354 | Phase 2: Kleene closure | negative cycle: −∞ through it | `TropicalSemiring<Int>` | `D[4]: 0>1:1, 1>2:-3, 2>1:1, 2>3:2` | `kleeneClosure()` | [0, Int.min, Int.min, Int.min; —, Int.min, Int.min, Int.min; —, Int.min, Int.min, Int.min; —, —, —, 0] |
| SR-355 | Phase 2: Kleene closure | a negative loop | `TropicalSemiring<Int>` | `D[3]: 0>0:-1, 1>0:2, 0>2:3` | `kleeneClosure()` | [Int.min, —, Int.min; Int.min, 0, Int.min; —, —, 0] |
| SR-356 | Phase 2: Kleene closure | no negative cycle: Floyd–Warshall's matrix | `TropicalSemiring<Double>` | `D[5]: 0>1:4, 0>2:1, 2>1:2, 1>3:1, 2>3:5` | `kleeneClosure()` | [0.0, 3.0, 1.0, 4.0, —; —, 0.0, —, 1.0, —; —, 2.0, 0.0, 3.0, —; —, —, —, 0.0, —; —, —, —, —, 0.0] |
| SR-357 | Phase 2: Kleene closure | negative cycle: −∞ through it | `TropicalSemiring<Double>` | `D[4]: 0>1:1, 1>2:-3, 2>1:1, 2>3:2` | `kleeneClosure()` | [0.0, -.infinity, -.infinity, -.infinity; —, -.infinity, -.infinity, -.infinity; —, -.infinity, -.infinity, -.infinity; —, —, —, 0.0] |
| SR-358 | Phase 2: Kleene closure | a negative loop | `TropicalSemiring<Double>` | `D[3]: 0>0:-1, 1>0:2, 0>2:3` | `kleeneClosure()` | [-.infinity, —, -.infinity; -.infinity, 0.0, -.infinity; —, —, 0.0] |
| SR-359 | Phase 2: Kleene closure | widest paths, cycles included | `BottleneckSemiring<Int>` | `D[4]: 0>1:3, 0>1:8, 1>2:2, 2>1:9, 1>3:5` | `kleeneClosure()` | [Int.max, 8, 2, 5; —, Int.max, 2, 5; —, 9, Int.max, 5; —, —, —, Int.max] |
| SR-360 | Phase 2: Kleene closure | reflexive transitive closure | `BooleanSemiring` | `D[6]: 0>1:true, 1>2:true, 2>0:true, 2>3:false, 3>4:true, 5>5:true` | `kleeneClosure()` | [true, true, true, —, —, —; true, true, true, —, —, —; true, true, true, —, —, —; —, —, —, true, true, —; —, —, —, —, true, —; —, —, —, —, —, true] |
| SR-361 | Phase 2: laws | ⊕ is associative | `LogSemiring<Double>` | `a = 1.0, b = 2.0, c = 0.5` | `(a ⊕ b) ⊕ c == a ⊕ (b ⊕ c)` | both ≈-0.104130605337 |
| SR-362 | Phase 2: laws | ⊕ is commutative | `LogSemiring<Double>` | `a = 1.0, b = 2.0, c = 0.5` | `a ⊕ b == b ⊕ a` | both ≈0.686738312482 |
| SR-363 | Phase 2: laws | zero is ⊕'s identity | `LogSemiring<Double>` | `a = 1.0, b = 2.0, c = 0.5` | `a ⊕ .zero == a` | both ≈1 |
| SR-364 | Phase 2: laws | ⊗ distributes over ⊕ from the left | `LogSemiring<Double>` | `a = 1.0, b = 2.0, c = 0.5` | `a ⊗ (b ⊕ c) == (a ⊗ b) ⊕ (a ⊗ c)` | both ≈1.29858672202 |
| SR-365 | Phase 2: laws | ⊕ is associative | `LogSemiring<Double>` | `a = .infinity, b = 0.25, c = 3.0` | `(a ⊕ b) ⊕ c == a ⊕ (b ⊕ c)` | both ≈0.188032410997 |
| SR-366 | Phase 2: laws | ⊕ is commutative | `LogSemiring<Double>` | `a = .infinity, b = 0.25, c = 3.0` | `a ⊕ b == b ⊕ a` | both ≈0.25 |
| SR-367 | Phase 2: laws | zero is ⊕'s identity | `LogSemiring<Double>` | `a = .infinity, b = 0.25, c = 3.0` | `a ⊕ .zero == a` | both .infinity |
| SR-368 | Phase 2: laws | ⊗ distributes over ⊕ from the left | `LogSemiring<Double>` | `a = .infinity, b = 0.25, c = 3.0` | `a ⊗ (b ⊕ c) == (a ⊗ b) ⊕ (a ⊗ c)` | both .infinity |
| SR-369 | Phase 2: Log | −log of the total probability of the paths | `LogSemiring<Double>` | `D[4]: 0>1:0.6931471805599453, 0>2:1.3862943611198906, 1>3:0.0, 2>3:0.6931471805599453` | `dagShortestDistances(from: 0)` | [≈0, ≈0.69314718056, ≈1.38629436112, ≈0.470003629246] |

369 rows.
