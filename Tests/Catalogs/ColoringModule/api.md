# ColoringModule: API

Vertex colourings and edge colourings of an undirected graph. A vertex colouring is a `Coloring`
(a colour per vertex, the number of colours, and the colour classes); an edge colouring is an
`EdgeColoring` (a colour per edge position).

* **Greedy vertex colouring.** `greedyColoring(strategy:)` with a `ColoringStrategy`: largest first
  (Welsh–Powell), smallest last (Matula–Beck), saturation largest first (DSatur, Brélaz),
  independent set, connected sequential breadth-first and depth-first, and colored neighbours.
  `greedyColoring(strategy:presetColor:)` fixes some colours in advance. `greedyColoring(order:)`
  colours in any order the caller gives; a random order is
  `greedyColoring(order: vertices.shuffled(using:))`.
* **Exact.** `chromaticNumber()` (χ); `minimumColoring()`, an optimal colouring numbered by first
  appearance; and `lexicographicallyFirstMinimumColoring()`, on each connected component the
  lexicographically least colour vector with that component's χ colours. Bipartite components
  cost O(n + m); the rest are solved by DSatur branch and bound with a clique lower bound.
* **Edge colouring.** `edgeColoring()`, Misra–Gries with at most Δ + 1 colours (Vizing's bound) on
  a simple graph. `bipartiteEdgeColoring()`, König's alternating-path recolouring with exactly Δ
  colours on any bipartite graph, parallel edges included, or nil when the graph is not bipartite.
  `greedyEdgeColoring()`, the line graph's largest-first colouring, with at most 2Δ − 1 colours on
  any graph.
* **Checks**: `isVertexColoring(_:)`, `isEdgeColoring(_:)`.

`cases.md` (CO-001 – CO-281, 281 cases) pins the values. `ref.py` computes every row from a model of
this API and checks it independently. Greedy rows are compared with NetworkX 3.7 `greedy_color`:
they are equal on every loop-free row for largest first and DSatur, and on most rows for the other
strategies, where the remaining differences come from NetworkX iterating Python sets (each one is
noted). Chromatic numbers are checked against an inclusion–exclusion count
(Björklund–Husfeldt–Koivisto) up to 18 vertices, and above that against a clique of that size, an
odd cycle, or the literature value (Mycielski M5 = 5, queen(6) = 7). Lexicographically first
colourings are checked against brute force over restricted-growth vectors, or against a second
index-order search that has no colourability oracle. Edge colourings are checked for properness and
for their bounds, with rustworkx's colour counts beside them. `--stress` adds 1,500 random graphs on
up to 9 vertices with shuffled edge orders and orientations, plus 300 random bipartite multigraphs.
Run `uv run --quiet --no-project --with networkx==3.7 --with rustworkx python3 ref.py [--stress]
[--write]`.

## Summary

```swift
import GraphProtocols
import BipartiteGraphs

/// How `greedyColoring(strategy:)` orders the vertices. Each vertex in turn takes the least
/// colour none of its already coloured neighbours has (first fit). Degrees are simple degrees
/// (distinct other neighbours); ties go to the lesser vertex index, except for `.coloredNeighbors`.
public enum ColoringStrategy: Hashable, Sendable, CaseIterable {
    case largestFirst                     // degree descending (Welsh–Powell)
    case smallestLast                     // Matula–Beck; at most degeneracy + 1 colours
    case saturationLargestFirst           // DSatur; exact on bipartite graphs
    case independentSet                   // colour classes as maximal independent sets
    case connectedSequentialBreadthFirst  // components by least vertex, breadth-first
    case connectedSequentialDepthFirst    // the same, depth-first preorder
    case coloredNeighbors                 // most coloured neighbours, ties by a two-way heap
}

extension Graph {
    // Vertex colouring. Each colours the simple graph: self-loops are ignored and parallel edges
    // count once.
    public func greedyColoring(strategy: ColoringStrategy = .largestFirst) -> Coloring<Self>
    public func greedyColoring(strategy: ColoringStrategy = .largestFirst,
                               presetColor: (Vertex) -> Int?) -> Coloring<Self>
    public func greedyColoring(order: some Sequence<Vertex>) -> Coloring<Self>
    public func chromaticNumber() -> Int
    public func minimumColoring() -> Coloring<Self>
    public func lexicographicallyFirstMinimumColoring() -> Coloring<Self>
    public func isVertexColoring(_ color: (Vertex) -> Int) -> Bool

    // Edge colouring.
    public func edgeColoring() -> EdgeColoring<Self>              // simple graphs; ≤ Δ + 1
    public func bipartiteEdgeColoring() -> EdgeColoring<Self>?    // exactly Δ, or nil
    public func greedyEdgeColoring() -> EdgeColoring<Self>        // any graph; ≤ 2Δ − 1
    public func isEdgeColoring(_ color: (Edges.Index) -> Int) -> Bool
}

/// A proper colouring of a graph's vertices by colours 0..<colorCount. It keeps a copy of the
/// graph to look vertices up (copy-on-write, O(1) to make).
public struct Coloring<G: Graph>: Equatable, CustomStringConvertible {
    public var colorCount: Int { get }
    public var colors: [Int] { get }                  // in `vertices` order
    public func color(of vertex: G.Vertex) -> Int
    public func color(checked vertex: G.Vertex) throws(VertexNotFound) -> Int
    public func color(ofIndex index: Int) -> Int
    public var colorClasses: [ArraySlice<G.Vertex>] { get }   // each in `vertices` order
    public static func == (lhs: Coloring, rhs: Coloring) -> Bool   // colour vectors
}

/// A proper edge colouring by colours 0..<colorCount.
public struct EdgeColoring<G: Graph>: Equatable, CustomStringConvertible {
    public var colorCount: Int { get }
    public func color(ofEdgeAt position: G.Edges.Index) -> Int
    public func color(checkedEdgeAt position: G.Edges.Index) throws(EdgeNotFound) -> Int
    public var colorClasses: [ArraySlice<G.Edges.Index>] { get }  // positions ascending; each a matching
}
```

Each strategy only produces an order and then runs the same first-fit pass, so the strategies are
cases of one enum. Welsh–Powell's class-by-class colouring equals first fit in the same order, so
`.largestFirst` is Welsh–Powell. `bipartiteEdgeColoring()` is separate from `edgeColoring()`
because Misra–Gries does not guarantee Δ colours on bipartite graphs: CO-253 gets 8 where Δ = 7,
and König gives 7 on the same graph (CO-228). It needs no sides, only bipartiteness, and returns
nil otherwise (`findOddCycle()` gives the witness).

## Semantics

### Self-loops, parallel edges, isolated vertices, directed graphs

* **Vertex colourings ignore self-loops**, since no proper colouring exists when one counts. The
  loop does not count in the degree that orders vertices (CO-022 – CO-025), and χ ignores loops
  (CO-131, CO-166). `isVertexColoring` ignores loops too, so every result passes it (CO-235,
  CO-236).
* **Parallel edges count once** for vertex colouring, in degrees too (CO-018, CO-021, CO-128,
  CO-134). For edge colouring they are distinct edges that share both ends, so they need different
  colours (CO-226, CO-244). `edgeColoring()` requires a simple graph (traps CO-215, CO-216);
  `bipartiteEdgeColoring()` and `greedyEdgeColoring()` accept parallel edges.
* **Isolated vertices** get colour 0 (CO-016, CO-170). The empty graph has `colorCount` 0 and no
  classes (CO-001 – CO-006, CO-167); an edgeless graph has χ = 1 (CO-132).
* **Directed graphs**: colour `digraph.undirectedView`; for its edges use `greedyEdgeColoring()`
  (or `bipartiteEdgeColoring()`), since `edgeColoring()` traps on any antiparallel pair.

### Colour numbers

* A greedy colouring returns first-fit numbers, not renumbered by least vertex: colour 0 goes to
  the first vertex coloured, which need not be vertex 0 (CO-022: [1, 2, 0, 1]; CO-052: smallest
  last gives the star's hub colour 1).
* Every colour in 0..<colorCount is used, since first fit only opens a new colour when the lower
  ones are taken. With preset colours a colour can be skipped, and its class is empty.
  `colorClasses[c]` lists colour c's vertices in `vertices` order.
* `==` compares colour vectors, so two colourings with the same classes under different numbers
  are not equal. Tests that want classes compare `Set`s of `colorClasses`.
* `minimumColoring()` numbers colours by first appearance in `vertices` order.
  `lexicographicallyFirstMinimumColoring()` is lexicographically least per component, so its
  colours appear in first-appearance order within each component.

### Greedy strategies

* **First fit**: each vertex takes the least colour that none of its already coloured neighbours
  holds. At most Δ + 1 colours whatever the order. `.smallestLast` uses at most degeneracy + 1
  (CO-049 – CO-064 check it), so at most 6 on a planar graph (CO-064: icosahedral, 5).
* **`.largestFirst`**: sort by (simple degree descending, vertex index ascending). Ties keep vertex
  order (CO-040); labels do not matter (CO-039).
* **`.smallestLast`**: remove a least-degree vertex (the least index on ties) until none is left,
  then colour in the reverse removal order (Matula–Beck). Batagelj–Zaversnik's order (Cliques'
  `degeneracyOrdering`) is not used: it keeps a vertex's bucket at the current core level instead
  of lowering it, so it is not always a smallest-last order (Petersen is a counterexample).
* **`.saturationLargestFirst`**: the first vertex has the greatest degree (the least index on
  ties). Then each next vertex maximizes (number of distinct neighbour colours, degree in the whole
  graph), the least index on ties. On a new component every saturation is 0, so it restarts at that
  component's greatest degree (CO-084). Exact on bipartite graphs (CO-076: crownx(5), 2 colours;
  largest first needs k colours on crownx(k), CO-038).
