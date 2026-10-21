# Grafluent

Grafluent is a generic graph library for Swift. It provides graph representations as value
types, graph classes that enforce their invariants, and a broad set of graph algorithms, from
shortest paths and connectivity to flows, matching, isomorphism and layout.

[Documentation](https://tyler-keith-thompson.github.io/Grafluent/documentation/) ·
[Explore](https://tyler-keith-thompson.github.io/Grafluent/explore/)

## Explore graph algorithms

[Explore Grafluent](https://tyler-keith-thompson.github.io/Grafluent/explore/) is a set of
interactive pages that run the library in your browser, compiled to WebAssembly. Each page takes
one algorithm, such as breadth-first search, Dijkstra, A*, minimum spanning trees or PageRank, and
lets you step through it on a small example you can edit, beside the Swift code that runs it.

## Why Grafluent

- **Value semantics.** Every graph is a copy-on-write struct. `let` graphs are immutable, copies
  are cheap, and stored graphs are `Sendable` when their vertex type is.
- **Generic vertices.** Use any `Hashable` type as a vertex, or dense `Int` vertices with
  index-based representations such as `CompressedSparseRow` and `AdjacencyMatrix`.
- **Fast generic code.** Algorithms are `@inlinable` generics over small protocols, and public
  storage is `@frozen`, so each call specializes for the concrete graph and weight types.
- **Invariants in types.** A `DirectedAcyclicGraph` rejects an edge that would close a cycle, a
  `BipartiteGraph` rejects an edge inside one side, and a `Tree` is always connected and acyclic.
- **Typed errors.** Lookups trap on a missing vertex, like an `Array` subscript. Their `checked:`
  spellings throw a typed `VertexNotFound` instead. Rejected mutations throw
  typed errors you can match exhaustively.
- **Modular.** `import Grafluent` brings in everything. Each module is also its own product, so
  you can depend on only what you use.

## Installation

Grafluent requires Swift 6.3 and supports macOS 15, iOS 18, tvOS 18, watchOS 11 and visionOS 2
or later.

Add the package to `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/Tyler-Keith-Thompson/Grafluent", from: "0.0.1"),
],
```

Then add a product to your target, either the umbrella or individual modules:

```swift
.target(name: "MyApp", dependencies: [
    .product(name: "Grafluent", package: "Grafluent"),
    // or, for example:
    // .product(name: "AdjacencyListModule", package: "Grafluent"),
    // .product(name: "ShortestPaths", package: "Grafluent"),
]),
```

## Usage

Build a graph with the result builder, then mutate it and sort it topologically:

```swift
import Grafluent

let steps = ["fetch", "compile", "test", "package"]
var build = AdjacencyList<String> {
    for (step, next) in zip(steps, steps.dropFirst()) {
        DirectedEdge(from: step, to: next)
    }
    DirectedEdge(from: "compile", to: "package")
}
build.insert(edge: DirectedEdge(from: "package", to: "publish"))

let next = Array(build.successors(of: "compile"))  // ["test", "package"]
let order = build.topologicalSort()                // ["fetch", "compile", "test", "package", "publish"]
```

Find the connected components of an undirected graph:

```swift
let friends = UndirectedAdjacencyList<String> {
    UndirectedEdge("ana", "ben")
    UndirectedEdge("ben", "cy")
    UndirectedEdge("dee", "eli")
    "fay"  // a vertex with no edges
}
let groups = friends.connectedComponents()

let groupCount = groups.count                                             // 3
let together = groups.component(of: "ana") == groups.component(of: "cy")  // true
```

Keep edge weights in a map attached to the graph, and pass them to an algorithm as a closure over
edge positions. The graph keeps its maps in step when edges and vertices are removed.

```swift
var roads = DirectedPseudograph<String>()
let miles = roads.addEdgeMap(default: 0)
for (from, to, length) in [("A", "B", 4), ("B", "C", 3), ("A", "C", 9)] {
    let edge = roads.insert(edge: DirectedEdge(from: from, to: to))
    roads[miles, ofEdgeAt: edge] = length
}

let lengths = roads.values(of: miles)
let routes = roads.dijkstraShortestPaths(from: "A", weight: { lengths[$0] })
let distance = routes.distance(to: "C")           // 7
let stops = routes.path(to: "C").map(Array.init)  // ["A", "B", "C"]
```

Handle rejected mutations and missing vertices with typed errors:

```swift
var plan = DirectedAcyclicGraph<AdjacencyList<String>>()
try plan.insert(edge: DirectedEdge(from: "design", to: "build"))
try plan.insert(edge: DirectedEdge(from: "build", to: "ship"))

do {
    try plan.insert(edge: DirectedEdge(from: "ship", to: "design"))
} catch .cycle {
    // Rejected. The graph is unchanged.
} catch {
    // .selfLoop or .missingEndpoint
}

let edgeCount = plan.edgeCount                         // 2
let missing = try? plan.successors(checked: "launch")  // nil: "launch" is not a vertex
```

Generate a graph from a named family and measure it:

```swift
let grid = UndirectedAdjacencyList<Int>.grid(dimensions: [3, 4])
let vertexCount = grid.vertexCount  // 12
let diameter = grid.diameter()      // 5
```

The full API reference is the [DocC documentation](https://tyler-keith-thompson.github.io/Grafluent/documentation/), with a page for each module.

## Modules

| Group | Modules |
|---|---|
| Vocabulary | `GraphProtocols` (protocols, edges, builders, errors), `Walks`, `Semirings` |
| Data structures | `PriorityQueueModule`, `DisjointSetModule`, `LinkCutTreeModule` |
| Representations | `AdjacencyListModule`, `AdjacencyMatrixModule`, `IncidenceMatrixModule`, `CompressedSparseRowModule`, `PackedCompressedSparseRowModule`, `EdgeListModule`, `ImplicitGraphs`, `LabeledGraphs` |
| Structures | `DirectedAcyclicGraphModule`, `Trees`, `BipartiteGraphs`, `Multigraphs`, `StableGraphs`, `Hypergraphs`, `FunctionalGraphs` |
| Operations | `GraphOperations` (views, subgraphs, ego graphs, condensation, line graphs, set operations, powers, contraction, relabeling, transitive closure), `GraphProducts` |
| Algorithms | `Traversal`, `ShortestPaths`, `SpanningTrees`, `Connectivity`, `Cycles`, `Tours`, `Flows`, `MatchingModule`, `ColoringModule`, `Cliques`, `Covering`, `Centrality`, `CommunityDetection`, `IsomorphismModule`, `Planarity`, `TreeAlgorithms`, `Distances`, `SpectralGraphTheory`, `Assortativity`, `Similarity` |
| Generators | `NamedGraphs`, `RandomGraphs` |
| Drawing and formats | `GraphDrawing` (layout coordinates), `GraphFormats` (DOT, GraphML, GEXF, GML, LEDA, node-link and Cytoscape JSON, Pajek, graph6/sparse6/digraph6, DIMACS, METIS, Matrix Market, edge and adjacency lists, Mermaid) |

## Building and testing

Development builds use [Bazel](https://bazel.build) through [just](https://github.com/casey/just).
SwiftPM builds the same targets.

| Command | Does |
|---|---|
| `just build` | Build every target |
| `just test` | Run every test in debug |
| `just test-one //Tests/ShortestPathsTests` | Run one test target |
| `just test-release` | Run the performance tests in an optimized build |
| `just spm-test` | Run the tests through SwiftPM |
| `just verify` | Run the tests with both Bazel and SwiftPM |
| `just docs` | Build the DocC site into `.build/docs` |
| `just bench` | Run the benchmarks in `Benchmarks/` |
| `just explore` | Build the browser explorer in `Explore/` as WebAssembly |

`Package.swift` and every `BUILD.bazel` are generated from `scripts/modules.py`. Edit the module
table there and run `just modules`.

## License

MIT. See [LICENSE](LICENSE).
