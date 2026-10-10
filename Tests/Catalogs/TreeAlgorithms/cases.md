# TreeAlgorithms: case catalog (TA-001 – TA-918)

Cases for the TreeAlgorithms module (api.md): the one-shot `lowestCommonAncestor(of:_:)` on
`RootedTree` and `Arborescence`, `LowestCommonAncestors`, `RootedTree.eulerTour`,
`HeavyLightDecomposition`, and `Tree`'s `center`, `centroid`, `centroidDecomposition`,
`diameter` and `diameterPath`, unweighted and weighted. Harvested from NetworkX
(`algorithms/tests/test_lowest_common_ancestors.py` `TestTreeLCA`, `tree/tests/test_distance_measures.py`
and the `tree.center` / `tree.centroid` docstrings), JGraphT's LCA finders' shapes (path, star,
binary tree), cp-algorithms (HLD, Euler tour) and the edge cases the design calls out. Every value
is recomputed by `ref.py`, which checks it against a naive implementation and NetworkX 3.7 (see
its docstring), and the large cases against closed forms.

## Notation

As the Trees catalog (`trees/cases.md`), with these additions.

**Source** (read by `ref.py`):

| Form | Meaning |
|---|---|
| `U: [vertices] edges` | an undirected graph: the listed vertices (duplicates dropped), then endpoints by first appearance; edges in **position order** |
| `D: [vertices] arcs` | a directed graph, the same way |
| `parents: [p0, p1, …]` | `RootedTree<Int>(parents:)` / `Arborescence<Int>(parents:)`; `_` is the root |
| `P(a,b,…)`, `S(c;a..b)`, `kary(n,k)`, `a..b` | path, star, igraph `kary_tree` (vertex i to k·i+1 … k·i+k below n), integer range |

**Op**: `Step > Step : query`. First step: `Tree` is `Tree(g)!`, `RootedTree(root: r)` is
`RootedTree(g, root: r)!` (or `RootedTree(parents:)!`), `Arborescence` is `Arborescence(g)!` (or
`Arborescence(parents:)!`). Later steps: `LowestCommonAncestors` is `LowestCommonAncestors(tree)`,
`HeavyLightDecomposition` is `HeavyLightDecomposition(tree)`. Queries are the API's, with vertex
arguments; `weight: [w0, w1, …]` is the weight closure `{ w[$0] }` by edge position (`weight: k`:
every edge weighs `k`); `allPairsAgree` asks that for every ordered pair (a, b),
`LowestCommonAncestors`, `HeavyLightDecomposition`, the one-shot query and NetworkX's
`tree_all_pairs_lowest_common_ancestor` give the same vertex. `x.length`, `x.count`, `x.height`
read that property of the result.

**Expected**: a vertex; `nil`; `trap` (a precondition); `T`; `#k` a number; `[a, b, …]` vertices
in order; `[vertices]/[edge positions]` a walk or path; `… #d` with the weighted distance;
`lo..<hi` a range of HLD positions; segments `[lo..<hi R, …]` in walk order from source to
target, `R` marking `isReversed` (the path visits those positions in decreasing order);
`[p0, p1, …]` the parent of each vertex in `vertices` order (`_` for the root) of a returned
`RootedTree`.

Fixtures used below:

* **F1** `U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8`; rooted at 0, children(0) = [1, 2],
  children(1) = [3, 4], children(4) = [6, 7], children(2) = [5], children(5) = [8].
* **F1b** the same edge set in another position order, `4-7, 0-2, 1-4, 5-8, 0-1, 4-6, 1-3, 2-5`,
  so children(0) = [2, 1] and children(4) = [7, 6].
* **NX** NetworkX's `TestTreeLCA` arborescence `0>1, 0>2, 1>3, 1>4, 2>5, 2>6`.

## A. One-shot lowest common ancestor (`RootedTree`, `Arborescence`)

