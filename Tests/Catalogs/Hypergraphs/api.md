# Hypergraphs: proposed API (phase 1)

A hypergraph is a pair (V, E) where each hyperedge is a set of vertices of any size. The README
plans a `Hypergraph` protocol (`hyperedges`, `incidentHyperedges(of:)`) kept apart from
`DirectedGraph` and `Graph`, because a hyperedge is not an edge, and a `Hypergraph<Vertex>`
structure. This file fixes:

- the protocol;
- the representation `Hypergraph<Vertex>`;
- a short list of phase-1 algorithms;
- how the graph algorithms reach a hypergraph: through the incidence graph, a `Graph` view at the
  base's speed.

`IncidenceMatrix` is the protocol's second conformer. It is designed in
`Tests/Catalogs/IncidenceMatrix/api.md`.

`cases.md` (HG-001 – HG-085, 85 rows) pins the values. `ref.py` ports the storage and counts every
vertex lookup. Each state is checked against:

- XGI 0.10.2, built edge by edge so empty and repeated hyperedges survive;
- HyperNetX 2.4.3, which drops empty hyperedges (mapped back);
- NetworkX 3.7 on the incidence graph;
- the protocol laws and the hash law.

`--stress` runs 300 random hypergraphs (with empty and repeated hyperedges) and 200 mutation
sequences of 30 steps, checked against XGI. Three planted model bugs were caught:

- `s` read as "more than s" in the line graph;
- a vertex listed as its own neighbor;
- an index-space row read through a vertex lookup (the hash law failed).

To run it:
`uv run --quiet --no-project --with networkx==3.7 --with xgi==0.10.2 --with hypernetx==2.4.3 python3 Tests/Catalogs/Hypergraphs/ref.py [--write] [--stress] [--baseline]`.

## Names

| Name | Decision | Source |
|---|---|---|
| Protocol | **`HypergraphProtocol`**, in `GraphProtocols` (see open question 1: `Hypergraph` cannot name both the protocol and the structure) | Swift's `StringProtocol` / `String` |
| Structure | **`Hypergraph<Vertex>`**, module `Hypergraphs` | XGI `xgi.Hypergraph`, HyperNetX `hnx.Hypergraph`, SimpleHypergraphs.jl `Hypergraph`, the WolframInstitute `Hypergraph` paclet |
| The hyperedges | **`hyperedges`**, a collection whose positions are the identities | README protocol row; XGI `H.edges`, HyperNetX `H.edges`, SimpleHypergraphs `nhe` / `gethyperedges` |
| Members of a hyperedge | **`members(ofHyperedgeAt:)`**, `memberIndices(ofHyperedgeAt:)` | XGI `H.edges.members(e)`; HyperNetX `incidence_dict`; SimpleHypergraphs `getvertices` |
| Hyperedges at a vertex | **`incidentHyperedges(of:)`**, `incidentHyperedges(ofIndex:)` | README protocol row; `Graph.incidentEdges(of:)`; XGI `nodes.memberships(n)`; SimpleHypergraphs `gethyperedges` |
| Number of hyperedges at a vertex | **`degree(of:)`** | XGI `nodes.degree`, HyperNetX `degree`, Berge |
| Number of members | **`size(ofHyperedgeAt:)`** (open question 2) | XGI `edges.size`, HyperNetX `size(edge)`, Berge's \|e\| |
| Counts | **`vertexCount`**, **`hyperedgeCount`** | README Terminology (`vertexCount`, `edgeCount`); XGI `num_nodes` / `num_edges` |
| Greatest size | **`rank`** | Berge, *Hypergraphs* (1989): r(H) = max \|e\|; HyperNetX's `dim` is rank − 1 |
| Every hyperedge of size k | **`isUniform(size:)`** | "k-uniform" (Berge); XGI `is_uniform` |
| Vertices sharing a hyperedge | **`neighbors(of:)`** | XGI `nodes.neighbors`, HyperNetX `neighbors(node, s=1)` |
| Bipartite vertex–hyperedge graph | **`incidenceGraph`** | Levi graph / incidence graph (Berge, Bretto); XGI `to_bipartite_graph`, HyperNetX `bipartite()`, SimpleHypergraphs `BipartiteView` |
| Pairwise graph on the vertices | **`cliqueExpansion()`** | XGI `to_graph` ("clique expansion"), SimpleHypergraphs `TwoSectionView` (2-section); Zhou–Huang–Schölkopf |
| Hyperedges as vertices, joined by overlaps ≥ s | **`lineGraph(s:)`** | XGI `to_line_graph(H, s)`, HyperNetX `get_linegraph(s, edges=True)`; Aksoy et al. (2020), "s-line graph"; README's `lineGraph` for graphs |
| Transpose | **`dual()`** | XGI `dual()`, HyperNetX `dual()`, SimpleHypergraphs `dual`, Berge H* |
| Components | **`connectedComponents()`**, **`isConnected`** | XGI `connected_components`, `is_connected`; Connectivity's names for `Graph` |
| Hyperedge components under s-overlap | **`sConnectedComponents(s:)`** (open question 5) | HyperNetX `s_connected_components` / `s_components`; Aksoy et al. (2020) |
| Histograms | **`degreeHistogram()`**, **`hyperedgeSizeHistogram()`** | NetworkX / XGI `degree_histogram`; XGI `edges.size`, HyperNetX `edge_size_dist` |
| Non-trapping | **`incidentHyperedges(safe:)`**, `degree(safe:)`, `vertexIndex(safe:)`, `insert(safe:)` | README Principle 6 |

