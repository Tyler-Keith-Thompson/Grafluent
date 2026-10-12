# Hypergraphs: proposed API (phase 1)

A hypergraph is a pair (V, E) where each hyperedge is a set of vertices of any size. A directed
hypergraph's hyperedge is an ordered pair of vertex sets, its sources (tail) and its targets
(head). The two are first-class siblings, as `Graph` and `DirectedGraph` are. This file fixes:

- the protocols `Hypergraph` and `DirectedHypergraph`, in `GraphProtocols`;
- the representations `UndirectedIncidenceList<Vertex>` and `IncidenceList<Vertex>`, in module
  `Hypergraphs`;
- a short list of phase-1 algorithms for each;
- how the graph algorithms reach a hypergraph: through its incidence graph, a lazy `Graph` or
  `BidirectionalDirectedGraph` view at the base's speed.

`IncidenceMatrix` and `OrientedIncidenceMatrix` are the protocols' second conformers. They are
designed in `Tests/Catalogs/IncidenceMatrix/api.md`.

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
- halp 1.0.0 `b_visit` / `f_visit`, which implement Gallo et al.'s B-Visit, and a fixpoint written
  from the paper's definition;
- the protocol laws, the hash law, reversal and dual as involutions, and a Codable round trip.

`--stress` runs 300 random hypergraphs of each kind and 200 mutation sequences of 30 steps of each
kind. The directed ones include empty sides, overlapping sides and repeats. Planted model bugs
caught:

- `s` read as "more than s" in the line graph;
- a vertex listed as its own neighbor;
- an index-space row read through a vertex lookup (the hash law failed);
- a B-visit that fires a hyperedge once any source is reached (halp and the fixpoint disagree);
- a directed clique expansion that keeps the self-loop of a vertex on both sides.

To run it:
`uv run --quiet --no-project --with networkx==3.7 --with xgi==0.10.2 --with hypernetx==2.4.3 --with halp==1.0.0 python3 Tests/Catalogs/Hypergraphs/ref.py [--write] [--stress] [--baseline]`.

## Names