| ID | Source | Op | Expected | Notes |
|---|---|---|---|---|
| TA-001 | `U: [0]` | `RootedTree(root: 0) : lowestCommonAncestor(0, 0)` | `0` | K₁ |
| TA-002 | `U: [] 0-1` | `RootedTree(root: 1) : lowestCommonAncestor(0, 1)` | `1` | The root of K₂ |
| TA-003 | `U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8` | `RootedTree(root: 0) : lowestCommonAncestor(3, 7)` | `1` | F1 |
| TA-004 | `U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8` | `RootedTree(root: 0) : lowestCommonAncestor(6, 7)` | `4` | Siblings |
| TA-005 | `U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8` | `RootedTree(root: 0) : lowestCommonAncestor(8, 6)` | `0` | Different subtrees of the root |
| TA-006 | `U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8` | `RootedTree(root: 0) : lowestCommonAncestor(4, 6)` | `4` | One is an ancestor of the other: it is the answer (NetworkX: a vertex is its own ancestor here) |
| TA-007 | `U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8` | `RootedTree(root: 0) : lowestCommonAncestor(6, 4)` | `4` | Symmetric |
| TA-008 | `U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8` | `RootedTree(root: 0) : lowestCommonAncestor(5, 5)` | `5` | Same vertex |
| TA-009 | `U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8` | `RootedTree(root: 4) : lowestCommonAncestor(3, 8)` | `1` | Rerooted F1: the answer depends on the root |
| TA-010 | `U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8` | `RootedTree(root: 4) : lowestCommonAncestor(0, 6)` | `4` | The new root |
| TA-011 | `U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8` | `RootedTree(root: 8) : lowestCommonAncestor(3, 7)` | `1` | Rooted at a leaf |
| TA-012 | `D: [] 0>1, 0>2, 1>3, 1>4, 2>5, 2>6` | `Arborescence : lowestCommonAncestor(3, 4)` | `1` | NX gold |
| TA-013 | `D: [] 0>1, 0>2, 1>3, 1>4, 2>5, 2>6` | `Arborescence : lowestCommonAncestor(3, 5)` | `0` | NX gold |
| TA-014 | `D: [] 0>1, 0>2, 1>3, 1>4, 2>5, 2>6` | `Arborescence : lowestCommonAncestor(5, 6)` | `2` | NX gold |
| TA-015 | `D: [] 0>1, 0>2, 1>3, 1>4, 2>5, 2>6` | `Arborescence : lowestCommonAncestor(2, 6)` | `2` | NX gold, ancestor |
| TA-016 | `parents: [_, 0, 0, 1, 1, 2, 2]` | `Arborescence : lowestCommonAncestor(4, 6)` | `0` | NX from a parent array |
| TA-017 | `parents: [3, 3, _, 2, 0]` | `RootedTree : lowestCommonAncestor(4, 1)` | `3` | Root not at index 0 |
| TA-018 | `U: [] a-b, b-c, b-d, d-e` | `RootedTree(root: c) : lowestCommonAncestor(a, e)` | `b` | String vertices |
| TA-019 | `U: [] a-b, b-c, b-d, d-e` | `RootedTree(root: c) : lowestCommonAncestor(e, z)` | `trap` | Not a vertex: precondition, as every Trees query |
| TA-020 | `D: [] 0>1, 0>2, 1>3, 1>4, 2>5, 2>6` | `Arborescence : lowestCommonAncestor(0, 9)` | `trap` | Not a vertex. NetworkX raises `NodeNotFound` |

## B. `LowestCommonAncestors`

