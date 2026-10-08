# DisjointSet test suite

`DisjointSet` is a union–find over the dense elements `0..<count`, with union by size and path
halving. The suite uses only the public API and is self-contained per test; the only shared
material is the seeded generator and the tags in `GrafluentTestSupport`.

## API under test

```swift
struct DisjointSet: Hashable, Sendable, CustomStringConvertible, CustomDebugStringConvertible
    init()
    init(count: Int)                                  // count singletons; traps if negative
    var count: Int                                    // elements
    var isEmpty: Bool
    var setCount: Int                                 // sets, O(1)
    mutating func makeSet() -> Int                    // @discardableResult; returns the old count
    mutating func reserveCapacity(_: Int)
    mutating func find(_: Int) -> Int                 // the representative; compresses
    mutating func union(_: Int, _: Int) -> Bool       // @discardableResult; whether it merged
    func inSameSet(_: Int, _: Int) -> Bool            // never writes
    func setSize(of: Int) -> Int                      // never writes
    func sets() -> [[Int]]                            // by smallest element, each ascending
    func labels() -> [Int]                            // each element's position in sets()
```

## Conventions

| Question | Choice | Why |
|---|---|---|
| Elements | Dense `Int`, `0..<count` | Every consumer works in vertex-index space |
| Representative | The larger set's representative wins; for sets of the same size, the smaller of the two, whatever the argument order. `find` never changes one. Documented, so tests pin every `find` exactly | scipy's rule; makes `union(a, b)` and `union(b, a)` identical (DS-19, DS-25) |
| Mutating queries | `find` and `union` are `mutating` (they compress); `inSameSet`, `setSize(of:)`, `sets()`, `labels()`, `setCount`, `==` and `description` work on a `let` (DS-30) and never copy shared storage | Every compressing library compresses in `find`; petgraph's `equiv` does not. Changed after the critical review: a borrowed value could otherwise only be asked through a copy |
| Equality and hashing | Same `count` and the same partition; representatives are not part of the value (DS-31) | The README's "`Equatable` (same partition)" |
| Descriptions | The sets as `sets()` prints them, at most 16 sets and 16 elements per set, then `…`; no representatives, so equal values print alike | Grafluent's description rule |
| Preconditions | Every element argument must be in `0..<count`, `union(x, x)` included; negative counts and capacities trap; tested with exit tests | Grafluent traps on invalid vertices |
| `Codable` | Not provided | No format needs one |

Expected values come from the catalog's reference (`ref.py`, printed by `cases.py`): the
recommended design and an independent naive oracle, cross-checked against scipy's own
`DisjointSet` and NetworkX's `UnionFind` on 2420 seeded random operation sequences. Randomized
tests write their oracles inside the test.

## Files

| File | Covers |
|---|---|
| `DisjointSetConstructionTests.swift` | §A: the empty value, singletons, self-unions, `reserveCapacity`, `makeSet` |
| `DisjointSetUnionTests.swift` | §B: `union`, `find` and `inSameSet` with the cases of petgraph, JGraphT, Boost, NetworkX and LEMON, exact |
| `RepresentativeRuleTests.swift` | §C: the representative rule, scipy's ported tests, `find` never changing a representative, argument order |
| `SetsAndLabelsTests.swift` | §D – §E: count and size laws, scipy's `test_subsets` traced exactly, label order, consistency on a `let` |
| `DisjointSetConformanceTests.swift` | §F, §G, §J: equality and hashing, value semantics, descriptions, `Sendable`, consumer patterns |
| `DisjointSetPreconditionTests.swift` | §H: exit tests |
| `DisjointSetStressTests.swift` | §I: 10⁶-element chains and star, the 2²⁰ binomial tree and 10⁶ random unions inside a `Task`; the differential test against a naive reference; petgraph's random law |

## Case IDs

Case IDs (DS-01 … DS-46) refer to the catalog of cases harvested from petgraph, Boost, NetworkX,
JGraphT, scipy and LEMON. Each test's name starts with its ID.

| Cases | Section | File |
|---|---|---|
| DS-01 – DS-07 | A. Construction | `DisjointSetConstructionTests.swift` |
| DS-08 – DS-18 | B. Union | `DisjointSetUnionTests.swift` |
| DS-19 – DS-25 | C. The representative rule | `RepresentativeRuleTests.swift` |
| DS-26 – DS-27 | D. Counts and sizes | `SetsAndLabelsTests.swift` |
| DS-28 – DS-30 | E. `sets()` and `labels()` | `SetsAndLabelsTests.swift` |
| DS-31 – DS-33 | F. Equality and hashing (DS-32 also checks that the 15 partitions of four elements hash apart, added after a planted hash of `count` alone survived) | `DisjointSetConformanceTests.swift` |
| DS-34 – DS-36 | G. Value semantics | `DisjointSetConformanceTests.swift` |
| DS-37 – DS-38 | H. Preconditions | `DisjointSetPreconditionTests.swift` |
| DS-39 – DS-43 | I. Large inputs and the differential test | `DisjointSetStressTests.swift` |
| DS-44 – DS-46 | J. Descriptions, `Sendable`, consumer patterns | `DisjointSetConformanceTests.swift` |
| DS-B01 – DS-B10 | Benchmarks | not tests: tree height, whether a `find` compressed, and copy-on-write allocations are not observable through the public API |
