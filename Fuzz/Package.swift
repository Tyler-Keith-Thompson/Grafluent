// swift-tools-version: 6.3
import PackageDescription

// libFuzzer targets, in their own package so the library never depends on the fuzzer runtime.
// Xcode's toolchain does not ship libFuzzer; `just fuzz` builds these with a swift.org toolchain
// installed by swiftly. See Fuzz/README.md.

func target(_ name: String, _ modules: [String]) -> Target {
    .executableTarget(
        name: name,
        dependencies: ["FuzzSupport"] + modules.map { .product(name: $0, package: "Grafluent") }
    )
}

let package = Package(
    name: "GrafluentFuzz",
    platforms: [.macOS(.v15)],
    dependencies: [.package(path: "..")],
    targets: [
        .target(name: "FuzzSupport"),
        target("FuzzPriorityQueue", ["PriorityQueueModule"]),
        target("FuzzDisjointSet", ["DisjointSetModule"]),
        target("FuzzAdjacencyList", ["GraphProtocols", "AdjacencyListModule"]),
        target("FuzzUndirectedAdjacencyList", ["GraphProtocols", "AdjacencyListModule"]),
        target("FuzzSpanningTrees", ["GraphProtocols", "AdjacencyListModule", "SpanningTrees"]),
        target("FuzzUndirectedConnectivity", ["GraphProtocols", "AdjacencyListModule", "Connectivity"]),
        target("FuzzWalks", ["GraphProtocols", "Walks"]),
        target("FuzzCentrality", ["GraphProtocols", "AdjacencyListModule", "Centrality"]),
        target("FuzzCommunityDetection", ["GraphProtocols", "AdjacencyListModule", "CommunityDetection"]),
        target("FuzzBipartiteGraphs", ["GraphProtocols", "AdjacencyListModule", "BipartiteGraphs", "Walks"]),
        target("FuzzMatching", ["GraphProtocols", "AdjacencyListModule", "BipartiteGraphs", "MatchingModule"]),
        target("FuzzCovering", ["GraphProtocols", "BipartiteGraphs", "MatchingModule", "Covering"]),
        target("FuzzColoring", ["GraphProtocols", "AdjacencyListModule", "ColoringModule"]),
        target("FuzzMultigraphs", ["GraphProtocols", "Multigraphs"]),
        target("FuzzCliques", ["GraphProtocols", "AdjacencyListModule", "Cliques"]),
        target("FuzzFlows", ["GraphProtocols", "Multigraphs", "Flows"]),
        target("FuzzTours", ["GraphProtocols", "Multigraphs", "CompressedSparseRowModule", "Tours", "Walks"]),
        target("FuzzDistances", ["GraphProtocols", "AdjacencyListModule", "Distances", "Walks"]),
        target("FuzzTreeAlgorithms", ["GraphProtocols", "Trees", "TreeAlgorithms", "Walks"]),
        target("FuzzTrees", ["GraphProtocols", "AdjacencyListModule", "Trees", "Walks"]),
        target("FuzzCycles", ["GraphProtocols", "AdjacencyListModule", "Cycles", "Walks"]),
        target("FuzzShortestPaths", ["GraphProtocols", "AdjacencyListModule", "CompressedSparseRowModule", "ShortestPaths", "Walks"]),
        target("FuzzStableGraphs", ["GraphProtocols", "StableGraphs", "Multigraphs", "Traversal", "Connectivity", "ShortestPaths"]),
        target("FuzzLabeledGraphs", ["GraphProtocols", "LabeledGraphs", "CompressedSparseRowModule", "AdjacencyMatrixModule", "AdjacencyListModule", "Multigraphs", "Traversal", "Connectivity", "ShortestPaths"]),
        target("FuzzGenerators", ["GraphProtocols", "NamedGraphs", "RandomGraphs", "AdjacencyListModule", "AdjacencyMatrixModule", "CompressedSparseRowModule", "Multigraphs", "StableGraphs", "Trees", "BipartiteGraphs", "DirectedAcyclicGraphModule"]),
        target("FuzzFunctionalGraphs", ["GraphProtocols", "FunctionalGraphs", "ImplicitGraphs", "Multigraphs", "Traversal", "Connectivity", "ShortestPaths"]),
        target("FuzzDirectedAcyclicGraph", ["GraphProtocols", "DirectedAcyclicGraphModule", "AdjacencyListModule", "Multigraphs", "StableGraphs", "Traversal", "Walks"]),
        target("FuzzHypergraphs", ["GraphProtocols", "Hypergraphs", "IncidenceMatrixModule", "AdjacencyListModule", "Connectivity"]),
        target("FuzzIsomorphism", ["GraphProtocols", "IsomorphismModule", "Multigraphs"]),
        target("FuzzSemirings", ["GraphProtocols", "Semirings", "ShortestPaths", "Multigraphs", "AdjacencyListModule", "DirectedAcyclicGraphModule", "Walks"]),
        target("FuzzGraphDrawing", ["GraphProtocols", "GraphDrawing", "Multigraphs", "Trees", "Cycles"]),
    ]
)
