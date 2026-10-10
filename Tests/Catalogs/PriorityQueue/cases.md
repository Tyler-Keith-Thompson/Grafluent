# Test catalog and design: `IndexedPriorityQueue`

This catalog covers Grafluent's planned `IndexedPriorityQueue`, the only type in `PriorityQueueModule`. The module is a 3-line stub today (`GF:Sources/PriorityQueueModule/PriorityQueueModule.swift:1-3`). `scripts/modules.py` describes it as "IndexedPriorityQueue: a d-ary heap with decrease-key." with no dependencies (`GF:scripts/modules.py:25`). The README lists it as "A d-ary heap with a position array, giving O(log n) decrease-key", "**Not** a `Sequence`; it exposes an `unordered` view instead, as swift-collections' `Heap` does. `Sendable`." (`GF:README.md:293`). Its consumers are `ShortestPaths` (Dijkstra, A*, Johnson, Yen; `GF:scripts/modules.py:52`) and `SpanningTrees` (Prim; `GF:scripts/modules.py:53`), all working in vertex-index space `0..<vertexIndexBound` (`GF:Sources/GraphProtocols/DirectedGraph.swift:16-32, 97`).

It follows the format of `test-catalog-disjoint-set.md`: a cross-library comparison, a decision table with evidence, a recommended API, then the cases. Case IDs `PQ-nn` are stable, so test names can refer to them.

**Sources** (shallow clones, Oct 2026, not kept in the repository):

| Library | Commit | Licence | What was used |
|---|---|---|---|
| Boost.Graph | `1ee1a99` | BSL-1.0 | `boost/graph/detail/d_ary_heap.hpp` (`d_ary_heap_indirect`), `boost/pending/mutable_queue.hpp`, `boost/pending/relaxed_heap.hpp`, `dijkstra_shortest_paths.hpp` (its default queue), `prim_minimum_spanning_tree.hpp`, `test/dijkstra_heap_performance.cpp` |
| LEMON | `31d79d6` | Boost-style | `lemon/bin_heap.h`, `quad_heap.h`, `dheap.h`, `fib_heap.h`, `radix_heap.h`, `bucket_heap.h`, `concepts/heap.h`, `dijkstra.h`, `test/heap_test.cc` (exact data: `test_seq`, `test_inc`, and a 10-node Dijkstra graph) |
| swift-collections | `3b69ced` | Apache-2.0 | `HeapModule/Heap.swift`, `Heap+Descriptions.swift`, `Tests/HeapTests/HeapTests.swift`, `Benchmarks/Sources/Benchmarks/HeapBenchmarks.swift`. **The Swift precedent for names and conformances.** |
| petgraph | `a4d94bd` | MIT OR Apache-2.0 | `src/algo/dijkstra.rs`, `astar.rs`, `min_spanning_tree.rs`, `src/scored.rs` (`MinScored`) |
| NetworkX | `6da4704` | BSD-3-Clause | `utils/heaps.py` (`BinaryHeap`, `PairingHeap`), `utils/tests/test_heaps.py` (exact op list), `algorithms/shortest_paths/weighted.py`, `astar.py`, `tree/mst.py` |
| JGraphT | `63976aa` | EPL-2.0 OR LGPL-2.1+ | `DijkstraClosestFirstIterator.java`, `IntVertexDijkstraShortestPath.java`, `PrimMinimumSpanningTree.java` (all on jheaps 0.16, not cloned; jheaps is cited only through these call sites) |
| igraph | `912f99d` | GPL-2.0+ (**behavior reference only; no code copied**) | `src/core/indheap.c` (`igraph_2wheap_*`), `src/paths/dijkstra.c`, `tests/unit/2wheap.c` (a hand-made operation trace, translated as data) |
| gonum | `0d48cee` | BSD-3-Clause | `graph/path/dijkstra.go`, `a_star.go`, `spanning_tree.go` |
| rustworkx | `25398ab` | Apache-2.0 | `rustworkx-core/src/shortest_path/dijkstra.rs`, `astar.rs`, `min_scored.rs` |
| pathfinding | `cd4600b` | Apache-2.0/MIT | `src/directed/dijkstra.rs`, `astar.rs` (`SmallestHolder`, `SmallestCostHolder`) |
| gapbs | `2972aeb` | BSD-style | `src/sssp.cc` (Δ-stepping; its serial verifier is a lazy-deletion Dijkstra) |
| scipy | `ec1861f` | BSD-3-Clause | `scipy/sparse/csgraph/_shortest_path.pyx` (sparse checkout; read with `git show`) |
| Swift stdlib | `5dc8186` | Apache-2.0 | `Comparable.swift` (exceptional values such as NaN) |

Sedgewick and Wayne's `IndexMinPQ` (*Algorithms*, 4th ed., §2.4) and CLRS's `DECREASE-KEY` are cited by name only; neither is in a clone.

**How the expectations were computed.** Values marked **(ref)** come from `ref.py` (next to this file). It has two models. `IPQ` is the recommended design: a 4-ary min-heap of `(priority, index)` pairs plus a position array, with strict `<` comparisons only and no tie-break by index (D5). `Naive` is an independent oracle: a dictionary from index to priority, whose minimum is a scan that reports *every* index tied at the minimum, so expectations never depend on a tie order. `ref.py` replays LEMON's `heapSortTest`/`heapIncreaseTest` data, LEMON's Dijkstra test graph (cross-checked against Bellman–Ford and against `IPQ` at arities 2, 3, 4 and 8), igraph's hand-made trace (with an invariant check after every operation), and 2000 seeded random operation sequences against `Naive` (69 312 934 checks, all pass). Its output is `cases.out`. `plant.py` encodes the catalog's cases PQ-01–10, 20–31, 34, 35, 40 and 50 in Python against the public operations only, runs them on the clean model at arities 2, 3, 4 and 8 (all pass), then on 15 planted bugs, and lists the cases that catch each one (§Q, `plant.out`). Where a value is tied, the catalog gives the priority exactly and the tied indices as a set.

**How the performance numbers were measured.** `proto/` was a scratch SwiftPM package (not kept). Its `PQProto` library holds `@frozen`, `@inlinable` prototypes behind a module boundary, as `PriorityQueueModule` will. These are an indexed d-ary heap of inline pairs (`IndexedHeap`), the same heap with a stored comparison closure, Boost's indirect layout (`IndirectHeap`) and a plain d-ary heap for lazy deletion (`LazyHeap`). `Proto` runs one Dijkstra relaxation loop over CSR arrays against each of them and against swift-collections' `Heap` with lazy deletion. Every variant must reach the same vertices with the same sum of distances, and all do. Build: `xcrun swift build -c release` (Swift 6.4, `-O`, Apple M1 Ultra). Each figure is the minimum of 7 runs, in ms. Raw output is in `bench-run1.txt` and `bench-run2.txt`, and the tables quote run 2. Run-to-run noise is about ±5 %.

