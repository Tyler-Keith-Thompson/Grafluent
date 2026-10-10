# Trees: case catalog (TS-001 – TS-813)

Cases for the Trees module's phase 1 (api.md): `Graph.isTree`, `DirectedGraph.isArborescence`,
the four types' failable initializers, the parent-function initializers, the rooted queries,
`path(from:to:)`, `Forest.trees` / `component(of:)`, Prüfer codes, the `Graph` /
`BidirectionalDirectedGraph` rows, and equality. Harvested from NetworkX
(`tree/tests/test_recognition.py`, `test_coding.py`, `traversal/tests/test_dfs.py`), igraph
(`igraph_is_tree.c`, `igraph_is_forest.c`, `igraph_to_prufer.c`, `igraph_from_prufer.c`,
`igraph_tree_from_parent_vector.c`), JGraphT (`GraphTestsTest`), LEMON (`connectivity_test.cc`)
and the edge cases the design calls out. Every value is recomputed by `ref.py` and checked
against a naive implementation and NetworkX 3.7 (see its docstring). IDs are `TS-` because
Traversal already owns `TR-`.

## Notation

**Source** (read by `ref.py`):

| Form | Meaning |
|---|---|
| `U: [vertices] edges` | an undirected graph (`ReferencePseudograph(vertices:edges:)`): the listed vertices (duplicates dropped, first kept), then endpoints by first appearance; edges in **position order** |
| `D: [vertices] arcs` | a directed graph (`ReferenceDirectedMultigraph`), the same way |
| `u-v`, `u>v` | one edge, one arc. Vertices are integers or identifiers (`String`) |
| `P(a,b,c,…)` | the path a–b, b–c, … (arcs in a `D:` graph) |
| `C(a,b,…,z)` | the cycle a–b, …, z–a |
| `S(c;a..b)` | the star c–a, …, c–b |
| `kary(n,k)` | igraph `kary_tree`: vertex i to k·i+1 … k·i+k below n, in that order |
| `a..b` | every integer from a to b inclusive |
| `parents: [p0, p1, …]` | `Arborescence<Int>(parents:)` / `RootedTree<Int>(parents:)`: vertex i has parent pᵢ; `_` is `nil` (the root) |
| `closure: [vertices] {child:parent, …}` | `init?(vertices:parent:)` with `parent` the dictionary lookup (absent = `nil`) |
| `prufer: [s…]` | `Tree<Int>(pruferSequence:)` |

**Op**: a predicate (`isTree`, `isArborescence`, `isAcyclic`), or a chain of constructions
`Step > Step > … : query`. The first step builds from the source (`Tree` is `Tree(g)`,
`Forest` is `Forest(g)`, `RootedTree(root: r)` is `RootedTree(g, root: r)`, `Arborescence` is
`Arborescence(g)` or the parent initializer); later steps convert (`Tree(rooted)`,
`RootedTree(tree, root: r)`, `Arborescence(rooted)`, `RootedTree(arborescence)`,
`Forest(tree)`). With no query the case asks whether construction succeeds. `X == source as
Chain` compares two values with `==`.

**Expected**: `nil` (the failable initializer, or `path`, returns `nil`), `trap` (a
precondition), `T`/`F`, `#k`, a vertex, a list `[a,b,…]` in order, a list of edges `[u-v,…]` by
position (`u>v` for arcs: source then target; an undirected edge's stored orientation is not part
of its value), a path `[vertices]/[edge positions]`, or a forest's trees `[vertices]/[edges]; …`
in order (`none` when there are none).

Unless a case says otherwise: a tree's incidence rows are in position order, `children(of:)` is
in position order of the child edges, `preorder` and `postorder` visit children in that order,
`descendants(of:)` is the subtree in preorder without the vertex, `ancestors(of:)` runs from the
parent up to the root, and `isAncestor(_:of:)` is strict.

## A. Recognition, undirected (`isTree`, `Tree(g)`, `Forest(g)`)

