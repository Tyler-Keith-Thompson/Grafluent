# Grafluent: notes for coding agents

Grafluent is a generic graph library for Swift 6.3 (minimum). Performance comes first: generic
code must run at the speed of a hand-written loop over arrays. Bazel is the development build;
SwiftPM is the published package. `README.md` is the user-facing overview.

## Layout

```
Sources/<Module>/              One directory per module, each with a generated BUILD.bazel
Sources/Grafluent/             Umbrella module (@_exported imports) and the landing DocC catalog
Tests/<Module>Tests/           One test target per module; Performance/ holds speed-reliant tests
Tests/GrafluentTests/          The README examples, verbatim
Tests/GrafluentTestSupport/    Shared test fixtures and test vertex types (data only)
Tests/Catalogs/<Module>/       Case catalogs, reference models and test generators (not compiled)
Benchmarks/                    Separate SwiftPM package (ordo-one/benchmark); Bazel ignores it
Differential/                  Differential-testing harness, driven by scripts/differential.py
Fuzz/                          libFuzzer targets, driven by scripts/fuzz.py
Explore/                       Browser explorer: Grafluent as WebAssembly with ElementaryUI (`just explore`)
scripts/modules.py             The module graph
scripts/mutants/<Module>.py    Hand-written mutants for `just mutate`
tools/                         Bazel rule wrappers (warnings as errors, Swift 6 mode), DocC rules
```

### Module graph

`scripts/modules.py` is the source of truth for modules, their dependencies, test targets,
external packages and platforms. `just modules` regenerates `Package.swift`, every `BUILD.bazel`,
the umbrella `Grafluent.swift` and the Differential manifests from it. Never edit the generated
files by hand; `//:package_swift_test` fails when `Package.swift` disagrees with the Bazel graph.

- Add a module: a row in `MODULES` (name, group, description, dependencies), then `just modules`.
- Add a test target: a row in `TEST_TARGETS`. A target with a `Performance/` directory of Swift
  sources must be listed in `PERFORMANCE_TESTS`, and the reverse.
- A module name takes a `Module` suffix only when it would otherwise equal its main type's name
  (`AdjacencyListModule` holds `AdjacencyList`). No catch-all modules ("Core", "Utilities").

Module groups: Vocabulary (`GraphProtocols`, `Walks`, `Semirings`), Data structures
(`PriorityQueueModule`, `DisjointSetModule`, `LinkCutTreeModule`), Representations, Structures, Operations
(`GraphOperations`, `GraphProducts`), Algorithms, Generators (`NamedGraphs`, `RandomGraphs`),
Drawing and formats (`GraphDrawing`, `GraphFormats`). The README's module table lists them all.

## Commands

Every shell command gets a timeout. macOS has no `timeout`; use
`perl -e 'alarm 1800; exec @ARGV' <command>`. A planted bug can make an algorithm loop forever.

| Command | Does |
|---|---|
| `just build` / `just test` | Build / test everything (debug) |
| `bazel test //Tests/XTests` | One test target (`just test-one //Tests/XTests`) |
| `just filter <pattern>` | Tests whose name matches |
| `just test-release` | `--config=release`: builds and runs only the `XPerformanceTests` targets |
| `just spm-test`, `just verify` | SwiftPM tests; both build systems |
| `just modules` | Regenerate build files from `scripts/modules.py` |
| `just mutate <Module>` | Mutation testing from `scripts/mutants/<Module>.py`; reports survivors |
| `just fuzz [Target] [-t secs]` | Time-boxed libFuzzer runs; `just fuzz-regress` replays corpora |
| `just diff [--module X]` | Differential tests against NetworkX, scipy, rustworkx and igraph |
| `just bench [--target X]` | Benchmarks; `just bench-compare` against the `main` baseline |
| `just explore` | The browser explorer as release WebAssembly into `Explore/dist/` |
| `just wasi-test [-c release] [--targets X,Y]` | SwiftPM tests on wasm32-wasi under wasmtime: a 32-bit `Int` |
| `just docs` | Combined DocC site into `.build/docs` |
| `bazel query 'rdeps(//Tests/..., //Sources/X)'` | Test targets affected by a change to X |

- Debug is the default configuration. Every test target except the `XPerformanceTests` ones is
  tagged `debug-only`, which `--config=release` filters out.
