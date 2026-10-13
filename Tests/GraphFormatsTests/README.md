# GraphFormats test suite

`GraphFormats` reads and writes seven text formats: DOT, GraphML, node-link JSON, Matrix Market,
edge list, adjacency list and Mermaid flowcharts. A reader is a throwing initializer on any mutable
representation. It reports vertex, edge and graph attributes through closures, by vertex and by
edge position. A writer is a method on any `DirectedGraph` or `Graph` that streams text into an
`inout some TextOutputStream`, and takes IDs and attributes from closures. The rules the tests pin
are in `api.md` in [`Tests/Catalogs/GraphFormats/`](../Catalogs/GraphFormats/). Among them:

- `MutableGraph` in `GraphProtocols` is the undirected counterpart of `MutableDirectedGraph`.
  `UndirectedAdjacencyList` and `Pseudograph` conform, so every reader also has an undirected form.
- A Mermaid flowchart that mixes arrows and open links is `kindMismatch`.
- The Matrix Market vertex count is inserted eagerly, bounded by `maximumVertexCount:` (default
  `nil`: 16 per input byte plus 4,096).
- Writers throw `WriteError` on data they cannot represent, and then write nothing: a repeated
  ID, XML control characters, whitespace or `#` in a list token, a boolean edge-list column, a
  Mermaid ID outside `[A-Za-z0-9_]+`, a non-finite double or a reserved name in node-link JSON, a
  GraphML key of two types. A closure that breaks its contract traps.
- DOT HTML strings are read as `.string`, and the writer quotes them.
- No writer emits `strict`.

The suite uses only the public API, and each test is self-contained. The only shared material is
the seeded generator and the tags in `GrafluentTestSupport`.

## API under test

```swift
enum AttributeValue: Hashable, Sendable, literals { case string(String), integer(Int), double(Double), boolean(Bool) }
struct ParseError: Error, Hashable, Sendable { var kind: Kind; var line, column, byteOffset: Int }
enum WriteError: Error, Hashable, Sendable { case duplicateID, invalidID, invalidKey, reservedKey, invalidValue, typeMismatch }

extension MutableDirectedGraph, MutableGraph {
    init(dot:vertex:vertexAttribute:edgeAttribute:graphAttribute:) throws(ParseError)
    init(graphML:vertex:vertexAttribute:edgeAttribute:graphAttribute:) throws(ParseError)
    init(nodeLinkJSON:vertex:vertexAttribute:edgeAttribute:graphAttribute:) throws(ParseError)   // vertex: (AttributeValue) -> Vertex?
    init(matrixMarket:vertex:edgeAttribute:) throws(ParseError)                                   // vertex: (Int) -> Vertex?
    init(edgeList:columns:vertex:edgeAttribute:) throws(ParseError)
    init(adjacencyList:vertex:) throws(ParseError)
    init(mermaid:vertex:vertexLabel:edgeLabel:) throws(ParseError)
}
// The same without `vertex:` where Vertex == String (all but matrixMarket) and where Vertex == Int
// (matrixMarket, nodeLinkJSON, edgeList, adjacencyList).

extension DirectedGraph, Graph {
    writeDOT(to:vertexID:vertexAttributes:edgeAttributes:graphAttributes:) throws(WriteError)
    writeGraphML(to:vertexID:vertexAttributes:edgeAttributes:graphAttributes:) throws(WriteError)
    writeNodeLinkJSON(to:vertexID:vertexAttributes:edgeAttributes:graphAttributes:) throws(WriteError)
    writeMatrixMarket(to:), writeMatrixMarket(to:weight: (Edges.Index) -> Int), writeMatrixMarket(to:weight: (Edges.Index) -> Double)
    writeEdgeList(to:vertexID:columns:edgeAttributes:) throws(WriteError)
    writeAdjacencyList(to:vertexID:) throws(WriteError)
    writeMermaid(to:vertexID:vertexLabel:edgeLabel:) throws(WriteError)
}
```

## How values are pinned

The catalog-row files are the seven `GraphFormats<Format>Tests.swift` files and
`GraphFormatsPreconditionTests.swift`. `swiftgen.py` generated them from `cases.md`. It sits next to
`ref.py` and `cases.md` in [`Tests/Catalogs/GraphFormats/`](../Catalogs/GraphFormats/):

