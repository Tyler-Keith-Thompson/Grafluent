// swift-tools-version: 6.4
// The browser explorer: Grafluent compiled to WebAssembly, with an ElementaryUI interface, one
// .wasm for every page of the site. Built by `just explore` (see README.md); Bazel ignores this
// package.
import PackageDescription

// SwiftPM names a package at a path by its directory, whatever the checkout is called.
let library = String(#filePath.split(separator: "/").dropLast(2).last!)

let package = Package(
    name: "Explore",
    platforms: [.macOS(.v15)],
    dependencies: [
        .package(path: ".."),
        .package(url: "https://github.com/elementary-swift/elementary-ui", exact: "0.7.0"),
        .package(url: "https://github.com/swiftwasm/JavaScriptKit", exact: "0.58.0"),
        // ElementaryUI 0.7.0 was built against swift-collections 1.6, whose container previews
        // (InputSpan, MutableRef) 1.7 moved.
        .package(url: "https://github.com/apple/swift-collections", "1.6.0" ..< "1.7.0"),
    ],
    targets: [
        .executableTarget(
            name: "Explore",
            dependencies: [
                .product(name: "ElementaryUI", package: "elementary-ui"),
                .product(name: "JavaScriptKit", package: "JavaScriptKit"),
            ] + [
                "GraphProtocols",
                "AdjacencyListModule",
                "AdjacencyMatrixModule",
                "CompressedSparseRowModule",
                "PackedCompressedSparseRowModule",
                "LabeledGraphs",
                "Traversal",
                "DirectedAcyclicGraphModule",
                "IsomorphismModule",
                "TreeAlgorithms",
                "Similarity",
                "FunctionalGraphs",
                "ShortestPaths",
                "SpanningTrees",
                "Connectivity",
                "BipartiteGraphs",
                "MatchingModule",
                "Multigraphs",
                "Walks",
                "ColoringModule",
                "Centrality",
                "NamedGraphs",
                "GraphDrawing",
                "Tours",
                "RandomGraphs",
                "Trees",
                "Planarity",
                "Semirings",
                "Flows",
                "Cliques",
                "Cycles",
                "GraphProducts",
                "Hypergraphs",
                "Assortativity",
                "GraphOperations",
                "Distances",
                "CommunityDetection",
                "SpectralGraphTheory",
                "Covering",
                "GraphFormats",
            ].map { .product(name: $0, package: library) },
            plugins: ["Snippets"]
        ),
        // The code panels: the regions of the page sources marked `// snippet: name`, as string
        // constants, so each page shows the code it runs.
        .executableTarget(name: "SnippetExtractor"),
        .plugin(name: "Snippets", capability: .buildTool(), dependencies: ["SnippetExtractor"]),
    ],
    swiftLanguageModes: [.v5]
)
