// swift-tools-version: 6.3
import PackageDescription

// The Grafluent side of the cross-language comparison (Benchmarks/CrossLanguage/README.md): a
// client of the package by path, built with `swift build -c release` as an application would be.

let package = Package(
    name: "CrossGrafluent",
    platforms: [.macOS(.v15)],
    dependencies: [.package(path: "../../..")],
    targets: [
        .executableTarget(
            name: "CrossGrafluent",
            dependencies: [
                "GraphProtocols", "AdjacencyListModule", "CompressedSparseRowModule", "Multigraphs",
                "BipartiteGraphs", "Traversal", "Connectivity", "ShortestPaths", "SpanningTrees", "Flows",
                "MatchingModule", "IsomorphismModule", "Centrality", "Cliques",
            ].map { .product(name: $0, package: "Grafluent") }
        ),
    ]
)