| Name | Decision | Source |
|---|---|---|
| Undirected protocol | **`Hypergraph`**, in `GraphProtocols` | README protocol row; XGI `Hypergraph`, HyperNetX `Hypergraph`, SimpleHypergraphs.jl `Hypergraph` |
| Directed protocol | **`DirectedHypergraph`**, in `GraphProtocols` | halp `DirectedHypergraph`, SimpleDirectedHypergraphs.jl `DirectedHypergraph`; Gallo et al. (1993) "directed hypergraph"; the repo's `Graph` / `DirectedGraph` pair. XGI says `DiHypergraph` |
| Undirected representation | **`UndirectedIncidenceList<Vertex>`** | "Incidence list": one list per vertex and one per hyperedge of their incident pairs ("Conformal Hypergraphs: Duality and Implications for the Upper Clique Transversal Problem", arXiv:2309.00098). `Undirected` prefix as `UndirectedAdjacencyList` |
| Directed representation | **`IncidenceList<Vertex>`** | The same storage with a source plane and a target plane. Unprefixed, as `AdjacencyList` is the directed one |
| Hyperedges | **`hyperedges`**, a collection whose positions are the identities | XGI `H.edges`, HyperNetX `H.edges`, SimpleHypergraphs `nhe` / `gethyperedges` |
| Members (undirected) | **`members(ofHyperedgeAt:)`**, `memberIndices(ofHyperedgeAt:)` | XGI `edges.members(e)`; SimpleHypergraphs `getvertices` |
| The two sides (directed) | **`sources(ofHyperedgeAt:)`**, **`targets(ofHyperedgeAt:)`**, `sourceIndices(ofHyperedgeAt:)`, `targetIndices(ofHyperedgeAt:)` | XGI `edges.sources` / `edges.targets` (aliases of `tail` / `head`, verified in 0.10.2); `DirectedEdge.source` / `target`; README Terminology "arc, with tail and head". HyperGraphs.jl spells them `src` / `tgt`; halp and SimpleDirectedHypergraphs.jl `tail` / `head` |
| Hyperedges at a vertex (undirected) | **`incidentHyperedges(of:)`**, `incidentHyperedges(ofIndex:)` | `Graph.incidentEdges(of:)`; XGI `nodes.memberships` |
| Hyperedges at a vertex (directed) | **`outHyperedges(of:)`** (v is a source), **`inHyperedges(of:)`** (v is a target), and `(ofIndex:)` forms | `DirectedGraph.outEdges(of:)` / `inEdges(of:)`; XGI `out_degree` / `in_degree` and `dimemberships`; Gallo's forward star FS(v) and backward star BS(v) (halp `get_forward_star` / `get_backward_star`) |
| Degrees | **`degree(of:)`** (undirected); **`outDegree(of:)`**, **`inDegree(of:)`**, **`degree(of:)`** = in + out (directed) | XGI `degree`, `out_degree`, `in_degree`; `BidirectionalDirectedGraph.degree(of:)` |
| Number of members | **`size(ofHyperedgeAt:)`** (undirected only) | XGI `edges.size`, HyperNetX `size(edge)`, Berge's \|e\| |
| Counts | **`vertexCount`**, **`hyperedgeCount`** | README Terminology; XGI `num_nodes` / `num_edges` |
| Greatest size, k-uniform | **`rank`**, **`isUniform(size:)`** (undirected) | Berge, *Hypergraphs* (1989); XGI `is_uniform` |
| Vertices sharing a hyperedge | **`neighbors(of:)`** (undirected) | XGI `nodes.neighbors`, HyperNetX `neighbors` |
| Bipartite vertex–hyperedge graph | **`incidenceGraph`**, a property, of type **`IncidenceGraphView<Self>`** / **`DirectedIncidenceGraphView<Self>`** | Levi graph (Berge); XGI `to_bipartite_graph` (directed for a `DiHypergraph`), SimpleHypergraphs `BipartiteView`; the repo's `undirected: UndirectedView<Self>` |
| Pairwise graph | **`cliqueExpansion()`**: undirected, and directed from every source to every target | XGI `to_graph` ("clique expansion"); SimpleHypergraphs and SimpleDirectedHypergraphs.jl `TwoSectionView` (2-section) |
| Hyperedges joined by overlaps ≥ s | **`lineGraph(s:)`** (undirected) | XGI `to_line_graph(H, s)`, HyperNetX `get_linegraph`; Aksoy et al. (2020) |
| Transpose | **`dual()`** | XGI and HyperNetX `dual()`, SimpleDirectedHypergraphs.jl `dual` (the transpose of each plane), Berge H* |
| Sources and targets swapped | **`reversed`** (directed) | README Terminology (`reversed`); Gallo et al.'s "symmetric image"; halp `get_symmetric_image` |
| Components | **`connectedComponents()`**, **`isConnected`** (undirected); **`weaklyConnectedComponents()`**, **`isWeaklyConnected`**, **`stronglyConnectedComponents()`**, **`isStronglyConnected`** (directed) | `Connectivity`'s names; XGI `connected_components`; SimpleDirectedHypergraphs.jl `get_weakly_connected_components` |
| s-components | **`sConnectedComponents(s:)`** (undirected) | HyperNetX `s_connected_components`; Aksoy et al. (2020) |
| B- and F-connection | **`bConnectedVertices(from:)`**, **`isBConnected(from:to:)`**, **`fConnectedVertices(to:)`**, **`isFConnected(from:to:)`** | Gallo, Longo, Pallottino, Nguyen (1993) "B-connected", "F-connected", B-Visit, F-Visit; halp `b_visit`, `is_b_connected`, `f_visit`, `is_f_connected` |
| Hyperedge classes | **`isBHypergraph`**, **`isFHypergraph`**, **`isBFHypergraph`** | Gallo et al. "B-graph (or B-hypergraph)", "F-graph", "BF-graph"; halp `is_B_hypergraph`; SimpleDirectedHypergraphs.jl `is_b_hypergraph` |
| Histograms | **`degreeHistogram()`**, **`hyperedgeSizeHistogram()`**; **`outDegreeHistogram()`**, **`inDegreeHistogram()`**, **`sourceSizeHistogram()`**, **`targetSizeHistogram()`** | NetworkX / XGI `degree_histogram`; XGI `edges.size`, `tail_size`, `head_size` |
| Non-trapping | `incidentHyperedges(checked:)`, `degree(checked:)`, `outHyperedges(checked:)`, `inHyperedges(checked:)`, `outDegree(checked:)`, `inDegree(checked:)`, `vertexIndex(checked:)`, `insert(checked:)`, `insert(checked:targets:)`; each throws `VertexNotFound` | README Principle 6; the first label becomes `checked:` (Rust's `checked_*`) |

No `Hyperedge<Vertex>` value type (open question 3). No synonyms: no `nodes`, `edges`, `tail`,
`head`, `twoSection`, `symmetricImage`, `bipartiteGraph`, `memberships`, or `forwardStar`.

**Representation names.** The repo names representations after their storage and marks the
undirected one (`AdjacencyList` / `UndirectedAdjacencyList`). Neither XGI nor HyperNetX names its
storage: XGI keeps two dictionaries (`_node` and `_edge`, memberships and members) and HyperNetX
an `IncidenceStore`. "Incidence list" is the established term for exactly this layout (a list per
vertex and a list per hyperedge of the incidences). It is not in Berge's book, and
"incidence structure" (design theory: points, blocks, an incidence relation) names the
mathematical object rather than a storage, so it is not used. The one cost: `IncidenceList` is the
directed type while `IncidenceMatrix` is the undirected matrix, because "oriented incidence matrix"
is the established name of the other one (open question 1).

## The protocols (`GraphProtocols`)

**Two independent protocols, no shared parent.** `Graph` does not refine `DirectedGraph`, nor the
other way round (`Graph.swift`: "It does not refine…"). A shared parent would hold only vertices,
positions and indices; the incidence members differ (`incidentHyperedges` versus
`outHyperedges` / `inHyperedges`), so generic code over the parent could not reach a hyperedge's
vertices. Shared algorithm code goes in package-level index-space helpers, as `UndirectedRows.swift`
does for the graphs.

```swift
/// An undirected hypergraph: vertices, and hyperedges that are sets of vertices of any size,
/// the empty set included. Not a `Graph`: `incidenceGraph` reads it as one.
public protocol Hypergraph<Vertex> {
    associatedtype Vertex: Hashable
    associatedtype Vertices: Collection<Vertex>
    associatedtype Members: Collection<Vertex>
    associatedtype Hyperedges: Collection<Members> where Hyperedges.Index: Hashable
    associatedtype IncidentHyperedges: Sequence<Hyperedges.Index>
    associatedtype MemberIndices: Sequence<Int> = LazyMapSequence<Members, Int>
    associatedtype IncidentHyperedgeIndices: Sequence<Int> = LazyMapSequence<IncidentHyperedges, Int>

    var vertices: Vertices { get }
    var hyperedges: Hyperedges { get }                    // position = identity
    func incidentHyperedges(of vertex: Vertex) -> IncidentHyperedges

    // Requirements with defaults, so a representation's faster version is what generic code calls:
    func members(ofHyperedgeAt position: Hyperedges.Index) -> Members   // hyperedges[position]
    func size(ofHyperedgeAt position: Hyperedges.Index) -> Int
    func degree(of vertex: Vertex) -> Int
    var vertexCount: Int { get }; var hyperedgeCount: Int { get }
    func contains(_ vertex: Vertex) -> Bool                             // never traps
    func contains(hyperedge members: some Sequence<Vertex>) -> Bool     // exact member set; never traps
    var vertexIndexBound: Int? { get }                                  // default nil
    func vertexIndex(of vertex: Vertex) -> Int
    func vertex(atIndex index: Int) -> Vertex
    var hyperedgeIndexBound: Int? { get }                               // default nil
    func hyperedgeIndex(of position: Hyperedges.Index) -> Int
    func memberIndices(ofHyperedgeAt position: Hyperedges.Index) -> MemberIndices
    func incidentHyperedges(ofIndex index: Int) -> IncidentHyperedges
    func degree(ofIndex index: Int) -> Int

    func incidentHyperedgeIndices(ofIndex index: Int) -> IncidentHyperedgeIndices  // hyperedge indices

    // Underscored, as `_withIncidentIndexRows` is. `_forEachMemberIndex` runs `body` over
    // `memberIndices` (the matrix scans its words). `_withIncidenceRows` lends the incidences as
    // flat rows, numbered hyperedge by hyperedge in index order, members in `memberIndices` order,
    // with each vertex's incidence numbers and hyperedge indices: the default writes them out in
    // O(n + m + p) per call, the incidence list lends its storage. The incidence-graph view numbers
    // its edges this way and builds its rows from it once per whole-graph algorithm.
    func _forEachMemberIndex(ofHyperedgeAt position: Hyperedges.Index, _ body: (Int) -> Void)
    func _withIncidenceRows<Result>(_ body: (_ memberOffsets: UnsafeBufferPointer<Int>, _ members: UnsafeBufferPointer<Int>,
        _ incidences: UnsafeBufferPointer<Int>, _ incidenceRows: UnsafeBufferPointer<Int>,
        _ hyperedges: UnsafeBufferPointer<Int>, _ hyperedgeRows: UnsafeBufferPointer<Int>) -> Result) -> Result
}

/// A directed hypergraph: each hyperedge is a pair of vertex sets, its sources and its targets
/// (tail and head). Either side may be empty, and a vertex may be on both. Not a `DirectedGraph`:
/// `incidenceGraph` reads it as one.
public protocol DirectedHypergraph<Vertex> {
    associatedtype Vertex: Hashable
    associatedtype Vertices: Collection<Vertex>
    associatedtype Members: Collection<Vertex>            // one side of a hyperedge
    associatedtype Hyperedges: Collection where Hyperedges.Index: Hashable  // element: the representation's
    associatedtype IncidentHyperedges: Sequence<Hyperedges.Index>
    associatedtype MemberIndices: Sequence<Int> = LazyMapSequence<Members, Int>
    associatedtype IncidentHyperedgeIndices: Sequence<Int> = LazyMapSequence<IncidentHyperedges, Int>

    var vertices: Vertices { get }
    var hyperedges: Hyperedges { get }
    func outHyperedges(of vertex: Vertex) -> IncidentHyperedges        // v is a source: FS(v)
    func inHyperedges(of vertex: Vertex) -> IncidentHyperedges         // v is a target: BS(v)
    func sources(ofHyperedgeAt position: Hyperedges.Index) -> Members   // the tail
    func targets(ofHyperedgeAt position: Hyperedges.Index) -> Members   // the head

    // Requirements with defaults:
    func sourceSize(ofHyperedgeAt position: Hyperedges.Index) -> Int    // XGI tail_size
    func targetSize(ofHyperedgeAt position: Hyperedges.Index) -> Int    // XGI head_size
    func outDegree(of vertex: Vertex) -> Int
    func inDegree(of vertex: Vertex) -> Int
    func degree(of vertex: Vertex) -> Int                               // outDegree + inDegree
    var vertexCount: Int { get }; var hyperedgeCount: Int { get }
    func contains(_ vertex: Vertex) -> Bool
    func contains(sources: some Sequence<Vertex>, targets: some Sequence<Vertex>) -> Bool
    var vertexIndexBound: Int? { get }
    func vertexIndex(of vertex: Vertex) -> Int
    func vertex(atIndex index: Int) -> Vertex
    var hyperedgeIndexBound: Int? { get }
    func hyperedgeIndex(of position: Hyperedges.Index) -> Int
    func sourceIndices(ofHyperedgeAt position: Hyperedges.Index) -> MemberIndices
    func targetIndices(ofHyperedgeAt position: Hyperedges.Index) -> MemberIndices
    func outHyperedges(ofIndex index: Int) -> IncidentHyperedges
    func inHyperedges(ofIndex index: Int) -> IncidentHyperedges
    func outDegree(ofIndex index: Int) -> Int
    func inDegree(ofIndex index: Int) -> Int

    func outHyperedgeIndices(ofIndex index: Int) -> IncidentHyperedgeIndices
    func inHyperedgeIndices(ofIndex index: Int) -> IncidentHyperedgeIndices

    // `_forEachMemberIndex` runs over both sides, each vertex at least once (the oriented matrix
    // ORs its planes' words).
    func _forEachMemberIndex(ofHyperedgeAt position: Hyperedges.Index, _ body: (Int) -> Void)
}
```

**`Hyperedges.Element` is free.** An earlier draft required `Hyperedges.Element == (sources:
Members, targets: Members)`. That compiles on Swift 6.1 – 6.3, but associated-type inference
cannot see through a labeled tuple, so every third-party conformer had to write `typealias
Members`. Generic code now reads a hyperedge only through `sources(ofHyperedgeAt:)` and
`targets(ofHyperedgeAt:)`, which are plain requirements, and `Members` is inferred from them. The
library's `hyperedges` still yield `(sources:, targets:)` pairs (HypergraphConformanceTests'
`minimalDirectedConformer` has no typealias).

