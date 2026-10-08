#!/usr/bin/env python3
"""The module graph, written once.

Package.swift and every Sources/*/BUILD.bazel are generated from this table, so SwiftPM and Bazel
cannot drift. Run `just modules` after editing it.

Module names follow swift-collections: named after the concept they hold, with a `Module` suffix
only where the module would otherwise share a name with its main type (as DequeModule/Deque).
"""

# External packages: (identity, url, minimum version). A dependency written "identity/Product"
# in the table below refers to a product of one of these.
PACKAGES = [
    ("swift-collections", "https://github.com/apple/swift-collections", "1.3.0"),
]

# (name, group, description, dependencies)
MODULES = [
    # Vocabulary
    ("GraphProtocols", "Vocabulary", "DirectedGraph, Graph and their refinements; Arc and Edge; the result builders that construct graphs.", []),
    ("Walks", "Vocabulary", "Walk, Trail, Path, Circuit and Cycle.", ["GraphProtocols"]),
    ("Semirings", "Vocabulary", "The Semiring protocol and the tropical, bottleneck, Boolean and counting semirings, for algebraic path problems.", []),

    # Data structures used by graph algorithms
    ("PriorityQueueModule", "Data structures", "IndexedPriorityQueue: a d-ary heap with decrease-key.", []),
    ("DisjointSetModule", "Data structures", "DisjointSet: union–find with path compression and union by rank.", []),

    # Representations
    ("AdjacencyListModule", "Representations", "AdjacencyList: a directed graph stored as out- and in-adjacency per vertex.", ["GraphProtocols"]),
    ("AdjacencyMatrixModule", "Representations", "AdjacencyMatrix: a directed graph on vertices 0..<n stored as an n×n bit matrix.", ["GraphProtocols", "swift-collections/BitCollections"]),
    ("IncidenceMatrixModule", "Representations", "IncidenceMatrix.", ["GraphProtocols"]),
    ("CompressedSparseRowModule", "Representations", "CompressedSparseRow and CompressedSparseColumn.", ["GraphProtocols"]),
    ("EdgeListModule", "Representations", "EdgeList.", ["GraphProtocols"]),
    ("ImplicitGraphs", "Representations", "ImplicitDirectedGraph: out-neighbors computed on demand, never stored.", ["GraphProtocols"]),
    ("LabeledGraphs", "Representations", "LabeledGraph: arbitrary vertex labels over an index-based representation.", ["GraphProtocols"]),

    # Graph classes with invariants
    ("DirectedAcyclicGraphModule", "Structures", "DirectedAcyclicGraph: acyclicity enforced on insertion by incremental cycle detection.", ["GraphProtocols", "Walks"]),
    ("Trees", "Structures", "Tree, RootedTree, Forest and Arborescence.", ["GraphProtocols"]),
    ("BipartiteGraphs", "Structures", "BipartiteGraph.", ["GraphProtocols", "Walks"]),
    ("Multigraphs", "Structures", "Multigraph, DirectedMultigraph and Pseudograph.", ["GraphProtocols"]),
    ("Hypergraphs", "Structures", "Hypergraph and Hyperedge.", []),
    ("FlowNetworks", "Structures", "FlowNetwork: a directed graph with capacities, a source and a sink.", ["GraphProtocols"]),
    ("FunctionalGraphs", "Structures", "FunctionalGraph: every vertex has outdegree 1; Floyd's and Brent's cycle detection.", ["GraphProtocols", "Walks"]),

    # Operations
    ("GraphOperations", "Operations", "Subgraph, induced subgraph, converse, underlying graph, complement, line graph, condensation, quotient graph, union, intersection and join.", ["GraphProtocols", "DirectedAcyclicGraphModule"]),
    ("GraphProducts", "Operations", "Cartesian, tensor, strong and lexicographic products.", ["GraphProtocols"]),

    # Algorithms
    ("Traversal", "Algorithms", "Breadth-first and depth-first search, topological ordering, lexicographic BFS.", ["GraphProtocols", "Walks"]),
    ("ShortestPaths", "Algorithms", "Dijkstra, Bellman–Ford, A*, Floyd–Warshall, Johnson, Yen, Δ-stepping, contraction hierarchies.", ["GraphProtocols", "Walks", "Semirings", "Trees", "PriorityQueueModule"]),
    ("SpanningTrees", "Algorithms", "Kruskal, Prim, Borůvka, Chu–Liu/Edmonds, Steiner tree approximation.", ["GraphProtocols", "Trees", "DisjointSetModule", "PriorityQueueModule"]),
    ("Connectivity", "Algorithms", "Components, strong components, blocks, cut vertices, bridges, dominators.", ["GraphProtocols", "Traversal", "Trees", "DisjointSetModule"]),
    ("Cycles", "Algorithms", "Cycle detection, cycle bases, elementary circuits, girth.", ["GraphProtocols", "Walks", "Traversal", "DisjointSetModule"]),
    ("Tours", "Algorithms", "Eulerian trails and circuits, Hamiltonian paths and cycles, travelling salesman heuristics.", ["GraphProtocols", "Walks", "SpanningTrees", "MatchingModule"]),
    ("Flows", "Algorithms", "Maximum flow, minimum-cost flow, minimum cut, Gomory–Hu trees.", ["GraphProtocols", "FlowNetworks", "Trees", "Traversal"]),
    ("MatchingModule", "Algorithms", "Matching: Hopcroft–Karp, Hungarian, Edmonds' blossom, Gale–Shapley.", ["GraphProtocols", "BipartiteGraphs"]),
    ("ColoringModule", "Algorithms", "Coloring: greedy, DSatur, Welsh–Powell, exact chromatic number, edge coloring.", ["GraphProtocols", "BipartiteGraphs"]),
    ("Cliques", "Algorithms", "Bron–Kerbosch, k-cores, triangle counting, clustering coefficient.", ["GraphProtocols"]),
    ("Covering", "Algorithms", "Vertex cover, independent set, dominating set.", ["GraphProtocols", "MatchingModule"]),
    ("Centrality", "Algorithms", "Degree, closeness, harmonic, betweenness, eigenvector, Katz, PageRank, HITS.", ["GraphProtocols", "ShortestPaths", "Traversal"]),
    ("CommunityDetection", "Algorithms", "Louvain, Leiden, label propagation, Girvan–Newman, modularity.", ["GraphProtocols", "Centrality"]),
    ("IsomorphismModule", "Algorithms", "Isomorphism: VF2, VF2++, Weisfeiler–Leman, canonical labeling.", ["GraphProtocols"]),
    ("Planarity", "Algorithms", "Boyer–Myrvold planarity testing and planar embeddings.", ["GraphProtocols", "Traversal"]),
    ("TreeAlgorithms", "Algorithms", "Lowest common ancestor, Euler tour, heavy–light decomposition, centroid, diameter.", ["GraphProtocols", "Trees"]),
    ("Distances", "Algorithms", "Eccentricity, diameter, radius, center, periphery, density.", ["GraphProtocols", "ShortestPaths"]),
    ("SpectralGraphTheory", "Algorithms", "Adjacency and Laplacian matrices, Fiedler vector, spectral clustering.", ["GraphProtocols"]),

    # Generators
    ("NamedGraphs", "Generators", "Complete, complete bipartite, path, cycle, star, wheel, grid, hypercube and Petersen graphs.", ["GraphProtocols"]),
    ("RandomGraphs", "Generators", "Erdős–Rényi, Barabási–Albert, Watts–Strogatz, random geometric, stochastic block model, random trees and DAGs.", ["GraphProtocols"]),

    # Drawing and formats
    ("GraphDrawing", "Drawing", "Force-directed, layered (Sugiyama), tree, spectral and circular layouts.", ["GraphProtocols", "Traversal", "Cycles", "SpectralGraphTheory"]),
    ("GraphFormats", "Formats", "DOT, GraphML, GML, GEXF, Matrix Market and edge-list readers and writers.", ["GraphProtocols"]),
]

