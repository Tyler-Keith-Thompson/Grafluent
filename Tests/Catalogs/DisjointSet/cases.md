# Test catalog: `DisjointSet`

The cases for `DisjointSet`, the only type in `DisjointSetModule`. Case IDs `DS-nn` are stable,
and each test's name starts with its ID.

Values marked **(ref)** come from `ref.py` (next to this file). It has two models. `DS` models
`DisjointSet`: one array with negative sizes at roots, union by size with ties won by the smaller
index, and path halving. `Naive` is an independent oracle: an owner array, member lists, and each
set's representative maintained from sizes and representatives alone. `cases.py` prints every
value in §2 (`cases.out`).

`check.py` cross-checks both models against scipy's `DisjointSet` and NetworkX's `UnionFind` on
2420 seeded random operation sequences (n ∈ {0, 1, 2, 3, 10, 50, 1000}). After every operation
it checks the union result, the set count and the set size. At the end it checks the exact
representative of every element, the parent forest itself, `subsets()` and its order, the labels,
and the partition. Values marked **(scipy)** are assertions from scipy's tests that hold under the
same linking rule. `rules.py` replays alternative linking rules (by rank, or with ties won by the
first or second argument) on the cases that tell them apart.

The Source column cites the file and lines a case was translated from, or the behavior (Dn) it
checks.

## 1. Behavior the cases refer to

| # | Behavior |
|---|---|
| D3 | Union by size. The larger set's representative stays; for sets of the same size, the smaller of the two representatives stays, whatever the argument order. |
| D4 | Path halving inside `find` and `union`. It never changes a representative, so representatives depend only on the unions that merged sets. A `find` along a path that is already flat writes nothing. |
| D5 | `find` and `union` are `mutating`. `inSameSet`, `setSize(of:)`, `count`, `isEmpty`, `setCount`, `sets()`, `labels()`, `==`, `hash(into:)` and `description` never write and work on a `let`. |
| D6 | `sets()` lists the sets ordered by their smallest element, each in ascending order. It depends only on the partition. |
| D7 | `labels()` gives each element the position of its set in `sets()`, so labels run over `0..<setCount` in order of each set's smallest element. |
| D11 | Storage is one `[Int]`, where a root holds minus its set's size and any other element its parent, copied on write. `DisjointSet` is `Sendable`. |
| D12 | Two values are equal when they have the same `count` and the same partition. `hash(into:)` hashes `labels()`. The representative `find` returns is not part of the value. |
| D13 | `description` lists the sets as `sets()` does, at most 16 sets and 16 elements per set, then `…`: `[[0, 1, 3, 4, 7], [2], [5, 6]]`. `debugDescription` is `DisjointSet(count: 8, setCount: 3, sets: [[0, 1, 3, 4, 7], [2], [5, 6]])`. No representatives appear, so equal values print alike. |
| D15 | `find` is a loop, not a recursion. Under D3 a tree's height is at most ⌊log₂ n⌋; root-to-root unions of equal sets reach it, as in DS-41's binomial tree (height 20 at n = 2²⁰). |

## 2. Test catalog

Every case runs on the public API alone. "reps" lists `find(x)` for x in `0..<count`. "sizes" lists `setSize(of: x)`. Where a library's own assertion is weaker than the exact value, the catalog gives both. All values are (ref) unless marked.

### A. Construction

