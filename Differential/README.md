# Differential testing

Runs the library and independent implementations on the same random graphs and compares the
answers. The references are NetworkX 3.7, scipy 1.18.1, rustworkx 0.18.1 and python-igraph 1.0.0,
pinned and run through `uv`, so nothing is installed globally.

| Command | Does |
|---|---|
| `just diff` | 2,000 random cases with a random seed, every module (about 2 min) |
| `just diff --cases 20000 --seed 7` | More cases, reproducibly |
| `just diff --module Coloring` | Only one module's queries and comparisons (about 20 s for Coloring); repeat the flag for several |
| `just diff --swiftpm` | Build the library side with SwiftPM instead of Bazel |

`GrafluentDifferential` (this package) reads a batch of cases as JSON and answers them with the
library; `scripts/differential.py` generates the cases, asks NetworkX (and scipy's `csgraph`,
rustworkx and python-igraph where they apply) the same questions, and compares.

The executable is built through Bazel, `//Differential:GrafluentDifferential` (a `manual`
`swift_binary`), with `--config=release` in the output base `just test-release` uses, so the
remote cache serves the library and a run only compiles what changed. `scripts/modules.py`
writes its BUILD.bazel and Package.swift from one dependency list. The SwiftPM package serves
`--swiftpm`.

`--module` takes a library module's name, with or without its `Module` suffix and ignoring case
(Trees and TreeAlgorithms are one section; `just diff --help` lists them). The cases are generated
the same way whatever is chosen, so a seed gives the same graphs in a one-module run as in a full
one; the executable skips the other modules' calls, and the script skips their references and
comparisons. Iterate on a module with `--module`, and run everything before it ships.

## What is compared

Only what ties cannot change: distances, reachability, whether a negative cycle is reachable or
exists anywhere, and the validity of every path and witness the library returns (each step an
edge, the stated length, a negative simple cycle reachable from a source). Parents and the
choice among equal paths are not compared, since correct implementations differ there.

Where two references answer the same question (Dijkstra in NetworkX and scipy), a disagreement
between them is reported on its own: it means a convention differs, not that the library is wrong.

