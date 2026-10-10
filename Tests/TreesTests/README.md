# Trees test suite

`Trees` holds four immutable value types whose invariant is the type: `Tree` (connected, acyclic,
undirected, at least one vertex), `RootedTree` (a `Tree` with a root), `Arborescence` (every arc
points away from the root) and `Forest` (acyclic, possibly empty). The first three and `Forest` are
`Graph`s; `Arborescence` is a `BidirectionalDirectedGraph`. Beside them: the predicates
`Graph.isTree` and `DirectedGraph.isArborescence`, construction from a graph, from vertices and
edges, from a parent function, and from another tree type; the rooted queries; `path(from:to:)` as a
Walks `Path<Vertex, Int>`; `Forest.trees` and `component(of:)`; and Prüfer codes. The tests were
written before the implementation, from the proposed API (`api.md`, phase 1). The suite uses only
the public API and is self-contained per test; shared material is the `ReferencePseudograph` and
`ReferenceDirectedMultigraph` test conformers, `Collider`, `HashableBox`, `MinimalSequence`, the
seeded generator and the tags in `GrafluentTestSupport`. Conformers private to a file model
representations the package does not have (rows out of position order, no indices, an implicit
10⁶-vertex path, vertices that count their hashes).

## API under test

```swift
extension Graph { var isTree: Bool }                                 // n ≥ 1, connected, acyclic; loops and parallel pairs are cycles
extension DirectedGraph { var isArborescence: Bool }                 // one root of in-degree 0, the rest 1, all reached

struct Tree<Vertex: Hashable>: Graph
    init?(_ graph: some Graph<Vertex>)                                // the graph's vertex order and edge positions
    init?(edges:), init?(vertices:edges:)                            // listed vertices (repeats dropped), then endpoints
    init(_ tree: RootedTree<Vertex>)
    func path(from:to:) -> Path<Vertex, Int>                         // traps on a non-vertex
    var pruferSequence: [Vertex]?                                    // by vertex index; nil for n < 2
extension Tree where Vertex == Int { init?(pruferSequence: some Sequence<Int>) }

struct RootedTree<Vertex: Hashable>: Graph
    init(_ tree: Tree<Vertex>, root:)                                // traps when root is not a vertex
    init?(_ graph: some Graph<Vertex>, root:)                        // traps when root is not a vertex
    init(_ arborescence: Arborescence<Vertex>)
    init?<E>(vertices:parent: (Vertex) throws(E) -> Vertex?) throws(E)
    init?(parents: [Int?])                                           // Vertex == Int
    root, parent(of:), parentEdge(of:), children(of:), depth(of:), height,
    preorder, postorder, descendants(of:), ancestors(of:), isAncestor(_:of:),
    path(from:to:), rootIndex, parent(ofIndex:), depth(ofIndex:)

struct Arborescence<Vertex: Hashable>: BidirectionalDirectedGraph
    init?(_ graph: some DirectedGraph<Vertex>), init?(edges:), init?(vertices:edges:)
    init(_ tree: RootedTree<Vertex>)                                 // arcs parent → child at the tree's positions
    init?<E>(vertices:parent:) throws(E), init?(parents: [Int?])
    the rooted queries above; path(from:to:) -> Path<Vertex, Int>?  // nil unless downward

struct Forest<Vertex: Hashable>: Graph
    init(), init?(_ graph:), init?(edges:), init?(vertices:edges:), init(_ tree: Tree<Vertex>)
    var trees: Trees                                                 // RandomAccessCollection<Tree<Vertex>>, by least vertex
    func component(of:) -> Int
    func path(from:to:) -> Path<Vertex, Int>?                        // nil across trees
// All four: Equatable, Hashable, Codable, Sendable (when Vertex is), descriptions
```

## Conventions

| Question | Choice | Cases |
|---|---|---|
| Null graph | Not a tree (no empty `Tree`, `RootedTree` or `Arborescence`); the empty `Forest` exists | TS-001 – TS-004, TS-050, TS-159, TS-405 |
| Failure | Unchecked input gives `nil`; a root or query vertex that is not a vertex traps | §A – §D, TS-109, TS-246, TS-315 |
| Vertex order | The graph's `vertices`; from `vertices:edges:`, the listed vertices with repeats dropped, then endpoints by first appearance; from a parent function, `vertices` with repeats dropped | TS-100 – TS-103, TS-165 |
| Edge positions | The graph's positions; from a parent function one edge per non-root vertex, in vertex order, `(parent, child)`; Prüfer decoding in decoding order | TS-030, TS-063, TS-151, TS-163, TS-501 |
| Rows | Rebuilt in position order whatever the source's row order; `children(of:)` is the row without the parent edge | TS-105, TS-219, TS-225, representation tests |
| Orders | `preorder` root then each child's subtree in `children` order; `postorder` likewise with each vertex after its subtree; `descendants(of:)` a preorder slice without the vertex; `ancestors(of:)` parent first | §E |
| `isAncestor` | Strict | TS-215 |
| Paths | Up to the meeting vertex then down, with positions; independent of the root; on an `Arborescence` only downward; on a `Forest` nil across trees | §F |
| Forest | `trees` by least vertex in `vertices` order; each tree's vertices and edges in the forest's order, edges renumbered from 0 | §G |
| Prüfer | Least leaf by vertex index (not value); nil for n < 2; decoding rejects elements outside `0..<count+2` | §H |
| Equality | Vertex set and edge set; undirected orientation ignored; `RootedTree` adds the root; `Arborescence` compares ordered arcs | §J |

