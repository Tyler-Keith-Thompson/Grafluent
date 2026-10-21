#!/usr/bin/env python3
"""The module graph, written once.

Package.swift and every Sources/*/BUILD.bazel are generated from this table, so SwiftPM and Bazel
cannot drift. Run `just modules` after editing it.

Modules are named after the concept they hold, with a `Module` suffix only where the module
would otherwise share a name with its main type (AdjacencyListModule and AdjacencyList).
"""

# External packages: (identity, url, minimum version). A dependency written "identity/Product"
# in the table below refers to a product of one of these.
PACKAGES = [
    ("swift-collections", "https://github.com/apple/swift-collections", "1.3.0"),
    ("swift-algorithms", "https://github.com/apple/swift-algorithms", "1.2.0"),
    # Publish-once lazy state (ManagedAtomicLazyReference) shared by copies of a value.
    ("swift-atomics", "https://github.com/apple/swift-atomics", "1.3.0"),
    # Tests only: property checks with shrinking, for Swift Testing.
    ("swift-property-based", "https://github.com/x-sheep/swift-property-based", "2.0.1"),
]

# (name, group, description, dependencies)
MODULES = [
    # Vocabulary
    ("GraphProtocols", "Vocabulary", "DirectedGraph, Graph and their refinements; DirectedEdge and UndirectedEdge; the result builders that construct graphs; NoConvergence, the error of iterative methods.", ["swift-algorithms/Algorithms"]),
    ("Walks", "Vocabulary", "Walk, Trail, Path, Circuit and Cycle: vertex sequences with the edge positions between them, their invariants enforced by construction.", ["GraphProtocols"]),
    ("Semirings", "Vocabulary", "The Semiring protocol and the tropical, max-plus, bottleneck, Viterbi, Boolean and counting semirings and the lexicographic product, for algebraic path problems.", []),

    # Data structures used by graph algorithms
    ("PriorityQueueModule", "Data structures", "IndexedPriorityQueue: an indexed 4-ary min-heap over 0..<indexBound with decrease-key; RadixHeap: a monotone priority queue over integer keys.", []),
    ("DisjointSetModule", "Data structures", "DisjointSet: union–find over 0..<count, with union by size and path halving.", []),
    ("LinkCutTreeModule", "Data structures", "LinkCutTree: Sleator–Tarjan dynamic trees over 0..<count, with link, cut, rerooting, and minimum and addition along root paths.", []),

    # Representations
    ("AdjacencyListModule", "Representations", "AdjacencyList: a directed graph stored as out- and in-adjacency per vertex.", ["GraphProtocols", "swift-atomics/Atomics"]),
    ("AdjacencyMatrixModule", "Representations", "AdjacencyMatrix: a directed graph on vertices 0..<n stored as an n×n bit matrix.", ["GraphProtocols", "swift-collections/BitCollections"]),
    ("IncidenceMatrixModule", "Representations", "IncidenceMatrix and OrientedIncidenceMatrix: a hypergraph's incidence as bit planes, conforming to Hypergraph and DirectedHypergraph.", ["GraphProtocols", "swift-collections/BitCollections"]),
    ("PackedCompressedSparseRowModule", "Representations", "PackedCompressedSparseRow: a mutable directed graph whose out- and in-rows stay contiguous in slot order with spare cells between them, a packed memory array over rows, so walks run as over compressed sparse rows and an insertion moves O(log² n) cells amortized.", ["GraphProtocols", "AdjacencyListModule"]),
    ("CompressedSparseRowModule", "Representations", "CompressedSparseRow: an immutable directed graph on vertices 0..<n in compressed sparse row form; BidirectionalCompressedSparseRow adds its column form for predecessors and in-edges.", ["GraphProtocols"]),
    ("EdgeListModule", "Representations", "EdgeList: a directed multigraph as an ordered, mutable list of edges.", ["GraphProtocols"]),
    ("ImplicitGraphs", "Representations", "ImplicitDirectedGraph: out-neighbors computed on demand, never stored.", ["GraphProtocols"]),
    ("LabeledGraphs", "Representations", "LabeledGraph: Hashable vertex labels over CompressedSparseRow or AdjacencyMatrix, kept in an OrderedSet whose element i names base vertex i, with every index-space member forwarded to the base.", ["GraphProtocols", "CompressedSparseRowModule", "AdjacencyMatrixModule", "swift-collections/OrderedCollections"]),

    # Graph classes with invariants
    ("DirectedAcyclicGraphModule", "Structures", "DirectedAcyclicGraph: a wrapper over any MutableDirectedGraph that rejects an edge closing a cycle and keeps a topological order by Pearce–Kelly, with every read member forwarded to the base; transitive closure and reduction, longest paths (unit and weighted), d-separation, minimal d-separators and the moral graph.", ["GraphProtocols", "Walks", "StableGraphs"]),
    ("Trees", "Structures", "Tree, RootedTree, Forest, Arborescence, OrderedTree and BinaryTree (every binary tree, Huffman trees); prefix trees.", ["GraphProtocols", "Walks"]),
    ("BipartiteGraphs", "Structures", "BipartiteGraph, bipartiteness, bipartitions and odd-cycle witnesses, one-mode projections (plain, shared-neighbour, overlap and collaboration weighted).", ["GraphProtocols", "Walks", "AdjacencyListModule"]),
    ("Multigraphs", "Structures", "Pseudograph, Multigraph, DirectedPseudograph and DirectedMultigraph: parallel edges, with and without self-loops.", ["GraphProtocols", "AdjacencyListModule"]),
    ("StableGraphs", "Structures", "StableDirectedGraph and StableUndirectedGraph: pseudographs whose vertex and edge positions survive removals, stored in pages freed once dead.", ["GraphProtocols"]),
    ("Hypergraphs", "Structures", "UndirectedIncidenceList and IncidenceList, the hypergraph algorithms, and the incidence-graph views through which graph algorithms reach a hypergraph.", ["GraphProtocols", "AdjacencyListModule", "DisjointSetModule", "swift-collections/OrderedCollections", "Connectivity"]),
    ("FunctionalGraphs", "Structures", "FunctionalGraph: every vertex has outdegree 1; Floyd's and Brent's cycle detection.", ["GraphProtocols", "Walks"]),

    # Operations
    ("GraphOperations", "Operations", "Subgraph, induced subgraph, ego graph, transposed and complement views, line graph, condensation, quotient graph and contraction, disjoint union and join, union, intersection, difference and symmetric difference, power, relabeling, transitive closure and reduction.", ["GraphProtocols", "DirectedAcyclicGraphModule", "Connectivity", "CompressedSparseRowModule", "swift-atomics/Atomics"]),
    ("GraphProducts", "Operations", "Cartesian, tensor, strong and lexicographic products.", ["GraphProtocols"]),

    # Algorithms
    ("Traversal", "Algorithms", "Breadth-first and depth-first search as event sequences, lexicographic breadth-first and maximum cardinality search, reachability, topological ordering (every order too), cycle finding, all simple paths, random walks (uniform, weighted, node2vec).", ["GraphProtocols", "Walks", "Trees"]),
    ("ShortestPaths", "Algorithms", "Dijkstra, bidirectional Dijkstra, Bellman–Ford, A*, DAG, unweighted, Floyd–Warshall and Johnson shortest paths, over numeric weights or a selective semiring; k shortest simple paths (Yen) and all shortest paths; and Mohri's DAG shortest distances over any semiring.", ["GraphProtocols", "Walks", "Semirings", "PriorityQueueModule", "DirectedAcyclicGraphModule", "Trees", "Connectivity"]),
    ("SpanningTrees", "Algorithms", "Minimum and maximum spanning forests by Kruskal, Prim and Borůvka; minimum and maximum spanning arborescences and branchings (Edmonds); Steiner trees (Mehlhorn; Kou, Markowsky and Berman); random spanning trees (Wilson).", ["GraphProtocols", "DisjointSetModule", "PriorityQueueModule", "Trees"]),
    ("Connectivity", "Algorithms", "Strong and weak components, condensation, attracting components, dominators; connected components, bridges, articulation points, biconnected, bi-edge-connected and k-edge-connected components, k-edge-connected subgraphs, k-components and the block–cut tree of undirected graphs.", ["GraphProtocols", "CompressedSparseRowModule", "Trees"]),
    ("Cycles", "Algorithms", "Cycle detection, cycle bases and minimum cycle bases (de Pina), elementary circuits, chordless cycles, minimum mean cycles (Karp), girth, feedback arc sets.", ["GraphProtocols", "Walks", "DisjointSetModule", "Connectivity", "PriorityQueueModule"]),
    ("Tours", "Algorithms", "Eulerian trails and circuits, Chinese postman tours, Hamiltonian paths and cycles, travelling salesman tours (exact, heuristic and metaheuristic).", ["GraphProtocols", "Walks", "MatchingModule", "SpanningTrees", "PriorityQueueModule", "Flows"]),
    ("Flows", "Algorithms", "Maximum flow (push–relabel, Dinic, Edmonds–Karp, Boykov–Kolmogorov), minimum cuts (s–t, Nagamochi–Ibaraki, Hao–Orlin), Gomory–Hu trees, minimum-cost flow (network simplex), feasible flows with lower bounds, cut metrics (conductance, expansions), edge and vertex connectivity, disjoint paths.", ["GraphProtocols", "Trees", "Walks", "LinkCutTreeModule"]),
    ("MatchingModule", "Algorithms", "Matching: Hopcroft–Karp, Hungarian, Edmonds' blossom, Gale–Shapley, bipartite b-matching.", ["GraphProtocols", "BipartiteGraphs", "Flows", "Multigraphs"]),
    ("ColoringModule", "Algorithms", "Vertex coloring (greedy strategies, exact chromatic number), edge coloring (Misra–Gries, König, greedy).", ["GraphProtocols", "BipartiteGraphs", "Cliques"]),
    ("Cliques", "Algorithms", "Bron–Kerbosch, every clique by size, maximum and maximum-weight cliques, k-cores, crusts and coronas, onion layers, k-trusses, triangle counting, clustering coefficient, chordal graphs (recognition, perfect elimination orderings, holes, cliques, treewidth), tree decompositions by the minimum-degree and minimum fill-in heuristics.", ["GraphProtocols", "Walks", "Traversal", "PriorityQueueModule"]),
    ("Covering", "Algorithms", "Vertex cover, independent set, dominating set, edge cover.", ["GraphProtocols", "MatchingModule", "BipartiteGraphs", "Cliques"]),
    ("Centrality", "Algorithms", "Degree, closeness, harmonic, betweenness (vertex and edge, exact or from pivots), load, percolation, current-flow betweenness and closeness, subgraph centrality and communicability, group centralities, VoteRank, eigenvector, Katz, PageRank, HITS.", ["GraphProtocols", "PriorityQueueModule"]),
    ("ParallelCentrality", "Algorithms", "Betweenness, closeness and harmonic centrality with their searches shared among tasks of a task group, as async spellings of Centrality's measures.", ["GraphProtocols", "Centrality"]),
    ("CommunityDetection", "Algorithms", "Modularity, the constant Potts model and the map equation; Louvain, Leiden and hierarchical Leiden, Infomap, label propagation, greedy modularity, Girvan–Newman, Kernighan–Lin bisection, k-clique percolation, asynchronous fluid, Walktrap and leading-eigenvector communities; spectral clustering (Ng–Jordan–Weiss).", ["GraphProtocols", "PriorityQueueModule", "Centrality", "Cliques", "SpectralGraphTheory"]),
    ("IsomorphismModule", "Algorithms", "Isomorphism and subgraph isomorphism (VF2++), canonical labeling, automorphism groups, Weisfeiler–Leman hashing, graph edit distance.", ["GraphProtocols"]),
    ("Planarity", "Algorithms", "Planarity testing and planar embeddings by the left-right test, Kuratowski subgraphs by Boyer–Myrvold, outerplanarity, dual graphs.", ["GraphProtocols", "Walks", "Multigraphs"]),
    ("TreeAlgorithms", "Algorithms", "Lowest common ancestor, Euler tour, heavy–light decomposition, center, centroid, diameter, tree edit distance (Zhang–Shasha).", ["GraphProtocols", "Trees", "Walks"]),
    ("Distances", "Algorithms", "Eccentricity, radius, diameter, center, periphery, centroid, Wiener index, average shortest path length, density, global and local efficiency.", ["GraphProtocols", "Walks", "PriorityQueueModule"]),
    ("Assortativity", "Algorithms", "Degree, attribute and numeric assortativity, average neighbor degree and degree connectivity, reciprocity, degree histograms and regularity, rich-club coefficients, the s-metric and the triadic census.", ["GraphProtocols"]),
    ("SpectralGraphTheory", "Algorithms", "Adjacency, Laplacian, normalized, random-walk and signless Laplacian matrices and incidence matrices as a SparseMatrix, modularity matrices; dense spectra; algebraic connectivity, Fiedler vector, spectral ordering, spectral radius and the k extreme eigenpairs by thick-restart Lanczos; spectral embedding (Laplacian eigenmaps); spanning-tree counts, resistance distance, effective graph resistance, the Kemeny constant, hitting and commute times, and stationary distributions.", ["GraphProtocols", "CompressedSparseRowModule"]),
    ("Similarity", "Algorithms", "Vertex-pair similarity for link prediction (common neighbors, Jaccard, Sørensen–Dice, cosine, Adamic–Adar, resource allocation, preferential attachment) and SimRank.", ["GraphProtocols"]),

    # Generators
    ("NamedGraphs", "Generators", "Complete, complete bipartite and multipartite, Turán, path, cycle, star, wheel, ladder, circular ladder, barbell, lollipop, windmill, grid, triangular and hexagonal lattice, hypercube, circulant, generalized Petersen, Kneser, de Bruijn, Kautz, LCF, balanced, full r-ary and binomial tree graphs, and the Petersen, Heawood, Möbius–Kantor, Pappus, Desargues, dodecahedral, icosahedral, Frucht, Tutte, Chvátal and Hoffman–Singleton graphs.", ["GraphProtocols", "Trees", "BipartiteGraphs", "AdjacencyListModule", "Multigraphs"]),
    ("RandomGraphs", "Generators", "Erdős–Rényi, R-MAT, Barabási–Albert, Holme–Kim, Watts–Strogatz and Newman–Watts–Strogatz, random geometric, random regular, random k-out, random bipartite, stochastic block model, Chung–Lu, configuration model, directed scale-free, random trees and DAGs; graphical degree sequences and Havel–Hakimi.", ["GraphProtocols", "AdjacencyListModule", "BipartiteGraphs", "NamedGraphs", "Trees", "DirectedAcyclicGraphModule", "Multigraphs"]),

    # Drawing and formats
    ("GraphDrawing", "Drawing", "Coordinates for drawing graphs: circular, shell, spiral, bipartite, multipartite, BFS, random, spectral, multidimensional scaling, planar straight-line (de Fraysseix–Pach–Pollack), Fruchterman–Reingold and ForceAtlas2 (exact or Barnes–Hut), stress majorization, Reingold–Tilford and layered (Sugiyama) layouts.", ["GraphProtocols", "Trees", "Cycles", "Planarity", "SpectralGraphTheory"]),
    ("GraphFormats", "Formats", "Readers and writers for DOT, GraphML, GML, node-link and Cytoscape JSON, Pajek, graph6, sparse6, digraph6, DIMACS, METIS, Matrix Market, edge lists, adjacency lists and Mermaid flowcharts, with their own UTF-8, XML and JSON scanners (no Foundation).", ["GraphProtocols"]),
]

