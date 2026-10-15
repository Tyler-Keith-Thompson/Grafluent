// swift-tools-version: 6.3
// The browser explorer: Grafluent compiled to WebAssembly, with an ElementaryUI interface, one
// .wasm for every page of the site. Built by `just explore` (see README.md); Bazel ignores this
// package.
import PackageDescription

let package = Package(
    name: "Explore",
    platforms: [.macOS(.v15)],
    dependencies: [
        .package(name: "Grafluent", path: ".."),
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
                .product(name: "GraphProtocols", package: "Grafluent"),
                .product(name: "AdjacencyListModule", package: "Grafluent"),
                .product(name: "AdjacencyMatrixModule", package: "Grafluent"),
                .product(name: "CompressedSparseRowModule", package: "Grafluent"),
                .product(name: "LabeledGraphs", package: "Grafluent"),
                .product(name: "Traversal", package: "Grafluent"),
                .product(name: "DirectedAcyclicGraphModule", package: "Grafluent"),
                .product(name: "IsomorphismModule", package: "Grafluent"),
                .product(name: "TreeAlgorithms", package: "Grafluent"),
                .product(name: "Similarity", package: "Grafluent"),
                .product(name: "FunctionalGraphs", package: "Grafluent"),
                .product(name: "ShortestPaths", package: "Grafluent"),
                .product(name: "SpanningTrees", package: "Grafluent"),
                .product(name: "Connectivity", package: "Grafluent"),
                .product(name: "BipartiteGraphs", package: "Grafluent"),
                .product(name: "MatchingModule", package: "Grafluent"),
                .product(name: "Multigraphs", package: "Grafluent"),
                .product(name: "Walks", package: "Grafluent"),
                .product(name: "ColoringModule", package: "Grafluent"),
                .product(name: "Centrality", package: "Grafluent"),
                .product(name: "NamedGraphs", package: "Grafluent"),
                .product(name: "GraphDrawing", package: "Grafluent"),
                .product(name: "Tours", package: "Grafluent"),
                .product(name: "RandomGraphs", package: "Grafluent"),
                .product(name: "Trees", package: "Grafluent"),
                .product(name: "Planarity", package: "Grafluent"),
                .product(name: "Semirings", package: "Grafluent"),
                .product(name: "Flows", package: "Grafluent"),
                .product(name: "Cliques", package: "Grafluent"),
                .product(name: "CommunityDetection", package: "Grafluent"),
            ],
            plugins: ["Snippets"]
        ),
        // The code panels: the regions of the page sources marked `// snippet: name`, as string
        // constants, so each page shows the code it runs.
        .executableTarget(name: "SnippetExtractor"),
        .plugin(name: "Snippets", capability: .buildTool(), dependencies: ["SnippetExtractor"]),
    ],
    swiftLanguageModes: [.v5]
)
