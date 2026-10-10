# SpanningTrees test suite

`SpanningTrees`, phase 1: minimum and maximum spanning forests of undirected graphs (`Graph`),
by Kruskal, Prim (over every component, or from one root) and Borůvka, an unweighted spanning
forest, and the `SpanningForest` result. Nothing is offered on `DirectedGraph`; a bidirectional
digraph is spanned through `.undirected`. The suite was written before the implementation, from
the proposed API, and uses only the public API. Each test is self-contained; shared material is
the fixtures, the `ReferencePseudograph` test conformer and the seeded generator in
`GrafluentTestSupport`.

## API under test

```swift
struct SpanningForest<G: Graph, Weight: Comparable & AdditiveArithmetic>
        // Equatable; Hashable when Weight is; Sendable when G.Edges.Index and Weight are
    let edges: [G.Edges.Index]                         // positions in the graph's edges, in the algorithm's order
    let weight: Weight                                 // their sum, added in edges order; zero when empty

extension Graph
    func minimumSpanningTree(weight: (Edges.Index) -> W) -> SpanningForest<Self, W>         // the canonical forest (Kruskal when sparse, Prim under (weight, position) when dense)
    func minimumSpanningTree() -> SpanningForest<Self, Int>                                  // first forest in position order; weight = edge count
    func maximumSpanningTree(weight:) -> SpanningForest<Self, W>                             // reversed comparison, ties by position
    func kruskalMinimumSpanningTree(weight:) -> SpanningForest<Self, W>                      // canonical, nondecreasing (weight, position)
    func primMinimumSpanningTree(weight:) -> SpanningForest<Self, W>                         // a forest; restarts in vertices order; ties unspecified
    func primMinimumSpanningTree(from root: Vertex, weight:) -> SpanningForest<Self, W>      // root's component only
    func boruvkaMinimumSpanningTree(weight:) -> SpanningForest<Self, W>                      // canonical edge set, by round
```

`W` is `Comparable & AdditiveArithmetic` throughout.

## Conventions

| Question | Choice | Why |
|---|---|---|
| Weights | A closure over edge positions, `(Edges.Index) -> W`. Tests keep weights in an array by position (`ReferencePseudograph`, `UndirectedAdjacencyList` and `AdjacencyList.undirected` built without repeated edges, so positions are the written order) or by cell (`AdjacencyMatrix.undirected`) | The only form that tells parallel edges apart and works on every representation |
| The tie rule | The default, Kruskal, Borůvka and the maximum return the canonical forest under the strict order (weight, position); the maximum reverses the weight only. Prim's choice among equal weights is unspecified | api.md, "Ties" |
| Edge order | Kruskal and the default: nondecreasing (weight, position). Maximum: nonincreasing weight, ties ascending position. Unweighted: ascending position. Prim: each edge joins a spanned vertex to a new one, trees started at the first unspanned vertex in `vertices` order. Borůvka: by round, unspecified within a round, so tests compare it as a set | api.md |
| Disconnected graphs | A forest of n − c edges from every entry point but `from:`, which spans the root's component only | NetworkX, JGraphT, igraph; Boost for `from:` |
| Self-loops | Never in the forest and never weighed, so a NaN self-loop does not trap (ST-31, ST-57, ST-63) | api.md |
| Weight calls | Exactly once per non-loop edge in every algorithm; `from:` only the root's component (ST-63, ST-127) | api.md |
| NaN, ±∞, overflow | A NaN weight on a non-loop edge traps in every algorithm, even off the forest (ST-58); ±∞ are ordinary weights; a NaN total (+∞ and −∞ in one forest) and an overflowing total trap; `Int.max` exactly is fine | api.md, ShortestPaths' rules |
| Maximum | Never negates, so `UInt8` works (ST-61, ST-85); it equals the minimum of the negated `Int` weights edge for edge (ST-89) | api.md |
| Results | Values without a copy of the graph: mutating the graph afterwards changes nothing (ST-124). Equatable, so canonical results compare whole (`==`); Hashable; Sendable whatever the graph (ST-125) | api.md |
| Index space | On an indexed `UndirectedAdjacencyList` no algorithm hashes a vertex; `from:` hashes only the root (ST-128) | ShortestPaths SP-129 |