```
uv run --quiet --no-project --with networkx==3.7 --with scipy==1.18.1 --with pydot==4.0.1 python3 Tests/Catalogs/GraphFormats/swiftgen.py
```

It first checks that `ref.py` reproduces `cases.md` byte for byte. Then it re-runs every row on the
model and checks that the result renders to the row's Expected cell. Last, it writes one `@Test` per
row (259 rows):

- **Read rows (109).** The reader runs on the row's target with closures that record every
  attribute call (or Mermaid label call). For each key the test keeps the order it was first set
  in and the last value set. The test then checks the vertices in order, and every edge position
  with its endpoints (stored orientation for undirected edges). It also checks the counts and every
  recorded attribute of every vertex, every edge and the graph, and that no other attribute was
  set. A NaN is checked by `isNaN`.
- **Error rows (110).** The test checks the `ParseError`'s kind, line, column and byte offset. The
  offset is computed from the model's position and counts from after a byte-order mark.
- **Write rows (40).** The test builds the row's graph as a `DirectedPseudograph` or `Pseudograph`:
  vertices in order, then edges in position order. It passes the row's attributes through the
  writer's closures, as `switch` statements over the vertex or position, and checks every byte.

The catalog has no trap rows. The writers' preconditions (the closures' contract) are in
`extra_traps.swift`, which `swiftgen.py` splices into `GraphFormatsPreconditionTests.swift`. Each
trapping call runs in a child process (an exit test), through `try?` so that a throw would fail it.
The same call without the fault then runs in this process and its output is checked, so the trap
comes from the fault.

## Hand-written files

- **Round trips** (`GraphFormatsRoundTripTests.swift`, swift-property-based, with shrinking). There
  are fourteen properties: one per format and kind, 200 random graphs each. The graphs have
  parallel edges, loops and isolated vertices. Names and values are built from awkward pieces:
  quotes, a backslash before a quote, before a newline or at the end, newlines, tabs, CR, `#`,
  `<&>`, `]]>`, `#quot;`, non-ASCII and astral characters, the empty string, keywords, and numbers
  written as text. A graph is written, read back, and compared with api.md's round-trip table:
  - DOT: all values come back as text.
  - GraphML: typed. An integer under a key that also holds doubles comes back as a double.
  - Node-link JSON: typed. The output is ASCII.
  - Matrix Market: indices in `vertices` order, weights bit-exact, undirected edges as (larger,
    smaller), and both arcs of each entry in a directed target.
  - Edge list: columns re-typed by their text, isolated vertices lost.
  - Adjacency list: edges grouped by line.
  - Mermaid: index IDs, labels exact.

  Attributes reach a writer as an array of `(key:, value:)` pairs in writing order. Each element has
  one of five key shapes, chosen by its code, with values drawn from fixed pools.
- **Hostile input** (`GraphFormatsHostileInputTests.swift`). Every reader must throw a `ParseError`
  (never trap or hang), and each test bounds its own time. The inputs:
  - Nesting 100,000 deep: XML elements, JSON arrays and objects, DOT braces, DOT HTML strings,
    Mermaid shapes.
  - Huge numbers: 100,000-digit integers, exponents past `Double`, Matrix Market indices and sizes
    past `Int`, a 73-byte file claiming 10¹⁸ entries, and edge-list columns that fall back to text.
  - DOCTYPE anywhere: billion laughs, an external `SYSTEM` entity, inside the root, after a comment.
    The vertex closure must never run.
  - Undeclared entities and invalid character references.
  - Invalid UTF-8 in every format: overlong, surrogate, past U+10FFFF, lone continuation, truncated,
    UTF-16, and after a byte-order mark.
  - Every byte prefix of a valid file in every format. A scalar cut in half must be `invalidUTF8` at
    its lead byte.
  - 3,000 seeded random mutations of valid files.

  Positions are pinned to `ref.py`'s where api.md fixes them. For every other error, line and
  column must agree with the byte offset.
- **Write errors** (`GraphFormatsWriteErrorTests.swift`). Every `WriteError` case in every writer
  that throws it, each beside the same call without the fault, and the output unchanged after the
  throw: a string, and a recording stream that must receive nothing when the fault comes after
  the first 64 KiB.