- A test that bounds wall-clock time, or runs a large input under `.timeLimit`, belongs in
  `Tests/X/Performance/`.
- Release builds use their own output base (see the justfile). Don't create other output bases
  or copies of the repo, and shut down any extra Bazel server you start.
- Run suites through Bazel, not `swift test --filter`. Only `mutate.py` builds inside
  `.build/mutation`.

### 32-bit `Int` (WebAssembly)

watchOS's arm64_32 and wasm32 have a 32-bit `Int`. `just wasi-test` (`scripts/wasi_test.py`)
builds the SwiftPM test targets with `swift build --build-tests --swift-sdk
swift-6.3.3-RELEASE_wasm` through swiftly into `.build/wasm`, then runs each binary with
`wasmtime run --dir . <binary> --testing-library swift-testing`, logs in
`.build/wasm/logs`. Needs swiftly's 6.3.3 toolchain, its WebAssembly SDK (`swift sdk list`; the
install command is in `Explore/README.md`) and `brew install wasmtime`. If the toolchain crashes
on the manifest against a newer Xcode's SDK, pass `--xcode /Applications/Xcode-26.2.0.app` (as
`EXPLORE_XCODE` does for `just explore`).

- One binary of every target passes wasmtime's limit of a million functions, so targets run in
  groups (`GRAFLUENT_WASI_TESTS` makes `Package.swift` declare only those).
- Not run on WASI: files with exit tests (no child processes; the manifest leaves them out) and
  the `*MapConcurrencyTests` (one thread, no `Thread`; `#if !os(WASI)`). On WASI a time
  limit's timer holds the thread until it expires, after the body has run, so every
  `.timeLimit` test reports its limit exceeded; the script runs tests in parallel (the timers
  overlap) and reports the issues besides those.
- A test whose literals need a 64-bit `Int` sits inside `#if _pointerBitWidth(_64)`; the catalog
  generators add that guard themselves.
- Write width-dependent bounds as comparisons on `Int64` or `Int.max`, never `1 << 32` on an
  `Int` (it is 0 at 32 bits); keep counts that grow as n² or n³ in `Int64`.

### Mutation, fuzzing and differential testing

- `just mutate X` re-runs only mutants whose code or tests changed (`--all` runs every one).
  Fix each survivor with a test, or prove it equivalent and remove it with a note in the spec
  file's header. A mutant that edits a comment survives silently; `nth=` counts comment matches.
- Each module has a fuzz target in `Fuzz/`, built with the swift.org toolchain through swiftly.
  A crash becomes a regression test.
- `just diff` compares only answers that ties cannot change and validates returned paths and
  witnesses.

### Catalogs

`Tests/Catalogs/<Module>/` holds `cases.md` (case IDs, inputs, expected values), `api.md` (the API
the tests were written against), `ref.py` (an independent Python reference model that re-checks
every row; `ref.py --write` regenerates `cases.md` where supported) and `swiftgen.py` or `gen.py`
(writes the catalog-row Swift tests). Generated test files must match the generator byte for
byte: edit the generator, regenerate, `git diff`, then run the suite. `Tests/Catalogs/README.md`
lists each catalog's scripts and Python pins (run through `uv`).

## House rules

### Library code

- No Apple private API (`@_silgen_name`, undocumented runtime entry points). Apps using it are
  rejected from the App Store.
- No hooks or SPI added only for tests.
- Use swift-atomics (`ManagedAtomicLazyReference` and so on) or the standard library's
  `Atomic`/`Mutex` for shared state. No hand-rolled atomics.
- Names come from established graph libraries or the literature, familiar programmer terms
  first and the mathematical term when no common one exists. Never invent names. No synonym
  typealiases; one name per concept. Spell names out (`StableDirectedGraph`, not a short form).
- Delete unused API rather than keeping it.
- No datasets in the library. Generators are mathematical families only.

### Tests

- Swift Testing. Each test is self-contained: no assertion or setup helpers, not DRY; a test
  copied to another file still works. Shared fixture data in `GrafluentTestSupport` is tolerated.
- Tests may call underscored and `package` API.
- Property tests use swift-property-based (`import PropertyBased`, `propertyCheck`).

### Docs

