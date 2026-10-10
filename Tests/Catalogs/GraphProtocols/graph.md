# `Graph` / `UndirectedEdge`: protocol design research

Scope: the undirected protocol `Graph` and the element type `UndirectedEdge<Vertex>` in
`GraphProtocols`, the views between `Graph` and `DirectedGraph`, the first undirected
representation, and the test catalog. Mirrors `protocol-design-directed-graph.md` (DG doc) and the
implemented `DirectedGraph` (laws DG-L01…L28).

Path abbreviations used in citations:

| Prefix | Path |
|---|---|
| `GF:` | the repository root |
| `pg:` | `research/petgraph/crates/petgraph/` |
| `bgl:` | `research/graph/` (Boost.Graph) |
| `lemon:` | `research/lemon/lemon/` |
| `jgt:` | `research/jgrapht/jgrapht-core/src/main/java/org/jgrapht/` |
| `nx:` | `research/networkx/networkx/` |
| `ig:` | `research/igraph/` |
| `rx:` | `research/rustworkx/` |
| `gonum:` | `research/gonum/graph/` |
| `scipy:` | `research/scipy/scipy/sparse/csgraph/` |
| `swift:` | `research/swift/stdlib/public/core/` |

`research/` holds upstream shallow clones (Oct 2026), not kept in the repository.

**(verified)** marks claims compiled and run with Apple Swift 6.2-dev, `-swift-version 6`, against
the real `GF:Sources/GraphProtocols/*.swift`: `proto.swift` (scratch, not kept: protocol, edge,
a Boost-style undirected adjacency list with removal, the directed view, a BFS written against
`DirectedGraph`; all 18 checks print `ok`) and `both.swift` (scratch, not kept: dual conformance
rejected). NetworkX values were computed with NetworkX 3.7.1rc0 from the checkout:
`undirected_calc.py` and `undirected_calc2.py`, next to this file (NetworkX 3.7 prints the same);
`verify.py` checks the fixtures' counts and degrees.

---

## 1. Recommended declaration

```swift
// GraphProtocols

/// An edge of an undirected graph: the unordered pair {u, v}. `UndirectedEdge(1, 2)` and
/// `UndirectedEdge(2, 1)` are equal and hash alike.
///
/// `u` and `v` keep the order they were given in. That order is not part of the value (as a
/// `Set`'s iteration order is not): equal edges may list their endpoints in different orders.
/// Code that needs an endpoint relative to a vertex uses `oppositeVertex(to:)`.
@frozen
public struct UndirectedEdge<Vertex: Hashable>: Hashable {
    public var u: Vertex
    public var v: Vertex
    @inlinable public init(_ u: Vertex, _ v: Vertex)
    @inlinable public var isSelfLoop: Bool { u == v }
    /// The endpoint that is not `vertex`; `vertex` itself for a self-loop.
    /// - Precondition: `vertex` is `u` or `v`.
    @inlinable public func oppositeVertex(to vertex: Vertex) -> Vertex
    // == : (u == u' && v == v') || (u == v' && v == u')
    // hash(into:): the endpoints' hashes h(u), h(v), each from a fresh Hasher, combined as
    //              min(h(u), h(v)) then max(h(u), h(v))
}
extension UndirectedEdge: Comparable where Vertex: Comparable    // by (min(u,v), max(u,v))
extension UndirectedEdge: Sendable where Vertex: Sendable {}
extension UndirectedEdge: BitwiseCopyable where Vertex: BitwiseCopyable {}
extension UndirectedEdge: Encodable where Vertex: Encodable {}  // synthesized, keys u, v
extension UndirectedEdge: Decodable where Vertex: Decodable {}
extension UndirectedEdge: CustomStringConvertible, CustomDebugStringConvertible  // "u–v"

/// An undirected graph: a finite set of vertices and a finite collection of undirected edges.
///
/// **Edges and their identity.** `edges` lists every edge once, each copy of a parallel edge
/// once, a self-loop once. An edge's position in `edges` is its identity: the edge is reachable
/// from both endpoints through `incidentEdges(of:)`, always at that one position, so a value
/// keyed by `Edges.Index` (a weight) is the same in both directions.
///
/// **Counting.** Neighborhoods are counted by edge ends. A vertex `w ≠ v` appears in
/// `neighbors(of: v)` once per edge between them; a self-loop has both its ends at `v`, so `v`
/// appears in `neighbors(of: v)` twice per loop, and the loop's position twice in
/// `incidentEdges(of: v)`. `degree(of:)` is the length of either, so a self-loop counts 2 and the
/// degrees sum to `2 * edgeCount`.
///
/// **Laws.** UG-L01 … UG-L23 below. **Defaults** are requirements, as for `DirectedGraph`.
public protocol Graph<Vertex> {
    associatedtype Vertex: Hashable
    associatedtype Vertices: Collection<Vertex>
    associatedtype Edges: Collection<UndirectedEdge<Vertex>> where Edges.Index: Hashable
    associatedtype Neighbors: Sequence<Vertex>
    associatedtype IncidentEdges: Sequence<Edges.Index>
    associatedtype NeighborIndices: Sequence<Int> = LazyMapSequence<Neighbors, Int>

    var vertices: Vertices { get }
    var edges: Edges { get }

    /// The far end of every edge end at `vertex`, in the order of `incidentEdges(of:)`.
    /// - Precondition: `contains(vertex)` (may trap or return empty; generic code relies on neither).
    func neighbors(of vertex: Vertex) -> Neighbors

    /// The position in `edges` of every edge end at `vertex`: each incident edge once, a self-loop twice.
    /// - Precondition: `contains(vertex)`.
    func incidentEdges(of vertex: Vertex) -> IncidentEdges

    /// The endpoint of the edge at `position` that is not `vertex` (`vertex` for a self-loop).
    /// Default: `edges[position].oppositeVertex(to: vertex)`.
    func oppositeVertex(to vertex: Vertex, acrossEdgeAt position: Edges.Index) -> Vertex

    var vertexCount: Int { get }                         // default vertices.count
    var edgeCount: Int { get }                           // default edges.count
    func contains(_ vertex: Vertex) -> Bool              // default scan; never traps
    func contains(edge: UndirectedEdge<Vertex>) -> Bool  // default: both endpoints, then scan neighbors(of: u); never traps
    func degree(of vertex: Vertex) -> Int                // default: length of neighbors(of:)

    var vertexIndexBound: Int? { get }                   // default nil
    func vertexIndex(of vertex: Vertex) -> Int           // default traps
    func vertex(atIndex index: Int) -> Vertex            // default traps
    func neighborIndices(ofIndex index: Int) -> NeighborIndices  // default: neighbors mapped
}

extension Graph { public var directed: DirectedView<Self> }                         // D13
extension BidirectionalDirectedGraph { public var undirected: UndirectedView<Self> } // D13 (README name)
```

`UndirectedAdjacencyList<Vertex>` (D15), in `AdjacencyListModule`, conforms with every member
its own:

