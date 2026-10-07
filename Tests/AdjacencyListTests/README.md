# AdjacencyList test suite

`AdjacencyList<Vertex: Hashable>` is a directed graph: a set of vertices and a set of directed
edges, each an ordered pair (source, target). Parallel edges are not allowed; self-loops are. This
suite was written before the implementation, so it is the specification. It uses only the public
API.

## API under test

```swift
// GraphProtocols
struct DirectedEdge<Vertex: Hashable>: Hashable  // Sendable, Codable when Vertex is
    init(from source: Vertex, to target: Vertex)
    var source: Vertex, target: Vertex, isSelfLoop: Bool

@resultBuilder enum DirectedGraphBuilder<Vertex>  // accepts DirectedEdge<Vertex> and Vertex expressions

// AdjacencyListModule
struct AdjacencyList<Vertex: Hashable>
    : Hashable, ExpressibleByDictionaryLiteral    // Sendable, Codable when Vertex is

    init()
    init(vertices: some Sequence<Vertex>)
    init(edges: some Sequence<DirectedEdge<Vertex>>)
    init(vertices: some Sequence<Vertex>, edges: some Sequence<DirectedEdge<Vertex>>)
    init<S: Sequence<Vertex>>(adjacency: [Vertex: S])
    init(@DirectedGraphBuilder<Vertex> _: () -> ...)

    var vertexCount: Int
    var edgeCount: Int
    var vertices: some Collection<Vertex>
    var edges: some Collection<DirectedEdge<Vertex>>
    func contains(_: Vertex) -> Bool
    func contains(_: DirectedEdge<Vertex>) -> Bool
    func successors(of: Vertex) -> some Collection<Vertex>     // vertices one edge out
    func predecessors(of: Vertex) -> some Collection<Vertex>   // vertices one edge in
    func outDegree(of: Vertex) -> Int
    func inDegree(of: Vertex) -> Int
    func degree(of: Vertex) -> Int                // outDegree + inDegree

    mutating func insert(_: Vertex) -> (inserted: Bool, memberAfterInsert: Vertex)
    mutating func insert(_: DirectedEdge<Vertex>) -> (inserted: Bool, memberAfterInsert: DirectedEdge<Vertex>)
    mutating func remove(_: Vertex) -> Vertex?
    mutating func remove(_: DirectedEdge<Vertex>) -> DirectedEdge<Vertex>?
    mutating func removeAll(keepingCapacity: Bool = false)
    mutating func removeAllEdges(keepingCapacity: Bool = false)
    mutating func reserveCapacity(vertexCount: Int, edgeCount: Int)
```

The views (`vertices`, `edges`, `successors`, `predecessors`) are values that obey the Collection
laws and are `Sendable` when `Vertex` is. Their concrete types are up to the implementation.

## Conventions

The libraries these cases were drawn from disagree on several points. These are the choices, and
why.

| Question | Choice | Why | Disagreement |
|---|---|---|---|
| Parallel edges | Not allowed; inserting an existing edge returns `inserted: false` | A directed graph's edge set is a set; parallel edges belong to `DirectedMultigraph` | petgraph `Graph` allows them |
| Self-loops | Allowed | Common in practice (NetworkX `DiGraph`, Boost, JGraphT pseudographs) | JGraphT `SimpleDirectedGraph` rejects them |
| A self-loop's contribution | 1 to `edgeCount`, 1 to `outDegree`, 1 to `inDegree`, so 2 to `degree` | Keeps Σ outDegree = Σ inDegree = edgeCount and Σ degree = 2 · edgeCount | Boost `setS` undirected counts it once |
| A self-loop in neighborhoods | v appears once in `successors(of: v)` and once in `predecessors(of: v)` | Neighborhoods are sets | Boost `vecS` lists it twice |
| Inserting an edge with absent endpoints | Inserts the endpoints | Matches `Set.insert` ergonomics; NetworkX does the same | JGraphT throws; petgraph `Graph` panics |
| Removing something absent | Returns `nil`; never traps | Matches `Set.remove` | NetworkX raises |
| Removing an edge with absent endpoints | Returns `nil`; inserts nothing | A removal must not grow the graph | |
| Successors, predecessors or degree of an absent vertex | **Traps** (precondition) | A programming error, like an out-of-bounds index; an empty answer would hide it | petgraph returns empty |
| Equal-but-distinct vertex instances | The first stored instance is kept and returned, including as edge endpoints | Matches `Set.insert`'s `memberAfterInsert` | |
| Dictionary literal with a repeated key | Traps | Matches `Dictionary` | |
| `==` | Equal vertex sets and equal edge sets; independent of insertion order; not isomorphism | Value semantics | NetworkX and petgraph have no structural `==` |
| Iteration order | Unspecified | Leaves the implementation free to optimize; every test is order-insensitive | JGraphT documents insertion order |
| Encoded form (`Codable`) | Unspecified; only round trips are tested | | |

## Files

Every test is self-contained: there are no shared helper functions, and any test can be copied to
another file and still compile. The only shared material is data in `GrafluentTestSupport`: the
named fixtures and the vertex types used to stress `Hashable` (`Collider`, `HashableBox`,
`LifetimeTracked`).

| File | Covers |
|---|---|
| `AdjacencyListConstructionTests.swift` | Initializers, adjacency mappings, literals, single-pass input, independence from input order |
| `AdjacencyListBuilderTests.swift` | The result builder: edges, bare vertices, `for`, `if`, `switch` |
| `AdjacencyListVertexMutationTests.swift` | Inserting and removing vertices, clearing, mutating while iterating |
| `AdjacencyListEdgeMutationTests.swift` | Inserting and removing edges, self-loops, the Boost disconnect sequence |
| `AdjacencyListQueryTests.swift` | Membership, successors and predecessors, degrees, the degree-sum identities, self-loops |
| `AdjacencyListEqualityTests.swift` | `Equatable`/`Hashable` laws over equivalence classes; all 512 directed graphs on 3 vertices |
| `AdjacencyListValueSemanticsTests.swift` | Every kind of mutation leaves an existing copy unchanged |
| `AdjacencyListLifetimeTests.swift` | No leaks; removed vertices are released immediately |
| `AdjacencyListCollectionTests.swift` | Collection laws for every view; views are values; `Sendable` |
| `AdjacencyListModelTests.swift` | Seeded random operation sequences checked step by step against a reference model |
| `AdjacencyListPreconditionTests.swift` | Exit tests for every trapping precondition |
| `AdjacencyListVertexTypeTests.swift` | String, colliding-hash, extreme Int, optional, enum, unit and reference-type vertices |
| `AdjacencyListCodableTests.swift` | JSON and property list round trips |

Case IDs in test names (C-04, V-06, Q-14, ...) refer to the catalog of cases harvested from
NetworkX, petgraph, Boost.Graph and JGraphT; fixtures cite their sources in
`Tests/GrafluentTestSupport/DirectedFixtures.swift`.

Properties that can only be observed internally (whether a no-op mutation copies storage, whether
an empty graph allocates) are performance properties and belong in the benchmarks, not here.