| ID | Source | Op | Expected | Notes |
|---|---|---|---|---|
| TS-001 | `U: []` | `isTree` | `F` | The null graph is not a tree: igraph, JGraphT agree; NetworkX raises `NetworkXPointlessConcept`; LEMON's `tree()` says true |
| TS-002 | `U: []` | `Tree` | `nil` | No empty `Tree`: a `RootedTree` needs a root, and `Tree` converts to one |
| TS-003 | `U: []` | `Forest : treeCount` | `#0` | The empty forest exists (igraph `is_forest` true, LEMON `acyclic` true; JGraphT `isForest` false despite its own doc comment; NetworkX raises) |
| TS-004 | `U: []` | `isAcyclic` | `T` | Cycles' predicate, the same as `Forest(g) != nil` |
| TS-005 | `U: [0]` | `isTree` | `T` | K₁ |
| TS-006 | `U: [0]` | `Tree : edgeCount` | `#0` | |
| TS-007 | `U: 0-0` | `isTree` | `F` | One vertex, one self-loop: m = n but not a tree |
| TS-008 | `U: 0-0` | `Forest` | `nil` | A self-loop is a cycle |
| TS-009 | `U: 0-1` | `isTree` | `T` | K₂ |
| TS-010 | `U: 0-1, 0-1` | `isTree` | `F` | Parallel pair: a 2-cycle |
| TS-011 | `U: 0-1, 1-0` | `Forest` | `nil` | The same edge written both ways is still two edges |
| TS-012 | `U: [0,1]` | `isTree` | `F` | Two isolated vertices: acyclic, disconnected |
| TS-013 | `U: [0,1]` | `Forest : treeCount` | `#2` | |
| TS-014 | `U: P(0..4)` | `isTree` | `T` | |
| TS-015 | `U: C(0,1,2)` | `isTree` | `F` | |
| TS-016 | `U: C(0,1,2)` | `isAcyclic` | `F` | |
| TS-017 | `U: S(0;1..5)` | `isTree` | `T` | |
| TS-018 | `U: 0-1, 2-3` | `isTree` | `F` | m = n − 2 |
| TS-019 | `U: 0-1, 2-3` | `Forest : treeCount` | `#2` | |
| TS-020 | `U: 0-1, 1-2, 2-0, 3-4` | `isTree` | `F` | m = n − 1 but a cycle and two components: the edge count alone is not enough |
| TS-021 | `U: 0-1, 1-2, 2-0, 3-4` | `Forest` | `nil` | |
| TS-022 | `U: [5] 0-1, 1-2, 2-3` | `isTree` | `F` | A tree plus an isolated vertex |
| TS-023 | `U: [5] 0-1, 1-2, 2-3` | `Forest : treeCount` | `#2` | |
| TS-024 | `U: 0-1, 1-1` | `isTree` | `F` | m = n − 1 + 1; a loop on a leaf |
| TS-025 | `U: [0,1,2] 0-1, 1-1` | `isTree` | `F` | m = n − 1, but 2 is isolated: the loop used up the edge that would have connected it |
| TS-026 | `U: kary(15,2)` | `isTree` | `T` | igraph `igraph_is_tree.c`: a binary tree |
| TS-027 | `U: a-b, b-c, b-d` | `isTree` | `T` | `String` vertices |
| TS-028 | `U: a-b, b-c, c-a` | `Tree` | `nil` | |
| TS-029 | `U: P(0..3), 3-0` | `Forest` | `nil` | Closing edge last: union–find fails at position 3 |
| TS-030 | `U: 0-1, 2-3, 1-2` | `Tree : edges` | `[0-1,2-3,1-2]` | Edges keep the graph's positions, in its order |

## B. Recognition, directed (`isArborescence`, `Arborescence(g)`)

| ID | Source | Op | Expected | Notes |
|---|---|---|---|---|
| TS-050 | `D: []` | `isArborescence` | `F` | NetworkX raises on the null graph |
| TS-051 | `D: [0]` | `Arborescence : root` | `#0` | |
| TS-052 | `D: 0>1, 0>2` | `Arborescence : root` | `#0` | |
| TS-053 | `D: 1>0, 2>0` | `isArborescence` | `F` | An in-tree (igraph `IGRAPH_IN`): in-degree 2 at 0 |
| TS-054 | `D: 0>1, 2>1` | `isArborescence` | `F` | A polytree that is not an arborescence |
| TS-055 | `D: C(0,1,2)` | `isArborescence` | `F` | No root |
| TS-056 | `D: 0>1, 1>2, 2>1` | `isArborescence` | `F` | m = n; in-degree 2 at 1 |
| TS-057 | `D: 0>1, 0>1` | `isArborescence` | `F` | Parallel arcs |
| TS-058 | `D: 0>0` | `isArborescence` | `F` | Self-loop |
| TS-059 | `D: 0>1, 1>0` | `isArborescence` | `F` | Opposite arcs |
| TS-060 | `D: 0>1, 2>3` | `isArborescence` | `F` | A branching (NetworkX `is_branching`), not an arborescence |
| TS-061 | `D: [0,1]` | `isArborescence` | `F` | Two roots |
| TS-062 | `D: 3>1, 1>0, 1>2` | `Arborescence : root` | `#3` | The root is not the first vertex |
| TS-063 | `D: 1>2, 0>1` | `Arborescence : edges` | `[1>2,0>1]` | Positions kept |
| TS-064 | `D: 0>1, 0>2, 2>3, 3>4` | `isArborescence` | `T` | NetworkX `is_arborescence` docstring |
| TS-065 | `D: 0>2, 1>2, 2>3, 3>4` | `isArborescence` | `F` | The same after `remove_edge(0, 1); add_edge(1, 2)` |
| TS-066 | `D: x>y, x>z, z>w` | `Arborescence : children(x)` | `[y,z]` | `String` vertices |
| TS-067 | `D: [0,1,2] 0>1, 1>1` | `isArborescence` | `F` | m = n − 1; the loop makes 1's in-degree 2, and 2 is a second root |
| TS-068 | `D: [0,1,2,3] 0>1, 2>3, 3>2` | `isArborescence` | `F` | m = n − 1, in-degrees ≤ 1, exactly one root (0), but 2 and 3 are not reached: the reachability test is needed |