| Member | Cost | How |
|---|---|---|
| `vertices` | O(1) view | dense slots, as `AdjacencyList` (GF:Sources/AdjacencyListModule/AdjacencyList.swift:16-37) |
| `edges` | O(1) view; `Edges.Index == Int`, `0..<m` | dense edge records `(uSlot, vSlot, uOffset, vOffset)`, Boost's `m_edges` |
| `neighbors(of:)` | O(1) | neighbor-slot row, a `_RowPool` (GF:…/RowPool.swift:29) |
| `incidentEdges(of:)` | O(1), `ArraySlice<Int>` | edge-position row, parallel to the neighbor row |
| `oppositeVertex(to:acrossEdgeAt:)` | O(1) | the record's two slots |
| `degree(of:)`, `vertexCount`, `edgeCount` | O(1) | row length, array counts |
| `contains(_:)`, `contains(edge:)` | O(1) hash | slot map; unordered slot-pair → position map |
| `neighborIndices(ofIndex:)` | O(1), `ArraySlice<Int>` | the stored row, as `successorIndices` (AdjacencyList.swift:656) |
| `insert(edge:)` / `remove(edge:)` | O(1) | append to two rows (one row twice for a loop); swap-remove from rows, then move the last record into the hole |
| `remove(_:)` | O(degree) + degree of the moved slot | detach incident edges last-first, rename the last slot |

---

## 2. Decision table

