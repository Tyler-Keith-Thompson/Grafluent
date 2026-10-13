# Test catalog: `IndexedPriorityQueue`

The cases for `IndexedPriorityQueue`, the only type in `PriorityQueueModule`. Case IDs `PQ-nn` are
stable, and each test's name starts with its ID.

Values marked **(ref)** come from `ref.py` (next to this file), whose output is `cases.out`. It
has two models. `IPQ` models the queue: a 4-ary min-heap of `(priority, index)` pairs plus a
position array, with strict `<` comparisons only and no tie-break by index. `Naive` is an
independent oracle: a dictionary from index to priority, whose minimum is a scan that reports
every index tied at the minimum, so expectations never depend on a tie order. `ref.py` runs
PQ-20 – PQ-23, checks the Dijkstra graph of PQ-22 against Bellman–Ford and against `IPQ`
at arities 2, 3, 4 and 8, checks the heap invariant after every operation of PQ-23, and runs 2000
seeded random operation sequences against `Naive`. Where a value is tied, the catalog gives the
priority exactly and the tied indices as a set.

The Source column cites the file and lines a case was translated from, or the behavior (Dn) it
checks.

## 1. Behavior the cases refer to

| # | Behavior |
|---|---|
| D5 | Equal priorities come out in an unspecified order. `min` changes only when a strictly smaller priority arrives (by `insert`, `decreasePriority` or `updatePriority`), or when the current minimum leaves (`popMin`, `removeMin`, `remove`) or its priority increases. |
| D6 | An index is either queued or not. `popMin`, `remove` and `removeAll` return an index to "not queued", so an emptied queue equals a fresh one. |
| D8 | `decreasePriority(of:to:)` requires a queued index and a priority that is not greater; an equal priority is a no-op. `updatePriority(of:to:)` requires a queued index, moves it either way, and returns the old priority. |
| D13 | `description` lists the pairs sorted by priority, then index, at most 16, then `…`: `[4: 0.5, 1: 2.0, 7: 2.0]`; empty is `[]`. `debugDescription` is `IndexedPriorityQueue<Double>(indexBound: 10, [4: 0.5, 1: 2.0, 7: 2.0])`. |

## 2. Consumer loops

PQ-32 and PQ-33 write these loops inside the test.

```swift
// Dijkstra in index space. `dist` doubles as "seen".
var queue = IndexedPriorityQueue<Weight>(indexBound: n)
queue.insert(source, priority: .zero)
dist[source] = .zero
while let (u, du) = queue.popMin() {
    for (v, w) in neighbors(u) {
        let nd = du + w
        guard nd < dist[v] else { continue }
        if queue.contains(v) { queue.decreasePriority(of: v, to: nd) } else { queue.insert(v, priority: nd) }
        dist[v] = nd
        predecessor[v] = u
    }
}

// Prim: a separate set marks the tree, since a popped index is "not queued" (D6).
while let (u, _) = queue.popMin() {
    inTree.insert(u)
    for (v, w) in neighbors(u) where !inTree.contains(v) {
        if let key = queue.priority(of: v) { if w < key { queue.decreasePriority(of: v, to: w) } }
        else { queue.insert(v, priority: w) }
    }
}
```

## 3. Test catalog

Every case runs on the public API alone. "drain" means `popMin()` until `nil`, collecting `(index, priority)`. **"≡"** compares a drained list with an expected one up to ties: the priority sequences must be equal, and within each run of equal priorities the indices must be equal as sets. Every value is (ref) unless it is marked otherwise.

### A. Basics