**Path prefixes** (relative to the root of those clones):

| Prefix | Expands to |
|---|---|
| `bgl-dh:` | `graph/include/boost/graph/detail/d_ary_heap.hpp` |
| `bgl-dij:` / `bgl-prim:` / `bgl-perf:` | `graph/include/boost/graph/dijkstra_shortest_paths.hpp` / `.../prim_minimum_spanning_tree.hpp` / `graph/test/dijkstra_heap_performance.cpp` |
| `bgl-mq:` / `bgl-rh:` | `graph/include/boost/pending/mutable_queue.hpp` / `.../relaxed_heap.hpp` |
| `lemon-bin:` / `lemon-d:` / `lemon-c:` / `lemon-dij:` / `lemon-T:` | `lemon/lemon/bin_heap.h` / `lemon/lemon/dheap.h` / `lemon/lemon/concepts/heap.h` / `lemon/lemon/dijkstra.h` / `lemon/test/heap_test.cc` |
| `sc-heap:` / `sc-desc:` / `sc-T:` / `sc-B:` | `swift-collections/Sources/HeapModule/Heap.swift` / `Heap+Descriptions.swift` / `swift-collections/Tests/HeapTests/HeapTests.swift` / `swift-collections/Benchmarks/Sources/Benchmarks/HeapBenchmarks.swift` |
| `pg-dij:` / `pg-astar:` / `pg-sc:` | `petgraph/crates/petgraph/src/algo/dijkstra.rs` / `src/algo/astar.rs` / `src/scored.rs` |
| `nx-h:` / `nx-T:` / `nx-w:` | `networkx/networkx/utils/heaps.py` / `utils/tests/test_heaps.py` / `algorithms/shortest_paths/weighted.py` |
| `jgt-dij:` / `jgt-int:` / `jgt-prim:` | `jgrapht/jgrapht-core/src/main/java/org/jgrapht/alg/shortestpath/DijkstraClosestFirstIterator.java` / `.../IntVertexDijkstraShortestPath.java` / `.../alg/spanning/PrimMinimumSpanningTree.java` |
| `ig-h:` / `ig-dij:` / `ig-T:` | `igraph/src/core/indheap.c` / `igraph/src/paths/dijkstra.c` / `igraph/tests/unit/2wheap.c` |
| `go-dij:` / `go-astar:` / `go-prim:` | `gonum/graph/path/dijkstra.go` / `a_star.go` / `spanning_tree.go` |
| `rx-dij:` | `rustworkx/rustworkx-core/src/shortest_path/dijkstra.rs` |
| `pf-dij:` / `pf-astar:` | `pathfinding/src/directed/dijkstra.rs` / `astar.rs` |
| `gap:` | `gapbs/src/sssp.cc` |
| `sp-sp:` | `scipy/sparse/csgraph/_shortest_path.pyx` at `ec1861f` |
| `sw:` | `swift/stdlib/public/core/` |
| `GF:` | the Grafluent repository |
| `PROTO:` | `proto/Sources/` of the scratch prototype package (not kept) |

---

## 0. Cross-library comparison

| Question | Boost | LEMON | igraph | JGraphT | gonum | petgraph / rustworkx / pathfinding | NetworkX | scipy / gapbs | swift-collections `Heap` | Recommended for Grafluent |
|---|---|---|---|---|---|---|---|---|---|---|
| What Dijkstra uses | **indexed 4-ary heap** `d_ary_heap_indirect<Vertex, 4, …>` (bgl-dij:378-381) with `update` after relaxing (bgl-dij:57-62, 147-152) | **indexed binary heap** by default (lemon-dij:105), switching on `state()` while relaxing (lemon-dij:643-670) | **indexed binary max-heap** `2wheap` of negated distances (ig-dij:148, 210-258) | `PairingHeap` with handles and `decreaseKey` (jgt-dij:69, 218-227); **4-ary `DaryArrayAddressableHeap`** for `Integer` vertices (jgt-int:67, 193-214) | **lazy deletion** with `container/heap` (go-dij:64-105), after TR-07-54 | **lazy deletion** with `BinaryHeap<MinScored>` (pg-dij:180-209, rx-dij:116-124, pf-dij:422-441) | **lazy deletion** with `heapq` (nx-w:849-879) | **lazy deletion** with `std::priority_queue` (sp-sp:731-832; gap:164-183) | — (a min-max heap with no decrease-key, sc-heap:26-63) | **indexed 4-ary heap with decrease-key** (D1, D2) |
| Items | any `Value` with an index-in-heap property map (bgl-dh:86-92) | items with an item→int cross-reference map (lemon-bin:41-43, 67-75) | dense `0..<max_size` (ig-h:800-806, 843) | handles (jgt-dij:56-57) | `int64` IDs via a map (go-astar:111-150) | — | hashable keys (nx-h:86-107) | — | `Element: Comparable` (sc-heap:63) | **dense `Int` indices `0..<indexBound`** (D1) |
| Where priorities live | **outside**, in the distance map, read through `get(distance, v)` (bgl-dh:228-232, 258-261) | **inline**, `std::pair<Item, Prio>` in the heap array (lemon-bin:59, 178-191) | inline, `data` vector parallel to `index` (ig-h:883-925) | in the handle | inline | inline (`MinScored(K, T)`, pg-sc:13) | inline tuple | inline pair | inline (the element) | **inline `(index, priority)` pairs** (D3) |
| Arity | template parameter, Dijkstra uses 4: "optimal value appears to be 4" (bgl-dh:83-85) | `BinHeap` 2, `QuadHeap` 4, `DHeap<D = 16>` (lemon-d:44-51, 60) | 2 | 4 in `IntVertexDijkstra` (jgt-int:67) | 2 | 2 | 2 | 2 | min-max (binary) | **4, fixed** (D2) |
| Decrease-key | `update(v)` after the caller writes the new distance (bgl-dh:163-171) | `decrease(i, p)`, `increase(i, p)`, `set(i, p)` (lemon-bin:258-291) | `modify(idx, elem)`, either direction (ig-h:985-992) | `Handle.decreaseKey` (jgt-dij:225) | `heap.Fix` in A* and Prim only (go-astar:143-150, go-prim:139-144) | — (push a duplicate) | `insert(key, value, allow_increase)` re-pushes (nx-h:322-336) | — (push a duplicate) | — | **`decreasePriority(of:to:)`, `updatePriority(of:to:)`** (D7, D8) |
| Insert-or-decrease | `push_or_update` (bgl-dh:180-191) | `set` (lemon-bin:258-268) | — | — | — | — | `insert` returns "decreased" (nx-h:86-107) | — | — | **deferred**: the caller branches on `contains` (open question 6) |
| Remove an arbitrary item | — (`relaxed_heap::remove`, bgl-rh:183) | `erase(i)` (lemon-bin:228-238) | — | `Handle.delete` | — | — | — | — | `removeAll(where:)` | **`remove(_:) -> Priority?`** |
| Item states | 2: present or `(size_type)(-1)` (bgl-dh:148, 174-178) | **3**: `PRE_HEAP`, `IN_HEAP`, `POST_HEAP` (lemon-bin:71-75, 301-306) | **3**: absent, deactivated, active (ig-h:899-911, 946-962) | handle present or not | map membership | — | — | — | — | **2: present or absent** (D6) |
| Ties | unspecified | unspecified | unspecified | unspecified | unspecified | unspecified; **A\* puts its tie rule in the score**: `(f, h, g)` (pg-astar:106-111) or "highest `cost` favored" (pf-astar:356-388) | **insertion order**, from a `count()` in every tuple (nx-w:849-879) | by index as the second pair field: larger index first in scipy's max-heap of `(-dist, i)` (sp-sp:731-732, 762), smaller first in gapbs's `greater<pair>` (gap:169-170) | unspecified, "unstable" (sc-heap:45-50) | **unspecified, but `min` moves only for a strictly smaller priority or when it leaves** (D5) |
| NaN | — | — | — | — | — | `MinScored` orders NaN last, "so that it is possible to use float types" (pg-sc:8-11, 42-50) | Python ordering | — | — | **trap** (D4) |
| Copy | "**not safe to copy … and then modify one of the copies**": deep heap, shallow index map (bgl-dh:23-26) | reference to an external map | C struct | reference | reference | `Clone` | reference | — | value type, CoW | **value type, copy-on-write** (D11) |
| Iteration | — | — | — | — | — | — | — | — | **not a `Sequence`**; `unordered: [Element]`, O(1) (sc-heap:41-61, 92-102) | **not a `Sequence`; `unordered`** (D12) |
| Description | — | — | — | — | — | `Debug` | — | — | `"<3 items @0x…>"`, an address (sc-desc:15-37) | **contents in pop order** (D13) |

