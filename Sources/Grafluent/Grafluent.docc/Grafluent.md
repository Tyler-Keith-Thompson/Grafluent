# ``Grafluent``

A generic, high-performance graph library for Swift.

## Overview

Grafluent provides graph representations as copy-on-write value types, graph classes that
enforce their invariants, and generic algorithms that specialize for the concrete graph and weight
types they run on. Vertices can be any `Hashable` type. Lookups trap on a missing vertex, and
their `checked:` spellings throw a typed `VertexNotFound` instead.

`import Grafluent` imports every module. Each module also has its own documentation and can be
imported on its own.

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

### Modules

- **Vocabulary:** `GraphProtocols`, `Walks`, `Semirings`
- **Data structures:** `PriorityQueueModule`, `DisjointSetModule`
- **Representations:** `AdjacencyListModule`, `AdjacencyMatrixModule`, `IncidenceMatrixModule`,
  `CompressedSparseRowModule`, `PackedCompressedSparseRowModule`, `EdgeListModule`, `ImplicitGraphs`, `LabeledGraphs`
- **Structures:** `DirectedAcyclicGraphModule`, `Trees`, `BipartiteGraphs`, `Multigraphs`,
  `StableGraphs`, `Hypergraphs`, `FunctionalGraphs`
- **Operations:** `GraphOperations`, `GraphProducts`
- **Algorithms:** `Traversal`, `ShortestPaths`, `SpanningTrees`, `Connectivity`, `Cycles`, `Tours`,
  `Flows`, `MatchingModule`, `ColoringModule`, `Cliques`, `Covering`, `Centrality`,
  `CommunityDetection`, `IsomorphismModule`, `Planarity`, `TreeAlgorithms`, `Distances`,
  `SpectralGraphTheory`, `Assortativity`, `Similarity`
- **Generators:** `NamedGraphs`, `RandomGraphs`
- **Drawing and formats:** `GraphDrawing`, `GraphFormats`

## Topics

### Extensions

- <doc:Extensions>