| ID | Asserts | Expected | Source |
|---|---|---|---|
| DS-01 | The empty disjoint set | `DisjointSet()`: `count == 0`, `isEmpty`, `setCount == 0`, `sets() == []`, `labels() == []`, `description == "[]"` | pg:64-70 (`new_empty`) |
| DS-02 | `init(count: 0)` and one element | `DisjointSet(count: 0) == DisjointSet()`. `DisjointSet(count: 1)`: `find(0) == 0`, `setSize(of: 0) == 1`, `inSameSet(0, 0)`, `union(0, 0) == false`, `setCount == 1`, `sets() == [[0]]`, `labels() == [0]`, `!isEmpty` | — |
| DS-03 | The discrete partition | `DisjointSet(count: 8)`: reps `[0…7]`, `setCount == 8`, `sets() == [[0], [1], …, [7]]`, `labels() == [0, 1, …, 7]`, every size 1 | pg-T:10-17 (`find(i) == i`); sp-T:37-42 (`n_subsets == n`) |
| DS-04 | **Self-unions change nothing** | on `count: 8`: `union(i, i) == false` and `inSameSet(i, i)` for every i; afterwards `setCount == 8` and reps `[0…7]`; the value `==` a fresh `DisjointSet(count: 8)` | pg-T:16, 44, 75; sp-T:122-133 |
| DS-05 | `reserveCapacity` is invisible | `var d = DisjointSet(); d.reserveCapacity(100)`: `count == 0` and `d == DisjointSet()`; then 100 `makeSet()` calls give `d == DisjointSet(count: 100)`. `reserveCapacity(0)` on `count: 5` keeps it `==` | pg:271-283 |
| DS-06 | **`makeSet` from empty**: petgraph `uf_incremental`, translated | `makeSet()` returns 0, then 1, and `count == 2`. `union(0, 1)`. Then 2 and 3. `union(1, 3)`. Then 4. `union(1, 4)`. Then 5, 6 and 7, and `count == 8`. `union(4, 7)`, `union(5, 6)`. Now `inSameSet(0, 3)`, `inSameSet(1, 3)`, `!inSameSet(0, 2)`, `inSameSet(7, 0)`, `inSameSet(6, 5)`, `!inSameSet(6, 7)`, and `setCount == 3`. reps `[0, 0, 2, 0, 0, 5, 5, 0]`. The result is `==` DS-10's | pg-T:182-213 |
| DS-07 | `makeSet` on a non-empty set adds a singleton | `count: 3` after `union(0, 1)`: `makeSet() == 3`, `count == 4`, `setCount == 3`, `find(3) == 3`, `setSize(of: 3) == 1`, `!inSameSet(3, 0)`, `sets() == [[0, 1], [2], [3]]` | bgl:63-69; jgt-T:85-87 |

### B. Union