- **Interface** (`GraphFormatsInterfaceTests.swift`).
  - The `vertex` closure is called once per new ID, in first-appearance order, in every format.
    `nil` is `invalidVertex` at the ID, and two IDs that map to one vertex make one vertex.
  - Every kind of target reads: simple ones merge, and `StableDirectedGraph`,
    `UndirectedAdjacencyList` and the `Int` overloads all work.
  - Every kind of input sequence works: `String.UTF8View`, `[UInt8]`, `ArraySlice`, lazy and
    type-erased sequences.
  - The byte-order mark is skipped in every format. Columns count Unicode scalars, offsets count
    bytes, and CR LF counts as one line end.
  - Writers call each closure once per element, in order, and GraphML calls them twice. Every writer
    but node-link JSON ends with LF, and no writer ends a line with CR.
  - Writers work over `AdjacencyList`, `StableDirectedGraph` with holes and
    `UndirectedAdjacencyList`.
  - `AttributeValue` literals and the value semantics of both types.
- **Stress** (`Performance/GraphFormatsStressTests.swift`). Each test runs inside a `Task` with a one-minute
  limit and an explicit bound on its own time:
  - 10⁵ weighted arcs through the edge list, Matrix Market and node-link JSON.
  - 10⁵ labelled arcs through DOT, GraphML, the adjacency list and Mermaid.
  - A megabyte in one ID and one label.
  - A 2 MB output that must reach a recording `TextOutputStream` in order, in pieces of at most
    64 KiB that are on average at least half full.

- **Cost cases** (`GraphFormatsReviewTests.swift`, `Performance/GraphFormatsReviewScaleTests.swift`).
  Inputs whose cost could grow faster than their size: a Matrix Market size line over `maximumVertexCount` (every overload, and the 79-byte file
  claiming 10¹² vertices in a child process under 256 MB), DOT default lists, Mermaid `&` groups (the
  45 KB, 9·10⁶-edge file in a child process), GraphML defaults against data, defaults multiplied by
  vertices and edge chains (the budget's exact crossing point), JSON objects and XML tags with many
  keys, and the writers' distinct-ID check. Costs are checked by timing two sizes eight times apart
  (the least of five interleaved runs; a linear reader takes about 8×, a quadratic one 64×). The
  many-keys ratio is meaningful only in release builds.
- **Bulk construction** (`GraphFormatsBulkBuildTests.swift`). The line readers collect a file and
  build in one step; on seeded files with repeats, loops and aliased IDs, each representation must
  equal the graph insertion builds (vertices, positions, every row in order), mutate correctly
  afterwards, and report each edge's attributes at its position (a simple target's repeat on its
  first copy).
- **Numbers** (`GraphFormatsNumberTests.swift`). Decimal columns against `Double(_:)` on random
  digits, near-ties and extremes, to the bit; written doubles with `description`'s digits and
  the writers' layout, read back to the same bits in the edge list, Matrix Market, GraphML and node-link
  JSON, on random bit patterns, both ends of every binade, subnormals and 9·10¹⁵ – 2⁵⁴.
- **Identifiers** (`GraphFormatsIdentifierTests.swift`). IDs and attribute names compare by Unicode
  scalars: canonically equivalent IDs are two IDs (merged by a `String` target, kept apart by a
  scalar one), and two DOT default keys, two GraphML key names, two writer keys.
- **One-pass reads** (`GraphFormatsOnePassTests.swift`). Node-link JSON in the common layout is read
  in one pass, and GraphML's first walk reads the nodes and edges ahead; on seeded documents with
  errors of every kind, each must read as its general reader does (forced by an ignored member, or a
  key after the graph): the same graph, the same calls to every closure in order (the `vertex`
  mapping included, with merges and refusals), or the same error. Also the order of the attribute
  and label calls, which come after the build in document order.

`UndirectedAdjacencyList` and `Pseudograph` as `MutableGraph` are tested in their own suites
(`AdjacencyListTests`, `MultigraphsTests`).

## Planted bugs

`scripts/mutants/GraphFormats.py` plants bugs in the scanners, every reader and writer, the limits,
the decimal parser, Schubfach and the bulk hooks (`just mutate GraphFormats`).
