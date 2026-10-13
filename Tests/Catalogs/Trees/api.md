# Trees: API

Four immutable, copy-on-write value types whose invariant is the type, the two recognition
predicates, and Prüfer codes. Values are pinned by `cases.md` (TS-001 – TS-995), recomputed by
`ref.py`.

## Contents

| Entry point | What it is |
|---|---|
| `Tree<Vertex>` | Connected, acyclic, undirected, at least one vertex; a `Graph` |
| `RootedTree<Vertex>` | A `Tree` with a root; a `Graph`, plus `root`, `parent(of:)`, `children(of:)`, `depth(of:)` and the queries below |
| `Arborescence<Vertex>` | Every edge points away from the root; a `BidirectionalDirectedGraph` with the same rooted queries |
| `Forest<Vertex>` | Acyclic, undirected, possibly empty; a `Graph`, with `trees` (a `Collection` of `Tree`) and `component(of:)` |
| `Graph.isTree`, `DirectedGraph.isArborescence` | The predicates, without building a tree; O(1) rejection by counts |
| Initializers | From a graph, from vertices and edges, from a parent function or array, from another tree type |
| `path(from:to:) -> Walks.Path` | The unique path, with its edge positions, in O(length) |
| `preorder`, `postorder`, `descendants(of:)`, `ancestors(of:)`, `isAncestor(_:of:)`, `height` | The rooted-tree basics; preorder is the storage layout, so these are O(1) or O(answer) |
| `Tree.pruferSequence`, `Tree<Int>(pruferSequence:)` | Prüfer codes |