## How values are pinned

Every catalog row is written as the catalog writes it (listed vertices first, then endpoints by
first appearance; edges in written order, repeats and loops kept) on the `ReferencePseudograph` or
`ReferenceDirectedMultigraph`, whose rows are in position order, so every vertex and edge position
is exact; parent arrays and closures go to the initializers directly. Rows are repeated in
`TreeRepresentationTests.swift` on `UndirectedAdjacencyList`, `AdjacencyList`,
`CompressedSparseRow` (arcs rewritten in its row-major positions), the views, a conformer with
reversed rows and one with no indices. Adjacency lists after removals are checked against rows
and a preorder computed inside the test from the graph's own `edges`. Each literal is the catalog
cell, computed by the reference (`ref.py`: api.md's model in index space, a naive recursive
implementation, and NetworkX 3.7); literals that are not catalog cells (a few extra queries on
catalog sources, CSR's row-major positions, a parent closure in DominatorTree's order, the stress
shapes' endpoints) were computed with the same reference. The whole suite was also run against an
independent Swift model of the API before the implementation existed, and against planted bugs in
that model. The property tests write their oracles inside each test.

## Files

| File | Tests | Covers |
|---|---|---|
| `TreeRecognitionTests.swift` | 31 | §A: `isTree`, `Tree(g)`, `Forest(g)`, `isAcyclic`: the null graph, K₁, K₂, loops, parallel pairs, m = n − 1 that is not a tree, an isolated vertex, igraph's binary tree, String vertices, positions; the equivalences on every source |
| `ArborescenceRecognitionTests.swift` | 20 | §B: `isArborescence`, `Arborescence(g)`: in-trees, polytrees, cycles, parallel and opposite arcs, loops, branchings, two roots, the root not first, NetworkX's docstring pair, the unreached 2-cycle; the equivalence on every source |
| `TreeConstructionTests.swift` | 15 | §C: vertex order, repeats, endpoints added, positions, rows, one-vertex trees, conversions; single-pass sequences, the edge initializers' rejections, `Collider` and `HashableBox` vertices |
| `ParentFunctionTests.swift` | 22 | §D: `init?(parents:)` and `init?(vertices:parent:)` on both rooted types: roots, two roots, no root, self-parents, out-of-range and negative parents, cycles, the empty array, children and edges in vertex order; a thrown error propagates |
| `RootedQueryTests.swift` | 48 | §E: every rooted query on E1, E2, K₁, stars, paths and kary(15,2), rerooting, String vertices, the arborescence's queries; index-space queries; the queries' mutual consistency at every root |
| `TreePathTests.swift` | 16 | §F: paths on `Tree`, `RootedTree`, `Arborescence` and `Forest`; every pair of E1 against breadth-first distances |
| `ForestTests.swift` | 14 | §G: `trees` by least vertex, renumbered edges, listed order, isolated vertices, the empty forest, `Forest(tree)`, `component(of:)`, rejections; the trees partition the forest |
| `PruferTests.swift` | 20 | §H: NetworkX's and igraph's codes, paths, stars, n < 2, out-of-range elements, index order over value order; all 125 codes of length 3 (Cayley), any `Sequence<Int>` |
| `TreeGraphRowTests.swift` | 16 | §I: rows, degrees, in- and out-edges; the `Graph` laws for `Tree`, `RootedTree` (at every root) and `Forest`, and the `DirectedGraph` / `BidirectionalDirectedGraph` laws for `Arborescence` |
| `TreeEqualityTests.swift` | 10 | §J: order and orientation ignored, the root, ordered arcs, isolated vertices; sets, hashes, conversions |
| `TreeConformanceTests.swift` | 7 | Codable round trips and the adjacency-list format both ways, invalid encodings throwing `dataCorrupted`, descriptions, `Sendable`, generic code |
| `TreeRepresentationTests.swift` | 10 | Catalog rows on `UndirectedAdjacencyList` (also after removals), `AdjacencyList`, `CompressedSparseRow`, `.directed` and `.undirected`, reversed rows, no indices; `isTree` hashes no vertex on an indexed adjacency list |
| `TreePropertyTests.swift` | 7 | PropertyBased, shrinking: recognition against union–find and in-degree counts, rooted queries against recursion, paths against BFS, Prüfer against the textbook loop, parent arrays, equality and Codable under shuffles |
| `TreeStressTests.swift` | 16 | §K inside a `Task` with a one-minute limit: the 10⁶ path (depth, postorder, height, path, ancestor, descendants, Prüfer), the 10⁶ star, kary(10⁶, 2), 10⁶ isolated vertices, a 10⁶ parent chain, conversions and equality at 10⁶ |
| `TreePreconditionTests.swift` | 5 | Exit tests: a root that is not a vertex (TS-109), queries and paths on a non-vertex (TS-246, TS-315 and the other rooted queries, `component(of:)`) |
| `TreeReviewTests.swift` | 10 | Added after planting bugs and the review (TS-1001 – TS-1010): a forest with a parallel pair, edges keeping their orientation, hashes that see edges, `Int` vertices by first appearance, small trees without a vertex table, one-vertex trees of a forest, children with the parent edge anywhere in the row, parent arrays, rooted-tree decoding errors, equal hashes under shuffles |

267 tests in all.

## Case IDs

Case IDs (TS-001 … TS-813) refer to the catalog (`cases.md`, with `ref.py` and `api.md` in `Tests/Catalogs/Trees/`), harvested from NetworkX
(`tree/tests/test_recognition.py`, `test_coding.py`, `traversal/tests/test_dfs.py`), igraph
(`igraph_is_tree.c`, `igraph_is_forest.c`, `igraph_to_prufer.c`, `igraph_from_prufer.c`,
`igraph_tree_from_parent_vector.c`), JGraphT (`GraphTestsTest`) and LEMON (`connectivity_test.cc`).
Each test's name starts with its IDs; tests without an ID check laws, representations or
properties the catalog does not list.

| Cases | Section | File |
|---|---|---|
| TS-001 – TS-030 | A. Recognition, undirected | `TreeRecognitionTests.swift`; several again in `TreeRepresentationTests.swift` |
| TS-050 – TS-068 | B. Recognition, directed | `ArborescenceRecognitionTests.swift`; TS-052, TS-062, TS-063 and TS-068 again on `AdjacencyList` |
| TS-100 – TS-110, TS-112 | C. Construction | `TreeConstructionTests.swift`; TS-109 in `TreePreconditionTests.swift` |
| TS-111, TS-113 | C. `Tree(forest)`, `RootedTree(forest)` | not tested: see below |
| TS-150 – TS-169 | D. Parent functions | `ParentFunctionTests.swift` |
| TS-200 – TS-245 | E. Rooted queries | `RootedQueryTests.swift` |
| TS-246 | E. Query on a non-vertex | `TreePreconditionTests.swift` |
| TS-300 – TS-314 | F. Paths | `TreePathTests.swift` |
| TS-315 | F. Path to a non-vertex | `TreePreconditionTests.swift` |
| TS-400 – TS-412 | G. Forest | `ForestTests.swift` |
| TS-500 – TS-517 | H. Prüfer codes | `PruferTests.swift` |
| TS-600 – TS-611 | I. Graph rows | `TreeGraphRowTests.swift` |
| TS-700 – TS-707 | J. Equality | `TreeEqualityTests.swift` |
| TS-800 – TS-813 | K. Scale | `TreeStressTests.swift` |
| TS-1001 – TS-1010 | Review: see the file table | `TreeReviewTests.swift` |

## Not tested

| Case | Why |
|---|---|
| TS-111, TS-113 | `Tree(forest)` and `RootedTree(forest)` are not offered, so the catalog's "trap" is a compile-time absence that a test cannot express; the way to a forest's tree, `forest.trees[i]`, is TS-406 |
| Complexity (O(1) `children`, `descendants`, `isAncestor`; O(n) `==`; lazy `trees[i]`) | Internal costs belong to the benchmarks; the stress tests only bound them loosely (10⁶ one-vertex trees, a 10⁶-entry row, O(1)-shaped queries on 10⁶ vertices within the time limit) |
| `isArborescence` without hashing | api.md says the undirected build reads index rows (`isTree` is tested without hashing); it does not say the directed check avoids the vertex table |
| The exact `description` of `RootedTree` | api.md does not say whether it shows the root; it is checked to be non-empty, and the others to print as the adjacency list copied from them |
| The `root` key of `RootedTree`'s encoding | api.md says "adds the root's offset" without a key name; `RootedTree` is checked by round trips at every root, not by hand-written JSON |
| `Forest.Trees` and `Preorder` index types | api.md gives only `RandomAccessCollection`; the tests index with `index(_:offsetBy:)` and offsets from `enumerated()`, not literal integer subscripts |
| Mutation and copy-on-write | The types are immutable |