- Describe the current API. No history ("previously", "renamed"), design debates, comparisons
  with other libraries, or benchmark numbers in doc comments or READMEs. Complexity bounds are
  fine. Algorithm authors are fine when they name the algorithm.
- Doc comments: a one-line summary, then parameters, return value, complexity, and what traps or
  throws.

### Git

- Commit message style: `[main] - <summary>`, no trailers (no co-author or session lines).
- One commit per finished feature or fix, after its suites pass.
- Never file bugs with third-party projects; record them locally.

## API conventions

### Errors

- **Plain spellings trap** on a missing vertex or edge, like an `Array` subscript. They are the
  fast path.
- **`checked:` spellings throw** a typed, payload-free error: `successors(checked: v)` throws
  `VertexNotFound`; `source(checkedEdgeAt: p)` throws `EdgeNotFound`; calls that can fail either
  way throw `ElementNotFound` (`.vertex`, `.edge`). Labels such as `path(checkedFrom:to:)` or
  `distance(checkedTo:)` mark which argument is checked. There are no nil-returning variants;
  `try?` gives `nil`. These live in `GraphProtocols/MembershipErrors.swift`.
- **Invariant-breaking mutations throw on the plain spelling** and change nothing:
  `AcyclicEdgeError` (`.cycle`, `.selfLoop`, `.missingEndpoint`), `LooplessEdgeError`
  (`.selfLoop`, `.missingEndpoint`), `BipartitionError` (`.sameSide`, `.onOtherSide`,
  `.missingEndpoint`), `LabelingError`. `insert(checked:)` reports a missing endpoint as a case
  of the same error, so one typed `catch` is exhaustive. Errors carry no vertex, because a vertex
  type need not be `Sendable`.
- **Iterative solvers throw `NoConvergence`** (`iterations`, `residual`) when they spend their
  iteration limit. Invalid parameters (tolerance ≤ 0) still trap.
- **Queries whose failure is the answer return a witness**, not an error: `findCycle() ->
  Cycle?`, `findOddCycle()`, `findNegativeCycle`, `topologicalSort() -> [Vertex]?`.

### Shapes

- `Graph` (undirected) and `DirectedGraph` are separate protocols; no type conforms to both.
  `graph.directedView` and `digraph.undirectedView` convert. Refinements:
  `BidirectionalDirectedGraph` (predecessors), `SparselyIndexedDirectedGraph` and its undirected
  counterpart `SparselyIndexedGraph` (positions with holes), `MutableDirectedGraph` (mutation hooks
  for wrappers). `Hypergraph` and
  `DirectedHypergraph` are separate again.
- A graph exposes collections (`vertices`, `edges`); it is not itself a `Sequence`. An edge is
  identified by its position (`Edges.Index`), which tells parallel edges apart.