# Test targets that exist. SwiftPM rejects a target with no sources, so one is added here when a
# module's first suite is written. (name, dependencies)
TEST_TARGETS = [
    ("GrafluentTestSupportTests", ["GraphProtocols", "GrafluentTestSupport"]),
    ("AdjacencyListTests", ["GraphProtocols", "AdjacencyListModule", "GrafluentTestSupport"]),
    ("AdjacencyMatrixTests", ["GraphProtocols", "AdjacencyMatrixModule", "AdjacencyListModule", "GrafluentTestSupport", "swift-collections/BitCollections"]),
]

PLATFORMS = '[.macOS(.v15), .iOS(.v18), .tvOS(.v18), .watchOS(.v11), .visionOS(.v2)]'


def check():
    names = [m[0] for m in MODULES]
    assert len(names) == len(set(names)), "duplicate module"
    order = {n: i for i, n in enumerate(names)}
    for name, _, _, deps in MODULES:
        for d in deps:
            if "/" in d:
                assert d.split("/")[0] in [p[0] for p in PACKAGES], f"{name} depends on unknown package {d}"
            else:
                assert d in order, f"{name} depends on unknown {d}"


def spm_dep(d):
    if "/" in d:
        package, product = d.split("/")
        return f'.product(name: "{product}", package: "{package}")'
    return f'"{d}"'