`DirectedHypergraph` asks for both stars, so there is no `Bidirectional` split as on the graph
side. Both phase-1 conformers store both, and B-Visit needs the forward star while F-Visit needs
the backward one.

**Laws.** Every conformer satisfies all of these (`ref.py`'s `check` and `check_d`):

- `vertexCount == vertices.count`, the vertices are distinct, `hyperedgeCount == hyperedges.count`.
- Members (each side, when directed) are distinct vertices, in vertex-index order for every
  phase-1 conformer.
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
- **The hash law.** Index-space members and whole-hypergraph algorithms hash no vertex. A
  vertex-space read hashes once (HG-022, HG-023, DH-011, DH-012).

**What a hyperedge may be.** Both kinds allow:

- **empty hyperedges** (HG-008, DH-006). Without them `dual()` is not total (HG-056, DH-024).
- **repeated hyperedges**, each at its own position (HG-007, DH-007). XGI, HyperNetX and halp keep
  them.
- a repeated member listed in the input, stored once (HG-006, DH-004).
- directed only: **an empty side** (DH-006), and **a vertex on both sides** (DH-005). XGI's
  `DiHypergraph` allows both. Gallo et al. define a hyperarc as "an ordered pair … of (possibly
  empty) disjoint subsets", so the overlap is a deliberate extension, the hypergraph form of a
  self-loop; HyperGraphs.jl's chemical hypergraphs allow it too (a catalyst).

