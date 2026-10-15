# Explore

Interactive pages that run Grafluent itself in the browser: each builds a small graph with the
result builder, runs the real algorithm on it, and draws what happened. The interface is written
with [ElementaryUI](https://github.com/elementary-swift/elementary-ui) and compiled with the rest
to WebAssembly. The published site is at <https://tyler-keith-thompson.github.io/Grafluent/explore/>.

This is a separate SwiftPM package; Bazel ignores it.

## Pages

`web/contents.txt` is the reading order. Each `page` row has a page; `soon` rows are listed in the
contents and the menu without a link.

| Page | Runs |
|---|---|
| `basics` | `neighbors(of:)`, `successors(of:)`, `predecessors(of:)`; beside its figures, `dijkstraShortestPaths`, `Walk`, `Path`, `Cycle`, `Pseudograph`, `Multigraph` |
| `representations` | `AdjacencyList`, `LabeledGraph<_, AdjacencyMatrix>`, `LabeledGraph<_, CompressedSparseRow>` |
| `bfs` | `lazy.breadthFirstSearch(from:)` |
| `dfs` | `lazy.depthFirstSearch(from:)` |
| `dijkstra` | `lazy.dijkstra(from:weight:)`, `dijkstraShortestPaths(from:weight:)`; beside its figure, `bellmanFordShortestPaths` |
| `astar` | `lazy.aStar(from:to:weight:heuristic:)`, `aStarShortestPath(from:to:weight:heuristic:)`, `lazy.dijkstra(from:weight:)` |
| `bellmanford` | `lazy.bellmanFord(from:weight:)` |
| `kpaths` | `shortestSimplePaths(from:to:weight:)`, `prefix(_:)` |
| `semirings` | `dijkstraShortestPaths(from:weight:)` over `TropicalSemiring`, `BottleneckSemiring`, `ViterbiSemiring`, `BooleanSemiring`; `dagShortestDistances(from:weight:)` over `CountingSemiring`; `topologicalSort()` |
| `toposort` | `lazy.depthFirstSearch()`, `topologicalSort()`, `topologicalGenerations()`, `findCycle()` |
| `criticalpath` | `DirectedAcyclicGraph`, `lazy.kahn()`, `longestPath(weight:)`, `Path.weight(_:)` |
| `cyclefinding` | `FunctionalGraph(successors:)`, `lazy.floydCycleDetection(from:)`, `lazy.brentCycleDetection(from:)` |
| `components` | `connectedComponents()`, `lazy.breadthFirstSearch(from:)`, `stronglyConnectedComponents()`, `condensation()`, `lazy.depthFirstSearch()` |
| `bridges` | `bridges()`, `articulationPoints()`, `lazy.edgeDepthFirstSearch(from:)`, `connectedComponents()`; beside its figure, `biconnectedComponents()` |
| `dominators` | `dominatorTree(root:)`, `postDominatorTree(exit:)`, `dominators(of:)`, `immediateDominator(of:)`, `children(of:)`, `lazy.breadthFirstSearch(from:)` |
| `euler` | `degree(of:)`, `eulerianCircuit()`, `eulerianTrail()`, `incidentEdges(of:)` on a `Multigraph`; beside its figure, `hasEulerianTrail` |
| `postman` | `chinesePostmanTour(weight:)`, `PostmanTour`, `degree(of:)`, `dijkstraShortestPaths(from:weight:)` |
| `tsp` | `nearestNeighborTour(from:weight:)`, `twoOptTour(improving:weight:)`, `simulatedAnnealingTour(improving:weight:using:)`, `christofidesTour(weight:)`, `shortestTour(weight:)`, `Cycle.weight(_:)` |
| `hamiltonian` | `hamiltonianCycle()`, `hamiltonianPath(from:to:)`, `neighbors(of:)` |
| `mst` | `lazy.kruskal(weight:)`, `lazy.prim(from:weight:)`, `kruskalMinimumSpanningTree(weight:)`, `primMinimumSpanningTree(from:weight:)` |
| `huffman` | `BinaryTree.huffman(weights:)`, `parent(of:)`, `left(of:)`, `depth(of:)`, `inorder` |
| `lca` | `RootedTree`, `depth(of:)`, `parent(of:)`, `lowestCommonAncestor(of:_:)`, `LowestCommonAncestors`, `distance(from:to:)` |
| `prefixtree` | `prefixTree(of:)`, `children(of:)`, `isAncestor(_:of:)`, `isSequenceEnd(_:)`, `sequenceEnds` |
| `giant` | `erdosRenyi(vertexCount:edgeCount:using:)` with `Xoshiro256StarStar`, `connectedComponents()`, `fruchtermanReingoldLayout(iterations:weight:using:)` |
| `networkmodels` | `barabasiAlbert(vertexCount:edgesPerVertex:using:)`, `wattsStrogatz(vertexCount:nearestNeighborCount:rewiringProbability:using:)`, `averageClustering()`, `floydWarshallShortestPaths(weight:)`, `fruchtermanReingoldLayout` |
| `planarity` | `isPlanar`, `findKuratowskiSubgraph()`, `planarLayout()`, `planarEmbedding()` |
| `cliques` | `lazy.bronKerbosch()`, `maximalCliques()`, `maximumClique()` |
| `cores` | `coreNumbers()`, `kCore(_:)`, `degeneracy`, `trussNumbers()`, `kTruss(_:)`, `onionLayers()`, `layer(of:)` |
| `chordal` | `isChordal`, `perfectEliminationOrdering()`, `findHole()`, `maximumCardinalitySearch()`, `lexicographicBreadthFirstSearch()` |
| `isomorphism` | `weisfeilerLehmanGraphHash()`, `weisfeilerLehmanSubgraphHashes(iterations:)`, `isomorphism(to:)` |
| `communities` | `lazy.louvain()`, `louvainCommunities()`, `modularity(of:)` |
| `girvannewman` | `girvanNewmanCommunities()`, `edgeBetweennessCentrality(normalized:)`, `connectedComponents()`, `modularity(of:)` |
| `labelpropagation` | `asynchronousLabelPropagationCommunities()`, `labelPropagationCommunities()`, `asynchronousLabelPropagationCommunities(using:)` with `Xoshiro256StarStar`, `modularity(of:)`, `neighbors(of:)` |
| `flow` | `lazy.edmondsKarp(from:to:capacity:)`, `edmondsKarpMaximumFlow(from:to:capacity:)`, `minimumCut` |
| `mincut` | `minimumCut(capacity:)`, `gomoryHuTree(capacity:)`, `minimumCut(between:and:)` |
| `mincostflow` | `minimumCostFlow(supply:capacity:cost:)` |
| `matching` | `bipartition(left:)`, `maximumBipartiteMatching(bipartition:)` |
| `stablematching` | `galeShapley(proposerPreferences:reviewerPreferences:)`, `stableMatching(proposerPreferences:reviewerPreferences:)` |
| `coloring` | `greedyColoring(order:)`, `greedyColoring(strategy:)`, `chromaticNumber()`, `minimumColoring()` |
| `edgecoloring` | `edgeColoring()`, `colorClasses`, `isEdgeColoring(_:)` |
| `covering` | `minimumVertexCover()`, `lexicographicallyFirstMinimumVertexCover()`, `approximateMinimumVertexCover()`, `isVertexCover(_:)`, `minimumDominatingSet()`, `lexicographicallyFirstMinimumDominatingSet()`, `approximateMinimumDominatingSet()`, `isDominatingSet(_:)` |
| `pagerank` | `pageRank(dampingFactor:maxIterations:)`, `randomWalk(from:length:using:)` |
| `betweenness` | `betweennessCentrality(normalized:)`, `edgeBetweennessCentrality(normalized:)`, `shortestSimplePaths(from:to:)` |
| `linkprediction` | `jaccardCoefficient(of:and:)`, `adamicAdarIndex(of:and:)` |
| `layout` | `FruchtermanReingoldLayout(_:iterations:using:)` with `Xoshiro256StarStar`, `step()`, named graphs |
| `spectral` | `spectralLayout()`, `fiedlerVector()`, `algebraicConnectivity`, `value(of:)`, `spectralOrdering()` |
| `layered` | `sugiyamaLayout()`, `LayeredDrawing` (`layer(of:)`, `bends(ofEdgeAt:)`, `reversedEdges`, `crossingCount`), `RootedTree`, `reingoldTilfordLayout()`, `reingoldTilfordCircularLayout()` |

## Requirements

- [swiftly](https://www.swift.org/install/) with the Swift 6.3.3 toolchain:
  `swiftly install 6.3.3`.
- The matching Swift SDK for WebAssembly from swift.org:

  ```sh
  swiftly run swift sdk install \
      https://download.swift.org/swift-6.3.3-release/wasm-sdk/swift-6.3.3-RELEASE/swift-6.3.3-RELEASE_wasm.artifactbundle.tar.gz \
      --checksum cabfa08b73bb8ac783927ecd15fa386e99d0c139c5f232445067bcf58379cae7 +6.3.3
  ```

- `wasm-opt` from binaryen (`brew install binaryen`) to optimize the binary. The build still
  works without it, with a larger `.wasm`.

Without swiftly, `build.sh` uses the `swift` on `PATH`, which must be 6.3.3 (CI does this in the
`swift:6.3.3` container).

## Build

```sh
just explore
```

This builds release WebAssembly at `-Osize`, strips it, runs `wasm-opt -Oz`, draws each page's
first frame into its HTML (see below), and writes `Explore/dist/`: one `<page>.html` per page and `index.html`, `explore.css`, `Explore.wasm`, the
JavaScriptKit glue (`index.js`, `instantiate.js`, `runtime.js`, `bridge-js.js`,
`platforms/browser.js`) and the vendored WASI shim (`vendor/browser_wasi_shim/`). Every URL is
relative, so `dist/` works from any directory, such as `/Grafluent/explore/` on GitHub Pages.
Nothing is loaded from another host except the Google Fonts stylesheet.

If the swift.org toolchain crashes compiling a package manifest against a newer Xcode's macOS SDK,
point the build at an older Xcode: `EXPLORE_XCODE=/Applications/Xcode-26.2.0.app just explore`.
`GRAFLUENT_EXPLORE_SWIFT` and `GRAFLUENT_EXPLORE_SDK` choose another toolchain version and SDK.

## Serve

```sh
cd Explore/dist && python3 -m http.server 8000
```

Then open <http://localhost:8000/>. The pages must be served over HTTP; browsers do not load
WebAssembly modules from `file://` URLs.

## First frames

Each page's HTML already holds its first frame: the graph, the side panels, the timeline and the
code panels with their results, as they are before anyone touches a control. `build.sh` builds
this package a second time for the build machine (a debug build, about a minute the first time
and seconds after), and run there, `main.swift` renders every mount point of every page to HTML
with the same views, through Elementary's HTML rendering, and fills it into `dist/<page>.html`.
In the browser, `mountView` empties each mount point and ElementaryUI mounts the live view in its
place, in the same task, so nothing moves. Until then each mount point carries `data-loading`,
and its controls take no pointer and pulse.

So the first frame matches what the browser mounts, a page's initial state must not depend on
the platform: no iteration over a `Dictionary` or `Set` (hash order changes on every run), and
random draws through `next()` rather than `Int.random` or `randomElement`, which differ between
64-bit and 32-bit `Int`. Pages that draw at random (the giant component, the layout page) seed a
`Xoshiro256StarStar`, so the build machine and the browser draw the same start. ElementaryUI renders its event handlers only
into a live DOM; `FirstFrames.swift` gives the elements stand-ins that drop them on the build
machine.

## One WebAssembly module for the whole site

Every page loads the same `Explore.wasm`; `<body data-page="…">` tells `main.swift` which views to
mount. Most of the module is the Swift runtime, ElementaryUI and JavaScriptKit, which every page
needs, so one module per page would repeat them:

| | Raw | gzip -9 |
|---|---|---|
| The whole site, one module | 8.4 MB | 3.0 MB |
| The Dijkstra page alone | 6.7 MB | 2.4 MB |

With one module the browser downloads and compiles it once and every later page reuses it from the
cache. The index page loads no WebAssembly.

## Layout

| Path | Holds |
|---|---|
| `Sources/Explore/main.swift` | Mounts the page named by `data-page`; on the build machine, writes the first frames |
| `Sources/Explore/Shared/` | `mountView` (`Mount.swift`) and the first-frame writer (`FirstFrames.swift`), `GraphCanvas`, `Timeline` and `Marble`, `Playback` and `PlaybackButtons`, `CodePanel` and `Snippet`, `NamesStrip` and the `Names` pronunciations, DOM event glue |
| `Sources/Explore/Pages/<Page>/<Page>Code.swift` | The Grafluent code the page runs, with its `// snippet:` regions |
| `Sources/Explore/Pages/<Page>/<Page>Page.swift` | The page's model (`@Reactive`) and views |
| `Sources/Explore/Figures/` | The samples beside the static figures in the pages' prose, mounted on `<pre class="figcode" id="fig-…">` |
| `Sources/SnippetExtractor/`, `Plugins/Snippets/` | The build plugin that turns `// snippet:` regions into `Snippet` constants |
| `web/template.html` | The shell every page is poured into: head, top bar and menu, pager, loader |
| `web/pages/<page>.html` | A page's masthead and prose, with `#app`, `#code` and `#names` mount points |
| `web/contents.txt` | Reading order, groups and summaries: the index, the menu and previous/next links |
| `web/explore.css` | The one stylesheet, light and dark |
| `build.sh` | What `just explore` runs |

### The code panel is the code that runs

A page's Grafluent code lives in `<Page>Code.swift` between `// snippet: name` and
`// snippet end` lines. The Snippets plugin copies each region, dedented, into a constant
(`snippet: dijkstra-walk` becomes `Snippet.dijkstraWalk`), and the page passes those constants to
`CodePanel`. So the displayed text is the compiled text, and a snippet that stops compiling stops
the build. A line ending in `// →` gets a result the page computed, in order. The values a page
passes in (the start vertex, the edges someone drew) are shown as `let` lines in a `Snippet` the
page builds: they bind the names the snippets use.

## Adding a page

For a stepper such as `lazy.kruskal`, `lazy.prim`, `lazy.aStar` or `lazy.bronKerbosch`:

1. Add the module to the `Explore` target's dependencies in `Package.swift` if it is not there.
2. `Sources/Explore/Pages/MST/MSTCode.swift`: the example graph and a function that collects the
   stepper's events into an array, each inside `// snippet:` regions, as in `DijkstraCode.swift`.
3. `Sources/Explore/Pages/MST/MSTPage.swift`: a `@Reactive` model holding the events and a
   `Playback` (`playback.reset(count:)` after each run); a view that reads `playback.k` and draws
   the state after that many events with `GraphCanvas`, `PlaybackButtons` and a `Timeline` of one
   `Marble` per event; a `CodePanel` view; and `enum MSTPage { static func mount() }` mounting
   them with `mountView` on `app`, `code` and `names`. `DijkstraPage.swift` is the model to copy.
4. Pronunciations go in `Shared/Pronunciations.swift` (`Names.kruskal` and others are there).
5. `web/pages/mst.html`: the title and description comments, the masthead with its "Say it", the
   example, `<div id="app">`, and the prose with `<pre id="code">` and `<div id="names">`.
6. In `web/contents.txt`, change the row's status from `soon` to `page`; add a `case "mst":` to
   `main.swift`.

Every algorithm page has the playback buttons, the scrubber and the marble timeline, and every
graph drawn on a page has the Swift that builds it beside it: the page's `CodePanel` for the live
graph, and for a static figure in the prose a `<pre class="figcode" id="fig-…">` filled from a
`// snippet:` region in `Sources/Explore/Figures/FigureCode.swift` (add its line to
`mountFigureSamples()` in `Figures.swift`).

`just explore`, then check the page loads with no console errors, works at 400 px wide, and reads
in both themes.

## Versions

- ElementaryUI 0.7.0 (with Elementary 0.8.2), the newest release that builds with Swift 6.3;
  0.8.0 needs Swift 6.4.
- JavaScriptKit 0.58.0, the version ElementaryUI 0.7.0 allows.
- swift-collections 1.6, which ElementaryUI 0.7.0 was written against.
- `@bjorn3/browser_wasi_shim` 0.3.0, the version JavaScriptKit's packager targets.
- binaryen `version_133` in CI.

The app uses the full WebAssembly SDK, not the Embedded Swift one: Grafluent uses existential
types, which Embedded Swift does not support.
