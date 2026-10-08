// swift-tools-version: 6.2
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
            name: "DirectedGraphBenchmarks",
            dependencies: [
                "BenchmarkSupport",
                .product(name: "Benchmark", package: "benchmark"),
                .product(name: "GraphProtocols", package: "Grafluent"),
            ] + representation.map { .product(name: "\($0)Module", package: "Grafluent") },
            path: "Benchmarks/DirectedGraphBenchmarks",
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