| ID | Asserts | Expected | Source |
|---|---|---|---|
| DS-08 | **Union returns whether it merged, and is idempotent** | `count: 4`: `union(0, 1) == true`, `union(0, 1) == false`, `union(1, 0) == false`; `setCount` goes 4 → 3 and stays 3 | pg:177-186; sp-ds:175-178 (docstring: `merge('b', 'b')` is `False`); lemon:126-132 |
| DS-09 | Transitivity and symmetry of `inSameSet` | `count: 8`: `union(0, 1)` gives `inSameSet(0, 1)`. Then `union(1, 3)`, `union(1, 4)`, `union(4, 7)` give `inSameSet(0, 7)`, `inSameSet(1, 3)`, `!inSameSet(0, 2)`, `inSameSet(7, 0)`. `union(5, 6)` gives `inSameSet(6, 5)` and `!inSameSet(6, 7)` | pg-T:69-94 (`uf_test_with_equiv`) and 97-122 |
| DS-10 | **petgraph `uf_test`, exact** | `count: 8`, unions `(0,1), (1,3), (1,4), (4,7), (5,6)`, all `true`. reps `[0, 0, 2, 0, 0, 5, 5, 0]`, `setCount == 3`, `sets() == [[0, 1, 3, 4, 7], [2], [5, 6]]`, `labels() == [0, 0, 1, 0, 0, 2, 2, 0]`, sizes `[5, 5, 1, 5, 5, 2, 2, 5]`. petgraph asserts the three sets (pg-T:32-34); Boost's or LEMON's tie rule would give reps `[1, 1, 2, 1, 1, 6, 6, 1]` (`rules.py`) | pg-T:10-35 |
| DS-11 | petgraph `labeling`: two chains joined | `count: 48`. `union(i + 1, i)` for i in 0..<24, then `union(i, i + 1)` for i in 25..<47: `setCount == 2`, with representatives {0, 25}. Then `union(23, 25)` and `union(24, 23)`: `setCount == 1`, every rep 0, `labels()` all 0 | pg-T:167-180 |
| DS-12 | **JGraphT `testUnionFind`, translated** (`"aaa"…"eee"` → 0…4, its `TreeSet` order) | `count: 5`, `setCount == 5`. `union(0, 1)` gives 4, with `inSameSet(0, 1)` and `!inSameSet(1, 2)`. `union(2, 3)` gives 3. `union(2, 4)` gives 2. `union(2, 4)` again returns `false` and leaves 2. `union(0, 4)` gives 1, and **every rep is 2**: the size-3 set {2, 3, 4} absorbs the size-2 set {0, 1}. Union by rank sees equal ranks and gives 0 (`rules.py`). `makeSet() == 5`, so `setCount == 2` and `count == 6` | jgt-T:39-89 |
| DS-13 | Boost `disjoint_set_test`, translated | `count: 4`: all six pairs not in the same set. `union(0, 1)`, `union(2, 3)` give `find(0) != find(3)`. `a = find(0) = 0 == find(1)` and `b = find(2) = 2 == find(3)`. `union(a, b) == true` (Boost `link`), so `inSameSet(a, b)` and `setCount == 1`, with every rep 0 | bgl-T:28-55 |
| DS-14 | **Boost's documented example under Grafluent's rule** | `count: 6`, unions `(0,1), (1,2), (3,4)`: reps `[0, 0, 0, 3, 3, 5]`, `inSameSet(0, 2)`, `!inSameSet(0, 5)`, `sets() == [[0, 1, 2], [3, 4], [5]]`. Boost prints `1 1 1 4 4 5`, because its tie gives the second root (bgl-d:66). The difference is D3 | bgl-EX (`disjoint_sets.cpp`, `.txt`) |
| DS-15 | NetworkX `test_subtree_union` | `count: 6` (0 unused), unions `(1,2), (3,4), (4,5), (1,5)`: `sets() == [[0], [1, 2, 3, 4, 5]]`, reps `[0, 3, 3, 3, 3, 3]` | nx-T:15-24 |
| DS-16 | **NetworkX `test_unbalanced_merge_weights`: the larger set's representative wins** | `count: 10`, {1, 2, 3} by `(1,2), (2,3)` and {4…9} by `(4,5)…(8,9)`: `setSize(of: 1) == 3`, `setSize(of: 4) == 6`, `find(4) == 4`. Then `union(1, 4)`: `find(1) == 4` ("`uf[1] == largest_root`"), `setSize(of: 1) == 9`, reps `[0, 4, 4, 4, 4, 4, 4, 4, 4, 4]` | nx-T:37-47 |
| DS-17 | NetworkX `test_unionfind_weights` (variadic unions as chains) | `count: 10`: `(1,4), (4,7), (2,5), (5,8), (3,6), (6,9)` all `true`; then `(1,2), (2,3)` `true` and `(3,4)…(8,9)` all `false`; `setSize(of: 1) == 9`; reps `[0, 1, 1, 1, 1, 1, 1, 1, 1, 1]` | nx-T:27-34 |
| DS-18 | **LEMON `unionfind_test`, translated** (items 1…10, 0 unused; `insert(x, find(y))` becomes `union(x, y)`) | `count: 11`. `union(1, 2)`, `union(1, 4)` and `union(3, 5)` return `true`; `union(2, 4)` returns `false`. `union(8, 5)`. Sizes of 4, 5, 6 and 2 are `3, 3, 1, 3`. `union(10, 9)`, then `union(8, 10) == true`. Sizes of 4, 9 and 8 are `3, 5, 5`. reps `[0, 1, 1, 3, 1, 3, 6, 7, 3, 3, 3]`, `setCount == 5`, `sets() == [[0], [1, 2, 4], [3, 5, 8, 9, 10], [6], [7]]`. `erase`/`split`/`eraseClass` (lemon-T:75-99) have no Grafluent counterpart | lemon-T:36-73 |

### C. The representative rule (D3), exactly