Consumers, and what each needs from the queue:
- **Dijkstra** needs insert, popMin, decrease and contains. LEMON's switch (lemon-dij:652-666) and JGraphT's `updateDistance` (jgt-dij:218-227) are the two shapes: insert if absent, decrease if present and smaller.
- **Prim** needs the same, plus a way to know a vertex is already in the tree. Boost runs Prim as Dijkstra with `combine = project2nd` (bgl-prim:23-59) and its BFS colour map. JGraphT keeps one handle per vertex (jgt-prim:79-92). gonum's `primQueue` decreases with `heap.Fix` (go-prim:139-144).
- **A\*** needs Dijkstra's operations with a priority of f = g + h. gonum decreases (go-astar:143-150). petgraph, rustworkx and pathfinding push duplicates and put their tie rule into the score type (pg-astar:106-111, pf-astar:356-388).
- **Δ-stepping** uses buckets, not a heap (gap:29-46). It is not a consumer (Deferred).

---

## 1. Decision table

Benchmark figures (ms, minimum of 7) used below. **D4** is a 4-ary heap, **tie** compares `(priority, index)` lexicographically, and **lazy** means duplicates plus stale-skip.

| Workload | indexed D2 tie | indexed D4 tie | indexed D8 tie | **indexed D4 no tie** | indexed D2 no tie | indexed D4 tie, `Int32` positions | indexed D4, closure comparator | Boost indirect D4 | lazy D2 (hand-written binary heap) | lazy D4 | lazy swift-collections `Heap` |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Dijkstra, G(10⁵, 10⁶), `Int` weights 1…1000 | 19.5 | 17.4 | 18.8 | **16.2** | 18.3 | 19.8 | 22.6 | 18.5 | 23.7 | 20.9 | 24.4 |
| Dijkstra, G(10⁵, 10⁶), `Double` weights in [0, 1) | 27.1 | 27.4 | 25.0 | **16.7** | 20.9 | 24.2 | 24.6 | 17.0 | 30.0 | 23.9 | 29.2 |
| Dijkstra, G(10⁵, 10⁶), `Int` weights 1…4 (many ties) | 13.8 | 12.4 | 12.9 | **13.2** | 14.6 | 11.9 | 15.5 | 14.1 | 15.1 | 13.6 | 14.7 |
| Dijkstra, G(10⁶, 4·10⁶), `Int` 1…1000 | 438.9 | 414.7 | 458.2 | **315.9** | 367.1 | 404.0 | 381.6 | 346.9 | 392.9 | 314.0 | 359.5 |
| Dijkstra, 1000 × 1000 grid, `Int` 1…100 | 84.3 | 79.9 | 92.4 | **69.6** | 73.9 | 77.2 | 101.3 | 70.8 | 79.0 | 68.7 | 87.0 |
| Heap sort, 10⁶ random `Int` | 191.1 | 137.9 | 151.1 | **108.5** | — | — | — | — | 117.8 | 75.9 | 98.5 |
| 10⁶ inserts, 10⁶ decrease-keys, pop all | 207.2 | 154.8 | — | — | — | — | — | — | 413.8 | 276.1 | — |

Operation counts (`--stats`, `bench-run1.txt`) show how much work a decrease-key saves. G(10⁵, 10⁶) with `Int` weights does 99 995 inserts and 98 707 decreases, a maximum queue size of 67 040. The lazy heap there does 198 714 pushes and 98 719 stale pops, a maximum size of 125 566. On G(10⁶, 4·10⁶) the indexed queue does 980 103 inserts and 317 311 decreases (maximum size 403 498), against 1 297 431 lazy pushes (maximum 545 127).