## C. Construction: vertex order, positions, duplicates

| ID | Source | Op | Expected | Notes |
|---|---|---|---|---|
| TS-100 | `U: [2,0,1] 0-1, 1-2` | `Tree : vertices` | `[2,0,1]` | Listed vertices first, in the order given |
| TS-101 | `U: [2,2,0] 0-1, 1-2` | `Tree : vertices` | `[2,0,1]` | A duplicate in `vertices` is dropped (as `UndirectedAdjacencyList(vertices:edges:)` inserts) |
| TS-102 | `U: [0] 0-1, 1-2` | `Tree : vertices` | `[0,1,2]` | Endpoints missing from `vertices` are added by first appearance |
| TS-103 | `U: 2-1, 1-0` | `Tree : vertices` | `[2,1,0]` | |
| TS-104 | `U: 2-1, 1-0` | `Tree : edges` | `[2-1,1-0]` | |
| TS-105 | `U: b-a, c-a, a-d` | `Tree : incidentEdges(a)` | `[0,1,2]` | Rows in position order |
| TS-106 | `U: b-a, c-a, a-d` | `Tree : neighbors(a)` | `[b,c,d]` | |
| TS-107 | `U: [x]` | `Tree : vertices` | `[x]` | One `String` vertex, no edges |
| TS-108 | `U: [x]` | `RootedTree(root: x) : height` | `#0` | |
| TS-109 | `U: 0-1` | `RootedTree(root: 7)` | `trap` | A root that is not a vertex: precondition, like `findCycle(from:)` |
| TS-110 | `U: 0-1, 1-2, 2-0` | `RootedTree(root: 0)` | `nil` | Not a tree: `nil` |
| TS-111 | `U: 0-1` | `Tree > Forest > Tree` | `trap` | `Tree(forest)` is not offered (a forest is not one tree); the ref models it as a trap |
| TS-112 | `U: 0-1, 1-2` | `Tree > RootedTree(root: 2) > Tree : edges` | `[0-1,1-2]` | Forgetting the root keeps positions |
| TS-113 | `U: 0-1, 1-2` | `Forest > RootedTree(root: 0)` | `trap` | No `RootedTree(forest)` either |

## D. Parent functions (`init?(parents:)`, `init?(vertices:parent:)`)

| ID | Source | Op | Expected | Notes |
|---|---|---|---|---|
| TS-150 | `parents: [_]` | `Arborescence : root` | `#0` | |
| TS-151 | `parents: [_,0,0,1]` | `Arborescence : edges` | `[0>1,0>2,1>3]` | One edge per non-root vertex, in vertex order (igraph `igraph_tree_from_parent_vector`) |
| TS-152 | `parents: [1,_]` | `Arborescence : root` | `#1` | |
| TS-153 | `parents: [_,_]` | `Arborescence` | `nil` | Two roots: a branching, not a tree |
| TS-154 | `parents: [1,0]` | `Arborescence` | `nil` | No root: a cycle |
| TS-155 | `parents: [0]` | `Arborescence` | `nil` | Self-parent. Boost marks the root this way (`p[r] == r`); igraph rejects it as a self-loop, and so do we |
| TS-156 | `parents: [_,5]` | `Arborescence` | `nil` | A parent that is not a vertex |
| TS-157 | `parents: [_,2,1]` | `Arborescence` | `nil` | A root and a 2-cycle beside it |
| TS-158 | `parents: [_,-1]` | `Arborescence` | `nil` | Negative is not `nil` (igraph uses negatives for roots; Swift has `Optional`) |
| TS-159 | `parents: []` | `Arborescence` | `nil` | Empty |
| TS-160 | `parents: [3,3,1,_,1]` | `Arborescence : children(1)` | `[2,4]` | Children in vertex order |
| TS-161 | `parents: [3,3,1,_,1]` | `RootedTree : preorder` | `[3,0,1,2,4]` | |
| TS-162 | `closure: [a,b,c,d] {b:a, c:a, d:c}` | `Arborescence : edges` | `[a>b,a>c,c>d]` | |
| TS-163 | `closure: [d,c,b,a] {b:a, c:a, d:c}` | `Arborescence : edges` | `[c>d,a>c,a>b]` | Vertex order decides edge positions |
| TS-164 | `closure: [a,b,c] {b:a, c:z}` | `Arborescence` | `nil` | Parent outside `vertices` |
| TS-165 | `closure: [a,b,b,c] {b:a, c:b}` | `Arborescence : vertices` | `[a,b,c]` | Duplicate dropped |
| TS-166 | `closure: [a,b,c] {a:b, b:c, c:a}` | `RootedTree` | `nil` | |
| TS-167 | `closure: [r] {}` | `RootedTree : root` | `r` | |
| TS-168 | `parents: [_,0,1,2,3,4,5,6,7,8]` | `Arborescence : depth(9)` | `#9` | |
| TS-169 | `closure: [a,b,c,d] {b:a, c:b, d:c}` | `Arborescence == D: a>b, b>c, c>d as Arborescence` | `T` | Same vertices and arcs |

