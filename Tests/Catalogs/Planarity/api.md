# Planarity: proposed API (phase 1, with phase 2 pinned)

Planarity testing on `Graph` with a witness either way: a combinatorial embedding (a rotation
system: the clockwise order of the edges around each vertex) when the graph is planar, and a
Kuratowski subgraph (a subdivision of K₅ or K₃,₃) when it is not. The embedding gives its faces;
outerplanarity is one more test. Phase 2 adds the dual graph. Coordinates (straight-line
drawings) belong to `GraphDrawing`.

`cases.md` (PL-001 – PL-188, 188 rows; PL-178 – PL-188 are phase 2) pins the values. `ref.py`
certifies every row from the definitions below rather than from a library's answer. A planar
row gets a rotation system over every edge that satisfies Euler's formula. A non-planar row gets
an edge set checked to be a subdivision of K₅ or K₃,₃. Rows with at most 20,000 rotation systems
are also decided by enumerating all of them, and that enumeration also decides whether the
embedding, its faces and its face lengths are unique. Larger rows use Whitney's theorem. Rows
whose blocks have at most 16 edges list every Kuratowski subgraph (each lies in one block). NetworkX 3.7's
`check_planarity` must agree on every row, and its `PlanarEmbedding` (`check_structure`,
`faces`) must accept our rotation and give the same faces. python-igraph 1.0.0 supplies the
connectivity check for Whitney's theorem; it has no planarity test. `--stress` adds 1,500 random
multigraphs of up to 7 vertices against the enumeration oracle, plus 300 of 8–60 vertices that are
certified both ways. `--bench` prints the baselines under Performance. Run (about 25 s with
`--stress`):

`uv run --quiet --no-project --with networkx==3.7 --with igraph==1.0.0 python3 Tests/Catalogs/Planarity/ref.py [--write] [--stress]`

`--bench` also needs `--with scipy==1.18.1` (Delaunay triangulations) and uses rustworkx with
`--with rustworkx==0.18.1`. `PL_DUMP=<dir>` writes the instances for `boost_bench.cpp`, the Boost
harness (built with clang `-O2` against Boost 1.87; not compiled by the package).

## Scope

**In, phase 1**

