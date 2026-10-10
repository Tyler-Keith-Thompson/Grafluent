# Walks test catalog (WK-)

The signatures are the ones in `api.md`. The cases use only public API: `Walk`, `Trail`, `Path`, `Circuit`
and `Cycle` initializers and members, plus the shared fixtures in `GrafluentTestSupport`
(`ReferenceDirectedMultigraph`, `ReferencePseudograph`, whose edge positions are list indices and
whose out- and incident orders are position order). ✓ marks a case whose expected value
`ref.py` computes or checks (`uv run --quiet --no-project --with networkx==3.7 python3 ref.py`).

**Fixtures**

| Name | Graph | Positions |
|---|---|---|
| `D4` | `ReferenceDirectedMultigraph(edges: [0→1, 1→2, 2→3, 3→0])` (LEMON's n1…n4, a1…a4) | a1=0, a2=1, a3=2, a4=3 |
| `M` | `ReferenceDirectedMultigraph(edges: [0→1, 0→1, 1→0])` | 0, 1 parallel; 2 back |
| `DL` | `ReferenceDirectedMultigraph(edges: [0→0, 0→0])` | two loops |
| `U` | `ReferencePseudograph(edges: [0–1, 1–2, 2–0])` | triangle |
| `UL` | `ReferencePseudograph(edges: [0–0, 0–0])` | two loops |
| `UP` | `ReferencePseudograph(edges: [0–1, 0–1])` | parallel pair |
| `K5` | `ReferencePseudograph(edges:)` of `{a,b}` for `a<b` in 0..<5, lexicographic | 0–1=0, 0–2=1, 0–3=2, 0–4=3, 1–2=4, 1–3=5, 1–4=6, 2–3=7, 2–4=8, 3–4=9 |
| `C` | `ReferenceDirectedMultigraph(edges: [0→1, 1→2, 2→3, 3→1])` (JGraphT testConcatPath1) | 0..3 |
| `U3` | `ReferencePseudograph(edges: [0–1, 1–2, 2–3])`, weights `[2, 3, 4]` (JGraphT testReversePathUndirected) | 0..2 |
| `D3` | `ReferenceDirectedMultigraph(edges: [0→1, 1→2, 2→3])` | 0..2 |

## 1. Construction and validation (WK-1xx)

| ID | Input | Expected | Source |
|---|---|---|---|
| WK-101 ✓ | `Walk(vertices: [0,1,2,3], edges: [0,1,2], in: D4)` | non-nil; `length == 3`, `source == 0`, `target == 3` | LEMON addBack a1,a2,a3 |
| WK-102 ✓ | `Walk(vertices: [0,1,3,2], edges: [0,1,2], in: D4)` | nil | JGraphT testInvalidPath4 |
| WK-103 ✓ | `Walk(vertices: [0,1,2], edges: [0,2], in: D4)` | nil (skips 1→2) | JGraphT testInvalidPath5 |
| WK-104 ✓ | edges `[3,1,0]` (LEMON's a4,a2,a1) with any 4 vertices of D4 | nil | LEMON "inconsistent path", `checkPath == false` |
| WK-105 ✓ | `Walk(vertices: [3,0,1,2], edges: [3,0,1], in: D4)` | non-nil; `source == 3`, `target == 2` | LEMON addFront a4, addBack a1, a2 |
| WK-106 ✓ | `Walk(vertices: [2], edges: [], in: D4)`; `Walk(vertices: [9], edges: [], in: D4)` | non-nil trivial; nil (9 is not a vertex) | JGraphT verify() checks vertexSet |
| WK-107 ✓ | `Walk([], in: D4)`; `Walk(vertices: [], edges: [], in: D4)` | nil; nil | no empty walk |
| WK-108 ✓ | `Walk(vertices: [0,1], edges: [0,1], in: D4)` | nil (count mismatch with a graph: a "no", not a trap) | JGraphT IllegalArgument |
| WK-109 ✓ | `Walk([0,1,2,3,0,1], in: D4)` | edges `[0,1,2,3,0]` | |
| WK-110 ✓ | `Walk([0,2], in: D4)` | nil | |
| WK-111 ✓ | `Walk([0,0], in: ReferencePseudograph(edges: [0–1]))` | nil (no loop) | JGraphT testInvalidPath3 |
| WK-112 | `Walk(vertices: [0,0], edges: [0], in: ReferencePseudograph(edges: [0–0]))` | non-nil, the loop once; `Walk(vertices: [0,0], edges: [], in: …)` is nil (counts), and without `in:` it traps (WK-1301) | JGraphT testInvalidPath1 |
| WK-113 | `Walk(vertex: 7)` | `count == 1`, `length == 0`, `isTrivial`, `isClosed`, `source == target == 7`, `edges == []` | JGraphT singletonWalk |
| WK-114 | `Path(vertices: [0,1,2], edges: [5,6])` (no graph) | non-nil: intrinsic only, positions not checked | |
| WK-121…125 ✓ | NetworkX test_ispath graph `[(1,2),(2,3),(1,2),(3,4)]` as each of Graph, DiGraph, MultiGraph, MultiDiGraph (Grafluent: AdjacencyList / UndirectedAdjacencyList / the Reference multigraphs); `Walk(vs, in:) != nil` for `[1,2,3,4]`, `[1,2,4,3]`, `[1,2,3,4,5]`, `[3,2,1]`, `[1,2,1,2,3]` | agrees with `nx.is_path`: T, F, F, (undirected T, directed F), (undirected T, directed F) | NetworkX test_ispath |
| WK-126 ✓ | `Walk([99], in: ReferencePseudograph(edges: [1–2]))` | **nil**. NetworkX `is_path(G, [99])` is True | disagreement |
| WK-127 ✓ | `Walk([], in: …)` | **nil**. NetworkX `is_path(G, [])` is True | disagreement |
| WK-128 ✓ | `Walk([0,0,0], in: ReferenceDirectedMultigraph(edges: [0→0]))` | edges `[0,0]` | |
| WK-129 ✓ | `Trail([0,0,0], in: same)` | nil | |
| WK-130 | `Walk([1,2,3], in: g)` where `g` is a `MinimalSequence`-backed graph and the vertices are a one-pass sequence | consumed once; same result as an array | test support MinimalSequence |

## 2. Invariants per type (WK-2xx)

| ID | Input | Expected |
|---|---|---|
| WK-201 ✓ | `Trail(vertices: [0,1,2,3,2,3,4], edges: [0,1,2,3,4,5])` | non-nil (positions distinct, intrinsic only) |
| WK-202 ✓ | K5, vertices `[0,1,2,3,2,3,4]` (JGraphT testNonSimplePath) | `Walk(_, in: K5)` non-nil; `Trail(_, in: K5)` nil; `Path(_, in: K5)` nil |
| WK-203 ✓ | the same walk's `edges` | `[0,4,7,7,7,9]` (edge {2,3} three times) |
| WK-204 ✓ | `Trail(vertices: [0,1,2,0,3], edges: [0,1,2,3])`; `Path(` same `)` | non-nil; nil (0 repeats) |
| WK-205 ✓ | `Cycle(vertices: [0], edges: [5])`; `Circuit(` same `)` | both non-nil (self-loop 1-cycle) |
| WK-206 ✓ | `Cycle(vertices: [0,1], edges: [0,1])`; `Cycle(vertices: [0,1], edges: [0,0])` | non-nil; nil (digon needs two edges) |
| WK-207 ✓ | `Circuit(vertices: [], edges: [])`, `Cycle(vertices: [], edges: [])` | trap (shape: a circuit has ≥ 1 vertex) |
| WK-208 ✓ | `Circuit(vertices: [0,1,2,0,3,4], edges: [0,1,2,3,4,5])`; `Cycle(` same `)` | non-nil; nil (figure eight) |
| WK-209 ✓ | randomized: every `Path` that is a walk of a random multigraph | its edges are distinct (`Trail(path)` is total) |
| WK-210 ✓ | randomized: closed walks with distinct vertices | only undirected length-2 ones can repeat an edge, so `Cycle` must check edges as well |
| WK-211 | `Path(vertices: [0,1,0], edges: [0,1])` | nil |
| WK-212 | `Path(vertex: 3)` | non-nil, trivial; `Trail(vertex:)` likewise |
| WK-213 | `Cycle(Walk(vertex: 0))`, `Circuit(Walk(vertex: 0))` | nil (length 0, Bondy & Murty) while `Walk(vertex: 0).isClosed` is true (West) |
| WK-214 | `Cycle([0,1,2], in: U)` | edges `[0,1,2]` |
| WK-215 | `Cycle([0,1], in: ReferencePseudograph(edges: [0–1]))` | nil (a simple edge is not a 2-cycle; NetworkX WK-608 ✓) |

## 3. Collection behaviour (WK-3xx)

| ID | Input | Expected |
|---|---|---|
| WK-301 | `w = Walk([0,1,2,3,0,1], in: D4)!` | `Array(w) == [0,1,2,3,0,1]`, `count == 6`, `length == 5`, `startIndex == 0`, `endIndex == 6`, `w[4] == 0` |
| WK-302 | the same | `w.first == 0`, `w.last == 1`, `w.source == 0`, `w.target == 1` |
| WK-303 | `c = Cycle([2,3,0,1], in: D4)!` | `Array(c) == [2,3,0,1]`, `count == length == 4`, `c.edges == [2,3,0,1]` |
| WK-304 | `Walk(vertex: 5)` | `Array == [5]`, `indices == 0..<1`, `isEmpty == false` |
| WK-305 | `w.reversed()` vs `ReversedCollection(w)` | the same elements (the concrete member is chosen; the generic one still works in `some Collection` code) |
| WK-306 | `w.adjacentPairs()` (swift-algorithms) | `[(0,1),(1,2),(2,3),(3,0),(0,1)]`; on `c` it gives 3 pairs (no closing pair) |
| WK-307 | `w.vertices`, `w.edges` | `[0,1,2,3,0,1]`, `[0,1,2,3,0]` |
| WK-308 | `w.index(after: 5) == 6`, `w.distance(from: 0, to: 6) == 6` | RandomAccessCollection laws (a generic law check like the one used for `Components`) |
| WK-309 | `w.isClosed`; `Walk([0,1,2,3,0], in: D4)!.isClosed` | false; true |

## 4. Edges and orientation (WK-4xx)

| ID | Input | Expected |
|---|---|---|
| WK-401 | each `i` of WK-301's `w` | `D4.source(ofEdgeAt: w.edges[i]) == w[i]`, `target == w[i+1]` |
| WK-402 | each `i` of a `Cycle` `c` | edge `i` joins `c[i]` and `c[(i+1) % count]` |
| WK-403 | `Walk(vertices: [0,1], edges: [0], in: U)` and `Walk(vertices: [1,0], edges: [0], in: U)` | both non-nil (edge 0 crossed from either end) |
| WK-404 ✓ | `Walk(vertices: [0,2], edges: [0], in: U)` | nil |
| WK-405 | `Walk(vertices: [0,1], edges: [DirectedView.Edges.Index(position: 0, reversed: true)], in: U.directed)` | nil (that arc goes 1→0); `reversed: false` non-nil |

## 5. Multigraphs: parallel edges and self-loops (WK-5xx)

| ID | Input | Expected |
|---|---|---|
| WK-501 ✓ | `Walk([0,1], in: M)` | edges `[0]` (first in out-edge order) |
| WK-502 ✓ | `Walk(vertices: [0,1], edges: [1], in: M)` | non-nil and `!=` WK-501's walk (same vertices) |
| WK-503 ✓ | `Walk([0,1,0,1], in: M)` | edges `[0,2,0]` |
| WK-504 ✓ | `Trail([0,1,0,1], in: M)` | edges `[0,2,1]` (first unused copy) |
| WK-505 ✓ | `Trail([0,1,0,1,0,1], in: M)` | nil (only two copies of 0→1) |
| WK-506 ✓ | `Cycle(vertices: [0,1], edges: [0,2], in: M)` | non-nil |
| WK-507 ✓ | `Cycle(vertices: [0,1], edges: [0,2])` vs `Cycle(vertices: [0,1], edges: [1,2])` | `!=` |
| WK-508 ✓ | `Trail([0,0,0], in: DL)`, `Trail([0,0,0], in: UL)` | edges `[0,1]` both |
| WK-509 ✓ | `Circuit([0,0], in: DL)`; `Cycle([0,0], in: DL)` | non-nil, edges `[0,1]`; nil |
| WK-510 ✓ | randomized multigraphs, every vertex sequence | `Trail(vs, in: g) != nil` exactly when some choice of parallel edges gives a trail |
| WK-511 ✓ | `Trail(Walk([0,1,0,1], in: M)!)` vs `Trail([0,1,0,1], in: M)` | nil vs non-nil (document) |
| WK-512 ✓ | 2-cycles of `M` through 0 and 1 | two distinct `Cycle` values (`[0,2]`, `[1,2]`), whereas NetworkX `simple_cycles(MultiDiGraph)` lists one `[0,1]` |
| WK-513 ✓ | `ReferencePseudograph(edges: [1–1, 1–2, 1–2])`: `Cycle([1], in:)`, `Cycle([1,2], in:)` | edges `[0]`; `[1,2]` (NetworkX lists `[1]`, `[1,2]`) |
| WK-514 | `Cycle(vertices: [0], edges: [0], in: DL)` vs `Cycle(vertices: [0], edges: [1], in: DL)` | both valid; `!=` |
| WK-515 | `Walk([0,0], in: UL)` | edges `[0]` (a loop's two incident entries do not yield two different picks) |

## 6. Undirected graphs (WK-6xx)

| ID | Input | Expected |
|---|---|---|
| WK-601 ✓ | `Cycle([0,1,2], in: U)` and `Cycle([0,2,1], in: U)` | edges `[0,1,2]` and `[2,1,0]`; both valid |
| WK-602 ✓ | WK-601 pair | `!=` (no reflection); `a == b.reversed()` |
| WK-603 ✓ | `Walk(vertices: [0,1,0], edges: [0,0], in: U)` | non-nil Walk; `Trail(_)`, `Circuit(_)`, `Cycle(_)` all nil |
| WK-604 ✓ | `Cycle(vertices: [0,1], edges: [(0,false),(0,true)], in: U.directed)` | non-nil (a 2-cycle of `g.directed`) |
| WK-605 ✓ | `Cycle([0,1], in: UP)` | edges `[0,1]` (parallel pair, NetworkX WK-609) |
| WK-606 | `Cycle([0], in: UL)` | edges `[0]`; `Circuit([0,0], in: UL)` edges `[0,1]` |
| WK-607 ✓ | NetworkX `simple_cycles(cycle_graph(3))` has 1 cycle; `DiGraph` bidirected triangle has 5 | documents the reflection difference that callers handle themselves |

## 7. Equality and hashing (WK-7xx)

| ID | Input | Expected |
|---|---|---|
| WK-701 ✓ | `Cycle(vertices: [0,1,2], edges: [10,11,12])` vs each rotation `k = 0, 1, 2` | `==` and equal `hashValue` |
| WK-702 ✓ | vs `Cycle(vertices: [0,2,1], edges: [12,11,10])` | `!=` |
| WK-703 ✓ | `c.reversed().reversed()` | `== c` |
| WK-704 ✓ | `c.reversed()` | vertices `[0,2,1]`, edges `[12,11,10]` |
| WK-705 ✓ | vs `[0,1,2]` with edges `[10,11,13]` | `!=` |
| WK-706 ✓ | vs vertices `[1,0,2]` with edges `[10,11,12]` | `!=` |
| WK-707 ✓ | `Cycle(vertices: [5], edges: [9])` vs `[5]` with edges `[8]` | itself `==`; `!=` |
| WK-708 ✓ | figure-eight `Circuit(vertices: [0,1,2,0,3,4], edges: [0,1,2,3,4,5])` vs all 6 rotations | `==`, equal hashes |
| WK-709 ✓ | vs `[0,3,4,0,1,2]` with edges `[3,4,5,0,1,2]` | `==` (rotation from the second visit of 0) |
| WK-710 ✓ | vs `[0,3,4,0,1,2]` with edges `[0,1,2,3,4,5]` | `!=` |
| WK-711 ✓ | randomized circuits and perturbed rotations | linear equality equals brute-force rotation equality; equal values have equal hashes |
| WK-712 ✓ | `Walk(vertices: [0,1,2,0], edges: [10,11,12])` vs `Walk(vertices: [1,2,0,1], edges: [11,12,10])` | `!=` (open types are exact) |
| WK-713 | `Set` of 3 rotations of one cycle plus its reversal | `count == 2` |
| WK-714 | `Path` with the same vertices and different edges | `!=`, and the hashes usually differ (not required) |
| WK-715 | `Walk(vertex: 1) == Walk(vertex: 1)`; `!= Walk(vertex: 2)` | true; true (JGraphT testFirstEmptyWalkEquality analogue: no empty walk exists) |
| WK-716 | equal cycles with different rotations as `Dictionary` keys | one entry |

## 8. Conversions (WK-8xx)

| ID | Input | Expected |
|---|---|---|
| WK-801 ✓ | `Walk(Cycle(vertices: [0,1,2], edges: [10,11,12])!)` | vertices `[0,1,2,0]`, edges `[10,11,12]`, `isClosed` |
| WK-802 ✓ | `Cycle(Walk(vertices: [0,1,2,0], edges: [10,11,12]))` | vertices `[0,1,2]` |
| WK-803 ✓ | `Walk(Cycle(vertices: [4], edges: [7])!)` | vertices `[4,4]`, edges `[7]` |
| WK-804 ✓ | `Circuit(Walk(vertices: [0,1,2,0,3,0], edges: [0,1,2,3,4]))`; `Cycle(` same `)` | non-nil; nil |
| WK-805 | `Trail(path)`, `Walk(path)`, `Walk(trail)`, `Circuit(cycle)` | same vertices and edges (non-failable) |
| WK-806 | `Path(Walk(vertices: [0,1,0], …))`, `Trail(Walk(edges repeat))` | nil |
| WK-807 | `Cycle(Walk(vertices: [0,1,2], edges: [0,1]))` (open) | nil |
| WK-808 | `Cycle(circuit)` for a figure eight; for a triangle | nil; non-nil |
| WK-809 | round trip `Cycle(Walk(c))! == c` for random cycles | true |
| WK-810 | `Path(Trail(p)) == p` | true |

## 9. Weight (WK-9xx)

| ID | Input | Expected |
|---|---|---|
| WK-901 ✓ | NetworkX test_pathweight graph `[(1,2) cost 5, (2,3) cost 3, (1,2) cost 1]` as `ReferenceDirectedMultigraph` and `ReferencePseudograph`: `Walk(vertices: [1,2,3], edges: [2,1]).weight { cost[$0] }`; edges `[0,1]` | 4; 8 (NetworkX's `path_weight` gives 4, the lightest copy) |
| WK-902 ✓ | the same on simple graphs (the later edge replaces the earlier) | cost 4, dist 6 |
| WK-903 ✓ | `Walk(vertex: 1).weight { _ in 1 }` | 0 |
| WK-904 ✓ | cycle weights `[0.1, 0.2, 0.3]`, rotations 0 and 1 | `0.6000000000000001` and `0.6`: equal cycles, different sums (documented) |
| WK-905 ✓ | weights `[0.5, 0.25, 0.125]` | 0.875 for every rotation |
| WK-906 | a throwing weight closure (typed throws) | rethrows the closure's error type; earlier terms are not observable |
| WK-907 | JGraphT testReversePathDirected: D with 0→1:1, 1→2:2, 2→3:3, 3→2:4, 2→1:5, 1→0:6; `Walk([3,2,1,0], in:)` | edges `[3,4,5]`, weight 15 |

## 10. Reversal and concatenation (WK-10xx)

| ID | Input | Expected |
|---|---|---|
| WK-1001 ✓ | `Walk([0,1,2,3], in: U3)!.reversed()` | vertices `[3,2,1,0]`, edges `[2,1,0]`, valid in U3, weight 9 (JGraphT testReversePathUndirected) |
| WK-1002 ✓ | `Walk([0,1,2,3], in: D3)!.reversed()` | not a walk of D3 (`Walk(vertices:edges:in: D3)` nil), a walk of `D3.reversed` (JGraphT testReverseInvalidPathDirected throws instead) |
| WK-1003 ✓ | `Walk([0,1,2], in: C)!.appending(Walk(vertices: [2,3,1], edges: [2,3], in: C)!)` | vertices `[0,1,2,3,1]`, edges `[0,1,2,3]` (JGraphT testConcatPath1) |
| WK-1004 ✓ | `w.appending(Walk(vertex: w.target)) == w` and `Walk(vertex: w.source).appending(w) == w` | true (JGraphT testConcatPathWithSingleton) |
| WK-1005 ✓ | `Walk(vertex: 7).reversed()` | `== Walk(vertex: 7)` |
| WK-1006 ✓ | `Cycle(vertices: [0,1], edges: [0,1]).reversed()` | vertices `[0,1]`, edges `[1,0]`; `!=` the original |
| WK-1007 ✓ | a walk of `U.directed` with arcs `(0,false),(1,false)` over `[0,1,2]`, reversed | arcs `(1,false),(0,false)` over `[2,1,0]`: not a walk of `U.directed` (documented) |
| WK-1008 | `var w; w.append(x)` vs `w.appending(x)` | equal results; `append` does not copy a uniquely referenced buffer (benchmark, not a test) |
| WK-1009 | `Path.reversed()`, `Trail.reversed()`, `Circuit.reversed()` | keep their type (`Self`) |
| WK-1010 | `Cycle([0,1,2,3], in: D4)!.reversed()` | vertices `[0,3,2,1]`, edges `[3,2,1,0]` |

## 11. Codable, description, Sendable (WK-11xx)

| ID | Input | Expected |
|---|---|---|
| WK-1101 | `JSONEncoder` on `Walk(vertices: [0,1,2], edges: [5,6])` with sorted keys | `{"edges":[5,6],"vertices":[0,1,2]}` |
| WK-1102 | encode → decode round trip, every type, String vertices | `==` |
| WK-1103 | `Cycle` decode then `==` against a rotation | true (the stored rotation is kept; `Array(decoded)` is the encoded order) |
| WK-1104 | decode `Path` from `{"vertices":[0,1,0],"edges":[1,2]}`; `Walk` from `{"vertices":[0,1],"edges":[]}`; `Cycle` from `{"vertices":[],"edges":[]}` | `DecodingError.dataCorrupted` each, no trap |
| WK-1105 | `String(describing: Walk(vertices: [0,1,2], edges: [5,6]))` | `[0, 1, 2]` |
| WK-1106 | `String(reflecting: Path(vertices: ["a","b"], edges: [3]))` | `Path(vertices: ["a", "b"], edges: [3])` |
| WK-1107 | `String(describing: Cycle(vertices: [0,1,2], edges: [0,1,2]))` | `[0, 1, 2]` (no repeated start) |
| WK-1108 | a walk of 20 vertices | description elides after 16 with `…` (`GraphDescription.limit`) |
| WK-1109 | compile-time: `Walk<Int, Int>` passes into a `@Sendable` closure; `Walk<NonSendableVertex, Int>` does not (`VertexTypes.swift`) | builds / does not |
| WK-1110 | `LifetimeTracked` vertices | no leaks after conversions, append, reversal |

## 12. Migration of existing APIs (WK-12xx)

Each of these replaces an existing assertion. The vertex sequences stay the same, and only the type changes.

| ID | Call | Expected |
|---|---|---|
| WK-1201 ✓ | SP-63: `cycleGraph(5).findNegativeCycle(from: s) { weights[$0] }` (undirected, edge {1,2} negative) | `Cycle` with vertices `[1,2]`, edges `[(p,false),(p,true)]` where `p` is edge {1,2}'s position |
| WK-1202 ✓ | TR-105: `findCycle()` cases like `== [0,3,5]` | `?.vertices == [0,3,5]`, and `==` any rotation built with the same edges |
| WK-1203 ✓ | NetworkX TestFindCycle digraph `[(-1,0),(0,1),(1,0),(1,0),(2,1),(3,1)]` from `[0,1,2,3]` | NetworkX `[(0,1),(1,0)]`; Grafluent `findCycle(from: [0,1,2,3])?.vertices == [0,1]`, and its edges name the first 1→0 copy found by DFS |
| WK-1204 ✓ | NetworkX undirected find_cycle plus 2–0 | NetworkX `[(0,1),(1,2),(2,0)]` (for the planned `Graph.cycle()`) |
| WK-1205 ✓ | NetworkX `find_cycle(DAG, orientation='ignore')` | `[(0,1,fwd),(1,2,fwd),(0,2,rev)]`: equivalent to a cycle of `dag.undirected`, outside `Traversal`'s scope |
| WK-1206 ✓ | NetworkX `find_negative_cycle` on 0⇄1 at −1 | `[0,1,0]` (repeats the start; Grafluent does not) |
| WK-1207 | `ShortestPathTree.path(to: source)` | `Path(vertex: source)` (`length 0`) |
| WK-1208 | `path(to: unreached)` | nil |
| WK-1209 | `dijkstraShortestPath(from:to:weight:)` on a multigraph with parallel edges 0→1 at weights 5 and 1 | `path.edges == [1]`, `path.weight(w) == distance` |
| WK-1210 | property: for every reached `v`, `tree.path(to: v)!.weight(w) == tree.distance(to: v)` (integers) and `Path(vertices:edges:in: g) != nil` | holds |
| WK-1211 | `findNegativeCycle` on `M` with `w = [-1, -5, 1]` | edges `[1, 2]` (the lighter copy 0→1 closes it), vertices `[0,1]` |
| WK-1212 | `findNegativeCycle` witness laws (SP-69a): the result passes `Cycle(vertices:edges:in: g)` and `weight < 0` | holds |
| WK-1213 | `bidirectionalShortestPath(from: s, to: s)` | `Path(vertex: s)` |
| WK-1214 | `findCycle()` on a self-loop `0→0` | `Cycle` vertices `[0]`, edges `[that loop]` |
| WK-1215 | `findCycle()` on a graph where 1→2 has two copies and 2→1 exists | its edges are valid in the graph (`Cycle(vertices:edges:in:) != nil`) |

## 13. Preconditions and exit tests (WK-13xx)

Swift Testing `#expect(processExitsWith: .failure)`, as in `AdjacencyMatrixPreconditionTests`.

| ID | Call | Expected |
|---|---|---|
| WK-1301 | `Walk(vertices: [0,1], edges: [])` | trap: counts |
| WK-1302 | `Walk(vertices: [], edges: [])` | trap |
| WK-1303 | `Cycle(vertices: [0,1], edges: [0])` | trap: counts must be equal |
| WK-1304 | `Walk(vertex: 0).appending(Walk(vertex: 1))` | trap: `target != other.source` (JGraphT testIllegalConcatPath2) |
| WK-1305 | `Walk(vertices: [0,1], edges: [99], in: D4)` (position out of range) | trap through `source(ofEdgeAt:)` (documented precondition) |
| WK-1306 | `w[w.count]` | trap (array bounds) |

## Counts

| Section | Cases |
|---|---|
| 1 Construction and validation | 24 (WK-121…125 counted as 5) |
| 2 Invariants | 15 |
| 3 Collection | 9 |
| 4 Edges and orientation | 5 |
| 5 Multigraph and self-loops | 15 |
| 6 Undirected | 7 |
| 7 Equality and hashing | 16 |
| 8 Conversions | 10 |
| 9 Weight | 7 |
| 10 Reversal and concatenation | 10 |
| 11 Codable, description, Sendable | 10 |
| 12 Migration | 15 |
| 13 Preconditions | 6 |
| **Total** | **149** (80 rows marked ✓; `ref.py` runs 113 checks, all passing) |