# Test targets. SwiftPM rejects a target with no sources, so list a target only once its directory
# holds tests. (name, dependencies)
TEST_TARGETS = [
    ("GrafluentTestSupportTests", ["GraphProtocols", "GrafluentTestSupport"]),
    ("AdjacencyListTests", ["GraphProtocols", "AdjacencyListModule", "GrafluentTestSupport", "swift-property-based/PropertyBased"]),
    ("UndirectedAdjacencyListTests", ["GraphProtocols", "AdjacencyListModule", "GrafluentTestSupport"]),
    ("PackedCompressedSparseRowTests", ["GraphProtocols", "PackedCompressedSparseRowModule", "AdjacencyListModule", "CompressedSparseRowModule", "Traversal", "ShortestPaths", "Connectivity", "GrafluentTestSupport", "swift-property-based/PropertyBased"]),
    ("CompressedSparseRowTests", ["GraphProtocols", "CompressedSparseRowModule", "AdjacencyListModule", "AdjacencyMatrixModule", "GrafluentTestSupport", "swift-property-based/PropertyBased"]),
    ("AdjacencyMatrixTests", ["GraphProtocols", "AdjacencyMatrixModule", "AdjacencyListModule", "GrafluentTestSupport", "swift-collections/BitCollections", "swift-property-based/PropertyBased"]),
    ("EdgeListTests", ["GraphProtocols", "EdgeListModule", "AdjacencyListModule", "AdjacencyMatrixModule", "CompressedSparseRowModule", "GrafluentTestSupport"]),
    ("TraversalTests", ["GraphProtocols", "Traversal", "AdjacencyListModule", "AdjacencyMatrixModule", "CompressedSparseRowModule", "Multigraphs", "StableGraphs", "GraphOperations", "Hypergraphs", "GrafluentTestSupport", "swift-property-based/PropertyBased", "Walks", "Trees"]),
    ("PriorityQueueTests", ["PriorityQueueModule", "GrafluentTestSupport", "swift-property-based/PropertyBased"]),
    ("DisjointSetTests", ["DisjointSetModule", "GrafluentTestSupport"]),
    ("LinkCutTreeTests", ["LinkCutTreeModule", "GrafluentTestSupport", "swift-property-based/PropertyBased"]),
    ("ShortestPathsTests", ["GraphProtocols", "ShortestPaths", "Traversal", "AdjacencyListModule", "AdjacencyMatrixModule", "CompressedSparseRowModule", "DirectedAcyclicGraphModule", "Multigraphs", "StableGraphs", "GrafluentTestSupport", "swift-property-based/PropertyBased", "Walks", "Trees", "Semirings"]),
    ("SpanningTreesTests", ["GraphProtocols", "SpanningTrees", "AdjacencyListModule", "AdjacencyMatrixModule", "CompressedSparseRowModule", "Multigraphs", "StableGraphs", "GrafluentTestSupport", "swift-property-based/PropertyBased", "Trees"]),
    ("WalksTests", ["GraphProtocols", "Walks", "AdjacencyListModule", "AdjacencyMatrixModule", "CompressedSparseRowModule", "GrafluentTestSupport", "swift-property-based/PropertyBased"]),
    ("CyclesTests", ["GraphProtocols", "Cycles", "Walks", "Traversal", "AdjacencyListModule", "AdjacencyMatrixModule", "CompressedSparseRowModule", "Multigraphs", "StableGraphs", "GrafluentTestSupport", "swift-property-based/PropertyBased"]),
    ("TreesTests", ["GraphProtocols", "Trees", "Walks", "Cycles", "AdjacencyListModule", "CompressedSparseRowModule", "GrafluentTestSupport", "swift-property-based/PropertyBased"]),
    ("TreeAlgorithmsTests", ["GraphProtocols", "Trees", "TreeAlgorithms", "Walks", "AdjacencyListModule", "GrafluentTestSupport", "swift-property-based/PropertyBased"]),
    ("DistancesTests", ["GraphProtocols", "Distances", "Walks", "Trees", "TreeAlgorithms", "AdjacencyListModule", "AdjacencyMatrixModule", "CompressedSparseRowModule", "GrafluentTestSupport", "swift-property-based/PropertyBased"]),
    ("CliquesTests", ["GraphProtocols", "Cliques", "AdjacencyListModule", "AdjacencyMatrixModule", "CompressedSparseRowModule", "GrafluentTestSupport", "swift-property-based/PropertyBased", "Walks", "Traversal", "Multigraphs"]),
    ("CommunityDetectionTests", ["GraphProtocols", "CommunityDetection", "Centrality", "AdjacencyListModule", "AdjacencyMatrixModule", "CompressedSparseRowModule", "Connectivity", "GrafluentTestSupport", "swift-property-based/PropertyBased"]),
    ("BipartiteGraphsTests", ["GraphProtocols", "BipartiteGraphs", "Walks", "AdjacencyListModule", "AdjacencyMatrixModule", "CompressedSparseRowModule", "GrafluentTestSupport", "swift-property-based/PropertyBased"]),
    ("MatchingModuleTests", ["GraphProtocols", "MatchingModule", "BipartiteGraphs", "AdjacencyListModule", "AdjacencyMatrixModule", "CompressedSparseRowModule", "GrafluentTestSupport", "swift-property-based/PropertyBased"]),
    ("CoveringTests", ["GraphProtocols", "Covering", "MatchingModule", "BipartiteGraphs", "AdjacencyListModule", "AdjacencyMatrixModule", "CompressedSparseRowModule", "GrafluentTestSupport", "swift-property-based/PropertyBased"]),
    ("MultigraphsTests", ["GraphProtocols", "Multigraphs", "AdjacencyListModule", "GrafluentTestSupport", "swift-property-based/PropertyBased"]),
    ("ColoringModuleTests", ["GraphProtocols", "ColoringModule", "BipartiteGraphs", "AdjacencyListModule", "AdjacencyMatrixModule", "CompressedSparseRowModule", "GrafluentTestSupport", "swift-property-based/PropertyBased"]),
    ("FlowsTests", ["GraphProtocols", "Flows", "Trees", "Walks", "Multigraphs", "StableGraphs", "AdjacencyListModule", "AdjacencyMatrixModule", "CompressedSparseRowModule", "GrafluentTestSupport", "swift-property-based/PropertyBased"]),
    ("ToursTests", ["GraphProtocols", "Tours", "Walks", "Multigraphs", "AdjacencyListModule", "AdjacencyMatrixModule", "CompressedSparseRowModule", "GrafluentTestSupport", "swift-property-based/PropertyBased"]),
    ("CentralityTests", ["GraphProtocols", "Centrality", "AdjacencyListModule", "AdjacencyMatrixModule", "CompressedSparseRowModule", "GrafluentTestSupport", "swift-property-based/PropertyBased"]),
    ("ParallelCentralityTests", ["GraphProtocols", "Centrality", "ParallelCentrality", "AdjacencyListModule", "AdjacencyMatrixModule", "CompressedSparseRowModule", "Multigraphs", "StableGraphs", "GrafluentTestSupport", "swift-property-based/PropertyBased"]),
    ("ConnectivityTests", ["GraphProtocols", "Connectivity", "Traversal", "AdjacencyListModule", "AdjacencyMatrixModule", "CompressedSparseRowModule", "GrafluentTestSupport", "swift-property-based/PropertyBased", "Trees"]),
    ("StableGraphsTests", ["GraphProtocols", "StableGraphs", "Multigraphs", "Traversal", "Connectivity", "ShortestPaths", "AdjacencyListModule", "GrafluentTestSupport", "swift-property-based/PropertyBased"]),
    ("LabeledGraphsTests", ["GraphProtocols", "LabeledGraphs", "CompressedSparseRowModule", "AdjacencyMatrixModule", "AdjacencyListModule", "Multigraphs", "StableGraphs", "Traversal", "Connectivity", "ShortestPaths", "SpanningTrees", "Centrality", "Flows", "Distances", "GrafluentTestSupport", "swift-property-based/PropertyBased", "swift-collections/OrderedCollections"]),
    ("DirectedAcyclicGraphTests", ["GraphProtocols", "DirectedAcyclicGraphModule", "AdjacencyListModule", "Multigraphs", "StableGraphs", "Traversal", "Connectivity", "ShortestPaths", "Walks", "GrafluentTestSupport", "swift-property-based/PropertyBased"]),
    ("NamedGraphsTests", ["GraphProtocols", "NamedGraphs", "AdjacencyListModule", "AdjacencyMatrixModule", "CompressedSparseRowModule", "Multigraphs", "StableGraphs", "Trees", "BipartiteGraphs", "GrafluentTestSupport", "swift-property-based/PropertyBased"]),
    ("RandomGraphsTests", ["GraphProtocols", "RandomGraphs", "NamedGraphs", "BipartiteGraphs", "AdjacencyListModule", "AdjacencyMatrixModule", "CompressedSparseRowModule", "Multigraphs", "StableGraphs", "Trees", "DirectedAcyclicGraphModule", "GrafluentTestSupport", "swift-property-based/PropertyBased"]),
    ("GraphOperationsTests", ["GraphProtocols", "GraphOperations", "AdjacencyListModule", "AdjacencyMatrixModule", "CompressedSparseRowModule", "Multigraphs", "StableGraphs", "DirectedAcyclicGraphModule", "Traversal", "Connectivity", "ShortestPaths", "GrafluentTestSupport", "swift-property-based/PropertyBased"]),
    ("GraphProductsTests", ["GraphProtocols", "GraphProducts", "AdjacencyListModule", "CompressedSparseRowModule", "Multigraphs", "StableGraphs", "NamedGraphs", "Traversal", "Connectivity", "ShortestPaths", "GrafluentTestSupport", "swift-property-based/PropertyBased"]),
    ("GraphProtocolsTests", ["GraphProtocols", "Traversal", "AdjacencyListModule", "AdjacencyMatrixModule", "CompressedSparseRowModule", "EdgeListModule", "GrafluentTestSupport", "swift-collections/BitCollections", "swift-property-based/PropertyBased"]),
    ("FunctionalGraphsTests", ["GraphProtocols", "FunctionalGraphs", "Multigraphs", "LabeledGraphs", "Traversal", "Connectivity", "ShortestPaths", "Walks", "GrafluentTestSupport", "swift-property-based/PropertyBased"]),
    ("ImplicitGraphsTests", ["GraphProtocols", "ImplicitGraphs", "Multigraphs", "CompressedSparseRowModule", "LabeledGraphs", "Traversal", "Connectivity", "ShortestPaths", "Walks", "GrafluentTestSupport", "swift-property-based/PropertyBased"]),
    ("IsomorphismTests", ["GraphProtocols", "IsomorphismModule", "AdjacencyListModule", "AdjacencyMatrixModule", "CompressedSparseRowModule", "Multigraphs", "LabeledGraphs", "RandomGraphs", "GrafluentTestSupport", "swift-property-based/PropertyBased"]),
    ("HypergraphsTests", ["GraphProtocols", "Hypergraphs", "AdjacencyListModule", "Traversal", "Connectivity", "ShortestPaths", "SpanningTrees", "BipartiteGraphs", "Cycles", "GrafluentTestSupport", "swift-property-based/PropertyBased"]),
    ("IncidenceMatrixTests", ["GraphProtocols", "IncidenceMatrixModule", "Hypergraphs", "Multigraphs", "AdjacencyListModule", "GrafluentTestSupport", "swift-property-based/PropertyBased"]),
    ("PlanarityTests", ["GraphProtocols", "Planarity", "Walks", "Multigraphs", "AdjacencyListModule", "AdjacencyMatrixModule", "GrafluentTestSupport", "swift-property-based/PropertyBased"]),
    ("GraphFormatsTests", ["GraphProtocols", "GraphFormats", "AdjacencyListModule", "Multigraphs", "StableGraphs", "GrafluentTestSupport", "swift-property-based/PropertyBased"]),
    ("SemiringsTests", ["Semirings", "ShortestPaths", "GraphProtocols", "Multigraphs", "AdjacencyListModule", "DirectedAcyclicGraphModule", "StableGraphs", "Traversal", "Walks", "GrafluentTestSupport", "swift-property-based/PropertyBased"]),
    ("GraphDrawingTests", ["GraphProtocols", "GraphDrawing", "Cycles", "Trees", "Planarity", "SpectralGraphTheory", "RandomGraphs", "Multigraphs", "AdjacencyListModule", "AdjacencyMatrixModule", "CompressedSparseRowModule", "StableGraphs", "DirectedAcyclicGraphModule", "GrafluentTestSupport", "swift-property-based/PropertyBased"]),
    ("SpectralGraphTheoryTests", ["GraphProtocols", "SpectralGraphTheory", "CompressedSparseRowModule", "AdjacencyListModule", "AdjacencyMatrixModule", "Multigraphs", "GrafluentTestSupport", "swift-property-based/PropertyBased"]),
    ("SimilarityTests", ["GraphProtocols", "Similarity", "AdjacencyListModule", "AdjacencyMatrixModule", "CompressedSparseRowModule", "Multigraphs", "GrafluentTestSupport", "swift-property-based/PropertyBased"]),
    ("AssortativityTests", ["GraphProtocols", "Assortativity", "AdjacencyListModule", "AdjacencyMatrixModule", "CompressedSparseRowModule", "Multigraphs", "GrafluentTestSupport", "swift-property-based/PropertyBased"]),
    ("GrafluentTests", ["Grafluent"]),
]