| # | Question | Recommendation | Evidence | Disagreement / risk |
|---|---|---|---|---|
| D1 | Indexed or lazy deletion | **One type: an indexed queue over dense `Int` indices `0..<indexBound`, with a position array and decrease-key.** No second, non-indexed heap in Grafluent: swift-collections' `Heap` already serves lazy deletion, and Grafluent depends on swift-collections (`GF:Package.swift`). **Dijkstra, Prim and A\* use the indexed queue.** | **Speed.** Indexed D4 is the fastest or within noise of the fastest on every Dijkstra input: 16.2 vs lazy D4's 20.9 and `Heap`'s 24.4; 16.7 vs 23.9 and 29.2; 13.2 vs 13.6 and 14.7; 315.9 vs 314.0 and 359.5; 69.6 vs 68.7 and 87.0. It is 1.8× faster than lazy deletion in the decrease-heavy run (154.8 vs 276.1). Its queue stays smaller (403 498 vs 545 127 entries), and it gives `priority(of:)` and `remove(_:)`, which lazy deletion cannot. **Precedent.** Every library with dense vertex ids uses an indexed queue: Boost (bgl-dij:378), LEMON (lemon-dij:105), igraph (ig-dij:148-258) and JGraphT's `IntVertexDijkstraShortestPath` (jgt-int:67). Prim and A\* decrease in place in gonum too (go-prim:139-144, go-astar:143-150). | Lazy deletion is the more common choice for Dijkstra: petgraph, rustworkx, pathfinding, NetworkX, scipy, gonum's Dijkstra and the gapbs verifier. gonum follows UTCS TR-07-54 (go-dij:64-73), which found little to gain from decrease-key. Our numbers agree at 10⁶ vertices (315.9 vs 314.0), where it is a tie. The indexed queue costs 8 bytes per index for positions even when the frontier is small, which is 8 MB at 10⁶. Plain heap sort with no decrease-key is 43 % slower than lazy D4 (108.5 vs 75.9), because every move also writes a position. That is the price of addressability, and `Heap` remains the tool for that job. |
| D2 | Arity | **4, a fixed constant**: parent `(h − 1) >> 2`, children `4h + 1 … 4h + 4`. It is not a type parameter. | D4 beats D2 on every input, with ties or without: 17.4 vs 19.5, 27.4 vs 27.1 (noise), 12.4 vs 13.8, 414.7 vs 438.9 and 79.9 vs 84.3 with the tie rule; 16.2 vs 18.3, 16.7 vs 20.9, 315.9 vs 367.1 and 69.6 vs 73.9 without. It is 1.4× faster in heap sort and 1.3× in the decrease-heavy run. D8 loses to D4 at 10⁶ (458.2 vs 414.7; grid 92.4 vs 79.9). Boost says "optimal value appears to be 4, both in my and third-party experiments" (bgl-dh:83-85). LEMON ships `QuadHeap` (lemon-d:41-43), and JGraphT picks 4 for dense ints (jgt-int:67). **A value-generic `let Arity: Int` needs the macOS 26 runtime** ("values in generic types are only available in macOS 26.0.0 or newer", the prototype's build error), while Grafluent's floor is macOS 15 (`GF:Package.swift:16`). | LEMON's `DHeap` defaults to 16 (lemon-d:49-51), which is too wide for these inputs, since D8 is already slower. A runtime arity would replace the shifts with divisions. PQ-B04 rechecks 2/4/8 on the final code. Arity is invisible to every test (`plant.py`: arity 2 is caught by nothing), as intended. |
| D3 | Layout | **`_heap: [(index: Int, priority: Priority)]`** in heap order, plus **`_positions: [Int]`** of `indexBound` slots, where −1 means absent. Sifts move a hole, as LEMON's `bubbleUp`/`bubbleDown` (lemon-bin:132-168) and Boost's two-loop `preserve_heap_property_up` (bgl-dh:249-295) do, rather than swapping. All inner loops run on unsafe buffer pointers taken once per call, with the uniqueness check outside the loop (`GF:README.md:298-305`). | Inline pairs keep each comparison in the heap's own cache lines. Boost's indirect layout (priorities in an index-addressed array) is close but never better: 18.5 vs 16.2, 17.0 vs 16.7, 346.9 vs 315.9, 70.8 vs 69.6. Its one advantage is that the priority array doubles as Dijkstra's distance array, which saves n slots. `Int32` positions show no consistent gain (24.2 vs 27.4 but 404.0 vs 414.7 and 77.2 vs 79.9, against run 1's 22.2/23.4, 408.8/402.7 and 80.1/80.7), and every Grafluent index is `Int`. A tuple array makes `unordered` O(1), as `Heap.unordered` is (sc-heap:99-102). | With a 16-byte pair, `Int` plus `Double`, `Int32` indices would not shrink the pair anyway because of alignment. PQ-B06 keeps the comparison. |
| D4 | Priority type, order, NaN | **`IndexedPriorityQueue<Priority: Comparable>`, a min-queue only.** No comparator parameter, no max variant. A **priority that is not equal to itself (NaN) traps** in `insert`, `decreasePriority` and `updatePriority`: one `priority == priority` check. | Every consumer extracts minima. A stored closure comparator costs 21–47 % against `Comparable` (22.6 vs 16.2, 24.6 vs 16.7, 381.6 vs 315.9, 101.3 vs 69.6), because a stored closure cannot be specialized. `Heap` is `Comparable`-based too (sc-heap:63). Swift says exceptional values such as NaN "need not take part in the strict total order" (sw:Comparable.swift:131-137). A NaN in a heap compares false both ways, so the queue would hand out a wrong order silently. | petgraph orders NaN last instead of rejecting it (pg-sc:42-50). A caller who wants a max-queue or a custom order wraps the priority in its own `Comparable` type, as petgraph and pathfinding do for A\* ties (pg-astar:106-111, pf-astar:356-388). igraph negates distances to use a max-heap (ig-dij:210-214). Open question 5. |
| D5 | Ties | **Equal priorities come out in an unspecified order.** The queue does not compare indices. Documented guarantee: **`min` changes only when a strictly smaller priority arrives (by `insert`, `decreasePriority` or `updatePriority`), or when the current minimum leaves (`popMin`, `removeMin`, `remove`) or its priority increases.** It holds because every sift moves only across a strict `<`. The order is a pure function of the operations performed, so runs are reproducible within a library version. | Breaking ties by index costs **7–64 %** in Dijkstra (D4: 17.4 vs 16.2, 27.4 vs 16.7, 414.7 vs 315.9, 79.9 vs 69.6; it is free only with weights 1…4, 12.4 vs 13.2) and 27 % in heap sort (137.9 vs 108.5). A branch-free version is worse still (`bench-run2.txt`: 485.5 at 10⁶). No library with an indexed heap promises a tie order: Boost, LEMON and igraph leave it open, and `Heap` calls its order "unstable" (sc-heap:45-50). The weaker guarantee costs nothing and is what swift-collections tests (`test_tieBreaks_min`, sc-T:606-624 → PQ-28). Dijkstra's distances do not depend on tie order. LEMON's own Dijkstra-with-heap test checks the shortest-path tree's properties rather than exact predecessors (lemon-T:131-157). | Tests can pin indices only where priorities are distinct, and must compare tied indices as sets (`ref.py`'s `Naive` reports tie sets). Predecessor trees under ties can change between versions. A caller who needs a rule puts it in `Priority`: `(distance, index)` gives gapbs's rule (gap:169-170), and `(distance, counter)` gives NetworkX's insertion order (nx-w:849-879). Open question 3. |
| D6 | Item states | **Two states: an index is in the queue or it is not.** `popMin`, `remove` and `removeAll` all return an index to "not in the queue", so **an emptied queue is identical to a fresh one** and needs no O(indexBound) reset before reuse. | Boost has two states (bgl-dh:148, 174-178), and so does Sedgewick's `IndexMinPQ.contains`. Dijkstra never needs a third: with non-negative weights, a settled vertex cannot pass `nd < dist[v]`. Repeated Dijkstra (Johnson, Yen, Brandes betweenness) reuses one queue across sources at no cost. | LEMON's `POST_HEAP` (lemon-bin:71-75, 301-329) and igraph's "deactivated" (ig-h:899-911, 946-962) let Prim and Dijkstra skip a settled array. Grafluent's Prim keeps a `BitSet` of tree vertices instead. That is n bits, and `SpanningTrees` would need `swift-collections/BitCollections`. Open question 4. |
| D7 | Names | `IndexedPriorityQueue`, `init(indexBound:)`, `indexBound`, `count`, `isEmpty`, `unordered`, `reserveCapacity(_:)`, `min`, `insert(_:priority:)`, `popMin()`, `removeMin()`, `contains(_:)`, `priority(of:)`, `decreasePriority(of:to:)`, `updatePriority(of:to:)`, `remove(_:)`, `removeAll(keepingCapacity:)`. The sources are in §3. | From `Heap`: **`insert`, `min`, `popMin`, `removeMin`, `count`, `isEmpty`, `unordered`, `reserveCapacity`** (sc-heap:81-261). The **"index"** noun comes from igraph (`push_with_index`, `max_index`, ig-h:843, 891) and Sedgewick's `IndexMinPQ`, and matches Grafluent's `vertexIndexBound`. `contains` is Boost's (bgl-dh:174) and Sedgewick's. **`priority(of:)`** echoes LEMON's `prio()`/`operator[]` (lemon-bin:205, 245) and Sedgewick's `keyOf`, with `Heap`'s word "priority" (sc-heap:180-186). | **"Key" is avoided**: NetworkX's key is the *item* (nx-h:86-107), while CLRS's and Boost's is the *priority* (bgl-dh:103). `decreasePriority` spells CLRS `DECREASE-KEY`, LEMON `decrease` and Sedgewick `decreaseKey` with Grafluent's noun. Alternatives: `decreaseKey(of:to:)`, LEMON's bare `decrease(_:to:)`, Boost's `update(_:)`. The bound's name is open question 1. |
| D8 | Changing a priority | **`decreasePriority(of:to:)`**. Precondition: the index is in the queue and the new priority is not greater, so an equal one is a no-op. **`updatePriority(of:to:) -> Priority`** (`@discardableResult`) moves either way and returns the old priority, as `Dictionary.updateValue(_:forKey:)` does. Precondition: the index is in the queue. | LEMON's `decrease` requires "priority at least p" and its `increase` "at most p" (lemon-bin:270-291). Sedgewick's `decreaseKey` rejects an equal key, but Grafluent allows it because Dijkstra's relaxation is strict and NetworkX treats an equal insert as a no-op (nx-T:65-73). Increases are needed by LEMON's `heapIncreaseTest` (lemon-T:109-128 → PQ-21), by `Heap.replaceMin` (sc-T:357-386 → PQ-27), and by NetworkX `allow_increase` (nx-h:322-336). | The decrease is separate from the update so that Dijkstra's hot path makes one comparison less and trap-checks the direction. The decrease-key *is* the module's reason to exist (`GF:scripts/modules.py:25`). |
| D9 | `remove(_:)` | **`remove(_ index:) -> Priority?`** (`@discardableResult`): the old priority, or `nil` when absent, with no trap. The last slot moves into the hole and **sifts up or down** as needed. | LEMON's `erase` re-sifts both ways (lemon-bin:228-238). `Set.remove` and `Dictionary.removeValue(forKey:)` return optionals. The planted "only sifts down" bug is caught only by PQ-07 and PQ-30. | Sedgewick's `delete` throws when the index is absent. Grafluent follows Swift's collections. |
| D10 | Preconditions | **Traps:** `init(indexBound:)` with a negative bound; any index outside `0..<indexBound`, in every method that takes one, including `contains` and `priority(of:)`; `insert` of an index already in the queue; `decreasePriority`/`updatePriority` of an absent index; `decreasePriority` to a greater priority; a NaN priority; `removeMin()` on an empty queue; `reserveCapacity(-1)`. **No trap:** `popMin()`, `min` on an empty queue (`nil`), `remove` of an absent index (`nil`). Messages follow DisjointSet's style: "Index \(i) is out of range 0..<\(indexBound)" (`GF:Sources/DisjointSetModule/DisjointSet.swift:70-80`). | LEMON states the same preconditions without checking them: `push` "must not be stored" (lemon-bin:177), `decrease` "must be stored with priority at least p" (lemon-bin:276). Boost asserts on empty `top`/`pop` (bgl-dh:135, 147). `Heap.removeMin` says it "must not be empty" (sc-heap:227-236). | Inserting a present index would duplicate it in the heap, and nothing downstream would notice. That is the planted bug `insert-no-dup-check`, caught only by the exit test PQ-50. NetworkX's "insert means upsert" (nx-h:322-336) is not adopted (open question 6). |
| D11 | Value semantics | `@frozen public struct`, with two `@usableFromInline` stored arrays. Copy-on-write comes from `Array`, and one uniqueness check per mutating call precedes the unsafe-pointer work. `Sendable where Priority: Sendable`, as `Heap` (sc-heap:74). Everything `@inlinable`. | The README's storage rule (`GF:README.md:298-301`). Boost's copy is unsafe because "it deep-copies the heap contents yet shallow-copies the index_in_heap_map" (bgl-dh:23-26). A Swift value must not do that: planted bug `shared-storage` → PQ-40. | A copy that is then mutated duplicates both arrays, O(indexBound + count). Dijkstra never copies (PQ-B08). |
| D12 | Conformances | **Not a `Sequence`, not `Equatable`**, as `Heap` (sc-heap:41-61; sc-heap has no `Equatable`). `unordered: [(index: Int, priority: Priority)]`, O(1), in an unspecified order (`GF:README.md:293`). | Iterating would expose heap order. Equality would have to be "same pairs", O(count), and nothing in Grafluent compares queues. Tests compare by draining. | `ExpressibleByArrayLiteral` (`Heap` has one) is not adopted, because a literal would need `indexBound` from somewhere. |
| D13 | Descriptions | `description`: the pairs **sorted by priority, then index**, at most 16, then `…`: `[4: 0.5, 1: 2.0, 7: 2.0]`; empty `[]`. `debugDescription`: `IndexedPriorityQueue<Double>(indexBound: 10, [4: 0.5, 1: 2.0, 7: 2.0])`. Sorting by index as well makes two queues with the same contents print alike whatever their heap layout. | Grafluent's 16-item limit and "equal values print alike" (`GF:Sources/GraphProtocols/GraphDescription.swift:1-11`). `Heap` prints an address (sc-desc:15-29), which no Grafluent type does. The module has no dependency on `GraphProtocols` (`GF:scripts/modules.py:25`), so it carries its own 10-line formatter, as `DisjointSet` does (`GF:Sources/DisjointSetModule/DisjointSet.swift:251-275`). | O(count log count) to sort, which is fine for debugging output. |
| D14 | Capacity and reuse | `reserveCapacity(_:)` reserves heap slots; there can be at most `indexBound` of them. `removeAll(keepingCapacity:)` costs O(count): it resets the positions of the indices still queued. Heap storage starts empty and grows by doubling, so a queue with a small frontier never touches 16 × `indexBound` bytes. | `Heap.reserveCapacity`/`init(minimumCapacity:)` (sc-heap:104-139). LEMON's `clear` needs the caller to reset the cross-reference map (lemon-bin:114-122); D6 makes `removeAll` do it in O(count). Dijkstra with an early exit (a target reached) leaves entries behind, and `removeAll` readies the queue for the next source. | No `init(minimumCapacity:)`: `init(indexBound:)` plus `reserveCapacity` covers it. |

