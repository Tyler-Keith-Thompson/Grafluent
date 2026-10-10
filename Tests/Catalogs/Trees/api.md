# Trees: proposed API (phase 1)

Four immutable, copy-on-write value types whose invariant is the type (README principle 4), the
two recognition predicates, and Prüfer codes. Values are pinned by `cases.md` (TS-001 – TS-813),
recomputed by `ref.py`.

## Scope

**In, phase 1**

| Entry point | Why |
|---|---|
| `Tree<Vertex>`: connected, acyclic, undirected, at least one vertex; conforms to `Graph` | README Structures row. Every library has the concept (NetworkX/JGraphT/igraph `is_tree`, LEMON `tree()`), and none has the type: they recheck a mutable graph. A type is what principle 4 asks for |
| `RootedTree<Vertex>`: a `Tree` with a root; `Graph`, plus `root`, `parent(of:)`, `children(of:)`, `depth(of:)` and the queries below | README row. The undirected rooted tree is what tree algorithms read (LCA, Euler tour, HLD in TreeAlgorithms) |
| `Arborescence<Vertex>`: every edge points away from the root; `BidirectionalDirectedGraph`, with the same rooted queries | README row. NetworkX `is_arborescence`, Edmonds' and LEMON's `MinCostArborescence`; igraph's "out-tree". It is the directed form, so it conforms to the directed protocols, and `RootedTree` to the undirected one: no type conforms to both (README open question 8) |
| `Forest<Vertex>`: acyclic, undirected, possibly empty; `Graph`, with `trees` (a `Collection` of `Tree`) and `component(of:)` | README row ("the components are a `Collection` of `Tree`") |
| `Graph.isTree`, `DirectedGraph.isArborescence` | NetworkX `is_tree` / `is_arborescence`, JGraphT `GraphTests.isTree`, igraph `is_tree` (mode `OUT` for the arborescence), LEMON `tree()`. O(1) rejection by counts, no allocation of a tree |
| Construction from a graph, from vertices and edges, from a parent function, from another tree type | The ways trees arrive: a checked graph, a parent array (BFS/DFS, shortest paths, dominators: igraph `tree_from_parent_vector`, Boost's predecessor map), or rerooting |
| `path(from:to:) -> Walks.Path` | The unique path, with its edge positions, in O(length) |
| `preorder`, `postorder`, `descendants(of:)`, `ancestors(of:)`, `isAncestor(_:of:)`, `height` | The rooted-tree basics every tree algorithm starts from; preorder is the storage layout, so these are O(1) or O(answer) |
| `Tree.pruferSequence`, `Tree<Int>(pruferSequence:)` | NetworkX `to/from_prufer_sequence`, igraph `to/from_prufer`, JGraphT `PruferTreeGenerator`; RandomGraphs' random trees (README) are built on it |

**Out, and where it goes**

| Not in phase 1 | Reason |
|---|---|
| Lowest common ancestor, Euler tour, heavy–light decomposition, centroid, center, diameter, tree isomorphism (AHU) | `TreeAlgorithms` (README); isomorphism in `IsomorphismModule`. They take `RootedTree` / `Arborescence` (and `Tree`, rooting it); this module gives them preorder, depth and subtree intervals in index space |
| A `RootedTree` **protocol** for `ShortestPathTree` / `DominatorTree` | The name is the struct's (README). No surveyed library has such a protocol (Boost's `tree_traits` is undocumented and unused by its algorithms). And neither type satisfies the invariant over the graph's vertices: a shortest-path tree with several sources is a forest, and both leave vertices out (unreached). Convert instead: `Arborescence(vertices: reached, parent: tree.parent(of:))` (TS-169 shape); for `DominatorTree`, `parent: dt.immediateDominator(of:)` gives the same `children(of:)` order (vertex order) as `dt.children(of:)`. Revisit if TreeAlgorithms needs to be generic |
| `breadthFirstTree(from:)`, `depthFirstTree(from:)` | **Traversal**, which then imports Trees (NetworkX `bfs_tree` / `dfs_tree`). Result: `Arborescence` on `DirectedGraph`, `RootedTree` on `Graph`, over the reached vertices in discovery order, with the graph's positions of the tree edges returned beside it (CSR's `forwardEdgeIndices:` pattern), since a tree has its own positions |
| `SpanningForest` → `Forest` | One line with the existing initializer: `Forest(vertices: g.vertices, edges: sf.edges.map { g.edges[$0] })!`. A convenience can go in SpanningTrees later |
| Mutation (insert leaf, graft, prune, reroot in place) | Immutable, initializers only, as `CompressedSparseRow` (principle 2 allows it). The layout is preorder with subtree intervals, so an insertion moves O(n) entries; and no library offers a mutable tree that keeps its invariant (NetworkX and JGraphT mutate a general graph and recheck). Rerooting is `RootedTree(tree, root:)`, O(n) |
| `leaves`, `subtreeSize(of:)`, `levelOrder` | One-liners: `vertices.filter { children(of: $0).isEmpty }` (and "leaf" means degree 1 unrooted but childless rooted, so it would need two definitions); `descendants(of: v).count + 1`, O(1); `breadthFirstSearch(from: root)` on an `Arborescence`. No library names `subtreeSize` |
| `Branching` (a rooted forest; NetworkX `is_branching`) | Not in the README; needed with Chu–Liu/Edmonds (SpanningTrees phase 2) and multi-source BFS. Phase 2 |
| In-trees (igraph `IGRAPH_IN`, "anti-arborescence") | `Arborescence(g.reversed)` once GraphOperations' `reversed` view exists |
| `isForest` | It is Cycles' `isAcyclic` (and `Forest(g) != nil`); one name per concept, as the Cycles design decided |
| `isTree` on a digraph (NetworkX: underlying graph is a tree, a "polytree") | `digraph.undirected.isTree` on a `BidirectionalDirectedGraph` |
| Nested tuples (NetworkX `to_nested_tuple`), `join_trees`, `junction_tree`, igraph `unfold_tree` | One library each; nested heterogeneous tuples have no Swift type; junction trees belong with chordal graphs |
| Result builder (`@GraphBuilder`) initializers | A failable result-builder initializer reads badly; `Tree(edges: [...])` covers it |