* **`.independentSet`**: class k is built from the vertices not yet coloured. While some are still
  available, take the one with the fewest available neighbours (the least index on ties), then make
  it and its neighbours unavailable. Every vertex of class k gets colour k.
* **`.connectedSequential…`**: components by least vertex, each started at its least vertex,
  neighbours in `incidentEdges` order (parallel copies and loops skipped), BFS or DFS preorder.
* **`.coloredNeighbors`**: the vertex of greatest degree first (the least index on ties), then
  repeatedly the uncoloured vertex with the most coloured neighbours. Ties fall as a two-way
  indexed binary max-heap breaks them: vertices are pushed in index order and raised neighbour by
  neighbour in ascending order; an entry moves above an equal parent and sinks to the left child
  unless the right one is strictly greater.
* **`presetColor:`**: preset vertices keep their colours and count as coloured from the start.
  Static orders are the whole graph's with them skipped; DSatur counts them in saturation; the
  independent set's class k starts without the neighbours of vertices preset to k;
  `.coloredNeighbors` counts preset neighbours as coloured. Traps on a negative preset or two
  adjacent presets alike.
* **`greedyColoring(order:)`**: first fit in the caller's order. The crown graph in interleaved
  order needs n/2 colours (CO-122: crown(4), 4 colours; CO-038 is the same trap reached through
  largest first on `crownx`). Order preconditions: CO-248 – CO-250.