| Entry point | Why |
|---|---|
| `isPlanar` → `Bool` | NetworkX `is_planar`, rustworkx `is_planar`, Boost `boyer_myrvold_planarity_test` (returns `bool`), JGraphT `isPlanar()`, LEMON `checkPlanarity`, OGDF `isPlanar`, Mathematica `PlanarGraphQ`, Sage `is_planar`. igraph 1.0 has none (an open feature request; IGraph/M borrows LEMON's). |
| `planarEmbedding()` → `PlanarEmbedding<Self>?` | The witness of planarity: NetworkX `check_planarity` (returns a `PlanarEmbedding`), Boost's `embedding` parameter, JGraphT `getEmbedding()`, LEMON `PlanarEmbedding`, OGDF `planarEmbed`. `nil` when the graph is not planar (README: failures that are mathematics return an optional). |
| `findKuratowskiSubgraph()` → `KuratowskiSubgraph<Self>?` | The witness of non-planarity: Boost's `kuratowski_subgraph` output and `is_kuratowski_subgraph`, JGraphT `getKuratowskiSubdivision()`, LEMON `PlanarEmbedding::kuratowski()`, NetworkX `check_planarity(counterexample=True)`, Sage `is_planar(kuratowski=True)`. `nil` when the graph is planar. Spelled as `findCycle()` and `findOddCycle()` (BipartiteGraphs): a `find…` method returns the witness against the property. |
| `PlanarEmbedding`: clockwise orders, `faces`, `faceCount`, `face(from:alongEdgeAt:)` | NetworkX `neighbors_cw_order`, `faces`, `traverse_face`; Boost `planar_face_traversal`; JGraphT `Embedding.getEdgesAround`; OGDF `CombinatorialEmbedding` faces. The faces are also what tests check Euler's formula with. They cost O(m) once the rotation exists. |
| `isOuterplanar` → `Bool` | Mathematica `OuterplanarGraphQ`, Sage `is_circular_planar`. The test is planarity of the graph plus one vertex adjacent to every vertex, so it costs one more run of the same engine. NetworkX, igraph and Boost have none. |

**Phase 2** (rows pinned now: PL-178 – PL-188 for the dual)

| Entry point | Why |
|---|---|
| `PlanarEmbedding.dualGraph()` → `Pseudograph<Int>` | Mathematica `DualPlanarGraph`, OGDF `DualGraph`, Sage `planar_dual`. Vertex i is face i (in `faces` order) and edge k is the dual of the k-th edge position. A dual has loops (bridges) and parallel edges (two faces sharing several edges), so it is a `Pseudograph` (Multigraphs). Pinned by vertex, edge and loop counts, the degree multiset, and isomorphism to a named graph. |
| `PlanarEmbedding.init?(clockwiseIncidentEdges:in:)` | A caller-supplied rotation checked for planarity (NetworkX `add_half_edge` and `check_structure`). Needed once drawing code produces embeddings. |
| Augmentation: `makeConnected`, `makeBiconnectedPlanar`, `makeMaximalPlanar` | Boost has all three. They are the preprocessing for straight-line drawing, so they ship with it. |
| Straight-line drawing (Chrobak–Payne, de Fraysseix–Pach–Pollack, Schnyder) | In `GraphDrawing`, built on `PlanarEmbedding`. NetworkX `planar_layout`, Boost `chrobak_payne_straight_line_drawing`, LEMON `PlanarDrawing` (Schnyder). |
| An outerplanar embedding and its witness (a K₄ or K₂,₃ subdivision) | Sage only. Derived from the apex reduction's embedding or Kuratowski subgraph. |

**Not planned, or later**

| Not in phase 1 | Reason |
|---|---|
| Planar separators (Lipton–Tarjan) | No mainstream graph library ships one. It is a building block for divide-and-conquer algorithms, not an end-user call. Later only if an algorithm here needs it. |
| Planar colouring (LEMON `PlanarColoring`: five-colouring) | Belongs to `ColoringModule`, which can take a `PlanarEmbedding`. |
| Genus, crossing number, k-planarity, upward planarity | Each is a different problem: NP-hard (genus, crossing number), or specific to directed graphs (upward). OGDF covers them. |
| Many Kuratowski subgraphs (Chimani–Mutzel–Schmidt 2008; OGDF `BoyerMyrvold::planarEmbed` with `kuratowskis`) | For branch and cut on crossing numbers. One witness is what every other library returns. |
| `DirectedGraph` overloads | Planarity concerns the underlying undirected graph. `graph.undirected` (`UndirectedView`) gives it: each arc becomes an edge, and a 2-cycle becomes two parallel edges (PL-055 – PL-061, PL-168). NetworkX reads a `DiGraph` the same way. Boost and JGraphT take undirected graphs only. |

## Summary

```swift
extension Graph {
    public var isPlanar: Bool
    public func planarEmbedding() -> PlanarEmbedding<Self>?
    public func findKuratowskiSubgraph() -> KuratowskiSubgraph<Self>?
    public var isOuterplanar: Bool
}

public struct PlanarEmbedding<G: Graph> {
    // The clockwise order around a vertex, starting at the first edge of incidentEdges(of:).
    // A self-loop appears twice (its two ends), as in incidentEdges(of:).
    public func clockwiseIncidentEdges(of vertex: G.Vertex) -> ArraySlice<G.Edges.Index>   // traps on a non-vertex
    public func clockwiseIncidentEdges(safe vertex: G.Vertex) -> ArraySlice<G.Edges.Index>? // Principle 6
    public func clockwiseNeighbors(of vertex: G.Vertex) -> ClockwiseNeighbors               // RandomAccessCollection<G.Vertex>
    public func clockwiseNeighbors(safe vertex: G.Vertex) -> ClockwiseNeighbors?
    public func clockwiseNeighborIndices(ofIndex index: Int) -> ArraySlice<Int>             // index space, O(1)

    public var faceCount: Int                       // Σ (2 − n_c + m_c) over components with an edge
    public var faces: Faces                         // RandomAccessCollection<Walk<G.Vertex, G.Edges.Index>>, closed walks
    // The face to the right of `position` crossed from `vertex` (NetworkX traverse_face(v, w)):
    // a closed walk starting and ending at `vertex`. On a loop, the end listed first in
    // clockwiseIncidentEdges(of: vertex). Traps when the edge is not at the vertex.
    public func face(from vertex: G.Vertex, alongEdgeAt position: G.Edges.Index) -> Walk<G.Vertex, G.Edges.Index>

    // Phase 2
    public func dualGraph() -> Pseudograph<Int>
}
extension PlanarEmbedding: CustomStringConvertible

public struct KuratowskiSubgraph<G: Graph> {
    public enum Kind: Hashable, Sendable { case k5, k33 }    // K₅, K₃,₃
    public var kind: Kind
    public var edges: [G.Edges.Index]               // ascending position; no loops, one copy of each parallel pair
    public var branchVertices: [G.Vertex]           // K₅: 5 in vertices order; K₃,₃: the side holding the first branch vertex, then the other, each in vertices order
    public var paths: [Path<G.Vertex, G.Edges.Index>]  // 10 or 9: branchVertices[i] to branchVertices[j], i < j lexicographic (K₃,₃: across the sides)
}
extension KuratowskiSubgraph: CustomStringConvertible
```

## Names

| Grafluent | Used by | Not chosen, and why |
|---|---|---|
| `isPlanar` | NetworkX `is_planar`, rustworkx, JGraphT `isPlanar()`, OGDF `isPlanar`, Sage | Boost `boyer_myrvold_planarity_test` and LEMON `checkPlanarity` name the algorithm or a verb. A Swift `Bool` property reads `is…` (as `isBipartite`). |
| `planarEmbedding()`, `PlanarEmbedding` | NetworkX `PlanarEmbedding`, LEMON `PlanarEmbedding`, the README row | Boost has no type, only a property map named `embedding`. JGraphT's `Embedding` alone drops "planar", and OGDF's `CombinatorialEmbedding` is the textbook term but longer and less familiar. |
| `findKuratowskiSubgraph()`, `KuratowskiSubgraph` | Boost `kuratowski_subgraph` and `is_kuratowski_subgraph`, NetworkX's docstring ("a Kuratowski subgraph"), the README row | JGraphT `getKuratowskiSubdivision`, OGDF `KuratowskiSubdivision`: "subdivision" is the more precise term, and the doc comment says the subgraph *is* a subdivision. Boost and NetworkX agree on "subgraph", which reads better as a noun beside `findCycle()`. NetworkX's `counterexample` says nothing about the shape. |
| `Kind`: `.k5`, `.k33` | K₅ and K₃,₃ (Kuratowski 1930). Sage writes "K5" and "K33" | `.completeGraph` / `.completeBipartiteGraph` are unambiguous but hide the sizes, and a reader looks for K₅ and K₃,₃. |
| `branchVertices`, `paths` | "branch vertices" of a subdivision (Diestel; OGDF's `KuratowskiSubdivision` is a list of paths) | NetworkX and JGraphT return a graph and leave the reader to find the structure. Tests and drawing code both need it. |
| `clockwiseNeighbors(of:)`, `clockwiseIncidentEdges(of:)` | NetworkX `neighbors_cw_order`, Boost's embedding (each vertex's edges in order), JGraphT `getEdgesAround`, written with the repo's `neighbors(of:)` and `incidentEdges(of:)` | `neighborsClockwise`, `rotation(of:)`: "rotation system" is the textbook name for the whole structure, but no library names an accessor after it. |
| `faces`, `faceCount`, `face(from:alongEdgeAt:)` | NetworkX `faces()`, `traverse_face(v, w)`; Boost `planar_face_traversal`; OGDF `CombinatorialEmbedding` | NetworkX names the face by a half-edge (v, w). A position is the repo's edge identity (parallel edges differ), and `alongEdgeAt:` follows `oppositeVertex(to:acrossEdgeAt:)`. |
| `isOuterplanar` | Mathematica `OuterplanarGraphQ`; "outerplanar" everywhere in the literature | Sage `is_circular_planar` is the older name. |
| `dualGraph()` (phase 2) | OGDF `DualGraph`, Mathematica `DualPlanarGraph`, Sage `planar_dual` | `dual()` alone is ambiguous next to other duals (line graphs, transposes). |

## Semantics

### Definitions (what every row checks)

A **half-edge** is an edge position leaving one of its ends; a self-loop has two half-edges, both
at its vertex. A **rotation system** lists, for each vertex, the half-edges leaving it in
clockwise order. Its **faces** are the orbits of the face permutation: after the half-edge
u → w comes the half-edge before w → u in the clockwise order at w. This is NetworkX's
`next_face_half_edge`, and the face lies to the right of each of its half-edges. Each face is a
closed walk, which may repeat vertices and edges: a bridge is crossed twice in one face (PL-099,
PL-122). A rotation system is a **planar embedding** when every connected component with an edge
satisfies Euler's formula n_c − m_c + f_c = 2. Every rotation system has n − m + f = 2 − 2g per
component, so equality means genus 0. Hence:

- `faceCount` = Σ (2 − n_c + m_c) over the components with an edge, on every planar row. An
  isolated vertex has no half-edge, so it has no face (PL-062, PL-063, PL-128), as NetworkX's
  `check_structure` and `faces` treat it. A disconnected graph's faces are counted per component:
  the combinatorial embedding does not place one component inside another's face. Two triangles
  have 4 faces (PL-087), where a drawing in the plane would have 3.
- **Kuratowski subgraph**: a set of edge positions, without loops or two copies of one pair, whose
  degree-2 vertices can be suppressed to leave exactly K₅ (five branch vertices of degree 4, ten
  paths, one per pair) or K₃,₃ (six of degree 3, nine paths, bipartite 3 + 3). Kuratowski's
  theorem says exactly one of the two witnesses exists.
- **Outerplanar**: planar with every vertex on one face; equivalently, the graph plus a new vertex
  adjacent to every vertex is planar.

### Inputs

- **Self-loops and parallel edges never change the answer.** The test runs on the underlying
  simple graph (PL-049 – PL-054), and the embedding still covers **every edge position**.
  Parallel copies sit side by side in the rotation, and a loop's two ends are adjacent where the
  algorithm puts the loop, enclosing a face of length 1 (PL-089 – PL-095, PL-115, PL-125).
  NetworkX's embedding drops both (disagreements). Its Euler check would fail on the full edge
  set, and a caller keyed by position could not find the dropped edges. A Kuratowski subgraph
  never uses a loop and uses one copy of a parallel pair. Which copy is not pinned (PL-140).
- **Disconnected graphs**: planar exactly when every component is; the Kuratowski subgraph lies in
  one block (PL-138, PL-150).
- **Directed graphs** go through `graph.undirected` (Scope).
- **Vertex labels**: results are in the graph's vertices and edge positions, never indices
  (PL-116, PL-151); `clockwiseNeighborIndices(ofIndex:)` is the index-space accessor.

### Results

- `PlanarEmbedding` holds the graph (as `BiconnectedComponents` does, copy-on-write, O(1)), the
  rotation as one flat array of half-edge ids in vertex rows, each half-edge's slot, and the faces
  as one flat array with offsets, built once (O(m)).
- A clockwise order starts at the first edge of `incidentEdges(of:)`: a cyclic order needs a start,
  and this one costs nothing and makes rows comparable.
- `faces` lists faces in the order a walk of vertices in index order and each rotation in order
  first reaches them (NetworkX `faces()`). Each face starts at that half-edge's tail.
- `KuratowskiSubgraph.edges` is ascending; `paths` follow `branchVertices`.

## Determinism (decision)

**Pinned:** every yes/no answer (`isPlanar`, `isOuterplanar`, `nil` or not); `faceCount` on every
planar row; the face-length multiset wherever every planar embedding has the same one (from the
enumeration, from Whitney's theorem, or because the graph is a forest); the faces, the clockwise
orders and `face(from:alongEdgeAt:)` where the embedding is unique up to mirror image, written
"A or B (mirror image)". The test accepts either, but the same one for the whole embedding. A
unique Kuratowski subgraph is pinned exactly (K₅ and K₃,₃ themselves, their subdivisions, and a
Kuratowski subgraph plus pendant parts or other blocks: PL-133 – PL-139, PL-141, PL-151). Its kind
is pinned wherever only one kind occurs: Petersen, Wagner, Heawood, K₃,₄ and K₄,₄ contain only
K₃,₃ subdivisions, and two K₅s sharing a vertex contain only K₅ subdivisions.

**Not pinned:** the embedding of a graph with several (a star, a bowtie, K₄ with a loop: PL-066,
PL-070, PL-095); which Kuratowski subgraph is found when there are several (K₆ has 76: PL-142),
and its kind when both occur; the order of `faces`. Tests check these against the definitions:
Euler's formula, each rotation a permutation of the vertex's half-edges, `faces` partitioning the
2m half-edges, and the witness being a subdivision of its `kind`. They also check that a second
call returns the same result. The algorithm is deterministic (depth-first search in index order,
edges in incidence order), but pinning its choice would freeze the DFS order, and so the choice
of algorithm.

Whitney's theorem (a 3-connected planar graph has one embedding up to mirror image, and so does a
subdivision of one) is what makes uniqueness checkable on large rows (PL-170, PL-172). `ref.py`
asserts that it agrees with the enumeration wherever both apply.

## Algorithms (decision)

**Recommendation: the left-right planarity test (de Fraysseix–Rosenstiehl 1982, in Brandes's 2009
formulation, "The Left-Right Planarity Test") for `isPlanar`, `planarEmbedding()` and
`isOuterplanar`, and Boyer–Myrvold (JGAA 8(3), 2004) with its Kuratowski isolation for
`findKuratowskiSubgraph()`.** All three candidates are linear. The measurements below make speed
the deciding factor for the test, and witness extraction the deciding factor for the second
engine.

- **Speed.** On the same inputs and machine, rustworkx's `is_planar` (a Rust port of NetworkX's
  left-right code) is 1.2–15× faster than Boost's `boyer_myrvold_planarity_test`: 10.5 ms against
  49.6 ms on a 10,000-point Delaunay triangulation, 189 ms against 1,997 ms at 100,000 points,
  and 104 ms against 1,554 ms on a 316 × 316 grid. A 2025 TU Wien thesis compared C++
  implementations (PIGALE's, OGDF's Boyer–Myrvold, and two of Brandes's pseudo-code built on OGDF)
  and found the same ordering: PIGALE's left-right test was the fastest
  in every configuration, about 70 % faster than OGDF's Boyer–Myrvold, which was the slowest
  (Wodniansky-Wildenfeld, "The Left-Right Planarity Test: Comparing Variants and
  Implementations"). The 2003 comparison of six algorithms (Boyer, Cortese, Patrignani,
  Di Battista, "Stop minding your P's and Q's", GD 2003) put the left-right test and an early
  Boyer–Myrvold among the fastest. The left-right test is also shorter: one DFS orientation pass,
  one pass over conflict pairs, and an embedding pass. NetworkX's implementation (Python) and rustworkx's port
  (Rust) are direct references for it. So is the pseudo-code in Brandes's paper.
- **Witness extraction.** The left-right test has no widely implemented Kuratowski extraction.
  NetworkX's `get_counterexample` deletes edges one by one and reruns the test: O(m) tests, so
  quadratic. That took 30 s on a 1,000-vertex near-planar graph (Performance). A linear extraction
  for left-right exists (de Fraysseix–Ossona de Mendez, "On cotree-critical and DFS cotree-critical
  graphs", JGAA 7(4), 2003, used in PIGALE), but PIGALE is its only implementation. Boyer–Myrvold
  isolates a K₅ or K₃,₃ subdivision in linear time from the state where the embedding fails. Boost
  (`kuratowski_subgraph`), Boyer's edge-addition planarity suite (used by Sage), OGDF and JGraphT
  all implement it, and Boost's run with the embedding and Kuratowski outputs costs 1.5–2.2× its bare test
  (26.7 ms against 18.3 ms on the 10,000-point Delaunay graph plus one edge). This is the reference to port.
- **Why two engines.** The embedding and the yes/no answer are the frequent calls, and they get the
  fastest engine. The witness is requested only for non-planar graphs, and Boyer–Myrvold is the
  only linear extraction with several implementations to compare against. Both share the
  index-space set-up (simple underlying graph, DFS numbering), and `ref.py` checks both through
  the same certificates.
- **Single-engine fallback.** If two engines are too much code, use Boyer–Myrvold for everything,
  as the README row says now. It is correct and linear but, going by Boost and OGDF, 2–10× slower
  on the test. Alternatively, keep left-right and port PIGALE's cotree-critical extraction, which
  has one implementation to check against. Both are open question 1.
- **Hopcroft–Tarjan (1974)** and the PQ-tree vertex-addition algorithms (Booth–Lueker, OGDF
  `BoothLueker`) are rejected. Hopcroft–Tarjan is linear but famously intricate, and its embedding
  extension (Mehlhorn–Mutzel) is harder still. The PQ-tree algorithms were slower in the 2003
  comparison.
- **Shortcuts.** A simple graph with m > 3n − 6 is not planar (PL-013). `isPlanar` answers at once.
  `findKuratowskiSubgraph()` runs Boyer–Myrvold on the first 3n − 5 distinct pairs only, which are
  already non-planar, so it is O(n) after the O(m) deduplication. Components and blocks need no
  special handling: both algorithms run on a DFS forest.

## Implementation notes (index space)

- Read rows once through `_runOnUndirectedRows` (stored rows of `UndirectedAdjacencyList`, lazy rows
  otherwise), with `endpointIndices(ofEdgeAt:)` and `degree(ofIndex:)` where a representation
  offers them. Build the simple underlying graph in one pass: per vertex, a stamp array marks
  neighbours already seen; loops and later copies go to side lists.
- The engines work on half-edge ids 2k and 2k + 1 for edge number k, in flat `Int32` arrays sized
  once (`~Copyable` scratch, an explicit DFS stack, no recursion), per the performance notes.
- After the test, splice each parallel copy beside its representative (ascending at the
  lesser-index end, descending at the other) and each loop as two adjacent half-edges. Then rotate
  every row to start at its first incident edge. This is O(m).
- Faces: one pass marking half-edges (O(m)), storing offsets.
- Outerplanarity: the left-right test on the graph plus an apex, in place: the apex is index n, and
  its row is generated rather than stored.

## Complexity

| Entry point | Time | Extra memory |
|---|---|---|
| `isPlanar` | O(n + m) (O(1) after the edge count when m > 3n − 6 on the simple graph) | O(n + m) |
| `planarEmbedding()` | O(n + m), faces included | O(n + m), kept in the result |
| `findKuratowskiSubgraph()` | O(n + m): deduplication, then Boyer–Myrvold on at most 3n − 5 pairs | O(n) after deduplication |
| `isOuterplanar` | O(n + m) | O(n + m) |
| `clockwise…(of:)`, `face(from:alongEdgeAt:)` | O(1) to slice; O(face length) for a face | — |
| `dualGraph()` (phase 2) | O(n + m) | O(f + m) |

## Performance

Baselines (`ref.py --bench` and `boost_bench.cpp`, one run on Apple M1 Ultra, CPython 3.14,
NetworkX 3.7, rustworkx 0.18.1, Boost 1.87 at `-O2`, best of 5 for Boost). The Delaunay graphs
are triangulations of uniform random points (NumPy seed 1). "+ one edge" joins vertex 0 to the
highest-numbered vertex not already adjacent to it, which makes the graph non-planar.

| Input | n | m | NetworkX `check_planarity` | rustworkx `is_planar` | Boost test | Boost test + embedding + Kuratowski |
|---|---|---|---|---|---|---|
| Delaunay, 10,000 points | 10,000 | 29,973 | 462 ms | 10.5 ms | 49.6 ms | 72.1 ms |
| Delaunay, 100,000 points | 100,000 | 299,972 | 7,417 ms | 189 ms | 1,997 ms | 2,360 ms |
| grid 316 × 316 | 99,856 | 199,080 | 4,181 ms | 104 ms | 1,554 ms | 1,653 ms |
| stacked triangulation, 100,000 | 100,000 | 299,994 | 7,044 ms | 151 ms | 180 ms | 516 ms |
| Delaunay 10,000 + one edge | 10,000 | 29,974 | 122 ms | 3.9 ms | 18.3 ms | 26.7 ms (2,117-edge witness) |
| stacked triangulation 100,000 + one edge | 100,000 | 299,995 | 1,117 ms | 148 ms | 119 ms | 265 ms (33-edge witness) |
| Delaunay 1,000 + one edge: witness | 1,000 | 2,979 | 30,051 ms (`counterexample=True`) | — | 0.7 ms | 1.2 ms (381 edges) |

Readings: the C++ and Rust baselines differ by up to 15× on the same graphs, which says more about
implementations (Boost's list-based embedding storage) than about the algorithms. NetworkX's
witness is quadratic. The stacked triangulation has a short witness and good locality. The
Delaunay graph's witness runs around the whole convex hull.

Targets, measured in the benchmark target on the same instances (the Delaunay points generated
once and stored as edge lists):

| Measure | Target |
|---|---|
| `isPlanar` on the four planar inputs (10⁴–3 × 10⁵ edges) | ≤ rustworkx `is_planar`; ≥ 30× NetworkX |
| `planarEmbedding()` (rotation and faces) | ≤ 1.5× our `isPlanar`; ≤ ½ of Boost's test with embedding |
| `isPlanar` on the near-planar inputs | ≤ rustworkx (failure is found mid-run) |
| `findKuratowskiSubgraph()` on the near-planar inputs | ≤ Boost's test with Kuratowski output (26.7 ms, 265 ms, 1.2 ms) |
| `isPlanar` on dense inputs (m > 3n − 6 distinct pairs) | O(m) to count distinct pairs, no DFS |
| Allocations | `isPlanar`: scratch only (no per-vertex arrays); `planarEmbedding()`: the result's arrays plus scratch |

## Library disagreements found

| Where | What | Catalog |
|---|---|---|
| NetworkX `check_planarity` on multigraphs | The embedding is built on a copy without self-loops and with parallel edges merged (its `faces()` docstring says so). Ours embeds every edge position, and Euler's formula is checked on all of them. | PL-089 – PL-095, PL-115, PL-125 |
| NetworkX Kuratowski subgraph | `get_counterexample` deletes edges one at a time with a full test each (quadratic: 30 s at 1,000 vertices). It returns a bare graph without the kind or the branch vertices. | Performance; PL-133 – PL-151 |
| python-igraph 1.0.0 | No planarity test at all; rustworkx has only the `Bool`. | — |
| Disconnected faces | NetworkX's `check_structure` and ours count faces per component. A plane drawing would share one outer face (f = m − n + c + 1). Ours follows the combinatorial definition, which every library's face traversal implements. | PL-087, PL-129 |

## README edits proposed

- `Planarity` row: "On `Graph`: `isPlanar`, `planarEmbedding()` (left-right planarity test,
  Brandes's formulation; every edge position embedded, loops and parallel edges included),
  `findKuratowskiSubgraph()` (Boyer–Myrvold's Kuratowski isolation), `isOuterplanar`.
  `PlanarEmbedding` gives the clockwise orders, `faces`, `faceCount` and
  `face(from:alongEdgeAt:)`. Phase 2: `dualGraph()`, embeddings supplied by the caller,
  augmentation; straight-line drawing goes in `GraphDrawing`." Result types: `PlanarEmbedding`,
  `KuratowskiSubgraph` (kind, edges, branch vertices, paths).
- Terminology: "Clockwise order of edges at each vertex: rotation system / combinatorial
  embedding (NetworkX `PlanarEmbedding`, OGDF `CombinatorialEmbedding`)"; "Subdivision of K₅ or
  K₃,₃: Kuratowski subgraph (Boost, NetworkX); JGraphT, OGDF: Kuratowski subdivision".
- BUILD deps: `GraphProtocols` and `Walks` (faces are `Walk`s, branch paths are `Path`s);
  `Traversal` is not needed. Phase 2 adds `Multigraphs` for the dual's `Pseudograph`.

## Open questions (with recommendations)

1. **One engine or two.** *Recommendation:* two (left-right for the test and embedding,
   Boyer–Myrvold for the witness), decided by the benchmark table: left-right is the fast one in
   every comparison found, and Boyer–Myrvold is the only linear extraction with several reference
   implementations. If the second engine's size is unwelcome, use Boyer–Myrvold alone first and
   switch the test to left-right when the `isPlanar` target is missed.
2. **A combined call.** NetworkX `check_planarity(G, counterexample=True)` returns either witness
   in one run. On a non-planar graph, `planarEmbedding()` followed by `findKuratowskiSubgraph()`
   runs twice. *Recommendation:* no combined entry in phase 1, since both runs are linear. Add one
   only if a caller shows the cost, and then as an enum in NetworkX's spirit rather than a `Result`
   (a Kuratowski subgraph is not an `Error`).
3. **`Kind` case names.** *Recommendation:* `.k5`, `.k33`, documented as K₅ and K₃,₃.
4. **Pinning the embedding.** *Recommendation:* not pinned (Determinism). Revisit only if a caller
   needs reproducible drawings across library versions.
5. **Face order and the clockwise start.** *Recommendation:* the start is pinned (first incident
   edge); the face order is not, because it follows the rotation.