## Summary

```swift
import GraphProtocols
import Walks

extension Graph {
    /// Connected and acyclic, with at least one vertex. A self-loop or a parallel pair is a cycle.
    var isTree: Bool { get }                                   // O(1) when edgeCount != vertexCount - 1
}
extension DirectedGraph {
    /// A tree whose edges all point away from one root: exactly one vertex has in-degree 0, every
    /// other in-degree 1, and the root reaches every vertex. At least one vertex.
    var isArborescence: Bool { get }
}

@frozen public struct Tree<Vertex: Hashable>: Graph {
    public init?(_ graph: some Graph<Vertex>)                  // edges keep the graph's positions
    public init?(edges: some Sequence<UndirectedEdge<Vertex>>)
    public init?(vertices: some Sequence<Vertex>, edges: some Sequence<UndirectedEdge<Vertex>>)
    public init(_ tree: RootedTree<Vertex>)                    // forget the root, O(1)

    /// The unique path, with the edges it takes. O(length). Precondition: both are vertices.
    public func path(from source: Vertex, to target: Vertex) -> Path<Vertex, Int>

    /// Prüfer code: remove the leaf with the least vertex index, record its neighbour, n − 2
    /// times. nil when there are fewer than 2 vertices. O(n).
    public var pruferSequence: [Vertex]? { get }
    // Graph: vertices, edges (RandomAccessCollection, Int positions 0..<n−1), neighbors(of:),
    // incidentEdges(of:), vertex indices 0..<n, edge indices 0..<n−1, the index-space rows.
}
extension Tree where Vertex == Int {
    /// The tree on 0..<count+2 with this code; nil when an element is outside that range.
    public init?(pruferSequence: some Sequence<Int>)
}

@frozen public struct RootedTree<Vertex: Hashable>: Graph {
    public init(_ tree: Tree<Vertex>, root: Vertex)            // O(n); precondition: root ∈ tree
    public init?(_ graph: some Graph<Vertex>, root: Vertex)    // precondition: root ∈ graph
    public init(_ arborescence: Arborescence<Vertex>)          // O(1)
    public init?<E: Error>(vertices: some Sequence<Vertex>,
                           parent: (Vertex) throws(E) -> Vertex?) throws(E)
    public var root: Vertex { get }
    public func parent(of vertex: Vertex) -> Vertex?
    public func parentEdge(of vertex: Vertex) -> Int?
    public func children(of vertex: Vertex) -> Children       // RandomAccessCollection<Vertex>
    public func depth(of vertex: Vertex) -> Int
    public var height: Int { get }
    public var preorder: Preorder { get }                      // RandomAccessCollection<Vertex>, O(1)
    public var postorder: [Vertex] { get }                     // O(n)
    public func descendants(of vertex: Vertex) -> Preorder.SubSequence    // O(1)
    public func ancestors(of vertex: Vertex) -> Ancestors      // lazy Sequence, parent first
    public func isAncestor(_ a: Vertex, of b: Vertex) -> Bool  // strict, O(1)
    public func path(from source: Vertex, to target: Vertex) -> Path<Vertex, Int>
    // index space
    public var rootIndex: Int { get }
    public func parent(ofIndex index: Int) -> Int?
    public func depth(ofIndex index: Int) -> Int
}
extension RootedTree where Vertex == Int {
    /// Vertex i has parent parents[i]; exactly one nil, the root.
    public init?(parents: [Int?])
}

@frozen public struct Arborescence<Vertex: Hashable>: BidirectionalDirectedGraph {
    public init?(_ graph: some DirectedGraph<Vertex>)
    public init?(edges: some Sequence<DirectedEdge<Vertex>>)
    public init?(vertices: some Sequence<Vertex>, edges: some Sequence<DirectedEdge<Vertex>>)
    public init(_ tree: RootedTree<Vertex>)                    // O(1)
    public init?<E: Error>(vertices: some Sequence<Vertex>,
                           parent: (Vertex) throws(E) -> Vertex?) throws(E)
    // root, parent(of:), parentEdge(of:), children(of:), depth(of:), height, preorder, postorder,
    // descendants(of:), ancestors(of:), isAncestor(_:of:), rootIndex, parent(ofIndex:),
    // depth(ofIndex:): as RootedTree.
    /// The path down from `source` to `target`; nil unless source is target or an ancestor.
    public func path(from source: Vertex, to target: Vertex) -> Path<Vertex, Int>?
    // BidirectionalDirectedGraph: successors = children, outEdges = child edges, predecessors =
    // the parent (0 or 1), inEdges = the parent edge; edges are DirectedEdge(parent → child).
}
extension Arborescence where Vertex == Int { public init?(parents: [Int?]) }

@frozen public struct Forest<Vertex: Hashable>: Graph {
    public init()
    public init?(_ graph: some Graph<Vertex>)
    public init?(edges: some Sequence<UndirectedEdge<Vertex>>)
    public init?(vertices: some Sequence<Vertex>, edges: some Sequence<UndirectedEdge<Vertex>>)
    public init(_ tree: Tree<Vertex>)
    /// The trees, by least vertex; `trees[i]` builds its `Tree` in O(size of the tree).
    public var trees: Trees { get }                            // RandomAccessCollection<Tree<Vertex>>
    public func component(of vertex: Vertex) -> Int            // its tree's offset in `trees`
    public func path(from source: Vertex, to target: Vertex) -> Path<Vertex, Int>?
}
```