## How tests pin values

| What | How |
|---|---|
| Canonical forests | Exact positions, in order, for the default, Kruskal and the maximum; Borůvka's as a set with the same count and weight |
| Prim | The weight and the edge count always; the exact set where the optimum is unique (or, for ST-08, ST-09 and ST-27, membership in the enumerated optima); the order only where it is forced (a path from its end, a star with distinct weights from its center) and otherwise through the joining rule (ST-104) |
| Totals | Exact. `Int` everywhere it can be; `Double` only with values exact in binary (ST-19's quarters, ST-48's path of ones) or with edge sets compared instead (ST-72) |
| Representations | `ReferencePseudograph` (written order; the host for parallel edges, self-loops and `String` vertices), `UndirectedAdjacencyList` (insertion order), `AdjacencyList.undirected` (each arc an edge, so opposite arcs are parallel), `AdjacencyMatrix.undirected` (cells, row-major; vertex indices but no edge indices), and three conformers private to their files: `PlainGraph` (no indices), `VertexIndexedGraph` (vertex indices only) and `RowGraph` (dense rows built without hashing, for the stress tests) |

Expected values come from the catalog's independent reference (`ref.py`: Kruskal with a stable
sort, Borůvka with the same order, a lazy Prim, brute-force enumeration with optimum counts and a
cycle-property uniqueness check), cross-checked against NetworkX 3.7 and scipy 1.18.1, and from the
ported suites' own expectations (NetworkX, Boost, petgraph, JGraphT, LEMON, igraph, scipy).
Randomized tests write their oracles inside the test: a stable-sort Kruskal, union–find
components, brute-force enumeration, tree paths for cycle optimality and tree cuts for cut
optimality.

## Files

| File | Covers |
|---|---|
| `SpanningTreeBasicsTests.swift` | §A: the empty graph, one vertex, one edge, Wikipedia's graph from every Prim root, petgraph's Prim example and TEST_CASES (in petgraph's order), JGraphT, Boost's two doc examples and prim-example.cpp, LEMON's constant and negative costs (in LEMON's order), the Sörensen–Janssens graph, igraph's Frucht graph |
| `TiesAndMultigraphTests.swift` | §B: equal weights, K₄, Boost's kruskal-example.cpp, parallel copies (lighter, heavier, equal), self-loops never weighed, zero weights, positions not names, NetworkX's multigraphs |
| `ForestTests.swift` | §C: disconnected graphs, isolated vertices (one listed last), petgraph's and JGraphT's disconnected graphs, scipy's graph and planted path, Prim's forest against `from:` |
| `WeightEdgeCaseTests.swift` | §D: negative weights, ±∞, a NaN total, NaN weights (and with them filtered out), a NaN self-loop, `Int.max`, overflow, `UInt8`, `Double`, `Float`, `Duration` and a user type, weight-call counts |
| `AgreementTests.swift` | §E: every Int-weighted catalog case under every algorithm, tie-heavy random multigraphs against a stable-sort Kruskal and brute force, G(200, 0.5), igraph's multigraphs with loops, Prim's root, a long path for Borůvka |
| `MaximumSpanningTreeTests.swift` | §F: the maximum on the catalog's graphs, unsigned weights, −∞, and maximum = minimum of the negation |
| `RepresentationTests.swift` | §G: every representation and the two index-less conformers, `String` vertices |
| `SpanningTreePropertyTests.swift` | §H: seeded random graphs against oracles written in each test, and ST-107 with PropertyBased shrinking |
| `SpanningTreeStressTests.swift` | §I: a long path, a grid, a star, a complete graph, equal weights on a sparse random graph, the real-world fixtures, inside a `Task` |
| `SpanningTreeReviewTests.swift` | §K: cases added after planting bugs (`scripts/mutants/SpanningTrees.py`) and after the critical review, with file-private conformers with vertex indices only and with none |
| `SpanningTreeConformanceTests.swift` | §J: preconditions (exit tests), value semantics, Equatable / Hashable / Sendable, existentials and generic code, weight-call counts per representation, no vertex hashing, digraphs through `.undirected` |

## Case IDs