No `Hyperedge<Vertex>` value type in phase 1 (open question 3). No synonyms: no `nodes`, `edges`,
`order`, `twoSection`, `bipartiteGraph`, or `memberships`.

## The protocol (`GraphProtocols`)

```swift
/// A hypergraph: vertices, and hyperedges that are sets of vertices of any size. Not a
/// `DirectedGraph` or a `Graph`, which share member names (`edges`, `degree(of:)`) with
/// different meanings. `incidenceGraph` reads it as a `Graph`.
public protocol HypergraphProtocol<Vertex> {
    associatedtype Vertex: Hashable
    associatedtype Vertices: Collection<Vertex>
    associatedtype Members: Collection<Vertex>
    associatedtype Hyperedges: Collection<Members> where Hyperedges.Index: Hashable
    associatedtype IncidentHyperedges: Sequence<Hyperedges.Index>
    associatedtype MemberIndices: Sequence<Int> = LazyMapSequence<Members, Int>

    var vertices: Vertices { get }
    var hyperedges: Hyperedges { get }                    // position = identity
    func incidentHyperedges(of vertex: Vertex) -> IncidentHyperedges

    // Requirements with defaults, so a representation's faster version is what generic code calls:
    func members(ofHyperedgeAt position: Hyperedges.Index) -> Members   // hyperedges[position]
    func size(ofHyperedgeAt position: Hyperedges.Index) -> Int          // members(...).count
    func degree(of vertex: Vertex) -> Int                               // count of incidentHyperedges
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
}
```