## E. Rooted queries

Tree E1 is `U: 0-1, 0-2, 1-3, 1-4, 2-5, 4-6`; E2 is `U: 4-2, 0-2, 2-1, 1-3` (positions not in
vertex order).

| ID | Source | Op | Expected | Notes |
|---|---|---|---|---|
| TS-200 | `U: 0-1, 0-2, 1-3, 1-4, 2-5, 4-6` | `RootedTree(root: 0) : preorder` | `[0,1,3,4,6,2,5]` | |
| TS-201 | `U: 0-1, 0-2, 1-3, 1-4, 2-5, 4-6` | `RootedTree(root: 0) : postorder` | `[3,6,4,1,5,2,0]` | |
| TS-202 | `U: 0-1, 0-2, 1-3, 1-4, 2-5, 4-6` | `RootedTree(root: 0) : children(1)` | `[3,4]` | |
| TS-203 | `U: 0-1, 0-2, 1-3, 1-4, 2-5, 4-6` | `RootedTree(root: 0) : parent(6)` | `#4` | |
| TS-204 | `U: 0-1, 0-2, 1-3, 1-4, 2-5, 4-6` | `RootedTree(root: 0) : parent(0)` | `nil` | |
| TS-205 | `U: 0-1, 0-2, 1-3, 1-4, 2-5, 4-6` | `RootedTree(root: 0) : parentEdge(6)` | `#5` | |
| TS-206 | `U: 0-1, 0-2, 1-3, 1-4, 2-5, 4-6` | `RootedTree(root: 0) : parentEdge(0)` | `nil` | |
| TS-207 | `U: 0-1, 0-2, 1-3, 1-4, 2-5, 4-6` | `RootedTree(root: 0) : depth(6)` | `#3` | |
| TS-208 | `U: 0-1, 0-2, 1-3, 1-4, 2-5, 4-6` | `RootedTree(root: 0) : height` | `#3` | |
| TS-209 | `U: 0-1, 0-2, 1-3, 1-4, 2-5, 4-6` | `RootedTree(root: 0) : descendants(1)` | `[3,4,6]` | A preorder slice |
| TS-210 | `U: 0-1, 0-2, 1-3, 1-4, 2-5, 4-6` | `RootedTree(root: 0) : descendants(1).count` | `#3` | Subtree size − 1, O(1) |
| TS-211 | `U: 0-1, 0-2, 1-3, 1-4, 2-5, 4-6` | `RootedTree(root: 0) : descendants(6)` | `[]` | A leaf |
| TS-212 | `U: 0-1, 0-2, 1-3, 1-4, 2-5, 4-6` | `RootedTree(root: 0) : ancestors(6)` | `[4,1,0]` | Nearest first |
| TS-213 | `U: 0-1, 0-2, 1-3, 1-4, 2-5, 4-6` | `RootedTree(root: 0) : ancestors(0)` | `[]` | |
| TS-214 | `U: 0-1, 0-2, 1-3, 1-4, 2-5, 4-6` | `RootedTree(root: 0) : isAncestor(1,6)` | `T` | |
| TS-215 | `U: 0-1, 0-2, 1-3, 1-4, 2-5, 4-6` | `RootedTree(root: 0) : isAncestor(6,6)` | `F` | Strict, as `ancestors(of:)` and NetworkX `ancestors`; Swing's `isNodeAncestor` and `DominatorTree.dominates` are reflexive |
| TS-216 | `U: 0-1, 0-2, 1-3, 1-4, 2-5, 4-6` | `RootedTree(root: 0) : isAncestor(2,6)` | `F` | Different branches |
| TS-217 | `U: 0-1, 0-2, 1-3, 1-4, 2-5, 4-6` | `RootedTree(root: 0) : isAncestor(6,1)` | `F` | Reversed |
| TS-218 | `U: 0-1, 0-2, 1-3, 1-4, 2-5, 4-6` | `RootedTree(root: 4) : preorder` | `[4,1,0,2,5,3,6]` | Rerooted at an inner vertex: the edges on the old root's path turn around |
| TS-219 | `U: 0-1, 0-2, 1-3, 1-4, 2-5, 4-6` | `RootedTree(root: 4) : children(4)` | `[1,6]` | The former parent comes first: rows in position order |
| TS-220 | `U: 0-1, 0-2, 1-3, 1-4, 2-5, 4-6` | `RootedTree(root: 4) : parent(0)` | `#1` | |
| TS-221 | `U: 0-1, 0-2, 1-3, 1-4, 2-5, 4-6` | `RootedTree(root: 6) : height` | `#5` | |
| TS-222 | `U: 0-1, 0-2, 1-3, 1-4, 2-5, 4-6` | `RootedTree(root: 6) : ancestors(5)` | `[2,0,1,4,6]` | |
| TS-223 | `U: 0-1, 0-2, 1-3, 1-4, 2-5, 4-6` | `Tree > RootedTree(root: 5) > Tree > RootedTree(root: 0) : preorder` | `[0,1,3,4,6,2,5]` | Round trip through `Tree` equals rooting directly (TS-200) |
| TS-224 | `U: 4-2, 0-2, 2-1, 1-3` | `RootedTree(root: 0) : preorder` | `[0,2,4,1,3]` | E2 |
| TS-225 | `U: 4-2, 0-2, 2-1, 1-3` | `RootedTree(root: 0) : children(2)` | `[4,1]` | By child-edge position (4 at 0, 1 at 2), not vertex order |
| TS-226 | `U: 4-2, 0-2, 2-1, 1-3` | `RootedTree(root: 0) : postorder` | `[4,3,1,2,0]` | |
| TS-227 | `U: 4-2, 0-2, 2-1, 1-3` | `RootedTree(root: 0) : parentEdge(4)` | `#0` | |
| TS-228 | `U: [0]` | `RootedTree(root: 0) : preorder` | `[0]` | |
| TS-229 | `U: [0]` | `RootedTree(root: 0) : descendants(0)` | `[]` | |
| TS-230 | `U: S(0;1..5)` | `RootedTree(root: 0) : children(0)` | `[1,2,3,4,5]` | |
| TS-231 | `U: S(0;1..5)` | `RootedTree(root: 3) : preorder` | `[3,0,1,2,4,5]` | A star rooted at a leaf |
| TS-232 | `U: S(0;1..5)` | `RootedTree(root: 3) : height` | `#2` | |
| TS-233 | `U: P(0..5)` | `RootedTree(root: 3) : children(3)` | `[2,4]` | |
| TS-234 | `U: P(0..5)` | `RootedTree(root: 3) : postorder` | `[0,1,2,5,4,3]` | |
| TS-235 | `U: kary(15,2)` | `RootedTree(root: 0) : preorder` | `[0,1,3,7,8,4,9,10,2,5,11,12,6,13,14]` | |
| TS-236 | `U: kary(15,2)` | `RootedTree(root: 0) : postorder` | `[7,8,3,9,10,4,1,11,12,5,13,14,6,2,0]` | |
| TS-237 | `U: kary(15,2)` | `RootedTree(root: 0) : descendants(2)` | `[5,11,12,6,13,14]` | |
| TS-238 | `U: kary(15,2)` | `RootedTree(root: 0) : height` | `#3` | |
| TS-239 | `D: 0>1, 0>2, 1>3, 1>4, 2>5, 4>6` | `Arborescence : preorder` | `[0,1,3,4,6,2,5]` | The arborescence of E1 |
| TS-240 | `D: 0>1, 0>2, 1>3, 1>4, 2>5, 4>6` | `Arborescence > RootedTree : postorder` | `[3,6,4,1,5,2,0]` | `RootedTree(arborescence)` keeps the root |
| TS-241 | `D: 0>1, 0>2, 1>3, 1>4, 2>5, 4>6` | `Arborescence > RootedTree > Tree > RootedTree(root: 4) > Arborescence : edges` | `[1>0,0>2,1>3,4>1,2>5,4>6]` | Rerooting flips the arcs on the 0–4 path |
| TS-242 | `D: 2>3, 2>0, 0>1` | `Arborescence : children(2)` | `[3,0]` | Out-edges in position order |
| TS-243 | `D: 2>3, 2>0, 0>1` | `Arborescence : depth(1)` | `#2` | |
| TS-244 | `U: ann-bob, ann-cy, cy-dee` | `RootedTree(root: dee) : preorder` | `[dee,cy,ann,bob]` | `String` vertices |
| TS-245 | `U: ann-bob, ann-cy, cy-dee` | `RootedTree(root: dee) : ancestors(bob)` | `[ann,cy,dee]` | |
| TS-246 | `U: 0-1, 0-2, 1-3, 1-4, 2-5, 4-6` | `RootedTree(root: 0) : depth(9)` | `trap` | Not a vertex: precondition |

