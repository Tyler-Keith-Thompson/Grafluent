# Planarity: API

Planarity testing on `Graph` with a witness either way: a combinatorial embedding (a rotation
system: the clockwise order of the edges around each vertex) when the graph is planar, and a
Kuratowski subgraph (a subdivision of K₅ or K₃,₃) when it is not. The embedding gives its faces;
outerplanarity is one more test. Coordinates (straight-line drawings) belong to `GraphDrawing`.

`cases.md` (PL-001 – PL-188, 188 rows) pins the values; PL-178 – PL-188 pin dual graphs, which no
entry point computes. `ref.py` certifies every row from the definitions below rather than from a
library's answer. A planar row gets a rotation system over every edge that satisfies Euler's
formula. A non-planar row gets an edge set checked to be a subdivision of K₅ or K₃,₃. Rows with at
most 20,000 rotation systems are also decided by enumerating all of them, and that enumeration
also decides whether the embedding, its faces and its face lengths are unique. Larger rows use
Whitney's theorem. Rows whose blocks have at most 16 edges list every Kuratowski subgraph (each
lies in one block). NetworkX 3.7's `check_planarity` must agree on every row, and its
`PlanarEmbedding` (`check_structure`, `faces`) must accept our rotation and give the same faces.
python-igraph 1.0.0 supplies the connectivity check for Whitney's theorem. `--stress` adds 1,500
random multigraphs of up to 7 vertices against the enumeration oracle, plus 300 of 8–60 vertices
that are certified both ways. Run:

`uv run --quiet --no-project --with networkx==3.7 --with igraph==1.0.0 python3 Tests/Catalogs/Planarity/ref.py [--write] [--stress]`

## Scope

| Entry point | Purpose |
|---|---|
| `isPlanar` → `Bool` | The decision |
| `planarEmbedding()` → `PlanarEmbedding<Self>?` | The witness of planarity; `nil` when the graph is not planar |
| `findKuratowskiSubgraph()` → `KuratowskiSubgraph<Self>?` | The witness of non-planarity; `nil` when the graph is planar. Spelled as `findCycle()` and `findOddCycle()`: a `find…` method returns the witness against the property |
| `PlanarEmbedding`: clockwise orders, `faces`, `faceCount`, `face(from:alongEdgeAt:)`, `rightFace(from:alongEdgeAt:)` | The faces cost O(m) once the rotation exists, and they are what tests check Euler's formula with |
| `isOuterplanar` → `Bool` | Planarity of the graph plus one vertex adjacent to every vertex, so one more run of the same engine |

A directed graph's planarity is that of its underlying undirected graph: use
`graph.undirectedView`.

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
    // Each a RandomAccessCollection indexed from 0, O(1) to make, over the embedding's 32-bit rows.
    public func clockwiseIncidentEdges(of vertex: G.Vertex) -> ClockwiseIncidentEdges       // of G.Edges.Index; traps on a non-vertex
    public func clockwiseIncidentEdges(checked vertex: G.Vertex) throws(VertexNotFound) -> ClockwiseIncidentEdges
    public func clockwiseNeighbors(of vertex: G.Vertex) -> ClockwiseNeighbors               // of G.Vertex
    public func clockwiseNeighbors(checked vertex: G.Vertex) throws(VertexNotFound) -> ClockwiseNeighbors
    public func clockwiseNeighborIndices(ofIndex index: Int) -> ClockwiseNeighborIndices    // of Int, index space; without vertex indices, index i is the i-th vertex of `vertices`

    public var faceCount: Int                       // Σ (2 − n_c + m_c) over components with an edge
    public var faces: Faces                         // RandomAccessCollection<Walk<G.Vertex, G.Edges.Index>>, closed walks
    // The face to the right of `position` crossed from `vertex`:
    // a closed walk starting and ending at `vertex`. On a loop, the end listed first in
    // clockwiseIncidentEdges(of: vertex). Traps when the edge is not at the vertex.
    public func face(from vertex: G.Vertex, alongEdgeAt position: G.Edges.Index) -> Walk<G.Vertex, G.Edges.Index>
    // The position in `faces` of that face.
    public func rightFace(from vertex: G.Vertex, alongEdgeAt position: G.Edges.Index) -> Int
    // ElementNotFound.vertex for a non-vertex, else .edge for a position that is not
    // an edge or whose edge has no end at the vertex.
    public func face(checkedFrom vertex: G.Vertex, alongEdgeAt position: G.Edges.Index) throws(ElementNotFound) -> Walk<G.Vertex, G.Edges.Index>
    public func rightFace(checkedFrom vertex: G.Vertex, alongEdgeAt position: G.Edges.Index) throws(ElementNotFound) -> Int

    
}
extension PlanarEmbedding: CustomStringConvertible