def bazel_label(d):
    if "/" in d:
        package, product = d.split("/")
        return f"@swiftpkg_{package.replace('-', '_')}//:{product}"
    if d == "GrafluentTestSupport":
        return "//Tests/GrafluentTestSupport"
    return f"//Sources/{d}"


def excluded(path):
    """Non-source files SwiftPM would otherwise warn about, for the target at `path`."""
    import os
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    return [f for f in ("BUILD.bazel", "README.md") if os.path.exists(os.path.join(root, path, f))]


def exclude_arg(path):
    files = excluded(path)
    if files == ["BUILD.bazel"]:
        return ", exclude: bazelFiles"
    if files:
        return ", exclude: [" + ", ".join(f'"{f}"' for f in files) + "]"
    return ""


def package_swift():
    lines = [
        "// swift-tools-version: 6.2",
        "import PackageDescription",
        "",
        "// GENERATED by scripts/modules.py — edit the table there, then run `just modules`.",
        "//",
        "// The published package definition. Bazel is the development build system; both are generated",
        "// from the same table, and `just verify` builds and tests with both.",
        "",
        "// Every target directory holds a BUILD.bazel, which SwiftPM must be told to ignore.",
        'let bazelFiles = ["BUILD.bazel"]',
        "",
        "let package = Package(",
        '    name: "Grafluent",',
        "    // macOS 15 / iOS 18 is the floor for `Synchronization.Mutex`, used by the test support target.",
        "    // Revisit with open question 6 in README.md. Keep in step with .bazelrc.",
        f"    platforms: {PLATFORMS},",
        "    products: [",
        '        .library(name: "Grafluent", targets: ["Grafluent"]),',
    ]
    lines += [f'        .library(name: "{m[0]}", targets: ["{m[0]}"]),' for m in MODULES]
    lines += ["    ],", "    dependencies: ["]
    lines += [f'        .package(url: "{url}", from: "{version}"),' for _, url, version in PACKAGES]
    lines += ["    ],", "    targets: ["]
    group = None
    for name, g, _, deps in MODULES:
        if g != group:
            lines.append(f"        // {g}")
            group = g
        ex = exclude_arg(f"Sources/{name}")
        if deps:
            dl = ", ".join(spm_dep(d) for d in deps)
            lines.append(f'        .target(name: "{name}", dependencies: [{dl}]{ex}),')
        else:
            lines.append(f'        .target(name: "{name}"{ex}),')
    all_deps = ", ".join(f'"{m[0]}"' for m in MODULES)
    lines += [
        "",
        "        // Umbrella: `import Grafluent` imports every module.",
        f'        .target(name: "Grafluent", dependencies: [{all_deps}], exclude: bazelFiles),',
        "",
        "        // Shared fixtures, conformance checkers and instrumentation for every test target.",
        '        .target(name: "GrafluentTestSupport", dependencies: ["GraphProtocols"], path: "Tests/GrafluentTestSupport", exclude: bazelFiles),',
        "",
    ]
    for name, deps in TEST_TARGETS:
        dl = ", ".join(spm_dep(d) for d in deps)
        lines.append(f'        .testTarget(name: "{name}", dependencies: [{dl}]{exclude_arg(f"Tests/{name}")}),')
    lines += ["    ]", ")", ""]
    return "\n".join(lines)


