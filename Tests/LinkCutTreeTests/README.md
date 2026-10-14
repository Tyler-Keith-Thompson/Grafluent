# LinkCutTree test suite

`LinkCutTree` is a forest of rooted trees on `0..<count` with link, cut, rerooting, and minimum
and addition of vertex costs along the path from a vertex to its root. Each test is
self-contained; the property test checks random operation sequences against a forest kept as a
parent array.

## API under test

```swift
struct LinkCutTree<Cost: Comparable & AdditiveArithmetic>   // Sendable where Cost: Sendable
    init(count: Int, cost: Cost)                             // traps if count < 0
    var count: Int
    mutating func root(of: Int) -> Int
    mutating func parent(of: Int) -> Int?
    mutating func inSameTree(_: Int, _: Int) -> Bool
    mutating func cost(of: Int) -> Cost
    mutating func pathMinimum(from: Int) -> (vertex: Int, cost: Cost)   // ties: any vertex of least cost
    mutating func setCost(of: Int, to: Cost)
    mutating func addCost(_: Cost, toPathFrom: Int)
    mutating func link(_ child: Int, to parent: Int)         // traps unless child is a root of another tree
    mutating func cut(_: Int)                                // traps on a root
    mutating func makeRoot(_: Int)
```