# Bazel test sizes above the default "small" (60 s timeout), for suites whose solo run takes more
# than about 15 s on a laptop or 30 s on a four-core CI runner, and so can pass 60 s when other
# tests load the machine. "medium" is 300 s.
TEST_SIZES = {name: "medium" for name in [
    "ColoringModuleTests", "DistancesTests", "ShortestPathsTests", "TreesTests", "TreeAlgorithmsTests", "PriorityQueueTests",
    "IsomorphismTests", "SpectralGraphTheoryTests", "GraphFormatsTests", "ConnectivityTests", "StableGraphsTests",
    "AdjacencyMatrixTests", "AdjacencyListTests", "PlanarityTests", "RandomGraphsTests", "TraversalTests",
    "DirectedAcyclicGraphTests", "SpanningTreesTests", "MultigraphsTests",
]}

# Test targets whose speed-reliant tests live in Performance/ under the target's directory: tests
# that pass only if the code is fast enough, because they bound their own wall-clock time
# (ContinuousClock) or run a large or adversarial input under a `.timeLimit` meant to catch a
# complexity regression. Each is built as a target of its own, performance_target(name), with the
# same dependencies, in the same Bazel package. `--config=release` builds and runs only those:
# every other test target and test library is tagged RELEASE_EXCLUDED_TAG, which .bazelrc filters
# out under release. Debug runs both. A `.timeLimit` that only guards a small input against a hang
# does not make a test speed-reliant.
PERFORMANCE_TESTS = [
    "AdjacencyListTests", "AssortativityTests", "BipartiteGraphsTests", "CentralityTests", "ParallelCentralityTests", "CliquesTests", "ColoringModuleTests", "CommunityDetectionTests",
    "CoveringTests", "CyclesTests", "DistancesTests", "FlowsTests", "FunctionalGraphsTests", "GraphDrawingTests",
    "GraphFormatsTests", "GraphOperationsTests", "HypergraphsTests", "ImplicitGraphsTests", "IncidenceMatrixTests",
    "IsomorphismTests", "LabeledGraphsTests", "MatchingModuleTests", "MultigraphsTests", "PackedCompressedSparseRowTests", "PlanarityTests",
    "RandomGraphsTests", "ShortestPathsTests", "SimilarityTests", "SpanningTreesTests", "SpectralGraphTheoryTests", "StableGraphsTests", "ToursTests",
    "TraversalTests", "TreeAlgorithmsTests", "TreesTests",
]

