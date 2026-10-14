// swift-tools-version: 6.3
// The browser explorer: Grafluent compiled to WebAssembly, with an ElementaryUI interface. Built
// by `just explore` (see README.md); Bazel ignores this package.
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
                .product(name: "ShortestPaths", package: "Grafluent"),
            ]
        )
    ],
    swiftLanguageModes: [.v5]
)