---

## 2. Recommended API sketch

```swift
// PriorityQueueModule. Everything is @inlinable.

/// A min-priority queue of the indices `0..<indexBound`, each queued at most once with a
/// priority: a 4-ary heap with a position array. `insert`, `popMin`, `decreasePriority(of:to:)`,
/// `updatePriority(of:to:)` and `remove(_:)` are O(log count); `min`, `contains(_:)` and
/// `priority(of:)` are O(1). (Boost `d_ary_heap_indirect`, LEMON `QuadHeap`, Sedgewick
/// `IndexMinPQ`.)
///
/// Indices with equal priorities leave in an unspecified order. `min` changes only when a
/// strictly smaller priority arrives or when the minimum leaves or its priority increases.
/// To break ties a particular way, put the rule in `Priority`, for example `(distance, index)`.
///
/// Priorities must not be NaN. Not a `Sequence`: `unordered` lists the contents.
@frozen public struct IndexedPriorityQueue<Priority: Comparable> {
    /// An empty queue for the indices `0..<indexBound`. O(indexBound).
    /// - Precondition: `indexBound >= 0`.                       igraph `2wheap_init(max_size)`, Sedgewick `IndexMinPQ(maxN)`
    public init(indexBound: Int)

    public var indexBound: Int { get }
    public var count: Int { get }                                 // Heap
    public var isEmpty: Bool { get }                              // Heap
    /// The queued pairs in heap order (unspecified). O(1).       Heap `unordered`
    public var unordered: [(index: Int, priority: Priority)] { get }
    public mutating func reserveCapacity(_ minimumCapacity: Int)  // Heap

    /// Whether `index` is queued. - Precondition: `index` in `0..<indexBound`.   Boost `contains`
    public func contains(_ index: Int) -> Bool
    /// `index`'s priority, or `nil` if it is not queued.          LEMON `operator[]`, Sedgewick `keyOf`
    public func priority(of index: Int) -> Priority?
    /// The pair with the lowest priority, or `nil`. O(1).          Heap `min`, LEMON `top`/`prio`
    public var min: (index: Int, priority: Priority)? { get }

    /// Queues `index`. - Precondition: not already queued; in range; not NaN.   Heap `insert`, LEMON `push`
    public mutating func insert(_ index: Int, priority: Priority)
    /// Removes and returns the minimum, or `nil` when empty.      Heap `popMin`, LEMON `pop`
    public mutating func popMin() -> (index: Int, priority: Priority)?
    /// - Precondition: not empty.                                 Heap `removeMin`
    @discardableResult public mutating func removeMin() -> (index: Int, priority: Priority)

    /// Lowers a queued index's priority (equal is a no-op).
    /// - Precondition: queued; `priority <= priority(of: index)!`; not NaN.     CLRS DECREASE-KEY, LEMON `decrease`
    public mutating func decreasePriority(of index: Int, to priority: Priority)
    /// Sets a queued index's priority, either way; returns the old one.          LEMON `set`/`increase`, igraph `modify`
    @discardableResult public mutating func updatePriority(of index: Int, to priority: Priority) -> Priority
    /// Dequeues `index`; returns its priority, or `nil` if it was not queued.    LEMON `erase`, Sedgewick `delete`
    @discardableResult public mutating func remove(_ index: Int) -> Priority?
    /// Dequeues everything in O(count); the result equals a fresh queue.
    public mutating func removeAll(keepingCapacity: Bool = false)
}
extension IndexedPriorityQueue: Sendable where Priority: Sendable {}
extension IndexedPriorityQueue: CustomStringConvertible, CustomDebugStringConvertible {}
```