## F. Paths (`path(from:to:)`)

| ID | Source | Op | Expected | Notes |
|---|---|---|---|---|
| TS-300 | `U: 0-1, 0-2, 1-3, 1-4, 2-5, 4-6` | `Tree : path(6,5)` | `[6,4,1,0,2,5]/[5,3,0,1,4]` | Up to the meeting vertex, then down; edges by position |
| TS-301 | `U: 0-1, 0-2, 1-3, 1-4, 2-5, 4-6` | `Tree : path(5,6)` | `[5,2,0,1,4,6]/[4,1,0,3,5]` | The reverse of TS-300 |
| TS-302 | `U: 0-1, 0-2, 1-3, 1-4, 2-5, 4-6` | `Tree : path(3,3)` | `[3]/[]` | Trivial |
| TS-303 | `U: 0-1, 0-2, 1-3, 1-4, 2-5, 4-6` | `Tree : path(3,4)` | `[3,1,4]/[2,3]` | Siblings |
| TS-304 | `U: 0-1, 0-2, 1-3, 1-4, 2-5, 4-6` | `RootedTree(root: 6) : path(3,5)` | `[3,1,0,2,5]/[2,0,1,4]` | The same path whatever the root |
| TS-305 | `U: 0-1, 0-2, 1-3, 1-4, 2-5, 4-6` | `Tree : path(3,5)` | `[3,1,0,2,5]/[2,0,1,4]` | |
| TS-306 | `U: 0-1, 0-2, 1-3, 1-4, 2-5, 4-6` | `RootedTree(root: 0) : path(0,6)` | `[0,1,4,6]/[0,3,5]` | |
| TS-307 | `D: 0>1, 0>2, 1>3, 1>4, 2>5, 4>6` | `Arborescence : path(0,6)` | `[0,1,4,6]/[0,3,5]` | Down the tree |
| TS-308 | `D: 0>1, 0>2, 1>3, 1>4, 2>5, 4>6` | `Arborescence : path(6,0)` | `nil` | Against the arcs: `nil` |
| TS-309 | `D: 0>1, 0>2, 1>3, 1>4, 2>5, 4>6` | `Arborescence : path(3,5)` | `nil` | No directed path |
| TS-310 | `D: 0>1, 0>2, 1>3, 1>4, 2>5, 4>6` | `Arborescence : path(4,4)` | `[4]/[]` | |
| TS-311 | `U: 0-1, 2-3, 3-4` | `Forest : path(2,4)` | `[2,3,4]/[1,2]` | |
| TS-312 | `U: 0-1, 2-3, 3-4` | `Forest : path(0,4)` | `nil` | Different trees |
| TS-313 | `U: 4-2, 0-2, 2-1, 1-3` | `Tree : path(4,3)` | `[4,2,1,3]/[0,2,3]` | |
| TS-314 | `U: a-b, b-c, b-d` | `Tree : path(d,c)` | `[d,b,c]/[2,1]` | |
| TS-315 | `U: 0-1, 0-2, 1-3, 1-4, 2-5, 4-6` | `Tree : path(0,9)` | `trap` | Not a vertex |