| ID | Asserts | Expected | Source |
|---|---|---|---|
| PQ-01 | **Empty** | `IndexedPriorityQueue<Int>(indexBound: 0)`: `count == 0`, `isEmpty`, `min == nil`, `popMin() == nil`, `unordered.isEmpty`, `description == "[]"`. `indexBound: 5`: for every i, `!contains(i)` and `priority(of: i) == nil`; `remove(3) == nil`, still empty | sc-T:46-55 (`test_isEmpty`), sc-T:179-181; nx-T:33-38 |
| PQ-02 | **Single** | `indexBound: 1`, `insert(0, priority: 7)`: `count == 1`, `!isEmpty`, `min! == (0, 7)`, `contains(0)`, `priority(of: 0) == 7`; `popMin()! == (0, 7)`; then empty, `!contains(0)`, `popMin() == nil` | sc-T:213-219 |
| PQ-03 | Ordering, distinct priorities | `indexBound: 8`, inserts `(5,50) (2,20) (7,70) (0,0) (3,30) (6,60) (1,10) (4,40)`: drain `== [(0,0), (1,10), …, (7,70)]` | sc-T:179-194 (`test_min`) |
| PQ-04 | **The tie rule (D5)** | `indexBound: 6`. `insert(4, priority: 1)`. Then `insert(i, priority: 1)` for i in 0…3, after each `min!.index == 4` (an equal insert never displaces the minimum). `insert(5, priority: 0)` gives `min! == (5, 0)`. Drain: first `(5, 0)`, then five pairs of priority 1 whose indices are `{0, 1, 2, 3, 4}`. **Not** asserted: their order | sc-heap:45-50; D5 |
| PQ-05 | **Decrease-key to the top** | `indexBound: 20`, `insert(i, 100 + i)` for all i. `decreasePriority(of: 19, to: 0)` gives `min! == (19, 0)`, `priority(of: 19) == 0` and `count == 20`. `decreasePriority(of: 10, to: 50)` twice (the second, equal call is a no-op). Drain `== [(19,0), (10,50), (0,100), …, (9,109), (11,111), …, (18,118)]` | lemon-bin:270-280; CLRS |
| PQ-06 | **Increase via `updatePriority`** | `indexBound: 10`, `insert(i, i)`. `updatePriority(of: 0, to: 1000) == 0` gives `min! == (1, 1)` and `priority(of: 0) == 1000`. `updatePriority(of: 5, to: -1) == 5` gives `min! == (5, -1)`. `updatePriority(of: 7, to: 7) == 7`. Drain `== [(5,-1), (1,1), (2,2), (3,3), (4,4), (6,6), (7,7), (8,8), (9,9), (0,1000)]` | lemon-bin:282-291; ig-h:985-992 |
| PQ-07 | **Remove from the middle, where the moved last pair must sift *up*** | `indexBound: 21`, `insert(i, L[i])` with `L = [0, 45, 50, 60, 40, 46, 47, 48, 49, 51, 52, 53, 54, 61, 62, 63, 64, 41, 42, 43, 44]` (heap order for d = 4, so no insert moves). `remove(5) == 46`, `!contains(5)`, `count == 20`, and `remove(5) == nil`. Drain `== [(0,0), (4,40), (17,41), (18,42), (19,43), (20,44), (1,45), (6,47), (7,48), (8,49), (2,50), (9,51), (10,52), (11,53), (12,54), (3,60), (13,61), (14,62), (15,63), (16,64)]`. A remove that only sifts down yields priorities `…43, 45, 44, 47…` | lemon-bin:228-238; `plant.py` |
| PQ-08 | Remove the minimum, the last slot, the rest | `indexBound: 6`, `insert(i, 10 − i)`. `remove(5) == 5` gives `min! == (4, 6)`. `remove(0) == 10`, `remove(2) == 8`. Drain `== [(4,6), (3,7), (1,9)]` | lemon-bin:228-238 |
| PQ-09 | **Re-insert after pop and after remove** | `indexBound: 4`. `insert(3, 5)`, `popMin()! == (3, 5)`, `!contains(3)`. `insert(3, 1)` gives `priority(of: 3) == 1`. `insert(0, 0)`, `remove(0) == 0`, `insert(0, 2)`. Drain `== [(3,1), (0,2)]` | lemon-bin:295-299 (an item "will get back to the heap again") |
| PQ-10 | **States through `contains` and `priority(of:)`** | `indexBound: 5`. Index 2: never inserted gives `false`/`nil`; `insert(2, 9)` gives `true`/`9`; `decreasePriority(of: 2, to: 4)` gives `4`; `updatePriority(of: 2, to: 6)` gives `6`. Index 1: `insert(1, 1)` then `popMin()! == (1, 1)` gives `false`/`nil`. `remove(2)` gives `false`/`nil`. Then `insert(i, -i)` for all i, `removeAll()`: `isEmpty`, no index is contained. `insert(4, 3)` gives `min! == (4, 3)` and `count == 1` (D6: emptied equals fresh) | lemon-bin:295-306; bgl-dh:174-178 |
| PQ-11 | `count` and `isEmpty` through a sequence | `insert ×3 → 3`, `decreasePriority → 3`, `updatePriority → 3`, `popMin → 2`, `remove(present) → 1`, `remove(absent) → 1`, `removeMin → 0` and `isEmpty` | sc-T:57-69 (`test_count`) |
| PQ-12 | `unordered` | after `insert(i, 10 − i)` for i in 0..<10 and `remove(3)`: `Set(unordered.map(\.index)) == {0,1,2,4,…,9}`, and every pair has `priority == 10 − index`. `unordered.count == count` | sc-T:92-95 (`test_unordered`) |
| PQ-13 | `reserveCapacity` and `removeAll(keepingCapacity:)` are invisible | `reserveCapacity(1000)` on `indexBound: 10` leaves it empty, and PQ-03's operations then give the same drain. `removeAll(keepingCapacity: true)` gives the same states as PQ-10's `removeAll()` | sc-heap:104-139 |
| PQ-14 | `indexBound` | `IndexedPriorityQueue<Double>(indexBound: 7).indexBound == 7`, unchanged by inserts, pops and `removeAll` | — |

