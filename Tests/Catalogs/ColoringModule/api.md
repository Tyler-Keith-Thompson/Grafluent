# ColoringModule: proposed API (phase 1)

Vertex colourings and edge colourings of an undirected graph. A vertex colouring is a `Coloring`
(a colour index per vertex, the number of colours, and the colour classes); an edge colouring is
an `EdgeColoring` (a colour index per edge position).

* **Greedy vertex colouring.** One entry point, `greedyColoring(strategy:)`, with NetworkX's
  strategies as an enum: largest first (Welsh–Powell), smallest last (Matula–Beck), saturation
  largest first (DSatur, Brélaz), independent set, and connected sequential breadth-first and
  depth-first. `greedyColoring(order:)` colours in any order the caller gives (Boost's
  `sequential_vertex_coloring`). A random order is `greedyColoring(order: vertices.shuffled(using:))`,
  so `random_sequential` needs no strategy of its own.
* **Exact.** `chromaticNumber()` (χ) and `minimumColoring()`, an optimal colouring: on each
  connected component, the lexicographically least colour vector with that component's χ colours.
  Bipartite components cost O(n + m); the rest are solved by DSatur branch and bound with a clique
  lower bound (Brélaz; San Segundo).
* **Edge colouring.** `edgeColoring()`, Misra–Gries with at most Δ + 1 colours (Vizing's bound) on
  a simple graph. `bipartiteEdgeColoring()`, König's alternating-path recolouring with exactly Δ
  colours on any bipartite graph, parallel edges included, or nil when the graph is not bipartite.
* **Checks**: `isVertexColoring(_:)`, `isEdgeColoring(_:)`.

`cases.md` (CO-001 – CO-253, 253 cases) pins the values. `ref.py` computes every row from a model
of this API and checks it independently. Greedy rows are compared with NetworkX 3.7 `greedy_color`:
they are equal on every loop-free row for largest first and DSatur, and on most rows for the other
strategies, where the remaining differences come from NetworkX iterating Python sets (each one is
noted). Chromatic numbers are checked against an inclusion–exclusion count
(Björklund–Husfeldt–Koivisto) up to 18 vertices, and above that against a clique of that size, an
odd cycle, or the literature value (Mycielski M5 = 5, queen(6) = 7). Optimal colourings are checked
against brute force over restricted-growth vectors, or against a second index-order search that has
no colourability oracle. Edge colourings are checked for properness and for their bounds, with
rustworkx's colour counts beside them. `--stress` adds 1,500 random graphs on up to 9 vertices with
shuffled edge orders and orientations, plus 300 random bipartite multigraphs. On all of them largest
first and DSatur equal NetworkX, χ equals inclusion–exclusion, `minimumColoring()` equals brute
force, Misra–Gries is proper within Δ + 1 colours, and König uses exactly Δ. Run `uv run --quiet
--no-project --with networkx==3.7 --with rustworkx python3 ref.py [--stress] [--write]` (seconds).

## Scope

**In, phase 1**

| Entry point | On | Why |
|---|---|---|
| `greedyColoring(strategy:)` | `Graph` | README ("greedy, DSatur, Welsh–Powell"). NetworkX `greedy_color(G, strategy)`, igraph `vertex_coloring_greedy(method)`, rustworkx `graph_greedy_color(strategy=ColoringStrategy.…)`. One name with an enum, the shape all three use |
| `greedyColoring(order:)` | `Graph` | Boost `sequential_vertex_coloring(g, order, color)`, NetworkX `greedy_color` with a callable strategy, JGraphT `GreedyColoring(graph, order)`. Also covers `random_sequential` (shuffle first) and the orders other modules produce (`degeneracyOrdering`, a BFS order) |
| `chromaticNumber()` | `Graph` | README ("exact chromatic number"). Sage `chromatic_number`, JGraphT `BrownBacktrackColoring.getChromaticNumber`, Mathematica `VertexChromaticNumber`. χ without the lexicographic pass, as `cliqueNumber()` beside `maximumClique()` |
| `minimumColoring()` | `Graph` | Mathematica `FindVertexColoring`, Sage `vertex_coloring()`, JGraphT `BrownBacktrackColoring.getColoring`. Property-defined (lexicographic), as `maximumClique()` and `maximumIndependentSet()` are |
| `edgeColoring()` | `Graph` | README ("edge coloring"). Boost `edge_coloring` (Misra–Gries), rustworkx `graph_misra_gries_edge_color`, Sage `edge_coloring` |
| `bipartiteEdgeColoring()` | `Graph` | rustworkx `graph_bipartite_edge_color`. König's theorem: χ′ = Δ on bipartite graphs, constructively. The one optimal edge colouring available in polynomial time |
| `isVertexColoring(_:)`, `isEdgeColoring(_:)` | `Graph` | NetworkX `is_coloring` (in `equitable_coloring`), igraph C `igraph_is_vertex_coloring`, `igraph_is_edge_coloring` |
| `Coloring<G>`, `EdgeColoring<G>` | — | JGraphT `VertexColoringAlgorithm.Coloring` (`getColors`, `getNumberColors`, `getColorClasses`), Graphs.jl `Coloring` (`num_colors`, `colors`) |

**NetworkX functions, and where each goes**

| NetworkX | Here | Reason |
|---|---|---|
| `greedy_color(G, "largest_first")` (default) | `greedyColoring()` = `greedyColoring(strategy: .largestFirst)` | In, the same default. Equal on every loop-free row (CO-026 – CO-048) and on all 1,500 stress graphs: its `sorted(..., reverse=True)` is stable, so ties keep node order, which is our rule |
| `"smallest_last"` | `.smallestLast` | In. NetworkX pops degree buckets that are Python sets, so its ties are hash order. Ours take the least index. Equal on 1,097 of 1,500 stress graphs; CO-049 – CO-064 note each difference. NetworkX raises `KeyError` on a self-loop (CO-015) |
| `"saturation_largest_first"`, `"DSATUR"` | `.saturationLargestFirst` | In, the same tie rule (saturation, then degree, then node order: `max` over a node-ordered dict keeps the first). Equal on every loop-free row (CO-065 – CO-087) and stress graph |
| `"independent_set"` | `.independentSet` | In. Its `min(remaining, key=degree)` iterates a set; ours takes the least index on ties. Equal on 1,449 of 1,500 (CO-097 – CO-099 differ) |
| `"connected_sequential_bfs"`, `"_dfs"`, `"connected_sequential"` | `.connectedSequentialBreadthFirst`, `.connectedSequentialDepthFirst` | In. NetworkX starts each component at `arbitrary_element` of a set; ours at the least vertex. Equal on 1,499 of 1,500 (CO-114, CO-115 show the case: {5, 9} hashes 9 first) |
| `"random_sequential"` | `greedyColoring(order: g.vertices.shuffled(using: &rng))` | Not a strategy: a shuffled order. No `using:` overload (open question 6) |
| callable `strategy` | `greedyColoring(order:)` | In, given as the order itself (NetworkX passes a function of (G, colors); only DSatur reads `colors`, and it is a strategy here) |
| `greedy_color(..., interchange=True)` | — | Phase 2 (open question 2). Kosowski–Manuszewski's Kempe-chain interchange is deterministic, but NetworkX rejects it for two of its strategies, which an enum would have to reject at run time |
| `equitable_color(G, num_colors)` | — | Phase 2. Kierstead–Kostochka's Hajnal–Szemerédi algorithm, about 500 lines in NetworkX, needs `num_colors > Δ`. It returns *a* colouring from dict and set orders, which we would have to pin |
| `coloring.equitable_coloring.is_coloring`, `is_equitable` | `isVertexColoring(_:)` | `is_coloring` in, with the loop difference (Semantics). `is_equitable` is one line the caller can write from `colorClasses`; phase 2 with `equitable_color` |
| `chromatic_polynomial` | — | Out: symbolic (SymPy). Belongs with a future polynomial module, if any |
| (none) | `chromaticNumber()`, `minimumColoring()`, `edgeColoring()`, `bipartiteEdgeColoring()` | NetworkX has no exact colouring and no edge colouring. rustworkx, Boost, Sage and JGraphT are the references |

**Also out**

| Not in phase 1 | Reason |
|---|---|
| Exact chromatic index χ′ (Vizing class 1 or 2) | Phase 2. NP-hard even for cubic graphs (Holyer), so it would be a separate search. Phase 1 gives Δ or Δ + 1 colours, and exactly Δ on bipartite graphs |
| Edge colouring of non-bipartite multigraphs (Shannon ⌊3Δ/2⌋, Vizing Δ + μ), greedy edge colouring (rustworkx `graph_greedy_edge_color`, at most 2Δ − 1) | Phase 2 (open question 3). Misra–Gries's fans need distinct neighbours |
| Recursive largest first (Leighton's RLF), tabu search (TabuCol), JGraphT `ColorRefinementAlgorithm` | Phase 2 if asked. RLF is the usual next heuristic. Colour refinement is a different problem (the Weisfeiler–Leman 1-dimensional colouring) and belongs with `IsomorphismModule` |
| List colouring, k-colourability with fixed vertices, precolouring | Phase 2: `minimumColoring`'s search already supports fixed vertices internally |
| Directed graphs | Out. A colouring of a digraph is a colouring of `digraph.undirected` (README: `undirected` view), which tests use; its edges through `greedyEdgeColoring()`, which takes the antiparallel pairs `edgeColoring()` rejects |
| Planar 4- or 5-colouring (LEMON `Planarity` colorings) | Waits for `Planarity` |
| Vertex-weighted or interval colouring, total colouring, distance-2 colouring (Jacobian compression, ColPack) | Phase 2 or never; ColPack's distance-2 colouring is the next candidate if sparse-Jacobian users appear |

## Summary

```swift
import GraphProtocols
import BipartiteGraphs

/// How `greedyColoring(strategy:)` orders the vertices. Each vertex in turn takes the least
/// colour none of its already coloured neighbours has (first fit). Degrees are simple degrees
/// (distinct other neighbours); ties go to the lesser vertex index.
@frozen
public enum ColoringStrategy: Hashable, Sendable, CaseIterable {
    /// Degree descending (Welsh–Powell). NetworkX `largest_first`, the same colouring.
    case largestFirst
    /// Matula–Beck: repeatedly remove a vertex of least degree in what is left, then colour in
    /// the reverse of that removal order. At most degeneracy + 1 colours; at most 6 on a planar graph.
    case smallestLast
    /// DSatur (Brélaz): first a vertex of greatest degree, then repeatedly the uncoloured vertex
    /// with the most distinct colours among its neighbours, ties to the greatest degree. NetworkX
    /// `saturation_largest_first`, the same colouring. Exact on bipartite graphs.
    case saturationLargestFirst
    /// Colour classes one at a time: each a maximal independent set of the uncoloured vertices,
    /// built by repeatedly taking the vertex of least degree among those still available
    /// and removing it and its neighbours. NetworkX `independent_set`.
    case independentSet
    /// Components by least vertex, each in breadth-first order from its least vertex, neighbours in
    /// `incidentEdges` order. NetworkX `connected_sequential_bfs`.
    case connectedSequentialBreadthFirst
    /// The same in depth-first preorder. NetworkX `connected_sequential_dfs`.
    case connectedSequentialDepthFirst
}

extension Graph {
    // Vertex colouring. Each colours the simple graph: self-loops are ignored (no colouring
    // could satisfy one), and parallel edges count once.

    /// A greedy colouring (NetworkX `greedy_color`, the same colours on simple graphs; Boost
    /// `sequential_vertex_coloring` in the strategy's order). At most Δ + 1 colours. O(n + m)
    /// for every strategy except DSatur and independent set, O((n + m) log n).
    public func greedyColoring(strategy: ColoringStrategy = .largestFirst) -> Coloring<Self>

    /// First fit in `order`. Precondition: `order` lists every vertex exactly once. O(n + m).
    public func greedyColoring(order: some Sequence<Vertex>) -> Coloring<Self>

    /// The chromatic number χ of the simple graph: 0 for the empty graph, 1 without edges, 2 when
    /// bipartite with an edge. Otherwise DSatur branch and bound on each non-bipartite component,
    /// exponential in the worst case.
    public func chromaticNumber() -> Int

    /// An optimal colouring: on each connected component, of all its colourings with its own
    /// chromatic number of colours, the one whose colour vector (in `vertices` order) is
    /// lexicographically least. So colour classes are numbered by their least vertex, a
    /// bipartite component is coloured by its `bipartition()` sides (left 0), and `colorCount ==
    /// chromaticNumber()`. Exponential in the worst case.
    public func minimumColoring() -> Coloring<Self>

    /// Whether `color` gives the two ends of every edge different colours. Self-loops are ignored,
    /// as the colourings ignore them. Any Ints count as colours. `color` is called once per vertex. O(n + m).
    public func isVertexColoring(_ color: (Vertex) -> Int) -> Bool

    // Edge colouring.

    /// An edge colouring with at most Δ + 1 colours (Misra–Gries, Vizing's bound; Boost
    /// `edge_coloring`). Edges in position order, each one through a fan at its end with the lesser vertex index. O(n · m).
    /// Precondition: the graph is simple (no self-loops, no parallel edges).
    public func edgeColoring() -> EdgeColoring<Self>

    /// An edge colouring with exactly Δ colours, Δ counting parallel edges (König; rustworkx
    /// `bipartite_edge_color`), or nil
    /// when the graph is not bipartite (a self-loop makes it not bipartite). Parallel edges are
    /// fine. Edges in position order; a Kempe path is flipped when the two ends' least free colours
    /// differ. O(n · m).
    public func bipartiteEdgeColoring() -> EdgeColoring<Self>?

    /// Whether every two edges with a common end (parallel edges, or a self-loop and another edge
    /// at its vertex) have different colours. `color` is called once per edge. O(n + m).
    public func isEdgeColoring(_ color: (Edges.Index) -> Int) -> Bool
}

/// A proper colouring of a graph's vertices by colours 0..<colorCount, each of which is used.
/// It keeps a copy of the graph to look vertices up (copy-on-write, O(1) to make), as `Partition`.
@frozen
public struct Coloring<G: Graph>: Equatable, CustomStringConvertible {
    /// The number of colours: χ for `minimumColoring()`. 0 for the empty graph.
    public var colorCount: Int { get }
    /// The colour of `vertex`. O(1) after `vertexIndex(of:)`. Precondition: a vertex of the graph.
    public func color(of vertex: G.Vertex) -> Int
    /// The colour of the vertex at `index`. Precondition: `index` in `0..<vertexCount`.
    public func color(ofIndex index: Int) -> Int
    /// The vertices of each colour, by colour, each in `vertices` order (slices of one flat
    /// array; JGraphT `getColorClasses`). Each is an independent set.
    public var colorClasses: [ArraySlice<G.Vertex>] { get }
    /// Equal when every vertex has the same colour (the graphs are not compared).
    public static func == (lhs: Coloring, rhs: Coloring) -> Bool
}
extension Coloring: Sendable where G: Sendable, G.Vertex: Sendable {}

/// A proper edge colouring by colours 0..<colorCount, each of which is used.
@frozen
public struct EdgeColoring<G: Graph>: Equatable, CustomStringConvertible {
    public var colorCount: Int { get }
    /// The colour of the edge at `position`: O(1) with edge indices, O(log m) without.
    public func color(ofEdgeAt position: G.Edges.Index) -> Int
    /// The edge positions of each colour, ascending. Each is a matching.
    public var colorClasses: [ArraySlice<G.Edges.Index>] { get }
}
extension EdgeColoring: Sendable where G: Sendable, G.Edges.Index: Sendable {}
```

**One entry point with a strategy enum, not six names.** NetworkX (`strategy=`), igraph
(`method=`) and rustworkx (`ColoringStrategy`) all have one greedy function with a strategy
parameter. Each strategy only produces an order and then runs the same first-fit pass, so the
strategies are values of one choice, not separate algorithms. Separate names (Graphs.jl
`degree_greedy_color`, JGraphT's classes `LargestDegreeFirstColoring`, `SmallestDegreeLastColoring`,
`SaturationDegreeColoring`) would add five entry points with identical signatures and documentation
that differ in one sentence. An enum also lets tests loop over `ColoringStrategy.allCases`, for
example to check properness and the Δ + 1 bound. The enum is `ColoringStrategy`, rustworkx's name.

**Welsh–Powell has no name of its own.** Welsh and Powell colour class by class: the first colour
goes to every vertex, in degree order, not adjacent to one already holding it, then the second
colour, and so on. That gives the same colouring as first fit in the same order (by induction, a
vertex gets colour c in both exactly when its earlier neighbours hold every colour below c and
none holds c). So `.largestFirst` is Welsh–Powell; its doc comment says so, and there is no
typealias.

**`.saturationLargestFirst`, not `.dsatur`.** The enum's cases are NetworkX's strategy names, all
six from one source. `"DSATUR"` is an alias in NetworkX, so the doc comment carries the name
(open question 1).

**Why `minimumColoring()` is per component.** The obvious rule is the lexicographically least
colour vector among all χ(G)-colourings, but it couples components. When some other component
needs χ(G) = 3, a bipartite component may take a third colour because that gives a lexicographically
smaller vector. The path numbered 0–2–3–1 next to a triangle would get [0, 0, 1, 2] instead of its
bipartition [0, 1, 1, 0] (CO-183 pins the per-component answer). Per component, `minimumColoring()`
restricted to a component equals `minimumColoring()` of that component as a graph. On bipartite
graphs it equals `bipartition()` (left 0, right 1), which is a cross-module test. Overall it is
still the lexicographically least among colourings that are optimal on every component (a product
of independent choices has its least element at each factor's least element), and its colour
classes are still numbered by least vertex.

**Why `bipartiteEdgeColoring()` is a separate name returning an optional.** Misra–Gries does
not guarantee Δ colours on bipartite graphs: CO-253 (lcgb(8,5,30,11)) gets 8 where Δ = 7, and
König gives 7 on the same graph (CO-228). A
`BipartiteGraph` overload of `edgeColoring()` would shadow the `Graph` one, and MatchingModule and
Covering both rejected that, because generic code would get different results from concrete code.
The König algorithm needs no sides, only bipartiteness, so it takes no `Bipartition`. When the
graph is not bipartite it returns nil, the README's rule for failures that are part of the
mathematics (`findOddCycle()` gives the witness).

## Names

| Grafluent | Used by | Not chosen, and why |
|---|---|---|
| colouring, `Coloring`, `colorCount`, `colorClasses`, `color(of:)` | JGraphT `Coloring` (`getNumberColors`, `getColorClasses`, `getColors`); Graphs.jl `Coloring` (`num_colors`); Boost returns the number of colours | `numberOfColors` (JGraphT's getter, Swift-style): `colorCount` matches `vertexCount`, `edgeCount`. American spelling as in all code names |
| `greedyColoring` | NetworkX `greedy_color`, rustworkx `graph_greedy_color`, igraph `vertex_coloring_greedy`, Graphs.jl `greedy_color` | `sequentialVertexColoring` (Boost): less familiar; `greedyColor`: a verb phrase that does not say it returns a colouring |
| `ColoringStrategy`, `strategy:` | rustworkx `ColoringStrategy`, NetworkX `strategy=` | `GreedyColoringStrategy`: longer, no library uses it |
| `.largestFirst`, `.smallestLast`, `.saturationLargestFirst`, `.independentSet`, `.connectedSequentialBreadthFirst`, `.connectedSequentialDepthFirst` | NetworkX strategy strings | `.welshPowell`, `.matulaBeck`, `.dsatur`: authors' names, used in doc comments; `…BFS`/`…DFS` (NetworkX's suffix): the README spells out `BreadthFirstSearch` (open question 1) |
| `order:` | Boost `sequential_vertex_coloring(g, order, color)` | `strategy:` with a closure (NetworkX): the order is simpler to pass |
| `chromaticNumber()` | Sage `chromatic_number`, JGraphT `BrownBacktrackColoring.getChromaticNumber`, Mathematica `VertexChromaticNumber`; χ(G) | — |
| `minimumColoring()` | Mathematica `FindVertexColoring` (Combinatorica `MinimumVertexColoring` before it); "minimum colouring" in the literature; Grafluent's `minimumVertexCover`, `maximumClique` | `optimalColoring()`; `vertexColoring()` (Sage, which leaves the optimum implicit); `minimumVertexColoring()`: "vertex" is implied by the unqualified word, as in χ (open question 4) |
| `edgeColoring()` | Boost `edge_coloring`, Sage `edge_coloring`, Mathematica `FindEdgeColoring` | `misraGriesEdgeColoring` (rustworkx `graph_misra_gries_edge_color`): only needed if a second Δ + 1 algorithm appears |
| `bipartiteEdgeColoring()` | rustworkx `graph_bipartite_edge_color` | `edgeColoring(bipartition:)`: the algorithm needs no sides |
| `isVertexColoring`, `isEdgeColoring` | NetworkX `is_coloring`; igraph C `igraph_is_vertex_coloring`, `igraph_is_edge_coloring` | `isProperColoring`: no library uses it; "colouring" already means proper in all of them |

**Unqualified "colouring" means vertex colouring**, as χ means the vertex chromatic number:
NetworkX `greedy_color`, rustworkx `graph_greedy_color` beside `graph_greedy_edge_color`, Boost
`sequential_vertex_coloring` beside `edge_coloring`. Edge colourings always say "edge".

**Proposed Terminology rows**

* Colours on vertices, adjacent ones different: colouring, `Coloring`, `greedyColoring()`,
  `minimumColoring()`; the least number of colours the chromatic number, `chromaticNumber()`.
  NetworkX, JGraphT, Sage. Mathematical term: proper vertex colouring; χ(G).
* Colours on edges, edges with a common end different: edge colouring, `EdgeColoring`,
  `edgeColoring()`. Boost, Sage, rustworkx. Mathematical term: proper edge colouring; the least
  number is the chromatic index χ′(G).

## Semantics

### Self-loops, parallel edges, isolated vertices, directed graphs

* **Vertex colourings ignore self-loops.** No proper colouring exists when a self-loop is counted,
  so a strict reading would make every entry point optional or trap. NetworkX `greedy_color`, Boost
  `sequential_vertex_coloring` and igraph colour around loops (the vertex is not yet coloured when
  its own row is read), and Cliques already works on the simple graph. So the colourings are of
  the simple graph, the loop does not count in the degree that orders vertices (CO-022 – CO-025),
  and χ ignores loops (CO-131, CO-166). `isVertexColoring` ignores loops too, so every result passes it
  (CO-235, CO-236). NetworkX's `is_coloring` returns false on those rows, and its degrees count a
  loop twice, so its largest-first and DSatur orders differ on looped graphs (CO-022, CO-023). Its
  smallest-last raises `KeyError` (CO-015). Open question 5 is whether to trap instead.
* **Parallel edges count once** for vertex colouring, in degrees too (CO-018, CO-021, CO-128,
  CO-134). For edge colouring they are distinct edges that share both ends, so they need different
  colours (CO-226, CO-244). `edgeColoring()` requires a simple graph (traps CO-215, CO-216);
  `bipartiteEdgeColoring()` accepts parallel edges.
* **Isolated vertices** get colour 0 (CO-016, CO-170). The empty graph has `colorCount` 0 and no
  classes (CO-001 – CO-006, CO-167); an edgeless graph has χ = 1 (CO-132).
* **Directed graphs**: not here. Colour `digraph.undirected`; for its edges use `greedyEdgeColoring()` (or `bipartiteEdgeColoring()`), since `edgeColoring()` traps on any antiparallel pair.

### Colour numbers

* The colour numbers a greedy colouring returns are first-fit numbers, NetworkX's exactly. They are
  not renumbered by least vertex: colour 0 goes to the first vertex coloured, which need not be vertex 0
  (CO-022: [1, 2, 0, 1]; CO-052: smallest last gives the star's hub colour 1). First-fit numbering is what greedy
  colouring means, and keeping it makes `Coloring` equal to NetworkX's dict, vertex for vertex.
* Every colour in 0..<colorCount is used, since first fit only opens a new colour when the lower ones
  are taken. `colorClasses[c]` lists colour c's vertices in `vertices` order, so the classes are
  canonical for a given colouring.
* `==` compares colour vectors, so two colourings with the same classes under different numbers
  are not equal. That is the strict choice. Tests that want classes compare `Set`s of
  `colorClasses`.
* `minimumColoring()` is lexicographically least per component, so its colours appear in first
  appearance order along `vertices` within each component (restricted growth), and overall each
  class's least vertex is less than the next class's.

### Greedy strategies (each pinned against NetworkX)

* **First fit**: each vertex takes the least colour that none of its already coloured neighbours
  holds. At most Δ + 1 colours whatever the order. `.smallestLast` uses at most degeneracy + 1
  (CO-049 – CO-064 check it), so at most 6 on a planar graph (CO-064: icosahedral, 5).
* **`.largestFirst`**: sort by (simple degree descending, vertex index ascending). Equal to NetworkX
  on every loop-free row and stress graph. Ties keep vertex order (CO-040), labels do not matter
  (CO-039).
* **`.smallestLast`**: remove a least-degree vertex (the least index on ties) until none is left,
  then colour in the reverse removal order. This is Matula–Beck, NetworkX's definition. Its ties
  differ: NetworkX pops a set (CO-052 is a star whose leaves NetworkX removes in another order).
  Batagelj–Zaversnik's order (Cliques' `degeneracyOrdering`) is *not* used: it keeps a vertex's
  bucket at the current core level instead of lowering it, so it is not always a smallest-last
  order (`ref.py` found several catalog graphs where it is not, Petersen among them).
* **`.saturationLargestFirst`**: the first vertex has the greatest degree (the least index on
  ties). Then each next vertex maximizes (number of distinct neighbour colours, degree in the whole
  graph), the least index on ties. NetworkX's rule: degree in the whole graph, not in the uncoloured
  part as in Brélaz's paper. Equal to NetworkX everywhere loop-free. On a new component every
  saturation is 0, so it restarts at that component's greatest degree (CO-084). Exact on bipartite
  graphs (CO-076: crownx(5), 2 colours; largest first needs k colours on crownx(k), CO-038).
* **`.independentSet`**: class k is built from the vertices not yet coloured. While some are still
  available, take the one with the fewest available neighbours (the least index on ties), then make
  it and its neighbours unavailable. Every vertex of class k gets colour k: it is adjacent to every
  earlier class, since each is maximal among what was left, and to nothing in its own class. So the
  order inside a class does not matter, which is why NetworkX can yield a set. It differs from
  NetworkX only where NetworkX's set iteration is not ascending (CO-097 – CO-099).
* **`.connectedSequential…`**: components by least vertex, each started at its least vertex,
  neighbours in `incidentEdges` order (parallel copies and loops skipped), BFS or DFS preorder.
  NetworkX starts at `arbitrary_element(component)` (CO-114, CO-115).
* **`greedyColoring(order:)`**: first fit in the caller's order. The crown graph in interleaved
  order needs n/2 colours (CO-122: crown(4), 4 colours; CO-038 is the same trap reached through
  largest first on `crownx`). Order preconditions: CO-248 – CO-250.

### `chromaticNumber()`, `minimumColoring()`

* **Fast cases.** χ = 0 for the empty graph, 1 with no non-loop edge, 2 when bipartite with an
  edge (BipartiteGraphs' two-colouring, O(n + m)). Otherwise χ ≥ 3, and χ = max over components.
* **Search** (per non-bipartite component; the result does not depend on it). The upper bound is
  greedy DSatur. The lower bound is a clique found greedily, or Cliques-style by a colouring bound;
  its vertices are fixed to colours 0..<q, which breaks symmetry. Then DSatur branch and bound
  (Brélaz 1979, with San Segundo's 2012 tie-breaking as an option): branch on the uncoloured vertex
  with the fewest colours left (the most distinct neighbour colours), trying used colours ascending,
  then one new colour only while it stays below the best. The search stops when the bounds meet.
  Mycielski graphs (CO-146 – CO-148) and queen graphs (CO-152 – CO-154) are the hard rows, with
  χ above ω.
* **Lexicographically least colouring** (per component, k = its χ). First, first fit in index
  order: if it uses at most k colours, it is the answer, since first fit is the lexicographically
  least proper colouring of all. Otherwise each vertex in index order takes the least colour c ≤
  (greatest so far) + 1 such that the prefix still extends to a k-colouring, which the same
  branch and bound decides with the prefix fixed. That is n · k feasibility calls at most, each
  exponential in the worst case. CO-182 is a row where first fit fails and the search decides;
  CO-181 is bipartite, where it is the bipartition.
* **Witness.** χ has no small certificate in general. Tests check `minimumColoring()` with
  `isVertexColoring`, `colorCount == chromaticNumber()`, `chromaticNumber() >= cliqueNumber()`
  (Cliques, as a test dependency), and on small graphs brute force.

### `edgeColoring()` (Misra–Gries)

* **Procedure** (Misra and Gries 1992, the version that stops the fan early). Edges are taken
  in position order. For an edge {u, v}, u is the end with the lesser vertex index and c is the least
  colour free at u. The fan F starts as [v] and grows while c is not free at its last vertex: next is
  the neighbour x ∉ F of u whose edge ux has the least colour free at the last vertex. If c is free
  at the last fan vertex, d = c. Otherwise d is the least colour free there, and the d/c path from u
  is flipped. Then w is the first fan vertex such that F up to w is still a fan and d is free at w;
  the fan is rotated up to w and uw gets d. Colours stay in 0...Δ.
* **Bounds**: Δ ≤ colours ≤ Δ + 1. On class-1 graphs it may still use Δ + 1 (CO-200: K(4), 4).
  CO-211 shows the result depending on edge order. Equal to rustworkx's colouring on small rows;
  the counts are listed beside each row (CO-198: ours 2, rustworkx 3).
* **Precondition**: simple graph. A self-loop or parallel edges trap (CO-215, CO-216). The check
  costs nothing, since the fan pass reads every row anyway.

### `bipartiteEdgeColoring()` (König)

* For each edge {u, v} in position order (u the lesser index), a is the least colour free at u and b
  the least free at v. If a is used at v, flip the a/b path starting at v. Then colour the edge a.
  In a bipartite graph that path never reaches u, so exactly Δ colours are used, parallel edges
  included (CO-217 – CO-228; 300 stress multigraphs). Misra–Gries may use Δ + 1 on the same
  inputs (CO-253). nil on non-bipartite inputs (CO-229 –
  CO-231). The counts agree with rustworkx `bipartite_edge_color` on every row.

### Checks

* `isVertexColoring` calls the closure once per vertex, then compares the ends of every non-loop edge. Any
  Int values count (CO-239: [7, −2, 7]). `isEdgeColoring` compares the colours of the edges at each
  vertex, a self-loop once (CO-246, CO-247). Out-of-range lookups are the closure's own business.

## Determinism (decision)

| Entry point | Which result | Tests assert |
|---|---|---|
| `greedyColoring(strategy:)` | First fit in the strategy's order; ties to the lesser vertex index; simple degrees | Exact; = NetworkX for `.largestFirst` and `.saturationLargestFirst` on loop-free graphs, for the rest where NetworkX's set order is ascending |
| `greedyColoring(order:)` | First fit in the given order | Exact; = NetworkX with a callable strategy |
| `chromaticNumber()` | χ | Exact |
| `minimumColoring()` | Per component, the lexicographically least colour vector with that component's χ colours | Exact; brute force; = `bipartition()` sides on bipartite graphs |
| `edgeColoring()` | Misra–Gries as above, positions in order | Exact; proper; ≤ Δ + 1 |
| `bipartiteEdgeColoring()` | König path flips as above, positions in order | Exact; proper; = Δ |
| checks | Definitions | Exact |

The exact colouring is defined by a property, so the search can change without changing results.
The greedy and edge colourings are defined by their procedures, as `maximalMatching()` is.

## Complexity

n vertices, m edges, Δ the greatest simple degree.

| Entry point | Time | Extra memory |
|---|---|---|
| `greedyColoring` `.largestFirst`, `.connectedSequential…`, `order:` | O(n + m) (counting sort by degree) | n colours, a stamp array of Δ + 2 |
| `.smallestLast` | O((n + m) log n): a heap of (degree, index) with stale entries | heap of n + m |
| `.saturationLargestFirst` | O((n + m) log n): a heap keyed (saturation, degree, −index), with a per-vertex bitset or sorted set of neighbour colours | heap, colour sets O(n + m) |
| `.independentSet` | O((n + m) log n) per class worst; O(χ (n + m) log n) total | heap per class |
| `chromaticNumber`, `minimumColoring` | O(n + m) to split; exponential per non-bipartite component | bitset rows c² / 64 words per component, a flat search stack |
| `edgeColoring` | O(n · m): each edge's fan and path are O(n) | a colour → edge table per vertex, (Δ + 1) · n |
| `bipartiteEdgeColoring` | O(n · m) | Δ · n |
| checks | O(n + m) | n colours |

## Implementation notes (index space)

* **Rows.** Each algorithm is an `_UndirectedRowsAlgorithm` run by `_runOnUndirectedRows`, as
  `_TwoColoring` and Covering's `_CopyCoveringGraph` are. Vertex colouring reads simple rows, built
  with a stamp per row scan in first-appearance order (loops dropped, parallel copies once), which
  `_CopyCoveringGraph` and Cliques' `_simpleRows()` already do. ColoringModule cannot import either,
  so it gets its own copy, and the final reuse pass merges them (project memo). Edge colouring reads
  edge numbers (`readsEdges: true`).
* **First fit** with a stamp array (`used[c] = v` for each coloured neighbour, then scan up), as
  `_semisynchronousLabelPropagation` does. That function's ordering is exactly `.largestFirst`, so
  CommunityDetection could call ColoringModule's once the reuse pass runs (it does not depend on it
  today).
* **DSatur**: per-vertex saturation counts kept with a per-vertex colour bitset (Δ + 1 bits) or a
  count per (vertex, colour) pair. Then a binary heap of (saturation, degree, index), lazily
  re-pushed when saturation rises (it only rises), the same lazy-key heap as Covering's greedy
  dominating set.
* **Smallest last**: a heap of (degree, index) with stale entries skipped (degrees only fall). An
  O(n + m) bucket queue would need a tie rule that depends on the procedure. Open question 7.
* **Exact search**: bitset rows of each non-bipartite component (`[UInt64]`, c words per row),
  colour classes as bitsets, available colours per vertex as a `UInt64` mask when k ≤ 64 (else
  multiword), and a flat stack with no recursion, the layout of `_CliqueSubproblem.search`. The
  clique lower bound is a greedy clique in degree order, improved by Cliques' colouring bound if
  benchmarks say so. The lexicographic pass reuses the same search as a feasibility oracle with a
  fixed prefix.
* **Bipartite shortcut**: BipartiteGraphs' `_TwoColoring` (`@usableFromInline`, already inlinable
  across modules) gives the sides; this is why ColoringModule depends on BipartiteGraphs.
* **Edge colouring**: `at: [Int32]` of n · (Δ + 1) entries, the edge of each colour at each vertex
  or −1, so "is c free at x" is O(1); the least free colour is a scan (or a per-vertex free bitset).
  Path flips walk `at`. `colorClasses` by a counting pass over edge numbers into position order.
* **Results**: `Coloring` stores `_colors: [Int]` by vertex number, `_members: [G.Vertex]` and
  `_offsets: [Int]` for the classes (the counting layout of `Partition.init`), the graph, and
  `_numbers` for graphs without vertex indices. `EdgeColoring` stores colours by edge number and
  positions sorted by colour then position.
* **Dependencies**: GraphProtocols, BipartiteGraphs (as `scripts/modules.py` lists).
* **Tests** (public API only, self-contained): every catalog row; `multigraph` rows with an in-file
  `Graph` conformer. Properties with swift-property-based: every strategy's colouring passes
  `isVertexColoring` and uses ≤ Δ + 1 colours, `.smallestLast` ≤ degeneracy + 1 (Cliques' `coreNumbers()`
  as a test dependency), `.saturationLargestFirst` = 2 colours on bipartite graphs; `greedyColoring
  (strategy: s).colorCount >= chromaticNumber()`; `minimumColoring().colorCount == chromaticNumber()
  >= cliqueNumber()`; on bipartite graphs `minimumColoring()` matches `bipartition()`; edge
  colourings pass `isEdgeColoring`, Misra–Gries within [Δ, Δ + 1], König = Δ. `just diff` against
  NetworkX `greedy_color` (largest first and DSatur exactly) and rustworkx edge-colour counts.
  `just mutate`: the degree tie rule (CO-040), DSatur's degree tie (CO-084), the restart rule, fan
  stop (CO-198), the flip direction in König (CO-226). `just fuzz`: `minimumColoring` against brute
  force on random small graphs. Benchmarks against igraph `vertex_coloring_greedy` (both methods),
  rustworkx, and NetworkX.

## Library disagreements found

| Where | What | Catalog |
|---|---|---|
| Self-loops in degrees | NetworkX counts a loop twice in the degree that orders largest first and DSatur; ours ignores loops | CO-022 – CO-024 |
| NetworkX `smallest_last` on a self-loop | Raises `KeyError` (it removes a neighbour from the bucket of its current degree, but the loop has already changed that degree) | CO-015 |
| Smallest-last ties | NetworkX pops Python sets; ours least index | CO-052 – CO-064 |
| Independent-set and connected-sequential ties | NetworkX iterates sets (`min` over a set, `arbitrary_element`); ours least index | CO-097 – CO-099, CO-114, CO-115 |
| `is_coloring` and loops | NetworkX false whenever there is a loop; ours ignores loops | CO-235, CO-236 |
| DSatur ties | NetworkX breaks saturation ties by degree in the whole graph; Brélaz by degree in the uncoloured subgraph; igraph by its own rule (`vertex_coloring_greedy(method="dsatur")` on a triangle with a pendant gives [2, 1, 0, 1], ours and NetworkX [1, 2, 0, 1]). Ours follows NetworkX | — |
| Misra–Gries details | rustworkx's choices differ (CO-198: 3 colours where ours uses 2); Boost's are its own | EdgeColoring rows |
| Edge colouring in NetworkX | none exists | — |

## README edits proposed

* **Algorithms table, `ColoringModule` row**: "On `Graph`, over its simple graph:
  `greedyColoring(strategy:)` (NetworkX's strategies: largest first (Welsh–Powell), smallest last,
  DSatur, independent set, connected sequential; NetworkX's colourings), `greedyColoring(order:)`,
  `chromaticNumber()` and `minimumColoring()` (exact, DSatur branch and bound; the
  lexicographically least optimal colouring per component), `edgeColoring()` (Misra–Gries, ≤ Δ + 1),
  `bipartiteEdgeColoring()` (König, Δ), `isVertexColoring`, `isEdgeColoring` (**planned**, phase 1).
  Later: interchange, equitable colouring, exact chromatic index, multigraph edge colouring" |
  results "`Coloring` (a colour per vertex, `colorCount`, `colorClasses`), `EdgeColoring`".
* **Terminology**: the two rows under Names.
* **`scripts/modules.py`**: description "Vertex coloring (greedy strategies, exact chromatic
  number), edge coloring (Misra–Gries, König)."

## Open questions

1. **Strategy case names.** NetworkX's names (`.saturationLargestFirst`,
   `.connectedSequentialBreadthFirst`) or the common short ones (`.dsatur`, `.welshPowell`,
   `.connectedSequentialBFS`)? The README names DSatur and Welsh–Powell in prose.
2. **Interchange.** NetworkX's `interchange=True` (Kempe-chain swaps when a new colour would open) is
   deterministic and often saves colours. Add it as a `Bool` parameter, which must be rejected
   at run time for two strategies as NetworkX does, or as `greedyColoring(order:interchange:)` only?
3. **Multigraph edge colouring.** A greedy edge colouring (≤ 2Δ − 1, rustworkx
   `graph_greedy_edge_color`) would cover non-bipartite multigraphs, which phase 1 does not. Add it in
   phase 1, or wait for a caller?
4. **`minimumColoring()` vs `optimalColoring()`**, and whether `chromaticIndex()` (exact χ′) is wanted
   in phase 2.
5. **Self-loops: ignore or trap?** Ignoring matches NetworkX's colouring, Boost, igraph and Cliques,
   but `isVertexColoring` then disagrees with NetworkX's `is_coloring`. A precondition would make the
   contradiction loud, at the cost of a check in every entry point and of rejecting pseudographs.
6. **`using:` overloads** (`greedyColoring(using:)` for `random_sequential`, as in CommunityDetection)
   or leave shuffling to the caller with `order:`?
7. **Smallest-last in O(n + m).** The least-index tie needs a heap. A bucket queue is O(n + m) but its
   tie rule would depend on the procedure (as Batagelj–Zaversnik's does). Is the log factor
   acceptable?
8. **`Coloring` equality**: compare colour vectors (proposed), or classes up to renumbering? The
   latter would make two greedy colourings with permuted colours equal, but they are different
   functions V → colour.
9. **Equitable colouring** (`equitable_color`, Hajnal–Szemerédi) in phase 2: worth the code size?
10. **Traces not verified here.** Checked by running them: NetworkX 3.7, rustworkx 0.18.1 (`ColoringStrategy`,
    `graph_misra_gries_edge_color`, `graph_bipartite_edge_color`, `graph_greedy_edge_color`) and
    python-igraph 1.0 (`vertex_coloring_greedy` only, no check function). Cited from memory, then checked against the current
    documentation in review: igraph `is_vertex_coloring` / `is_edge_coloring`, Mathematica
    `VertexChromaticNumber` and `FindVertexColoring` (Combinatorica's `ChromaticNumber` is legacy),
    JGraphT `BrownBacktrackColoring` (there is no `ChromaticNumber` class), Boost `edge_coloring` being Misra–Gries. Confirm
    these before the README edit.

## Changes after the review

* **`isVertexColoring(_:)`** replaces `isColoring(_:)` (igraph `is_vertex_coloring`, beside
  `is_edge_coloring`).
* **`greedyEdgeColoring()`**: rustworkx `graph_greedy_edge_color` (largest first on the line graph,
  ties by position), at most 2Δ − 1 colours, any graph: parallel edges, self-loops (one edge at their
  vertex, as `isEdgeColoring` meets them) and so `digraph.undirected`, which `edgeColoring()` rejects
  as soon as it has an antiparallel pair. The directed-graph guidance points at it.
* **`greedyColoring(strategy:presetColor:)`**: rustworkx `graph_greedy_color(preset_color_fn=)`.
  Preset vertices keep their colours and are coloured first; static orders are the whole graph's
  with them skipped; DSatur counts them in saturation; the independent set's class k starts without
  the neighbours of vertices preset to k. `colorCount` is the greatest colour + 1, so a class can be
  empty. Traps on a negative preset or two adjacent presets alike.
* **`ColoringStrategy.coloredNeighbors`**: igraph `IGRAPH_COLORING_GREEDY_COLORED_NEIGHBORS`, with
  igraph's two-way heap ported so ties fall as igraph's do (the same colours as python-igraph on
  simple graphs). `ColoringStrategy` is no longer `@frozen`.
* **`Coloring.colors`**: the colour vector in `vertices` order (JGraphT `getColors`, Graphs.jl
  `colors`).
* **Edge colouring memory** is O(n + m): per vertex, a row indexed by colour when Δ + 1 is at most
  twice its table, else an open-addressing table (linear probing, backward-shift deletion) of a power
  of two at least twice its degree; `Int32` edges and colours; a per-vertex bound below which every
  colour is used. Misra–Gries's fan step scans the edges at u (O(deg u)), so its time is
  O(m (Δ² + n)) (the earlier O(n · m) was wrong).
* **`minimumColoring()`**: each candidate colour c < witness[v] is first tried by a Kempe swap of
  the witness's (c, witness[v]) chain from v, when the chain avoids the prefix; otherwise DSatur
  branch and bound runs only over the region of later vertices that v reaches through later
  vertices (the prefix separates regions; the rest keeps the witness). On components of average
  degree at most 8 that search also uses conflict-directed backjumping, tries the witness's colours
  first, and restarts with doubling budgets and new tie orders (its runtimes have heavy tails).
* **Smallest last, DSatur and the independent set** use an indexed heap (decrease-key, no stale
  entries); the independent set cuts its rows down to the uncoloured vertices after each class.
* Exact entry points document that they can take exponential time and do not check cancellation.

## Changes after the second review

* **`minimumColoring()`** (user decision) is now the exact search's own optimal colouring, renumbered
  by first appearance in `vertices` order: deterministic, and as fast as `chromaticNumber()`, as
  JGraphT `BrownBacktrackColoring.getColoring` and Sage `vertex_coloring()` return whichever optimal
  colouring their search finds. Per component: a bipartite one its two-colouring, the others the
  colouring DSatur branch and bound found, or greedy DSatur's when it uses no more colours than
  another component needs (the skip `chromaticNumber()` already made). A wholly bipartite graph
  keeps its `bipartition()` sides. Measured (release, review-bench): planted 3-colourable G(n, 2n)
  1.1 ms at n = 5000 and 1.3 ms at 2000, G(2000, 4000) 1.3 ms, against 2.6 s, 0.47 s and over
  100 s for the lexicographic pass.
* **`lexicographicallyFirstMinimumColoring()`** keeps the old semantics: per component the
  lexicographically least colour vector with that component's χ colours. The name traces to
  Khuller and Vazirani, "Planar graph coloring is not self-reducible, assuming P ≠ NP" (TCS 88,
  1991), whose "lexicographically first four coloring" / "LF-k coloring" is exactly this order on
  colour vectors, and whose self-reduction (each vertex the least colour its prefix still extends
  with, by a decision oracle) is the algorithm here; they show the planar LF-4 colouring NP-hard.
  "Lexicographically first" is also the literature's word for the greedy cases (the
  lexicographically first maximal independent set; first fit in index order is the lexicographically
  first proper colouring, this method's fast path). No library names an optimal one
  (NetworkX, igraph, JGraphT, Sage, Mathematica and Boost have none); `lexicographicallyLeast…`
  has no source. Documented as slow on large sparse graphs (0.2 s at 1000, 2.7 s at 2000, > 100 s at
  5000 on planted 3-colourable G(n, 2n)).
* **Catalog**: CO-167 – CO-194 now call `lexicographicallyFirstMinimumColoring()` (group
  LexicographicallyFirstMinimumColoring); CO-254 – CO-281 repeat those graphs for
  `minimumColoring()`, with Expected χ and the rule, and the colours where forced (no edges;
  bipartite; the only χ-colouring numbered by first appearance, by exhaustive search on ≤ 12
  vertices: K3, K5, wheel(6), CO-271).
* **`greedyColoring(order:)`** runs first fit straight on the graph's rows (`_FirstFitRows`), with
  no simple-rows copy (a loop or a parallel copy only marks a colour again), and checks an order's
  vertex with one hash (`vertexIndex(of:)`, then `vertex(atIndex:) == vertex`) instead of two.