Usage by the consumers:

```swift
// Dijkstra (ShortestPaths), in index space. `dist` doubles as "seen".
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

// Prim (SpanningTrees): a BitSet marks the tree, since a popped index is simply "not queued" (D6).
while let (u, _) = queue.popMin() {
    inTree.insert(u)
    for (v, w) in neighbors(u) where !inTree.contains(v) {
        if let key = queue.priority(of: v) { if w < key { queue.decreasePriority(of: v, to: w) } }
        else { queue.insert(v, priority: w) }
    }
}
```

---

## 3. Names and their sources

| Grafluent | From |
|---|---|
| `IndexedPriorityQueue` | README (`GF:README.md:293`), `scripts/modules.py:25`; Sedgewick `IndexMinPQ`; Boost's concept name `UpdatableQueue` (bgl-dh:79) |
| `init(indexBound:)`, `indexBound` | igraph `2wheap_init(max_size)` / `max_size()` (ig-h:800, 876); Sedgewick `IndexMinPQ(int maxN)`; spelled like `vertexIndexBound` (`GF:Sources/GraphProtocols/DirectedGraph.swift:97`) |
| index (the noun) | igraph `push_with_index`, `max_index`, `delete_max_index` (ig-h:843, 891, 966); Sedgewick "index"; LEMON says "item" |
| `count`, `isEmpty`, `reserveCapacity(_:)` | `Heap` (sc-heap:81-92, 137); Boost/LEMON `size`/`empty` |
| `unordered` | `Heap.unordered` (sc-heap:92-102); README (`GF:README.md:293`) |
| `min` | `Heap.min` (sc-heap:156-160); Boost/LEMON `top` |
| `insert(_:priority:)` | `Heap.insert` (sc-heap:145); LEMON `push(i, p)` (lemon-bin:191); Sedgewick `insert(i, key)` |
| `popMin()`, `removeMin()` | `Heap.popMin`/`removeMin` (sc-heap:185, 234); LEMON/Boost `pop`; Sedgewick `delMin` |
| `contains(_:)` | Boost `contains` (bgl-dh:174); Sedgewick `contains`; igraph `has_elem` (ig-h:899) |
| `priority(of:)` | LEMON `operator[]`/`prio` (lemon-bin:205, 245); Sedgewick `keyOf`; igraph `get` (ig-h:914); NetworkX `get` (nx-h:319) |
| `decreasePriority(of:to:)` | CLRS `DECREASE-KEY`; LEMON `decrease` (lemon-bin:277); Sedgewick/jheaps `decreaseKey` (jgt-dij:225) |
| `updatePriority(of:to:)` | LEMON `set` on a queued item (lemon-bin:258-268); igraph `modify` (ig-h:985); Sedgewick `changeKey`; Boost `update` (bgl-dh:167); return value as Swift `Dictionary.updateValue(_:forKey:)` |
| `remove(_:)` | LEMON `erase` (lemon-bin:228); Boost `relaxed_heap::remove` (bgl-rh:183); Sedgewick `delete`; return value as Swift `Set.remove` |
| `removeAll(keepingCapacity:)` | Swift `RangeReplaceableCollection.removeAll(keepingCapacity:)`; LEMON `clear` (lemon-bin:120) |

