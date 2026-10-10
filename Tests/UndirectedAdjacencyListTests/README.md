# UndirectedAdjacencyList test suite

`UndirectedAdjacencyList<Vertex: Hashable>` is an undirected graph: a set of vertices and a set of
undirected edges, each an unordered pair {u, v}. Parallel edges are not allowed; self-loops are. It
is the undirected twin of `AdjacencyList`, in the same module. This suite was written before the
implementation, so it is the specification. It uses only the public API.

## API under test

```swift
// GraphProtocols
struct UndirectedEdge<Vertex: Hashable>: Hashable  // Sendable, Codable, Comparable when Vertex is
    init(_ u: Vertex, _ v: Vertex)
    var u: Vertex, v: Vertex, isSelfLoop: Bool
    func oppositeVertex(to: Vertex) -> Vertex

@resultBuilder enum GraphBuilder<Vertex>  // accepts UndirectedEdge<Vertex> and Vertex expressions

// AdjacencyListModule
struct UndirectedAdjacencyList<Vertex: Hashable>
    : Graph, Hashable, ExpressibleByDictionaryLiteral  // Sendable, Codable when Vertex is

    init()
    init(vertices: some Sequence<Vertex>)
    init(edges: some Sequence<UndirectedEdge<Vertex>>)
    init(vertices: some Sequence<Vertex>, edges: some Sequence<UndirectedEdge<Vertex>>)
    init<S: Sequence<Vertex>>(adjacency: [Vertex: S])
    init(@GraphBuilder<Vertex> _: () -> ...)
    init(_ graph: some Graph<Vertex>)

    var vertexCount: Int
    var edgeCount: Int
    var vertices: Vertices                        // Collection
    var edges: Edges                              // Collection, Index == Int, 0..<edgeCount
    func contains(_: Vertex) -> Bool
    func contains(edge: UndirectedEdge<Vertex>) -> Bool  // either orientation
    func neighbors(of: Vertex) -> Neighbors       // a self-loop's vertex twice
    func incidentEdges(of: Vertex) -> ArraySlice<Int>    // a self-loop's position twice
    func oppositeVertex(to: Vertex, acrossEdgeAt: Int) -> Vertex
    func degree(of: Vertex) -> Int                // a self-loop counts 2
    var vertexIndexBound: Int?                    // vertexCount
    func vertexIndex(of: Vertex) -> Int
    func vertex(atIndex: Int) -> Vertex
    func neighborIndices(ofIndex: Int) -> ArraySlice<Int>

    mutating func insert(_: Vertex) -> (inserted: Bool, memberAfterInsert: Vertex)
    mutating func insert(edge: UndirectedEdge<Vertex>) -> (inserted: Bool, memberAfterInsert: UndirectedEdge<Vertex>)
    mutating func remove(_: Vertex) -> Vertex?
    mutating func remove(edge: UndirectedEdge<Vertex>) -> UndirectedEdge<Vertex>?
    mutating func removeAll(keepingCapacity: Bool = false)
    mutating func removeAllEdges(keepingCapacity: Bool = false)
    mutating func reserveCapacity(vertexCount: Int, edgeCount: Int)
```

## Conventions