# Performance tests run up to their one-minute limits each, so their targets get "medium" (300 s).
PERFORMANCE_TEST_SIZE = "medium"

# The tag .bazelrc's release config filters out of builds and tests (see PERFORMANCE_TESTS).
RELEASE_EXCLUDED_TAG = "debug-only"


def performance_target(name):
    """The speed-reliant target split from test target `name`: FlowsTests -> FlowsPerformanceTests."""
    return name.removesuffix("Tests") + "PerformanceTests"

# The library modules the differential harness (Differential/, scripts/differential.py) links.
# Both its Package.swift and its BUILD.bazel are written from this list.
DIFFERENTIAL_DEPENDENCIES = ["GraphProtocols", "AdjacencyListModule", "ShortestPaths", "SpanningTrees", "Connectivity", "Walks", "Cycles", "Trees", "TreeAlgorithms", "Distances", "Cliques", "Centrality", "ParallelCentrality", "CommunityDetection", "BipartiteGraphs", "MatchingModule", "Covering", "ColoringModule", "Multigraphs", "Flows", "Tours", "CompressedSparseRowModule", "DirectedAcyclicGraphModule", "Planarity", "Similarity", "Assortativity", "Traversal", "GraphOperations", "NamedGraphs", "RandomGraphs", "IsomorphismModule", "GraphDrawing", "SpectralGraphTheory", "GraphFormats"]

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
    tests = [t[0] for t in TEST_TARGETS]
    for name in PERFORMANCE_TESTS:
        assert name in tests, f"PERFORMANCE_TESTS names unknown test target {name}"


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
    return [f for f in ("BUILD.bazel", "README.md", "Performance") if os.path.exists(os.path.join(root, path, f))]