**Laws.** Every conformer satisfies all of these (`ref.py`'s `check`):

- `vertexCount == vertices.count`, the vertices are distinct, and `hyperedgeCount ==
  hyperedges.count`.
- A hyperedge's members are distinct vertices. Order is the representation's: vertex-index order
  for both conformers.
- `p` is in `incidentHyperedges(of: v)` exactly when `v` is in `members(ofHyperedgeAt: p)`. It
  appears once, and the list is in `hyperedges` order.
- `degree(of: v)` is that list's length, so Σ degree = Σ size (the handshake law, checked on every state).
- `contains(hyperedge:)` is true exactly when some hyperedge has that member set. The empty set
  is contained exactly when an empty hyperedge is.
- The index laws of `Graph`, with `hyperedgeIndexBound` playing `edgeIndexBound`:
  - `vertices` is in index order;
  - `memberIndices` is `members` mapped through `vertexIndex(of:)`;
  - `incidentHyperedges(ofIndex: vertexIndex(of: v))` is `incidentHyperedges(of: v)`;
  - with hyperedge indices, `hyperedges` is in index order.
- **The hash law.** Index-space members and whole-hypergraph reads hash no vertex. A
  vertex-space read hashes once (HG-022, HG-023).

**Multi-hyperedges are allowed and empty hyperedges are allowed** (open question 4).

- A repeated member set is a second hyperedge at its own position (HG-007). XGI and HyperNetX
  both keep repeats.
- A repeated member inside one hyperedge is stored once (HG-006).
- Directed hypergraphs are phase 2 (open question 6).

## `Hypergraph<Vertex>`: storage

```swift
@frozen
public struct Hypergraph<Vertex: Hashable> {
    @usableFromInline var _vertices: OrderedSet<Vertex>        // element i is vertex index i
    @usableFromInline var _memberOffsets: ContiguousArray<Int> // hyperedgeCount + 1
    @usableFromInline var _members: ContiguousArray<Int>       // p vertex indices; each row ascending
    @usableFromInline var _hyperedgeOfIncidence: ContiguousArray<Int>   // q -> p, parallel to _members
    @usableFromInline var _incidences: _RowPool                // row i: incidence numbers q, ascending
}
```

- **Incidence numbers.** p = Σ|e|. The q-th entry of `_members` is incidence q.
  - Hyperedge `p` is `_members[_memberOffsets[p] ..< _memberOffsets[p + 1]]`: compressed sparse
    rows, so `memberIndices` is an `ArraySlice<Int>`.
  - Vertex `i`'s row holds the incidence numbers of its memberships, and
    `incidentHyperedges(ofIndex:)` maps them through `_hyperedgeOfIncidence`: a load each, no
    hashing.
  - The incidence graph view uses q as its edge position directly, so both sides of that view are
    stored rows (see Views).
- **Rows.** `_RowPool` is `AdjacencyListModule`'s package type, the same one `AdjacencyList` uses.
  Rows grow in place or move at doubling, so appending a hyperedge is amortized O(k) and the rows
  stay ascending, because positions only increase.
- **Index assignment.** Listed vertices come first, then new members by first appearance (HG-003,
  HG-004). This is `LabeledGraph`'s rule.
- **Members** are stored in vertex-index order, not input order (HG-005). Sorting a k-member input
  costs O(k log k), or O(k) when it is already ascending.

## API

n = `vertexCount`, m = `hyperedgeCount`, p = Σ|e| (incidences), d = degree, k = size.
"Expected" means hashing.

### Construction and mutation

```swift
extension Hypergraph {
    public init()
    public init(vertices: some Sequence<Vertex>)
    public init(hyperedges: some Sequence<some Sequence<Vertex>>)
    public init(vertices: some Sequence<Vertex>, hyperedges: some Sequence<some Sequence<Vertex>>)
                                                             // O(n + p log k) expected
    public init(_ hypergraph: some HypergraphProtocol<Vertex>)   // vertices and hyperedges in order
    @discardableResult public mutating func insert(_ vertex: Vertex) -> (inserted: Bool, memberAfterInsert: Vertex)
    @discardableResult public mutating func insert(hyperedge members: some Sequence<Vertex>) -> Int
        // appends; inserts missing members (XGI add_edge); returns the position. O(k log k) amortized
    @discardableResult public mutating func insert(safe members: some Sequence<Vertex>) -> Int?
        // nil and no change unless every member is already a vertex (HG-040)
    public mutating func removeAll(keepingCapacity: Bool = false)
    public mutating func reserveCapacity(vertexCount: Int, hyperedgeCount: Int, incidenceCount: Int)
}
```

**Removal is phase 2** (open question 7). It needs a decision on positions (swap-remove versus
`StableGraphs`' holes), and the incidence rows must stay ascending.

### Reads

| Member | Cost | Notes |
|---|---|---|
| `vertices` | O(1) | `OrderedSet<Vertex>` |
| `hyperedges` | O(1) | `RandomAccessCollection`, `Index == Int`, `Element == Members` |
| `members(ofHyperedgeAt:)` | O(1) | `Members`: a `RandomAccessCollection<Vertex>` over the row slice and the labels; no hashing |
| `memberIndices(ofHyperedgeAt:)` | O(1) | `ArraySlice<Int>` |
| `size(ofHyperedgeAt:)` | O(1) | the offset difference |
| `incidentHyperedges(of:)` | O(1) expected | one hash, then the row; ascending positions |
| `incidentHyperedges(ofIndex:)` | O(1) | no hashing |
| `degree(of:)` / `degree(ofIndex:)` | O(1) expected / O(1) | the row's length |
| `contains(_:)` | O(1) expected | |
| `contains(hyperedge:)` | O(k) expected + O(d · k) | hashes the k members, then compares the rows at the first member's incidences |
| `vertexIndex(of:)`, `vertex(atIndex:)`, `vertexIndexBound`, `hyperedgeIndexBound` | O(1) expected, O(1), O(1), O(1) | both bounds always non-nil |
| `incidentHyperedges(safe:)`, `degree(safe:)`, `vertexIndex(safe:)` | the trapping spelling's one hash | `nil` for a non-vertex (HG-023) |

**Traps:**

- a vertex-space read on a non-vertex (HG-025 – HG-027);
- a hyperedge position out of `0..<m` (HG-028, HG-029);
- a vertex index out of `0..<n` (HG-030, HG-031).

### Algorithms (module `Hypergraphs`, on `HypergraphProtocol`)

| Member | Result | Cost | Rows |
|---|---|---|---|
| `neighbors(of:)` | `[Vertex]`: each once, in vertex-index order, never `v` itself | O(Σ_{e∋v} k) with a marker array | HG-009, HG-024 |
| `rank` | `Int`, 0 with no hyperedges | O(m) | HG-043 – HG-045 |
| `isUniform(size:)` | `Bool`. Vacuously true with no hyperedges; singletons and empty hyperedges count | O(m) | HG-046 – HG-050 |
| `degreeHistogram()` | `[Int]`: element d is the number of vertices of degree d; `[]` for no vertices (NetworkX's shape) | O(n) | HG-051, HG-053, HG-054 |
| `hyperedgeSizeHistogram()` | `[Int]`: element k is the number of hyperedges of size k; `[]` for no hyperedges | O(m) | HG-052 – HG-054 |
| `dual()` | `Hypergraph<Hyperedges.Index>`. Its vertices are the positions in order, and its hyperedge `i` is vertex `i`'s incidence row. An isolated vertex becomes an empty hyperedge, and an empty hyperedge an isolated vertex, so `dual().dual()` is the original relabeled to indices | O(n + m + p) expected (m hashes) | HG-055 – HG-058 |
| `incidenceGraph` | `IncidenceGraph<Self>`, a lazy `Graph<Int>` view (below) | O(1) | HG-059 – HG-061 |
| `cliqueExpansion()` | `UndirectedAdjacencyList<Vertex>`, simple: each pair sharing a hyperedge once, no self-loops. Edges ascend by (index of u, index of v) | O(n + Σ k²) | HG-062 – HG-064 |
| `lineGraph(s:)` | `UndirectedAdjacencyList<Hyperedges.Index>` on the positions. p–q (p < q) when the two share at least s members; edges ascend by (p, q) | O(m + Σ_v d(v)²), counting overlaps in an m-sized array per row | HG-065 – HG-068 |
| `connectedComponents()` | `[[Vertex]]`: vertices joined through hyperedges. Ordered by least vertex index, each ascending; an isolated vertex alone; an empty hyperedge joins nothing | O(n + p α(n)) union–find | HG-069 – HG-073 |
| `isConnected` | `Bool`: one component; **false for no vertices** (the repo's rule; XGI raises IndexError) | stops after n − 1 joins | HG-069 – HG-073 |
| `sConnectedComponents(s:)` | `[[Hyperedges.Index]]`: the components of `lineGraph(s:)`, singletons included, ordered by least position. The vertex form is `dual().sConnectedComponents(s:)` (HyperNetX `edges=False`) | O(m + Σ_v d(v)²) without building the graph | HG-074 – HG-077 |

Every algorithm runs in index space: it hashes no vertex inside its loops, and it maps to labels
only for output.

**Traps:**

- `s < 1` in `lineGraph(s:)` and `sConnectedComponents(s:)` (HG-032, HG-033);
- `size < 0` in `isUniform(size:)` (HG-034).

The generic versions need `vertexIndexBound` and `hyperedgeIndexBound` to be non-nil, which holds
for both phase-1 conformers. A conformer without them is phase 2.

### Views: how graph algorithms reach a hypergraph

The **incidence graph** is the one exact, lossless `Graph` reading of a hypergraph, and it is
bipartite (vertices on the left, hyperedges on the right).

```swift
@frozen public struct IncidenceGraph<Base: HypergraphProtocol>: Graph {
    public typealias Vertex = Int        // 0..<n are vertex indices; n + p is hyperedge p
    public var base: Base { get }
    // vertices: Range<Int> (0 ..< n + m); edges: RandomAccessCollection of UndirectedEdge<Int>,
    // position q = incidence number, edges[q] = (vertex index, n + hyperedge of q)
    // neighborIndices(ofIndex: i < n) = incidentHyperedges(ofIndex: i) shifted by n
    // neighborIndices(ofIndex: n + p) = memberIndices(ofHyperedgeAt: p)
    // incidentEdgeIndices: the stored incidence rows / the member offsets range
    // edgeIndexBound = p; endpointIndices(ofEdgeAt: q) without hashing
}
```

- **Numbering.** It is XGI's `to_bipartite_graph`: vertex indices first, hyperedges after. Its
  edge positions are the incidence numbers, so a per-incidence weight array (SimpleHypergraphs'
  vertex-in-hyperedge weights) is indexed by edge position (HG-059).
- **The LabeledGraph law.** Every index member reads the base's stored rows, so `Traversal`,
  `Connectivity`, `ShortestPaths` and the rest run on it with no hashing. With a
  hash-counting `Vertex`, `hashes()` stays 0 through any algorithm on the view.
  - `_withIncidentIndexRows` is not forwarded in phase 1, because the vertex side's neighbor
    storage is hyperedge positions without the `+ n` shift.
  - An algorithm that needs the raw rows can copy the view into an `UndirectedAdjacencyList<Int>`
    in O(n + m + p).
- **`BipartiteGraph`.** `BipartiteGraph(h.incidenceGraph, left: 0 ..< h.vertexCount)` builds a
  `BipartiteGraph<Int>` through the existing failable initializer. The view is always simple:
  members are sets, so no incidence repeats.
- **The clique expansion is materialized, not a view.** A lazy `neighbors(of:)` would need a
  scratch set per call, and `edges` would need the whole expansion anyway. It is lossy (it
  forgets which pairs came from which hyperedge) and quadratic: one hyperedge of 10⁴ members is
  5·10⁷ edges. Use the incidence graph unless the pairwise graph is what you want.
- **The line graph is materialized** for the same reasons.

### Conformances

- **`Equatable`, `Hashable`.** Two hypergraphs are equal when they have equal vertex sets and
  equal multisets of member sets, whatever the vertex order or hyperedge order (HG-078 – HG-085).
  This is the README rule for representations. The hash combines the counts, the sum of the
  vertices' hashes, and the sum over the hyperedges of an order-free hash of their members'
  hashes: each vertex is hashed once.
- **`Sendable`** when `Vertex` is.
- **`Codable`** as `{vertices, hyperedges: [[index]]}`, re-checked on decoding.
- **`CustomStringConvertible`.**

## Performance

The workload: n = 10⁵ vertices, m = 2·10⁵ hyperedges of sizes 2–8 (p ≈ 10⁶), `Int` vertices.
`ref.py --baseline` times XGI and HyperNetX on it. On the development machine (Python 3.12):

- XGI 0.10.2: build **1.23 s**; `connected_components` **1.55 s** (4 components); degrees
  0.013 s (NumPy); `to_line_graph(s=2)` **9.72 s** (562 edges).
- HyperNetX 2.4.3: build **18.9 s**; `s_components(s=1, edges=False)` **279 s**. The baseline
  takes about five minutes because of HyperNetX.

| Measure | Target |
|---|---|
| Build from nested arrays | ≤ 1.3× `CompressedSparseRow(edges:)` on p edges, plus n hashes. At least 50× XGI's build |
| `memberIndices`, `incidentHyperedges(ofIndex:)` | an `ArraySlice` and a lazy map over one: no allocation, no hashing |
| Breadth-first search and connected components on `incidenceGraph` | ≤ 1.10× the same call on an `UndirectedAdjacencyList<Int>` copy of the incidence graph |
| `connectedComponents()` | ≤ 1.2× a bare union–find over `_members`. At least 100× XGI's `connected_components` |
| `lineGraph(s: 2)` | O(Σ d²) with one counter array and no hashing. At least 20× XGI's `to_line_graph(s=2)` (a sparse product) |
| Vertex hashes in any index-space algorithm | 0 per incidence, checked with a hash-counting `Vertex` in the benchmark target (not public API) |

## Prior art (verified 2026-10-11)

| Library | What it does | Taken |
|---|---|---|
| XGI 0.10.2 (`xgi.Hypergraph`) | `nodes`, `edges`, `edges.members(e)`, `nodes.memberships(n)`, `degree`, `edges.size`, `dual()`, `to_bipartite_graph` (nodes 0..<n then edges), `to_graph` (clique expansion), `to_line_graph(H, s)`, `connected_components`, `is_connected` (IndexError when empty), `is_uniform` (returns the order or `False`; ignores singleton edges; `False` with no edges), `incidence_matrix`, `degree_histogram`, `unique_edge_sizes`. Multi-edges kept; `add_edge([])` keeps an empty edge, but `add_edges_from` cannot start with one. `DiHypergraph` with `edges.tail` / `edges.head` (also `sources` / `targets`) | Vocabulary, numbering, the views. Deviations: `isUniform` counts every hyperedge and is vacuous on none; `isConnected` is false when empty |
| HyperNetX 2.4.3 (`hnx.Hypergraph`) | Named edges; `incidence_dict`, `size`, `degree(node, s)`, `dual()`, `bipartite()`, `get_linegraph(s, edges)`, `s_components(s, edges, return_singletons=True)`, `s_connected_components(..., return_singletons=False)`, `toplexes`, `collapse_edges`, `incidence_matrix`, `adjacency_matrix(s)`, `edge_size_dist`. **Drops empty edges silently**; keeps repeated edges | s-connectivity and the s-line graph. Singletons always returned |
| SimpleHypergraphs.jl | `Hypergraph{T}` as an `AbstractMatrix` (vertex × hyperedge weights, `nothing` for absent); `nhv`, `nhe`, `getvertices`, `gethyperedges`, `add_vertex!`, `add_hyperedge!`, `remove_vertex!` / `remove_hyperedge!` (renumbering), `dual`, `TwoSectionView`, `BipartiteView`, `get_connected_components` | Views rather than copies; per-incidence weights → the incidence graph's edge positions |
| HyperGraphs.jl (Diaz & Stumpf, *Bioinformatics* 2022) | Hypergraphs over (multi)sets, and oriented "chemical" hypergraphs whose hyperedges have a source set and a target set | Directed hypergraphs as source/target pairs (phase 2) |
| SimpleDirectedHypergraphs.jl | Directed hypergraphs with tail and head sets, as sparse matrices | Phase 2 |
| Wolfram | No built-in `Hypergraph`. The WolframInstitute `Hypergraph` paclet (13.2+) has `Hypergraph`, `Hyperedge`, `HyperedgeList`, `EdgeMultiplicity`, `HypergraphIncidenceMatrix`, `ConnectedHypergraphQ`, `CanonicalHypergraph`; ordered and cyclic edges by "symmetry" | Confirms the vocabulary; ordered hyperedges are out of scope |
| JGraphT (current javadoc class index) | **No hypergraph type.** The class index has only `HyperCubeGraphGenerator`, and no incidence-matrix class | — |
| Berge (1989), Bretto (2013) | Rank, k-uniform, dual H*, incidence (Levi) graph, 2-section / line graph | Mathematical names where no library term exists |
| Aksoy, Joslyn, Marrero, Praggastis, Purvine, "Hypernetwork science via high-order hypergraph walks" (2020) | s-walks, s-line graphs, s-connected components | `lineGraph(s:)`, `sConnectedComponents(s:)` |

## Open questions (with recommendations)

1. **The protocol's name.** `import Grafluent` brings in both modules, so a protocol `Hypergraph`
   in `GraphProtocols` and a struct `Hypergraph` in `Hypergraphs` make every unqualified use
   ambiguous.
   - *Recommendation:* name the structure `Hypergraph<Vertex>`, as every library does, and the
     protocol `HypergraphProtocol`, after Swift's `StringProtocol` (whose `String` has the plain
     name). Update the README protocol row.
   - The alternative, `protocol Hypergraph` with a structure named after its storage, invents a
     name.
2. **`size(ofHyperedgeAt:)`.** The README avoids `size` because programmers read it as memory size,
   or as |E| in NetworkX's `G.size()`.
   - *Recommendation:* keep it. Here it is always "of a hyperedge", and it is the term in XGI,
     HyperNetX and Berge.
   - The alternative, `memberCount`, appears in no hypergraph library, and
     `members(ofHyperedgeAt:).count` is already O(1).
   - Add a Terminology row: "Number of members of a hyperedge | `size(ofHyperedgeAt:)` | XGI,
     HyperNetX | \|e\|".
3. **`Hyperedge<Vertex>`.** The README Elements row plans one: "a nonempty set", possibly
   `SetAlgebra`. *Recommendation:* no stored or returned `Hyperedge` value in phase 1.
   - `hyperedges[p]` is a `Members` view over the stored row. A set value would allocate on every
     read.
   - Construction takes `some Sequence<Vertex>`, and `contains(hyperedge:)` compares member sets.
   - Revisit if a `@HypergraphBuilder` wants an element type.
   - The "nonempty" clause is dropped in any case (question 4).
4. **Empty and repeated hyperedges.** *Recommendation:* allow both.
   - **Repeated:** XGI, HyperNetX and SimpleHypergraphs keep them.
   - **Empty:** without them, `dual()` is not total. An isolated vertex has no hyperedge to
     become, and `dual().dual()` would lose it (HG-056). XGI keeps empty edges; HyperNetX drops
     them silently, a trap the catalog documents (HG-076).
   - Fix the README Elements row accordingly.
5. **`sConnectedComponents(s:)`.** It is HyperNetX's name with the `s` made a label.
   - *Recommendation:* keep it on hyperedges (HyperNetX's default, `edges=True`) and spell the
     vertex form as `dual().sConnectedComponents(s:)`.
   - The phase-1 cost is the m-element `Int` array the dual builds.
   - A `connectedComponents(s:)` overload would read as if `s` changed the meaning of
     `connectedComponents()`, which is about vertices.
6. **Directed hypergraphs.** *Recommendation:* phase 2, as a separate protocol and structure.
   Each hyperedge has a source set and a target set: XGI's `DiHypergraph` (`tail` / `head`, also
   `sources` / `targets`), HyperGraphs.jl's oriented hypergraphs, SimpleDirectedHypergraphs.jl.
   - Use `sources` / `targets`, after `DirectedEdge`'s `source` / `target` and the README's
     arc / tail / head note.
   - Its incidence graph is a `BidirectionalDirectedGraph`: source → hyperedge → target, which is
     XGI's directed `to_bipartite_graph`.
7. **Removal.** *Recommendation:* phase 2.
   - Either swap-remove, with rows re-sorted, at O(Σ_{v∈e} d(v)), as `UndirectedAdjacencyList`
     does;
   - or stable positions, for which a `StableHypergraph` would follow `StableDirectedGraph`.
   - XGI and HyperNetX both keep names stable, which argues for stable positions if only one is
     built.
   - Attached maps (README open question 9) follow the same choice.
8. **Phase 2 algorithms**, in rough order of demand:
   - s-walks, s-distance, s-diameter, s-betweenness (HyperNetX);
   - weighted clique expansion (pair multiplicities, XGI `adjacency_matrix`) and the hypergraph
     Laplacians (Zhou–Huang–Schölkopf, Bolla), with `SpectralGraphTheory`;
   - toplexes and `collapse_edges` (simple-hypergraph reduction);
   - restriction and induced subhypergraphs;
   - random hypergraphs (XGI's uniform Erdős–Rényi and configuration model);
   - centralities and modularity (XGI, SimpleHypergraphs);
   - the HIF interchange format in `GraphFormats`.
9. **Components result type.** `Connectivity`'s `Components<G: DirectedGraph>` is tied to a
   directed graph. *Recommendation:* return `[[Vertex]]` in phase 1, and move to a shared
   vertex-index partition type in the final reuse pass (memory: "Final reuse pass") rather than
   making `Hypergraphs` depend on `Connectivity` now.
   - `h.incidenceGraph.connectedComponents()` already gives `Components` today.
   - Its hyperedge vertices are included.
10. **Dependencies.** `Hypergraphs` would depend on `GraphProtocols`, `AdjacencyListModule`
    (`_RowPool`, and `UndirectedAdjacencyList` for the expansions), `DisjointSetModule` and
    `OrderedCollections`. `HypergraphProtocol` lives in `GraphProtocols`, so `IncidenceMatrixModule`
    does not depend on `Hypergraphs`. The algorithms, written once on the protocol, reach the matrix
    when both are imported.
