# EdgeList test suite

`EdgeList<Vertex>` is a directed multigraph stored as an ordered list of edges: an `Array` of
`DirectedEdge` with graph queries. It conforms to `RandomAccessCollection`, `MutableCollection`
and `RangeReplaceableCollection` with `Int` positions, so everything `Array` can do to its
elements it can do to edges. The suite uses only the public API. Every test is self-contained;
shared material is limited to the fixtures and test types in `GrafluentTestSupport`.

## API under test

```swift
struct EdgeList<Vertex: Hashable>: RandomAccessCollection, MutableCollection, RangeReplaceableCollection,
                                    ExpressibleByArrayLiteral, Hashable, CustomStringConvertible,
                                    CustomDebugStringConvertible, CustomReflectable
                                    // Sendable and Codable when Vertex is

    init()
    init(_ edges: some Sequence<DirectedEdge<Vertex>>)  // shares an Array's or EdgeList's storage
    init(sources: some Collection<Vertex>, targets: some Collection<Vertex>)
    init(@DirectedGraphBuilder<Vertex> _:)          // traps on a bare vertex statement

    var edges: EdgeList                              // the list itself
    var edgeCount: Int                               // == count
    var vertices: [Vertex]                           // endpoints, first-appearance order, O(m)
    var vertexCount: Int                             // O(m)
    func contains(_: Vertex) -> Bool                 // O(m)
    func contains(edge:) -> Bool                     // O(m)
    func multiplicity(of: DirectedEdge<Vertex>) -> Int
    func successors(of:) -> [Vertex]                 // in edge order, once per edge
    func predecessors(of:) -> [Vertex]
    func outDegree(of:) / inDegree(of:) / degree(of:) -> Int   // repeats counted; 0 if absent
    var outDegrees, inDegrees: [Vertex: Int]         // every endpoint's, in one pass
    var multiplicities: [DirectedEdge<Vertex>: Int]  // every distinct edge's count, in one pass
    func transposed() -> EdgeList                    // every edge flipped, order kept
    mutating func transpose()
    var capacity: Int

    mutating func remove(edge:) -> DirectedEdge<Vertex>?       // the first copy
    mutating func removeEdges(incidentTo:) -> Int              // every edge at a vertex
    mutating func removeEdges(from:) / removeEdges(to:) -> Int  // one direction
    // A range subscript with _modify: list[a..<b].sort() mutates in place, without copying the list.
    // The positions of an edge's copies: the standard library's indices(of:) / indices(where:).
```

`DirectedEdge` is `Comparable` when its vertices are: lexicographic by source, then target
(row-major order), so `list.sort()` works without a closure.

## Conventions

| Question | Choice | Why | Disagreement |
|---|---|---|---|
| Parallel edges | Kept, at distinct positions | Every flat edge list studied keeps them; collapsing is a conversion to `AdjacencyList`, CSR or the matrix | NetworkX `DiGraph`, petgraph `GraphMap`, rustworkx `multigraph=False` collapse |
| Order | Preserved under every operation, with `Array` semantics; part of the value | Positions are edge identities, so a weight array indexed by position stays aligned | petgraph swap-removes and its `retain_edges` reverses; rustworkx reuses freed slots |
| Equality and hashing | Element by element, in order | Equal values must be interchangeable, and positions are observable; order-free comparisons go through `Set`, sorting or `AdjacencyList` | igraph and NetworkX's `edges_equal` compare multisets |
| Isolated vertices | Not representable; `vertices` are the endpoints | No flat edge list studied stores them; storing them would make an emptied list unequal to `EdgeList()` | JGraphT's CSV dialect can declare one |
| `remove(edge:)` | The first copy, matching `firstIndex(of:)` | Predictable and the same as the stdlib's search | NetworkX removes the last-added, rustworkx the newest, Boost every copy |
| Absent vertex in a query | No trap: degree 0, no neighbors | There is no vertex set to be absent from, and checking would cost the same O(m) scan | `AdjacencyList` traps |
| Bare vertex in the builder | Trap | Ignoring it silently would drop data | NetworkX skips one-token lines; rustworkx panics; igraph errors |
| Complexity | Graph queries are O(m) scans; nothing is indexed | An edge list is an input format and a value, not an index | — |
| Transpose | `transposed()`; `reversed()` is the stdlib's order reversal | The two must not share a name | — |
| Encoded form | Flat `[s₀, t₀, s₁, t₁, …]`; an odd count is corrupt | Compact, as large as the list, so nothing to limit | igraph's `edges` vector is the same shape |
| Mirror | A collection of the edges | It is a collection | The siblings show `vertices` and `edges` children |
| Initializer label | `init(_:)` | `RangeReplaceableCollection` requires it; a second spelling would duplicate it | The siblings use `init(edges:)` |
| Slices | `Slice<EdgeList>`: collection operations only | Graph queries on a slice are one `EdgeList(slice)` away; a custom slice type would duplicate the API | — |
| Neighbors | `successors(of:)` returns a new `[Vertex]` | The query is an O(m) scan either way, and an array has O(1) `count` | A lazy filter view would have O(m) `count` |
| Encoded form compatibility | Not interchangeable with `[DirectedEdge]`'s keyed form | Decoding one format, falling back to another, would hide which one was corrupt | — |

## Files

| File | Covers |
|---|---|
| `EdgeListConstructionTests.swift` | Empty and literal forms, sequences (single-pass and lazy), the builder, vertex types; vertices as endpoints; parallel edges and multigraph degrees from JGraphT and NetworkX; order under mutation |
| `EdgeListCollectionTests.swift` | Collection laws, every slice, `MutableCollection` (sorting and its stability, partition, shuffle, slice write-back), `RangeReplaceableCollection` (insert, remove, replace, `remove(edge:)`, `removeEdges(incidentTo:)`) |
| `EdgeListQueryTests.swift` | `contains(edge:)` over every pair, neighbors and degrees with multiplicity, real-data degrees, the transpose, conversions to `AdjacencyList`, `CompressedSparseRow` and `AdjacencyMatrix`, weights by position, GAP / Graph500 / Ligra data |
| `EdgeListConformanceTests.swift` | Equality and hashing (every short list on 2 and 3 vertices), Codable, descriptions, value semantics, a model test against `Array`, object lifetimes, exit tests |

Not ported from the catalog: the text-format cases (EL-T01–T17) belong to the future
`GraphFormats` reader and writer, and the API-shape cases that assert something does not exist
(EL-V09, EL-R19, EL-E10) and the protocol cases (EL-X12, EL-X13) wait for the `DirectedGraph`
protocol. EL-X11 is `CompressedSparseRow`'s own precondition, tested there. EL-O07 (positions are
identities) is what EL-K01–K04 exercise.

Case IDs (EL-C05, EL-R10, …) refer to the catalog of cases harvested from Boost.Graph, petgraph,
NetworkX, igraph, JGraphT, rustworkx, scipy, GAP, neo4j's graph crate, LEMON, gonum and the Swift
Algorithm Club. Spanning-tree cases from that catalog (Kruskal totals from LEMON, petgraph, gonum,
JGraphT and GAP's `4.wel`) belong to the future `SpanningTrees` module.