| ID | Asserts | Expected | Source |
|---|---|---|---|
| DS-19 | **Equal sizes: the smaller index wins, whatever the argument order** | `count: 4`: `union(3, 1)` and `union(1, 3)` both give reps `[0, 1, 2, 1]`. Under petgraph's and JGraphT's first-argument tie, `union(3, 1)` gives `[0, 3, 2, 3]` | sp-ds:166-168; sp-T:139-157 |
| DS-20 | **Larger set wins, whatever the indices** | `count: 8`: `union(5, 6)`, `union(6, 7)`, `union(0, 5)` → reps `[5, 1, 2, 3, 4, 5, 5, 5]` | sp-ds:166; nx-T:37-47 |
| DS-21 | **scipy `test_linear_union_sequence`**, n ∈ {10, 100} | Forwards, `union(i, i + 1)` for i = 0…n − 2: before each, `!inSameSet(i, i + 1)`; the union returns `true`; after it, `inSameSet(i, i + 1)` and `setCount == n − 1 − step`. Every rep is **0**. Backwards, i = n − 2…0: every rep is **n − 2** (8 and 98) (scipy). Either way, `union(0, n − 1) == false` at the end | sp-T:96-117 |
| DS-22 | **scipy `test_equal_size_ordering`, n = 10, exact pairs** | The pairs from `RandomState(0).shuffle` are `(2,8), (4,9), (1,6), (7,3), (0,5)`. Given as `(a, b)` and as `(b, a)`, every union returns `true` and reps are `[0, 1, 2, 3, 4, 0, 1, 3, 2, 4]`: each pair takes its smaller element (scipy asserts `elements[min(...)]`, sp-T:154) | sp-T:136-157 |
| DS-23 | **scipy `test_binary_tree`**, kmax ∈ {5, 10} (n = 32, 1024) | For k = 1, 2, 4, … < n, for each block start i (step 2k): pick any a in `i..<i+k` and b in `i+k..<i+2k` (scipy uses `RandomState(0)`; a `SeededRandomNumberGenerator` works, since the result does not depend on the picks). Then `!inSameSet(a, b)`, `union(a, b) == true`, `inSameSet(a, b)`. After each round, `find(x) == x − x % (2k)` for every x (scipy) | sp-T:160-179 |
| DS-24 | **`find` never changes a representative** | `count: 10` after DS-28's unions: call `find`, `inSameSet`, `setSize(of:)`, `sets()` and `labels()` on every element in random order, three times over. reps stay `[0, 7, 2, 0, 2, 0, 7, 7, 7, 7]` throughout. A failed `union` changes nothing either. ("as long as the set remains unchanged it will keep the same name", nx:15-17) | nx:15-17; D4 |
| DS-25 | **Argument order never matters** | Seeds 1…10, n = 200, 400 random pairs. Build `p` with `union(a, b)` and `q` with `union(b, a)`: the union results match pair by pair, and reps of p and q are identical (not merely `==`) | D3 |

### D. Counts and sizes

| ID | Asserts | Expected | Source |
|---|---|---|---|
| DS-26 | `setCount` law | seeds 1…10, n ∈ {1, 10, 100}, 3n random unions with some `makeSet()` calls: `setCount == count − (number of unions that returned true)` after every step | jgt:164; sp-ds:191 |
| DS-27 | Size laws | same runs: `setSize(of: x) == sets()[labels()[x]].count` for every x; the sizes of the sets add up to `count`; after a `true` union of a and b, `setSize(of: a)` is the sum of the two sizes before it | sp-T:192 (`subset_size == len(subset)`) |

### E. `sets()` and `labels()`

| ID | Asserts | Expected | Source |
|---|---|---|---|
| DS-28 | **scipy `test_subsets`, n = 10, exact trace** | pairs (`RandomState(0).randint(0, 10, (10, 2))`): `(5,0) T, (3,3) F, (7,9) T, (3,5) T, (2,4) T, (7,6) T, (8,8) F, (1,6) T, (7,7) F, (8,1) T`. `sets()` after each: `[[0,5],[1],[2],[3],[4],[6],[7],[8],[9]]`; unchanged; `[[0,5],[1],[2],[3],[4],[6],[7,9],[8]]`; `[[0,3,5],[1],[2],[4],[6],[7,9],[8]]`; `[[0,3,5],[1],[2,4],[6],[7,9],[8]]`; `[[0,3,5],[1],[2,4],[6,7,9],[8]]`; unchanged; `[[0,3,5],[1,6,7,9],[2,4],[8]]`; unchanged; `[[0,3,5],[1,6,7,8,9],[2,4]]`. Final reps `[0, 7, 2, 0, 2, 0, 7, 7, 7, 7]`, labels `[0, 1, 2, 0, 2, 0, 1, 1, 1, 1]`, sizes `[3, 5, 2, 3, 2, 3, 5, 5, 5, 5]`. scipy's own assertions (order of `subsets()` and `subset_size == len(subset)`) hold at every step | sp-T:182-199 |
| DS-29 | **Labels number sets by their first element, not by representative** | `count: 5` after `union(3, 0)`, `union(4, 1)`: `labels() == [0, 1, 2, 0, 1]`, `sets() == [[0, 3], [1, 4], [2]]`. `count: 4` after `union(2, 3)`, `union(0, 2)`: reps `[2, 1, 2, 2]` but `labels() == [0, 1, 0, 0]` and `sets() == [[0, 2, 3], [1]]` (numbering by representative would give `[1, 0, 1, 1]`) | sp-cc:88-92; `GF:Sources/Connectivity/WeaklyConnectedComponents.swift:64-78` |
| DS-30 | Consistency, and both work on a `let` | for every run of DS-26: `sets().count == setCount`; `sets().joined().sorted() == Array(0..<count)`; each set ascending and sets ordered by first element; `sets()[labels()[x]].contains(x)`; `labels().max() == setCount − 1` (or empty); and `let snapshot = d` compiles and calls `sets()`, `labels()`, `setCount`, `count`, `description` | D5, D6, D7 |