Tree algorithms (lowest common ancestor, Euler tour, heavy–light decomposition, centroid, center,
diameter) are in `TreeAlgorithms`; tree isomorphism is in `IsomorphismModule`; search trees
(`breadthFirstTree(from:)`, `depthFirstTree(from:)`) are in `Traversal`. Other modules' tree-shaped
results convert through the parent-function initializer, for example
`Arborescence(vertices: reached, parent: tree.parent(of:))` (TS-169's shape). A forest is acyclic
exactly when Cycles' `isAcyclic` holds, so there is no separate `isForest`. In-trees are
arborescences of the reversed graph.

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

    /// Prüfer code: remove the least-ranked leaf, record its neighbour, n − 2 times. The rank is
    /// the value for `Int` vertices exactly 0..<n (any order), the vertex index otherwise. nil when
    /// there are fewer than 2 vertices. O(n).
    public var pruferSequence: [Vertex]? { get }
    // Graph: vertices, edges (RandomAccessCollection, Int positions 0..<n−1), neighbors(of:),
    // incidentEdges(of:), vertex indices 0..<n, edge indices 0..<n−1, the index-space rows.
    // checked: neighbors(checked:), incidentEdges(checked:), degree(checked:),
    // vertexIndex(checked:), path(checkedFrom:to:) throw VertexNotFound (§L).
}
extension Tree where Vertex == Int {
    /// The tree on 0..<count+2 with this code; nil when an element is outside that range. Inverts
    /// `pruferSequence` for trees on the Ints 0..<n.
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
    // checked: parent(checked:) and parentEdge(checked:) (nil at the root), children(checked:),
    // depth(checked:), descendants(checked:), ancestors(checked:), isAncestor(checked:of:),
    // path(checkedFrom:to:) and Tree's four row lookups throw VertexNotFound (§L).
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
    // checked: RootedTree's tree lookups (path(checkedFrom:to:) nil unless downward), and
    // successors, predecessors, outEdges, inEdges, outDegree, inDegree, degree, vertexIndex
    // (checked:) throw VertexNotFound; source(checkedEdgeAt:), target(checkedEdgeAt:) throw
    // EdgeNotFound for a position outside 0..<edgeCount (§L).
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
    // checked: component(checked:), path(checkedFrom:to:) (nil across trees) and Tree's four row
    // lookups throw VertexNotFound (§L).
}
```

All four: `Equatable`, `Hashable`, `Sendable` when `Vertex` is, `Codable` when `Vertex` is,
`CustomStringConvertible`, `CustomDebugStringConvertible`. Not `Comparable`. `Forest.Trees`,
`RootedTree.Preorder` and the other views are `Sendable` under the same condition.

## Semantics

### What is a tree here

* **Tree**: at least one vertex, connected, acyclic; a self-loop and a parallel pair are cycles,
  so a tree has neither and has exactly n − 1 edges. There is no empty tree: a `RootedTree` needs
  a root and every `Tree` converts to one (TS-001).
* **Forest**: acyclic; the empty forest exists (TS-003). Isolated vertices are one-vertex trees.
* **Arborescence**: at least one vertex, exactly one vertex (the root) of in-degree 0, every
  other of in-degree 1, n − 1 arcs, every vertex reachable from the root. In-degree ≤ 1 and n − 1
  arcs do not imply reachability (TS-068: a root plus a separate 2-cycle). `ref.py` checks the
  predicate against NetworkX's `is_arborescence` on every `D:` case.
* `isTree` ⇔ `Tree(g) != nil`, `isArborescence` ⇔ `Arborescence(g) != nil`, and
  `isAcyclic` (Cycles) ⇔ `Forest(g) != nil` (checked on every case).
* A digraph whose underlying graph is a tree (a polytree) is `digraph.undirectedView.isTree`
  (TS-054).

### Failure is `nil`

Every initializer from unchecked input is failable. The witnesses for a rejection are
`g.findCycle()` (Cycles) for a cycle and `g.connectedComponents()` (Connectivity) for
disconnection. A root that is not a vertex is a precondition, as for Cycles' `findCycle(from:)`
(TS-109); a query on a non-vertex traps, as `DominatorTree`'s do (TS-246, TS-315). Each such
query also has a `checked:` spelling that throws `VertexNotFound` instead, or `EdgeNotFound` for
an `Arborescence` edge position, with the same lookup as the trapping spelling; a nil the plain
spelling returns (the root's parent, a path across trees or not downward) keeps its meaning (§L,
TS-900 – TS-995).

### Vertex order and edge positions

* From a graph: the graph's `vertices` order and its edges at their positions (TS-030, TS-063),
  so position k of the tree is position k of the graph. Rows are rebuilt in **position order**,
  whatever the graph's `incidentEdges` order (a representation after removals): a tree's rows
  are canonical.
* From `vertices:edges:`: the listed vertices with duplicates dropped, then endpoints by first
  appearance, edges in the order given: `UndirectedAdjacencyList(vertices:edges:)`'s rule
  (TS-100 – TS-102). The same edge written twice (either orientation) is a parallel pair (TS-011).
* From a parent function: `vertices` with duplicates dropped (TS-165); one edge per non-root
  vertex, **in vertex order**, `(parent, child)` (TS-151, TS-163). Fails on no root or several
  (TS-153, TS-154), a parent outside `vertices` (TS-156, TS-164), a self-parent (TS-155), or a
  cycle (TS-157). In `init?(parents: [Int?])` the root's entry is `nil`; a negative entry is an
  out-of-range parent, not a root (TS-158).
* Conversions keep vertices and positions: `Tree(rooted)`, `RootedTree(tree, root:)`,
  `Arborescence(rooted)`, `RootedTree(arborescence)`, `Forest(tree)` (TS-112, TS-241, TS-607).
  `RootedTree → Arborescence` orients every edge parent → child (TS-607). There is no
  `Tree(forest)`; a forest's trees are `forest.trees[i]` (TS-111, TS-113, TS-406).
* Prüfer decoding: vertices `0..<n`, edges in decoding order, edge k joining the k-th removed
  leaf to the k-th code element, the last edge joining the two remaining vertices (TS-501,
  TS-510). The linear decoder (Wang et al.) emits edges in the same order as the textbook
  least-leaf loop (checked).

### Rooted queries

* `children(of:)`: the vertex's incidence row without its parent edge, so **in position order of
  the child edges**, not vertex order (TS-225). After rerooting, the old parent is wherever its
  edge sits in the row (TS-219). From a parent function, edges are numbered in vertex order, so
  children come in vertex order (TS-160), which is `DominatorTree.children(of:)`'s order.
* `preorder`: root, then each child's subtree in `children` order (`ref.py` checks it against
  NetworkX's `dfs_preorder_nodes` on the same adjacency order on every rooted case).
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

The least-ranked leaf goes first. When `Vertex` is `Int` and the vertices are exactly `0..<n`, in
any order, a vertex's rank is its **value**: the code is the standard one, and
`Tree(pruferSequence:)` decodes it back to an equal tree (TS-515: `[1,2]` for vertices listed
`[3,0,1,2]`; TS-519, TS-520). Otherwise the rank is the **vertex index** (`vertices` order), giving
the code of the tree relabeled by index (TS-514 for `String`s; TS-518 for `Int`s `1...4`, `[3,2]`
where ranking by value would give `[2,3]`). Detecting `0..<n` is one O(n) pass. nil for fewer than
2 vertices (TS-504); the empty code decodes to K₂ (TS-502). Decoding rejects elements outside
`0..<count+2` (TS-506, TS-507).

### Equality, hashing, coding

Equality is **equal vertex sets and equal edge sets**, regardless of order and (undirected)
orientation (TS-700); `RootedTree` also compares the root (TS-703); `Arborescence` compares arcs
as ordered pairs, which fixes the root (TS-705). So two equal values can differ in
`children(of:)` order or edge positions, as two equal adjacency lists can differ in row order. An
edge {u, v} of the left side is tested on the right as `parent(u) == v || parent(v) == u` in the
right side's internal rooting, so `==` is O(n). `hash(into:)` is a commutative sum of per-vertex
and per-edge hashes, as for `UndirectedAdjacencyList` (an `UndirectedEdge` hashes without
orientation). `Codable` uses the `UndirectedAdjacencyList` format (vertices, then edges as pairs of
vertex offsets; `RootedTree` adds the root's offset); decoding re-checks the invariant and throws
`DecodingError.dataCorrupted`, and also rejects a repeated vertex.

### Attached maps and generations

All four types are `PropertyGraph`s (GraphProtocols). A tree never changes, so each map is one
dense array, allocated in full when attached: a vertex map by vertex index (the order of
`vertices`), an edge map by edge position. A read through `values(of:)` is one array load. The
plain subscripts trap off the tree; `[map, checkedVertexAt:]`, `[map, checked:]` and
`[map, checkedEdgeAt:]` throw `VertexNotFound` or `EdgeNotFound`.

Every initializer stamps a generation, which nothing advances. A conversion (`RootedTree(tree,
root:)`, `Arborescence(rooted)`, `Tree(rooted)`, `Forest(tree)`, `forest.trees[k]`) keeps vertex
indices and edge positions but is a new graph: it has its own generation and no maps, so a
handle from the source traps on it. Equality, hashing and coding ignore maps and generations.

## Complexity

| Operation | Cost |
|---|---|
| `isTree`, `isArborescence` | O(1) when the edge count is not n − 1; else O(n), with a visited mark and a stack |
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

* **One layout for all four types.** `_TreeLayout` holds, with vertex numbers 0..<n in `vertices`
  order: `ends` (2 per edge), `rowOffsets` (n + 1), `rowNeighbors` and `rowEdges` (2(n − 1)) for
  the incidence rows (a counting sort over edges in position order leaves every row ascending),
  `twin` (each row slot's offset in the other end's row), and the **rooting**: a root per tree,
  the preorder, and one `_TreeNode` record of `Int32`s per vertex (parent, parent edge, offset of
  the parent edge in the row, depth, preorder position, subtree size, tree). `Tree` stores a
  rooting at vertex 0, which is never observable but makes `path(from:to:)` O(length) and
  `Tree ↔ RootedTree` O(1); `Forest` roots each tree at its least vertex, and keeps the vertices
  and edges grouped by tree (counting sort, stable) so `trees[i]` copies contiguous runs.
* **Children without a children array.** `children(of: v)` is v's row with one hole, the parent
  edge at its row offset: a `RandomAccessCollection` with O(1) `count` and subscript.
  `Arborescence.outEdges(of:)` is the same view over edge positions; `inEdges(of:)` and
  `predecessors(of:)` hold zero or one element.
* **No recursion.** The rooting is one iterative depth-first walk with a stack of
  (vertex, row cursor), skipping the parent edge by position (not the parent vertex, so a
  parallel pair is found). It writes each vertex's record when the vertex is reached and adds its
  subtree size to its parent's when it is left. `postorder` needs no second walk:
  post(v) = pre(v) + size(v) − 1 − depth(v) (checked on every rooted case). `path` climbs
  `parent` by `depth`. The 10⁶-vertex path (TS-801 – TS-806), the 10⁶-leaf star (TS-807) and the
  10⁶-vertex binary tree (TS-812) are the stress shapes.
* **Validation.** Undirected tree: n ≥ 1, m == n − 1, and the walk reaches n vertices; with
  m = n − 1 connectivity implies acyclicity, and a loop or a parallel pair leaves a vertex
  unreached (TS-020, TS-025). Forest: m ≤ n − 1, then one walk from each vertex not yet reached;
  reaching a vertex twice is a cycle. Arborescence: in-degree counts (> 1 fails at once), one
  root, then the walk from the root, which fails on an arc pointing toward it and must reach n
  (TS-068). Parent function: gather parent numbers (one dictionary lookup each), exactly one
  root, no self-parent, then the walk from the root reaches n iff there is no cycle.
* **Reading the source graph.** With vertex and edge indices, the build reads the index-space
  rows, so building a `Tree` from an `UndirectedAdjacencyList` hashes nothing; otherwise it makes
  one pass over `edges` with a vertex dictionary. `isTree` reads the same rows.
* **Vertex lookup.** When `Vertex == Int` and the vertices are exactly `0..<n` in order (every
  `init?(parents:)`, Prüfer, most index-space use), a flag replaces the table and
  `vertexIndex(of: v)` is `v` after a bounds check. Trees of at most 8 vertices find a vertex by a
  linear scan; larger ones use a vertex → number dictionary.
* **Dependencies.** Trees depends on GraphProtocols and Walks (for `Path`).
