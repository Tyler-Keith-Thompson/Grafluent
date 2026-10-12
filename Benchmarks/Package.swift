// swift-tools-version: 6.3
import PackageDescription

// Benchmarks live in their own package so the library and its tests never depend on the
// benchmark framework. Run them with `just bench`; see Benchmarks/README.md.

let representation = ["AdjacencyList", "AdjacencyMatrix", "CompressedSparseRow", "EdgeList"]

let package = Package(
    name: "GrafluentBenchmarks",
    platforms: [.macOS(.v15)],
    dependencies: [
        .package(path: ".."),
        .package(url: "https://github.com/ordo-one/benchmark", from: "1.27.0"),
        .package(url: "https://github.com/apple/swift-collections", from: "1.3.0"),
    ],
    targets: [
        .target(name: "BenchmarkSupport", dependencies: [.product(name: "GraphProtocols", package: "Grafluent")]),
        .executableTarget(
            name: "TraversalBenchmarks",
            dependencies: [
                "BenchmarkSupport",
                .product(name: "Benchmark", package: "benchmark"),
                .product(name: "GraphProtocols", package: "Grafluent"),
                .product(name: "Traversal", package: "Grafluent"),
            ] + representation.map { .product(name: "\($0)Module", package: "Grafluent") },
            path: "Benchmarks/TraversalBenchmarks",
            plugins: [.plugin(name: "BenchmarkPlugin", package: "benchmark")]
        ),
        .executableTarget(
            name: "ConnectivityBenchmarks",
            dependencies: [
                "BenchmarkSupport",
                .product(name: "Benchmark", package: "benchmark"),
                .product(name: "GraphProtocols", package: "Grafluent"),
                .product(name: "Connectivity", package: "Grafluent"),
            ] + representation.map { .product(name: "\($0)Module", package: "Grafluent") },
            path: "Benchmarks/ConnectivityBenchmarks",
            plugins: [.plugin(name: "BenchmarkPlugin", package: "benchmark")]
        ),
        .executableTarget(
            name: "DisjointSetBenchmarks",
            dependencies: [
                "BenchmarkSupport",
                .product(name: "Benchmark", package: "benchmark"),
                .product(name: "GraphProtocols", package: "Grafluent"),
                .product(name: "DisjointSetModule", package: "Grafluent"),
                .product(name: "Connectivity", package: "Grafluent"),
                .product(name: "CompressedSparseRowModule", package: "Grafluent"),
            ],
            path: "Benchmarks/DisjointSetBenchmarks",
            plugins: [.plugin(name: "BenchmarkPlugin", package: "benchmark")]
        ),
        .executableTarget(
            name: "UndirectedAdjacencyListBenchmarks",
            dependencies: [
                "BenchmarkSupport",
                .product(name: "Benchmark", package: "benchmark"),
                .product(name: "GraphProtocols", package: "Grafluent"),
                .product(name: "AdjacencyListModule", package: "Grafluent"),
                .product(name: "Traversal", package: "Grafluent"),
            ],
            path: "Benchmarks/UndirectedAdjacencyListBenchmarks",
            plugins: [.plugin(name: "BenchmarkPlugin", package: "benchmark")]
        ),
        .executableTarget(
            name: "PriorityQueueBenchmarks",
            dependencies: [
                "BenchmarkSupport",
                .product(name: "Benchmark", package: "benchmark"),
                .product(name: "GraphProtocols", package: "Grafluent"),
                .product(name: "PriorityQueueModule", package: "Grafluent"),
                .product(name: "CompressedSparseRowModule", package: "Grafluent"),
                .product(name: "HeapModule", package: "swift-collections"),
            ],
            path: "Benchmarks/PriorityQueueBenchmarks",
            plugins: [.plugin(name: "BenchmarkPlugin", package: "benchmark")]
        ),
        .executableTarget(
            name: "SemiringsBenchmarks",
            dependencies: [
                "BenchmarkSupport",
                .product(name: "Benchmark", package: "benchmark"),
                .product(name: "GraphProtocols", package: "Grafluent"),
                .product(name: "Semirings", package: "Grafluent"),
                .product(name: "ShortestPaths", package: "Grafluent"),
                .product(name: "CompressedSparseRowModule", package: "Grafluent"),
            ],
            path: "Benchmarks/SemiringsBenchmarks",
            plugins: [.plugin(name: "BenchmarkPlugin", package: "benchmark")]
        ),
        .executableTarget(
            name: "ShortestPathsBenchmarks",
            dependencies: [
                "BenchmarkSupport",
                .product(name: "Benchmark", package: "benchmark"),
                .product(name: "GraphProtocols", package: "Grafluent"),
                .product(name: "ShortestPaths", package: "Grafluent"),
                .product(name: "AdjacencyListModule", package: "Grafluent"),
                .product(name: "CompressedSparseRowModule", package: "Grafluent"),
            ],
            path: "Benchmarks/ShortestPathsBenchmarks",
            plugins: [.plugin(name: "BenchmarkPlugin", package: "benchmark")]
        ),
        .executableTarget(
            name: "CentralityBenchmarks",
            dependencies: [
                "BenchmarkSupport",
                .product(name: "Benchmark", package: "benchmark"),
                .product(name: "GraphProtocols", package: "Grafluent"),
                .product(name: "Centrality", package: "Grafluent"),
                .product(name: "AdjacencyListModule", package: "Grafluent"),
            ],
            path: "Benchmarks/CentralityBenchmarks",
            plugins: [.plugin(name: "BenchmarkPlugin", package: "benchmark")]
        ),
        .executableTarget(
            name: "CommunityDetectionBenchmarks",
            dependencies: [
                "BenchmarkSupport",
                .product(name: "Benchmark", package: "benchmark"),
                .product(name: "GraphProtocols", package: "Grafluent"),
                .product(name: "CommunityDetection", package: "Grafluent"),
                .product(name: "AdjacencyListModule", package: "Grafluent"),
            ],
            path: "Benchmarks/CommunityDetectionBenchmarks",
            plugins: [.plugin(name: "BenchmarkPlugin", package: "benchmark")]
        ),
        .executableTarget(
            name: "BipartiteGraphsBenchmarks",
            dependencies: [
                "BenchmarkSupport",
                .product(name: "Benchmark", package: "benchmark"),
                .product(name: "GraphProtocols", package: "Grafluent"),
                .product(name: "BipartiteGraphs", package: "Grafluent"),
                .product(name: "AdjacencyListModule", package: "Grafluent"),
            ],
            path: "Benchmarks/BipartiteGraphsBenchmarks",
            plugins: [.plugin(name: "BenchmarkPlugin", package: "benchmark")]
        ),
        .executableTarget(
            name: "PlanarityBenchmarks",
            dependencies: [
                "BenchmarkSupport",
                .product(name: "Benchmark", package: "benchmark"),
                .product(name: "GraphProtocols", package: "Grafluent"),
                .product(name: "Planarity", package: "Grafluent"),
                .product(name: "AdjacencyListModule", package: "Grafluent"),
            ],
            path: "Benchmarks/PlanarityBenchmarks",
            plugins: [.plugin(name: "BenchmarkPlugin", package: "benchmark")]
        ),
        .executableTarget(
            name: "IsomorphismBenchmarks",
            dependencies: [
                "BenchmarkSupport",
                .product(name: "Benchmark", package: "benchmark"),
                .product(name: "GraphProtocols", package: "Grafluent"),
                .product(name: "IsomorphismModule", package: "Grafluent"),
                .product(name: "AdjacencyListModule", package: "Grafluent"),
                .product(name: "RandomGraphs", package: "Grafluent"),
            ],
            path: "Benchmarks/IsomorphismBenchmarks",
            plugins: [.plugin(name: "BenchmarkPlugin", package: "benchmark")]
        ),
        .executableTarget(
            name: "MatchingBenchmarks",
            dependencies: [
                "BenchmarkSupport",
                .product(name: "Benchmark", package: "benchmark"),
                .product(name: "GraphProtocols", package: "Grafluent"),
                .product(name: "MatchingModule", package: "Grafluent"),
                .product(name: "BipartiteGraphs", package: "Grafluent"),
                .product(name: "AdjacencyListModule", package: "Grafluent"),
            ],
            path: "Benchmarks/MatchingBenchmarks",
            plugins: [.plugin(name: "BenchmarkPlugin", package: "benchmark")]
        ),
        .executableTarget(
            name: "CoveringBenchmarks",
            dependencies: [
                "BenchmarkSupport",
                .product(name: "Benchmark", package: "benchmark"),
                .product(name: "GraphProtocols", package: "Grafluent"),
                .product(name: "Covering", package: "Grafluent"),
                .product(name: "AdjacencyListModule", package: "Grafluent"),
            ],
            path: "Benchmarks/CoveringBenchmarks",
            plugins: [.plugin(name: "BenchmarkPlugin", package: "benchmark")]
        ),
        .executableTarget(
            name: "ColoringBenchmarks",
            dependencies: [
                "BenchmarkSupport",
                .product(name: "Benchmark", package: "benchmark"),
                .product(name: "GraphProtocols", package: "Grafluent"),
                .product(name: "ColoringModule", package: "Grafluent"),
                .product(name: "AdjacencyListModule", package: "Grafluent"),
                .product(name: "Multigraphs", package: "Grafluent"),
            ],
            path: "Benchmarks/ColoringBenchmarks",
            plugins: [.plugin(name: "BenchmarkPlugin", package: "benchmark")]
        ),
        .executableTarget(
            name: "GraphOperationsBenchmarks",
            dependencies: [
                "BenchmarkSupport",
                .product(name: "Benchmark", package: "benchmark"),
                .product(name: "GraphProtocols", package: "Grafluent"),
                .product(name: "GraphOperations", package: "Grafluent"),
                .product(name: "AdjacencyListModule", package: "Grafluent"),
                .product(name: "CompressedSparseRowModule", package: "Grafluent"),
                .product(name: "DirectedAcyclicGraphModule", package: "Grafluent"),
                .product(name: "Traversal", package: "Grafluent"),
                .product(name: "Connectivity", package: "Grafluent"),
            ],
            path: "Benchmarks/GraphOperationsBenchmarks",
            plugins: [.plugin(name: "BenchmarkPlugin", package: "benchmark")]
        ),
        .executableTarget(
            name: "GraphProductsBenchmarks",
            dependencies: [
                "BenchmarkSupport",
                .product(name: "Benchmark", package: "benchmark"),
                .product(name: "GraphProtocols", package: "Grafluent"),
                .product(name: "GraphProducts", package: "Grafluent"),
                .product(name: "AdjacencyListModule", package: "Grafluent"),
                .product(name: "CompressedSparseRowModule", package: "Grafluent"),
                .product(name: "NamedGraphs", package: "Grafluent"),
                .product(name: "Traversal", package: "Grafluent"),
                .product(name: "Connectivity", package: "Grafluent"),
            ],
            path: "Benchmarks/GraphProductsBenchmarks",
            plugins: [.plugin(name: "BenchmarkPlugin", package: "benchmark")]
        ),
        .executableTarget(
            name: "LabeledGraphsBenchmarks",
            dependencies: [
                "BenchmarkSupport",
                .product(name: "Benchmark", package: "benchmark"),
                .product(name: "GraphProtocols", package: "Grafluent"),
                .product(name: "LabeledGraphs", package: "Grafluent"),
                .product(name: "CompressedSparseRowModule", package: "Grafluent"),
                .product(name: "AdjacencyMatrixModule", package: "Grafluent"),
                .product(name: "AdjacencyListModule", package: "Grafluent"),
                .product(name: "Traversal", package: "Grafluent"),
                .product(name: "Connectivity", package: "Grafluent"),
                .product(name: "ShortestPaths", package: "Grafluent"),
                .product(name: "SpanningTrees", package: "Grafluent"),
            ],
            path: "Benchmarks/LabeledGraphsBenchmarks",
            plugins: [.plugin(name: "BenchmarkPlugin", package: "benchmark")]
        ),
        .executableTarget(
            name: "DirectedAcyclicGraphBenchmarks",
            dependencies: [
                "BenchmarkSupport",
                .product(name: "Benchmark", package: "benchmark"),
                .product(name: "GraphProtocols", package: "Grafluent"),
                .product(name: "DirectedAcyclicGraphModule", package: "Grafluent"),
                .product(name: "AdjacencyListModule", package: "Grafluent"),
                .product(name: "Multigraphs", package: "Grafluent"),
                .product(name: "StableGraphs", package: "Grafluent"),
                .product(name: "Connectivity", package: "Grafluent"),
                .product(name: "Traversal", package: "Grafluent"),
                .product(name: "ShortestPaths", package: "Grafluent"),
            ],
            path: "Benchmarks/DirectedAcyclicGraphBenchmarks",
            plugins: [.plugin(name: "BenchmarkPlugin", package: "benchmark")]
        ),
        .executableTarget(
            name: "FunctionalGraphsBenchmarks",
            dependencies: [
                "BenchmarkSupport",
                .product(name: "Benchmark", package: "benchmark"),
                .product(name: "GraphProtocols", package: "Grafluent"),
                .product(name: "FunctionalGraphs", package: "Grafluent"),
                .product(name: "CompressedSparseRowModule", package: "Grafluent"),
                .product(name: "Connectivity", package: "Grafluent"),
                .product(name: "Traversal", package: "Grafluent"),
            ],
            path: "Benchmarks/FunctionalGraphsBenchmarks",
            plugins: [.plugin(name: "BenchmarkPlugin", package: "benchmark")]
        ),
        .executableTarget(
            name: "ImplicitGraphsBenchmarks",
            dependencies: [
                "BenchmarkSupport",
                .product(name: "Benchmark", package: "benchmark"),
                .product(name: "GraphProtocols", package: "Grafluent"),
                .product(name: "ImplicitGraphs", package: "Grafluent"),
                .product(name: "CompressedSparseRowModule", package: "Grafluent"),
                .product(name: "Connectivity", package: "Grafluent"),
                .product(name: "ShortestPaths", package: "Grafluent"),
                .product(name: "Traversal", package: "Grafluent"),
            ],
            path: "Benchmarks/ImplicitGraphsBenchmarks",
            plugins: [.plugin(name: "BenchmarkPlugin", package: "benchmark")]
        ),
        .executableTarget(
            name: "HypergraphsBenchmarks",
            dependencies: [
                "BenchmarkSupport",
                .product(name: "Benchmark", package: "benchmark"),
                .product(name: "GraphProtocols", package: "Grafluent"),
                .product(name: "Hypergraphs", package: "Grafluent"),
                .product(name: "AdjacencyListModule", package: "Grafluent"),
                .product(name: "CompressedSparseRowModule", package: "Grafluent"),
                .product(name: "DisjointSetModule", package: "Grafluent"),
                .product(name: "Connectivity", package: "Grafluent"),
                .product(name: "Traversal", package: "Grafluent"),
            ],
            path: "Benchmarks/HypergraphsBenchmarks",
            plugins: [.plugin(name: "BenchmarkPlugin", package: "benchmark")]
        ),
        .executableTarget(
            name: "IncidenceMatrixBenchmarks",
            dependencies: [
                "BenchmarkSupport",
                .product(name: "Benchmark", package: "benchmark"),
                .product(name: "GraphProtocols", package: "Grafluent"),
                .product(name: "IncidenceMatrixModule", package: "Grafluent"),
                .product(name: "Hypergraphs", package: "Grafluent"),
                .product(name: "Multigraphs", package: "Grafluent"),
            ],
            path: "Benchmarks/IncidenceMatrixBenchmarks",
            plugins: [.plugin(name: "BenchmarkPlugin", package: "benchmark")]
        ),
        .executableTarget(
            name: "StableGraphsBenchmarks",
            dependencies: [
                "BenchmarkSupport",
                .product(name: "Benchmark", package: "benchmark"),
                .product(name: "GraphProtocols", package: "Grafluent"),
                .product(name: "StableGraphs", package: "Grafluent"),
                .product(name: "Multigraphs", package: "Grafluent"),
                .product(name: "Connectivity", package: "Grafluent"),
                .product(name: "Traversal", package: "Grafluent"),
            ],
            path: "Benchmarks/StableGraphsBenchmarks",
            plugins: [.plugin(name: "BenchmarkPlugin", package: "benchmark")]
        ),
        .executableTarget(
            name: "GraphFormatsBenchmarks",
            dependencies: [
                "BenchmarkSupport",
                .product(name: "Benchmark", package: "benchmark"),
                .product(name: "GraphProtocols", package: "Grafluent"),
                .product(name: "GraphFormats", package: "Grafluent"),
                .product(name: "Multigraphs", package: "Grafluent"),
                .product(name: "AdjacencyListModule", package: "Grafluent"),
                .product(name: "CompressedSparseRowModule", package: "Grafluent"),
            ],
            path: "Benchmarks/GraphFormatsBenchmarks",
            plugins: [.plugin(name: "BenchmarkPlugin", package: "benchmark")]
        ),
        .executableTarget(
            name: "MultigraphsBenchmarks",
            dependencies: [
                "BenchmarkSupport",
                .product(name: "Benchmark", package: "benchmark"),
                .product(name: "GraphProtocols", package: "Grafluent"),
                .product(name: "Multigraphs", package: "Grafluent"),
                .product(name: "AdjacencyListModule", package: "Grafluent"),
            ],
            path: "Benchmarks/MultigraphsBenchmarks",
            plugins: [.plugin(name: "BenchmarkPlugin", package: "benchmark")]
        ),
        .executableTarget(
            name: "CliquesBenchmarks",
            dependencies: [
                "BenchmarkSupport",
                .product(name: "Benchmark", package: "benchmark"),
                .product(name: "GraphProtocols", package: "Grafluent"),
                .product(name: "Cliques", package: "Grafluent"),
                .product(name: "AdjacencyListModule", package: "Grafluent"),
            ],
            path: "Benchmarks/CliquesBenchmarks",
            plugins: [.plugin(name: "BenchmarkPlugin", package: "benchmark")]
        ),
        .executableTarget(
            name: "DistancesBenchmarks",
            dependencies: [
                "BenchmarkSupport",
                .product(name: "Benchmark", package: "benchmark"),
                .product(name: "GraphProtocols", package: "Grafluent"),
                .product(name: "Distances", package: "Grafluent"),
                .product(name: "AdjacencyListModule", package: "Grafluent"),
            ],
            path: "Benchmarks/DistancesBenchmarks",
            plugins: [.plugin(name: "BenchmarkPlugin", package: "benchmark")]
        ),
        .executableTarget(
            name: "TreeAlgorithmsBenchmarks",
            dependencies: [
                "BenchmarkSupport",
                .product(name: "Benchmark", package: "benchmark"),
                .product(name: "GraphProtocols", package: "Grafluent"),
                .product(name: "Trees", package: "Grafluent"),
                .product(name: "TreeAlgorithms", package: "Grafluent"),
                .product(name: "Walks", package: "Grafluent"),
            ],
            path: "Benchmarks/TreeAlgorithmsBenchmarks",
            plugins: [.plugin(name: "BenchmarkPlugin", package: "benchmark")]
        ),
        .executableTarget(
            name: "TreesBenchmarks",
            dependencies: [
                "BenchmarkSupport",
                .product(name: "Benchmark", package: "benchmark"),
                .product(name: "GraphProtocols", package: "Grafluent"),
                .product(name: "Trees", package: "Grafluent"),
                .product(name: "Walks", package: "Grafluent"),
                .product(name: "AdjacencyListModule", package: "Grafluent"),
            ],
            path: "Benchmarks/TreesBenchmarks",
            plugins: [.plugin(name: "BenchmarkPlugin", package: "benchmark")]
        ),
        .executableTarget(
            name: "CyclesBenchmarks",
            dependencies: [
                "BenchmarkSupport",
                .product(name: "Benchmark", package: "benchmark"),
                .product(name: "GraphProtocols", package: "Grafluent"),
                .product(name: "Cycles", package: "Grafluent"),
                .product(name: "Walks", package: "Grafluent"),
                .product(name: "AdjacencyListModule", package: "Grafluent"),
            ],
            path: "Benchmarks/CyclesBenchmarks",
            plugins: [.plugin(name: "BenchmarkPlugin", package: "benchmark")]
        ),
        .executableTarget(
            name: "WalksBenchmarks",
            dependencies: [
                "BenchmarkSupport",
                .product(name: "Benchmark", package: "benchmark"),
                .product(name: "GraphProtocols", package: "Grafluent"),
                .product(name: "Walks", package: "Grafluent"),
                .product(name: "AdjacencyListModule", package: "Grafluent"),
            ],
            path: "Benchmarks/WalksBenchmarks",
            plugins: [.plugin(name: "BenchmarkPlugin", package: "benchmark")]
        ),
        .executableTarget(
            name: "SpanningTreesBenchmarks",
            dependencies: [
                "BenchmarkSupport",
                .product(name: "Benchmark", package: "benchmark"),
                .product(name: "GraphProtocols", package: "Grafluent"),
                .product(name: "SpanningTrees", package: "Grafluent"),
                .product(name: "AdjacencyListModule", package: "Grafluent"),
                .product(name: "AdjacencyMatrixModule", package: "Grafluent"),
            ],
            path: "Benchmarks/SpanningTreesBenchmarks",
            plugins: [.plugin(name: "BenchmarkPlugin", package: "benchmark")]
        ),
        .executableTarget(
            name: "DirectedGraphBenchmarks",
            dependencies: [
                "BenchmarkSupport",
                .product(name: "Benchmark", package: "benchmark"),
                .product(name: "GraphProtocols", package: "Grafluent"),
            ] + representation.map { .product(name: "\($0)Module", package: "Grafluent") },
            path: "Benchmarks/DirectedGraphBenchmarks",
            plugins: [.plugin(name: "BenchmarkPlugin", package: "benchmark")]
        ),
        .executableTarget(
            name: "FlowsBenchmarks",
            dependencies: [
                "BenchmarkSupport",
                .product(name: "Benchmark", package: "benchmark"),
                .product(name: "GraphProtocols", package: "Grafluent"),
                .product(name: "Flows", package: "Grafluent"),
                .product(name: "Multigraphs", package: "Grafluent"),
                .product(name: "CompressedSparseRowModule", package: "Grafluent"),
            ],
            path: "Benchmarks/FlowsBenchmarks",
            plugins: [.plugin(name: "BenchmarkPlugin", package: "benchmark")]
        ),
        .executableTarget(
            name: "ToursBenchmarks",
            dependencies: [
                "BenchmarkSupport",
                .product(name: "Benchmark", package: "benchmark"),
                .product(name: "GraphProtocols", package: "Grafluent"),
                .product(name: "Tours", package: "Grafluent"),
                .product(name: "AdjacencyListModule", package: "Grafluent"),
                .product(name: "Multigraphs", package: "Grafluent"),
                .product(name: "CompressedSparseRowModule", package: "Grafluent"),
            ],
            path: "Benchmarks/ToursBenchmarks",
            plugins: [.plugin(name: "BenchmarkPlugin", package: "benchmark")]
        ),
        .executableTarget(
            name: "NamedGraphsBenchmarks",
            dependencies: [
                .product(name: "Benchmark", package: "benchmark"),
                .product(name: "GraphProtocols", package: "Grafluent"),
                .product(name: "NamedGraphs", package: "Grafluent"),
                .product(name: "AdjacencyListModule", package: "Grafluent"),
                .product(name: "CompressedSparseRowModule", package: "Grafluent"),
                .product(name: "Trees", package: "Grafluent"),
            ],
            path: "Benchmarks/NamedGraphsBenchmarks",
            plugins: [.plugin(name: "BenchmarkPlugin", package: "benchmark")]
        ),
        .executableTarget(
            name: "GraphDrawingBenchmarks",
            dependencies: [
                .product(name: "Benchmark", package: "benchmark"),
                .product(name: "GraphProtocols", package: "Grafluent"),
                .product(name: "GraphDrawing", package: "Grafluent"),
                .product(name: "RandomGraphs", package: "Grafluent"),
                .product(name: "AdjacencyListModule", package: "Grafluent"),
                .product(name: "CompressedSparseRowModule", package: "Grafluent"),
                .product(name: "Trees", package: "Grafluent"),
            ],
            path: "Benchmarks/GraphDrawingBenchmarks",
            plugins: [.plugin(name: "BenchmarkPlugin", package: "benchmark")]
        ),
        .executableTarget(
            name: "RandomGraphsBenchmarks",
            dependencies: [
                .product(name: "Benchmark", package: "benchmark"),
                .product(name: "GraphProtocols", package: "Grafluent"),
                .product(name: "RandomGraphs", package: "Grafluent"),
                .product(name: "AdjacencyListModule", package: "Grafluent"),
                .product(name: "BipartiteGraphs", package: "Grafluent"),
                .product(name: "CompressedSparseRowModule", package: "Grafluent"),
                .product(name: "DirectedAcyclicGraphModule", package: "Grafluent"),
                .product(name: "Trees", package: "Grafluent"),
            ],
            path: "Benchmarks/RandomGraphsBenchmarks",
            plugins: [.plugin(name: "BenchmarkPlugin", package: "benchmark")]
        ),
        .executableTarget(
            name: "SpectralGraphTheoryBenchmarks",
            dependencies: [
                "BenchmarkSupport",
                .product(name: "Benchmark", package: "benchmark"),
                .product(name: "GraphProtocols", package: "Grafluent"),
                .product(name: "SpectralGraphTheory", package: "Grafluent"),
                .product(name: "AdjacencyListModule", package: "Grafluent"),
            ],
            path: "Benchmarks/SpectralGraphTheoryBenchmarks",
            plugins: [.plugin(name: "BenchmarkPlugin", package: "benchmark")]
        ),
    ] + representation.map { name in
        .executableTarget(
            name: "\(name)Benchmarks",
            dependencies: [
                "BenchmarkSupport",
                .product(name: "Benchmark", package: "benchmark"),
                .product(name: "GraphProtocols", package: "Grafluent"),
                .product(name: "\(name)Module", package: "Grafluent"),
                .product(name: "BitCollections", package: "swift-collections"),
            ],
            path: "Benchmarks/\(name)Benchmarks",
            plugins: [.plugin(name: "BenchmarkPlugin", package: "benchmark")]
        )
    }
)