### F. Equality and hashing

| ID | Asserts | Expected | Source |
|---|---|---|---|
| DS-31 | **Same partition, different representatives: equal** | `A = count: 3, union(1, 2), union(0, 1)` → reps `[1, 1, 1]`; `B = count: 3, union(0, 1), union(1, 2)` → reps `[0, 0, 0]`; `A == B`, `A.hashValue == B.hashValue`, `A.description == B.description == "[[0, 1, 2]]"`; and `A.find(0) != B.find(0)` (the documented non-value aspect, D12). Also: the 400 pairs of DS-25 applied in forward and reversed order give equal values | `GF:README.md:294`; sw:Equatable.swift:112-117 |
| DS-32 | Inequality | `DisjointSet(count: 3) != DisjointSet(count: 4)`; `count: 4` with `union(0, 1)` ≠ with `union(2, 3)` ≠ with nothing; `{0,1},{2,3}` ≠ `{0,2},{1,3}` (same `setCount`, same sizes); `count: 4` with `union(0, 1)` ≠ `count: 5` with `union(0, 1)` | — |
| DS-33 | Equality laws | reflexive after finds (`var c = d; _ = c.find(7); c == d`); `Set([A, B, DisjointSet(count: 3)]).count == 2`; equal after building the same partition via `makeSet()` vs `init(count:)` | D12 |

### G. Value semantics

| ID | Asserts | Expected | Source |
|---|---|---|---|
| DS-34 | **A union on a copy leaves the original alone** | `var a = DisjointSet(count: 4); a.union(0, 1); var b = a; b.union(2, 3)`: `a.setCount == 3`, `!a.inSameSet(2, 3)`, `a.sets() == [[0, 1], [2], [3]]`; `b.sets() == [[0, 1], [2, 3]]`; and the other way round (mutate `a`, check `b`) | `GF:README.md:298-300` |
| DS-35 | **A compressing `find` on a copy changes neither** | the binomial tree of DS-41 at n = 2¹⁰: `var b = a; for x in 0..<1024 { _ = b.find(x) }`: `a == b`, reps of `a` still all 0; then `a.makeSet()`: `b.count == 1024` | D4, D11 |
| DS-36 | `makeSet` and `reserveCapacity` on a copy | `var b = a; b.makeSet(); b.reserveCapacity(10_000)`: `a.count` unchanged, `a == ` its earlier value | — |

### H. Preconditions (exit tests)

| ID | Asserts | Expected | Source |
|---|---|---|---|
| DS-37 | **Out-of-range elements trap** | `await #expect(processExitsWith: .failure)` for each, on `DisjointSet(count: 8)`: `find(-1)`, `find(8)`, `union(0, 8)`, `union(8, 0)`, **`union(8, 8)`** (petgraph would return `false`, pg:192-194), `inSameSet(0, 8)`, `inSameSet(-1, 0)`, `setSize(of: 8)`; on `DisjointSet()`: `find(0)`, `union(0, 0)` | sp-T:82-95; pg-T:215-236; jgt:107-110, 142-144 |
| DS-38 | Negative counts trap | `DisjointSet(count: -1)`; `reserveCapacity(-1)` | `GF:Sources/CompressedSparseRowModule/CompressedSparseRow.swift:89-93` |

### I. Large inputs (10⁶, run in a `Task` like the Connectivity deep cases)