public struct KuratowskiSubgraph<G: Graph> {
    public let kind: KuratowskiGraph
    public let edges: [G.Edges.Index]               // ascending position; no loops, one copy of each parallel pair
    public let branchVertices: [G.Vertex]           // K₅: 5 in vertices order; K₃,₃: the side holding the first branch vertex, then the other, each in vertices order
    public let paths: [Path<G.Vertex, G.Edges.Index>]  // 10 or 9: branchVertices[i] to branchVertices[j], i < j lexicographic (K₃,₃: across the sides)
}
extension KuratowskiSubgraph: Equatable, CustomStringConvertible

// Top level, not nested in the generic KuratowskiSubgraph, so kinds compare across graph types.
public enum KuratowskiGraph: Hashable, Sendable, CaseIterable { case k5, k33 }   // K₅, K₃,₃
```

## Semantics

### Definitions (what every row checks)

A **half-edge** is an edge position leaving one of its ends; a self-loop has two half-edges, both at
its vertex. A **rotation system** lists, for each vertex, the half-edges leaving it in clockwise
order. Its **faces** are the orbits of the face permutation: after the half-edge u → w comes the
half-edge before w → u in the clockwise order at w, and the face lies to the right of each of its
half-edges. Each face is a closed walk, which may repeat vertices and edges: a bridge is crossed
twice in one face (PL-099, PL-122). A rotation system is a **planar embedding** when every connected
component with an edge satisfies Euler's formula n_c − m_c + f_c = 2. Every rotation system has n −
m + f = 2 − 2g per component, so equality means genus 0. Hence:

- `faceCount` = Σ (2 − n_c + m_c) over the components with an edge, on every planar row. An isolated
  vertex has no half-edge, so it has no face (PL-062, PL-063, PL-128). A disconnected graph's faces
  are counted per component: the combinatorial embedding does not place one component inside
  another's face. Two triangles have 4 faces (PL-087), where a drawing in the plane would have 3.
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
  algorithm puts the loop, enclosing a face of length 1 (PL-089 – PL-095, PL-115, PL-125),
  so a caller keyed by position finds every edge. A Kuratowski subgraph
  never uses a loop and uses one copy of a parallel pair. Which copy is not pinned (PL-140).
- **Disconnected graphs**: planar exactly when every component is; the Kuratowski subgraph lies in
  one block (PL-138, PL-150).
- **Directed graphs** go through `graph.undirectedView`: each arc becomes an edge, and a 2-cycle
  becomes two parallel edges (PL-055 – PL-061, PL-168).
- **Vertex labels**: results are in the graph's vertices and edge positions, never indices
  (PL-116, PL-151); `clockwiseNeighborIndices(ofIndex:)` is the index-space accessor. On a graph
  without vertex indices, index i is the i-th vertex of `vertices` (its position).

### Results

- `PlanarEmbedding` holds the graph (as `BiconnectedComponents` does, copy-on-write, O(1)), the
  rotation as one flat array of half-edge ids in vertex rows, each half-edge's slot, and the faces
  as one flat array with offsets, built once (O(m)).
- A clockwise order starts at the first edge of `incidentEdges(of:)`: a cyclic order needs a start,
  and this one costs nothing and makes rows comparable.
- `faces` lists faces in the order a walk of vertices in index order and each rotation in order
  first reaches them. Each face starts at that half-edge's tail.
- `KuratowskiSubgraph.edges` is ascending; `paths` follow `branchVertices`.

## Determinism

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
edges in incidence order).

**Guaranteed:** graphs with identical rows (the same vertices in the same order, the
same edge positions, the same incidence order) get the same embedding and the same witness,
position for position, whatever the representation (`Pseudograph`, `Multigraph`, a conformer
without vertex or edge indices). Both engines read only the rows, so this holds by construction;
the conformance tests check it.

Whitney's theorem (a 3-connected planar graph has one embedding up to mirror image, and so does a
subdivision of one) is what makes uniqueness checkable on large rows (PL-170, PL-172). `ref.py`
asserts that it agrees with the enumeration wherever both apply.

## Algorithms

The left-right planarity test (de Fraysseix–Rosenstiehl 1982, in Brandes's 2009 formulation, "The
Left-Right Planarity Test") answers `isPlanar`, `planarEmbedding()` and `isOuterplanar`: one DFS
orientation pass, one pass over conflict pairs, and an embedding pass. Boyer–Myrvold (JGAA 8(3),
2004) with its Kuratowski isolation answers `findKuratowskiSubgraph()`: it isolates a K₅ or K₃,₃
subdivision in linear time from the state where the embedding fails. Both share the index-space
set-up (simple underlying graph, DFS numbering), and `ref.py` checks both through the same
certificates.

**Shortcuts.** A simple graph with m > 3n − 6 is not planar (PL-013); `isPlanar` answers at once.
`findKuratowskiSubgraph()` runs Boyer–Myrvold on the first 3n − 5 distinct pairs only, which are
already non-planar, so it is O(n) after the O(m) deduplication. Components and blocks need no
special handling: both algorithms run on a DFS forest.

## Implementation notes (index space)

- Read rows once through `_runOnUndirectedRows` (stored rows of `UndirectedAdjacencyList`, lazy rows
  otherwise), with `endpointIndices(ofEdgeAt:)` and `degree(ofIndex:)` where a representation
  offers them. Build the simple underlying graph in one pass: per vertex, a stamp array marks
  neighbours already seen; loops and later copies go to side lists.
- The engines work on half-edge ids 2k and 2k + 1 for edge number k, in flat `Int32` arrays sized
  once (`~Copyable` scratch, an explicit DFS stack, no recursion). The
  left-right engine reads the simple graph's own arrays rather than copying them, and initializes
  only the arrays it reads before writing. Its embedding pass orders each vertex's outgoing edges
  when the search first reaches the vertex, so there is no separate linking pass.
- After the test, splice each parallel copy beside its representative (ascending at the
  lesser-index end, descending at the other) and each loop as two adjacent half-edges. Then rotate
  every row to start at its first incident edge. This is O(m).
- Faces: one pass over the slots (O(m)), storing each face's first slot and each slot's face, both
  `Int32`. The face count is known beforehand from Euler's formula (m − n′ + 2c over the vertices
  with an edge and their components), so the array is sized exactly, and the pass checks that it
  finds exactly that many.
- The result keeps 32-bit rows of edge numbers and neighbours, each slot's twin, each slot's face
  and each face's first slot: five integers per edge and one per vertex and face, about 36 bytes
  per edge on a triangulation.
- Outerplanarity: the left-right test on the graph plus an apex, in place: the apex is index n, and
  its row is generated rather than stored.

## Complexity

| Entry point | Time | Extra memory |
|---|---|---|
| `isPlanar` | O(n + m) (O(1) after the edge count when m > 3n − 6 on the simple graph) | O(n + m) |
| `planarEmbedding()` | O(n + m), faces included | O(n + m), kept in the result |
| `findKuratowskiSubgraph()` | O(n + m): deduplication, then Boyer–Myrvold on at most 3n − 5 pairs | O(n) after deduplication |
| `isOuterplanar` | O(n + m) | O(n + m) |
| `clockwise…(of:)`, `faces[i]` | O(1) to slice; O(face length) for a face | — |
| `face(from:alongEdgeAt:)`, `rightFace(from:alongEdgeAt:)` | O(degree) to find the half-edge, plus O(face length) for the walk | — |


