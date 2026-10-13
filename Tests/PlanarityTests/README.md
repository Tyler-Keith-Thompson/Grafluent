# Planarity test suite

`Planarity` answers whether an undirected graph is planar, with a witness either way: a
`PlanarEmbedding` (a rotation system, the clockwise order of the edges around each vertex, and its
faces) when it is, and a `KuratowskiSubgraph` (a subdivision of K₅ or K₃,₃) when it is not. It also
tests outerplanarity. The API description (`api.md`) is in
[`Tests/Catalogs/Planarity/`](../Catalogs/Planarity/). Two engines run behind it: the left-right
test (Brandes's formulation) for `isPlanar`, `planarEmbedding()` and `isOuterplanar`, and
Boyer–Myrvold's Kuratowski isolation for `findKuratowskiSubgraph()`. The embedding is not pinned
where it is not unique. Each clockwise order starts at the first incident edge, and the order of
`faces` follows the rotation.

The suite uses only the public API, and each test is self-contained. The only shared material is
the seeded generator, `ReferencePseudograph` and the tags in `GrafluentTestSupport`.

## API under test

```swift
extension Graph {
    var isPlanar: Bool
    func planarEmbedding() -> PlanarEmbedding<Self>?
    func findKuratowskiSubgraph() -> KuratowskiSubgraph<Self>?
    var isOuterplanar: Bool
}
struct PlanarEmbedding<G: Graph>: CustomStringConvertible
    clockwiseIncidentEdges(of:), clockwiseIncidentEdges(checked:), clockwiseNeighbors(of:),
        clockwiseNeighbors(checked:), clockwiseNeighborIndices(ofIndex:)
        faceCount, faces, face(from:alongEdgeAt:), rightFace(from:alongEdgeAt:)

struct KuratowskiSubgraph<G: Graph>: CustomStringConvertible
    kind (.k5, .k33), edges, branchVertices, paths
```

## Conventions

| Question | Choice | Cases |
|---|---|---|
| Loops and parallel edges | Never change an answer; every edge position is embedded, a loop's position twice | PL-049 – PL-054, PL-089 – PL-095, PL-115, PL-125 |
| Clockwise start | The first edge of `incidentEdges(of:)` | every planar row |
| Faces | Orbits of "the slot before the twin, clockwise", met walking the vertices in order and each row in order | every planar row |
| `faceCount` | Σ (2 − n_c + m_c) over components with an edge; an isolated vertex has no face | PL-062, PL-063, PL-087, PL-128, PL-129 |
| Loop in `face(from:alongEdgeAt:)` | The end listed first in the clockwise order | PL-125, PL-093 |
| Witness edges | Ascending positions, no loop, one copy of a parallel pair | PL-139, PL-140 |
| Branch vertices | K₅ in vertices order; K₃,₃ the side holding the first, then the other, each in vertices order | PL-133 – PL-151 |
| Paths | One per pair, i < j lexicographic (K₃,₃ across the sides), from `branchVertices[i]` | PL-133 – PL-151 |
| Directed graphs | Through `graph.undirectedView` | PL-055 – PL-061, PL-168 |
| Non-vertices | The vertex-keyed accessors trap; the `checked:` spellings throw `VertexNotFound` | PL-117, PL-118 |

## How values are pinned

Graphs are `Pseudograph<Int>` (Multigraphs) with every vertex of the row listed, so vertex order
and edge positions are the catalog's. `D:` rows are `AdjacencyList<Int>(...).undirectedView`. Large
rows carry their edges as one flat array of ends.

Every planar row checks the embedding against the definitions, written out in the test:

- each clockwise order is a permutation of the vertex's incident edges (a loop twice) and starts at
  the first one;
- `clockwiseNeighbors`, `clockwiseNeighborIndices(ofIndex:)` and the `checked:` spellings say the
  same;
- `faces` is exactly the orbits of the face permutation, in the documented order and from the
  documented start, computed in the test from the clockwise orders;
- `face(from:alongEdgeAt:)` is the orbit from every half-edge (a sample of them on the largest
  rows), and `rightFace(from:alongEdgeAt:)` is that orbit's position in `faces`;
- `faceCount` is Euler's count;
- a second call returns the same embedding, `isPlanar` is true and there is no witness.

Then the row's pinned values: the face-length multiset where every embedding has the same one. Where
the embedding is unique up to mirror image, every clockwise order is compared, read cyclically, with
the model's embedding or with its mirror image. Whichever of the two matches must match at every
vertex, and the row's accessor (`faces`, a clockwise order, a face) is then checked against that
same choice.

Every non-planar witness is checked against the definition: ascending positions of the graph, no
loop, no two copies of a pair, branch vertices in the documented order, and one path per pair in the
documented order. Each path joins its pair through the graph's edges, its inner vertices are not
branch vertices and lie on that path only, and together the paths use every witness edge once. A
unique witness (K₅, K₃,₃, their subdivisions, with pendant parts or other blocks) is pinned
exactly. Where only one kind occurs, the kind is pinned. A second call returns the same witness.

The catalog-row files are every file except `PlanarityConformanceTests.swift`,
`PlanarityPropertyTests.swift`, `Performance/PlanarityStressTests.swift`,
`Performance/PlanarityDeepGraphTests.swift`, `PlanarityEngineBranchTests.swift` and
`PlanarityLayoutTests.swift` (the scale rows, `Performance/PlanarityScaleTests.swift`, are catalog
rows too). `swiftgen.py` generates them from `cases.md`; it sits next to `ref.py` and `cases.md` in
[`Tests/Catalogs/Planarity/`](../Catalogs/Planarity/):

```
uv run --quiet --no-project --with networkx==3.7 --with igraph==1.0.0 python3 Tests/Catalogs/Planarity/swiftgen.py [--phase2]
```

It first checks that `ref.py` reproduces `cases.md` byte for byte. Then it re-evaluates every row
with `ref.py`'s functions (the enumeration oracle, the embedding NetworkX certifies, Whitney's
theorem, the enumeration of Kuratowski subgraphs) and asserts that each value it writes matches the
catalog cell. The precondition file also takes the hand-written exit tests in `extra_traps.swift`,
and the in-process tests of the `checked:` spellings there. The catalog's dual-graph rows (PL-178 –
PL-188) have no tests.