def exclude_arg(path):
    files = excluded(path)
    if files == ["BUILD.bazel"]:
        return ", exclude: bazelFiles"
    if files:
        return ", exclude: [" + ", ".join(f'"{f}"' for f in files) + "]"
    return ""


def exit_test_files(directory, excludes):
    """Swift files under `directory` (outside `excludes`) that contain an exit test, as a Swift array literal."""
    import os, pathlib
    root = pathlib.Path(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))) / directory
    found = []
    for path in sorted(root.rglob("*.swift")):
        rel = path.relative_to(root).as_posix()
        if any(rel.startswith(e) for e in excludes):
            continue
        if "processExitsWith" in path.read_text(encoding="utf-8"):
            found.append(rel)
    return "[" + ", ".join(f'"{f}"' for f in found) + "]"


def package_swift():
    lines = [
        "// swift-tools-version: 6.3",
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
        "// The WebAssembly test run (scripts/wasi_test.py) sets GRAFLUENT_WASI_TESTS to a comma-separated",
        "// list of test targets: the package then declares only those, as one binary of every target",
        "// passes wasmtime's limit of a million functions, and leaves out each test file with an exit",
        "// test, since WASI cannot start a child process. Unset, nothing changes.",
        'let wasiTests = Context.environment["GRAFLUENT_WASI_TESTS"].map { Set($0.split(separator: ",").map(String.init)) }',
        "",
        "func testExcludes(_ excludes: [String], wasi exitTestFiles: [String]) -> [String] {",
        "    wasiTests == nil ? excludes : excludes + exitTestFiles",
        "}",
        "",
        "// Typed arrays of their own: as one `Package(...)` expression, the manifest is too big for the",
        "// type checker.",
        "let products: [Product] = [",
        '    .library(name: "Grafluent", targets: ["Grafluent"]),',
    ]
    lines += [f'    .library(name: "{m[0]}", targets: ["{m[0]}"]),' for m in MODULES]
    lines += ["]", "", "let dependencies: [Package.Dependency] = ["]
    lines += [f'    .package(url: "{url}", from: "{version}"),' for _, url, version in PACKAGES]
    lines += ["]", "", "let targets: [Target] = ["]
    group = None
    for name, g, _, deps in MODULES:
        if g != group:
            lines.append(f"    // {g}")
            group = g
        ex = exclude_arg(f"Sources/{name}")
        if deps:
            dl = ", ".join(spm_dep(d) for d in deps)
            lines.append(f'    .target(name: "{name}", dependencies: [{dl}]{ex}),')
        else:
            lines.append(f'    .target(name: "{name}"{ex}),')
    all_deps = ", ".join(f'"{m[0]}"' for m in MODULES)
    lines += [
        "",
        "    // Umbrella: `import Grafluent` imports every module.",
        f'    .target(name: "Grafluent", dependencies: [{all_deps}], exclude: bazelFiles),',
        "",
        "    // Shared fixtures, conformance checkers and instrumentation for every test target.",
        '    .target(name: "GrafluentTestSupport", dependencies: ["GraphProtocols"], path: "Tests/GrafluentTestSupport", exclude: bazelFiles),',
        "",
    ]
    for name, deps in TEST_TARGETS:
        dl = ", ".join(spm_dep(d) for d in deps)
        files = excluded(f"Tests/{name}")
        ex = "[" + ", ".join(f'"{f}"' for f in files) + "]" if files != ["BUILD.bazel"] else "bazelFiles"
        lines.append(f'    .testTarget(name: "{name}", dependencies: [{dl}], exclude: testExcludes({ex}, wasi: {exit_test_files(f"Tests/{name}", files)})),')
    lines += [
        "",
        "    // Speed-reliant tests, split from the target of the same module (PERFORMANCE_TESTS in scripts/modules.py).",
    ]
    for name, deps in TEST_TARGETS:
        if name in PERFORMANCE_TESTS:
            dl = ", ".join(spm_dep(d) for d in deps)
            lines.append(f'    .testTarget(name: "{performance_target(name)}", dependencies: [{dl}], path: "Tests/{name}/Performance", exclude: testExcludes([], wasi: {exit_test_files(f"Tests/{name}/Performance", [])})),')
    lines += [
        "]",
        "",
        "let package = Package(",
        '    name: "Grafluent",',
        "    // macOS 15 / iOS 18 is the floor for `Synchronization.Mutex`, used by the test support target.",
        "    // Keep in step with .bazelrc.",
        f"    platforms: {PLATFORMS},",
        "    products: products,",
        "    dependencies: dependencies,",
        "    targets: targets.filter { $0.type != .test || wasiTests?.contains($0.name) ?? true }",
        ")",
        "",
    ]
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
    doc_deps = "".join(f'        "{bazel_label(d)}:{d}Documentation",\n' for d in deps if "/" not in d)
    doc_deps_attr = f"    deps = [\n{doc_deps}    ],\n" if doc_deps else ""
    # The umbrella's catalog gains the cross-module extension index (scripts/extensions.py).
    generator = (
        '    catalog_generator = "//scripts:extensions.py",\n'
        '    catalog_generator_srcs = ["//scripts:modules.py"],\n'
    ) if umbrella else ""
    # The generator writes Extensions/, which is gitignored; a local `just docs` can leave it in the checkout.
    catalog = 'glob(["*.docc/**"], exclude = ["*.docc/Extensions/**"])' if umbrella else 'glob(["*.docc/**"], allow_empty = True)'
    return (
        "# GENERATED by scripts/modules.py — edit the table there, then run `just modules`.\n\n"
        'load("//tools:docc.bzl", "docc_archive")\n'
        'load("//tools:swift_rules.bzl", "swift_library")\n\n'
        f"# {description}\n"
        "swift_library(\n"
        f'    name = "{name}",\n'
        '    srcs = glob(["**/*.swift"]),\n'
        f'    module_name = "{name}",\n'
        f"{deps_attr}"
        '    visibility = ["//visibility:public"],\n'
        ")\n\n"
        "# The module's DocC archive, merged into //:docs. `manual` keeps it out of `bazel build //...`.\n"
        "docc_archive(\n"
        f'    name = "{name}Documentation",\n'
        f'    module = ":{name}",\n'
        f"    catalog = {catalog},\n"
        f"{doc_deps_attr}"
        f"{generator}"
        '    tags = ["manual"],\n'
        '    visibility = ["//visibility:public"],\n'
        ")\n"
    )