| Question | Choice | Why | Disagreement |
|---|---|---|---|
| Parallel edges | Not allowed; inserting an existing edge, in either orientation, returns `inserted: false` | The simple-with-loops class is the default undirected graph in NetworkX, JGraphT and petgraph's `GraphMap`; parallel edges belong to `Pseudograph` | petgraph `Graph` allows them |
| Self-loops | Allowed | As `AdjacencyList` | JGraphT `SimpleGraph` rejects them |
| A self-loop's contribution | 1 to `edgeCount`; 2 to `degree`; its vertex twice in `neighbors`, its position twice in `incidentEdges` | `degree == neighbors.count` and Σ degree = 2 · edgeCount | NetworkX, JGraphT and petgraph list the loop once among the neighbors |
| Orientation | An edge keeps the orientation it was first inserted with; `memberAfterInsert` and `remove(edge:)` return the stored one | `UndirectedEdge`'s `u` and `v` are not part of its value, but are observable | igraph canonicalizes, which needs `Comparable` |
| Edge positions | `0..<edgeCount`, in insertion order until a removal; a removal moves the last edge into the hole | A weight is an array lookup, the same from both ends | — |
| Row order | Before any removal, `neighbors` and `incidentEdges` are in insertion order, a loop's two entries side by side | What Boost's `vecS` lists give; tested for one fixture (UG-R06) | — |
| Absent vertex | `neighbors`, `incidentEdges`, `degree` and `vertexIndex` trap; `contains` and removals never do | As `AdjacencyList` | petgraph returns empty |
| `oppositeVertex(to:acrossEdgeAt:)` off the edge | Traps | A programming error | — |
| `==` | Equal vertex sets and equal edge sets, as unordered pairs; independent of insertion order and orientation | Value semantics | — |
| `description` | `[0, 1, 2]; [0–1, 1–2]`, the form every representation shares, with `–` | Equal graphs print alike | — |
| Encoded form (`Codable`) | Unspecified, except that decoding keeps each edge's position and orientation and rejects a repeated edge | | |

## Files

Every test is self-contained: there are no shared helper functions, and any test can be copied to
another file and still compile. The only shared material is in `GrafluentTestSupport`: the named
fixtures (`UndirectedFixtures.swift`), the pseudograph test conformer and `MinimalSequence`.

| File | Covers |
|---|---|
| `UndirectedAdjacencyListQueryTests.swift` | The named fixtures through generic code: the empty and trivial graphs, a lone self-loop, K₃ with and without a loop, a loop on a path in insertion order, petgraph's graph with repeats, Petersen, cube, karate, isolated vertices, positions |
| `UndirectedAdjacencyListMutationTests.swift` | Removing vertices (with incident loops, and so a slot with a loop moves) and edges, with the laws after every step; reversed duplicate inserts; clearing |
| `UndirectedAdjacencyListPreconditionTests.swift` | Exit tests for every trapping precondition; membership and removal never trap |
| `UndirectedAdjacencyListEqualityTests.swift` | `Equatable`/`Hashable` over equivalence classes; all 64 graphs on 3 vertices with loops |
| `UndirectedAdjacencyListValueSemanticsTests.swift` | Every kind of mutation leaves an existing copy and its views unchanged |
| `UndirectedAdjacencyListDescriptionTests.swift` | `description` |
| `UndirectedAdjacencyListCodableTests.swift` | JSON and property list round trips |
| `UndirectedAdjacencyListConstructionTests.swift` | Dictionary literals, adjacency mappings, initializers, order independence, conversion from any `Graph` |
| `UndirectedAdjacencyListReviewTests.swift` | Added after the critical review, for bugs that survived the first suite: `removeAllEdges` forgets edges (UG-R21); edgeless graphs compare vertices and hashes see both sets (UG-R16); `memberAfterInsert` returns stored instances and orientation (UG-R10); decoding keeps orientation and rejects repeated edges (UG-R19); edge indices (UG-R22); seeded random mutations against a set model, every law after every step (UG-P02) |

The `Graph` laws on this type (with Int and String vertices), its associated types, the builder,
the `directed` view and conversions are tested in `Tests/GraphProtocolsTests`, beside the other
conformers.

Case IDs in test names (UG-R01, UG-L16, ...) refer to the undirected protocol catalog (`Tests/Catalogs/GraphProtocols/graph.md`); see
`Tests/GraphProtocolsTests/README.md`. Fixtures cite their sources in
`Tests/GrafluentTestSupport/UndirectedFixtures.swift`.

Properties that can only be observed internally (O(1) `degree` and `contains(edge:)`, O(degree)
vertex removal, a constant number of buffers copied) are performance properties and belong in the
benchmarks (UG-B02 – B04), not here.