| Library | NetworkX | scipy |
|---|---|---|
| `dijkstraShortestPaths(from:cutoff:weight:)` | `multi_source_dijkstra_path_length(cutoff:)` | `csgraph.dijkstra(indices:, min_only=True, limit:)` |
| `dijkstraShortestPath(from:to:weight:)` | `dijkstra_path_length`; the path is checked | — |
| `bellmanFordShortestPaths(from:weight:)` | `single_source_bellman_ford_path_length` from a super-source with zero edges to the sources; `NetworkXUnbounded` is `nil` | — |
| `findNegativeCycle(from:weight:)`, `findNegativeCycle(weight:)` | unbounded above; `negative_edge_cycle` | — |
| `shortestPaths(from:)` | `single_source_shortest_path_length`, nearest source | — |
| `shortestSimplePaths(from:to:weight:)`, first 8 | `shortest_simple_paths` lengths; each path checked simple and of its length | — |
| `allShortestPaths(from:to:weight:)` | `all_shortest_paths` count (up to 5 000, positive weights only: NetworkX lists a path twice when a zero-weight cycle runs through the source) and `dijkstra_path_length`; each path checked, none repeated | — |
| `bidirectionalDijkstraShortestPath(from:to:weight:)` | `bidirectional_dijkstra` distance; the path checked | — |
| `allPairsDijkstraShortestPaths(weight:)`, `johnsonShortestPaths(weight:)` (n ≤ 40) | `all_pairs_dijkstra_path_length`; `floyd_warshall`, `nil` exactly when `negative_edge_cycle` (undirected: a negative edge); every path checked | — |
| `simpleCycles()`, `simpleCycles(maxLength: 3)` (both kinds) | `simple_cycles`, `simple_cycles(length_bound=3)`, as vertex cycles up to rotation (and reversal, undirected), when there are at most 3 000; also canonical form, order by least vertex, and the bounded sequence equal to the unbounded one filtered | — |
| `girth()` (both kinds) | `girth`; directed, a breadth-first search back to each vertex | — |
| `nontrivialStronglyConnectedComponents()` (directed); `hasSelfLoops`, `verticesWithSelfLoops()`, `selfLoopEdges()` (both kinds), in the connectivity section | `strongly_connected_components` kept where a component has two vertices or a self-loop, as sets, and in the order of the library's own `stronglyConnectedComponents()`; `nodes_with_selfloops`, `selfloop_edges` (in order) and `number_of_selfloops` | — |
| `isAcyclic`, `findCycle()` | `is_forest`; the cycle must exist exactly when the graph is not a forest, valid and canonical | — |
| `cycleBasis()` | m − n + c cycles (`number_connected_components`), independent over GF(2), each valid and canonical (NetworkX's Paton basis differs and is not compared) | — |
| `isTree`, `Tree(g)`, `Forest(g)`, `isArborescence` | `is_tree`, `is_forest`, `is_arborescence`; for trees, `pruferSequence`, `preorder` / `postorder` / depths / `height` / `path(from:to:)` rooted at the first source against `dfs_preorder_nodes`, `dfs_postorder_nodes`, `shortest_path`; a forest's `trees` against `connected_components` | — |
| TreeAlgorithms on trees | `tree_all_pairs_lowest_common_ancestor` for every pair; `center`, `diameter` (unweighted and weighted), `tree.centroid`; heavy–light segments expanded against the path; centroid decomposition height ≤ ⌊log₂ n⌋ | — |
| Distances (both kinds, unweighted and weighted) | eccentricities by searches from every vertex (nil where one misses), radius, diameter, center, periphery, the least-total centroid; `wiener_index`, `average_shortest_path_length`, `density`, `diameter`, `radius` where connected; the diameter path's endpoints and length | — |
| Cliques (undirected) | `find_cliques` as a set, and the exact documented order against a port of the order's model; the clique number and the lexicographically least maximum clique; `core_number`, `triangles`, `clustering`, `transitivity`, `average_clustering` on the graph without loops | — |
| Coloring (the simple undirected graph: loops dropped, a directed case's two arcs once) | `greedy_color` with `largest_first` and `saturation_largest_first`, exactly; smallest last, independent set and connected sequential (undirected cases) exactly through callable strategies with least-vertex ties (NetworkX's own break ties in set order); `greedyColoring(order:)`; every result proper within Δ + 1, smallest last within degeneracy + 1 (`core_number`); `chromaticNumber()` between ω and every greedy count, ≤ 2 exactly when `is_bipartite`, with `minimumColoring()` proper, χ colours, numbered by first appearance, and `lexicographicallyFirstMinimumColoring()` against plain backtracking per component of ≤ 12 vertices; Misra–Gries proper with Δ or Δ + 1 colours; König nil exactly when the multigraph is not bipartite, else proper with exactly Δ counting parallel edges; `isColoring`, `isEdgeColoring` on fixed colourings | — |
| Flows (scripts/differential_flows.py), on a multigraph per case: the case's edges with capacity \|w\| and cost w, then a parallel copy of every fourth (reversed when undirected) | maximum-flow values against `maximum_flow_value` and igraph `maxflow`; every cut's sink side against `minimum_cut`'s partition, its edges and value against its sides; every flow's capacity and conservation; Edmonds–Karp's flow against ref.py's model of the procedure; the global cut's value against igraph maxflow values (min over vertex 0 and each other vertex), its sides against ref.py's Stoer–Wagner and cyclic-pair models; Gomory–Hu trees against `gomory_hu_tree` (n ≤ 50) and every queried pair against igraph `maxflow`; minimum-cost and min-cost max flows against `network_simplex` (feasibility and cost), each flow checked and its potentials' certificate; λ against igraph `edge_connectivity` (parallel edges counted), κ against igraph `vertex_connectivity` and `node_connectivity(s, t)`, vertex cuts against ref.py's models. Before the random cases, every row of Tests/Catalogs/Flows/cases.md is replayed (`GrafluentDifferential flows-catalog`), traps one per process | — |
| Planarity (the case's edges as an undirected multigraph: a directed case's arcs as edges, loops kept) | `check_planarity` on the simple graph for `isPlanar`, and on the graph plus an apex for `isOuterplanar`; `planarEmbedding()` and `findKuratowskiSubgraph()` present exactly when they should be; the embedding's face count against Euler's formula over every edge (m − n′ + 2c) and its rotations and face sides against the definitions; the witness made of the graph's edges, with no loop or repeated pair, and isomorphic to K₅ or K₃,₃ as its kind says once its degree-2 vertices are suppressed (`is_isomorphic`) | — |
| GraphOperations | `power` (undirected) and shortest-path lengths with a cutoff (directed) for `power(of:_:)` at k = 2 and 3; `ego_graph` at radius 2 from the first source, vertices and edges (directed also with `undirected=True`); `contracted_nodes` of the first source and the target, without loops, renumbered as documented; `transitive_closure` without loops; the reduction checked for the closure's reachability and the fewest arcs (nontrivial component sizes plus `transitive_reduction` of the `condensation`), and equal to `transitive_reduction` on acyclic cases; `relabel_nodes` by v mod 3; `compose`, `intersection`, `difference` and `symmetric_difference` with the case shifted by one (mod n) | — |
| Assortativity (directed: the case's digraph, loops kept; undirected: loops dropped where NetworkX's loop conventions differ) | `degree_assortativity_coefficient` for every x, y in in/out (undirected: plain), plain and weighted, with nil checked against a model that the coefficient is undefined; `attribute_assortativity_coefficient` (v mod 3) and `numeric_assortativity_coefficient` (7v mod 11); `average_neighbor_degree` for every source and target, plain and weighted; `average_degree_connectivity` for source in or out (and undirected); `overall_reciprocity` and per-vertex `reciprocity` on the loopless digraph; `triadic_census`; in- and out-degree histograms, `degree_histogram`, `is_regular`, `s_metric`; `rich_club_coefficient(normalized=False)`; `global_efficiency` and `local_efficiency` | — |
| GraphFormats (its own requests from each case: awkward names, typed attributes, parallel edges where the format holds them) | GML, Pajek, Cytoscape JSON and the delimited edge list written by the library and read by NetworkX, and NetworkX's `generate_gml`, `generate_pajek`, `cytoscape_data` and `generate_edgelist(data=True)` read by the library; GML, Pajek and Cytoscape JSON byte for byte against NetworkX's writers (edges as a multiset); graph6 byte for byte against `to_graph6_bytes` and read back; sparse6 against an encoder from nauty's formats.txt, decoded by `from_sparse6_bytes` (n ≥ 2), and `to_sparse6_bytes` read back; digraph6, DIMACS (`sp`, `edge`) and METIS against writers and parsers from their definitions; node-link JSON with tuple nodes read as their canonical JSON text | NetworkX's sparse6 padding and its 1-bit numbers for n ≤ 1 (nauty is followed); its Pajek writer leaves `'` unquoted |
| IsomorphismModule (cases with n ≤ 6 and at most 10 edges) | `graph_edit_distance` between the case's graph and its partner (vertices 0..<max(n − 1, 1); the edges at offsets k with k mod 3 ≠ 2, ends mod n′, repeats dropped; then 0–(n′ − 1)), at unit costs and with `node_match` on v mod 2; each path costing what its operations add up to, edges substituted only between images. With a self-loop in either graph NetworkX can substitute a loop for a non-loop and report less, so those cases are compared with brute force over every partial injection (NetworkX must not exceed it) | — |
| NamedGraphs and RandomGraphs (the generators section; the inputs are derived from each case by a stable hash: its degree sequences, often perturbed, and parameters for every family, the random ones drawn from one seed) | `is_graphical` and `is_digraphical` for `isGraphical` and `isDigraphical`; `havel_hakimi_graph` (its vertices of nonzero degree renumbered to the sequence's indices, see below) and `directed_havel_hakimi_graph` edge for edge; on the same stream (`StreamRandom` of Tests/Catalogs/RandomGraphs/ref.py): `configuration_model` and `directed_configuration_model` as multisets (and in order against the catalog's port), `expected_degree_graph(selfloops=False)`, `newman_watts_strogatz_graph`, `connected_watts_strogatz_graph` (nil where it raises), `random_uniform_k_out_graph(self_loops=False, with_replacement=False)`, `scale_free_graph` and `bipartite.gnmk_random_graph` (when its right side's set iterates in order) edge for edge; Holme–Kim against the catalog's port, with m(n − m) edges and m older neighbors per later vertex; `circulant_graph`, `generalized_petersen_graph`, `kneser_graph`, `windmill_graph`, `binomial_tree`, `full_rary_tree`, `triangular_lattice_graph`, `hexagonal_lattice_graph`, `LCF_graph` and the LCF-named graphs edge for edge, igraph's `De_Bruijn` and `Kautz` edge for edge, and the icosahedral, Frucht, Tutte and Hoffman–Singleton graphs by `is_isomorphic` | — |
| SpectralGraphTheory (weights \|w\|; the case's edges as an undirected multigraph, a directed case's arcs as edges, loops kept) | The k = min(3, n) extreme eigenpairs (L both ends, N smallest, A both ends, Q largest) against `scipy.linalg.eigh` of the matrices built from their definitions, those checked against `laplacian_matrix`, `normalized_laplacian_matrix` and `adjacency_matrix` on loopless cases (NetworkX adds a loop to A once, the library twice); eigenvalues to 1e-6, eigenvectors up to sign as their projection on the reference eigenspace (eigenvalues within 1e-3 of the scale grouped); `incidence_matrix(oriented=)` exactly, loop columns apart (NetworkX's are empty; the library's hold 2 unoriented); `modularity_matrix` on loopless cases and A − k kᵀ / vol otherwise (n ≤ 60); hitting times both ways and the commute time against a dense solve of (I − P) h = 1; on directed cases the stationary distribution against the lazy walk's limit from the uniform distribution (repeated squaring) and `pagerank(alpha=1)` where it is unique, `incidence_matrix(oriented=True)` and `directed_modularity_matrix` | `scipy.linalg.eigh` |
| CommunityDetection's spectral clustering (scripts/differential_communities.py; a planted partition derived from each case by a stable hash) | 2 to 4 planted blocks (10 to 40 vertices, inside 0.7, across 0.002, every vertex with at least three neighbours in its block and three times as many as outside) recovered with adjusted Rand index 1 | — |

NetworkX 3.7's `havel_hakimi_graph` numbers the vertices of nonzero degree 0, 1, … in order, so when a
zero comes before the last nonzero degree its graph has edges at the wrong vertices (vertices of
degree 0 among them). The comparison maps its vertex i to the i-th vertex of nonzero degree.

Cases: simple graphs on 0..<n (n ≤ 30, every tenth ≤ 300), directed or undirected, self-loops
allowed, sparse, dense, chains and grids, weights from {0…1, 0…3, 0…10, 0…1000} and in 30 % of
cases a few negative ones (half of the directed ones acyclic, so the distances are finite, some
with a negative cycle elsewhere), one to three sources, a cutoff in 30 %. The run prints how many
cases fell in each class.

A disagreement is written to `Differential/Failures/` (not committed) with the case and what
differed; it becomes a test in the module's suite, and then the file is deleted.