| ID | Asserts | Expected | Source |
|---|---|---|---|
| DS-39 | **Chains and a star at n = 10⁶** | (a) `union(i, i + 1)` for i in 0..<n − 1: all `true`, `setCount == 1`, every rep 0, `setSize(of: 0) == 1_000_000`. (b) The same in reverse, i = n − 2…0: every rep **999 998** (scipy's backwards law at scale). (c) `union(i + 1, i)` forwards: every rep 0. (d) `union(i, 0)` for i in 1..<n: every rep 0. In each, `labels()` is all zeros and `sets().count == 1` | sp-T:96-117 |
| DS-40 | **Randomized differential against a naive reference** | A test-local naive model: `owner: [Int]`, `members: [[Int]]`, and each set's representative updated by D3 from the two sizes and representatives. Seeds 1…30, n ∈ {1, 2, 10, 100, 1000}, 4n operations: 5 % `makeSet()`, otherwise random `union`, `inSameSet` or `setSize(of:)`. After every step it checks the result, `setCount`, `count` and the size. At the end it checks reps, `sets()`, `labels()`, and `==` with a value rebuilt from the naive partition in a different union order | `check.py` (same oracle, cross-checked against scipy and NetworkX) |
| DS-41 | **Maximum height: the binomial tree**, n = 2²⁰ | for k = 1, 2, 4, …, 2¹⁹ and i stepping by 2k: `union(i, i + k)`. Both arguments are roots of equal-size sets, so every call returns `true` and no compression happens. Element n − 1 sits at depth 20 (internal). Then `setCount == 1`, `find(n − 1) == 0`, and every rep is 0 | D15; (ref) |
| DS-42 | petgraph's `uf_rand` law | `count: 2¹⁴`, 100 random pairs, and `count: 256`, 2048 pairs (petgraph's `uf_u8` sizes): before each union compute `let separate = find(a) != find(b)`; then `union(a, b) == separate` | pg-T:124-164 |
| DS-43 | 10⁶ random unions, order independence | n = 10⁶, 10⁶ seeded random pairs: `setCount == n − trues`; the same pairs in reverse order (and with swapped arguments) give an `==` value with equal `labels()` | D12 |

### J. Descriptions and conformances

| ID | Asserts | Expected | Source |
|---|---|---|---|
| DS-44 | `description` / `debugDescription` | DS-10's value: `"[[0, 1, 3, 4, 7], [2], [5, 6]]"` and `"DisjointSet(count: 8, setCount: 3, sets: [[0, 1, 3, 4, 7], [2], [5, 6]])"`; `DisjointSet()` → `"[]"` and `"DisjointSet(count: 0, setCount: 0, sets: [])"`; `DisjointSet(count: 20)` lists 16 singletons then `…`; one set of 20 lists 16 elements then `…` | D13 |
| DS-45 | `Sendable` | a `DisjointSet` crosses into a `Task` and back (compile-time) | D11 |
| DS-46 | Consumer patterns | petgraph's `connected_components` example: `count: 8`, union a→b→c→d→a and e→f→g→h→e (`(0,1),(1,2),(2,3),(3,0),(4,5),(5,6),(6,7),(7,4)`) returns `T, T, T, F, T, T, T, F`; `setCount == 2`; `labels() == [0, 0, 0, 0, 1, 1, 1, 1]`; then `union(1, 4) == true` and `setCount == 1`. The triangle `(0,1),(1,2),(2,0)` returns `T, T, F`, so the third edge closes the cycle | pg-algo:100-131, 171-178 |

## 3. Benchmarks (not tests)

All use n = 10⁶ unless stated. The baseline is a hand-written union–find: one `[Int]` with
negative sizes at the roots, union by size and path halving, inside a single buffer.

| ID | Measures |
|---|---|
| DS-B01 | `union` over 4 × 10⁶ seeded random pairs from fresh `init(count:)`, against the baseline |
| DS-B02 | `union` over already-merged pairs, against the baseline |
| DS-B03 | Kruskal-shaped unions over the edges of a seeded G(n, 4n) in shuffled order, stopping at one set, against the baseline |
| DS-B04 | `find` on every element of a fresh copy of the same unions, against the baseline; `inSameSet` on already-merged pairs |
| DS-B05 | `labels()` and `sets()`, against the baseline's numbering pass |
| DS-B07 | `weaklyConnectedComponents()` labels through `DisjointSet` on a `CompressedSparseRow`, against Connectivity's own `weaklyConnectedComponents()` |
| DS-B08 | `find` on every element of a shared, fully compressed copy, which must not copy the storage |
| DS-B09 | `==` on equal values built in different orders |
| DS-B10 | `init(count:)` against `[Int](repeating: -1, count:)`, and `makeSet()` 10⁶ times |