Case IDs (ST-01 … ST-134) refer to the catalog of cases (`Tests/Catalogs/SpanningTrees/cases.md`, with `ref.py` and `api.md`) harvested from NetworkX, Boost, petgraph,
JGraphT, LEMON, igraph and scipy. Each test's name starts with its ID; ST-56 and ST-58 each have a
trapping test and a filtered one.

| Cases | Section | File |
|---|---|---|
| ST-01 – ST-19 | A. Basics | `SpanningTreeBasicsTests.swift` |
| ST-25 – ST-36 | B. Ties, self-loops, parallel edges | `TiesAndMultigraphTests.swift` |
| ST-40 – ST-48 | C. Disconnected graphs: forests | `ForestTests.swift` |
| ST-50 – ST-63 | D. Weight edge cases | `WeightEdgeCaseTests.swift` |
| ST-70 – ST-75 | E. Algorithm agreement | `AgreementTests.swift` |
| ST-80 – ST-89 | F. Maximum | `MaximumSpanningTreeTests.swift` |
| ST-90 – ST-95 | G. Representations | `RepresentationTests.swift` |
| ST-100 – ST-107 | H. Properties (ST-107 with shrinking) | `SpanningTreePropertyTests.swift` |
| ST-110 – ST-116 | I. Stress | `SpanningTreeStressTests.swift` |
| ST-120 – ST-129 | J. Preconditions and conformance | `SpanningTreeConformanceTests.swift` |
| ST-130 – ST-134 | K. Added after planting bugs and after the critical review: a NaN weight on an edge never taken still traps on every path that reads weights; the default's total is added up in the listed order (no overflow Kruskal would not have); the dense path's tie rule on conformers with both indices, vertex indices only, and none; its Double total bit for bit; Prim from a root on a disconnected graph | `SpanningTreeReviewTests.swift` |
| ST-B01 – ST-B04 | Benchmarks | not tests |

Where the tests differ from the catalog:

- **Stress sizes (ST-110 – ST-116)** are scaled so each test stays under about two seconds in a
  debug build: a 10⁵-vertex path (catalog 10⁶), a 200 × 200 grid (1000 × 1000), a star with
  5 · 10⁴ leaves (10⁶), K₄₅₀ (K₁₅₀₀), and G(5 · 10⁴, 10⁵) (G(10⁵, 5 · 10⁵)). The catalog's sizes
  belong to the benchmarks (ST-B01). They run on `RowGraph`, a conformer private to the file,
  because building an `UndirectedAdjacencyList` of that size dominates a debug run; ST-115 runs on
  `AdjacencyList.undirected`.
- **ST-71 and ST-89** use 70 graphs per weight range (420 in all); ref.py's 400 trials are in
  Python. Brute force runs where a graph has at most 14 non-loop edges.
- **ST-72** compares Prim's Double total with Kruskal's within 1e-9 besides the edge sets.
- **ST-102** draws 300 graphs over 5 seeds.
- **ST-104** checks Prim's joining rule, and for `from:` that the first edge leaves the root; it
  does not check Borůvka's order, which is unspecified within a round.
- **ST-106** permutes positions and checks the weight, the sorted multiset of weights, and, with
  distinct weights, the edge set; it does not enumerate which tie changes.
- **ST-122 and ST-123** repeat ST-55 and ST-60 on `UndirectedAdjacencyList` for each entry point;
  ST-123 adds a `UInt8` maximum that overflows.
- **ST-120** covers the six weighted entry points on `UndirectedAdjacencyList`, two on
  `AdjacencyList.undirected` (ST-58's parallel NaN copy as opposite arcs) and two without indices.
- **ST-128** expects zero vertex hashes from every entry point but `from:` (the catalog names
  Kruskal and Borůvka), following api.md's "no hashing on an indexed graph".
- **CompressedSparseRow** is not used: it is a `DirectedGraph` only and has no `.undirected`.

Not tested here: that nothing is offered on `DirectedGraph` (ST-129's first half), which is a
compile-time property; the law that with edge indices `edges` is in index order, which is
`Graph`'s and tested there (UG-L25); and the benchmarks ST-B01 – ST-B04 (Kruskal against Prim
against Borůvka, gathering from rows against walking `edges`, a `(W, Int)` Prim priority, the early
exit at n − 1).