A trap row runs the trapping call in a child process (an exit test). The same setup then runs in
this process without the call, so the trap comes from the call and not from the setup.

## Hand-written files

- **Conformance.** Graphs with the same rows give the same embedding and witness, position for
  position: `Pseudograph`, `Multigraph` (loop-free), `ReferencePseudograph`, and a file-private
  conformer with no vertex or edge indices. `UndirectedAdjacencyList` (parallel edges collapsed),
  `AdjacencyList.undirectedView` and `AdjacencyMatrix.undirectedView` (whose positions are cells)
  give the same answers, and each embedding and witness meets the definitions. A copy with String
  vertices gives the same embedding through the labels. A copy with its vertices listed and its
  edges inserted in another order gives the same answers and face count. An embedding and a witness
  keep the graph they were made from.
- **Properties** (swift-property-based, with shrinking). The brute-force model enumerates every
  rotation system of a small multigraph with loops and parallel edges (up to 6 vertices and 11
  edges, at most 40 000 rotation systems). Euler's formula on its face orbits decides planarity,
  and a face through every vertex of each component decides outerplanarity. The tests compare
  `isPlanar`, `isOuterplanar`, the embedding (one of the model's planar rotations) and the witness
  (its degrees). On graphs of up to 30 vertices, exactly one witness exists and meets the
  definitions; a chord drawn inside a face keeps the graph planar and adds one face; and a
  Kuratowski subgraph is minimal, since deleting any of its edges leaves a planar graph. On graphs
  of up to 14 vertices the two engines are cross-checked: Boyer–Myrvold on the graph plus an apex
  agrees with `isOuterplanar`, reversing the labels and the edge order changes no answer, a second
  call returns the same embedding and witness, and `rightFace` names the face that
  `face(from:alongEdgeAt:)` walks.
- **Deep graphs** (`Performance/PlanarityDeepGraphTests.swift`), depth-first trees 10⁵ or more
  vertices deep: a 200 000-vertex path; a 100 000-rung ladder and a 100 000-vertex polygon fan (both
  outerplanar, the fan with exactly 2n − 3 edges, and not outerplanar after one more chord); a K₃,₃
  with each edge subdivided into 20 001 edges, whose witness is the whole graph; and a K₅ at the end
  of a 200 000-vertex path.
- **Engine branches** (`PlanarityEngineBranchTests.swift`): the smallest graphs where a
  bug in one branch changes the outcome: an edge returning as low as its parent edge (the
  left-right test's second-lowest return point), a Walkdown stopping vertex already beside the
  root on the other side (the short-circuit's deviation from the reference implementation,
  documented in `BoyerMyrvold.swift`), minor C attached above both x and y, and minor E2. Each is
  checked against the definitions, the witnesses for minimality.
- **Stress.** Each test has a one-minute limit:
  - a 120 × 120 triangulated grid (3-connected, so its embedding is unique: triangles and one
    outer face);
  - a 100 × 100 triangulated grid plus an apex on its outer cycle (maximal planar, a Delaunay
    triangulation's shape), and the same plus one more edge;
  - a 30 × 30 triangulated grid plus an edge between far interior vertices, with its witness
    checked;
  - a 20 000-vertex stacked triangulation, plus one edge, with a witness on its first 3 000
    vertices;
  - a 300 × 300 grid, and the same plus one far edge.

## Mutation testing

The implementation is checked by `just mutate Planarity` (scripts/mutants/Planarity.py): 100
mutants over the reading of the simple graph and the shortcuts; the left-right test's
orientation, nesting order, conflict pairs, side resolution and embedding search; the layout's
rows, twins, copies, loops and face tracing; the public accessors; Boyer–Myrvold's set-up, Walkup
and Walkdown (including the short-circuit beside the root); and the Kuratowski isolation, with a
marking mutant in each of minors A–D, E1 (x side), E2, E3, E4 and the K₅ case, each caught, which
shows each case is reached. Five survive as equivalent (two sorts that give the same order, a sign
that is never 0, a choice between planar embeddings, and two Walkup stops that only cost time);
the spec lists each with its reason. `PlanarityLayoutTests.swift` pins where a loop goes beside
parallel copies, and `PlanarityEngineBranchTests.swift` holds deterministic graphs for mutants the
randomized properties catch only on some runs.
