// swift-tools-version: 6.2
import PackageDescription

// Differential testing against NetworkX and scipy: this executable answers a batch of queries
// with the library, and scripts/differential.py asks the reference libraries the same questions
// and compares. In its own package so the library never depends on Foundation's JSON coding.
// See Differential/README.md.

let package = Package(
    name: "GrafluentDifferential",
    platforms: [.macOS(.v15)],
    dependencies: [.package(path: "..")],
    targets: [
        .executableTarget(
            name: "GrafluentDifferential",
            dependencies: ["GraphProtocols", "AdjacencyListModule", "ShortestPaths", "SpanningTrees", "Connectivity"].map { .product(name: $0, package: "Grafluent") }
        ),
    ]
)