| ID | Source | Op | Expected | Notes |
|---|---|---|---|---|
| TA-101 | `U: [0]` | `RootedTree(root: 0) > LowestCommonAncestors : lowestCommonAncestor(0, 0)` | `0` | K₁: no range to search |
| TA-102 | `U: [0]` | `RootedTree(root: 0) > LowestCommonAncestors : distance(0, 0)` | `#0` | |
| TA-103 | `U: [] 0-1` | `RootedTree(root: 0) > LowestCommonAncestors : lowestCommonAncestor(1, 0)` | `0` | |
| TA-104 | `U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8` | `RootedTree(root: 0) > LowestCommonAncestors : lowestCommonAncestor(3, 7)` | `1` | = TA-003 |
| TA-105 | `U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8` | `RootedTree(root: 0) > LowestCommonAncestors : lowestCommonAncestor(7, 3)` | `1` | Arguments in either preorder order |
| TA-106 | `U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8` | `RootedTree(root: 0) > LowestCommonAncestors : lowestCommonAncestor(1, 7)` | `1` | Ancestor: the range's least entry is the ancestor itself |
| TA-107 | `U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8` | `RootedTree(root: 0) > LowestCommonAncestors : lowestCommonAncestor(0, 8)` | `0` | The root |
| TA-108 | `U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8` | `RootedTree(root: 0) > LowestCommonAncestors : distance(3, 8)` | `#5` | depth(3) + depth(8) − 2·depth(0) |
| TA-109 | `U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8` | `RootedTree(root: 0) > LowestCommonAncestors : distance(6, 7)` | `#2` | |
| TA-110 | `U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8` | `RootedTree(root: 4) > LowestCommonAncestors : distance(3, 8)` | `#5` | Distance does not depend on the root (= TA-108) |
| TA-111 | `U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8` | `RootedTree(root: 0) > LowestCommonAncestors : allPairsAgree` | `T` | |
| TA-112 | `U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8` | `RootedTree(root: 4) > LowestCommonAncestors : allPairsAgree` | `T` | |
| TA-113 | `U: [0..8] 4-7, 0-2, 1-4, 5-8, 0-1, 4-6, 1-3, 2-5` | `RootedTree(root: 0) > LowestCommonAncestors : allPairsAgree` | `T` | F1b: another preorder, the same answers |
| TA-114 | `D: [] 0>1, 0>2, 1>3, 1>4, 2>5, 2>6` | `Arborescence > LowestCommonAncestors : allPairsAgree` | `T` | NX gold, all 49 ordered pairs |
| TA-115 | `D: [] 0>1, 0>2, 1>3, 1>4, 2>5, 2>6` | `Arborescence > LowestCommonAncestors : lowestCommonAncestor(4, 5)` | `0` | From an `Arborescence` |
| TA-116 | `U: [] kary(63,2)` | `RootedTree(root: 0) > LowestCommonAncestors : allPairsAgree` | `T` | Complete binary tree, crosses the 64-entry RMQ block boundary |
| TA-117 | `U: [] P(0..140)` | `RootedTree(root: 70) > LowestCommonAncestors : allPairsAgree` | `T` | Path rooted in the middle: three RMQ blocks |
| TA-118 | `U: [] S(0;1..150)` | `RootedTree(root: 7) > LowestCommonAncestors : allPairsAgree` | `T` | Star rooted at a leaf |
| TA-119 | `U: [] P(0..140)` | `RootedTree(root: 70) > LowestCommonAncestors : lowestCommonAncestor(0, 140)` | `70` | Ends across blocks |
| TA-120 | `U: [] P(0..140)` | `RootedTree(root: 70) > LowestCommonAncestors : distance(0, 140)` | `#140` | |
| TA-121 | `U: [] a-b, b-c, b-d, d-e` | `RootedTree(root: e) > LowestCommonAncestors : allPairsAgree` | `T` | String vertices |
| TA-122 | `U: [] a-b, b-c, b-d, d-e` | `RootedTree(root: e) > LowestCommonAncestors : lowestCommonAncestor(a, c)` | `b` | |
| TA-123 | `U: [] a-b, b-c, b-d, d-e` | `RootedTree(root: e) > LowestCommonAncestors : distance(a, z)` | `trap` | Not a vertex |
| TA-124 | `U: [] 3-1, 1-2, 1-0` | `RootedTree(root: 3) > LowestCommonAncestors : lowestCommonAncestor(2, 0)` | `1` | `Int` vertices not listed in value order (`vertices` = [3, 1, 2, 0]) |

## C. Euler tour (`RootedTree.eulerTour`)

The closed walk from the root that crosses every edge twice, children in `children(of:)` order:
2n − 1 vertices, 2n − 2 edges.

| ID | Source | Op | Expected | Notes |
|---|---|---|---|---|
| TA-201 | `U: [0]` | `RootedTree(root: 0) : eulerTour` | `[0]/[]` | The trivial walk |
| TA-202 | `U: [] 0-1` | `RootedTree(root: 0) : eulerTour` | `[0, 1, 0]/[0, 0]` | |
| TA-203 | `U: [] 0-1` | `RootedTree(root: 1) : eulerTour` | `[1, 0, 1]/[0, 0]` | |
| TA-204 | `U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8` | `RootedTree(root: 0) : eulerTour` | `[0, 1, 3, 1, 4, 6, 4, 7, 4, 1, 0, 2, 5, 8, 5, 2, 0]/[0, 2, 2, 3, 5, 5, 6, 6, 3, 0, 1, 4, 7, 7, 4, 1]` | F1 |
| TA-205 | `U: [0..8] 4-7, 0-2, 1-4, 5-8, 0-1, 4-6, 1-3, 2-5` | `RootedTree(root: 0) : eulerTour` | `[0, 2, 5, 8, 5, 2, 0, 1, 4, 7, 4, 6, 4, 1, 3, 1, 0]/[1, 7, 3, 3, 7, 1, 4, 2, 0, 0, 5, 5, 2, 6, 6, 4]` | F1b: children by edge position |
| TA-206 | `U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8` | `RootedTree(root: 4) : eulerTour` | `[4, 1, 0, 2, 5, 8, 5, 2, 0, 1, 3, 1, 4, 6, 4, 7, 4]/[3, 0, 1, 4, 7, 7, 4, 1, 0, 2, 2, 3, 5, 5, 6, 6]` | Rerooted: the old parent is wherever its edge sits in the row |
| TA-207 | `U: [] P(0..3)` | `RootedTree(root: 2) : eulerTour` | `[2, 1, 0, 1, 2, 3, 2]/[1, 0, 0, 1, 2, 2]` | |
| TA-208 | `U: [] S(0;1..3)` | `RootedTree(root: 0) : eulerTour` | `[0, 1, 0, 2, 0, 3, 0]/[0, 0, 1, 1, 2, 2]` | Star from its center |
| TA-209 | `U: [] S(0;1..3)` | `RootedTree(root: 2) : eulerTour` | `[2, 0, 1, 0, 3, 0, 2]/[1, 0, 0, 2, 2, 1]` | Star from a leaf |
| TA-210 | `D: [] 0>1, 0>2, 1>3, 1>4, 2>5, 2>6` | `Arborescence > RootedTree : eulerTour` | `[0, 1, 3, 1, 4, 1, 0, 2, 5, 2, 6, 2, 0]/[0, 2, 2, 3, 3, 0, 1, 4, 4, 5, 5, 1]` | Through `RootedTree(arborescence)`, O(1); the walk goes back up arcs, so it is not on `Arborescence` |
| TA-211 | `U: [] a-b, b-c, b-d, d-e` | `RootedTree(root: d) : eulerTour` | `[d, b, a, b, c, b, d, e, d]/[2, 0, 0, 1, 1, 2, 3, 3]` | |
| TA-212 | `U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8` | `RootedTree(root: 0) : eulerTour.length` | `#16` | 2(n − 1) |