## Storage

### `UndirectedIncidenceList<Vertex>`

```swift
@frozen
public struct UndirectedIncidenceList<Vertex: Hashable> {
    @usableFromInline var _vertices: OrderedSet<Vertex>        // element i is vertex index i
    @usableFromInline var _plane: _IncidencePlane              // hyperedges and their transpose
}

/// Package type: one plane of incidences. (Not `_IncidenceRows`, which `GraphProtocols` already
/// names for the graphs' stored rows.)
@usableFromInline package struct _IncidencePlane {
    var memberOffsets: ContiguousArray<Int>    // hyperedgeCount + 1
    var members: ContiguousArray<Int>          // p vertex indices; each row ascending
    var hyperedgeOfIncidence: ContiguousArray<Int>   // q -> hyperedge, parallel to members
    var incidences: _RowPool                   // row i: incidence numbers q, ascending
    var positions: _RowPool                    // row i: hyperedge positions, parallel to incidences
}
```

- **Incidence numbers.** p = Σ|e|. The q-th entry of `_members` is incidence q. Hyperedge `p` is
  `_members[_memberOffsets[p] ..< _memberOffsets[p + 1]]`, compressed sparse rows, so
  `memberIndices` is an `ArraySlice<Int>`. Vertex `i`'s row holds the incidence numbers of its
  memberships, and `incidentHyperedges(ofIndex:)` is the parallel `positions` row, an `ArraySlice<Int>`.
  (Mapping each incidence number through `hyperedgeOfIncidence` instead, as first designed, cost
  a dependent random load per entry and made traversals of the views 2–10× slower than an
  adjacency-list copy; the second row costs 8 bytes per incidence.) The incidence-graph view uses q as its edge position.
- **Rows.** `_RowPool` is `AdjacencyListModule`'s package type. Appending a hyperedge is amortized
  O(k), and the rows stay ascending because positions only increase.
- **Index assignment.** Listed vertices first, then new members by first appearance (HG-003,
  HG-004), `LabeledGraph`'s rule. Members are stored in vertex-index order (HG-005), at
  O(k log k) per hyperedge, O(k) when already ascending.

### `IncidenceList<Vertex>`

```swift
@frozen
public struct IncidenceList<Vertex: Hashable> {
    @usableFromInline var _vertices: OrderedSet<Vertex>
    @usableFromInline var _sources: _IncidencePlane   // hyperedge p's sources; vertex i's out-hyperedges
    @usableFromInline var _targets: _IncidencePlane   // hyperedge p's targets; vertex i's in-hyperedges
}
```

- **Two planes**, each an `UndirectedIncidenceList`'s storage, as SimpleDirectedHypergraphs.jl
  keeps `hg_tail` and `hg_head` and `OrientedIncidenceMatrix` keeps two bit planes. Source
  incidences are numbered 0..<P_s, target incidences 0..<P_t.
