// swift-tools-version: 6.2
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
        target("FuzzDistances", ["GraphProtocols", "AdjacencyListModule", "Distances", "Walks"]),
        target("FuzzTreeAlgorithms", ["GraphProtocols", "Trees", "TreeAlgorithms", "Walks"]),
        target("FuzzTrees", ["GraphProtocols", "AdjacencyListModule", "Trees", "Walks"]),
        target("FuzzCycles", ["GraphProtocols", "AdjacencyListModule", "Cycles", "Walks"]),
        target("FuzzShortestPaths", ["GraphProtocols", "AdjacencyListModule", "CompressedSparseRowModule", "ShortestPaths", "Walks"]),
    ]
)
