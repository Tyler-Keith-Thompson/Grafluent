# `DirectedGraph` / `BidirectionalDirectedGraph`: protocol design research

Scope: the two core protocols in `GraphProtocols`, how the four implemented representations
(`AdjacencyList`, `AdjacencyMatrix`, `CompressedSparseRow`, `EdgeList`) conform, conversion
initializers between them, and the test catalog for the conformances.

Path abbreviations used in citations:

| Prefix | Path |
|---|---|
| `GF:` | the repository root |
| `pg:` | `research/petgraph/crates/petgraph/` |
| `bgl:` | `research/graph/` (Boost.Graph) |
| `lemon:` | `research/lemon/` |
| `jgt:` | `research/jgrapht/jgrapht-core/src/main/java/org/jgrapht/` |
| `nx:` | `research/networkx/networkx/` |
| `sg:` | `research/swiftgraph/Sources/SwiftGraph/` |
| `swift:` | `research/swift/stdlib/public/core/` |
| `sc:` | `research/swift-collections/Sources/` |
| `rev:` | `reviews/` (earlier per-type reviews, not kept) |

`research/` holds upstream shallow clones (Oct 2026), not kept in the repository.

Language claims marked **(verified)** were compiled and run with the local toolchain (Apple Swift
6.2-dev, `-swift-version 6`). The prototype (`proto.swift`), the overload
ambiguity check (`amb.swift`) and the dispatch check (`dispatch.swift`) were scratch files and
were not kept. Algorithm expectations were computed with NetworkX 3.7.1rc0
from the checkout (`directed_calc.py`, next to this file; NetworkX 3.7 prints the same) and are not
derived from Grafluent code.

---

## 1. Recommended declaration

```swift
// GraphProtocols

/// A directed graph: a finite set of vertices and a finite collection of directed edges between
/// them. Edges may repeat (parallel edges) unless the conforming type says otherwise; every
/// count and neighborhood below counts each edge once, so a repeated edge counts once per copy.
public protocol DirectedGraph<Vertex> {
    associatedtype Vertex: Hashable                       // DirectedEdge requires it
    associatedtype Vertices: Collection<Vertex>
    associatedtype Edges: Collection<DirectedEdge<Vertex>>
    associatedtype Successors: Sequence<Vertex>

    /// Every vertex once, in an order the conforming type documents.
    var vertices: Vertices { get }

    /// Every edge, once per copy, in an order the conforming type documents.
    var edges: Edges { get }

    /// The target of every edge leaving `vertex`, once per edge.
    /// - Precondition: `contains(vertex)`. A conforming type may trap or return an empty
    ///   sequence when this does not hold; generic code must not rely on either.
    func successors(of vertex: Vertex) -> Successors

    // Customization points: requirements with default implementations. They must be
    // requirements, not extension methods, so a conformer's faster version is called from
    // generic code (see D2).

    /// `vertices.count`. Default: O(1) when `Vertices` is random-access, else O(n).
    var vertexCount: Int { get }

    /// `edges.count`, repeats included. Default: O(1) when `Edges` is random-access, else O(m).
    var edgeCount: Int { get }

    /// Whether `vertex` is in `vertices`. Never traps. Default: O(n) scan of `vertices`.
    func contains(_ vertex: Vertex) -> Bool

    /// Whether at least one copy of `edge` is in `edges`. Never traps; false when either
    /// endpoint is absent. Default: `contains(source)`, then a scan of `successors(of: source)`.
    func contains(edge: DirectedEdge<Vertex>) -> Bool

    /// The number of edges leaving `vertex`, repeats included: the length of
    /// `successors(of: vertex)`. Same precondition as `successors(of:)`.
    /// Default: iterate `successors(of:)`; `.count` when `Successors` is a `Collection`.
    func outDegree(of vertex: Vertex) -> Int
}

/// A directed graph that also answers in-neighborhoods. (Boost: `BidirectionalGraph`.)
public protocol BidirectionalDirectedGraph<Vertex>: DirectedGraph {
    associatedtype Predecessors: Sequence<Vertex>

    /// The source of every edge entering `vertex`, once per edge. Precondition as `successors(of:)`.
    func predecessors(of vertex: Vertex) -> Predecessors

    /// The number of edges entering `vertex`. Default: the length of `predecessors(of:)`.
    func inDegree(of vertex: Vertex) -> Int

    /// `outDegree(of:) + inDegree(of:)`; a self-loop counts twice. Default: that sum.
    func degree(of vertex: Vertex) -> Int
}

extension DirectedGraph {
    @inlinable public var vertexCount: Int { vertices.count }
    @inlinable public var edgeCount: Int { edges.count }
    @inlinable public func contains(_ vertex: Vertex) -> Bool { vertices.contains(vertex) }
    @inlinable public func contains(edge: DirectedEdge<Vertex>) -> Bool {
        guard contains(edge.source), contains(edge.target) else { return false }
        return successors(of: edge.source).contains(edge.target)
    }
    @inlinable public func outDegree(of vertex: Vertex) -> Int {
        var count = 0
        for _ in successors(of: vertex) { count &+= 1 }
        return count
    }
}

extension DirectedGraph where Successors: Collection {
    @inlinable public func outDegree(of vertex: Vertex) -> Int { successors(of: vertex).count }
}

extension BidirectionalDirectedGraph {
    @inlinable public func inDegree(of vertex: Vertex) -> Int {
        var count = 0
        for _ in predecessors(of: vertex) { count &+= 1 }
        return count
    }
    @inlinable public func degree(of vertex: Vertex) -> Int { outDegree(of: vertex) + inDegree(of: vertex) }
}

extension BidirectionalDirectedGraph where Predecessors: Collection {
    @inlinable public func inDegree(of vertex: Vertex) -> Int { predecessors(of: vertex).count }
}
```

Conformances (each is an empty `extension X: P {}`, because every member already exists with a
matching signature):