## G. Forest

| ID | Source | Op | Expected | Notes |
|---|---|---|---|---|
| TS-400 | `U: 0-1, 2-3, 3-4` | `Forest : trees` | `[0,1]/[0-1]; [2,3,4]/[2-3,3-4]` | By least vertex; each tree's vertices and edges in the forest's order, edges renumbered from 0 |
| TS-401 | `U: [5,4,3] 0-1, 2-3, 3-4` | `Forest : trees` | `[5]/[]; [4,3,2]/[2-3,3-4]; [0,1]/[0-1]` | The listed order decides which tree comes first |
| TS-402 | `U: 3-4, 0-1, 2-3` | `Forest : trees` | `[3,4,2]/[3-4,2-3]; [0,1]/[0-1]` | |
| TS-403 | `U: 3-4, 0-1, 2-3` | `Forest : component(2)` | `#0` | `Components.component(of:)`'s shape |
| TS-404 | `U: [0,1,2,3]` | `Forest : trees` | `[0]/[]; [1]/[]; [2]/[]; [3]/[]` | Every vertex its own tree |
| TS-405 | `U: []` | `Forest : trees` | `none` | |
| TS-406 | `U: 0-1, 1-2` | `Tree > Forest : trees` | `[0,1,2]/[0-1,1-2]` | `Forest(tree)` |
| TS-407 | `U: 0-1, 1-2` | `Forest : edges` | `[0-1,1-2]` | `Forest` is a `Graph` with the source's positions |
| TS-408 | `U: a-b, c-d, e-c` | `Forest : trees` | `[a,b]/[a-b]; [c,d,e]/[c-d,e-c]` | `String` vertices |
| TS-409 | `U: 0-1, 2-3, 3-4` | `Forest : treeCount` | `#2` | `trees.count` |
| TS-410 | `U: [9] 0-1, 2-3, 3-4` | `Forest : component(9)` | `#0` | |
| TS-411 | `U: 0-1, 2-3, 3-4, 4-2` | `Forest` | `nil` | |
| TS-412 | `U: 0-1, 2-3, 2-3` | `Forest` | `nil` | Parallel edges in a second tree |