All four: `Equatable`, `Hashable`, `Sendable` when `Vertex` is, `Codable` when `Vertex` is,
`CustomStringConvertible`, `CustomDebugStringConvertible`. Not `Comparable`. `Forest.Trees`,
`RootedTree.Preorder` and the other views are `Sendable` under the same condition.

## Names

| Grafluent | Used by | Not chosen, and why |
|---|---|---|
| `Tree`, `Forest`, `isTree` | NetworkX `is_tree`/`is_forest`, JGraphT `isTree`/`isForest`, igraph `is_tree`/`is_forest`, LEMON `tree()` | `FreeTree` (Knuth's unrooted tree): no library |
| `RootedTree` | README; NetworkX's documentation ("rooted tree": `random_labeled_rooted_tree`, `join_trees(rooted_trees)`, `to_nested_tuple(T, root)`), igraph's | |
| `Arborescence`, `isArborescence` | NetworkX `is_arborescence`, LEMON `MinCostArborescence`, Edmonds (1967) | igraph's "out-tree" (one library); "directed tree" (NetworkX means polytree by it) |
| `root`, `parent(of:)`, `children(of:)` | README Terminology ("all"), `DominatorTree.root`/`children(of:)`, `ShortestPathTree.parent(of:)`, Swing `TreeNode.getParent()`/`children()`/`getRoot()` | `predecessor` (Boost, scipy): in Grafluent `predecessors(of:)` means in-neighbours, which for an `Arborescence` it is, through the protocol |
| `parentEdge(of:)` | `ShortestPathTree.parentEdge(of:)` | |
| `depth(of:)`, `height` | README row (`depth(of:)`); CLRS and Knuth ("depth of a node", "height of a tree") | Swing's `getLevel()` is our depth and its `getDepth()` is our **height**: the opposite of CLRS, so not followed |
| `preorder`, `postorder` | NetworkX `dfs_preorder_nodes`/`dfs_postorder_nodes`, Swing `preorderEnumeration`/`postorderEnumeration`, Knuth | `dfsPreorder`: the tree's order needs no search qualifier |
| `descendants(of:)`, `ancestors(of:)` | README Terminology (NetworkX); both exclude the vertex, as NetworkX's do | |
| `isAncestor(_:of:)` | Swing `isNodeAncestor` (which is reflexive; ours is strict, to agree with `ancestors(of:)`, TS-215) | `dominates` (DominatorTree, LLVM): dominance is a different relation that happens to be the tree's |
| `path(from:to:)` | Walks' `Path`; NetworkX `shortest_path(T, u, v)`; Swing `getPath()` (root to node) | |
| `trees`, `component(of:)` | JGraphT ("a forest is a set of disjoint trees"); `component(of:)` is Connectivity's `Components.component(of:)` | `components`: Connectivity's `Components` holds vertex slices; these elements are `Tree` values |
| `pruferSequence`, `init?(pruferSequence:)` | NetworkX `to_prufer_sequence`/`from_prufer_sequence`, igraph `to_prufer`/`from_prufer`, JGraphT `PruferTreeGenerator` | `pruferCode`: less common |
| `init?(vertices:parent:)`, `init?(parents:)` | igraph `tree_from_parent_vector(parents)`; README Terminology `parent(of:)` | `predecessors:` (Boost, scipy, NetworkX `bfs_predecessors`): the same clash as above |

## Semantics

### What is a tree here

* **Tree**: at least one vertex, connected, acyclic; a self-loop and a parallel pair are cycles,
  so a tree has neither and has exactly n − 1 edges. **No empty tree**: a `RootedTree` needs a
  root and every `Tree` converts to one. The libraries disagree on the null graph: igraph and
  JGraphT say not a tree, NetworkX raises, LEMON's `tree()` says it is one (TS-001).
* **Forest**: acyclic; the empty forest exists (igraph and LEMON agree; NetworkX raises;
  JGraphT's `isForest` returns false although its comment says "this includes the empty graph",
  TS-003). Isolated vertices are one-vertex trees.
* **Arborescence**: at least one vertex, exactly one vertex (the root) of in-degree 0, every
  other of in-degree 1, n − 1 arcs, every vertex reachable from the root. In-degree ≤ 1 and n − 1
  arcs do not imply reachability (TS-068: a root plus a separate 2-cycle). NetworkX's
  `is_arborescence` (polytree plus in-degree ≤ 1) is the same predicate (cross-checked on every
  `D:` case).
* `isTree` ⇔ `Tree(g) != nil`, `isArborescence` ⇔ `Arborescence(g) != nil`, and
  `isAcyclic` (Cycles) ⇔ `Forest(g) != nil` (checked on every case).

### Failure is `nil`

Every initializer from unchecked input is failable. A thrown error would have to be `Sendable`,
so it could not carry vertices (README, the DAG row: witnesses, not errors), and the witnesses
already exist: `g.findCycle()` (Cycles) for a cycle, `g.connectedComponents()` (Connectivity) for
disconnection. A root that is not a vertex is a precondition, as Cycles' `findCycle(from:)`
(TS-109); a query on a non-vertex traps, as `DominatorTree`'s do (TS-246, TS-315).

### Vertex order and edge positions

* From a graph: the graph's `vertices` order and its edges at their positions (TS-030, TS-063),
  so position k of the tree is position k of the graph. Rows are rebuilt in **position order**,
  whatever the graph's `incidentEdges` order (a representation after removals): a tree's rows
  are canonical.
* From `vertices:edges:`: the listed vertices with duplicates dropped, then endpoints by first
  appearance, edges in the order given: `UndirectedAdjacencyList(vertices:edges:)`'s rule
  (TS-100 – TS-102). The same edge written twice (either orientation) is a parallel pair (TS-011).
* From a parent function: `vertices` with duplicates dropped (TS-165); one edge per non-root
  vertex, **in vertex order**, `(parent, child)` (igraph `tree_from_parent_vector`, TS-151,
  TS-163). Fails on: no root or several (TS-153, TS-154), a parent outside `vertices` (TS-156,
  TS-164), a self-parent (TS-155; Boost marks roots with `p[r] == r`, igraph rejects it, so do
  we), a cycle (TS-157). In `init?(parents: [Int?])`, a negative entry is an out-of-range parent,
  not a root (TS-158; igraph uses negatives for roots, Swift has `Optional`).
* Conversions keep vertices and positions: `Tree(rooted)`, `RootedTree(tree, root:)`,
  `Arborescence(rooted)`, `RootedTree(arborescence)`, `Forest(tree)` (TS-112, TS-241, TS-607).
  `RootedTree → Arborescence` orients every edge parent → child (TS-607).
* Prüfer decoding: vertices `0..<n`, edges in decoding order, edge k joining the k-th removed
  leaf to the k-th code element, the last edge joining the two remaining vertices (TS-501,
  TS-510). The linear decoder (Wang et al., NetworkX's and igraph's) emits edges in the same
  order as the textbook least-leaf loop (checked).

### Rooted queries

* `children(of:)`: the vertex's incidence row without its parent edge, so **in position order of
  the child edges**, not vertex order (TS-225). After rerooting, the old parent is wherever its
  edge sits in the row (TS-219). From a parent function, edges are numbered in vertex order, so
  children come in vertex order (TS-160): exactly `DominatorTree.children(of:)`'s order.
* `preorder`: root, then each child's subtree in `children` order (NetworkX
  `dfs_preorder_nodes` on the same adjacency order, checked on every rooted case).
  `postorder` the same with each vertex after its subtree. `descendants(of: v)` is v's subtree
  in preorder, without v: a slice of `preorder`, O(1), so `descendants(of: v).count + 1` is the
  subtree size (TS-209, TS-210). `ancestors(of: v)` runs parent first up to the root (TS-212).
  `isAncestor(a, of: b)` is strict: `ancestors(of: b).contains(a)` in O(1) (TS-214 – TS-217).