def dependency_manifest():
    deps = "".join(f'        .package(url: "{url}", from: "{version}"),\n' for _, url, version in PACKAGES)
    return (
        "// swift-tools-version: 6.0\n"
        "import PackageDescription\n\n"
        "// GENERATED by scripts/modules.py. Dependency-resolution manifest for Bazel\n"
        "// (rules_swift_package_manager); it lists the same packages as the root Package.swift.\n"
        "// After changing it, run `just resolve`.\n"
        "let package = Package(\n"
        '    name: "GrafluentDependencies",\n'
        '    platforms: [.macOS("15.0")],\n'
        f"    dependencies: [\n{deps}    ]\n"
        ")\n"
    )


def build_bazel(name, description, deps, umbrella=False):
    dl = "".join(f'        "{bazel_label(d)}",\n' for d in deps)
    deps_attr = f"    deps = [\n{dl}    ],\n" if deps else ""
    return (
        "# GENERATED by scripts/modules.py — edit the table there, then run `just modules`.\n\n"
        'load("//tools:swift_rules.bzl", "swift_library")\n\n'
        f"# {description}\n"
        "swift_library(\n"
        f'    name = "{name}",\n'
        '    srcs = glob(["**/*.swift"]),\n'
        f'    module_name = "{name}",\n'
        f"{deps_attr}"
        '    visibility = ["//visibility:public"],\n'
        ")\n"
    )


def test_build_bazel(name, deps):
    dl = "".join(f'        "{bazel_label(d)}",\n' for d in deps)
    return (
        "# GENERATED by scripts/modules.py — edit the table there, then run `just modules`.\n\n"
        'load("//tools:swift_rules.bzl", "swift_test")\n\n'
        "swift_test(\n"
        f'    name = "{name}",\n'
        '    size = "small",\n'
        '    srcs = glob(["**/*.swift"]),\n'
        f'    module_name = "{name}",\n'
        "    # Visible so `//:xcodeproj` can name it as a top-level target; a test target is otherwise\n"
        "    # private to its own package.\n"
        '    visibility = ["//visibility:public"],\n'
        f"    deps = [\n{dl}    ],\n"
        ")\n"
    )


def main():
    import os
    check()
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    for name, _, description, deps in MODULES:
        d = os.path.join(root, "Sources", name)
        os.makedirs(d, exist_ok=True)
        with open(os.path.join(d, "BUILD.bazel"), "w") as f:
            f.write(build_bazel(name, description, deps))
        # SwiftPM and Bazel both reject a module with no sources. Until a module has real
        # sources, it carries a file holding only its description.
        if not any(fn.endswith(".swift") for _, _, fns in os.walk(d) for fn in fns):
            with open(os.path.join(d, f"{name}.swift"), "w") as f:
                f.write(f"// {name}: {description}\n//\n// No implementation yet; see README.md.\n")
    for name, deps in TEST_TARGETS:
        d = os.path.join(root, "Tests", name)
        os.makedirs(d, exist_ok=True)
        with open(os.path.join(d, "BUILD.bazel"), "w") as f:
            f.write(test_build_bazel(name, deps))
    d = os.path.join(root, "Sources", "Grafluent")
    os.makedirs(d, exist_ok=True)
    names = [m[0] for m in MODULES]
    with open(os.path.join(d, "BUILD.bazel"), "w") as f:
        f.write(build_bazel("Grafluent", "Umbrella: `import Grafluent` imports every module.", names))
    with open(os.path.join(d, "Grafluent.swift"), "w") as f:
        f.write("// GENERATED by scripts/modules.py.\n//\n// Umbrella: `import Grafluent` imports every module.\n\n")
        f.write("".join(f"@_exported import {n}\n" for n in names))
    with open(os.path.join(root, "swift", "Package.swift"), "w") as f:
        f.write(dependency_manifest())
    # Written last: which files each target must exclude depends on the BUILD files above.
    with open(os.path.join(root, "Package.swift"), "w") as f:
        f.write(package_swift())


if __name__ == "__main__":
    main()
