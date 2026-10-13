# SpanningTrees API

Minimum and maximum spanning forests of undirected graphs (`Graph`), by Kruskal, Prim and
Borůvka, and an unweighted spanning forest.

## Public API

```swift
/// A spanning forest of an undirected graph: one spanning tree per connected component, as edge
/// positions in the graph's `edges`, with the sum of their weights.
@frozen
public struct SpanningForest<G: Graph, Weight: Comparable & AdditiveArithmetic> {
    public let edges: [G.Edges.Index]   // in the order the algorithm added them
    public let weight: Weight           // added up in `edges` order; zero with no edges
}
// Equatable. Hashable when Weight is. Sendable when G.Edges.Index and Weight are.

extension Graph {
    // The canonical minimum spanning forest, in nondecreasing (weight, position) order.
    func minimumSpanningTree<W>(weight: (Edges.Index) -> W) -> SpanningForest<Self, W>
    // Every edge weighs 1: the first forest in position order. `weight` is the edge count.
    func minimumSpanningTree() -> SpanningForest<Self, Int>
    // The canonical maximum spanning forest, in nonincreasing weight, ties by position.
    func maximumSpanningTree<W>(weight: (Edges.Index) -> W) -> SpanningForest<Self, W>
    // The canonical forest, in the order taken.
    func kruskalMinimumSpanningTree<W>(weight: (Edges.Index) -> W) -> SpanningForest<Self, W>
    // A minimum spanning forest over every component; ties unspecified.
    func primMinimumSpanningTree<W>(weight: (Edges.Index) -> W) -> SpanningForest<Self, W>
    // A minimum spanning tree of root's component only.
    func primMinimumSpanningTree<W>(from root: Vertex, weight: (Edges.Index) -> W) -> SpanningForest<Self, W>
    // The canonical forest's edges, by round.
    func boruvkaMinimumSpanningTree<W>(weight: (Edges.Index) -> W) -> SpanningForest<Self, W>
}

extension Forest {
    // Every vertex of `graph` in `vertices` order, and the forest's edges in `forest.edges` order.
    init<G: Graph, W>(_ forest: SpanningForest<G, W>, in graph: G)
}
```

`W` is `Comparable & AdditiveArithmetic` throughout. Nothing is offered on `DirectedGraph`; call
`digraph.undirectedView.minimumSpanningTree(weight:)`. Each arc becomes an edge, so `u → v` and
`v → u` are parallel edges and the lighter one wins.

## Semantics

| Question | Rule |
|---|---|
| Result | Edge positions plus the total weight, with no copy of the graph. Positions stay valid until the graph is mutated |
| Disconnected graphs | A forest of n − c edges from every entry point except `from:`, which spans the root's component only (ST-47) |
| Ties | Edges are ordered by (weight, position in `edges`). Under that strict order the minimum spanning forest is unique. `minimumSpanningTree(weight:)`, Kruskal and Borůvka return it; the maximum reverses the weight only. Prim's choice among equal weights is unspecified |
| Position | The order of `edges`. With edge indices, `edges` is in index order, so `edgeIndex(of:)` is the position's rank |
| Edge order | Default and Kruskal: nondecreasing (weight, position). Maximum: nonincreasing weight, ties by ascending position. Unweighted: ascending position. Prim: each edge joins a spanned vertex to a new one, trees started at the first unspanned vertex in `vertices` order. Borůvka: by round, unspecified within a round |
| Default algorithm | `minimumSpanningTree(weight:)` runs Kruskal when the graph has fewer than 4 edges per vertex. Otherwise it runs Prim under (weight, position), scanning an array of keys instead of a heap when the graph has vertex indices and at least n²/4 edges, then sorts the n − 1 edges taken. The forest is the same either way |
| Self-loops | Never in the forest and never weighed, so a NaN self-loop does not trap (ST-57) |
| Parallel edges | The lightest copy wins; among equal copies, the first position (ST-28, ST-30) |
| Negative and zero weights | Ordinary weights |
| NaN | Every weight read is checked (`precondition(w == w)`), so a NaN weight on any non-loop edge traps, on or off the forest (ST-58) |
| ±∞ | Ordinary weights: a `+∞` bridge is in the tree (ST-52). A forest holding both `+∞` and `−∞` has a NaN total, which traps (ST-55) |
| Total weight | Added up in `edges` order. Overflow traps (ST-60); `Int.max` exactly is fine (ST-59). Kruskal and Prim add Doubles in different orders, so their Double totals can differ in the last ulp |
| Maximum | A reversed comparison, never negation, so `UInt8` works (ST-61) |
| Vertex indices | With `vertexIndexBound`, every array is indexed by vertex and no vertex is hashed (ST-128). Without it, vertices are numbered once through a dictionary |
| Edge indices | With `edgeIndexBound`, edges are gathered from the rows, each at its lower-index end, with no hashing. Without it, edges are walked in `edges` order and each endpoint is looked up once |
| Weight calls | Exactly once per non-loop edge for every algorithm. Prim skips an edge whose far end is already spanned before weighing it. `from:` weighs only the root's component (ST-63) |
| Equality | Compares the edge arrays and weights. Canonical results compare whole; Prim's and Borůvka's are compared as edge sets |

## Complexity

- Kruskal: O(m log m) comparisons plus O(m α(n)) for the union–find; stops once n − 1 edges are
  taken.
- Prim: O(m log n) with a 4-ary indexed heap; O(n² + m) with the array of keys.
- Borůvka: O(m log n) over at most ⌈log₂ n⌉ rounds, each a scan of the edges still between
  components.
- Unweighted: O(m α(n)), with no sort.