## D. `HeavyLightDecomposition`

Heavy child: the child with the largest subtree, the first in `children(of:)` order on a tie.
Positions: a preorder that visits each heavy child first, then the other children in
`children(of:)` order, so every heavy path and every subtree is an interval.

| ID | Source | Op | Expected | Notes |
|---|---|---|---|---|
| TA-301 | `U: [0]` | `RootedTree(root: 0) > HeavyLightDecomposition : preorder` | `[0]` | |
| TA-302 | `U: [0]` | `RootedTree(root: 0) > HeavyLightDecomposition : segments(0, 0)` | `[0..<1]` | One one-position segment, not reversed |
| TA-303 | `U: [0]` | `RootedTree(root: 0) > HeavyLightDecomposition : segments(0, 0, includingCommonAncestor: false)` | `[]` | Empty |
| TA-304 | `U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8` | `RootedTree(root: 0) > HeavyLightDecomposition : preorder` | `[0, 1, 4, 6, 7, 3, 2, 5, 8]` | F1: heavy children 0→1, 1→4, 4→6 (tie with 7: first), 2→5, 5→8 |
| TA-305 | `U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8` | `RootedTree(root: 0) > HeavyLightDecomposition : heavyChild(4)` | `6` | Tie: first in `children(of:)` |
| TA-306 | `U: [0..8] 4-7, 0-2, 1-4, 5-8, 0-1, 4-6, 1-3, 2-5` | `RootedTree(root: 0) > HeavyLightDecomposition : heavyChild(4)` | `7` | F1b: the tie goes the other way, by edge position |
| TA-307 | `U: [0..8] 4-7, 0-2, 1-4, 5-8, 0-1, 4-6, 1-3, 2-5` | `RootedTree(root: 0) > HeavyLightDecomposition : preorder` | `[0, 1, 4, 7, 6, 3, 2, 5, 8]` | F1b |
| TA-308 | `U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8` | `RootedTree(root: 0) > HeavyLightDecomposition : heavyChild(8)` | `nil` | A leaf has none |
| TA-309 | `U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8` | `RootedTree(root: 0) > HeavyLightDecomposition : heavyChild(0)` | `1` | |
| TA-310 | `U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8` | `RootedTree(root: 0) > HeavyLightDecomposition : head(6)` | `0` | On the root's heavy path |
| TA-311 | `U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8` | `RootedTree(root: 0) > HeavyLightDecomposition : head(7)` | `7` | A light child heads its own path |
| TA-312 | `U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8` | `RootedTree(root: 0) > HeavyLightDecomposition : head(8)` | `2` | |
| TA-313 | `U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8` | `RootedTree(root: 0) > HeavyLightDecomposition : position(7)` | `#4` | |
| TA-314 | `U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8` | `RootedTree(root: 0) > HeavyLightDecomposition : subtree(1)` | `1..<6` | Subtrees are intervals of positions |
| TA-315 | `U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8` | `RootedTree(root: 0) > HeavyLightDecomposition : subtree(2)` | `6..<9` | |
| TA-316 | `U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8` | `RootedTree(root: 0) > HeavyLightDecomposition : subtree(0)` | `0..<9` | Everything |
| TA-317 | `U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8` | `RootedTree(root: 0) > HeavyLightDecomposition : segments(7, 8)` | `[4..<5, 0..<3 R, 6..<9]` | Up a light leaf, up the root's path, down another |
| TA-318 | `U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8` | `RootedTree(root: 0) > HeavyLightDecomposition : segments(8, 7)` | `[6..<9 R, 0..<3, 4..<5]` | The reverse walk: the same ranges, reversed order and flags |
| TA-319 | `U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8` | `RootedTree(root: 0) > HeavyLightDecomposition : segments(6, 3)` | `[1..<4 R, 5..<6]` | |
| TA-320 | `U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8` | `RootedTree(root: 0) > HeavyLightDecomposition : segments(0, 6)` | `[0..<4]` | Straight down one heavy path |
| TA-321 | `U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8` | `RootedTree(root: 0) > HeavyLightDecomposition : segments(0, 6, includingCommonAncestor: false)` | `[1..<4]` | For values on edges, stored at the child: the ancestor drops |
| TA-322 | `U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8` | `RootedTree(root: 0) > HeavyLightDecomposition : segments(6, 0, includingCommonAncestor: false)` | `[1..<4 R]` | Upward, the ancestor is the low end |
| TA-323 | `U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8` | `RootedTree(root: 0) > HeavyLightDecomposition : segments(7, 8, includingCommonAncestor: false)` | `[4..<5, 1..<3 R, 6..<9]` | The middle segment loses the ancestor's position |
| TA-324 | `U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8` | `RootedTree(root: 0) > HeavyLightDecomposition : segments(3, 3)` | `[5..<6]` | |
| TA-325 | `U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8` | `RootedTree(root: 0) > HeavyLightDecomposition : segments(3, 4, includingCommonAncestor: false)` | `[5..<6, 2..<3]` | The ancestor 1 alone in the middle segment: it disappears |
| TA-326 | `U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8` | `RootedTree(root: 0) > HeavyLightDecomposition : lowestCommonAncestor(7, 8)` | `0` | |
| TA-327 | `U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8` | `RootedTree(root: 0) > HeavyLightDecomposition : lowestCommonAncestor(6, 7)` | `4` | |
| TA-328 | `U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8` | `RootedTree(root: 4) > HeavyLightDecomposition : preorder` | `[4, 1, 0, 2, 5, 8, 3, 6, 7]` | Rerooted |
| TA-329 | `U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8` | `RootedTree(root: 4) > HeavyLightDecomposition : segments(3, 8)` | `[6..<7, 1..<6]` | |
| TA-330 | `U: [] S(0;1..3)` | `RootedTree(root: 0) > HeavyLightDecomposition : heavyChild(0)` | `1` | All children tie: the first |
| TA-331 | `U: [] S(0;1..3)` | `RootedTree(root: 0) > HeavyLightDecomposition : segments(2, 3)` | `[2..<3, 0..<1, 3..<4]` | |
| TA-332 | `D: [] 0>1, 0>2, 1>3, 1>4, 2>5, 2>6` | `Arborescence > HeavyLightDecomposition : segments(4, 6)` | `[3..<4, 0..<2 R, 4..<5, 6..<7]` | From an `Arborescence` |
| TA-333 | `U: [] kary(63,2)` | `RootedTree(root: 0) > HeavyLightDecomposition : segments(62, 31)` | `[62..<63, 60..<61, 56..<57, 48..<49, 32..<33, 0..<6]` | Leaves of a complete binary tree: light edges at every level |
| TA-334 | `U: [] kary(63,2)` | `RootedTree(root: 0) > HeavyLightDecomposition : segments(62, 31).count` | `#6` | |
| TA-335 | `U: [] a-b, b-c, b-d, d-e` | `RootedTree(root: c) > HeavyLightDecomposition : segments(a, e)` | `[4..<5, 1..<4]` | String vertices |
| TA-336 | `U: [] a-b, b-c, b-d, d-e` | `RootedTree(root: c) > HeavyLightDecomposition : position(z)` | `trap` | Not a vertex |

