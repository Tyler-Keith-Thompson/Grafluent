# IndexedPriorityQueue test suite

`IndexedPriorityQueue` is a min-priority queue of the dense indices `0..<indexBound`, each queued
at most once with a priority, with decrease-key. The suite uses only the public API and is
self-contained per test; the only shared material is the seeded generator and the tags in
`GrafluentTestSupport`.

## API under test

```swift
struct IndexedPriorityQueue<Priority: Comparable>: CustomStringConvertible, CustomDebugStringConvertible
        // Sendable where Priority: Sendable; not a Sequence, not Equatable
    init(indexBound: Int)                                      // traps if negative
    var indexBound: Int
    var count: Int
    var isEmpty: Bool
    var unordered: [(index: Int, priority: Priority)]          // unspecified order
    mutating func reserveCapacity(_: Int)
    func contains(_ index: Int) -> Bool
    func priority(of index: Int) -> Priority?
    var min: (index: Int, priority: Priority)?
    mutating func insert(_ index: Int, priority: Priority)     // traps if already queued
    mutating func popMin() -> (index: Int, priority: Priority)?
    mutating func removeMin() -> (index: Int, priority: Priority)   // @discardableResult; traps if empty
    mutating func decreasePriority(of: Int, to: Priority)      // equal is a no-op; greater traps
    mutating func insertOrDecreasePriority(of: Int, to: Priority) -> Bool  // inserts, lowers, or nothing; whether it changed
    mutating func updatePriority(of: Int, to: Priority) -> Priority // @discardableResult; the old one
    mutating func remove(_ index: Int) -> Priority?            // @discardableResult; nil if absent
    mutating func removeAll(keepingCapacity: Bool = false)
```

## Conventions

| Question | Choice | Why |
|---|---|---|
| Indices | Dense `Int`, `0..<indexBound` | Every consumer (Dijkstra, Prim, A\*) works in vertex-index space |
| Order | Min-only, `Priority: Comparable`, no comparator | Every consumer extracts minima; a caller wanting another order wraps the priority |
| Ties | Unspecified. The only guarantee: `min` changes only when a strictly smaller priority arrives, or when the minimum leaves or its priority increases. Tests compare tied indices as sets and pin only that guarantee (PQ-04, PQ-28) | Breaking ties by index cost 7–64 % in the prototype's Dijkstra |
| States | Two: queued or not. An emptied queue equals a fresh one (PQ-10, PQ-13) | Reuse across Dijkstra sources needs no reset |
| Descriptions | The pairs sorted by priority, then index, at most 16, then `…`; equal contents print alike | Grafluent's description rule |
| Preconditions | Every index argument must be in `0..<indexBound`, `contains` and `priority(of:)` included; duplicate inserts, changes of absent indices, decreases upwards, NaN priorities, `removeMin` on an empty queue and negative bounds or capacities trap; tested with exit tests. `popMin`, `min` and `remove` of an absent index return `nil` | Grafluent traps on invalid vertices |

Expected values come from the catalog's reference (`ref.py`, output `cases.out`): the
recommended design and an independent naive oracle that reports every index tied at the minimum,
run on LEMON's, igraph's, NetworkX's and swift-collections' data and on 2000 seeded random
sequences. Randomized tests write their oracles inside the test (a naive scan, a sort,
Bellman–Ford, Kruskal, Dial's buckets).

## Files

| File | Covers |
|---|---|
| `PriorityQueueBasicsTests.swift` | §A: the empty queue, ordering, the tie guarantee, decrease-key, increases, removal (including a pair that must sift up), re-insertion, states, counts, `unordered`, capacity, `indexBound` |
| `PriorityQueueTranslatedTests.swift` | §B: LEMON's `heapSortTest`, `heapIncreaseTest` and Dijkstra graph; igraph's `2wheap` trace (GPL, data only); NetworkX's `test_heaps`; swift-collections' `popMin`, `minimumReplacement`, `tieBreaks_min` and `removeEvenNumbers` tests |
| `PriorityQueueStressTests.swift` | §C: the differential test against a naive scan; heap sort; Dijkstra against Bellman–Ford; Prim against Kruskal; 10⁶-scale permutation, worst-case sifts, grid Dijkstra against Dial's algorithm and heap sort with ties, inside a `Task` |
| `PriorityQueueConformanceTests.swift` | §D: value semantics, a copy taken mid-drain, `Sendable`, descriptions |
| `PriorityQueuePreconditionTests.swift` | §E: exit tests |
| `PriorityQueueReviewTests.swift` | Added after the critical review: copy-on-write when a copy's first mutation reorders in place or clears (PQ-44); `insertOrDecreasePriority` (PQ-45, and in a Dijkstra checked against Bellman–Ford, PQ-46); a composite tie-breaking priority (PQ-47); out-of-range indices as far as `Int.min` and `Int.max`, expecting the queue's own `SIGTRAP` rather than any crash, since a weakened check would read past the slot array (PQ-53) |

## Case IDs

Case IDs (PQ-01 … PQ-52) refer to the catalog of cases (`Tests/Catalogs/PriorityQueue/cases.md`, with `ref.py` and `cases.out`) harvested from Boost, LEMON, igraph,
NetworkX and swift-collections. Each test's name starts with its ID.

| Cases | Section | File |
|---|---|---|
| PQ-01 – PQ-14 | A. Basics | `PriorityQueueBasicsTests.swift` |
| PQ-20 – PQ-29 | B. Translated library tests (exact values) | `PriorityQueueTranslatedTests.swift` |
| PQ-30 – PQ-37 | C. Randomized and large | `PriorityQueueStressTests.swift` |
| PQ-40 – PQ-43 | D. Value semantics and conformances | `PriorityQueueConformanceTests.swift` |
| PQ-50 – PQ-52 | E. Preconditions | `PriorityQueuePreconditionTests.swift` |
| PQ-B01 – PQ-B11 | Benchmarks | not tests: the arity, the tie rule, the layout and copy-on-write allocations are not observable through the public API |