| # | Question | Recommendation | Evidence | Alternatives / risks |
|---|---|---|---|---|
| D1 | Requirements of `Graph` | `vertices`, `edges`, `neighbors(of:)`, `incidentEdges(of:)` without defaults; `oppositeVertex(to:acrossEdgeAt:)`, `vertexCount`, `edgeCount`, `contains(_:)`, `contains(edge:)`, `degree(of:)`, `vertexIndexBound`, `vertexIndex(of:)`, `vertex(atIndex:)`, `neighborIndices(ofIndex:)` with defaults. The exact shape of `DirectedGraph` (GF:Sources/GraphProtocols/DirectedGraph.swift:44-129) with out→incident, successors→neighbors, outDegree→degree, source/target(ofEdgeAt:)→oppositeVertex. No refinement for in-edges. | Boost: on undirected graphs `out_edges(v)` is the incident edges and `out_degree` the incident count (bgl:doc/modules/ROOT/pages/concepts/IncidenceGraph.adoc:67-80; graph_concepts.adoc:109-114); `BidirectionalGraph` is "not an issue" for undirected, since in-edges and out-edges are the same (BidirectionalGraph.adoc:9-11). JGraphT's single `Graph` has `edgesOf`, `degreeOf` (jgt:Graph.java:312-340). LEMON's undirected `Graph` concept: `IncEdgeIt`, `u()`, `v()`, `oppositeNode` (lemon:concepts/graph.h:285-316, 590-612, 704). | `_withNeighborIndexRows` (the CSR fast path, DirectedGraph.swift:124) is deferred until an undirected CSR exists; adding a requirement with a default later is source-compatible. |
| D2 | Name of the incident-edge member | `incidentEdges(of:)`. | Boost's own wording for undirected `out_edges`: "incident edges (for undirected graphs)" (IncidenceGraph.adoc:69); LEMON `IncEdgeIt`, `countIncEdges` (lemon:core.h:425-432); igraph `igraph_incident` (ig:src/graph/type_indexededgelist.c:1750-1766). README already uses `incidentHyperedges(of:)` (GF:README.md:101). | `edges(of:)` is the call in NetworkX `G.edges(v)` (nx:classes/graph.py:1436-1439), petgraph `edges(a)` (pg:src/graph_impl/mod.rs:990) and JGraphT `edgesOf` (jgt:Graph.java:331-340); it reads well, but next to `var edges` it is easy to misread, and a directed reader takes "edges of v" as out-edges. `outEdges(of:)` would claim a direction. |
| D3 | **Self-loops in `neighbors`, `incidentEdges`, `degree`** | **Each loop counts once per end: `v` twice in `neighbors(of: v)`, the position twice in `incidentEdges(of: v)`, `degree` +2.** Law UG-L05/L06/L11: `degree == neighbors.count == incidentEdges.count`, `Σ degree == 2·edgeCount`. | Twice in the incidence list: Boost `adjacency_list<…, undirectedS>` pushes a loop into `out_edge_list(u)` and then `out_edge_list(v)`, the same list (bgl:include/boost/graph/detail/adjacency_list.hpp:1069-1080), and its removal code says "With self loops, the descriptor will show up twice" (:491-501); `degree` is `out_degree` (:1100-1108). LEMON `ListGraph::addEdge` links both arcs of a loop into `u`'s list (lemon:list_graph.h:1042-1068), so `IncEdgeIt` visits it twice. igraph: `IGRAPH_LOOPS_TWICE` "is the standard interpretation in graph theory, thus `IGRAPH_LOOPS` serves as an alias" (ig:include/igraph_constants.h:63-75); neighbors/incident list a loop twice under it (type_indexededgelist.c:869-875, 1760-1766). Degree 2 everywhere: NetworkX (`len(nbrs) + (n in nbrs)`, nx:classes/reportviews.py:713-717; test `G.add_edge(1, 1)` → `degree(1) == 2`, nx:classes/tests/test_graph.py:171-178), JGraphT ("self-loops are counted twice", jgt:Graph.java:315-317; jgt:graph/specifics/UndirectedSpecifics.java:194-215), rustworkx (`count + 2`, rx:src/graph.rs:1202-1211). This keeps the directed rule "degree is the length of the neighborhood" (DG D11; GF:Tests/GraphProtocolsTests/README.md, Conventions "Parallel edges"), and it is what the undirected view of a directed loop gives for free: the loop is in both `successors` and `predecessors`, and `BidirectionalDirectedGraph.degree` already counts it twice (DirectedGraph.swift:149). | **Disagree (loop once in neighbors):** NetworkX `neighbors(0) == [0, 1]` with `degree(0) == 3` for `{0–0, 0–1}` (calc.py); petgraph skips loops on the incoming pass, "make sure we don't double count selfloops" (pg:src/graph_impl/mod.rs:1918-1926, 2081-2084; test `undir_edges = [a, b, c]`, pg:tests/graph.rs:1898-1922); JGraphT `edgesOf` is a `Set` and `neighborListOf` maps it (jgt:Graphs.java:290-299). Each then has `degree ≠ neighbors.count`, the mismatch DG D11 rejected for multigraphs. Boost's own `adjacency_matrix<undirectedS>` lists a loop once (one triangle cell, bgl:include/boost/graph/adjacency_matrix.hpp:631-652, 731-739). **Costs of this choice:** (a) a bit-row matrix needs a custom `Neighbors` that yields the diagonal twice (D18); (b) the directed view must give a loop's two incidences two different arc positions (D13, verified); (c) NetworkX-derived neighbor lists in tests get the loop vertex added once more per loop. |
| D4 | Parallel edges | Allowed by the protocol; a neighbor appears once per copy, `incidentEdges` lists each copy, counts include copies, `contains(edge:)` means at least one copy. Same as DG D11/D12. | petgraph undirected `neighbors(b) == [a, c, a]` (pg:tests/graph.rs:34-59); igraph "the neighbor will be returned multiple times" (ig:src/graph/type_indexededgelist.c:855-857); JGraphT neighbor lists repeat in multigraphs (jgt:Graphs.java:346-348); Boost `allow_parallel_edge_tag` path pushes every copy (adjacency_list.hpp:1055-1056). | NetworkX `MultiGraph([(0,1),(0,1),(0,0)])`: `neighbors(0) == [1, 0]`, `degree(0) == 4` (calc.py): distinct neighbors, counted degree. |
| D5 | What `edges` lists, in which orientation | Every edge once (loops once, each parallel copy once), each in the orientation it was stored with: `edges[e].u`/`.v` are the endpoints in insertion order. `edgeCount` counts loops once. | NetworkX `EdgeView` skips already-seen nodes so each edge is reported once (nx:classes/reportviews.py:1044-1051); K3 + loop has `number_of_edges() == 4` (calc2.py). Boost keeps one `m_edges` entry per undirected edge (adjacency_list.hpp:1069-1071). petgraph `edge_count() == 7` for 7 `add_edge` calls including a loop (pg:tests/graph.rs:34-48). | igraph canonicalizes, storing the larger id as `from` (ig:src/graph/type_indexededgelist.c:282-288); that needs ordered vertices, which `Hashable` does not give. |
| D6 | Edge identity and weights (Q4) | An edge's identity is its single position in `edges`; `incidentEdges(of:)` yields that same position from both endpoints, so `weight(e)` keyed by `Edges.Index` applies in both directions. Positions are valid until mutation. The first representation uses dense `Int` positions `0..<m`, so a weight is an array lookup (README "Weights", GF:README.md:139). | Boost stores the edge once and both incidence entries point at it (`StoredEdge(v, p_iter, &g.m_edges)`, adjacency_list.hpp:1073-1080); "edge properties are shared: `weight(u,v)` and `weight(v,u)` return the same value" (bgl:…/concepts/graph_concepts.adoc:116-119). LEMON edge id is arc id / 2 (list_graph.h:1066, 977-985). petgraph `EdgeReference.index` is the one `EdgeIndex` from either end (pg:src/graph_impl/mod.rs:2066, 2088). | The directed `AdjacencyList` uses `(source slot, offset)` positions (AdjacencyList.swift:433-447) because each directed edge lives in exactly one out-row; an undirected edge lives in two rows (one row twice for a loop), so neither entry can be its identity. |
| D7 | Getting the far end of an incident edge (Q3) | `UndirectedEdge.oppositeVertex(to:)` and the graph requirement `oppositeVertex(to:acrossEdgeAt:)` (default via `edges[position]`). `neighbors(of: v)` is, by law, `incidentEdges(of: v)` mapped through it, in the same order, so an algorithm that needs both iterates them in lockstep (as `successors`/`outEdges` today) and never pays the lookup. | JGraphT `Graphs.getOppositeVertex(g, e, v)`, documented "vertex opposite to v across e" (jgt:Graphs.java:413-435); LEMON `oppositeNode(Node, Edge)` (lemon:concepts/graph.h:701-704); igraph `IGRAPH_OTHER(graph, eid, vid)`, "the other endpoint" (ig:include/igraph_interface.h:129-146). | Boost orients each incidence instead: "the out-edge connecting `u` and `v` must be given as `(u,v)`" (IncidenceGraph.adoc:91-99); petgraph does the same, "with `a` being the source of each edge" (pg:src/graph_impl/mod.rs:1001-1002); NetworkX `G.edges(0)` reports `(0, nbr)` (nx:classes/graph.py:1438-1439). Oriented incidences need an incidence value richer than a position, and two orientations of one edge would then compare unequal as positions, which defeats D6. |
| D8 | `UndirectedEdge` endpoint names and initializer | `u` and `v`; `init(_ u:, _ v:)` unlabeled. | LEMON: "Edges don't have source and target nodes, however, methods `u()` and `v()` are used to query the two end-nodes of an edge" (lemon:concepts/graph.h:590-612). NetworkX's API and docs name the endpoints `u, v` throughout (`add_edge(u, v)`, nx:classes/graph.py; `edges_equal` treats `(u, v)` and `(v, u)` alike for undirected, nx:utils/misc.py:555-600). Swift's guidelines omit labels when arguments are peers, as in `min(x, y)`. | `source`/`target`: Boost, JGraphT (`getEdgeSource` on undirected graphs, jgt:Graphs.java:424-427), petgraph and gonum `From`/`To` (gonum:graph.go:15-29) all reuse directed names. Rejected: `DirectedEdge` already has `source`/`target` (GF:Sources/GraphProtocols/DirectedEdge.swift:5-11), so code moved from directed to undirected would compile and silently drop the direction. |
| D9 | `==`, `hash`, `Comparable` (README row, GF:README.md:120) | Symmetric `==`. Hash: hash each endpoint with a fresh `Hasher`, then combine `min` and `max` of the two values: order-free, no `Comparable` needed, and distinct for `{a, a}` and `{b, b}`. `Comparable` only when `Vertex: Comparable`, by `(min(u, v), max(u, v))`, which agrees with `==` **(verified: `{1,2}` and `{2,1}` are equal, hash alike, neither `<` the other; `[2–0, 1–0, 0–0].sorted() == [0–0, 0–1, 0–2]`)**. Document `u`/`v` order as a non-value aspect. | Swift: "Exposing nonvalue aspects of `Equatable` types … is discouraged, and any that *are* exposed should be explicitly pointed out in documentation" (swift:Equatable.swift:112-117). JGraphT undirected `equals` accepts either endpoint order (jgt:graph/AbstractGraph.java:279-289). `Set` combines members with `^=` (swift:Set.swift:448-460): applied to the two endpoints that maps every self-loop to 0, so not that. | A commutative sum (what `AdjacencyList.hash(into:)` uses over elements, AdjacencyList.swift:503-528) also works but collides more (it is not injective on unordered pairs of hash values); min/max is. Canonicalizing storage (igraph, D5) needs `Comparable`. |
| D10 | Degree, handshake, no in/out | `degree(of:)` is a requirement with default "length of `neighbors`". No `BidirectionalGraph` analogue. | Boost `degree` on undirected = `out_degree` (adjacency_list.hpp:1100-1108); `in_degree` = `degree` (:1125-1129); BidirectionalGraph.adoc:9-11. | — |
| D11 | Dense vertex indices, L27 | Mirror exactly: `vertexIndexBound`, `vertexIndex(of:)`, `vertex(atIndex:)`, `neighborIndices(ofIndex:)` with the same defaults; with indices, `vertices` is in index order (L27 analogue UG-L20) and `neighborIndices` is `neighbors` mapped, same order (UG-L21). | DirectedGraph.swift:26-34, 97-114; the Traversal engine reads `successorIndices` (GF:Sources/Traversal/VertexIdentifiers.swift:44-51), so the directed view forwards `successorIndices` to `neighborIndices` and the engine runs on the stored rows. | — |
| D12 | Absent vertices | `neighbors`, `incidentEdges`, `degree`: precondition `contains(v)` (trap or empty; generic code relies on neither). `contains(_:)`, `contains(edge:)`: never trap, false. Same as DG D9/D10. | NetworkX raises for `neighbors(-1)`, `edges(-1)`, `degree(-1)` and returns false for `has_edge(0, -1)` (nx:classes/tests/test_graph.py:66-74, 116-131); petgraph returns empty (pg:src/graph_impl/mod.rs:895, 964-972); JGraphT throws (jgt:Graph.java:325). | — |
| D13 | Relationship to `DirectedGraph`; views (Q5) | Separate protocols, no type conforms to both **(verified: `struct Both: Graph, DirectedGraph` fails, `edges` cannot be both element types)**. Two lazy views, named after the README's `undirected` (GF:README.md:82, 204) and NetworkX's "directed view" / "undirected view" (nx:classes/function.py:577-595): **`graph.directed: DirectedView<Base>`** (each edge as two opposite arcs, loops included: `edgeCount == 2m`, `outDegree == degree`, `successors == neighbors`, `successorIndices == neighborIndices`; `Edges.Index` = (base position, reversed); a loop's first incidence is the forward arc and its second the reversed arc, so every arc is in `outEdges` exactly once; conforms to `BidirectionalDirectedGraph` with `predecessors == neighbors`). **`digraph.undirected: UndirectedView<Base>`** for `Base: BidirectionalDirectedGraph` (`neighbors` = `successors` then `predecessors`, `incidentEdges` = `outEdges` then `inEdges`, `Edges.Index == Base.Edges.Index`, `degree == Base.degree`; reciprocal arcs become parallel edges, a directed loop a loop of degree 2). Both forward every requirement (README wrapper rule). **(verified: the directed view satisfies DG-L19–L21 with the loop as two arcs `0→0, 0→0`; a BFS written against `DirectedGraph` gives `{2:0, 1:1, 0:2}` through it.)** | Two arcs per edge: LEMON's undirected graphs "also fulfill the concept of Digraph, since each edge can also be regarded as two oppositely directed arcs" (lemon:concepts/graph.h:48-60); NetworkX `to_directed` replaces each edge by `(u, v)` and `(v, u)` (nx:classes/graph.py:1680-1720); rustworkx `to_directed` adds both arcs for every edge, loops included (rx:src/graph.rs:1240-1246). Undirected view: JGraphT `AsUndirectedGraph` "will be a multigraph" unless the digraph is oriented (jgt:graph/AsUndirectedGraph.java:26-39); petgraph `UndirectedAdaptor` (pg:src/visit/undirected_adaptor.rs:10-12); gonum `Undirect` (gonum:undirect.go:7-8). | NetworkX `to_directed()` of `{0–0, 0–1, 1–2}` has 5 arcs (one `0→0`, because a `DiGraph` is simple) and `to_undirected()` of reciprocal arcs collapses them (calc2.py: 3 edges, all degrees 2). A concrete conversion (`AdjacencyList(g.directed)`, `UndirectedAdjacencyList(d.undirected)`) collapses the same way, so the materialized results match NetworkX; only the lazy views keep copies. CSR is not bidirectional, so it has no `undirected` view; `UndirectedAdjacencyList(vertices:edges:)` with mapped edges converts it. |
| D14 | Reuse traversal or duplicate it? | **BFS, layers, reachability, BFS distances: reuse through `directed`** (a forwarding `extension Graph { func breadthFirstSearch(from:) }` returning the directed search over the view). The view is generic and `@inlinable`, `successorIndices` is the stored neighbor row, so the specialized engine is the hand-written loop (benchmark UG-B01). **DFS edge classification, bridges, cut vertices, biconnected components, Euler tours: undirected-specific** code in index space over `incidentEdges` positions, since each needs edge identity. Connected components: union–find over `edges` (as `_joinEndpoints`, GF:Sources/Connectivity/WeaklyConnectedComponents.swift:3-45) or BFS over the view. | Boost runs one `breadth_first_search` for "a directed or undirected graph" (bgl:doc/modules/ROOT/pages/algorithms/traversal/breadth_first_search.adoc:4, 39) but a separate `undirected_dfs` that colors **edges** so a tree edge's reverse is not a back edge (bgl:include/boost/graph/undirected_dfs.hpp:70-100; `forward_or_cross_edge` "in an undirected graph … is never called", depth_first_search.adoc:275-276). Computed: CLRS DFS over `K4.to_directed()` from 0 classifies 3 tree, **6 back, 3 forward** arcs, while undirected DFS has 3 tree and 3 back edges (calc2.py). NetworkX `bridges` must special-case multigraphs because a doubled edge is never a bridge (nx:algorithms/bridges.py:44-49; `MultiGraph([(0,1),(1,2),(1,2)])` → `[(0, 1)]`, calc2.py). JGraphT and gonum share traversal by giving undirected graphs the directed accessor (jgt:traverse/CrossComponentIterator.java:319-322; gonum:graph.go:50-54). | Duplicating BFS for `Graph` would double the code and the test surface for identical behavior. A package-internal "index adjacency" protocol under `IndexSpaceSearch` (GF:Sources/Traversal/IndexSpaceSearch.swift:13) is the fallback if a benchmark shows the view costs anything. **Naming risk:** Traversal and Connectivity name generic parameters `Graph` (11 places, e.g. BreadthFirstSearch.swift:12); this compiles **(verified)** but shadows the protocol inside those types, so an extension there needs `GraphProtocols.Graph`. |
| D15 | First representation: name, semantics, storage (Q6) | **`UndirectedAdjacencyList<Vertex: Hashable>`**: no parallel edges, self-loops allowed, the undirected twin of `AdjacencyList` (which is "self-loops are allowed, parallel edges are not", AdjacencyList.swift:3-6). Storage as in §1 (Boost's `m_edges` plus two incidence entries, D6), rows in the existing `_RowPool`. Same API shape: `init()`, `init(vertices:)`, `init(edges:)`, `init(vertices:edges:)`, `@GraphBuilder` init, `insert(_:)`, `insert(edge:) -> (inserted, memberAfterInsert)`, `remove(_:)`, `remove(edge:)`, `removeAll`, `removeAllEdges`, `reserveCapacity`, `init(_ graph: some Graph<Vertex>)`. **(verified: insert, edge removal including loops, vertex removal with an incident loop and a moved slot that has a loop, all keep the laws)** | Simple-with-loops is the default undirected class in NetworkX (`Graph`), JGraphT (`DefaultUndirectedGraph`: no parallel edges, loops allowed, jgt:graph/DefaultUndirectedGraph.java:25-28) and petgraph `GraphMap` ("does not allow parallel edges, but self loops are allowed", pg:src/graphmap.rs:68). Boost's class with this storage is `adjacency_list<…, undirectedS>` (and `undirected_graph`, bgl:include/boost/graph/undirected_graph.hpp:35). | Name alternatives: `Graph` (NetworkX's class) collides with the protocol; petgraph's `UnGraph` (pg:src/graph_impl/mod.rs:408) abbreviates; JGraphT's `SimpleGraph` excludes loops (jgt:graph/SimpleGraph.java:25-30). Renaming the existing type to `DirectedAdjacencyList` so the undirected one could be `AdjacencyList` would mirror `DirectedGraph`/`Graph` but breaks the shipped API (open item 2). |
| D16 | Module placement; `Multigraph` clash | Put `UndirectedAdjacencyList` in `AdjacencyListModule` (one family, shares `_RowPool`, like `OrderedSet`/`OrderedDictionary` in one module). **Rename the test conformer `GrafluentTestSupport.Multigraph`** (a *directed* multigraph, GF:Tests/GrafluentTestSupport/Multigraph.swift:10, used by 17 test files) before `Multigraphs` ships, and add an undirected test conformer with loops and parallel edges for the UG laws. | The planned `Multigraphs` module holds `Multigraph`, `DirectedMultigraph`, `Pseudograph` (GF:scripts/modules.py:41; README.md:190-191). In JGraphT `Multigraph` is undirected with no loops and `Pseudograph` allows both (jgt:graph/Multigraph.java:25-29; Pseudograph.java:25-28), so the test type's name contradicts both meaning and the future type, and a test importing both modules will hit an ambiguous `Multigraph`. | Suggested test names: `ReferenceDirectedMultigraph` and `ReferencePseudograph` (open item 3). |
| D17 | Equality and hashing of the representation (Q7) | Equal vertex sets and equal edge sets, with `UndirectedEdge`'s symmetric equality: insertion order and stored orientation do not matter. Hash: count-prefixed commutative sums of per-vertex and per-edge (symmetric) hashes, as `AdjacencyList` does. Fast path when the slot arrays are equal. **(verified: `{2–2, 2–0}` equals the graph left after removals from `{0–0, 0–1, 0–2, 2–2}`.)** | README: "equality means equal vertex sets and equal edge sets … must not depend on the order edges were inserted" (GF:README.md:165); AdjacencyList.swift:481-528. NetworkX `graphs_equal` compares `adj` and `nodes` (nx:utils/misc.py:636-653); JGraphT compares vertex and edge sets with either endpoint order (jgt:graph/AbstractGraph.java:237-289). | — |
| D18 | Later undirected counterparts | (1) **Undirected adjacency matrix**: lower-triangle bits, as Boost (`m_matrix[u * (u + 1) / 2 + v]`, adjacency_matrix.hpp:631-652); one cell per edge = one position; `Neighbors` walks row/column bits and yields the diagonal twice (D3). (2) **Symmetric CSR**: each edge in both rows plus an `m`-sized entry→edge map; Boost has none yet ("undirected CSR graphs will also be supported", bgl:include/boost/graph/compressed_sparse_row_graph.hpp:243-246); scipy reads one matrix as undirected via `directed=False` (scipy:_shortest_path.pyx:104). Brings `_withNeighborIndexRows`. (3) **Edge list**: `[UndirectedEdge<V>]` is already Kruskal's input; no new type until a need appears. | — | Order: the matrix after the first algorithms that want dense undirected adjacency (coloring, cliques); CSR with the first large-graph undirected algorithm. |
| D19 | Builder, description, `Codable` | `GraphBuilder<Vertex>` beside `DirectedGraphBuilder` (same `Content` shape with `[UndirectedEdge]`, the vertex overload `@_disfavoredOverload`, DirectedGraphBuilder.swift:31-37). Description `u–v`; graphs print `[0, 1, 2]; [0–1, 1–2]` through a `GraphDescription.edge(_: UndirectedEdge)` overload. `Codable` synthesized, which keeps orientation. | README construction row `@GraphBuilder` (GF:README.md:152); DOT writes undirected edges as `--`. | `↔` would suggest two arcs, the model D13 rejects. |
| D20 | Test organization | As DG D20: laws per representation in `<Type>GraphTests.swift`; defaults, dispatch, views and generic algorithms in `Tests/GraphProtocolsTests` (`GraphDefaultTests`, `GraphLawTests`, `GraphConformanceTests`, `GraphAlgorithmTests`); each law a local generic function inside its test. | GF:Tests/GraphProtocolsTests/README.md; memory: public API only, self-contained tests. | — |

---

## 3. Test catalog

Notation: `UAL` is `UndirectedAdjacencyList`; `RP` the undirected reference conformer
(pseudograph: edges as written, loops and copies kept, D16); `F.x` is
`UndirectedFixture<Int>.x` (new, written with `GraphBuilder`, each citing its source).
"Generic" means read through a local `func f<G: Graph>(_ g: G)`. Laws run over `UAL` and `RP`
for every fixture; `UAL` collapses written repeats. Edges below are written `a–b`.

### 3.0 Fixtures (`UndirectedFixture`)

| Name | Edges | n / m (UAL) | Degrees | Source |
|---|---|---|---|---|
| `empty` | — | 0 / 0 | — | definition |
| `trivial` | vertex 0 | 1 / 0 | `[0:0]` | definition |
| `singleSelfLoop` | 0–0 | 1 / 1 | `[0:2]` | nx test_graph.py:171-178 |
| `isolatedVertices` | vertices 0…9 | 10 / 0 | all 0 | definition |
| `k3` | 0–1, 0–2, 1–2 | 3 / 3 | all 2 | nx test_graph.py:661-668, 125-131 |
| `k3WithLoop` | k3 + 0–0 | 3 / 4 | `[0:4, 1:2, 2:2]` | nx test_graph.py:180-185; calc2.py |
| `loopAndPath` | 0–0, 0–1, 1–2 | 3 / 3 | `[0:3, 1:2, 2:1]` | calc.py |
| `petgraphUndirected` | a–b, a–c, c–a, a–a, b–c, b–a, a–d (a…d = 0…3) | 4 / 5 (RP: 7) | UAL `[0:5, 1:2, 2:2, 3:1]`; RP `[0:7, 1:3, 2:3, 3:1]` | pg:tests/graph.rs:34-71; nx `MultiGraph` degrees (calc.py) |
| `components7` | vertices 0…6; 0–1, 1–2, 3–4 | 7 / 3 | `[0:1, 1:2, 2:1, 3:1, 4:1, 5:0, 6:0]` | calc2.py |
| `path4` | 0–1, 1–2, 2–3 | 4 / 3 | `[0:1, 1:2, 2:2, 3:1]` | nx `path_graph(4)` |
| `cycle5` | 0–1, 1–2, 2–3, 3–4, 0–4 | 5 / 5 | all 2 | nx `cycle_graph(5)` |
| `k4` | all pairs of 0…3 | 4 / 6 | all 3 | nx `complete_graph(4)` |
| `house` | 0–1, 0–2, 1–3, 2–3, 2–4, 3–4 | 5 / 6 | `[0:2, 1:2, 2:3, 3:3, 4:2]` | nx:generators/small.py:495 |
| `petersen` | 0–1, 0–4, 0–5, 1–2, 1–6, 2–3, 2–7, 3–4, 3–8, 4–9, 5–7, 5–8, 6–8, 6–9, 7–9 | 10 / 15 | all 3 | nx:generators/small.py:746 |
| `cube` | 0–1, 0–2, 0–4, 1–3, 1–5, 2–3, 2–6, 3–7, 4–5, 4–6, 5–7, 6–7 | 8 / 12 | all 3 | nx:generators/lattice.py:159, labels sorted |
| `karate` | Zachary's 78 edges | 34 / 78 | `[0:16, 1:9, 2:10, 3:6, 4:3, 5:4, 6:4, 7:4, 8:5, 9:2, 10:3, 11:1, 12:2, 13:5, 14:2, 15:2, 16:2, 17:2, 18:2, 19:3, 20:2, 21:2, 22:2, 23:5, 24:3, 25:3, 26:2, 27:4, 28:3, 29:4, 30:4, 31:6, 32:12, 33:17]` | nx:generators/social.py:16 |
| `parallelPath` (RP only) | 0–1, 1–2, 1–2 | 3 / 3 | `[0:1, 1:3, 2:2]` | calc2.py (`MultiGraph`) |

Expected neighbor lists from NetworkX are adjusted by D3: the loop vertex is added once more per loop.

### 3.1 Laws (any conformer)

| ID | Law | DG analogue |
|---|---|---|
| UG-L01 | `vertexCount == vertices.count`; vertices distinct | L01 |
| UG-L02 | `edgeCount == edges.count` (each edge once, loop once, each copy once) | L02 |
| UG-L03 | every `v` in `vertices` has `contains(v)`; both endpoints of every edge are vertices | L03 |
| UG-L04 | for each `v`: multiset of `neighbors(of: v)` == multiset over `edges` of: `w` for each `{v, w}` with `w ≠ v`, and `v, v` for each `{v, v}` | L04 |
| UG-L05 | `degree(of: v) == Array(neighbors(of: v)).count == Array(incidentEdges(of: v)).count` | L05 |
| UG-L06 | handshake: `Σ degree == 2 · edgeCount` | L06, L12 |
| UG-L07 | for `u, v` in `vertices`: `contains(edge: u–v) == contains(edge: v–u) == edges.contains(u–v) == neighbors(of: u).contains(v)` | L07 |
| UG-L08 | `contains(edge:)` with an absent endpoint is false, no trap (`-1`, or `"∅"`) | L08 |
| UG-L09 | `contains(x)` for absent `x` is false, no trap | L09 |
| UG-L10 | symmetry: for `u ≠ v`, `u` occurs in `neighbors(of: v)` as often as `v` in `neighbors(of: u)` | L13 |
| UG-L11 | each loop copy at `v` puts `v` twice in `neighbors(of: v)` and its position twice in `incidentEdges(of: v)` | L14 |
| UG-L12 | simple conformers (UAL): `Set(edges).count == edgeCount`; `neighbors(of: v)` repeats only `v`, exactly twice when `v–v` exists | L15 |
| UG-L13 | generic == concrete for `vertexCount`, `edgeCount`, `contains`, `contains(edge:)`, `degree`, `oppositeVertex` on every vertex/edge | L16 |
| UG-L14 | generic counts and degrees == fixture's | L17 |
| UG-L15 | `neighbors(of:)` and `incidentEdges(of:)` asked twice are equal (multi-pass) | L18 |
| UG-L16 | for each `e` in `incidentEdges(of: v)`: `edges[e]` has `v` as an endpoint, and `incidentEdges(of: v).map { oppositeVertex(to: v, acrossEdgeAt: $0) } == Array(neighbors(of: v))` | L19, L20 |
| UG-L17 | over all vertices, each position occurs exactly twice in the incident lists: once at each end of a non-loop, twice at a loop's vertex; the positions seen are exactly `Set(edges.indices)` | L21 |
| UG-L18 | `oppositeVertex(to: oppositeVertex(to: v, acrossEdgeAt: e), acrossEdgeAt: e) == v` | — |
| UG-L19 | indices map `vertices` one-to-one onto `0..<vertexIndexBound`, `vertex(atIndex: vertexIndex(of: v)) == v` | L22 |
| UG-L20 | with indices, `vertices.map(vertexIndex) == Array(0..<n)` | L27 |
| UG-L21 | `Array(neighborIndices(ofIndex: vertexIndex(of: v))) == neighbors(of: v).map(vertexIndex)` | successorIndices law |
| UG-L22 | `vertices` and `edges` equal when asked again | L23 |
| UG-L23 | stored orientation is stable: `edges[e].u` and `.v` read twice are identical, not merely `==` | — |
| UG-P01 | seeded random graphs (n ∈ 1…30, ≤ 3n edges, loops and repeats allowed): `UAL` observed generically equals `RP(Set(edges))` observed the same way (counts, sorted neighbors, degrees, adjacency row), as DG-P01 | P01 |

### 3.2 `UndirectedEdge` cases

| ID | Case | Expected |
|---|---|---|
| UG-E01 | symmetric `==`/hash | `UndirectedEdge(1, 2) == UndirectedEdge(2, 1)`, equal `hashValue` **(verified)** |
| UG-E02 | `Set` dedup | `Set([1–2, 2–1, 1–1]).count == 2` **(verified)** |
| UG-E03 | loops are distinct values | `0–0 != 1–1`; `Set((0..<100).map { UndirectedEdge($0, $0).hashValue }).count == 100` (an xor combination would give 1) |
| UG-E04 | non-edges differ | `3–3 != 3–4`; `1–2 != 1–3` |
| UG-E05 | `isSelfLoop` | `2–2` true, `2–3` false |
| UG-E06 | `oppositeVertex(to:)` | `(1–2).oppositeVertex(to: 1) == 2`, `(to: 2) == 1`, `(5–5).oppositeVertex(to: 5) == 5`; exit test: `(1–2).oppositeVertex(to: 3)` traps |
| UG-E07 | `Comparable` | neither `1–2 < 2–1` nor `2–1 < 1–2`; `[2–0, 1–0, 0–0].sorted() == [0–0, 0–1, 0–2]` **(verified)** |
| UG-E08 | orientation kept | `UndirectedEdge(2, 1).u == 2`, `.v == 1` |
| UG-E09 | description | `"\(UndirectedEdge(1, 2))" == "1–2"`; `String(reflecting: UndirectedEdge("a", "b")) == "\"a\"–\"b\""` |
| UG-E10 | `Codable` | JSON round trip gives `u == 2, v == 1` for `UndirectedEdge(2, 1)` |
| UG-E11 | conditional conformances | `UndirectedEdge<Int>` is `Sendable` and `BitwiseCopyable`; with a non-`Sendable` class vertex it still compiles as `Hashable` |

### 3.3 Per-representation cases (`UndirectedAdjacencyList`, generic unless noted)

| ID | Case | Expected |
|---|---|---|
| UG-R01 | `F.empty` | `vertexCount 0`, `edgeCount 0`, `contains(0) == false`, `contains(edge: 0–0) == false` |
| UG-R02 | `F.trivial` | `neighbors(of: 0) == []`, `degree 0`, `incidentEdges == []` |
| UG-R03 | `F.singleSelfLoop` | `edges == [0–0]`, `edgeCount 1`, `neighbors(of: 0) == [0, 0]`, `incidentEdges(of: 0) == [0, 0]`, `degree 2`, `contains(edge: 0–0)` (nx degree 2; nx neighbors `[0]`) |
| UG-R04 | `F.k3` (nx BaseGraphTester) | `neighbors(of: 0).sorted() == [1, 2]`; incident edges of 0 read back as `{0–1, 0–2}`; degrees all 2; `edgeCount 3`; `contains(edge: 1–0)`; `contains(edge: 0–(-1)) == false` (nx test_graph.py:66-74, 116-131) |
| UG-R05 | `F.k3WithLoop` | degrees `[0:4, 1:2, 2:2]`, `edgeCount 4`, `neighbors(of: 0).sorted() == [0, 0, 1, 2]` |
| UG-R06 | `F.loopAndPath`, insertion order | `neighbors(of: 0) == [0, 0, 1]`, `incidentEdges(of: 0) == [0, 0, 1]`, degrees `[3, 2, 1]`, `Σ == 6` **(verified)**; nx: `neighbors(0) == [0, 1]`, `degree(0) == 3` |
| UG-R07 | `F.petgraphUndirected` | `edgeCount 5`, degrees `[0:5, 1:2, 2:2, 3:1]`, `neighbors(of: 1).sorted() == [0, 2]`; after `remove(0)`: `vertexCount 3`, `edgeCount 1`, `edges == [1–2]`, `neighbors(of: 1) == [2]` (petgraph asserts `edge_count() == 1`, `neighbors(b) == [c]`, pg:tests/graph.rs:61-63) |
| UG-R08 | remove a vertex with an incident loop | `F.loopAndPath` `.remove(0)` returns `0`; `vertices` `{1, 2}`, `edges == [1–2]`, `degree(of: 1) == 1` (nx: edges `[(1, 2)]`) **(verified)** |
| UG-R09 | remove a loop, then a vertex so a slot with a loop moves | `{0–0, 0–1, 0–2, 2–2}`: `remove(edge: 0–0)` → `edgeCount 3`, `degree(of: 0) == 2`; then `remove(1)` → `edgeCount 2`, `degree(of: 2) == 3`, `neighbors(of: 2).sorted() == [0, 2, 2]`; all UG laws hold after each step **(verified)** |
| UG-R10 | reversed duplicate insert | after `insert(edge: 0–1)`, `insert(edge: 1–0)` returns `(false, 0–1)` with `.u == 0`; `edgeCount` unchanged; `remove(edge: 1–0)` returns `0–1` (stored orientation) **(verified)** |
| UG-R11 | positions | `Array(edges.indices) == Array(0..<edgeCount)`; after `remove(edge:)` the laws (UG-L16, L17) still hold over the new positions |
| UG-R12 | `F.petersen`, `F.cube` | `(10, 15)`, `(8, 12)`, every degree 3, `Set(edges)` equals the fixture list |
| UG-R13 | `F.karate` | `vertexCount 34`, `edgeCount 78`, degrees as §3.0 |
| UG-R14 | `F.isolatedVertices` | `vertexCount 10`, `edgeCount 0`, all degrees 0 |
| UG-R15 | exit tests: absent vertex | on `UAL(F.k3)`: `neighbors(of: 99)`, `incidentEdges(of: 99)`, `degree(of: 99)`, `vertexIndex(of: 99)` trap; `oppositeVertex(to: 2, acrossEdgeAt: 0)` (edge `0–1`) traps |
| UG-R16 | equality | `UAL(edges: [0–1, 1–2]) == UAL(edges: [2–1, 1–0])` and equal hashes; `!=` after adding isolated vertex 3; `!=` with `0–0` added; `UAL(edges: [0–1]) != UAL(edges: [0–2])` |
| UG-R17 | value semantics | `var b = a; b.insert(edge: 5–6)`: `a` unchanged, `a.edgeCount` as before |
| UG-R18 | description | `UAL(vertices: [0, 1, 2], edges: [0–1, 1–2]).description == "[0, 1, 2]; [0–1, 1–2]"` |
| UG-R19 | `Codable` | round trip of `F.k3WithLoop` is `==` |
| UG-R20 | dictionary literal | `["a": ["b"], "b": ["a"]]` has `edgeCount 1` |

### 3.4 Type-level and API shape

| ID | Case | Expected |
|---|---|---|
| UG-T01 | associated types | `UAL<Int>.IncidentEdges == ArraySlice<Int>`, `.NeighborIndices == ArraySlice<Int>`, `.Edges.Index == Int`, `.Neighbors == UAL<Int>.Neighbors` |
| UG-T02 | `some Graph<Int>` | accepts `UAL`, `RP` and `AdjacencyList(DirectedFixture.house).undirected`; a local `count` returns `edgeCount` (6, 6, 7) |
| UG-T03 | `any Graph<Int>` | `[UAL(F.house), RP(F.house), AdjacencyList(UAL(F.house).directed).undirected]`: `edgeCount` 6, 6, 12 (each edge's two arcs become two parallel edges); `Set(neighbors(of: 2)) == [0, 3, 4]` through each |
| UG-T04 | `Graph & Sendable` | accepts `UAL<Int>`; result sendable to a `Task` |
| UG-T05 | no dual conformance | `(UAL<Int>() as Any) is any DirectedGraph == false`; `(AdjacencyList<Int>() as Any) is any Graph == false`; a type conforming to both does not compile **(verified)** |
| UG-T06 | defaults through minimal conformers | single-pass `MinimalSequence` neighbors: default `degree` counts, default `contains(edge:)` false for an absent endpoint without trapping, default `oppositeVertex` reads `edges` |
| UG-T07 | dispatch | a conformer counting calls to its own `degree`/`contains(edge:)` is reached from generic code, a second generic layer, and `any Graph` (as DirectedGraphDefaultTests) |
| UG-T08 | builder | `UAL<Int> { for i in 0..<5 { UndirectedEdge(i, (i + 1) % 5) }; 99 }` has `vertexCount 6`, `edgeCount 5`; `UAL<UndirectedEdge<Int>> { UndirectedEdge(1, 2) }` reads the expression as an edge (disfavored vertex overload) |
| UG-T09 | Comparable only when possible | `UndirectedEdge<Int>` is `Comparable`; `UndirectedEdge<AnyHashable>` is not (`is any Comparable == false`) |

### 3.5 Generic algorithms (test-local, against `Graph`; expected from NetworkX)

| ID | Algorithm / fixture | Expected | Types |
|---|---|---|---|
| UG-A01 | BFS distances from 0 | `petersen {0:0, 1:1, 4:1, 5:1, 2:2, 3:2, 6:2, 7:2, 8:2, 9:2}`; `cube {0:0, 1:1, 2:1, 4:1, 3:2, 5:2, 6:2, 7:3}`; `house {0:0, 1:1, 2:1, 3:2, 4:2}`; `karate {0:0; 1–8, 10–13, 17, 19, 21, 31:1; 9, 16, 24, 25, 27, 28, 30, 32, 33:2; 14, 15, 18, 20, 22, 23, 26, 29:3}` | UAL, RP |
| UG-A02 | BFS layers from 0 (`bfs_layers`) | `petersen [[0],[1,4,5],[2,3,6,7,8,9]]`; `cube [[0],[1,2,4],[3,5,6],[7]]`; `cycle5 [[0],[1,4],[2,3]]` | UAL, RP |
| UG-A03 | DFS preorder, ascending neighbors | `petersen [0,1,2,3,4,9,6,8,5,7]`; `cube [0,1,3,2,6,4,5,7]`; `house [0,1,3,2,4]`; `karate [0,1,2,3,7,12,13,33,8,30,32,14,15,18,20,22,23,25,24,27,31,28,29,26,9,19,17,21,4,6,5,10,16,11]` | UAL, RP |
| UG-A04 | connected components (union–find over `edges`) | `components7 {{0,1,2},{3,4},{5},{6}}`, 4; `petersen`, `karate` 1 | UAL, RP |
| UG-A05 | undirected DFS edge classes by position (Boost `undirected_dfs`) | `k4` from 0: 3 tree, 3 back (= m − n + c); `singleSelfLoop`: 0 tree, 1 back; RP `{0–1, 0–1}`: 1 tree, 1 back. Contrast: CLRS on `UAL(k4).directed`: 3 tree, 6 back, 3 forward (calc2.py) | UAL, RP |
| UG-A06 | bridges by edge position | `path4 {0–1, 1–2, 2–3}`; `karate {0–11}`; `petersen`, `cube`, `house`, `k4`, `cycle5` none; RP `parallelPath {0–1}` (nx `MultiGraph` → `[(0, 1)]`) | UAL, RP |
| UG-A07 | Euler circuit condition (connected, all degrees even) using `degree` | `singleSelfLoop` true; `k3WithLoop` true (4, 2, 2); RP `{0–1, 1–2, 2–0, 0–1}` false (3, 3, 2); `cycle5` true; `k4` false (nx `is_eulerian`) | UAL, RP |
| UG-A08 | bipartite 2-coloring by BFS | `cube`, `path4` true; `petersen`, `cycle5`, `k4`, `house`, `singleSelfLoop` false | UAL, RP |
| UG-A09 | the same through `any Graph<Int>` | UG-A01 and UG-A04 values | all |

### 3.6 Views and conversions

| ID | Case | Expected |
|---|---|---|
| UG-C01 | `directed` view laws, every fixture | `vertexCount == n`, `edgeCount == 2m`, `outDegree(of: v) == degree(of: v)`, `successors == neighbors`, `successorIndices == neighborIndices`, DG-L19–L21 (every arc once in `outEdges`), `edges[a]` is the base edge or its reverse, `contains(edge: u→v) == contains(edge: v→u) == base.contains(edge: u–v)` |
| UG-C02 | `directed` exact | `UAL(F.loopAndPath).directed`: `Array(edges) == [0→0, 0→0, 0→1, 1→0, 1→2, 2→1]`, `edgeCount 6` **(verified)**; `AdjacencyList(that view)` has 5 edges `{0→0, 0→1, 1→0, 1→2, 2→1}`, NetworkX `to_directed()`'s 5 |
| UG-C03 | `directed` is bidirectional | `predecessors(of: v) == neighbors(of: v)`; `inDegree == degree`; `degree(of: v) == 2 · base.degree(of: v)`; Kosaraju on it gives the connected components of UG-A04 |
| UG-C04 | Traversal through the view | `UAL(F.petersen).breadthFirstSearch(from: 0)` distances == UG-A01 |
| UG-C05 | `undirected` view of `AdjacencyList(DirectedFixture.house)` | degrees `{0:2, 1:3, 2:2, 3:3, 4:3, 5:1}`; BFS from 5 `{5:0, 3:1, 2:2, 4:2, 0:3, 1:3}`; 1 component (nx `to_undirected`) |
| UG-C06 | reciprocal arcs stay parallel in the view | `DirectedFixture.triangleWithReciprocalEdge`: view `edgeCount 4`, degrees `{1:3, 2:3, 3:2}` (JGraphT `AsUndirectedGraph`: multigraph); `UAL(view)` collapses to `edgeCount 3`, degrees all 2 (nx `to_undirected`) |
| UG-C07 | directed loops in the view | `AdjacencyList(DirectedFixture.selfLoopsAndDuplicates).undirected`: degrees `{1:1, 2:4, 3:1, 4:3, 5:3}` == base `degree`; `neighbors(of: 4)` contains 4 twice; `Σ degree == 12 == 2 · 6` |
| UG-C08 | view positions | `undirected` view's `Edges.Index == AdjacencyList.Edges.Index`; a weight dictionary keyed by base positions gives the same value from `incidentEdges` of both ends |
| UG-C09 | round trips over every fixture | `UAL(AdjacencyList(ual.directed).undirected) == ual`; `UAL(ual) == ual` |
| UG-C10 | conversion from a pseudograph | `UAL(RP(F.petgraphUndirected))` has `edgeCount 5` (copies collapse, loop kept), `== UAL(F.petgraphUndirected)` |
| UG-C11 | CSR to undirected | `UAL(vertices: csr.vertices, edges: csr.edges.map { UndirectedEdge($0.source, $0.target) })` for `DirectedFixture.house` equals UG-C05's collapsed graph |

### 3.7 Benchmarks, not tests

| ID | Measurement |
|---|---|
| UG-B01 | BFS from 0 on Graph500 scale 8 read as undirected (GF:Tests/GrafluentTestSupport/RealWorldFixtures.swift:45-46) and on karate: hand-written loop over `neighborIndices` vs `breadthFirstSearch` through `directed` vs `any Graph`. Expect the first two equal under `-O` |
| UG-B02 | `degree(of:)` and `contains(edge:)` through generic code on a hub of degree 20,000: O(1), not the default scans |
| UG-B03 | `remove(_:)` of the hub: O(degree) |
| UG-B04 | copying a 100k-edge `UAL` copies a constant number of buffers; building it takes O(log) row-pool allocations, as `AdjacencyList` (GF:README.md:169) |

---

## 4. Open items for the user

1. **Self-loop convention (D3).** Recommended: a loop appears twice in `neighbors` and
   `incidentEdges` (Boost adjacency_list, LEMON, igraph's default), so `degree ==
   neighbors.count` holds everywhere. NetworkX, JGraphT and petgraph list it once.
2. **Type name (D15).** `UndirectedAdjacencyList`, or rename the shipped `AdjacencyList` to
   `DirectedAdjacencyList` and give the undirected one the plain name.
3. **Test conformer rename (D16).** `GrafluentTestSupport.Multigraph` is directed and clashes
   with the planned undirected `Multigraphs.Multigraph`. Proposed: `ReferenceDirectedMultigraph`,
   plus a new `ReferencePseudograph`.
4. **Endpoint names `u`/`v` (D8)** and the `–` glyph (D19).
5. **View names (D13):** `directed` / `DirectedView` and `undirected` / `UndirectedView`. This
   settles README open question 8 (GF:README.md:316), which floated `asDirected`/`asUndirected`.
6. **Generic parameters named `Graph`** in Traversal and Connectivity shadow the new protocol
   (D14). They compile, but renaming them to `G` makes later `extension Graph` code there simpler.
7. **README edits:** line 98 (the `Graph` sketch becomes §1's requirements); line 120 (hashing is
   min/max of the endpoint hashes, no `Comparable`); line 316 (views decided).
