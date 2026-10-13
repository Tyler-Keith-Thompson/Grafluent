# IndexedPriorityQueue test suite

`IndexedPriorityQueue` is a min-priority queue of the dense indices `0..<indexBound`, each queued
at most once with a priority, with decrease-key. The suite uses only the public API, and each
test is self-contained. The only shared material is the seeded generator and the tags in
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

| Question | Choice |
|---|---|
| Indices | Dense `Int`, `0..<indexBound` |
| Order | Min-only, `Priority: Comparable`, no comparator. A caller wanting another order wraps the priority |
| Ties | Unspecified. The only guarantee: `min` changes only when a strictly smaller priority arrives, or when the minimum leaves or its priority increases. Tests compare tied indices as sets and pin only that guarantee (PQ-04, PQ-28) |
| States | Two: queued or not. An emptied queue equals a fresh one (PQ-10, PQ-13) |
| Descriptions | The pairs sorted by priority, then index, at most 16, then `…`; equal contents print alike |
| Preconditions | Every index argument must be in `0..<indexBound`, `contains` and `priority(of:)` included. Duplicate inserts, changes of absent indices, decreases upwards, NaN priorities, `removeMin` on an empty queue and negative bounds or capacities trap; exit tests check each. `popMin`, `min` and `remove` of an absent index return `nil` |

Expected values come from the catalog's reference (`ref.py`, output `cases.out`): a model of the
queue and an independent naive oracle that reports every index tied at the minimum, run on the
fixed sequences of PQ-20 – PQ-23 and on 2000 seeded random sequences. Randomized tests write
their oracles inside the test (a naive scan, a sort, Bellman–Ford, Kruskal, Dial's buckets).

## Files

| File | Covers |
|---|---|
| `PriorityQueueBasicsTests.swift` | §A: the empty queue, ordering, the tie guarantee, decrease-key, increases, removal (including a pair that must sift up), re-insertion, states, counts, `unordered`, capacity, `indexBound` |
| `PriorityQueueTranslatedTests.swift` | §B: fixed operation sequences with exact values: heap sort, priority increases, a Dijkstra graph, a recorded Dijkstra trace, mixed operation lists with an upsert, and pop, replacement, tie and removal sequences |
| `PriorityQueueStressTests.swift` | §C: the differential test against a naive scan; heap sort; Dijkstra against Bellman–Ford; Prim against Kruskal; 10⁶-scale permutation, worst-case sifts, grid Dijkstra against Dial's algorithm and heap sort with ties, inside a `Task` |
| `PriorityQueueConformanceTests.swift` | §D: value semantics, a copy taken mid-drain, `Sendable`, descriptions |
| `PriorityQueuePreconditionTests.swift` | §E: exit tests |
| `PriorityQueueReviewTests.swift` | Further invariants: copy-on-write when a copy's first mutation reorders in place or clears (PQ-44); `insertOrDecreasePriority` (PQ-45, and in a Dijkstra checked against Bellman–Ford, PQ-46); a composite tie-breaking priority (PQ-47); out-of-range indices as far as `Int.min` and `Int.max`, expecting the queue's own `SIGTRAP` rather than any crash, since a weakened check would read past the slot array (PQ-53) |

## Case IDs

Case IDs PQ-01 … PQ-43 and PQ-50 … PQ-52 refer to the catalog of cases
(`Tests/Catalogs/PriorityQueue/cases.md`, with `ref.py` and `cases.out`). PQ-44 – PQ-47 and PQ-53
are defined by their tests in `PriorityQueueReviewTests.swift`. Each test's name starts with its
ID.

| Cases | Section | File |
|---|---|---|
| PQ-01 – PQ-14 | A. Basics | `PriorityQueueBasicsTests.swift` |
| PQ-20 – PQ-29 | B. Fixed sequences (exact values) | `PriorityQueueTranslatedTests.swift` |
| PQ-30 – PQ-37 | C. Randomized and large | `PriorityQueueStressTests.swift` |
| PQ-40 – PQ-43 | D. Value semantics and conformances | `PriorityQueueConformanceTests.swift` |
| PQ-44 – PQ-47, PQ-53 | Further invariants | `PriorityQueueReviewTests.swift` |
| PQ-50 – PQ-52 | E. Preconditions | `PriorityQueuePreconditionTests.swift` |
| PQ-B01 – PQ-B03 | Benchmarks | not tests: run time against hand-written baselines is not observable through the public API |