---

## 4. Test catalog

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

### B. Translated OSS tests (exact values)

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

---

### Q. Planted bugs the suite must catch

Planted in the reference (`plant.py`, output `plant.out`), which reruns PQ-01–10, 20–31, 34, 35, 40 and 50/51/52 (as one trap case) against each variant. The clean model passes everything at d ∈ {2, 3, 4, 8}.

| Bug | Caught by |
|---|---|
| Sift-up does not update the moved parent's position | PQ-08, PQ-21, PQ-23, PQ-25, PQ-29, PQ-30, PQ-35 |
| Sift-down scans only d − 1 children | PQ-03, PQ-05, PQ-06, PQ-07, PQ-20, PQ-21, PQ-25, PQ-26, PQ-29, PQ-30, PQ-31, PQ-34, PQ-35 |
| Parent computed as `h / d` instead of `(h − 1) / d` | PQ-25, PQ-30, PQ-31, PQ-34, PQ-35 |
| `popMin` leaves the popped index's position set | PQ-10, PQ-23, PQ-25, PQ-30 |
| `popMin` of the last pair leaves its position set | PQ-02, PQ-09, PQ-23, PQ-24, PQ-30 |
| `decreasePriority` sifts down | PQ-05, PQ-23, PQ-24, PQ-30, PQ-35, PQ-40 |
| `decreasePriority` moves the pair but keeps the old priority | PQ-05, PQ-10, PQ-23, PQ-24, PQ-25, PQ-30, PQ-35, PQ-40 |
| `updatePriority` only sifts up (increases ignored) | PQ-06, PQ-21, PQ-24, PQ-27, PQ-30 |
| `remove` only sifts down | **PQ-07**, PQ-30 |
| `removeAll` does not reset positions | **PQ-10** only |
| Copies share storage (Boost's shallow index map) | **PQ-40** only |
| `insert` of a queued index not trapped (duplicates it) | **PQ-51** only |
| `decreasePriority` to a greater priority not trapped | **PQ-51** only |
| Sift-up crosses equal priorities (`<=`) | **PQ-04** only |
| Sift-down crosses equal priorities | **PQ-28** only |
| Arity 2 instead of 4 | **not observable** (by design, D2); PQ-B04 |
| Ties broken by index (or not) | **not observable** by design: no case pins a tie order (D5); PQ-B05 |

### R. Benchmarks (not tests)

Inputs come from `BenchmarkSupport`'s seeded generator, on CSR graphs. The **hand-written baselines** are copied into the benchmark target. One is the indexed 4-ary heap of `PROTO:PQProto/Queues.swift` (`IndexedHeap<_, Int, 4, 0>`). The other is a **hand-written lazy binary heap** (`LazyHeap<_, 2>`), the textbook petgraph/scipy loop. The third comparison is **swift-collections `Heap` with lazy deletion**, inside the same Dijkstra loop.

| ID | Measures | Target |
|---|---|---|
| PQ-B01 | Dijkstra with `IndexedPriorityQueue` on the five inputs of §1: G(10⁵, 10⁶) with `Int` 1…1000, with `Double` and with `Int` 1…4; G(10⁶, 4·10⁶); the 1000 × 1000 grid | ≤ 1.05× the hand-written indexed 4-ary heap; report vs the lazy binary heap and vs `Heap` (prototype: 0.57–0.90× of `Heap`, 0.56–0.88× of the lazy binary heap) |
| PQ-B02 | Heap sort of 10⁶ random `Int`s (insert all, pop all), as in `HeapBenchmarks` "insert"/"popMin" (sc-B:35-90) | report against `Heap` (prototype 108.5 vs 98.5 ms) and lazy 4-ary (75.9) |
| PQ-B03 | 10⁶ inserts, 10⁶ decrease-keys, pop all, against a lazy heap re-pushing | ≤ 0.7× the lazy 4-ary heap (prototype 0.56×) |
| PQ-B04 | Arity matrix, internal variants: d = 2 / 4 / 8 on B01–B03 | decides D2 (prototype: 4) |
| PQ-B05 | Tie-break cost: `(priority, index)` comparisons vs priority only, on B01 | records D5 (prototype +7 to +64 %) |
| PQ-B06 | Layout matrix: inline pairs vs Boost indirect; `Int` vs `Int32` positions | records D3 |
| PQ-B07 | Prim on G(10⁵, 10⁶) undirected vs a hand-written Prim on the same heap | ≤ 1.05× |
| PQ-B08 | Copy-on-write: allocations in a Dijkstra run are the two arrays plus growth (no copy) | 0 extra copies |
| PQ-B09 | The NaN check (D4) and the range checks (D10): checked vs unchecked internal variant on B01 | ≤ 1.02× |
| PQ-B10 | Reuse: n Dijkstras from every source on G(10⁴, 10⁵) with one queue (`removeAll` not needed, D6) vs a fresh queue per source | report |
| PQ-B11 | Comparator alternatives, for the record: a stored closure (prototype +21–47 %) | report |

---

## Deferred

- **A non-indexed heap of pairs.** swift-collections' `Heap` covers lazy deletion for searches without dense ids, such as A\* on `ImplicitGraphs`. A hand-written lazy 4-ary heap was 8–27 % faster than `Heap` in Dijkstra (20.9 vs 24.4, 23.9 vs 29.2, 314.0 vs 359.5, 68.7 vs 87.0), because `Heap` is a min-max heap, but a second heap type would duplicate swift-collections.
- **Hashable items** (an `OrderedSet`-indexed wrapper, the way NetworkX keys `BinaryHeap` by hashable keys, nx-h:281-336).
- **Insert-or-decrease in one call** (Boost `push_or_update`, bgl-dh:180-191; LEMON `set`; NetworkX `insert`). It saves one load of the position array. Open question 6.
- **Three-state `state(of:)`** (LEMON, igraph). Open question 4.
- **Bulk initialization by heapify** (`Heap.init(_:)`, sc-heap:338; igraph `indheap_init_array`, ig-h:87). Prim seeding every vertex at ∞ would use it.
- **Max-queues and comparators** (D4).
- **Monotone integer queues for Δ-stepping and Dial**: LEMON `RadixHeap`, `BucketHeap` (heap_test runs them on the same data, lemon-T:236-258), gapbs's buckets (gap:29-46).
- **Fibonacci, pairing and relaxed heaps** (JGraphT's default `PairingHeap`, jgt-dij:69; `FibonacciHeap` in Prim, jgt-prim:82; Boost `relaxed_heap`). Boost itself defaults Dijkstra to the 4-ary heap "for its good practical performance" (bgl-dh:69-75).
- `removeAll(where:)` (`Heap`, sc-heap:282) and `Codable`.

---

## Open questions for the maintainer

1. **The bound's name (D7).** `init(indexBound:)`/`indexBound` (igraph and Sedgewick "index", Grafluent's `vertexIndexBound`), or LEMON's "item" (`itemBound`)? Or igraph's `maxSize`?
2. **Changing priorities (D7, D8).** `decreasePriority(of:to:)`/`updatePriority(of:to:)`, or CLRS's `decreaseKey`? (The word "key" means the item in NetworkX and the priority in CLRS and Boost.) Or LEMON's terse `decrease(_:to:)`/`set(_:to:)`?
3. **Ties (D5).** Accept "unspecified, but `min` moves only for a strictly smaller priority" and keep the 7–64 % saving? Or document "smaller index first", as gapbs's pairs give, and pay for it?
4. **States (D6).** Two states with a `BitSet` in Prim, or LEMON's `PRE/IN/POST` `state(of:)` (one array serves as "settled")? Three states mean an O(indexBound) reset before reuse.
5. **Min-only (D4).** Is a max-queue or comparator wanted for any planned algorithm (for example, widest path)? Or is wrapping the priority enough?
6. **One-call insert-or-decrease** (Boost `push_or_update`, NetworkX `insert`)? Dijkstra's call site is two lines without it.
7. **Heapify initializer** for Prim, or keep inserts?

---

## Summary of key decisions

1. One type: an **indexed 4-ary min-heap** over dense `Int` indices `0..<indexBound`, with a position array and decrease-key (Boost, LEMON, igraph, JGraphT's int Dijkstra). No second lazy heap, since swift-collections `Heap` covers that.
2. Dijkstra, Prim and A\* use it. In Swift it beat lazy deletion on every input (up to 1.4×) or tied it (10⁶ vertices). It beat `Heap` with lazy deletion by 1.1–1.75×, and was 1.8× faster in decrease-heavy work.
3. **Arity is 4, hard-coded.** It beat 2 and 8 everywhere, and value generics would need macOS 26 against Grafluent's macOS 15 floor.
4. Layout: inline `(index, priority)` pairs plus `[Int]` positions, with hole-based sifts on unsafe buffers. Boost's indirect layout and `Int32` positions bought nothing.
5. `IndexedPriorityQueue<Priority: Comparable>` is **min-only, with no comparator** (a stored closure costs 21–47 %). NaN priorities trap.
6. **Ties are unspecified.** Index tie-breaking costs 7–64 %. The free guarantee is that `min` moves only for a strictly smaller priority or when it leaves. Tests compare tied indices as sets.
7. **Two states (queued or not).** An emptied queue equals a fresh one, and Prim keeps a `BitSet`.
8. Names follow `Heap` (`insert`, `min`, `popMin`, `removeMin`, `count`, `isEmpty`, `unordered`, `reserveCapacity`), plus `contains`, `priority(of:)`, `decreasePriority(of:to:)`, `updatePriority(of:to:)` (returns the old priority), `remove(_:) -> Priority?` and `removeAll(keepingCapacity:)`.
9. The type traps on out-of-range indices, a duplicate `insert`, a decrease to a larger priority, changing an absent index, `removeMin` on empty and a negative bound. `popMin`/`min`/`remove` return `nil` instead of trapping.
10. It is a value type with copy-on-write over two arrays, `Sendable` when the priority is, and neither `Sequence` nor `Equatable` (as `Heap`). `description` lists pairs by (priority, index), at most 16.
