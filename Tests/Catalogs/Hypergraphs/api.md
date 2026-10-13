# Hypergraphs: API

A hypergraph is a pair (V, E) where each hyperedge is a set of vertices of any size. A directed
hypergraph's hyperedge is an ordered pair of vertex sets, its sources (tail) and its targets
(head). The two are separate protocols, as `Graph` and `DirectedGraph` are. This file covers:

- the protocols `Hypergraph` and `DirectedHypergraph`, in `GraphProtocols`;
- the representations `UndirectedIncidenceList<Vertex>` and `IncidenceList<Vertex>`, in module
  `Hypergraphs`;
- the algorithms written once on each protocol;
- how the graph algorithms reach a hypergraph: through its incidence graph, a lazy `Graph` or
  `BidirectionalDirectedGraph` view.

`IncidenceMatrix` and `OrientedIncidenceMatrix` are the protocols' other conformers. They are
described in `Tests/Catalogs/IncidenceMatrix/api.md`.

`cases.md` (151 rows: HG-001 – HG-094 undirected, DH-001 – DH-057 directed) pins the values.
`ref.py` ports both storages and counts every vertex lookup. Each undirected state is checked
against:

- XGI 0.10.2 `Hypergraph`, built edge by edge so empty and repeated hyperedges survive;
- HyperNetX 2.4.3, which drops empty hyperedges (mapped back);
- NetworkX 3.7 on the incidence graph;
- the protocol laws, the hash law and a Codable round trip.

Each directed state is checked against:

- XGI 0.10.2 `DiHypergraph`: `edges.tail` / `edges.head` and their aliases `edges.sources` /
  `edges.targets`, `nodes.out_degree`, `nodes.in_degree`, `nodes.dimemberships`, and the directed
  `to_bipartite_graph`;
- NetworkX 3.7 on that bipartite digraph: weak and strong components, and the two-step paths that
  make the clique expansion;
- halp 1.0.0 `b_visit` / `f_visit`, and a fixpoint written from Gallo et al.'s definition;
- the protocol laws, the hash law, reversal and dual as involutions, and a Codable round trip.

`--stress` runs 300 random hypergraphs of each kind and 200 mutation sequences of 30 steps of each
kind. The directed ones include empty sides, overlapping sides and repeats.

To run it:
`uv run --quiet --no-project --with networkx==3.7 --with xgi==0.10.2 --with hypernetx==2.4.3 --with halp==1.0.0 python3 Tests/Catalogs/Hypergraphs/ref.py [--write] [--stress] [--baseline]`.

## Names