- **`reversed` is O(1)**: it swaps the two planes.
- **Index assignment.** Listed vertices, then each new hyperedge's sources, then its targets, by
  first appearance (DH-002).

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
        // appends; inserts missing members (XGI add_edge); returns the position. O(k log k) amortized
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
        // a type that is both reads as a hypergraph, so the call is not ambiguous
    @discardableResult public mutating func insert(_ vertex: Vertex) -> (inserted: Bool, memberAfterInsert: Vertex)
    @discardableResult public mutating func insert(sources: some Sequence<Vertex>, targets: some Sequence<Vertex>) -> Int
    @discardableResult public mutating func insert(checked sources: some Sequence<Vertex>, targets: some Sequence<Vertex>) throws(VertexNotFound) -> Int
    public mutating func removeAll(keepingCapacity: Bool = false)
    public mutating func reserveCapacity(vertexCount: Int, hyperedgeCount: Int, sourceCount: Int, targetCount: Int)
}
```

**Removal is phase 2** (open question 7): it needs a decision on positions (swap-remove versus
`StableGraphs`' holes), and the incidence rows must stay ascending.

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
| `contains(hyperedge:)`, `contains(sources:targets:)` | O(k) expected + O(d · k) | compares the rows at the first member's incidences |
| `vertexIndex(of:)`, `vertex(atIndex:)`, `vertexIndexBound`, `hyperedgeIndexBound` | O(1) expected, O(1), O(1), O(1) | both bounds always non-nil |
| `(checked:)` spellings | the trapping spelling's one hash | throw `VertexNotFound` for a non-vertex (HG-021, HG-023, DH-012, DH-057) |

**Traps:** a vertex-space read on a non-vertex (HG-025 – HG-027, DH-013, DH-016, DH-017); a
hyperedge position out of `0..<m` (HG-028, HG-029, DH-014); a vertex index out of `0..<n` (HG-030,
HG-031, DH-015).

### Algorithms on `Hypergraph` (module `Hypergraphs`)

| Member | Result | Cost | Rows |
|---|---|---|---|
| `neighbors(of:)` | `[Vertex]`: each once, in vertex-index order, never `v` itself | O(Σ_{e∋v} k) with a marker array | HG-009, HG-024 |
| `rank` | `Int`, 0 with no hyperedges | O(m) | HG-043 – HG-045 |
| `isUniform(size:)` | `Bool`; vacuously true with no hyperedges; singletons and empty hyperedges count | O(m) | HG-046 – HG-050 |
| `degreeHistogram()`, `hyperedgeSizeHistogram()` | `[Int]`: element d (k) counts the vertices of degree d (hyperedges of size k); `[]` when there are none (NetworkX's shape) | O(n), O(m) | HG-051 – HG-054 |
| `dual()` | `UndirectedIncidenceList<Hyperedges.Index>`: vertices are the positions in order; hyperedge `i` is vertex `i`'s incidence row. `dual().dual()` is the original relabeled to indices | O(n + m + p) expected (m hashes) | HG-055 – HG-058 |
| `incidenceGraph` | `IncidenceGraphView<Self>`, a lazy `Graph` (Views) | O(1) | HG-059 – HG-061 |
| `cliqueExpansion()` | `UndirectedAdjacencyList<Vertex>` with **every vertex, isolated ones too, in vertex-index order**; each pair sharing a hyperedge once, no self-loops, edges ascending by (index of u, index of v) | O(n + Σ k² + e log d). Building the result hashes each vertex once, n hashes whatever the edge count (none for the `Int`s `0..<n` in order), through a package bulk initializer of `UndirectedAdjacencyList`; through the public `init(vertices:edges:)` it would hash both ends of every edge, growing with the output | HG-062 – HG-064 |
| `lineGraph(s:)` | `UndirectedAdjacencyList<Hyperedges.Index>` with **every position `0..<m`** as a vertex, an empty or unmatched hyperedge isolated; p–q (p < q) when they share at least s members; edges ascending by (p, q) | O(m + Σ_v d(v)²) | HG-065 – HG-068 |
| `connectedComponents()`, `isConnected` | `[[Vertex]]` by least vertex index, each ascending; an isolated vertex alone; an empty hyperedge joins nothing. `isConnected` is **false for no vertices** (the repo's rule; XGI raises) | O(n + p α(n)) union–find | HG-069 – HG-073 |
| `sConnectedComponents(s:)` | `[[Hyperedges.Index]]`: the components of `lineGraph(s:)`, singletons included, by least position. The vertex form is `dual().sConnectedComponents(s:)` | O(m + Σ_v d(v)²) without building the graph | HG-074 – HG-077 |

**Traps:** `s < 1` (HG-032, HG-033); `size < 0` (HG-034).

### Algorithms on `DirectedHypergraph` (module `Hypergraphs`)

| Member | Result | Cost | Rows |
|---|---|---|---|
| `reversed` | On `IncidenceList` (and `OrientedIncidenceMatrix`): `Self` with every hyperedge's sources and targets swapped, Gallo's symmetric image. An involution | O(1): swaps the planes | DH-022 |
| `dual()` | `IncidenceList<Hyperedges.Index>`: vertices are the positions; hyperedge `i` has sources `outHyperedges(ofIndex: i)` and targets `inHyperedges(ofIndex: i)`, the transpose of each plane (SimpleDirectedHypergraphs.jl's convention, and `OrientedIncidenceMatrix.transposed()`) | O(n + m + p) expected | DH-023, DH-024 |
| `incidenceGraph` | `DirectedIncidenceGraphView<Self>`, a lazy `BidirectionalDirectedGraph` (Views) | O(1) | DH-025, DH-026 |
| `weaklyConnectedComponents()`, `isWeaklyConnected` | `[[Vertex]]`: vertices joined through any side of a hyperedge, by least vertex index, each ascending. False for no vertices | O(n + p α(n)) union–find | DH-027, DH-030 |
| `stronglyConnectedComponents()`, `isStronglyConnected` | `[[Vertex]]`: u and v together when each reaches the other along source → hyperedge → target steps (Gallo's "connected", a path in the incidence graph). The strong components of `incidenceGraph`, restricted to the vertices; same order. False for no vertices | O(n + m + p), Tarjan on the view's index rows | DH-028 – DH-030 |
| `bConnectedVertices(from: s)` | `[Vertex]`, ascending vertex index, `s` included: every vertex B-connected to `s`. Gallo's B-Visit: a hyperedge fires once **every** source has been reached, then reaches all its targets. A hyperedge with no sources is in no forward star and never fires | O(n + m + p): a counter per hyperedge | DH-031 – DH-034 |
| `isBConnected(from:to:)` | `Bool` | B-Visit, stopping at `to` | DH-032 |
| `fConnectedVertices(to: t)` | `[Vertex]`, ascending, `t` included: every `s` such that `t` is F-connected to `s`. Gallo: "the F-Visit must start from the destination of the F-paths to retain a linear time complexity"; it is B-Visit on the symmetric image, and `reversed.bConnectedVertices(from: t)` gives the same set | O(n + m + p) | DH-035, DH-037 |
| `isFConnected(from:to:)` | `Bool`: an F-path, whose symmetric image is a B-path from `to` to `from`. Every target of a hyperedge it uses must lead on to `to` (DH-036) | F-Visit from `to` | DH-036 |
| `isBHypergraph`, `isFHypergraph`, `isBFHypergraph` | `Bool`: every hyperedge has exactly one target (B-arc) / exactly one source (F-arc) / one or the other. Vacuously true with no hyperedges | O(m) | DH-038 – DH-040 |
| `cliqueExpansion()` | `AdjacencyList<Vertex>` with every vertex in index order; an arc u→v for each hyperedge with u a source and v a target, u ≠ v, each pair once, ascending by (index of u, index of v). SimpleDirectedHypergraphs.jl's `TwoSectionView` | O(n + Σ \|S\|·\|T\| + e log d); n vertex hashes building the result, as undirected | DH-041, DH-042 |
| `outDegreeHistogram()`, `inDegreeHistogram()`, `sourceSizeHistogram()`, `targetSizeHistogram()` | `[Int]`, NetworkX's shape; `[]` when there are no vertices (hyperedges) | O(n), O(m) | DH-043 – DH-045 |

**Definitions (verified against the paper).** G. Gallo, G. Longo, S. Pallottino, S. Nguyen,
"Directed hypergraphs and applications", *Discrete Applied Mathematics* 42(2–3):177–201, 1993,
doi:10.1016/0166-218X(93)90045-P. A B-path from s to t is a minimal sub-hypergraph containing s
and t in which every node is connected to s by a cycle-free simple path; an F-path from s to t is
one whose symmetric image is a B-path from t to s; "node y is B-connected (F-connected,
BF-connected) to node x if a B-path (F-path, BF-path) Π_xy exists". B-Visit runs in O(size(H)).

**BF-connectivity is not in phase 1.** The paper defines it (a hyperpath that is both a B-path and
an F-path) but gives no algorithm: "One can also define a BF-Visit. Unfortunately, the problem of
performing such a visit is not an easy one unless the hypergraph is either a B-graph or a F-graph;
in the former case a BF-path is simply a B-path, while in the latter it is a F-path." Phase 1 ships
the class predicates, so a caller can see when B- or F-connection already answers it (open
question 6).

Every algorithm runs in index space and maps to labels only for output. The generic versions need
both index bounds non-nil, which holds for all four phase-1 conformers.

### Views: how graph algorithms reach a hypergraph

The **incidence graph** is the one lossless graph reading of a hypergraph, and it is bipartite:
vertices on the left, hyperedges on the right.

```swift
@frozen public struct IncidenceGraphView<Base: Hypergraph>: Graph {
    public typealias Vertex = Int        // 0..<n are vertex indices; n + p is hyperedge p
    public var base: Base { get }
    // vertices: Range<Int> (0 ..< n + m)
    // edges: RandomAccessCollection of UndirectedEdge<Int> with Index == Int;
    //   position q = incidence number, edges[q] = (vertex index, n + hyperedge of q)
    // neighborIndices(ofIndex: i < n) = incidentHyperedgeIndices(ofIndex: i) shifted by n
    // neighborIndices(ofIndex: n + p) = memberIndices(ofHyperedgeAt: p)
    // incidentEdgeIndices: IncidentEdgeIndices, the member offsets range of a hyperedge; a
    //   vertex's stored incidence row (the list) or its computed one (other bases, O(Σ k))
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

- **`Edges.Index == Int`** in both views: the incidence numbers. A per-incidence weight array
  (SimpleHypergraphs' vertex-in-hyperedge weights) is indexed by edge position (HG-059, DH-025).
- **Numbering.** XGI's `to_bipartite_graph`: vertex indices first, hyperedges after; for a
  `DiHypergraph`, tail → edge → head. A vertex on both sides of `p` gives the 2-cycle i → n + p → i
  (DH-026). Our edge order lists all source incidences before all target incidences; XGI's
  `DiGraph` has no edge positions, so `ref.py` compares edge sets.
- **Positions are valid until the next mutation.** A view is a snapshot, so its own positions never
  change, but the view of a mutated hypergraph numbers the incidences afresh: on the matrices one
  cell edit shifts every later incidence. A per-incidence array is rebuilt after a mutation (README
  open question 9: maps attached through a view key by (vertex, hyperedge)).
- **The LabeledGraph law.** Every index member reads the base's rows, unboxed, so `Traversal`,
  `Connectivity`, `ShortestPaths` and the rest run on the views with no hashing. Each view keeps
  every hyperedge's first incidence number (a prefix sum of the sizes, O(m) at init, lent by the
  list), so a hyperedge's incidence numbers are a range and `edges[q]` a binary search plus a walk
  of one hyperedge. The undirected view's `_withIncidentIndexRows` writes its rows out for the
  call from the base's `_withIncidenceRows`, O(n + m + p) on every base, since the vertex side's
  rows lack the `+ n` shift: whole-graph algorithms (components, bridges) then run at an
  adjacency-list copy's speed, on the matrices too. The directed view offers no
  `_withSuccessorIndexRows`, whose contract needs edge positions in row order.
- **`BipartiteGraph`.** `BipartiteGraph(h.incidenceGraph, left: 0 ..< h.vertexCount)` builds one
  through the existing failable initializer. The undirected view is always simple.
- **Reachability.** Plain directed reachability ("connected" in Gallo et al.) is
  `h.incidenceGraph.descendants(of: i)` filtered to `0..<n`, so phase 1 adds no separate member.
- **The expansions and the line graph are materialized**, not views. A lazy `neighbors(of:)` would
  need a scratch set per call; they are lossy and quadratic (one hyperedge of 10⁴ members is
  5·10⁷ edges).

### Conformances

- **`Equatable`, `Hashable`.** Equal vertex sets and equal multisets of hyperedges (member sets,
  or (source set, target set) pairs), whatever the vertex order or hyperedge order (HG-078 –
  HG-085, DH-046 – DH-050). This is the README rule for representations. The hash combines the
  counts, the sum of the vertices' hashes, and the sum over the hyperedges of an order-free hash
  of their sides' members' hashes. The n vertex hashes are computed once and combined by index,
  so each vertex is hashed once.
- **`Sendable`** when `Vertex` is.
- **`Codable`.** Undirected as `{vertices, hyperedges: [[index]]}`, directed as `{vertices,
  sources: [[index]], targets: [[index]]}`, rows ascending (HG-089, DH-052). A round trip keeps the
  vertex order and the positions. Decoding re-checks, throwing `DecodingError.dataCorrupted`:
  - a repeated vertex (HG-091);
  - a member index outside `0..<vertices.count` (HG-092, DH-056);
  - a row that is not strictly ascending, which covers a repeated member inside one hyperedge or
    one side (HG-093, HG-094, DH-055): the encoder never writes one, so the decoder does not
    repair it;
  - directed: `sources` and `targets` of different lengths (DH-054).
- **`CustomStringConvertible`**, as `GraphDescription.graph`: at most 16 vertices and 16
  hyperedges, then `…` (HG-088), each vertex `String(reflecting:)`:
  - undirected: `["a", "b", "c"]; [{"a", "b"}, {}, {"b", "c"}]` (HG-086);
  - directed: `["a", "b", "c"]; [{"a", "b"}→{"c"}, {}→{}]` (DH-051).
- **`CustomDebugStringConvertible`**: the type, the counts, then the same lists:
  `UndirectedIncidenceList<String>(vertexCount: 3, hyperedgeCount: 3, vertices: [...], hyperedges:
  [...])` (HG-086, HG-087), `IncidenceList<String>(…)` (DH-051).

### Divergences from the references (each asserted in `ref.py`)

| Where | Ours | Theirs |
|---|---|---|
| `isUniform(size:)` | counts every hyperedge; vacuously true with none | XGI `is_uniform` ignores singletons; `False` with no edges |
| `isConnected`, `isWeaklyConnected`, `isStronglyConnected` on no vertices | `false` | XGI raises |
| empty hyperedges | kept, each its own s-component | HyperNetX drops them silently |
| `sConnectedComponents(s:)` | singletons always | HyperNetX `s_connected_components` drops them by default |
| directed `degree(of:)` | in + out: a vertex on both sides counts the hyperedge twice | XGI `nodes.degree` counts it once |
| a vertex on both sides | allowed | Gallo et al. require disjoint sides |
| `stronglyConnectedComponents()` | mutual reachability along source → target steps | SimpleDirectedHypergraphs.jl's `get_strongly_connected_components` uses mutual B-connection (Martín-Recuerda 2016); that is phase 2 |
| XGI `nodes.neighbors` on a `DiHypergraph` | n/a | raises `IDNotFound` in 0.10.2, so no directed `neighbors` is checked or offered |

## Performance

The workload: n = 10⁵ vertices, m = 2·10⁵ hyperedges of sizes 2–8 (p ≈ 10⁶), `Int` vertices; the
directed form splits each hyperedge in half, sources then targets. `ref.py --baseline` times the
references. Previous run on the development machine (Python 3.12):

- XGI 0.10.2: build **1.23 s**; `connected_components` **1.55 s** (4 components);
  `to_line_graph(s=2)` **9.72 s** (562 edges).
- HyperNetX 2.4.3: build **18.9 s**; `s_components(s=1, edges=False)` **279 s**.
- The directed baselines (XGI `DiHypergraph` build, `to_bipartite_graph` plus NetworkX strong
  components, halp `b_visit`) are printed by the same run.

| Measure | Target |
|---|---|
| Build from nested arrays | ≤ 1.6× `CompressedSparseRow(edges:)` on p edges (retargeted from 1.3×, see below). At least 50× XGI's build |
| `memberIndices`, `sourceIndices`, `incidentHyperedges(ofIndex:)`, `outHyperedges(ofIndex:)` | an `ArraySlice` and a lazy map over one: no allocation, no hashing |
| BFS and components on `incidenceGraph` (both views) | ≤ 1.10× the same call on an adjacency-list copy of the view |
| `connectedComponents()`, `weaklyConnectedComponents()` | ≤ 1.2× a bare union–find over the rows. At least 100× XGI |
| `stronglyConnectedComponents()` | ≤ 1.2× `Connectivity`'s on a `CompressedSparseRow` copy of the view |
| `bConnectedVertices(from:)` | one counter array of m `Int`s and one queue; O(n + m + p); at least 50× halp's `b_visit` |
| `lineGraph(s: 2)` | O(Σ d²) with one counter array, no hashing. At least 20× XGI |
| `reversed` | O(1) |
| Matrix conformers (`IncidenceMatrix`, `OrientedIncidenceMatrix`) | the algorithms allocate nothing per vertex or per hyperedge: allocation counts equal an incidence-list copy's (`IncidenceMatrixBenchmarks`, `mallocCountTotal`) |
| Vertex hashes in any index-space algorithm | 0, checked with a hash-counting `Vertex` in the benchmark target |

**Why the build target is 1.6×, not 1.3×.** The baseline, `CompressedSparseRow(vertexCount:edges:)`,
counting-sorts p edges into rows and stops. The incidence list does that and more that the
baseline never does: it sorts each hyperedge's members and drops repeats, and it builds the
`OrderedSet` of vertices. The review's probe composed the fastest measured version of each step
(a single-buffer insertion sort that drops repeats as it inserts, the plane's hyperedge-of-incidence
pass fused into the scatter over uninitialized storage, `OrderedSet(uncheckedUniqueElements:)`
for the vertices `0..<n`) at 16 ms against the baseline's 10 ms: 1.6× is that floor. All three are
in; measured 19 against 11 ms (1.7×) at load average 70, and 2.2× before them.

## Prior art (verified 2026-10-11)

| Library or paper | What it does | Taken |
|---|---|---|
| XGI 0.10.2 `Hypergraph` | `nodes`, `edges`, `members`, `memberships`, `degree`, `size`, `dual()`, `to_bipartite_graph`, `to_graph`, `to_line_graph(H, s)`, `connected_components`, `is_uniform`, `incidence_matrix`. Multi-edges and empty edges kept | Vocabulary, numbering, the views |
| XGI 0.10.2 `DiHypergraph` | `add_edge((tail, head))`; `edges.tail` / `edges.head` with aliases `edges.sources` / `edges.targets`, `edges.dimembers`, `tail_size`, `head_size`; `nodes.in_degree` (head memberships), `nodes.out_degree` (tail memberships), `nodes.degree` (union), `dimemberships`. Allows a node in both tail and head, and empty sides. `to_bipartite_graph` gives a `DiGraph` tail → edge → head. `incidence_matrix`, `to_graph`, `to_line_graph` and `nodes.neighbors` fail on it (`KeyError: 'in'` / `IDNotFound`) | `sources` / `targets`, the overlap rule, the directed incidence graph |
| HyperNetX 2.4.3 | `s_components`, `get_linegraph`, `dual()`, `IncidenceStore`. **Drops empty edges.** No directed hypergraphs | s-connectivity |
| halp 1.0.0 (Murali lab) | `DirectedHypergraph` with `get_hyperedge_tail` / `head`, `get_forward_star` / `get_backward_star`, `get_symmetric_image`, `is_B_hypergraph`, `is_F_hypergraph`, `is_BF_hypergraph`; `visit`, `b_visit`, `f_visit` (B-visit on the symmetric image), `is_b_connected`, `is_f_connected`, `shortest_b_tree`. No BF-visit. Refuses a hyperedge with both sides empty | The reference for B- and F-connection |
| SimpleDirectedHypergraphs.jl (CoReACTER) | `DirectedHypergraph` as two `Hypergraph`s, `hg_tail` and `hg_head`; `dual` (transpose of both), `TwoSectionView`, `BipartiteView`, `get_weakly_connected_components`, `get_strongly_connected_components` (mutual B-connection), `forward_reachable` (B-visit), `backward_traceable`, `is_b_hypergraph`, `is_f_hypergraph`, `is_bf_hypergraph` | The two-plane storage; the dual's convention |
| HyperGraphs.jl (Diaz & Stumpf 2022) | `ChemicalHyperEdge` with `src` / `tgt`; oriented incidence matrix `I[v, e] -= s` per source, `+= s` per target | A vertex on both sides; the matrix encoding |
| SimpleHypergraphs.jl | `Hypergraph{T}` as an `AbstractMatrix`; `dual`, `TwoSectionView`, `BipartiteView` | Views rather than copies |
| Gallo, Longo, Pallottino, Nguyen (1993) | Directed hypergraphs, hyperarcs (T(E), H(E)), FS / BS, B-arcs and F-arcs, B-, F- and BF-graphs, symmetric image, incidence matrix (−1 tail, +1 head), paths, B-, F- and BF-paths, B-Visit and F-Visit in O(size), super-connection, cuts, shortest hyperpaths | The definitions and the visits |
| Berge (1989), Bretto (2013) | Rank, k-uniform, dual, incidence graph, 2-section | Undirected mathematical names |
| Aksoy, Joslyn, Marrero, Praggastis, Purvine (2020) | s-walks, s-line graphs, s-connected components | `lineGraph(s:)`, `sConnectedComponents(s:)` |
| JGraphT, Boost, petgraph | No hypergraph type | — |

## Open questions (with recommendations)

1. **`IncidenceList` is directed while `IncidenceMatrix` is undirected.** The list pair follows
   `AdjacencyList` / `UndirectedAdjacencyList`; the matrix pair follows the established
   "oriented incidence matrix". *Recommendation:* accept the asymmetry, which the literature
   forces, and say so in both doc comments. The alternative, `IncidenceList` (undirected) and
   `DirectedIncidenceList`, follows `Pseudograph` / `DirectedPseudograph` instead, but those are
   structures, not representations.
2. **`size(ofHyperedgeAt:)`.** The README avoids `size`. *Recommendation:* keep it for the
   undirected protocol only ("of a hyperedge", XGI, HyperNetX, Berge) and add a Terminology row.
   The directed protocol has no `size`: XGI's `edges.size` there is \|tail ∪ head\|, which hides
   the sides. It has `sourceSize(ofHyperedgeAt:)` and `targetSize(ofHyperedgeAt:)` instead (XGI's
   `tail_size` / `head_size`), O(1) from the stored rows or the matrices' cached sizes, where
   `sources(ofHyperedgeAt:).count` copies a `BitSet` on a matrix.
3. **`Hyperedge<Vertex>`.** *Decided:* no stored or returned hyperedge value in phase 1;
   `hyperedges[p]` is a view over the stored rows (or a labeled tuple of two). The protocol leaves
   `Hyperedges.Element` free (see "`Hyperedges.Element` is free" above), so no
   `DirectedHyperedge<Members>` struct is needed.
4. **`insert(checked:targets:)`.** The repo's rule makes the first label `checked:`. It reads a
   little oddly here. *Recommendation:* keep the rule rather than invent
   `insert(checkedSources:targets:)`.
5. **`sConnectedComponents(s:)`.** *Recommendation:* hyperedges by default (HyperNetX
   `edges=True`); the vertex form is `dual().sConnectedComponents(s:)`.
6. **BF-connection, B-strong components, hyperpaths.** *Recommendation:* phase 2, in this order:
   - `bStronglyConnectedComponents()`, mutual B-connection (Martín-Recuerda 2016, as
     SimpleDirectedHypergraphs.jl), n B-visits;
   - shortest B-hypertrees (Gallo's SBT procedure, halp `shortest_b_tree`) with additive weights;
   - super-connection (Gallo's SuperVisit);
   - BF-connection only on B- or F-graphs, where the paper says it reduces to B or F.
7. **Removal.** *Recommendation:* phase 2, swap-remove (as `UndirectedAdjacencyList`) or stable
   positions (a `StableIncidenceList` after `StableDirectedGraph`); XGI and HyperNetX keep names
   stable, which argues for stable positions if only one is built.
8. **Missing against the prior art, all phase 2** (recorded after the phase-1 review):
   - removal of vertices and hyperedges (question 7);
   - restriction: the sub-hypergraph on a vertex subset or a hyperedge subset (XGI `subhypergraph`,
     `restrict_to_nodes` / `restrict_to_edges`; HyperNetX `restrict_to_nodes` / `restrict_to_edges`);
   - duplicate-hyperedge detection (XGI `edges.duplicates()`, HyperNetX `collapse_edges`);
   - B-Visit with predecessors, and shortest B-hyperpaths (halp `b_visit` returns `Pv`/`Pe`;
     Gallo's SBT procedure, halp `shortest_b_tree`);
   - s-distance and s-paths (Aksoy et al. 2020; HyperNetX `s_distance`, `s_diameter`).
9. **Other phase-2 algorithms:** s-walks and s-distances; weighted clique expansion and hypergraph
   Laplacians (with `SpectralGraphTheory`, including the directed ones); toplexes and simple
   reduction; induced subhypergraphs; random hypergraphs (XGI's uniform Erdős–Rényi, configuration
   model, SimpleDirectedHypergraphs.jl's random models); directed line graphs; HIF in `GraphFormats`
   (HIF has a directed form).
10. **Components result type.** `Connectivity`'s `Components<G>` is tied to a graph.
   *Recommendation:* `[[Vertex]]` in phase 1, a shared partition type in the final reuse pass.
   `h.incidenceGraph.stronglyConnectedComponents()` already gives `Components` today, hyperedge
   vertices included.
11. **Dependencies.** `Hypergraphs` depends on `GraphProtocols`, `AdjacencyListModule` (`_RowPool`,
    and the adjacency lists the expansions return), `DisjointSetModule` and `OrderedCollections`.
    Both protocols live in `GraphProtocols`, so `IncidenceMatrixModule` does not depend on
    `Hypergraphs`; the algorithms, written once on the protocols, reach the matrices when both are
    imported.