### B. Fixed sequences (exact values)

| ID | Asserts | Expected | Source |
|---|---|---|---|
| PQ-20 | **LEMON `heapSortTest`** | `indexBound: 14`, `insert(i, test_seq[i])` with `test_seq = [2, 28, 19, 27, 33, 25, 13, 41, 10, 26, 1, 9, 4, 34]`. Drain `== [(10,1), (0,2), (12,4), (11,9), (8,10), (6,13), (2,19), (5,25), (9,26), (3,27), (1,28), (4,33), (13,34), (7,41)]`. LEMON checks only the priorities | lemon-T:87, 92-107 |
| PQ-21 | **LEMON `heapIncreaseTest`** (`increase` → `updatePriority`) | after PQ-20's inserts, `updatePriority(of: i, to: test_seq[i] + test_inc[i])` with `test_inc = [20, 28, 34, 16, 0, 46, 44, 0, 42, 32, 14, 8, 6, 37]`. That gives `[22, 56, 53, 43, 33, 71, 57, 41, 52, 58, 15, 17, 10, 71]`; index 4's call is an equal update. Drain ≡ `[(12,10), (10,15), (11,17), (0,22), (4,33), (7,41), (3,43), (8,52), (2,53), (1,56), (6,57), (9,58), {5, 13} at 71]` | lemon-T:88, 109-128 |
| PQ-22 | **LEMON `dijkstraHeapTest` graph**, with a test-local Dijkstra written on the queue | the 20 arcs of `test_lgf` (lemon-T:49-84) from source 3: `dist == [105, 27, 45, 0, 168, 49, 78, 84, ∞, 11]` (node 8 unreached), equal to Bellman–Ford. Settle order (`popMin` sequence) `== [(3,0), (9,11), (1,27), (2,45), (5,49), (6,78), (7,84), (0,105), (4,168)]`, which has no ties. LEMON also checks `dist(t) − dist(s) ≤ len` on every arc, and equality on tree arcs | lemon-T:131-157 |
| PQ-23 | **igraph `2wheap` hand-made trace**, translated to a min-queue (PUSH → `insert`, MOD → `decreasePriority`, MAX → `popMin`; behavior only, GPL) | `indexBound: 21`, the 38 operations of ig-T:105-151. Popped priorities `== [0.0, 0.05, 0.12, 0.4, 0.4, 0.44, 1.1, 1.1, 1.1, 1.3, 1.3, 1.5, 1.6, 1.3, 1.3]`. Indices: `4, 15, 16`, then `{12, 13}`, `11`, `{0, 14, 20}`, `{7, 18}`, `17`, `19`, `{3, 6}`. At the end `count == 5`, holding `(1,2.3) (5,2.2) (8,1.6) (9,1.7) (10,2.3)`. Every tie set is drained before any operation touches its members, so the trace does not depend on tie order | ig-T:105-151 |
| PQ-24 | **NetworkX `test_heaps` data list**, translated (x → 0, None → 5, other keys unchanged; `insert` → `insert`/`decreasePriority`/`updatePriority` per D8) | `indexBound: 6`, `Double` priorities. `min`/`popMin` empty give `nil`. `priority(of: 0)` and `priority(of: 5)` are `nil`. `insert(0, 1)` gives `priority(of: 0) == 1` and `min == (0, 1)` twice (min does not pop). `insert(1, -2.0)` gives `min == (1, -2.0)`. `insert(3, -1e100)` and `insert(4, 5)`, then `popMin == (3, -1e100)` and `popMin == (1, -2.0)`. `decreasePriority(of: 4, to: -50)` and then `to: -60`: `count == 2` (no duplicate), `popMin == (4, -60)`, `popMin == (0, 1)`, empty. `insert(0, 0)` and `decreasePriority(of: 0, to: 0)` (no-op) give `min == (0, 0)` and `count == 1`, then pop gives `(0, 0)`, then `nil`. `insert(5, 0)`, `insert(2, -1)`, `min == (2, -1)`. `updatePriority(of: 2, to: 1) == -1` gives `min == (5, 0)`. Pops give `(5, 0)`, `(2, 1)`, then `nil` | nx-T:33-88 |
| PQ-25 | **NetworkX `_test_heap_class` coverage loop** (`indexBound: 100`; NetworkX's `insert` written at the call site as "absent → insert; smaller → decrease; `allow_increase` and larger → update", returning whether it inserted or decreased) | Inserting 99…0 with priority i: all `true`. 50 pops give `(i, i)` for i < 50. `insert(i, i)` returns `i < 50`. `insert(i, i + 1)` returns `false` for all i. 50 pops give `(i, i)`. `insert(i, i + 1)` returns `i < 50`. 49 pops give `(i, i + 1)` for i < 49. The next two pops are `{(49, 50), (50, 50)}` in either order (nx-T:114). Then for i in 51..<100, `insert(i, i + 1, allow_increase: true)` returns `false` but raises the priority. 19 pops give `(i, i + 1)` for i in 51..<70. `insert(i, i)` returns `true` for all i (an insert below 70, a decrease from 70 on). 100 pops give `(i, i)`, then `nil` | nx-T:91-125 |
| PQ-26 | **swift-collections `test_popMin`**, with indices assigned | `indexBound: 30`. `popMin() == nil`. `insert(0, 7)` → pop gives `(0, 7)`. `insert(1, 12)`, `insert(2, 9)` → pop gives `(2, 9)`. `insert(3, 13)`, `insert(4, 1)`, `insert(5, 4)` → pop gives `(4, 1)`. Then `insert(9 + v, v)` for v in a seeded shuffle of 1…20. The 23 popped priorities are `[1, 2, 3, 4, 4, 5, 6, 7, 8, 9, 10, 11, 12, 12, 13, 13, 14, …, 20]`, exactly Heap's (sc-T:233-255), ≡ with ties `{5, 13}` at 4, `{1, 21}` at 12 and `{3, 22}` at 13 | sc-T:213-258 |
| PQ-27 | **swift-collections `test_minimumReplacement`** (`replaceMin` → `updatePriority` on `min!.index`) | `indexBound: 10`, `insert(i, 3i)` in a seeded order. `min == (0, 0)`. Update to 0 gives `min == (0, 0)`; to -1 gives `(0, -1)`; to 2 gives `(0, 2)` ("larger, but not enough to usurp"); to 5 gives `min == (1, 3)`. Drain `== [(1,3), (0,5), (2,6), (3,9), …, (9,27)]` | sc-T:357-386 |
| PQ-28 | **swift-collections `test_tieBreaks_min`**: an equal update keeps the minimum | `indexBound: 5`, all at priority 1. Repeat while not empty: `let old = min!.index`, `updatePriority(of: old, to: 1)`, then `min!.index == old` and `removeMin() == (old, 1)`. The removed indices form `{0, 1, 2, 3, 4}` | sc-T:606-624 |
| PQ-29 | **swift-collections `test_removeAll_removeEvenNumbers`**, with `remove(_:)` | for count in 0..<20 and seeds 0..<10: insert a seeded shuffle of `(i, i)`, `remove(i) == i` for every even i; drain `== [(1,1), (3,3), …]` | sc-T:672-683 |

### C. Randomized and large (run in a `Task`, `.tags(.randomized)` like `DS-40`)

| ID | Asserts | Expected | Source |
|---|---|---|---|
| PQ-30 | **Interleaved operations against a naive reference** | A test-local reference: `[Int?]` priorities by index; its minimum is a scan that returns the minimum priority and the set of tied indices. Seeds 1…200, `indexBound` ∈ {1, 2, 3, 10, 50, 200}, 4n + 10 operations: 35 % `insert` (when absent), 15 % `decreasePriority` (when present), 10 % `updatePriority` (its result checked), 10 % `remove` (its result checked), 30 % `popMin`. Half the priorities come from 0..<8, so there are many ties. After every operation: `count`, `contains(j)` and `priority(of: j)` for a random j, and `min`'s priority and that its index is in the tie set. At the end, drain ≡ the reference sorted. `ref.py` runs 2000 such sequences with every j checked (69 312 934 checks) | `ref.py` `differential` |
| PQ-31 | **Heap-sort equivalence** | seeds 1…50, n ∈ {0, 1, 2, 7, 64, 1000}: random priorities in 0..<10⁹, inserted in a shuffled order. The drained priorities `== priorities.sorted()`, and drain ≡ `(i, p[i])` sorted by priority | sc-T:114-129 (`test_insert_random`, 5000 seeds × 128) |
| PQ-32 | Dijkstra on the queue equals Bellman–Ford | seeds 1…100: random digraphs, n ∈ {1, 5, 50, 300}, m = 4n, weights in 0…9 (zero included). A test-local Dijkstra (§2's loop) gives the same `dist` as a test-local Bellman–Ford, and every popped priority is ≥ the one before | lemon-T:131-157; bgl-perf:100-136 (`binary_heap_distances == relaxed_heap_distances`) |
| PQ-33 | Prim on the queue (§2's loop with a `[Bool]` tree set) equals a test-local Kruskal weight | seeds 1…50, connected random undirected graphs, n ≤ 300, weights in 1…20 | go-prim:139-144 |
| PQ-34 | **10⁶ permutation** | n = 10⁶, `insert(i, (i · 7919) % 10⁶)`. Pop k gives `((k · 17 679) % 10⁶, k)`, since 17 679 = 7919⁻¹ mod 10⁶. The first five are `(0,0), (17679,1), (35358,2), (53037,3), (70716,4)` and the last is `(982321, 999999)` | (ref) |
| PQ-35 | **Worst-case sifts at 10⁶** | `insert(i, n − 1 − i)` for i in 0..<n, each giving `min == (i, n − 1 − i)` (every insert climbs to the root). Then `decreasePriority(of: i, to: −1 − i)` for all i, each giving `min == (i, −1 − i)`. Drain `== [(n − 1, −n), (n − 2, −n + 1), …, (0, −1)]` | (ref; `plant.py` at n = 2000) |
| PQ-36 | **10⁶ Dijkstra against a bucket reference** | the 1000 × 1000 grid with seeded integer weights 1…100. Distances from vertex 0 equal those of a test-local Dial's algorithm (an array of buckets, independent of any heap), and the popped priorities never decrease | Dial's algorithm (cited by name) |
| PQ-37 | 10⁶ heap sort with ties | 10⁶ priorities from 0..<1000: drained priorities `== sorted()`; within each priority, the indices are exactly that priority's indices | — |

### D. Value semantics and conformances

| ID | Asserts | Expected | Source |
|---|---|---|---|
| PQ-40 | **A copy is independent** | `var a` with `insert(i, i)` for i in 0..<4; `var b = a`; then on b `insert(7, -1)`, `decreasePriority(of: 3, to: -5)`, `popMin()`, `remove(0)`. Now `a.count == 4`, `a.min == (0, 0)`, `!a.contains(7)`, `a.priority(of: 3) == 3`, `a` drains to `[(0,0), (1,1), (2,2), (3,3)]`, and `b` drains to `[(7,-1), (1,1), (2,2)]`. Also the other way round (mutate a, check b) | bgl-dh:23-26 (Boost's unsafe copy); `GF:README.md:298-301` |
| PQ-41 | Copy taken mid-drain | in a `while let` loop over `a`, take `let snapshot = a` at each step: `snapshot.count` stays what it was when taken, and draining the snapshot afterwards gives exactly the rest of `a`'s pops | — |
| PQ-42 | `Sendable` | a queue of `Double` crosses into a `Task` and back (compile-time) | sc-heap:74 |
| PQ-43 | `description` / `debugDescription` | `indexBound: 10` with `(1, 2.0)`, `(4, 0.5)`, `(7, 2.0)` inserted in any order: `"[4: 0.5, 1: 2.0, 7: 2.0]"` and `"IndexedPriorityQueue<Double>(indexBound: 10, [4: 0.5, 1: 2.0, 7: 2.0])"`. Two queues that reach the same contents by different operations print alike. Empty gives `"[]"`. 20 entries list 16, then `…` | D13; `GF:Sources/GraphProtocols/GraphDescription.swift:1-11` |

### E. Preconditions (exit tests, `.tags(.precondition)`)

| ID | Asserts | Expected | Source |
|---|---|---|---|
| PQ-50 | **Bad indices trap** | `await #expect(processExitsWith: .failure)` on `indexBound: 4` for `insert(4, …)`, `insert(-1, …)`, `contains(4)`, `priority(of: -1)`, `remove(4)`, `decreasePriority(of: 4, …)`, `updatePriority(of: -1, …)`; and on `indexBound: 0` for `contains(0)` | `GF:Sources/DisjointSetModule/DisjointSet.swift:70-80`; DS-37 |
| PQ-51 | **Misuse traps** | `insert` of an index already queued (`insert(1, 5); insert(1, 3)`); `decreasePriority(of: 1, to: 6)` when it holds 5; `decreasePriority`/`updatePriority` of an index not queued; `removeMin()` on an empty queue; `IndexedPriorityQueue<Int>(indexBound: -1)`; `reserveCapacity(-1)` | lemon-bin:177, 276; sc-heap:227-236 |
| PQ-52 | **NaN traps** | `insert(0, priority: .nan)`; `decreasePriority(of: 0, to: .nan)` and `updatePriority(of: 0, to: .nan)` on a queued 0 | sw:Comparable.swift:131-137; pg-sc:42-50 (petgraph's alternative) |

## 4. Benchmarks (not tests)

Inputs come from `BenchmarkSupport`'s seeded generator, on CSR graphs. The comparisons are a
hand-written indexed 4-ary heap in raw buffers, a hand-written lazy-deletion 4-ary heap, and
swift-collections' `Heap` with lazy deletion.

| ID | Measures |
|---|---|
| PQ-B01 | Dijkstra on G(10⁵, 10⁶) with `Int` weights 1…1000 and 1…4, and on G(10⁶, 4·10⁶) with weights 1…1000, with all four queues; on G(10⁵, 10⁶) with `Double` weights, against the hand-written indexed heap only |
| PQ-B02 | Heap sort of 10⁶ random `Int`s (insert all, pop all) |
| PQ-B03 | 10⁶ inserts, 10⁶ decrease-keys, pop all, against a lazy heap that re-pushes |