* `depth(of: root) == 0`; `height` is the greatest depth, 0 for one vertex (TS-108).
* `path(from: a, to: b)`: up from a to the meeting vertex, then down to b, with the edge
  positions (TS-300). It does not depend on the root (TS-304 = TS-305), and `Tree` and `Forest`
  answer it too. On an `Arborescence` it follows arcs: `nil` unless a is b or an ancestor of b
  (TS-307 – TS-310). On a `Forest`, `nil` across trees (TS-312). The trivial path is `[v]`.

### Forest

`trees` lists the trees **by least vertex** (in `vertices` order, Connectivity's component
order; TS-401). Each tree has the forest's vertices in the forest's order and its edges in the
forest's position order, **renumbered from 0** (TS-400, TS-402). `trees[i]` builds that `Tree` in
O(size of tree i), so a forest of 10⁶ isolated vertices costs nothing until read (TS-810).
`component(of: v)` is the offset of v's tree in `trees` (TS-403).

### Prüfer codes

By **vertex index** (`vertices` order), the package's "least vertex" (Cycles' canonical form):
for `Int` vertices listed in value order that is NetworkX's and igraph's code; listed out of
order, it is the code of the tree relabeled by index (TS-515: `[2,1]`, where ranking by value
would give `[1,2]`). nil for fewer than 2 vertices (NetworkX raises
`NetworkXPointlessConcept`, igraph `EINVAL`, TS-504); the empty code decodes to K₂ (TS-502).
Decoding rejects elements outside `0..<count+2` (TS-506, TS-507).