| Type | `DirectedGraph` | `BidirectionalDirectedGraph` | `Vertices` | `Edges` | `Successors` / `Predecessors` |
|---|---|---|---|---|---|
| `AdjacencyList<V>` | yes | yes | `AdjacencyList.Vertices` | `AdjacencyList.Edges` | `AdjacencyList.Neighbors` (both) |
| `AdjacencyMatrix` | yes | yes | `Range<Int>` | `AdjacencyMatrix.Edges` | `BitSet` (both) |
| `CompressedSparseRow` | yes | **no** (no in-adjacency) | `Range<Int>` | `CompressedSparseRow.Edges` | `ArraySlice<Int>` / n/a |
| `EdgeList<V>` | yes | yes | `[V]` | `EdgeList` (itself) | `[V]` (both) |

Cost of every member under each conformance (the type's own member is the witness in every case):

| Member | `AdjacencyList` | `AdjacencyMatrix` | `CompressedSparseRow` | `EdgeList` | Default it replaces |
|---|---|---|---|---|---|
| `vertices` | O(1) view (GF:Sources/AdjacencyListModule/AdjacencyList.swift:374) | O(1) (GF:…/AdjacencyMatrix.swift:224) | O(1) (GF:…/CompressedSparseRow.swift:353) | O(m), allocates (GF:…/EdgeList.swift:195) | — |
| `edges` | O(1) view (AdjacencyList.swift:378) | O(1) view (AdjacencyMatrix.swift:642) | O(1) view (CompressedSparseRow.swift:542) | O(1), `self` (EdgeList.swift:186) | — |
| `successors(of:)` | O(1) (AdjacencyList.swift:168) | O(n/64) copy of a row (AdjacencyMatrix.swift:268) | O(1) slice (CompressedSparseRow.swift:393) | O(m) (EdgeList.swift:239) | — |
| `vertexCount` | O(1) (:144) | O(1) (:216) | O(1) (:345) | O(m), no array (:207) | `vertices.count`: EdgeList would allocate |
| `edgeCount` | O(1) (:148) | O(1) (:220) | O(1) (:349) | O(1) (:190) | equal cost |
| `contains(_:)` | O(1) hash (:152) | O(1) (:228) | O(1) (:378) | O(m) (:218) | O(n) scan: **AdjacencyList must override** |
| `contains(edge:)` | O(1) (:158) | O(1) (:234) | O(log d) (:438) | O(m) (:224) | O(d⁺) scan: matrix and CSR must override |
| `outDegree(of:)` | O(1) (:185) | O(1) (:293) | O(1) (:402) | O(m) (:256) | `BitSet.count` is O(n/64) (sc:BitCollections/BitSet/BitSet+BidirectionalCollection.swift:130-139): **matrix must override** |
| `predecessors(of:)` | O(1) (:177) | O(n) column scan (:278) | — | O(m) (:248) | — |
| `inDegree(of:)` | O(1) (:193) | O(1) (:302) | — (`inDegrees` array, :410) | O(m) (:264) | as `outDegree` |
| `degree(of:)` | O(1) (:201) | O(1) (:311) | — | O(m) (:272) | equal cost |

---

## 2. Decision table

| # | Question | Recommendation | Evidence | Disagreements / risks |
|---|---|---|---|---|
| D1 | What is in the base protocol? | `vertices`, `edges`, `successors(of:)` (no default) plus `vertexCount`, `edgeCount`, `contains(_:)`, `contains(edge:)`, `outDegree(of:)` (with defaults). | Boost splits these across `IncidenceGraph` (`out_edges`, `out_degree`), `VertexListGraph` (`vertices`, `num_vertices`), `EdgeListGraph` (`edges`, `num_edges`) and `AdjacencyMatrix` (`edge(u,v)`) (bgl:include/boost/graph/graph_concepts.hpp:73-114, 173-263, 362-375). petgraph splits them into `GraphBase`, `IntoNeighbors`, `NodeCount`, `EdgeCount`, `IntoNodeIdentifiers`, `IntoEdgeReferences` (pg:src/visit/mod.rs:80-90, 107-113, 183-187, 304, 373-376, 507-511). JGraphT puts all of them on one `Graph` interface (jgt:Graph.java:61-559). Boost itself says a vertex-only concept "would no longer really be a graph" and groups vertices with out-edges for convenience (bgl:doc/modules/ROOT/pages/concepts/VertexListGraph.adoc:52-64). The README already decided on one base protocol (GF:README.md:97). | **Risk:** requiring `vertices` and `edges` excludes infinite implicit graphs (state spaces, unbounded grids), which the README plans to model as `ImplicitDirectedGraph` conforming to `DirectedGraph` (GF:README.md:176). petgraph's minimum for traversal is only `GraphBase + IntoNeighbors + Visitable` (pg:src/visit/mod.rs:30-33), and Boost's `breadth_first_visit` needs only `IncidenceGraph`. Recommendation: keep the base finite, and give `Traversal` closure-based entry points (`from:successors:`) for infinite state spaces. Decide this before `ImplicitDirectedGraph` is built. |
| D2 | Requirement with default, or extension method? | Every member that some conformer answers faster than the generic formula is a **requirement with a default** (a customization point). Pure derivations that no representation can beat stay extension methods (none yet). | Swift statically dispatches protocol-extension members that are not requirements: a conformer's own `b()` is ignored in generic code **(verified: `dispatch.swift` prints `1 2`)**. The standard library makes `Collection.count` a requirement documented as O(n) unless random-access (swift:Collection.swift:511-521, default at :1129), and has `_customContainsEquatableElement` as a requirement with a default (swift:Sequence.swift:385, :814) for the same reason. LEMON does the same with tags: `countNodes` is O(n) unless the graph has `NodeNumTag` (lemon:lemon/core.h:224-254), and `findArc` scans out-arcs unless the graph has `FindArcTag` (lemon:lemon/core.h:1601-1656). Boost's `lookup_edge` uses `edge()` for adjacency matrices and scans `out_edges` otherwise (bgl:include/boost/graph/lookup_edge.hpp:24-50). SwiftGraph shows what goes wrong: `edgeCount` is an extension member computed as `edges.joined().count` (sg:Graph.swift:39-41), so no conformer can make it faster for generic code. | JGraphT puts defaults on `GraphIterables` (jgt:GraphIterables.java:57-218), a separate object rather than on `Graph`. NetworkX has no static dispatch, so the issue doesn't arise. |
| D3 | Where do `inDegree`, `degree` and `predecessors` go? | On `BidirectionalDirectedGraph`. `degree` needs `inDegree`, so it goes there too. Bulk forms (`inDegrees`) stay concrete; a generic Kahn sort computes in-degrees in one pass over `edges`. | Boost's `BidirectionalGraph` adds `in_edges`, `in_degree` **and** `degree` (bgl:graph_concepts.hpp:116-147), and keeps it separate "because … efficient access to in-edges typically requires more storage space, and many algorithms do not require access to in-edges" (bgl:doc/…/concepts/BidirectionalGraph.adoc:3-10). petgraph's `IntoNeighborsDirected` is implemented by `Graph`, `StableGraph`, `GraphMap` and `MatrixGraph`, but not by `Csr` or `List` (pg:src/visit/mod.rs:52-53). NetworkX's `topological_generations` builds an in-degree map from `in_degree()` (nx:algorithms/dag.py:286-287). | README open question 7 (GF:README.md:315) floats putting `predecessors` on every `DirectedGraph` at O(\|A\|). Recommend against: CSR would hide an O(m) cost behind an O(1)-looking call, and Boost and petgraph both keep the split. |
| D4 | Name of the refinement | Keep `BidirectionalDirectedGraph`. It **is** an established term: Boost's concept is `BidirectionalGraph`, defined for exactly this property. "Directed" is added because Grafluent's `Graph` means undirected. | bgl:graph_concepts.hpp:116; bgl:…/BidirectionalGraph.adoc:1-10. | Open question 7 says the name isn't established. It is, through Boost. petgraph's name for the same capability is `IntoNeighborsDirected`. |
| D5 | `Vertices`, `Edges` constraints | `Collection` (multi-pass, with `count`). Each concrete type exposes a stronger type: random-access for AL, CSR and EL; `Range<Int>` for index graphs; bidirectional for matrix edges. | Boost requires `MultiPassInputIterator` for vertices and edges (bgl:graph_concepts.hpp:181, 232). The README table already says `Collection` (GF:README.md:109-110). | — |
| D6 | `Successors` constraint | `Sequence<Vertex>`, as the README decided (GF:README.md:111-113). Document that `successors(of:)` may be called again for another pass. Algorithms that need `count` or multiple passes add `where G.Successors: Collection`. | petgraph: `type Neighbors: Iterator` (pg:src/visit/mod.rs:109-112). Boost asks for multi-pass (bgl:graph_concepts.hpp:87). All four implemented types return a `Collection`. | **`Span<Vertex>` cannot be `Successors`.** `Span` is `~Escapable` (swift:Span/Span.swift:29) and does not conform to `Sequence`, so the README's "`Span<Vertex>` for contiguous storage" (GF:README.md:111) can't be the protocol's return type. It confirms the CSR review's guess (rev:csr-review.md:158). Spans stay concrete-type API (`withUnsafeBufferPointers` exists today, CompressedSparseRow.swift:366). |
| D7 | Primary associated type; `some` / `any` | `DirectedGraph<Vertex>` and `BidirectionalDirectedGraph<Vertex>`, modeled on `Collection<Element>` (swift:Collection.swift:338). `some DirectedGraph<Int>` works as a parameter type and calls each conformer's witnesses **(verified: the custom `outDegree` returned through both `some` and `any`)**. `any DirectedGraph<Int>` compiles; associated-type results come back erased (`successors` is `any Sequence<Int>` statically) and every call goes through the witness table. | proto.swift, `viaGeneric` / `viaAny` / `anySucc`. README: "algorithm parameters are `some` generics, never `any`" (GF:README.md:303). | Only `Vertex` is primary. Making `Successors` primary too would put representation details into every signature. |
| D8 | `Sendable` | The protocols do **not** refine `Sendable`. Conformers stay conditionally `Sendable`, as they are today (AdjacencyList.swift:530-534; AdjacencyMatrix.swift:837-839; CompressedSparseRow.swift:656-658; EdgeList.swift:395). Algorithms that cross isolation write `G: DirectedGraph & Sendable`. | Standard-library and swift-collections protocols don't refine `Sendable`. A protocol can't refine `Sendable` conditionally. `AdjacencyList` is tested with reference-type vertices (Tests/AdjacencyListTests/README.md, VertexTypeTests), which a `Sendable` refinement would reject when they aren't `Sendable`. | README line 103 ("All protocols are `Sendable` when their vertex type is") should read "all conforming types". |
| D9 | Querying an absent vertex | Protocol contract: **precondition `contains(vertex)`** for `successors`, `predecessors` and the degrees. A violation may trap (AL, AM, CSR) or return empty / 0 (EdgeList). Generic code must not depend on either. Law tests query present vertices only; each type's own suite pins its own behavior. | AL traps (AdjacencyList.swift:208-213; Tests/AdjacencyListTests/README.md:70); AM and CSR trap out of range (AdjacencyMatrix.swift:139; CompressedSparseRow.swift:383-386; Tests/CompressedSparseRowTests/README.md:62); EdgeList returns empty because it has no vertex set (EdgeList.swift:237-268; Tests/EdgeListTests/README.md:57). This matches `Collection`'s "must be a valid index", which is a precondition and not a promise to trap. | The libraries split: NetworkX raises (nx:classes/digraph.py:911-938); JGraphT throws `IllegalArgumentException` (jgt:Graph.java:325, 358, 394); petgraph `Graph` and `MatrixGraph` return an empty iterator (pg:src/graph_impl/mod.rs:895; pg:src/matrix_graph.rs:620) while petgraph `Csr` panics (pg:src/csr.rs:410-441); Boost leaves it undefined. |
| D10 | `contains(_:)` / `contains(edge:)` on absent things | **Never trap; return false.** The default `contains(edge:)` checks both endpoints first, so it keeps this promise for any conformer. | All four agree: AdjacencyList.swift:158-161, AdjacencyMatrix.swift:234-237, CompressedSparseRow.swift:423-440, EdgeList.swift:224. Tests/AdjacencyMatrixTests/README.md:70. NetworkX `has_edge` and JGraphT `containsEdge` return false too (test-catalog-adjacency-list.md Q-03). | — |
| D11 | Multigraphs: what neighborhoods contain | **One entry per edge**: a vertex appears in `successors(of: u)` once for each copy of `u→v`. So `outDegree(of: u)` equals the length of `successors(of: u)` in every conformer, and a Kahn sort or in-degree count needs no special case. | Boost: "the behavior is defined to match that of `out_edges()`", repeats included (bgl:doc/…/concepts/AdjacencyGraph.adoc:102-110). JGraphT: "If the graph is a multigraph vertices may appear more than once" (jgt:Graphs.java:346-369). petgraph `Graph` lists a parallel neighbor twice (`neighbors(b) == [a, c, a]`, pg:tests/graph.rs:33-71). EdgeList already does this (EdgeList.swift:237-243). | **NetworkX disagrees:** `MultiDiGraph.successors` yields distinct neighbors while `out_degree` counts edges. Verified: `MultiDiGraph([(1,3),(1,3),(1,2)])` gives `successors(1) == [3, 2]` and `out_degree(1) == 3`. Its own `topological_generations` must then decrement by `len(G[node][child])` on multigraphs (nx:algorithms/dag.py:285-297). DG-A07 tests this case. |
| D12 | Multigraphs: counts and `contains(edge:)` | `edgeCount == edges.count` counts every copy. `outDegree` and `inDegree` count every copy. `contains(edge:)` means "at least one copy". The number of copies (`multiplicity(of:)`, EdgeList.swift:230) is not in this round's protocols. | NetworkX `number_of_edges()` counts copies and `has_edge` means "any" (nx:classes/multigraph.py:773, 1238; verified 3 and `True`). JGraphT `getAllEdges` returns all copies (jgt:Graph.java:63-78). Boost `out_degree` counts out-edges. | For a simple graph each of these reduces to the set definition, so one law set covers both kinds of graph. |
| D13 | Separate `DirectedMultigraph` refinement now? | **No, not this round.** `DirectedGraph` already permits parallel edges (D11, D12). Keep `DirectedMultigraph` (edge identity, `edges(from:to:)`, multiplicity) for when there is a second multigraph type or an algorithm that needs it. Algorithms that need a simple graph state it in their documentation for now. A type-level flag (Boost's `edge_parallel_category`) can be added later as a static requirement with a default. | Boost records it as a type trait (`allow_parallel_edge_tag`, `allows_parallel_edges`, `is_multigraph`, bgl:include/boost/graph/graph_traits.hpp:141-172; Graph.adoc:57-63). JGraphT checks `GraphType.isAllowingMultipleEdges()` at run time (jgt:GraphType.java:66) and throws from algorithms such as VF2 (jgt:alg/isomorphism/VF2AbstractIsomorphismInspector.java:62). NetworkX uses `@not_implemented_for("multigraph")` 105 times in `algorithms/` (decorator at nx:utils/decorators.py:24). | The EdgeList review wants `edges(from:to:)`'s shape fixed early (rev:edge-list-review.md:284-290). Adding a refinement later breaks nothing. |
| D14 | Dense vertex indices for algorithms | **Design now, ship with the first algorithm module (`Traversal`), as a separate refinement.** Sketch: `protocol <name><Vertex>: DirectedGraph { func index(of: Vertex) -> Int; func vertex(at: Int) -> Vertex }`. The indices are exactly `0..<vertexCount`, valid until the next mutation (the graph is a value, so an algorithm's copy keeps them stable). AL (its dense slots), AM and CSR (identity) conform; EdgeList does not. Algorithms add faster overloads constrained on it, and Swift picks the more constrained overload, so adding it later breaks nothing. | petgraph `NodeIndexable { node_bound, to_index, from_index }` and `NodeCompactIndexable` ("exactly the indices `0..node_bound()`") (pg:src/visit/mod.rs:335-346, 386). petgraph `GraphMap` builds it on `IndexMap::get_index_of`, which is AL's design (pg:src/graphmap.rs:1238-1262). Boost synthesizes `vertex_index` for `vecS` only, and other graphs must pass `vertex_index_map` (bgl:doc/modules/ROOT/pages/faq.adoc:160-166; property_maps/pitfalls.adoc:123). LEMON: `id(Node)`, `nodeFromId`, `maxNodeId` (lemon:lemon/concepts/digraph.h:340-365). The AL review measured a 3.9× BFS penalty without indices (rev:adjacency-list-review.md:73-90). | The AL review asks for it in this round ("retrofitting it after five algorithm modules exist will be painful"). As a refinement it isn't a retrofit, but it has no user until `Traversal` exists, so its tests would have nothing to test. **Naming needs a decision.** petgraph's term is `NodeCompactIndexable`; in Grafluent's vocabulary that becomes `VertexIndexable` (compact only, since no representation has holes; AM refuses vertex removal for this reason, Tests/AdjacencyMatrixTests/README.md:68). Only the compact form is needed. |
| D15 | Conversion initializers | `AdjacencyList(_ graph: some DirectedGraph<Vertex>)`, `AdjacencyMatrix(_ graph: some DirectedGraph<Int>)`, `CompressedSparseRow(_ graph: some DirectedGraph<Int>)`. Concrete initializers, not protocol requirements. Semantics: the result's vertex set is `graph.vertices` (isolated vertices kept) and its edge set is `Set(graph.edges)` (parallel edges collapse, the same as `init(edges:)`). CSR passes `graph.edges` to its existing `init(vertexCount:edges:)` taking a `Collection` (CompressedSparseRow.swift:66), which reads it twice without copying. | README "Conversion" row (GF:README.md:156); EL catalog EL-C11, EL-X10, EL-X11 (research/test-catalog-edge-list.md:150, 324-325); CSR review asks for it (rev:csr-review.md:163). Boost `copy_graph(VertexListGraph, MutableGraph)` (bgl:include/boost/graph/copy.hpp:17-21) and petgraph `Graph::from(StableGraph)` (petgraph notes §1) are the same "vertices, then edges" copy. | — |
| D16 | Int graphs whose vertices are not `0..<n` | `AdjacencyMatrix(_:)` and `CompressedSparseRow(_:)` use `n = graph.vertexCount` and **trap** unless every vertex is in `0..<n`. Because the vertices are distinct and there are `n` of them, that check is the same as "the vertices are exactly `0..<n`", and it costs O(n). Edge endpoints are then in range automatically. Other numberings go through the existing `init(vertexCount:edges:)` or the planned `LabeledGraph`. | CSR's convention: "Vertex count: Always explicit" (Tests/CompressedSparseRowTests/README.md:58). AM and CSR trap on out-of-range endpoints (Tests/AdjacencyMatrixTests/README.md:69; EL-X11). The fixture set already separates `zeroBased` fixtures (GF:Tests/GrafluentTestSupport/DirectedFixtures.swift:582-583). | petgraph and GAP infer `max + 1` and fill the holes with isolated vertices (Tests/CompressedSparseRowTests/README.md:58). That would quietly turn `directedCycle4` (vertices 1…4) into a 5-vertex graph. Renumbering would quietly change what the vertices mean. Both are rejected. |
| D17 | `EdgeList(_:)` overload ambiguity | **Give `EdgeList` no `init(_ graph:)`.** The conversion is spelled `EdgeList(graph.edges)`, using the existing `init(_ edges: some Sequence<DirectedEdge<Vertex>>)` (EdgeList.swift:32), and does what EL-C11 asks (copies `edges` in their order). | Adding `init(_ graph: some DirectedGraph<V>)` next to the `Sequence` initializer makes `EdgeList(edgeList)` an **error: ambiguous use of 'init(_:)'** **(verified, amb.swift)**, because `EdgeList` is both a `Sequence` and a `DirectedGraph` and neither protocol refines the other. `RangeReplaceableCollection` requires the unlabeled `Sequence` init (Tests/EdgeListTests/README.md:63). | `@_disfavoredOverload` would fix the ambiguity, but it is underscored and would make `EdgeList(list)` mean different things depending on the static type. A labeled `init(graph:)` is the fallback if a direct spelling is wanted. AL, AM and CSR have no unlabeled `Sequence` initializer, so their `init(_:)` is unambiguous. |
| D18 | `contains(_ vertex:)` on `EdgeList` | Keep the requirement unlabeled, matching `Set` and AL (AdjacencyList.swift:152). On `EdgeList<AnyHashable>`, a `DirectedEdge` argument resolves to `Sequence.contains(_:)` (edge membership, exact match) before `contains(_ vertex:)`, which would need a conversion. DG-T06 pins this. | AL review on `AnyHashable` overloads (rev:adjacency-list-review.md:28-39); EL review (rev:edge-list-review.md:343). | A `contains(vertex:)` label would remove the question completely, but AL's API and `Set` would then disagree. |
| D19 | Performance: generic vs concrete vs existential | Algorithms are `@inlinable` generics over `some`. Protocol defaults are `@inlinable`. All current members are already `@inlinable` (e.g. AdjacencyList.swift:142-205), so specialized generic code calls them directly. Existentials pay witness dispatch and boxing of each returned neighborhood. This is measured in benchmarks, never in tests. | README principle 3 and the "Specialization" note (GF:README.md:10, 303). User memory: properties visible only internally go to benchmarks. | — |
| D20 | How conformance tests are organized | Like NetworkX (one tester class re-run per graph class), Boost (one `test_graph` body for every configuration) and petgraph (one generic checker per graph type). Write each law **once per test as a local generic function inside the test body**, and run it over every representation × fixture with `@Test(arguments:)`. No shared helper, so each test can be copied anywhere (user memory). | nx:classes/tests/test_multidigraph.py:13, 255 (`BaseMultiDiGraphTester(BaseMultiGraphTester)`), test_digraph.py:11, 201; bgl:test/test_graph.hpp:103-140 and bgl:test/test_graphs.cpp:30-198 (the same body over `adjacency_list` ×4, `adjacency_matrix` ×2, `labeled_graph`, `compressed_sparse_row_graph` ×2); pg:tests/adjacency_matrix.rs:14-34 (one generic law run for `Graph`, `StableGraph`, `GraphMap`, `MatrixGraph`, `Csr`, `List`); jgt `SimpleIdentityDirectedGraphTest` (reruns the suite on another storage strategy). Boost's compile-time archetypes are bgl:test/graph_concepts.cpp:18-44. | Where the tests live: laws in each representation's test target (`<Type>DirectedGraphTests.swift`), because the conformance is declared there. Cross-representation agreement and conversion tests go in a new `Tests/GraphProtocolsTests` target that depends on all four modules. |

---

## 3. Test catalog

Notation: `AL`, `AM`, `CSR`, `EL` are the four types. `F.x` is
`DirectedFixture<Int>.x` or `DirectedFixture<String>.x` from
`GF:Tests/GrafluentTestSupport/DirectedFixtures.swift`. Built as
`AdjacencyList(vertices: F.vertices, edges: F.edges)`,
`AdjacencyMatrix(vertexCount: F.vertexCount, edges: F.edges)`,
`CompressedSparseRow(vertexCount: F.vertexCount, edges: F.edges)` (zero-based fixtures only), and
`EdgeList(F.edges)` (edges as written, so repeats are kept and isolated vertices are lost).
"Generic" means the value is read through a local `func f<G: DirectedGraph>(_ g: G)`, never
through the concrete type. Each law runs for the four types × `F.all` (AM and CSR use
`zeroBased`), plus `F<String>.all` for AL and EL.

### 3.1 Laws (any conformer)

| ID | Law | Applies to |
|---|---|---|
| DG-L01 | `g.vertexCount == g.vertices.count` and `Set(g.vertices).count == g.vertexCount` (vertices are distinct) | all |
| DG-L02 | `g.edgeCount == g.edges.count` | all |
| DG-L03 | Every `v` in `vertices` has `contains(v)`. Every endpoint of every edge in `edges` is in `vertices` | all |
| DG-L04 | For each `v` in `vertices`: the multiset of `successors(of: v)` equals the multiset of `e.target` over `edges` with `e.source == v` | all |
| DG-L05 | For each `v`: `outDegree(of: v) == Array(successors(of: v)).count` (repeats included) | all |
| DG-L06 | `Σ_v outDegree(of: v) == edgeCount` | all |
| DG-L07 | For each `u, v` in `vertices`: `contains(edge: u→v) == edges.contains(u→v) == successors(of: u).contains(v)` | all |
| DG-L08 | `contains(edge:)` with an endpoint not in `vertices` is `false` and does not trap (absent vertex `-1`, or `"∅"` for String fixtures) | all |
| DG-L09 | `contains(x)` for `x` not in `vertices` is `false` and does not trap | all |
| DG-L10 | For each `v`: the multiset of `predecessors(of: v)` equals the multiset of `e.source` over `edges` with `e.target == v` | AL, AM, EL |
| DG-L11 | `inDegree(of: v) == Array(predecessors(of: v)).count`; `Σ inDegree == edgeCount` | AL, AM, EL |
| DG-L12 | `degree(of: v) == outDegree(of: v) + inDegree(of: v)`; `Σ degree == 2 · edgeCount` | AL, AM, EL |
| DG-L13 | Duality: `u` occurs in `predecessors(of: v)` exactly as many times as `v` occurs in `successors(of: u)` | AL, AM, EL |
| DG-L14 | Self-loop: for each edge `v→v`, `v` is in both `successors(of: v)` and `predecessors(of: v)`, once per copy; for a simple graph exactly once | all (predecessors: AL, AM, EL) |
| DG-L15 | Simple representations: `edges` has no repeats (`Set(edges).count == edgeCount`) and `successors(of: v)` has no repeats | AL, AM, CSR |
| DG-L16 | The generic value equals the concrete member's value for each of `vertexCount`, `edgeCount`, `contains`, `contains(edge:)`, `outDegree`, `inDegree`, `degree` on every vertex. This guards against a renamed or retyped member falling back to the default | all |
| DG-L17 | Fixture agreement: generic `vertexCount`, `edgeCount`, `outDegree`, `inDegree` equal `F.vertexCount`, `F.edgeCount`, `F.outDegree[v]`, `F.inDegree[v]`. **Not EL**: its counts differ for fixtures with repeats or isolated vertices (DG-R10–R13) | AL, AM, CSR |
| DG-L18 | Repeated calls: `successors(of: v)` called twice gives equal sequences. This is the multi-pass contract | all |

### 3.2 Per-representation conformance cases (exact values)

| ID | Case | Expected |
|---|---|---|
| DG-R01 | `AL(F.house)`, generic | `vertexCount 6`, `edgeCount 7`, `outDegree` `[0:0, 1:1, 2:1, 3:2, 4:2, 5:1]`, `inDegree` `[0:2, 1:2, 2:1, 3:1, 4:1, 5:0]` (Boost test_direction.hpp:38-43, 85-90 expects the same) |
| DG-R02 | `AL(F.networkXABCD)` (String), generic | `vertexCount 7`, `edgeCount 5`; `Set(successors(of: "A")) == ["B", "C"]`; `degree(of: "G") == 0`; `contains("G")` |
| DG-R03 | `AL(F.singleSelfLoop)`, generic | `successors(of: 0) == [0]`, `predecessors(of: 0) == [0]`, `outDegree 1`, `inDegree 1`, `degree 2`, `contains(edge: 0→0)` |
| DG-R04 | `AM(F.boostExample)`, generic | `Array(successors(of: 1)) == [2, 5]`, `Array(predecessors(of: 0)) == [2, 5]`, `Array(predecessors(of: 2)) == [1, 2]`, `outDegree(of: 2) == 2`, `degree(of: 2) == 4`, `contains(edge: 0→1) == false` |
| DG-R05 | `AM(F.isolatedVertices)`, generic | `vertexCount 10`, `edgeCount 0`, every `successors` empty, `Array(vertices) == Array(0..<10)` |
| DG-R06 | `CSR(F.petgraphCsr1)`, generic | `Array(successors(of: 0)) == [0, 2]`, `(of: 1) == [0, 1, 2]`, `(of: 2) == [2]`; `outDegree` `[2, 3, 1]`; `contains(edge: 2→1) == false`, `contains(edge: 1→1) == true` |
| DG-R07 | `CSR(F.boostCsrUnsorted)`, generic `edges` | `Array(edges) == [0→2, 3→2, 4→0, 4→1, 5→0, 5→2]` (row-major); `edgeCount 6` |
| DG-R08 | `CSR(F.scipyConstructor2)`, generic | `vertexCount 6`, `edgeCount 1`, `outDegree(of: 3) == 1`, all others 0 |
| DG-R09 | `CSR` is not bidirectional | `(CompressedSparseRow() as Any) is any BidirectionalDirectedGraph == false`; for AL, AM and EL the same check is `true` |
| DG-R10 | `EL(F.pathWithChord)` (multigraph), generic | `edgeCount 7`, `vertexCount 6`, `Array(successors(of: 1)) == [2, 3, 3]`, `outDegree(of: 1) == 3`, `Array(predecessors(of: 3)) == [2, 1, 1]`, `inDegree(of: 3) == 3`, `degree(of: 1) == 4`, `contains(edge: 1→3)` (NetworkX `MultiDiGraph` agrees on degrees: out `{1: 3}`, in `{3: 3}`) |
| DG-R11 | `EL(F.jgraphtSparseDirected)` (2→4 three times), generic | `edgeCount 13`, `vertexCount 8`, `Array(vertices) == [0, 1, 4, 5, 6, 2, 3, 7]`, `Array(successors(of: 2)) == [4, 4, 4]`, `outDegree(of: 2) == 3`, `Array(predecessors(of: 4)) == [1, 2, 2, 2, 3]`, `inDegree(of: 4) == 5`, `degree(of: 7) == 3`, `Σ outDegree == 13` (NetworkX `MultiDiGraph`: out `{2: 3}`, in `{4: 5}`) |
| DG-R12 | `EL(F.networkXABCD)` (String) | `vertexCount 4` (G, J, K are lost); `contains("G") == false` |
| DG-R13 | EL absent vertex, generic | `Array(successors(of: 99)) == []`, `outDegree(of: 99) == 0`, `Array(predecessors(of: 99)) == []`, `inDegree 0`, `degree 0` on `EL(F.house)`; no trap |
| DG-R14 | AL absent vertex, generic: exit tests | `successors(of: 99)`, `outDegree(of: 99)`, `predecessors(of: 99)`, `inDegree(of: 99)`, `degree(of: 99)` each trap on `AL(F.house)` |
| DG-R15 | AM and CSR out of range, generic: exit tests | `successors(of: 6)` and `outDegree(of: -1)` trap on `AM(F.house)` and `CSR(F.house)`; `predecessors(of: 6)` traps on AM |
| DG-R16 | The empty graph through every type, generic | `vertexCount 0`, `edgeCount 0`, `vertices` and `edges` empty, `contains(0) == false`, `contains(edge: 0→0) == false` |

### 3.3 Type-level and API-shape cases

| ID | Case | Expected |
|---|---|---|
| DG-T01 | Associated types are the concrete views (no wrapper) | `AdjacencyList<Int>.Successors.self == AdjacencyList<Int>.Neighbors.self`; `AdjacencyMatrix.Successors.self == BitSet.self`, `.Predecessors == BitSet`; `CompressedSparseRow.Successors.self == ArraySlice<Int>.self`; `EdgeList<Int>.Successors.self == [Int].self`, `.Edges == EdgeList<Int>`, `.Vertices == [Int]`; `AdjacencyMatrix.Vertices == Range<Int>` |
| DG-T02 | `some DirectedGraph<Int>` accepts all four | A local `func count(_ g: some DirectedGraph<Int>) -> Int` returns `F.house.edgeCount` (7) for AL, AM, CSR and EL built from `house` |
| DG-T03 | `some BidirectionalDirectedGraph<String>` accepts AL and EL | `degree(of: "b") == 4` on `F.petgraphDAG` (in-edges a→b and d→b, out-edges b→c and b→e) |
| DG-T04 | Existentials work | `let gs: [any DirectedGraph<Int>] = [AL(house), AM(house), CSR(house), EL(house.edges)]`: every `edgeCount == 7`, and `Set(successors(of: 3)) == [2, 4]` through each opened existential |
| DG-T05 | `Sendable` composition | `func f<G: DirectedGraph & Sendable>(_: G)` accepts all four with `Int` vertices, and the result can be sent to a `Task` |
| DG-T06 | `EdgeList<AnyHashable>` membership overloads | With `list = EdgeList<AnyHashable>([DirectedEdge(from: 1, to: 2)])`: `list.contains(DirectedEdge<AnyHashable>(from: 1, to: 2))` is edge membership, `true`; `list.contains(AnyHashable(1))` is vertex membership, `true`; `list.contains(AnyHashable(DirectedEdge(from: 1, to: 2)))` is `false` |
| DG-T07 | `EdgeList(edgeList)` still compiles and copies | `EdgeList(EL(F.pathWithChord.edges)) == EL(F.pathWithChord.edges)` (guards against adding `EdgeList.init(_ graph:)`, D17) |

### 3.4 Generic algorithms (test-local, written against the protocol)

Each test declares its algorithm as a local generic function in its own body: BFS, DFS
(iterating `successors` sorted, so the result doesn't depend on neighbor order), Kahn's
topological generations (in-degrees from one pass over `edges`), Tarjan SCC (base protocol), and
Kosaraju SCC (`BidirectionalDirectedGraph`). It then checks that every representation gives the
NetworkX value. Sets and partitions are compared order-free.

| ID | Algorithm / fixture / source | Expected (NetworkX) | Types |
|---|---|---|---|
| DG-A01 | BFS reachable set and distances, `house` from 5 | descendants `{0,1,2,3,4}`; dist `{5:0, 3:1, 2:2, 4:2, 0:3, 1:3}` | AL, AM, CSR, EL |
| DG-A02 | BFS distances, `boost24` from 7 | `{7:0, 11:1, 17:1, 4:2, 15:2, 19:2, 20:2, 0:3, 5:3, 6:3, 13:3, 18:3, 22:3, 23:3, 3:4, 8:4, 9:4, 14:4, 16:4, 21:4, 1:5, 10:5, 12:5, 2:6}`, 24 reached | AL, AM, CSR, EL |
| DG-A03 | BFS distances, `scc9` from 1 | `{1:0, 7:1, 4:2, 5:2, 8:3, 2:4, 6:4, 0:5, 3:6}` | AL, AM, CSR, EL |
| DG-A04 | BFS order with ascending successors, `petgraphEdgesDirected` from 0 | `[0, 1, 2, 3, 5, 4]`; dist `{0:0, 1:1, 2:1, 3:1, 5:1, 4:2}`; from 6 only `[6]` (self-loop) | AL, AM, CSR, EL |
| DG-A05 | DFS preorder with ascending successors | `petgraphEdgesDirected` from 0: `[0, 1, 3, 2, 4, 5]`; `neo4jDirected` from 0: `[0, 1, 2, 4, 3]`; `petgraphDAG` from "a": `["a", "b", "c", "e", "g", "d", "f"]` | AL, AM, CSR, EL (String: AL, EL) |
| DG-A06 | Topological generations (Kahn) | `house` `[[5],[3],[2,4],[1],[0]]`; `neo4jDirected` `[[0],[1],[2,3],[4]]`; `boostCsrUnsorted` `[[3,4,5],[0,1],[2]]`; `petgraphDAG` `[[a],[d],[b,f],[c],[e],[g]]`; `networkXABCD` `[[A,G,J,K],[B],[C],[D]]` (EL: `[[A],[B],[C],[D]]`); `scipyConstructor2` `[[0,1,2,3,5],[4]]` (EL: `[[3],[4]]`) | AL, AM, CSR, EL |
| DG-A07 | Kahn on a multigraph | `EL(pathWithChord)` (1→3 twice) gives `[[0],[1],[2],[3],[4],[5]]`, all 6 vertices emitted. If neighborhoods were de-duplicated while in-degrees counted every copy (NetworkX's mismatch, D11), vertex 3 would keep in-degree 1 and never be emitted | EL (AL for contrast) |
| DG-A08 | Kahn on cyclic graphs emits fewer than `vertexCount` vertices | `scc9`, `directedCycle4`, `boost24`: not acyclic (`is_directed_acyclic_graph == False`) | all |
| DG-A09 | SCC partition (Tarjan, base protocol) | `scc9` `{{0,3,6},{1,4,7},{2,5,8}}`; `boost24` `{{0},{7},{1…6, 8…23}}` (3 components); `petgraphEdgesDirected` `{{0,2,4},{1},{3},{5},{6}}`; `igraphReverseEdges` `{{0},{1,2,3},{4}}`; `networkXFunctionGraph` `{{0,1},{2},{3},{4}}`; `boostExample` `{{0},{1},{2},{3,4},{5}}` | AL, AM, CSR, EL |
| DG-A10 | SCC partition (Kosaraju, uses `predecessors`) | Same partitions as DG-A09 | AL, AM, EL |
| DG-A11 | Reverse reachability through `predecessors` | ancestors of 8 in `scc9`: `{1,2,4,5,7}`; ancestors of 8 in `petgraphBellmanFord`: `{4,5,6,7}`; ancestors of 5 in `boostExample`: `{1}` | AL, AM, EL |
| DG-A12 | The same algorithm through `any DirectedGraph<Int>` gives the same result | DG-A01 and DG-A09 values through `[any DirectedGraph<Int>]` | all |

### 3.5 Conversions

| ID | Case | Expected |
|---|---|---|
| DG-C01 | `AdjacencyList(EL(F.pathWithChord.edges))` | `vertexCount 6`, `edgeCount 6` (the repeated 1→3 collapses), equal to `AL(F.pathWithChord)` |
| DG-C02 | `AdjacencyList(AM(F.scipyConstructor2))` keeps isolated vertices | `vertexCount 6`, `edgeCount 1`, `contains(5)`; compare `EdgeList(AM(F.scipyConstructor2).edges).vertexCount == 2` |
| DG-C03 | `AdjacencyList(AM(F.isolatedVertices))` | `vertexCount 10`, `edgeCount 0` |
| DG-C04 | `CompressedSparseRow(AM(F.boostCsrUnsorted))` exact arrays | `offsets == [0, 1, 1, 1, 2, 4, 6]`, `targets == [2, 2, 0, 1, 0, 2]` |
| DG-C05 | `EdgeList(CSR(F.house).edges)` row-major (EL-C11) | `[1→0, 2→1, 3→2, 3→4, 4→0, 4→1, 5→3]` |
| DG-C06 | `EdgeList(AM(F.boostExample).edges)` (EL-X10) | `[1→2, 1→5, 2→0, 2→2, 3→4, 4→3, 5→0]` |
| DG-C07 | Round trips over every `zeroBased` fixture | `AdjacencyMatrix(CSR(AL(F))) == AM(F)`, `CSR(AM(F)) == CSR(F)`, `AdjacencyList(CSR(F)) == AL(F)`, `AdjacencyList(AM(F)) == AL(F)` |
| DG-C08 | Self-conversion is identity | `AdjacencyList(al) == al`; `AdjacencyMatrix(am) == am`; `CompressedSparseRow(csr) == csr` |
| DG-C09 | Exit test: vertices not `0..<n` | `AdjacencyMatrix(AL(F.directedCycle4))` and `CompressedSparseRow(AL(F.directedCycle4))` trap (vertices 1…4, n = 4); likewise `triangleWithReciprocalEdge`, `selfLoopsAndDuplicates` |
| DG-C10 | Exit test: EdgeList endpoints out of range (EL-X11) | `CompressedSparseRow(EdgeList([0→2]))` traps (vertexCount 2, vertex 2 out of range); `AdjacencyMatrix(EdgeList([0→2]))` traps |
| DG-C11 | Conversion from EdgeList with a gap-free numbering | `CompressedSparseRow(EL(F.neo4jDirected.edges)) == CSR(F.neo4jDirected)` (endpoints are exactly 0…4) |
| DG-C12 | String conversion (EL-X14) | `AdjacencyList(EL(F.networkXABCD.edges)).vertexCount == 4`; `AdjacencyList(AL(F.networkXABCD)).vertexCount == 7` |
| DG-C13 | Conversion preserves the generic answers | For each `zeroBased` fixture and each pair of source and destination types, every DG-L16 value matches between source and destination, except EL sources with repeats, where `edgeCount` and degrees drop to the set values |

### 3.6 Benchmarks, not tests (D19)

| ID | Measurement |
|---|---|
| DG-B01 | BFS from vertex 0 on Graph500 scale 8 and the Ligra rMat fixture (GF:Tests/GrafluentTestSupport/RealWorldFixtures.swift): concrete loop vs `some DirectedGraph` vs `any DirectedGraph`, for each of the four types. Expect concrete ≈ generic under `-O`, and the existential measurably slower |
| DG-B02 | `outDegree(of:)` through generic code on AM at n = 4096. Expect O(1), not the O(n/64) `BitSet.count` default |
| DG-B03 | `contains(edge:)` through generic code on CSR with a hub of out-degree 20,000. Expect O(log d), not the default O(d) scan |

---

## 4. Open items for the user

1. **ImplicitDirectedGraph vs a finite base (D1).** Either accept that infinite state spaces use
   closure-based traversal, or split out a smaller base protocol (Boost `IncidenceGraph` style)
   before anything conforms.
2. **Vertex-index refinement name and timing (D14).** Recommended: land it with `Traversal`.
   Name to approve: `VertexIndexable` (petgraph's `NodeCompactIndexable` in Grafluent's vertex
   vocabulary), with `index(of:)` and `vertex(at:)`.
3. **README edits this implies:** line 103 (`Sendable` belongs to conforming types, not the
   protocols); line 111 (`Span` cannot be `Successors`); line 315 (`BidirectionalDirectedGraph`
   comes from Boost's `BidirectionalGraph`).