- Lazy views end in `View` (`transposedView`, `undirectedView`, `complementView`,
  `inducedSubgraphView(on:)`, `cartesianProductView`). The materialized form shares the root:
  `transposed()`. Reversing every edge is "transposed", never "reversed" (which is the
  standard library's sequence reversal).
- Results are dedicated types (`ShortestPathTree`, `Components`, `Matching`, `Flow`), not tuples.
  Walk-like results are `Walk`, `Trail`, `Path`, `Circuit`, `Cycle` (vertices plus edge positions).
- Materializing operations and generators are static factories on a target the caller picks:
  `CompressedSparseRow.complete(vertexCount: 5)`, `Target.lineGraph(of:)`.

### Weights and attached maps

- Algorithms take weights as a closure over edge positions, `weight: (Edges.Index) -> W`, called
  on demand and never stored. Shortest-path entry points also take a `SelectiveSemiring`.
- `PropertyGraph` representations own attached maps: `addEdgeMap(default:)`,
  `addVertexMap(default:)`, and `addEdgeMap(of: T.self)` for an `EdgeMap<T?>` defaulting to `nil`.
  Maps are total (every element has the default until set). Read and write with
  `graph[map, ofEdgeAt: p]` / `graph[map, of: v]`; a removed element traps there and throws from
  `graph[map, checkedEdgeAt: p]`. Every mutation keeps every map in step, swap-removes included.
- `values(of:)` is an O(1) snapshot that reads like an array; pass `{ w[$0] }` to an algorithm.
- `generation` changes with every structural mutation (map writes don't count). Derived
  structures such as `CompressedSparseRow(g)` record it (`isCurrent(for:)`).
- `GraphAdaptor` exposes `base`; maps read through an adaptor whose positions are its base's.
  `GraphDelegator` refines it for rule-adding wrappers (`Multigraph`, `DirectedMultigraph`,
  `BipartiteGraph`, `DirectedAcyclicGraph`): every read member forwards to the base by default,
  and the wrapper implements its mutations, attached-map management and map writes. The wrapped
  graph is stored in an internal `_base`, never settable from outside, so its rules cannot be
  bypassed. Views that reorient or filter must not use it.

### Performance patterns

- Public types are copy-on-write structs, `@frozen`, with `@usableFromInline` internals.
  Algorithms are `@inlinable`; parameters are `some` generics, never `any`.
- Copy-on-write: the uniqueness check is inlined and the reallocation slow path is
  `@inline(never)`. Bulk mutations check uniqueness once, outside the loop.
- Algorithms number vertices densely (`vertexIndex(of:)`) and run index-space loops over flat
  rows (`successorIndices(ofIndex:)`) and unsafe buffers; scratch storage avoids copy-on-write.
- Traps measured in this codebase: nested functions capturing mutable locals (boxed, retained per
  step); generic iterators stored in arrays (use integer cursors); reading a struct out of a class
  property (copies and retains); lazy maps capturing `self`; per-round work proportional to the
  whole graph instead of the piece. In compound conditions, test the predictable part first.
- Write overflow guards as comparisons (`x <= Int.max / 4`), not a discarded
  `multipliedReportingOverflow` result, which an optimized build has miscompiled.

## Terminology

| Grafluent | Meaning (mathematical term) |
|---|---|
| `DirectedEdge` (`source`, `target`) | Ordered pair (arc, with tail and head) |
| `UndirectedEdge` | Unordered pair; `==` and hashing are symmetric |
| self-loop, `isSelfLoop`, `hasSelfLoops` | Edge from a vertex to itself (loop) |
| `successors(of:)` / `predecessors(of:)` | Out-neighbors N⁺(v) / in-neighbors N⁻(v) |
| `neighbors(of:)` | Neighbors in an undirected graph, N(v); a self-loop is listed twice |
| `outDegree`, `inDegree`, `degree` | d⁺(v), d⁻(v), d(v); a self-loop counts 2 in `degree` |
| `vertexCount`, `edgeCount` | Order \|V\|, size \|E\| |
| `transposedView`, `transposed()` | Every edge reversed (converse, transpose) |
| `undirectedView` | Directions dropped (underlying graph) |
| `descendants(of:)`, `ancestors(of:)` | Reachable from / reaching v |
| `parent`, `children`, `root`, `depth(of:)`, `height` | Rooted-tree relations; depth counts edges to the root |
| `Arborescence` | Directed rooted tree, edges away from the root (out-tree) |
| `Branching`, `minimumSpanningArborescence` | Forest of arborescences; optimum branching / arborescence (Edmonds) |
| `SteinerTree`, `terminals:` | Tree connecting a vertex subset (Steiner tree), its required vertices |
| `bridges()`, `articulationPoints()` | Cut edges, cut vertices |
| `biconnectedComponents()` | Blocks |
| `biEdgeConnectedComponents()` | 2-edge-connected components |
| `nontrivialStronglyConnectedComponents()` | Strong components containing a cycle |
| `simpleCycles()` | Elementary circuits |
| `chordlessCycles()` | Induced cycles (no chord) |
| `minimumMeanCycle(weight:)` | Cycle of least mean weight (Karp) |
| `allSimplePaths(from:to:)` | Every path with no repeated vertex |
| `randomWalk(…returnParameter:inOutParameter:)` | node2vec's p and q |
| `lexicographicBreadthFirstSearch()`, `maximumCardinalitySearch()` | LexBFS, MCS vertex orderings |
| `isChordal`, `findHole()` | Chordal (triangulated) graph; a chordless cycle of length ≥ 4 |
| `perfectEliminationOrdering()` | Perfect elimination ordering (PEO) |
| `girth()` | Length of a shortest cycle |
| `shortestSimplePaths(from:to:)` | Simple paths in nondecreasing length; `prefix(k)` is the k shortest paths (Yen) |
| `MaxPlusSemiring`, `ViterbiSemiring` | (max, +), the arctic semiring; (max, ×) over probabilities |
| `isAcyclic` | Forest (undirected) or DAG (directed) |
| `maximalCliques()`, `maximumClique()` | Maximal / maximum cliques; clique number ω(G) |
| `coreNumbers()` | Core numbers; the greatest is the degeneracy |
| `trussNumbers()`, `kTruss(_:)` | Truss numbers (trussness); the k-truss, every edge in k − 2 triangles |
| `onionLayers()` | Onion decomposition (Hébert-Dufresne et al.) |
| `cliqueNumber(of:)` | Largest clique through a vertex (node clique number) |
| `kEdgeConnectedComponents(_:)`, `kEdgeConnectedSubgraphs(_:)` | Classes with local edge connectivity λ(u, v) ≥ k; maximal k-edge-connected induced subgraphs |
| `isDSeparator(_:between:and:)`, `moralGraph(of:)` | d-separation; the moral graph (parents married) |
| `transitivity()` | Global clustering coefficient |
| `effectiveGraphResistance()` | Kirchhoff index |
| `modularity(of:resolution:)` | Q, with resolution γ |
| `cosineSimilarity(of:and:)`, `diceCoefficient(of:and:)` | Salton index; Sørensen index (vertex-pair similarity over neighbor sets) |
| `left`, `right`, `side(of:)` | The two classes of a bipartite graph (V = L ∪ R) |
| `Matching`: maximal / maximum / perfect | Independent edge set |
| `linearSumAssignment` | Assignment problem |
| `Coloring`, `chromaticNumber()` | Proper vertex colouring, χ(G) |
| `EdgeColoring` | Proper edge colouring; fewest colours is χ′(G) |
| `subgraphIsomorphism(to:)` / `monomorphism(to:)` | Induced subgraph isomorphism / subgraph isomorphism |
| `vertexColor:`, `edgeColor:` | Classes an isomorphism must preserve |
| `optimalEditPath(to:)`, `graphEditDistance(to:)` | Least-cost edit path; graph edit distance (GED) |
| `Pseudograph` / `Multigraph` | Parallel edges with / without self-loops (directed: `Directed…`) |
| `edgeCount(between:and:)` | Multiplicity |
| `cycleBasis()` | Fundamental cycles (basis of the cycle space) |
| `chinesePostmanTour(weight:)`, `PostmanTour` | Chinese postman problem (route inspection); `duplicatedEdges` eulerize the graph |
| `dualGraph()` | Planar dual of an embedding (a vertex per face) |
| `capacity:`, `supply:` | c : E → ℝ≥0; b(v), positive sends |
| `Flow`, `Cut` | s–t flow; s–t cut (S, T) |
| `incidenceGraphView` | Bipartite incidence graph of a hypergraph (Levi graph) |
| `size(ofHyperedgeAt:)` | \|e\| |
| `sources(ofHyperedgeAt:)`, `targets(ofHyperedgeAt:)` | Tail T(e), head H(e) |
| `outHyperedges(of:)`, `inHyperedges(of:)` | Forward star FS(v), backward star BS(v) |
| `cliqueExpansion()` | 2-section |
| `bConnectedVertices(from:)`, `fConnectedVertices(to:)` | B- and F-connection (Gallo et al. 1993) |

## Representations and structures

Every representation is a copy-on-write value; `Equatable` compares vertex and edge sets (not
isomorphism, not insertion order), except `EdgeList`, whose order is part of its value.

| Type | What it is | Notes |
|---|---|---|
| `AdjacencyList<V>` | Directed, simple (self-loops allowed); out- and in-rows per vertex | O(1) expected `contains(edge:)`, `edges(from:to:)` (`edges(between:and:)` undirected) and edge removal; O(degree) vertex removal. Removals swap-remove, so positions may change. Bulk initializers lay rows out packed in slot order. `MutableDirectedGraph`, `PropertyGraph` |
| `UndirectedAdjacencyList<V>` | Undirected counterpart of `AdjacencyList` | `Graph`, `PropertyGraph` |
| `AdjacencyMatrix` | Directed on `0..<n`, n×n bit matrix | O(1) adjacency; rows are `BitSet`s; vertices appended (`appendVertex()`), never removed; edge positions are cells; edge maps are dense, n² values each |
| `CompressedSparseRow` | Directed on `0..<n`, offsets plus targets | Immutable (initializers only); edge positions `0..<m`; binary-search `contains(edge:)`; not bidirectional (use `transposed()`) |
| `EdgeList<V>` | Ordered list of directed edges | A `RandomAccessCollection`/`MutableCollection`/`RangeReplaceableCollection`; queries are O(m) scans; not a `DirectedGraph` |
| `ImplicitDirectedGraph<Row>` | Directed on `0..<n`, successors from a closure | Never stored; not `Equatable`/`Sendable`; no attached maps |
| `LabeledGraph<Label, Base>` | `Hashable` labels over `CompressedSparseRow` or `AdjacencyMatrix` | Label `i` names base vertex `i`; index-space members are the base's; positions are the base's |
| `IncidenceMatrix` / `OrientedIncidenceMatrix` | Hypergraph incidence as bit planes | `Hypergraph` / `DirectedHypergraph` |
| `UndirectedIncidenceList<V>` / `IncidenceList<V>` | Hypergraphs as incidence lists | Hyperedges may be empty or repeated |
| `DirectedAcyclicGraph<Base>` | Wrapper over any `MutableDirectedGraph` (`AdjacencyList`, `DirectedPseudograph`, `StableDirectedGraph`) | Rejects cycle-closing edges with `AcyclicEdgeError`; maintains `topologicalOrder` (Pearce–Kelly); reads are the base's |
| `Tree`, `Forest` | Undirected; connected and acyclic / acyclic | Immutable; failable initializers from unchecked input |
| `RootedTree`, `Arborescence` | Rooted tree, undirected / directed away from the root | `parent`, `children`, `depth`, `preorder`; O(1) conversion between them |
| `OrderedTree` | Rooted tree whose child order is part of its value (plane tree) | Not a graph; O(1) conversion to and from `RootedTree` and `Arborescence`; `treeEditDistance` (Zhang–Shasha) in TreeAlgorithms |
| `BinaryTree` | Rooted tree with positional left and right children | Not a graph; O(1) conversion to `OrderedTree` (left first) and `Arborescence`; `inorder`; `allBinaryTrees(vertexCount:)` (Algorithm B), `huffman(weights:)` |
| `PrefixTree<Symbol>` | `prefixTree(of:)`: the trie of some sequences | An `Arborescence<Int>` (root 0, edge into v at position v − 1), `symbol(ofEdgeAt:)`, `sequenceEnds`, `isSequenceEnd(_:)` |
| `BipartiteGraph<V>` | Undirected, simple, every edge crosses L–R | Throws `BipartitionError`; a `GraphDelegator` over `UndirectedAdjacencyList` |
| `Pseudograph<V>` / `DirectedPseudograph<V>` | Parallel edges and self-loops | `insert(edge:)` returns the new edge's position |
| `Multigraph<V>` / `DirectedMultigraph<V>` | Parallel edges, no self-loops | Throw `LooplessEdgeError`; `GraphDelegator`s of the pseudographs |
| `StableDirectedGraph<V>` | Directed pseudograph whose positions survive removals | Positions never reused; dense index bounds are `nil` while holes exist; paged storage (1024 positions a page) |
| `StableUndirectedGraph<V>` | Undirected counterpart of `StableDirectedGraph` | The same pages and positions, one incidence row per vertex in position order (a self-loop twice); `SparselyIndexedGraph` |
| `FunctionalGraph` | Out-degree exactly 1 on `0..<n` | `cycleDecomposition()` in O(n) |

Data structures: `IndexedPriorityQueue` (4-ary min-heap over `0..<indexBound` with
decrease-key; not a `Sequence`), `RadixHeap` (monotone queue over `UInt` keys, no decrease-key),
`DisjointSet` (union by size, path halving), `LinkCutTree` (Sleator–Tarjan dynamic trees over
`0..<count`: link, cut, `makeRoot`, path minimum, addition and subtraction). Bit sets come from
swift-collections' `BitCollections`.