### `chromaticNumber()`, `minimumColoring()`, `lexicographicallyFirstMinimumColoring()`

* **Fast cases.** χ = 0 for the empty graph, 1 with no non-loop edge, 2 when bipartite with an
  edge (BipartiteGraphs' two-colouring, O(n + m)). Otherwise χ ≥ 3, and χ = max over components.
* **Search** (per non-bipartite component). The upper bound is greedy DSatur. The lower bound is a
  largest clique (Cliques' branch and bound, stopped at the upper bound); its vertices are fixed to
  colours 0..<q, which breaks symmetry. Then DSatur branch and bound (Brélaz 1979): branch on the
  uncoloured vertex with the most distinct neighbour colours, trying used colours ascending, then
  one new colour only while it stays below the best. The search stops when the bounds meet.
  Mycielski graphs (CO-146 – CO-148) and queen graphs (CO-152 – CO-154) are the hard rows, with χ
  above ω.
* **`minimumColoring()`** is the search's own optimal colouring, renumbered by first appearance in
  `vertices` order. A bipartite component gets its two-colouring; the others get the colouring
  DSatur branch and bound found, or greedy DSatur's when it uses no more colours than another
  component needs. A wholly bipartite graph keeps its `bipartition()` sides. It costs the same as
  `chromaticNumber()` (CO-254 – CO-281).
* **`lexicographicallyFirstMinimumColoring()`** (per component, k = its χ; Khuller and Vazirani's
  LF-k colouring). First fit in index order is tried first: if it uses at most k colours it is the
  answer, since it is the lexicographically least proper colouring of all. Otherwise each vertex in
  index order takes the least colour its prefix still extends with: a Kempe swap of the last
  colouring found when the chain avoids the prefix, else DSatur branch and bound over the region of
  later vertices the vertex reaches (with conflict-directed backjumping and restarts on sparse
  components). Exponential in the worst case, and much slower than `minimumColoring()` on large
  sparse graphs (CO-167 – CO-194; CO-182 is a row where first fit fails).

### `edgeColoring()` (Misra–Gries)

* **Procedure** (Misra and Gries 1992, the version that stops the fan early). Edges are taken in
  position order. For an edge {u, v}, u is the end with the lesser vertex index and c is the least
  colour free at u. The fan F starts as [v] and grows while c is not free at its last vertex: next
  is the neighbour x ∉ F of u whose edge ux has the least colour free at the last vertex. If c is
  free at the last fan vertex, d = c. Otherwise d is the least colour free there, and the d/c path
  from u is flipped. Then w is the first fan vertex such that F up to w is still a fan and d is free
  at w; the fan is rotated up to w and uw gets d. Colours stay in 0...Δ.
* **Bounds**: Δ ≤ colours ≤ Δ + 1. On class-1 graphs it may still use Δ + 1 (CO-200: K(4), 4).
  CO-211 shows the result depending on edge order.
* **Precondition**: simple graph. A self-loop or parallel edges trap (CO-215, CO-216).

### `bipartiteEdgeColoring()` (König)

For each edge {u, v} in position order (u the lesser index), a is the least colour free at u and b
the least free at v. If a is used at v, flip the a/b path starting at v. Then colour the edge a. In
a bipartite graph that path never reaches u, so exactly Δ colours are used, parallel edges
included (CO-217 – CO-228). nil on non-bipartite inputs (CO-229 – CO-231).

### `greedyEdgeColoring()`

Edges by the number of other edges they share an end with, most first (a parallel copy counts at
both ends, a self-loop meets each other edge at its vertex once), ties in position order; each
takes the least colour of no already coloured edge it shares an end with. At most 2Δ − 1 colours.

### Checks

`isVertexColoring` calls the closure once per vertex, then compares the ends of every non-loop
edge. Any Int values count (CO-239: [7, −2, 7]). `isEdgeColoring` compares the colours of the edges
at each vertex, a self-loop once (CO-246, CO-247).

## Determinism

| Entry point | Which result |
|---|---|
| `greedyColoring(strategy:)` | First fit in the strategy's order; ties to the lesser vertex index (`.coloredNeighbors`: the heap's); simple degrees |
| `greedyColoring(order:)` | First fit in the given order |
| `chromaticNumber()` | χ |
| `minimumColoring()` | The search's optimal colouring, numbered by first appearance |
| `lexicographicallyFirstMinimumColoring()` | Per component, the lexicographically least colour vector with that component's χ colours |
| `edgeColoring()` | Misra–Gries as above, positions in order |
| `bipartiteEdgeColoring()` | König path flips as above, positions in order |
| `greedyEdgeColoring()` | The line graph's largest first, ties in position order |

## Complexity

n vertices, m edges, Δ the greatest simple degree.

| Entry point | Time |
|---|---|
| `greedyColoring` `.largestFirst`, `.connectedSequential…`, `order:` | O(n + m) |
| `.smallestLast`, `.saturationLargestFirst`, `.coloredNeighbors` | O((n + m) log n), indexed heaps |
| `.independentSet` | O(χ (n + m) log n) |
| `chromaticNumber`, `minimumColoring`, `lexicographicallyFirstMinimumColoring` | O(n + m) to split; exponential per non-bipartite component |
| `edgeColoring` | O(m · (Δ² + n)) |
| `bipartiteEdgeColoring` | O(m · (n + Δ)) |
| `greedyEdgeColoring` | O(n + m · Δ) |
| checks | O(n + m) |

Edge colourings use O(n + m) memory: per vertex, a row indexed by colour when Δ + 1 is at most
twice its table, else an open-addressing table of a power of two at least twice its degree.

## Implementation notes (index space)

* **Rows.** Each algorithm is an `_UndirectedRowsAlgorithm` run by `_runOnUndirectedRows`. Vertex
  colouring reads simple rows, built with a stamp per row scan in first-appearance order (loops
  dropped, parallel copies once). `greedyColoring(order:)` runs first fit on the graph's own rows.
  Edge colouring reads edge numbers.
* **First fit** uses a stamp array (`used[c] = v` for each coloured neighbour, then scan up).
* **DSatur** keeps each vertex's neighbour colours 0...degree in a bitset (colours above the degree
  in one shared hash set) and an indexed heap keyed by (saturation, degree), lowered as the
  saturation rises. Smallest last and the independent set use indexed heaps too.
* **Exact search**: bitset rows of each non-bipartite component, colour classes as bitsets, and a
  flat stack with no recursion. The clique lower bound comes from Cliques' maximum-clique search.
* **Bipartite shortcut**: BipartiteGraphs' two-colouring gives the sides.
* **Results**: `Coloring` stores colours by vertex number and the classes in the counting layout of
  `Partition`; `EdgeColoring` stores colours by edge number and positions sorted by colour then
  position.