## H. Prüfer codes

| ID | Source | Op | Expected | Notes |
|---|---|---|---|---|
| TS-500 | `U: 0-3, 1-3, 2-3, 3-4, 4-5` | `Tree : prufer` | `[3,3,3,4]` | NetworkX `test_coding.py` `test_known_tree` / docstring: `[3, 3, 3, 4]` |
| TS-501 | `prufer: [3,3,3,4]` | `Tree : edges` | `[0-3,1-3,2-3,3-4,4-5]` | Its inverse; edges in decoding order (least leaf first) |
| TS-502 | `prufer: []` | `Tree : edges` | `[0-1]` | The empty code is K₂ (n = 2) |
| TS-503 | `U: 0-1` | `Tree : prufer` | `[]` | |
| TS-504 | `U: [0]` | `Tree : prufer` | `nil` | Undefined for n < 2: `nil` (NetworkX raises `NetworkXPointlessConcept`, igraph `IGRAPH_EINVAL`) |
| TS-505 | `prufer: [2]` | `Tree : edges` | `[0-2,1-2]` | |
| TS-506 | `prufer: [3]` | `Tree` | `nil` | Out of range (n = 3): `nil` (NetworkX `NetworkXError`, igraph `IGRAPH_EINVAL`) |
| TS-507 | `prufer: [-1]` | `Tree` | `nil` | |
| TS-508 | `U: P(0..9)` | `Tree : prufer` | `[1,2,3,4,5,6,7,8]` | A path: `1, 2, …, n − 2` |
| TS-509 | `U: S(0;1..9)` | `Tree : prufer` | `[0,0,0,0,0,0,0,0]` | A star: the center n − 2 times |
| TS-510 | `prufer: [0,0,0,0,0,0,0,0]` | `Tree : edges` | `[1-0,2-0,3-0,4-0,5-0,6-0,7-0,8-0,0-9]` | |
| TS-511 | `prufer: [4,4,0,2,6,6]` | `Tree : edges` | `[1-4,3-4,4-0,0-2,2-6,5-6,6-7]` | |
| TS-512 | `U: 0-1, 0-2, 1-3, 1-4, 2-5, 4-6` | `Tree : prufer` | `[1,2,0,1,4]` | |
| TS-513 | `prufer: [1,0,0,4,2]` | `Tree : prufer` | `[1,0,0,4,2]` | Round trip: decode then encode |
| TS-514 | `U: a-b, b-c, b-d` | `Tree : prufer` | `[b,b]` | Generic vertices: index order (`vertices` order) ranks the leaves |
| TS-515 | `U: [3,0,1,2] 0-1, 1-2, 2-3` | `Tree : prufer` | `[2,1]` | `Int` vertices listed out of order: index order, not value order, ranks the leaves (by value it would be `[1,2]`); this is NetworkX's code of the tree relabeled by index |
| TS-516 | `prufer: [6,2,6,0,3]` | `Tree : prufer` | `[6,2,6,0,3]` | igraph `igraph_from_prufer.c` |
| TS-517 | `prufer: [2,4,5,1,1,4]` | `Tree : edges` | `[0-2,2-4,3-5,5-1,6-1,1-4,4-7]` | |

## I. Graph rows