## E. Center (`Tree.center()`, `Tree.center(weight:)`)

The vertices of least eccentricity, in `vertices` order: one, or two adjacent, unweighted or
with positive weights; with zero weights any number.

| ID | Source | Op | Expected | Notes |
|---|---|---|---|---|
| TA-401 | `U: [0]` | `Tree : center` | `[0]` | NetworkX `path_graph(1)` |
| TA-402 | `U: [] 0-1` | `Tree : center` | `[0, 1]` | Both ends |
| TA-403 | `U: [] 1-2, 1-3, 2-4, 2-5` | `Tree : center` | `[1, 2]` | NetworkX `test_center_simple_tree` / docstring |
| TA-404 | `U: [] P(0..4)` | `Tree : center` | `[2]` | NetworkX docstring |
| TA-405 | `U: [] P(0..98)` | `Tree : center` | `[49]` | NetworkX `test_center_path_graph(99)` |
| TA-406 | `U: [] P(0..99)` | `Tree : center` | `[49, 50]` | `path_graph(100)`: two |
| TA-407 | `U: [] S(0;1..5)` | `Tree : center` | `[0]` | `star_graph(5)` |
| TA-408 | `U: [] kary(40,3)` | `Tree : center` | `[0]` | `balanced_tree(3, 3)` |
| TA-409 | `U: [] S(0;1..6), P(6,7,8,9,10)` | `Tree : center` | `[7]` | NetworkX's star with a long branch: center ≠ centroid (TA-506) |
| TA-410 | `U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8` | `Tree : center` | `[0]` | F1 |
| TA-411 | `U: [] a-b, b-c, b-d, d-e` | `Tree : center` | `[b, d]` | Two centers |
| TA-412 | `U: [4, 2, 7, 1] 7-2, 2-4, 4-1` | `Tree : center` | `[4, 2]` | Tie order is `vertices` order, not value order (sorted values would give [2, 4]) |
| TA-413 | `U: [] P(0..4)` | `Tree : center(weight: [1, 1, 1, 10])` | `[3]` | A heavy end edge moves the center |
| TA-414 | `U: [] 0-1` | `Tree : center(weight: [5])` | `[0, 1]` | |
| TA-415 | `U: [] P(0..2)` | `Tree : center(weight: [0, 0])` | `[0, 1, 2]` | All zero: every vertex has eccentricity 0 |
| TA-416 | `U: [] P(0..3)` | `Tree : center(weight: [0, 1, 0])` | `[0, 1, 2, 3]` | Zero end edges: four centers (NetworkX `center(weight=)` agrees) |
| TA-417 | `U: [] P(0..3)` | `Tree : center(weight: [1, 0, 1])` | `[1, 2]` | |
| TA-418 | `U: [] S(0;1..4)` | `Tree : center(weight: [3, 1, 3, 2])` | `[0]` | |
| TA-419 | `U: [] S(0;1..4)` | `Tree : center(weight: [3, 1, 30, 2])` | `[0]` | One long spoke: the hub stays the center (eccentricity 30; the long spoke's leaf has 33) |
| TA-420 | `U: [] P(0..3)` | `Tree : center(weight: [0.5, 0.25, 0.75])` | `[2]` | Floating-point weights |
| TA-421 | `U: [] P(0..3)` | `Tree : center(weight: [1, -1, 1])` | `trap` | A negative weight: precondition (as Dijkstra). NetworkX raises `ValueError` ("negative weights?") |
| TA-422 | `U: [] P(0..3)` | `Tree : center(weight: [1, nan, 1])` | `trap` | NaN: precondition |
| TA-423 | `U: [0]` | `Tree : center(weight: [])` | `[0]` | K₁ weighted: the closure is never called |

## F. Centroid and centroid decomposition

The centroid: the vertices whose removal leaves no component of more than n/2 vertices, in
`vertices` order (one, or two adjacent). Edge weights play no part.

| ID | Source | Op | Expected | Notes |
|---|---|---|---|---|
| TA-501 | `U: [0]` | `Tree : centroid` | `[0]` | |
| TA-502 | `U: [] 0-1` | `Tree : centroid` | `[0, 1]` | |
| TA-503 | `U: [] P(0..98)` | `Tree : centroid` | `[49]` | NetworkX `test_tree_centroid_path_graphs(99)` |
| TA-504 | `U: [] P(0..99)` | `Tree : centroid` | `[49, 50]` | `path_graph(100)` |
| TA-505 | `U: [] kary(8,2)` | `Tree : centroid` | `[0, 1]` | NetworkX `full_rary_tree(2, 8)`: two |
| TA-506 | `U: [] S(0;1..6), P(6,7,8,9,10)` | `Tree : centroid` | `[0]` | NetworkX: centroid [0], center [7] |
| TA-507 | `U: [] kary(40,3)` | `Tree : centroid` | `[0]` | `balanced_tree(3, 3)` |
| TA-508 | `U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8` | `Tree : centroid` | `[1]` | F1: centroid 1, center 0 (TA-410) |
| TA-509 | `U: [] a-b, b-c, b-d, d-e` | `Tree : centroid` | `[b]` | One centroid, two centers (TA-411) |
| TA-510 | `U: [4, 2, 7, 1] 7-2, 2-4, 4-1` | `Tree : centroid` | `[4, 2]` | `vertices` order |
| TA-511 | `U: [0]` | `Tree : centroidDecomposition` | `[_]` | |
| TA-512 | `U: [] 0-1` | `Tree : centroidDecomposition` | `[_, 0]` | Two centroids: the first in `vertices` order is the root |
| TA-513 | `U: [] P(0..6)` | `Tree : centroidDecomposition` | `[1, 3, 1, _, 5, 3, 5]` | Path of 7: a perfect binary hierarchy |
| TA-514 | `U: [] P(0..7)` | `Tree : centroidDecomposition` | `[1, 3, 1, _, 5, 3, 5, 6]` | Path of 8: ties at every level, broken by `vertices` order |
| TA-515 | `U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8` | `Tree : centroidDecomposition` | `[2, _, 1, 1, 1, 2, 4, 4, 5]` | F1 |
| TA-516 | `U: [] S(0;1..5)` | `Tree : centroidDecomposition` | `[_, 0, 0, 0, 0, 0]` | Height 1 |
| TA-517 | `U: [] a-b, b-c, b-d, d-e` | `Tree : centroidDecomposition` | `[b, _, b, b, d]` | |
| TA-518 | `U: [] kary(63,2)` | `Tree : centroidDecomposition.height` | `#5` | ≤ ⌊log₂ n⌋ |
| TA-519 | `U: [] P(0..127)` | `Tree : centroidDecomposition.height` | `#7` | 128 vertices: ⌊log₂ 128⌋ = 7 |

## G. Diameter (`diameter()`, `diameterPath()`, weighted)

`diameterPath` is the path between the lexicographically least pair (u, v), by `vertices` order,
at distance `diameter`: u the first vertex of greatest eccentricity, v the first vertex farthest
from u. One vertex, or all-zero weights: the trivial path at `vertices[0]`.

| ID | Source | Op | Expected | Notes |
|---|---|---|---|---|
| TA-601 | `U: [0]` | `Tree : diameter` | `#0` | NetworkX `diameter` of K₁ is 0 |
| TA-602 | `U: [0]` | `Tree : diameterPath` | `[0]/[]` | Trivial |
| TA-603 | `U: [] 0-1` | `Tree : diameterPath` | `[0, 1]/[0]` | |
| TA-604 | `U: [] 1-0` | `Tree : diameterPath` | `[1, 0]/[0]` | `vertices` = [1, 0]: the path starts at 1 |
| TA-605 | `U: [] P(0..9)` | `Tree : diameter` | `#9` | |
| TA-606 | `U: [] P(0..9)` | `Tree : diameterPath` | `[0, 1, 2, 3, 4, 5, 6, 7, 8, 9]/[0, 1, 2, 3, 4, 5, 6, 7, 8]` | From the first end |
| TA-607 | `U: [] S(0;1..5)` | `Tree : diameterPath` | `[1, 0, 2]/[0, 1]` | Many diametral pairs: leaves 1 and 2 |
| TA-608 | `U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8` | `Tree : diameter` | `#6` | F1 |
| TA-609 | `U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8` | `Tree : diameterPath` | `[6, 4, 1, 0, 2, 5, 8]/[5, 3, 0, 1, 4, 7]` | 6 is the first peripheral vertex, 8 the first farthest from it |
| TA-610 | `U: [0..8] 4-7, 0-2, 1-4, 5-8, 0-1, 4-6, 1-3, 2-5` | `Tree : diameterPath` | `[6, 4, 1, 0, 2, 5, 8]/[5, 2, 4, 1, 7, 3]` | F1b: the same vertices, edge positions differ |
| TA-611 | `U: [] a-b, b-c, b-d, d-e` | `Tree : diameterPath` | `[a, b, d, e]/[0, 2, 3]` | |
| TA-612 | `U: [] S(0;1..6), P(6,7,8,9,10)` | `Tree : diameterPath` | `[1, 0, 6, 7, 8, 9, 10]/[0, 5, 6, 7, 8, 9]` | |
| TA-613 | `U: [] kary(40,3)` | `Tree : diameter` | `#6` | `balanced_tree(3, 3)` |
| TA-614 | `U: [] P(0..4)` | `Tree : diameter(weight: [1, 1, 1, 10])` | `#13` | |
| TA-615 | `U: [] P(0..4)` | `Tree : diameterPath(weight: [1, 1, 1, 10])` | `[0, 1, 2, 3, 4]/[0, 1, 2, 3] #13` | |
| TA-616 | `U: [] S(0;1..4)` | `Tree : diameterPath(weight: [3, 1, 3, 2])` | `[1, 0, 3]/[0, 2] #6` | Weights pick the spokes |
| TA-617 | `U: [] P(0..2)` | `Tree : diameterPath(weight: [0, 0])` | `[0]/[] #0` | All zero: trivial path at `vertices[0]` |
| TA-618 | `U: [] P(0..3)` | `Tree : diameterPath(weight: [0, 1, 0])` | `[0, 1, 2]/[0, 1] #1` | Not the path with most edges: the least pair at distance 1 is (0, 2) |
| TA-619 | `U: [] P(0..3)` | `Tree : diameter(weight: [0.5, 0.25, 0.75])` | `#1.5` | Floating point |
| TA-620 | `U: [] 0-1` | `Tree : diameter(weight: [-1])` | `trap` | Negative: precondition |
| TA-621 | `U: [] 0-1` | `Tree : diameterPath(weight: [nan])` | `trap` | NaN: precondition |
| TA-622 | `U: [0]` | `Tree : diameterPath(weight: [])` | `[0]/[] #0` | `#0` with the trivial path |
| TA-623 | `U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8` | `Tree : diameterPath(weight: [1, 1, 1, 1, 1, 1, 1, 1])` | `[6, 4, 1, 0, 2, 5, 8]/[5, 3, 0, 1, 4, 7] #6` | Unit weights equal the unweighted answer (TA-609) |
| TA-624 | `U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8` | `Tree : diameterPath(weight: [5, 1, 1, 1, 1, 1, 1, 1])` | `[6, 4, 1, 0, 2, 5, 8]/[5, 3, 0, 1, 4, 7] #10` | |

## H. Large inputs (closed forms in `ref.py`)

| ID | Source | Op | Expected | Notes |
|---|---|---|---|---|
| TA-901 | `U: [] P(0..999999)` | `Tree : diameter` | `#999999` | 10⁶-vertex path: no recursion anywhere |
| TA-902 | `U: [] P(0..999999)` | `Tree : center` | `[499999, 500000]` | |
| TA-903 | `U: [] P(0..999999)` | `Tree : centroid` | `[499999, 500000]` | |
| TA-904 | `U: [] P(0..999999)` | `RootedTree(root: 0) > LowestCommonAncestors : lowestCommonAncestor(999999, 500000)` | `500000` | Depth 10⁶ − 1 |
| TA-905 | `U: [] P(0..999999)` | `RootedTree(root: 0) > LowestCommonAncestors : distance(3, 999999)` | `#999996` | |
| TA-906 | `U: [] P(0..999999)` | `RootedTree(root: 0) : eulerTour.length` | `#1999998` | |
| TA-907 | `U: [] P(0..999999)` | `RootedTree(root: 0) > HeavyLightDecomposition : segments(999999, 0)` | `[0..<1000000 R]` | One heavy path |
| TA-908 | `U: [] P(0..999999)` | `RootedTree(root: 500000) > LowestCommonAncestors : lowestCommonAncestor(0, 999999)` | `500000` | |
| TA-909 | `U: [] P(0..999999)` | `RootedTree(root: 500000) > HeavyLightDecomposition : segments(0, 999999)` | `[0..<500001 R, 500001..<1000000]` | Heavy side 0…499999 (500 000 vertices) |
| TA-910 | `U: [] S(0;1..999999)` | `Tree : diameter` | `#2` | 10⁶-vertex star |
| TA-911 | `U: [] S(0;1..999999)` | `Tree : center` | `[0]` | |
| TA-912 | `U: [] S(0;1..999999)` | `Tree : centroid` | `[0]` | |
| TA-913 | `U: [] S(0;1..999999)` | `Tree : diameterPath` | `[1, 0, 2]/[0, 1]` | |
| TA-914 | `U: [] S(0;1..999999)` | `Tree : centroidDecomposition.height` | `#1` | 999 999 one-vertex components |
| TA-915 | `U: [] P(0..131070)` | `Tree : centroidDecomposition.height` | `#16` | 2¹⁷ − 1 vertices |
| TA-916 | `U: [] P(0..999999)` | `Tree : diameter(weight: 2)` | `#1999998` | |
| TA-917 | `U: [] kary(1000000,2)` | `RootedTree(root: 0) > LowestCommonAncestors : lowestCommonAncestor(999999, 524287)` | `0` | 10⁶-vertex binary heap shape |
| TA-918 | `U: [] kary(1000000,2)` | `Tree : diameter` | `#38` | |