### Equality, hashing, coding

Equality is the README's rule for representations: **equal vertex sets and equal edge sets**,
regardless of order and (undirected) orientation (TS-700); `RootedTree` also compares the root
(TS-703); `Arborescence` compares arcs as ordered pairs, which fixes the root (TS-705). So two
equal values can differ in `children(of:)` order or edge positions, as two equal adjacency lists
can differ in row order. Testing an edge {u, v} of the left side on the right is O(1) without
hashing an edge: `parent(u) == v || parent(v) == u` in the right side's (internal) rooting, so
`==` is O(n). `hash(into:)` follows `UndirectedAdjacencyList`: a commutative sum of per-vertex and
per-edge hashes (an `UndirectedEdge` hashes without orientation). `Codable` uses the
`UndirectedAdjacencyList` format (vertices, then edges as pairs of vertex offsets; `RootedTree`
adds the root's offset); decoding re-checks the invariant and throws `DecodingError.dataCorrupted`
(as Walks' types do), and also rejects a repeated vertex.

## Complexity

| Operation | Cost |
|---|---|
| `isTree`, `isArborescence` | O(1) when the edge count is not n − 1; else O(n), no allocation beyond a visited mark and a stack |
| Any initializer | O(n) after hashing the input vertices (none with dense `Int` vertices `0..<n`, below) |
| `RootedTree(tree, root:)` | O(n); O(1) when the root is the tree's internal root |
| Conversions otherwise | O(1) (shared storage) |
| `parent`, `parentEdge`, `depth`, `height`, `isAncestor`, `children(of:)`, `descendants(of:)`, `preorder` | O(1) (plus one hash of each vertex argument) |
| `postorder` | O(n), allocated |
| `ancestors(of:)`, `path(from:to:)` | O(answer) |
| `pruferSequence`, `init?(pruferSequence:)` | O(n) |
| `forest.trees[i]` | O(size of tree i) |
| `==`, `hash(into:)` | O(n) |

## Implementation notes (index space)

* **One layout for all four types.** A `@usableFromInline final class` (or a few arrays shared
  by copy-on-write) holding, with vertex numbers 0..<n in `vertices` order:
  `ends: [Int]` (2 per edge), `rowOffsets: [Int]` (n + 1) and `rowEdges: [Int]` (2(n − 1)) for
  the incidence rows (a counting sort over edges in position order leaves every row ascending),
  and the **rooting**: `parent`, `parentEdge`, `depth`, `preorder`, `preorderPosition`,
  `subtreeSize`, `parentOffsetInRow`. `Tree` stores a rooting at vertex 0, which is never
  observable but makes `path(from:to:)` O(length) and `Tree ↔ RootedTree` O(1); `Forest` roots
  each tree at its least vertex, with `component` per vertex and the vertices and edges grouped
  by tree (counting sort, stable) so `trees[i]` copies contiguous runs. About 12 `Int`s per vertex.
* **Children without a children array.** `children(of: v)` is v's row with one hole, the parent
  edge at `parentOffsetInRow[v]`: a `RandomAccessCollection` with O(1) `count` and subscript.
  `Arborescence.outEdges(of:)` is the same view over edge positions; `inEdges(of:)` and
  `predecessors(of:)` hold zero or one element.
* **No recursion.** The rooting is one iterative depth-first walk with a stack of
  (vertex, row cursor), skipping the parent edge by position (not the parent vertex: in a tree it
  is the same, but the build must also survive invalid input until rejected). It writes parent,
  parent edge, depth and preorder; `subtreeSize` is one pass over `preorder` in reverse.
  `postorder` needs no second walk: post(v) = pre(v) + size(v) − 1 − depth(v) (checked on every
  rooted case). `path` climbs `parent` by `depth`. The 10⁶-vertex path (TS-801 – TS-806), the
  10⁶-leaf star (TS-807) and the 10⁶-vertex binary tree (TS-812) are the stress shapes.
* **Validation.** Undirected tree: n ≥ 1, m == n − 1, and the walk reaches n vertices; with
  m = n − 1 connectivity implies acyclicity, and a loop or a parallel pair leaves a vertex
  unreached (TS-020, TS-025). Forest: one walk over every root counting c trees; valid iff
  m == n − c (no union–find, so no DisjointSetModule dependency). Arborescence: in-degree counts
  (> 1 fails at once), one root, then the walk over out-rows reaches n (TS-068). Parent
  function: gather parent numbers (one dictionary lookup each), exactly one root, counting-sort
  the children rows, then the walk from the root reaches n iff there is no cycle (every non-root
  has exactly one parent, so n − 1 edges).
* **Reading the source graph.** With vertex and edge indices, read the index-space rows
  (`_withIncidentIndexRows`, `incidentEdgeIndices(ofIndex:)`), so building a `Tree` from an
  `UndirectedAdjacencyList` hashes nothing; else one pass over `edges` with a vertex dictionary.
  `isTree` uses the same rows. This wants the row helpers moved from Connectivity to
  GraphProtocols as `package`, which the Cycles design already asks for.
* **Vertex lookup.** Generic vertices need a vertex → number map; reuse the dense-slot table of
  `AdjacencyList` (or `_DenseVertices`' shape). When `Vertex == Int` and the vertices are exactly
  `0..<n` in order (every `init?(parents:)`, Prüfer, most index-space use), set a flag and skip the
  table: `vertexIndex(of: v)` is `v` after a bounds check.
* **Dependencies.** Trees → GraphProtocols and **Walks** (for `Path`; today only GraphProtocols:
  update `scripts/modules.py`). Traversal → Trees for `breadthFirstTree`. Connectivity and
  ShortestPaths need not depend on Trees (the parent-function initializer is the bridge).

## Library disagreements found

| Where | What | Catalog |
|---|---|---|
| Null graph, `is_tree` | igraph, JGraphT: false; LEMON `tree()`: true; NetworkX raises | TS-001 |
| Null graph, `is_forest` | igraph, LEMON (`acyclic`): true; JGraphT `isForest`: false, contradicting its own Javadoc ("this includes the empty graph"); NetworkX raises | TS-003 |
| Directed "tree" | NetworkX `is_tree` on a digraph tests the underlying graph (a polytree) and calls an arborescence a "tree" in "another convention"; igraph `is_tree(mode=OUT)` is the arborescence | TS-054 |
| Root marker in a parent array | Boost: `p[r] == r`; igraph: any negative; scipy: −9999; NetworkX dicts: absent. Ours: `nil`, and a self-parent fails | TS-155, TS-158 |
| Depth and height | Swing's `getDepth()` is the height and `getLevel()` the depth; CLRS/Knuth (ours) the other way | TS-207, TS-208 |
| Ancestor | NetworkX `ancestors` strict; Swing `isNodeAncestor` reflexive; `DominatorTree.dominates` reflexive. Ours strict | TS-215 |
| Prüfer for n < 2 | NetworkX raises `NetworkXPointlessConcept`, igraph `IGRAPH_EINVAL`; ours `nil` | TS-504 |
| Prüfer labels | NetworkX requires the node set to be exactly {0, …, n − 1} (`KeyError` otherwise) and ranks by value; ours ranks by index for any vertex type | TS-514, TS-515 |