| ID | Source | Op | Expected | Notes |
|---|---|---|---|---|
| TS-600 | `U: 0-1, 0-2, 1-3, 1-4, 2-5, 4-6` | `RootedTree(root: 4) : incidentEdges(1)` | `[0,2,3]` | `RootedTree` is a `Graph`; its rows are the tree's, whatever the root |
| TS-601 | `U: 0-1, 0-2, 1-3, 1-4, 2-5, 4-6` | `RootedTree(root: 4) : degree(1)` | `#3` | |
| TS-602 | `D: 0>1, 0>2, 1>3, 1>4, 2>5, 4>6` | `Arborescence : outEdges(1)` | `[2,3]` | Child edges |
| TS-603 | `D: 0>1, 0>2, 1>3, 1>4, 2>5, 4>6` | `Arborescence : inEdges(1)` | `[0]` | The parent edge |
| TS-604 | `D: 0>1, 0>2, 1>3, 1>4, 2>5, 4>6` | `Arborescence : inEdges(0)` | `[]` | |
| TS-605 | `D: 0>1, 0>2, 1>3, 1>4, 2>5, 4>6` | `Arborescence : inDegree(0)` | `#0` | |
| TS-606 | `D: 0>1, 0>2, 1>3, 1>4, 2>5, 4>6` | `Arborescence : outDegree(1)` | `#2` | |
| TS-607 | `U: 0-1, 0-2, 1-3, 1-4, 2-5, 4-6` | `RootedTree(root: 4) > Arborescence : edges` | `[1>0,0>2,1>3,4>1,2>5,4>6]` | Every arc parent → child, at the tree's positions |
| TS-608 | `U: 0-1, 0-2, 1-3, 1-4, 2-5, 4-6` | `RootedTree(root: 4) > Arborescence : outEdges(1)` | `[0,2]` | |
| TS-609 | `U: 0-1, 0-2, 1-3, 1-4, 2-5, 4-6` | `Tree : vertexCount` | `#7` | |
| TS-610 | `U: 0-1, 0-2, 1-3, 1-4, 2-5, 4-6` | `Tree : edgeCount` | `#6` | |
| TS-611 | `U: [9] 0-1, 2-3` | `Forest : degree(9)` | `#0` | |

## J. Equality

| ID | Source | Op | Expected | Notes |
|---|---|---|---|---|
| TS-700 | `U: 0-1, 1-2` | `Tree == U: 2-1, 1-0 as Tree` | `T` | Vertex set and edge set, not order or orientation (README's rule for representations) |
| TS-701 | `U: 0-1, 1-2` | `Tree == U: 0-1, 0-2 as Tree` | `F` | |
| TS-702 | `U: 0-1, 1-2` | `RootedTree(root: 0) == U: 1-2, 0-1 as RootedTree(root: 0)` | `T` | |
| TS-703 | `U: 0-1, 1-2` | `RootedTree(root: 0) == U: 0-1, 1-2 as RootedTree(root: 2)` | `F` | The root is part of the value |
| TS-704 | `D: 0>1, 1>2` | `Arborescence == parents: [_,0,1] as Arborescence` | `T` | |
| TS-705 | `D: 0>1, 1>2` | `Arborescence == D: 2>1, 1>0 as Arborescence` | `F` | Arcs are ordered pairs |
| TS-706 | `U: [0,1]` | `Forest == U: [1,0] as Forest` | `T` | |
| TS-707 | `U: [0,1,2] 0-1` | `Forest == U: 0-1 as Forest` | `F` | The isolated vertex counts |

## K. Scale (no recursion)

| ID | Source | Op | Expected | Notes |
|---|---|---|---|---|
| TS-800 | `U: P(0..999999)` | `isTree` | `T` | 10⁶ vertices |
| TS-801 | `U: P(0..999999)` | `RootedTree(root: 0) : depth(999999)` | `#999999` | Depth 10⁶ − 1: any recursive DFS overflows the stack |
| TS-802 | `U: P(0..999999)` | `RootedTree(root: 0) : postorder[0]` | `#999999` | |
| TS-803 | `U: P(0..999999)` | `RootedTree(root: 500000) : height` | `#500000` | |
| TS-804 | `U: P(0..999999)` | `Tree : path(0,999999).length` | `#999999` | |
| TS-805 | `U: P(0..999999)` | `RootedTree(root: 0) : isAncestor(1,999999)` | `T` | O(1) by preorder intervals |
| TS-806 | `U: P(0..999999)` | `RootedTree(root: 999999) : descendants(500000).count` | `#500000` | |
| TS-807 | `U: S(0;1..999999)` | `RootedTree(root: 0) : children(0).count` | `#999999` | One row of 10⁶ − 1 |
| TS-808 | `U: S(0;1..999999)` | `RootedTree(root: 7) : preorder[2]` | `#1` | |
| TS-809 | `parents: [_,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29]` | `Arborescence : postorder[0]` | `#30` | |
| TS-810 | `U: [0..999999]` | `Forest : treeCount` | `#1000000` | 10⁶ one-vertex trees: `trees` must not build them eagerly |
| TS-811 | `U: P(0..999999)` | `Tree : prufer[999997]` | `#999998` | |
| TS-812 | `U: kary(1000000,2)` | `RootedTree(root: 0) : height` | `#19` | |
| TS-813 | `U: kary(1000000,2)` | `RootedTree(root: 0) : preorder[19]` | `#524287` | The leftmost leaf: 2^k − 1 down the first children |