def test_targets_bazel(name, deps, size, srcs, tags):
    """One test module: its library, the swift_test that `bazel test` runs, and the Xcode bundle."""
    dl = "".join(f'        "{bazel_label(d)}",\n' for d in deps)
    tags_attr = f"    tags = {tags},\n".replace("'", '"') if tags else ""
    return (
        "swift_library(\n"
        f'    name = "{name}Library",\n'
        "    testonly = True,\n"
        "    # Tests are found through metadata the linker would otherwise drop, since nothing\n"
        "    # references them by name.\n"
        "    alwayslink = True,\n"
        f"    srcs = {srcs},\n"
        f'    module_name = "{name}",\n'
        f"{tags_attr}"
        "    # Read by //:package_swift_test, which checks Package.swift against the Bazel graph.\n"
        '    visibility = ["//:__pkg__"],\n'
        f"    deps = [\n{dl}    ],\n"
        ")\n\n"
        "# `bazel test` / `just test`: a standalone executable, fast to start and run in Bazel's sandbox.\n"
        "swift_test(\n"
        f'    name = "{name}",\n'
        f'    size = "{size}",\n'
        f"{tags_attr}"
        f'    deps = [":{name}Library"],\n'
        ")\n\n"
        "# The generated Xcode project: a real .xctest bundle (an MH_BUNDLE), which is what Xcode's test\n"
        "# runner loads. `manual` keeps it out of `bazel test //...`; it runs through xcodebuild, so it\n"
        "# is only for Xcode. XCTest refuses exit tests in a sandboxed host, hence `no-sandbox`.\n"
        "macos_unit_test(\n"
        f'    name = "{name}Bundle",\n'
        f'    bundle_name = "{name}",\n'
        f'    size = "{size}",\n'
        '    minimum_os_version = "15.0",\n'
        '    tags = ["manual", "no-sandbox"],\n'
        "    # Visible so `//:xcodeproj` can name it as a top-level target.\n"
        '    visibility = ["//visibility:public"],\n'
        f'    deps = [":{name}Library"],\n'
        ")\n"
    )