| Concept | Name |
|---|---|
| Undirected protocol | `Hypergraph`, in `GraphProtocols` |
| Directed protocol | `DirectedHypergraph`, in `GraphProtocols` |
| Undirected representation | `UndirectedIncidenceList<Vertex>`: a list per vertex and one per hyperedge of their incidences |
| Directed representation | `IncidenceList<Vertex>`: the same storage with a source plane and a target plane |
| Hyperedges | `hyperedges`, a collection whose positions are the identities |
| Members (undirected) | `members(ofHyperedgeAt:)`, `memberIndices(ofHyperedgeAt:)` |
| The two sides (directed) | `sources(ofHyperedgeAt:)`, `targets(ofHyperedgeAt:)`, `sourceIndices(ofHyperedgeAt:)`, `targetIndices(ofHyperedgeAt:)` |
| Hyperedges at a vertex (undirected) | `incidentHyperedges(of:)`, `incidentHyperedges(ofIndex:)` |
| Hyperedges at a vertex (directed) | `outHyperedges(of:)` (v is a source: the forward star FS(v)), `inHyperedges(of:)` (v is a target: the backward star BS(v)), and `(ofIndex:)` forms |
| Degrees | `degree(of:)` (undirected); `outDegree(of:)`, `inDegree(of:)`, `degree(of:)` = in + out (directed) |
| Number of members | `size(ofHyperedgeAt:)` (undirected); `sourceSize(ofHyperedgeAt:)`, `targetSize(ofHyperedgeAt:)` (directed) |
| Counts | `vertexCount`, `hyperedgeCount` |
| Greatest size, k-uniform | `rank`, `isUniform(size:)` (undirected; Berge) |
| Vertices sharing a hyperedge | `neighbors(of:)` (undirected) |
| Bipartite vertex–hyperedge graph | `incidenceGraphView`, of type `IncidenceGraphView<Self>` / `DirectedIncidenceGraphView<Self>` (Berge's incidence graph, the Levi graph) |
| Pairwise graph | `cliqueExpansion()`: undirected, and directed from every source to every target (the 2-section) |
| Hyperedges joined by overlaps ≥ s | `lineGraph(s:)` (undirected; Aksoy et al. 2020) |
| Transpose | `dual()` (Berge's H*) |
| Sources and targets swapped | `reversed` (directed; Gallo et al.'s symmetric image) |
| Components | `connectedComponents()`, `isConnected` (undirected); `weaklyConnectedComponents()`, `isWeaklyConnected`, `stronglyConnectedComponents()`, `isStronglyConnected` (directed) |
| s-components | `sConnectedComponents(s:)` (undirected; Aksoy et al. 2020) |
| B- and F-connection | `bConnectedVertices(from:)`, `isBConnected(from:to:)`, `fConnectedVertices(to:)`, `isFConnected(from:to:)` (Gallo et al. 1993) |
| Hyperedge classes | `isBHypergraph`, `isFHypergraph`, `isBFHypergraph` (Gallo et al.'s B-, F- and BF-graphs) |
| Histograms | `degreeHistogram()`, `hyperedgeSizeHistogram()`; `outDegreeHistogram()`, `inDegreeHistogram()`, `sourceSizeHistogram()`, `targetSizeHistogram()` |
| Non-trapping | `incidentHyperedges(checked:)`, `degree(checked:)`, `outHyperedges(checked:)`, `inHyperedges(checked:)`, `outDegree(checked:)`, `inDegree(checked:)`, `vertexIndex(checked:)`, `insert(checked:)`, `insert(checked:targets:)`; each throws `VertexNotFound` |

There is no `Hyperedge<Vertex>` value type: `hyperedges[p]` is a view over the stored rows (a
labeled pair of two, directed).

## The protocols (`GraphProtocols`)

`Hypergraph` and `DirectedHypergraph` have no shared parent, and neither refines `Graph` or
`DirectedGraph`; `incidenceGraphView` reads a hypergraph as a graph. `Hypergraph.swift` and
`DirectedHypergraph.swift` list the requirements. Each protocol has vertex-space members
(`incidentHyperedges(of:)`, `outHyperedges(of:)`, …), index-space members (`vertexIndex(of:)`,
`memberIndices(ofHyperedgeAt:)`, the `(ofIndex:)` reads, both index bounds), and underscored
members that conformers may implement faster:

- `_forEachMemberIndex(ofHyperedgeAt:_:)` runs over `memberIndices` (directed: both sides, each
  vertex at least once);
- `_memberRank` and `_memberIndex(atRank:…)` locate a member within a hyperedge;
- `_withIncidenceRows` (undirected) lends the incidences as flat rows, numbered hyperedge by
  hyperedge in index order and members in `memberIndices` order, with each vertex's incidence
  numbers and hyperedge indices. The default writes them out in O(n + m + p) per call; the
  incidence list lends its storage.

`DirectedHypergraph.Hyperedges.Element` is unconstrained: generic code reads a hyperedge through
`sources(ofHyperedgeAt:)` and `targets(ofHyperedgeAt:)`, and `Members` is inferred from them.
`IncidenceList.hyperedges` yields `(sources:, targets:)` pairs. `DirectedHypergraph` requires both
stars: B-Visit reads the forward star and F-Visit the backward one.

**Laws.** Every conformer satisfies all of these (`ref.py`'s `check` and `check_d`):

- `vertexCount == vertices.count`, the vertices are distinct, `hyperedgeCount == hyperedges.count`.
- Members (each side, when directed) are distinct vertices, in vertex-index order on every
  conformer in the library.
- `p` is in `incidentHyperedges(of: v)` exactly when `v` is a member of `p`; directed, `p` is in
  `outHyperedges(of: v)` exactly when `v` is a source of `p`, and in `inHyperedges(of: v)` exactly
  when `v` is a target. Each list has `p` once, in `hyperedges` order.
- Degrees are those lists' lengths, so Σ degree = Σ size; directed, Σ outDegree = Σ |sources| and
  Σ inDegree = Σ |targets|. Checked on every state.
- `contains(hyperedge:)` / `contains(sources:targets:)` is true exactly when some hyperedge has
  those sets. The empty set (or the empty pair) is contained exactly when such a hyperedge is.
- The index laws of `Graph`, with `hyperedgeIndexBound` playing `edgeIndexBound`: `vertices` in
  index order; `memberIndices` (`sourceIndices`, `targetIndices`) is the members mapped through
  `vertexIndex(of:)`; the `(ofIndex:)` reads equal the vertex reads; with hyperedge indices,
  `hyperedges` is in index order.
- The hash law: index-space members and whole-hypergraph algorithms hash no vertex. A vertex-space
  read hashes once (HG-022, HG-023, DH-011, DH-012).

**What a hyperedge may be.** Both kinds allow:

- empty hyperedges (HG-008, DH-006), which keep `dual()` total (HG-056, DH-024);
- repeated hyperedges, each at its own position (HG-007, DH-007);
- a repeated member listed in the input, stored once (HG-006, DH-004);
- directed only: an empty side (DH-006), and a vertex on both sides (DH-005), the hypergraph form
  of a self-loop.

## Storage

### `UndirectedIncidenceList<Vertex>`

```swift
@frozen
public struct UndirectedIncidenceList<Vertex: Hashable> {
    @usableFromInline var _vertices: OrderedSet<Vertex>        // element i is vertex index i
    @usableFromInline var _plane: _IncidencePlane              // hyperedges and their transpose
    // plus the attached maps and the generation
}

@usableFromInline package struct _IncidencePlane {
    var memberOffsets: ContiguousArray<Int>    // hyperedgeCount + 1
    var members: ContiguousArray<Int>          // p vertex indices; each row ascending
    var hyperedgeOfIncidence: ContiguousArray<Int>   // q -> hyperedge, parallel to members
    var incidences: _RowPool                   // row i: incidence numbers q, ascending
    var positions: _RowPool                    // row i: hyperedge positions, parallel to incidences
}
```

- **Incidence numbers.** p = Σ|e|. The q-th entry of `members` is incidence q. Hyperedge `p` is
  `members[memberOffsets[p] ..< memberOffsets[p + 1]]`, compressed sparse rows, so
  `memberIndices` is an `ArraySlice<Int>`. Vertex `i`'s row holds the incidence numbers of its
  memberships, and `incidentHyperedges(ofIndex:)` is the parallel `positions` row, an
  `ArraySlice<Int>`. The incidence-graph view uses q as its edge position.
- **Rows.** `_RowPool` is `AdjacencyListModule`'s package type. Appending a hyperedge is amortized
  O(k), and the rows stay ascending because positions only increase.
- **Index assignment.** Listed vertices first, then new members by first appearance (HG-003,
  HG-004). Members are stored in vertex-index order (HG-005), at O(k log k) per hyperedge, O(k)
  when already ascending.

### `IncidenceList<Vertex>`

```swift
@frozen
public struct IncidenceList<Vertex: Hashable> {
    @usableFromInline var _vertices: OrderedSet<Vertex>
    @usableFromInline var _sources: _IncidencePlane   // hyperedge p's sources; vertex i's out-hyperedges
    @usableFromInline var _targets: _IncidencePlane   // hyperedge p's targets; vertex i's in-hyperedges
    // plus the attached maps and the generation
}
```

- **Two planes**, each an `UndirectedIncidenceList`'s storage. Source incidences are numbered
  0..<P_s, target incidences 0..<P_t.
- **`reversed` is O(1)**: it swaps the two planes.
- **Index assignment.** Listed vertices, then each new hyperedge's sources, then its targets, by
  first appearance (DH-002).

Hyperedges can be appended but not removed.

## API

n = `vertexCount`, m = `hyperedgeCount`, p = Σ|e| (incidences; directed, P_s + P_t), d = degree,
k = size. "Expected" means hashing.

### Construction and mutation

```swift
extension UndirectedIncidenceList {
    public init()
    public init(vertices: some Sequence<Vertex>)
    public init(hyperedges: some Sequence<some Sequence<Vertex>>)
    public init(vertices: some Sequence<Vertex>, hyperedges: some Sequence<some Sequence<Vertex>>)  // O(n + p log k) expected
    public init(_ hypergraph: some Hypergraph<Vertex>)            // vertices and hyperedges in order
    @discardableResult public mutating func insert(_ vertex: Vertex) -> (inserted: Bool, memberAfterInsert: Vertex)
    @discardableResult public mutating func insert(hyperedge members: some Sequence<Vertex>) -> Int
        // appends; inserts missing members; returns the position. O(k log k) amortized
    @discardableResult public mutating func insert(checked members: some Sequence<Vertex>) throws(VertexNotFound) -> Int
        // throws, changing nothing, unless every member is already a vertex (HG-040)
    public mutating func removeAll(keepingCapacity: Bool = false)
    public mutating func reserveCapacity(vertexCount: Int, hyperedgeCount: Int, incidenceCount: Int)
}

extension IncidenceList {
    public init()
    public init(vertices: some Sequence<Vertex>)
    public init<S: Sequence, T: Sequence>(hyperedges: some Sequence<(sources: S, targets: T)>)
        where S.Element == Vertex, T.Element == Vertex
    public init<S: Sequence, T: Sequence>(vertices: some Sequence<Vertex>, hyperedges: some Sequence<(sources: S, targets: T)>)
        where S.Element == Vertex, T.Element == Vertex
    public init(_ hypergraph: some DirectedHypergraph<Vertex>)
    public init(_ graph: some DirectedGraph<Vertex>)      // each edge as ({source}, {target}), in edges order
    public init<H: DirectedHypergraph & DirectedGraph>(_ hypergraph: H) where H.Vertex == Vertex
        // a type that is both reads as a hypergraph
    @discardableResult public mutating func insert(_ vertex: Vertex) -> (inserted: Bool, memberAfterInsert: Vertex)
    @discardableResult public mutating func insert(sources: some Sequence<Vertex>, targets: some Sequence<Vertex>) -> Int
    @discardableResult public mutating func insert(checked sources: some Sequence<Vertex>, targets: some Sequence<Vertex>) throws(VertexNotFound) -> Int
    public mutating func removeAll(keepingCapacity: Bool = false)
    public mutating func reserveCapacity(vertexCount: Int, hyperedgeCount: Int, sourceCount: Int, targetCount: Int)
}
```

### Reads

| Member | Cost | Notes |
|---|---|---|
| `vertices` | O(1) | `OrderedSet<Vertex>` |
| `hyperedges` | O(1) | `RandomAccessCollection`, `Index == Int`; `Element` is `Members`, or `(sources: Members, targets: Members)` |
| `members` / `sources` / `targets(ofHyperedgeAt:)` | O(1) | `Members`: a `RandomAccessCollection<Vertex>` over the row slice and the labels; no hashing |
| `memberIndices` / `sourceIndices` / `targetIndices(ofHyperedgeAt:)` | O(1) | `ArraySlice<Int>` |
| `size(ofHyperedgeAt:)` | O(1) | the offset difference |
| `incidentHyperedges`, `outHyperedges`, `inHyperedges(of:)` | O(1) expected | one hash, then the row; ascending positions |
| the same `(ofIndex:)` | O(1) | no hashing |
| `degree`, `outDegree`, `inDegree` | O(1) expected / O(1) by index | the row lengths; directed `degree` is their sum, so a vertex on both sides of a hyperedge counts it twice (DH-009) |
| `contains(_:)` | O(1) expected | |
| `contains(hyperedge:)`, `contains(sources:targets:)` | O(k log k) expected + O(d · k) | compares the rows at one listed vertex's hyperedges |
| `vertexIndex(of:)`, `vertex(atIndex:)`, `vertexIndexBound`, `hyperedgeIndexBound` | O(1) expected, O(1), O(1), O(1) | both bounds always non-nil |
| `(checked:)` spellings | the trapping spelling's one hash | throw `VertexNotFound` for a non-vertex (HG-021, HG-023, DH-012, DH-057) |

**Traps:** a vertex-space read on a non-vertex (HG-025 – HG-027, DH-013, DH-016, DH-017); a
hyperedge position out of `0..<m` (HG-028, HG-029, DH-014); a vertex index out of `0..<n` (HG-030,
HG-031, DH-015).

### Algorithms on `Hypergraph` (module `Hypergraphs`)

| Member | Result | Cost | Rows |
|---|---|---|---|
| `neighbors(of:)` | `[Vertex]`: each once, in vertex-index order, never `v` itself | O(K log K), K = Σ k over the hyperedges at `v` | HG-009, HG-024 |
| `rank` | `Int`, 0 with no hyperedges | O(m) | HG-043 – HG-045 |
| `isUniform(size:)` | `Bool`; vacuously true with no hyperedges; singletons and empty hyperedges count | O(m) | HG-046 – HG-050 |
| `degreeHistogram()`, `hyperedgeSizeHistogram()` | `[Int]`: element d (k) counts the vertices of degree d (hyperedges of size k); `[]` when there are none | O(n), O(m) | HG-051 – HG-054 |
| `dual()` | `UndirectedIncidenceList<Hyperedges.Index>`: vertices are the positions in order; hyperedge `i` is vertex `i`'s incidence row. `dual().dual()` is the original relabeled to indices | O(n + m + p) expected (m hashes) | HG-055 – HG-058 |
| `incidenceGraphView` | `IncidenceGraphView<Self>`, a lazy `Graph` (Views) | O(1) on the list | HG-059 – HG-061 |
| `cliqueExpansion()` | `UndirectedAdjacencyList<Vertex>` with every vertex, isolated ones too, in vertex-index order; each pair sharing a hyperedge once, no self-loops, edges ascending by (index of u, index of v) | O(n + Σ k² + e log d). Building the result hashes each vertex once, whatever the edge count (none for the `Int`s `0..<n` in order) | HG-062 – HG-064 |
| `lineGraph(s:)` | `UndirectedAdjacencyList<Hyperedges.Index>` with every position `0..<m` as a vertex, an empty or unmatched hyperedge isolated; p–q (p < q) when they share at least s members; edges ascending by (p, q) | O(m + Σ_v d(v)² + e log e) | HG-065 – HG-068 |
| `connectedComponents()`, `isConnected` | `[[Vertex]]` by least vertex index, each ascending; an isolated vertex alone; an empty hyperedge joins nothing. `isConnected` is false for no vertices | O(n + p α(n)) union–find | HG-069 – HG-073 |
| `sConnectedComponents(s:)` | `[[Hyperedges.Index]]`: the components of `lineGraph(s:)`, singletons included, by least position. The vertex form is `dual().sConnectedComponents(s:)` | O(m + Σ_v d(v)²) without building the graph | HG-074 – HG-077 |

**Traps:** `s < 1` (HG-032, HG-033); `size < 0` (HG-034).

### Algorithms on `DirectedHypergraph` (module `Hypergraphs`)

| Member | Result | Cost | Rows |
|---|---|---|---|
| `reversed` | On `IncidenceList` (and `OrientedIncidenceMatrix`): `Self` with every hyperedge's sources and targets swapped, Gallo et al.'s symmetric image. An involution | O(1): swaps the planes | DH-022 |
| `dual()` | `IncidenceList<Hyperedges.Index>`: vertices are the positions; hyperedge `i` has sources `outHyperedges(ofIndex: i)` and targets `inHyperedges(ofIndex: i)`, the transpose of each plane | O(n + m + p) expected | DH-023, DH-024 |
| `incidenceGraphView` | `DirectedIncidenceGraphView<Self>`, a lazy `BidirectionalDirectedGraph` (Views) | O(1) on the list | DH-025, DH-026 |
| `weaklyConnectedComponents()`, `isWeaklyConnected` | `[[Vertex]]`: vertices joined through any side of a hyperedge, by least vertex index, each ascending. False for no vertices | O(n + p α(n)) union–find | DH-027, DH-030 |
| `stronglyConnectedComponents()`, `isStronglyConnected` | `[[Vertex]]`: u and v together when each reaches the other along source → hyperedge → target steps (Gallo et al.'s "connected", a path in the incidence graph). The strong components of `incidenceGraphView`, restricted to the vertices; same order. False for no vertices | O(n + m + p), Tarjan on the view's index rows | DH-028 – DH-030 |
| `bConnectedVertices(from: s)` | `[Vertex]`, ascending vertex index, `s` included: every vertex B-connected to `s`. B-Visit: a hyperedge fires once every source has been reached, then reaches all its targets. A hyperedge with no sources is in no forward star and never fires | O(n + m + p): a counter per hyperedge | DH-031 – DH-034 |
| `isBConnected(from:to:)` | `Bool` | B-Visit, stopping at `to` | DH-032 |
| `fConnectedVertices(to: t)` | `[Vertex]`, ascending, `t` included: every `s` such that `t` is F-connected to `s`. F-Visit, started at the destination: B-Visit on the symmetric image, so `reversed.bConnectedVertices(from: t)` gives the same set | O(n + m + p) | DH-035, DH-037 |
| `isFConnected(from:to:)` | `Bool`: an F-path, whose symmetric image is a B-path from `to` to `from`. Every target of a hyperedge it uses must lead on to `to` (DH-036) | F-Visit from `to` | DH-036 |
| `isBHypergraph`, `isFHypergraph`, `isBFHypergraph` | `Bool`: every hyperedge has exactly one target (B-arc) / exactly one source (F-arc) / one or the other. Vacuously true with no hyperedges | O(m) | DH-038 – DH-040 |
| `cliqueExpansion()` | `AdjacencyList<Vertex>` with every vertex in index order; an arc u→v for each hyperedge with u a source and v a target, u ≠ v, each pair once, ascending by (index of u, index of v) | O(n + Σ \|S\|·\|T\| + e log d); n vertex hashes building the result, as undirected | DH-041, DH-042 |
| `outDegreeHistogram()`, `inDegreeHistogram()`, `sourceSizeHistogram()`, `targetSizeHistogram()` | `[Int]`; `[]` when there are no vertices (hyperedges) | O(n), O(m) | DH-043 – DH-045 |

**Definitions.** G. Gallo, G. Longo, S. Pallottino, S. Nguyen, "Directed hypergraphs and
applications", *Discrete Applied Mathematics* 42(2–3):177–201, 1993. A B-path from s to t is a
minimal sub-hypergraph containing s and t in which every node is connected to s by a cycle-free
simple path; an F-path from s to t is one whose symmetric image is a B-path from t to s; "node y
is B-connected (F-connected) to node x if a B-path (F-path) Π_xy exists". B-Visit runs in
O(size(H)). Plain directed reachability ("connected") is
`h.incidenceGraphView.descendants(of: i)` filtered to `0..<n`.

Every algorithm runs in index space and maps to labels only for output. The generic versions need
both index bounds non-nil, which holds for every conformer in the library.

### Views: how graph algorithms reach a hypergraph

The incidence graph is the lossless graph reading of a hypergraph, and it is bipartite: vertices
on the left, hyperedges on the right.

```swift
@frozen public struct IncidenceGraphView<Base: Hypergraph>: Graph {
    public typealias Vertex = Int        // 0..<n are vertex indices; n + p is hyperedge p
    public var base: Base { get }
    // vertices: Range<Int> (0 ..< n + m)
    // edges: RandomAccessCollection of UndirectedEdge<Int> with Index == Int;
    //   position q = incidence number, edges[q] = (vertex index, n + hyperedge of q)
    // neighborIndices(ofIndex: i < n) = incidentHyperedgeIndices(ofIndex: i) shifted by n
    // neighborIndices(ofIndex: n + p) = memberIndices(ofHyperedgeAt: p)
    // incidentEdgeIndices: the member offsets range of a hyperedge; a vertex's stored incidence
    //   row (the list) or its computed one (other bases)
    // edgeIndexBound = p; endpointIndices(ofEdgeAt: q) without hashing
}

@frozen public struct DirectedIncidenceGraphView<Base: DirectedHypergraph>: BidirectionalDirectedGraph {
    public typealias Vertex = Int        // 0..<n are vertex indices; n + p is hyperedge p
    public var base: Base { get }
    // vertices: Range<Int> (0 ..< n + m)
    // edges: RandomAccessCollection of DirectedEdge<Int> with Index == Int;
    //   0..<P_s: source incidence q is (vertex index → n + p);
    //   P_s + q: target incidence q is (n + p → vertex index)
    // successorIndices(ofIndex: i < n) = outHyperedgeIndices(ofIndex: i) + n; of n + p = targetIndices(p)
    // predecessorIndices(ofIndex: i < n) = inHyperedgeIndices(ofIndex: i) + n; of n + p = sourceIndices(p)
    // outEdges / inEdges: OutEdges (InEdges is the same type)
}
```

- **`Edges.Index == Int`** in both views: the incidence numbers. A per-incidence array (a weight
  of a vertex in a hyperedge) is indexed by edge position (HG-059, DH-025).
- **Numbering.** Vertex indices first, hyperedges after; directed, source → hyperedge → target. A
  vertex on both sides of `p` gives the 2-cycle i → n + p → i (DH-026). The directed view lists
  all source incidences before all target incidences. `ref.py` compares edge sets with XGI's
  `to_bipartite_graph`, which has no edge positions.
- **Positions are valid until the next mutation.** A view is a snapshot, so its own positions never
  change, but the view of a mutated hypergraph numbers the incidences afresh: on the matrices one
  cell edit shifts every later incidence. A per-incidence array is rebuilt after a mutation.
- **Index members.** Every index member reads the base's rows, unboxed, so `Traversal`,
  `Connectivity`, `ShortestPaths` and the rest run on the views with no hashing. Each view keeps
  every hyperedge's first incidence number (a prefix sum of the sizes, O(m) at init, lent by the
  list), so a hyperedge's incidence numbers are a range and `edges[q]` a binary search plus a walk
  of one hyperedge. The undirected view's `_withIncidentIndexRows` writes its rows out for the
  call from the base's `_withIncidenceRows`, O(n + m + p) on every base. The directed view offers
  no `_withSuccessorIndexRows`, whose contract needs edge positions in row order.
- **`BipartiteGraph`.** `BipartiteGraph(h.incidenceGraphView, left: 0 ..< h.vertexCount)` builds one
  through the failable initializer. The undirected view is always simple.
- **The expansions and the line graph are materialized**, not views. They are lossy and quadratic
  (one hyperedge of 10⁴ members is 5·10⁷ edges).

### Conformances

- **`Equatable`, `Hashable`.** Equal vertex sets and equal multisets of hyperedges (member sets,
  or (source set, target set) pairs), whatever the vertex order or hyperedge order (HG-078 –
  HG-085, DH-046 – DH-050). The hash combines the counts, the sum of the vertices' hashes, and the
  sum over the hyperedges of an order-free hash of their sides' members' hashes. Each vertex is
  hashed once.
- **`Sendable`** when `Vertex` is.
- **`Codable`.** Undirected as `{vertices, hyperedges: [[index]]}`, directed as `{vertices,
  sources: [[index]], targets: [[index]]}`, rows ascending (HG-089, DH-052). A round trip keeps the
  vertex order and the positions. Decoding re-checks, throwing `DecodingError.dataCorrupted`:
  - a repeated vertex (HG-091);
  - a member index outside `0..<vertices.count` (HG-092, DH-056);
  - a row that is not strictly ascending, which covers a repeated member inside one hyperedge or
    one side (HG-093, HG-094, DH-055);
  - directed: `sources` and `targets` of different lengths (DH-054).
- **`CustomStringConvertible`**, as `GraphDescription.graph`: at most 16 vertices and 16
  hyperedges, then `…` (HG-088), each vertex `String(reflecting:)`:
  - undirected: `["a", "b", "c"]; [{"a", "b"}, {}, {"b", "c"}]` (HG-086);
  - directed: `["a", "b", "c"]; [{"a", "b"}→{"c"}, {}→{}]` (DH-051).
- **`CustomDebugStringConvertible`**: the type, the counts, then the same lists:
  `UndirectedIncidenceList<String>(vertexCount: 3, hyperedgeCount: 3, vertices: [...], hyperedges:
  [...])` (HG-086, HG-087), `IncidenceList<String>(…)` (DH-051).
- **`PropertyGraph`** (GraphProtocols). Maps attached to the hypergraph: `addVertexMap(default:)`,
  `addEdgeMap(default:)`, and `addEdgeMap(of:)` / `addVertexMap(of:)` for a map of `T?` whose
  default is `nil`. A vertex map is read by vertex index (`[map, ofVertexAt: i]`) or by vertex
  (`[map, of: v]`, one hash), an edge map by hyperedge position (`[map, ofEdgeAt: p]`), and
  `values(of:)` is a snapshot read like an array. Both are dense: every insertion appends the
  default (the vertices a hyperedge's insertion adds included), and `removeAll` empties the maps
  and keeps them attached. Outside the elements the plain subscripts trap, and
  `[map, checkedEdgeAt:]`, `[map, checkedVertexAt:]` and `[map, checked:]` throw `EdgeNotFound` /
  `VertexNotFound`. `IncidenceList.reversed` keeps every position, so it carries the maps.
  Equality, hashing, `Codable` and the descriptions ignore the maps. The catalog does not cover
  them; `HypergraphMapTests` and `HypergraphMapPropertyTests` do.
- **`generation`.** Every insertion of a vertex or a hyperedge, and `removeAll`, starts a new
  generation; inserting a vertex already present, a checked insertion that throws, reserving
  capacity and map writes do not. Built and decoded hypergraphs have one; `init()` and `reversed`
  have none until their first mutation.

### Where `ref.py` maps the references' results

| Where | Library | Reference, as `ref.py` adjusts for it |
|---|---|---|
| `isUniform(size:)` | counts every hyperedge; vacuously true with none | XGI `is_uniform` ignores singletons and is `False` with no edges |
| `isConnected`, `isWeaklyConnected`, `isStronglyConnected` on no vertices | `false` | XGI raises |
| empty hyperedges | kept, each its own s-component | HyperNetX drops them; `ref.py` maps them back |
| `sConnectedComponents(s:)` | singletons always | HyperNetX `s_connected_components` drops them by default |
| directed `degree(of:)` | in + out: a vertex on both sides counts the hyperedge twice | XGI `nodes.degree` counts it once |
| a hyperedge with both sides empty | allowed; never fires in either visit | halp refuses it, so `ref.py` leaves it out of halp's copy |

## Benchmark workload

n = 10⁵ vertices, m = 2·10⁵ hyperedges of sizes 2–8 (p ≈ 10⁶), `Int` vertices; the directed form
splits each hyperedge in half, sources then targets. `ref.py --baseline` runs it on the reference
libraries.

## Dependencies

`Hypergraphs` depends on `GraphProtocols`, `AdjacencyListModule` (`_RowPool`, and the adjacency
lists the expansions return), `DisjointSetModule`, `Connectivity` and `OrderedCollections`. Both
protocols live in `GraphProtocols`, so `IncidenceMatrixModule` does not depend on `Hypergraphs`;
the algorithms, written once on the protocols, reach the matrices when both are imported.