def test_build_bazel(name, deps):
    size = TEST_SIZES.get(name, "small")
    header = (
        "# GENERATED by scripts/modules.py — edit the table there, then run `just modules`.\n\n"
        'load("@rules_apple//apple:macos.bzl", "macos_unit_test")\n'
        'load("//tools:swift_rules.bzl", "swift_library", "swift_test")\n\n'
    )
    excluded = (
        f"Tagged `{RELEASE_EXCLUDED_TAG}`: none of these relies on speed, so\n"
        "# `--config=release` neither builds nor runs them (.bazelrc).\n"
    )
    if name not in PERFORMANCE_TESTS:
        return (header + "# The tests, built once and linked into two runners.\n# " + excluded
                + test_targets_bazel(name, deps, size, 'glob(["**/*.swift"])', [RELEASE_EXCLUDED_TAG]))
    return (
        header
        + "# The tests, built once and linked into two runners; the speed-reliant ones, in Performance/, are\n"
        + f"# {performance_target(name)} below. " + excluded
        + test_targets_bazel(name, deps, size, 'glob(["**/*.swift"], exclude = ["Performance/**"])', [RELEASE_EXCLUDED_TAG])
        + "\n# The speed-reliant tests (PERFORMANCE_TESTS in scripts/modules.py): debug and `--config=release`\n"
        + "# both run them.\n"
        + test_targets_bazel(performance_target(name), deps, PERFORMANCE_TEST_SIZE, 'glob(["Performance/**/*.swift"])', [])
    )


def performance_tests_bzl():
    packages = "".join(f'    "Tests/{name}",\n' for name in PERFORMANCE_TESTS)
    return (
        '"""GENERATED by scripts/modules.py (PERFORMANCE_TESTS) — edit the list there, then run `just modules`."""\n\n'
        "# The test packages that also hold a speed-reliant target, `<Name>PerformanceTests` built from\n"
        "# Performance/, which the root BUILD.bazel cannot find from the directory layout alone.\n"
        f"PERFORMANCE_TEST_PACKAGES = [\n{packages}]\n"
    )


def differential_package_swift():
    deps = ", ".join(f'"{d}"' for d in DIFFERENTIAL_DEPENDENCIES)
    return (
        "// swift-tools-version: 6.3\n"
        "import PackageDescription\n\n"
        "// GENERATED by scripts/modules.py (DIFFERENTIAL_DEPENDENCIES): edit the list there, then run `just modules`.\n"
        "//\n"
        "// Differential testing against NetworkX, scipy, rustworkx and igraph: this executable answers a\n"
        "// batch of queries with the library, and scripts/differential.py asks the reference libraries\n"
        "// the same questions and compares. In its own package so the library never depends on\n"
        "// Foundation's JSON coding.\n"
        "// `just diff` builds it through Bazel (Differential/BUILD.bazel); this package is the\n"
        "// `--swiftpm` fallback. See Differential/README.md.\n\n"
        f"let products: [Target.Dependency] = [{deps}].map {{ .product(name: $0, package: \"Grafluent\") }}\n\n"
        "let package = Package(\n"
        '    name: "GrafluentDifferential",\n'
        "    platforms: [.macOS(.v15)],\n"
        '    dependencies: [.package(path: "..")],\n'
        '    targets: [.executableTarget(name: "GrafluentDifferential", dependencies: products)]\n'
        ")\n"
    )


def differential_build_bazel():
    dl = "".join(f'        "{bazel_label(d)}",\n' for d in DIFFERENTIAL_DEPENDENCIES)
    return (
        "# GENERATED by scripts/modules.py (DIFFERENTIAL_DEPENDENCIES) — edit the list there, then run\n"
        "# `just modules`.\n\n"
        'load("//tools:swift_rules.bzl", "swift_binary")\n\n'
        "# The library side of `just diff` (scripts/differential.py builds it with --config=release).\n"
        "# `manual` keeps it out of `bazel build //...`.\n"
        "swift_binary(\n"
        '    name = "GrafluentDifferential",\n'
        '    srcs = glob(["Sources/GrafluentDifferential/**/*.swift"]),\n'
        '    module_name = "GrafluentDifferential",\n'
        f"    deps = [\n{dl}    ],\n"
        '    tags = ["manual"],\n'
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
                f.write(f"// {name}: {description}\n")
    for name, deps in TEST_TARGETS:
        d = os.path.join(root, "Tests", name)
        os.makedirs(d, exist_ok=True)
        with open(os.path.join(d, "BUILD.bazel"), "w") as f:
            f.write(test_build_bazel(name, deps))
        # SwiftPM rejects a target with no sources, and one left out of PERFORMANCE_TESTS would be
        # compiled into the module's own target, which release skips.
        performance = os.path.join(d, "Performance")
        has_performance = any(fn.endswith(".swift") for _, _, fns in os.walk(performance) for fn in fns)
        assert has_performance == (name in PERFORMANCE_TESTS), \
            f"{name}: Performance/ holds Swift sources exactly when the target is in PERFORMANCE_TESTS"
    with open(os.path.join(root, "tools", "performance_tests.bzl"), "w") as f:
        f.write(performance_tests_bzl())
    d = os.path.join(root, "Sources", "Grafluent")
    os.makedirs(d, exist_ok=True)
    names = [m[0] for m in MODULES]
    with open(os.path.join(d, "BUILD.bazel"), "w") as f:
        f.write(build_bazel("Grafluent", "Umbrella: `import Grafluent` imports every module.", names, umbrella=True))
    with open(os.path.join(d, "Grafluent.swift"), "w") as f:
        f.write("// GENERATED by scripts/modules.py.\n//\n// Umbrella: `import Grafluent` imports every module.\n\n")
        f.write("".join(f"@_exported import {n}\n" for n in names))
    with open(os.path.join(root, "swift", "Package.swift"), "w") as f:
        f.write(dependency_manifest())
    with open(os.path.join(root, "Differential", "BUILD.bazel"), "w") as f:
        f.write(differential_build_bazel())
    with open(os.path.join(root, "Differential", "Package.swift"), "w") as f:
        f.write(differential_package_swift())
    # Written last: which files each target must exclude depends on the BUILD files above.
    with open(os.path.join(root, "Package.swift"), "w") as f:
        f.write(package_swift())


if __name__ == "__main__":
    main()
