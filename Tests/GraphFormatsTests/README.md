# GraphFormats test suite

`GraphFormats` reads and writes fifteen text formats: DOT, GraphML, node-link JSON, Matrix Market,
edge list, adjacency list, Mermaid flowcharts, GML, Pajek, graph6, sparse6, digraph6, DIMACS
(shortest path and clique), METIS and Cytoscape JSON. A reader is a throwing initializer on any
mutable representation. It reports vertex, edge and graph attributes through closures, by vertex
and by edge position. A writer is a method on any `DirectedGraph` or `Graph` that streams text into
an `inout some TextOutputStream`, and takes IDs and attributes from closures. The rules the tests
pin are in `api.md` in [`Tests/Catalogs/GraphFormats/`](../Catalogs/GraphFormats/). Among them:

- `MutableGraph` in `GraphProtocols` is the undirected counterpart of `MutableDirectedGraph`.
  `UndirectedAdjacencyList` and `Pseudograph` conform, so every reader but digraph6's also has an
  undirected form; graph6, sparse6 and METIS are undirected only.
- A Mermaid flowchart that mixes arrows and open links is `kindMismatch`.
- DOT subgraphs join the one graph with their own default scope; ports become `tailport` and
  `headport`. GraphML graphs nested in nodes (yEd groups) are read into the one graph.
- The vertex counts a file declares (Matrix Market, Pajek, DIMACS, METIS, sparse6) are inserted
  eagerly, bounded by `maximumVertexCount:` (default `nil`: 16 per input byte plus 4,096).
- Writers throw `WriteError` on data they cannot represent, and then write nothing: a repeated
  ID, XML control characters, whitespace or `#` in a list token (the delimiter, `#`, LF or CR with a
  `delimiter:`), a boolean edge-list column, a Mermaid ID outside `[A-Za-z0-9_]+`, a non-finite
  double or a reserved name in node-link and Cytoscape JSON, a GraphML key of two types, a GML key
  outside `[A-Za-z][A-Za-z0-9_]*`, a Pajek line feed or a non-numeric coordinate, a self-loop
  (graph6, METIS) or a parallel edge (graph6, digraph6, METIS). A closure that breaks its contract
  traps, and so does an edge-list delimiter that is not ASCII or is a letter, a digit, `.`, `+`,
  `-`, `#`, LF or CR.
- DOT HTML strings are read as `.string`, and the writer quotes them.
- No writer emits `strict`.

The suite uses only the public API, and each test is self-contained. The only shared material is
the seeded generator and the tags in `GrafluentTestSupport`.

## API under test

```swift
enum AttributeValue: Hashable, Sendable, literals { case string(String), integer(Int), double(Double), boolean(Bool) }
struct ParseError: Error, Hashable, Sendable { var kind: Kind; var line, column, byteOffset: Int }
enum WriteError: Error, Hashable, Sendable { case duplicateID, invalidID, invalidKey, reservedKey, invalidValue, typeMismatch, selfLoop, parallelEdge }

extension MutableDirectedGraph, MutableGraph {
    init(dot:vertex:vertexAttribute:edgeAttribute:graphAttribute:) throws(ParseError)
    init(graphML:vertex:vertexAttribute:edgeAttribute:graphAttribute:) throws(ParseError)
    init(nodeLinkJSON:vertex:vertexAttribute:edgeAttribute:graphAttribute:) throws(ParseError)   // vertex: (AttributeValue) -> Vertex?
    init(matrixMarket:maximumVertexCount:vertex:edgeAttribute:) throws(ParseError)                // vertex: (Int) -> Vertex?
    init(edgeList:columns:delimiter:vertex:edgeAttribute:) throws(ParseError)
    init(adjacencyList:vertex:) throws(ParseError)
    init(mermaid:vertex:vertexLabel:edgeLabel:) throws(ParseError)
    init(gml:vertex:vertexAttribute:edgeAttribute:graphAttribute:) throws(ParseError)            // vertex: (AttributeValue) -> Vertex?
    init(pajek:maximumVertexCount:vertex:vertexAttribute:edgeAttribute:graphAttribute:) throws(ParseError)
    init(dimacs:maximumVertexCount:vertex:…) throws(ParseError)                                   // directed: p sp, edgeAttribute:; undirected: p edge, p col
    init(cytoscapeJSON:vertex:vertexAttribute:edgeAttribute:graphAttribute:) throws(ParseError)
}
extension MutableDirectedGraph { init(digraph6:vertex:) throws(ParseError) }
extension MutableGraph {
    init(graph6:vertex:), init(sparse6:maximumVertexCount:vertex:) throws(ParseError)
    init(metis:maximumVertexCount:vertex:vertexAttribute:edgeAttribute:) throws(ParseError)
}
// The same without `vertex:` where Vertex == String (the formats with names) and where
// Vertex == Int (Matrix Market, node-link JSON, the edge and adjacency lists, the nauty formats,
// DIMACS, METIS).

extension DirectedGraph, Graph {
    writeDOT, writeGraphML, writeNodeLinkJSON, writeGML, writeCytoscapeJSON
        (to:vertexID:vertexAttributes:edgeAttributes:graphAttributes:) throws(WriteError)
    writePajek(to:vertexID:vertexAttributes:edgeAttributes:) throws(WriteError)
    writeMatrixMarket(to:), writeMatrixMarket(to:weight: (Edges.Index) -> Int), writeMatrixMarket(to:weight: (Edges.Index) -> Double)
    writeEdgeList(to:vertexID:columns:delimiter:edgeAttributes:) throws(WriteError)
    writeAdjacencyList(to:vertexID:) throws(WriteError)
    writeMermaid(to:vertexID:vertexLabel:edgeLabel:) throws(WriteError)
}
extension DirectedGraph { writeDigraph6(to:header:) throws(WriteError); writeDIMACS(to:weight:) }
extension Graph {
    writeGraph6(to:header:) throws(WriteError); writeSparse6(to:header:); writeDIMACS(to:)
    writeMETIS(to:), writeMETIS(to:weight:) throws(WriteError)
}
```

## How values are pinned

The catalog-row files are the thirteen `GraphFormats<Format>Tests.swift` files (DOT, GraphML,
NodeLinkJSON, MatrixMarket, EdgeList, AdjacencyList, Mermaid, GML, Pajek, Nauty for graph6, sparse6
and digraph6, DIMACS, METIS, CytoscapeJSON) and `GraphFormatsPreconditionTests.swift`. `swiftgen.py`
generated them from `cases.md`. It sits next to `ref.py` and `cases.md` in
[`Tests/Catalogs/GraphFormats/`](../Catalogs/GraphFormats/):

```
uv run --quiet --no-project --with networkx==3.7 --with scipy==1.18.1 --with pydot==4.0.1 python3 Tests/Catalogs/GraphFormats/swiftgen.py
```

It first checks that `ref.py` reproduces `cases.md` byte for byte. Then it re-runs every row on the
model and checks that the result renders to the row's Expected cell. Last, it writes one `@Test` per
row (592 rows):

- **Read rows (223).** The reader runs on the row's target, with the row's options (`columns:`,
  `delimiter:`, `maximumVertexCount:`), with closures that record every attribute call (or Mermaid
  label call). For each key the test keeps the order it was first set in and the last value set.
  The test then checks the vertices in order, and every edge position with its endpoints (stored
  orientation for undirected edges). It also checks the counts and every recorded attribute of
  every vertex, every edge and the graph, and that no other attribute was set. A NaN is checked by
  `isNaN`. The nauty readers and the undirected DIMACS reader have no attribute closures.
- **Error rows (287).** The test checks the `ParseError`'s kind, line, column and byte offset. The
  offset is computed from the model's position and counts from after a byte-order mark.
- **Write rows (82).** The test builds the row's graph as a `DirectedPseudograph` or `Pseudograph`:
  vertices in order, then edges in position order. It passes the row's attributes through the
  writer's closures, as `switch` statements over the vertex or position (weights through `weight:`,
  and `header:` and `delimiter:` where the row has them), and checks every byte.

The catalog has no trap rows. The writers' and readers' preconditions are in `extra_traps.swift`,
which `swiftgen.py` splices into `GraphFormatsPreconditionTests.swift`: a key given twice for one
element (every attribute writer, GML, Pajek and Cytoscape JSON included), an edge-list column an
edge has no value for, a node-link id that is neither a string nor an integer, and an edge-list
delimiter that is not ASCII or is a letter, a digit, `.`, `+`, `-`, `#`, LF or CR (reader and
writer). Each trapping call runs in a child process (an exit test), through `try?` so that a throw
would fail it. The same call without the fault then runs in this process and its output is
checked, so the trap comes from the fault.

## Hand-written files

- **Round trips** (`GraphFormatsRoundTripTests.swift`, swift-property-based, with shrinking). There
  are fourteen properties: one per format and kind for the first seven formats, 200 random graphs
  each. The graphs have parallel edges, loops and isolated vertices. Names and values are built from
  awkward pieces: quotes, a backslash before a quote, before a newline or at the end, newlines,
  tabs, CR, `#`, `<&>`, `]]>`, `#quot;`, non-ASCII and astral characters, the empty string,
  keywords, and numbers written as text. A graph is written, read back, and compared with api.md's
  round-trip table:
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
- **Named round trips** (`GraphFormatsNamedRoundTripTests.swift`, with shrinking, 200 graphs each).
  GML in both kinds (names, edges and values survive; integers outside 32 bits come back as text,
  booleans as 1 and 0); Pajek in both kinds (labels and every token survive its quoting; numbers come
  back as doubles, other values as text); Cytoscape JSON in both kinds (ids, edges and typed values
  survive; `value` and `name` are added; a multigraph's keys are not read); the edge list with a
  delimiter (IDs with blanks and empty IDs survive, columns typed by their text); and NetworkX's dict
  edge data, with and without a delimiter, formatted here as Python's `repr` writes it.
- **Indexed round trips** (`GraphFormatsIndexedRoundTripTests.swift`, with shrinking). For graph6,
  digraph6 and sparse6, the writer's output is compared with an encoder written in the test from
  nauty's `formats.txt` (sparse6 with nauty's padding rule), and the reader must give the edges in
  the format's order (by column, by row, by larger end), loops and parallel edges included for
  sparse6. DIMACS arcs and edges come back in position order with their weights; METIS edges from
  their smaller end's line, with their weights.
- **Hostile input** (`GraphFormatsHostileInputTests.swift`, and at scale in
  `Performance/GraphFormatsHostileInputScaleTests.swift`). Every reader must throw a `ParseError`
  (never trap or hang), and each test bounds its own time. The inputs:
  - Nesting 100,000 deep: XML elements, JSON arrays and objects, DOT braces and `subgraph {` (the
    65th is `nestingTooDeep`), DOT HTML strings, GML lists (the 64th inside the graph's), Mermaid
    shapes.
  - Huge numbers: 100,000-digit integers, exponents past `Double`, Matrix Market indices and sizes
    past `Int`, a 73-byte file claiming 10¹⁸ entries, and edge-list columns that fall back to text.
  - DOCTYPE anywhere: billion laughs, an external `SYSTEM` entity, inside the root, after a comment.
    The vertex closure must never run.
  - Undeclared entities and invalid character references.
  - Invalid UTF-8 in every format, the eight added ones and the delimited edge list included:
    overlong, surrogate, past U+10FFFF, lone continuation, truncated, UTF-16, and after a
    byte-order mark.
  - Every byte prefix of a valid file in every format, DOT with subgraphs and ports, GML, Pajek,
    the nauty formats, DIMACS, METIS, Cytoscape JSON and dict edge data included. A scalar cut in
    half must be `invalidUTF8` at its lead byte.
  - 3,000 seeded random mutations of valid files in every format.

  Positions are pinned to `ref.py`'s where api.md fixes them. For every other error, line and
  column must agree with the byte offset.
- **Write errors** (`GraphFormatsWriteErrorTests.swift`). Every `WriteError` case in every writer
  that throws it, each beside the same call without the fault, and the output unchanged after the
  throw: a string, and a recording stream that must receive nothing when the fault comes after
  the first 64 KiB. Among them: graph6's `selfLoop` and `parallelEdge` (whichever edge comes
  first) and digraph6's `parallelEdge`; METIS's `selfLoop` and `parallelEdge`; GML's repeated
  label, unspellable key and reserved key; Pajek's repeated label, line feed and non-numeric
  coordinate or weight; Cytoscape JSON's repeated ID, reserved key and non-finite double; and a
  delimited edge list's token holding the delimiter, `#`, LF or CR (whitespace and empty tokens are
  fine).
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
- **Edge cases of the newer readers** (`GraphFormatsEdgeCaseTests.swift`). Cases no catalog row
  reaches: indices mapped to one vertex (DIMACS, METIS, graph6), the four- and eight-byte N(n)
  boundary, which unmirrored METIS entry is reported, a repeated GML id under another label, GML
  character references past U+10FFFF, Pajek backslashes inside quotes, Cytoscape `key` in and out of
  multigraphs, a repeated Cytoscape id under a mapping that gives two vertices, dict data and
  delimited columns into `Int` targets with CR LF, `\U` past U+10FFFF in dict data, nested subgraph
  members and ports on subgraphs in DOT, and the budget of a DOT hop between groups.
- **Stress** (`Performance/GraphFormatsStressTests.swift`). Each test runs inside a `Task` with a
  one-minute limit and an explicit bound on its own time:
  - 10⁵ weighted arcs through the edge list, Matrix Market and node-link JSON.
  - 10⁵ labelled arcs through DOT, GraphML, the adjacency list and Mermaid.
  - 10⁵ weighted edges through GML, Pajek, Cytoscape JSON, DIMACS, METIS, sparse6 and a delimited
    edge list.
  - A megabyte in one ID and one label.
  - A 2 MB output that must reach a recording `TextOutputStream` in order, in pieces of at most
    64 KiB that are on average at least half full.
- **Cost cases** (`GraphFormatsReviewTests.swift`, `Performance/GraphFormatsReviewScaleTests.swift`).
  Inputs whose cost could grow faster than their size: a Matrix Market size line over
  `maximumVertexCount` (every overload, and the 79-byte file claiming 10¹² vertices in a child
  process under 256 MB), DOT default lists, Mermaid `&` groups (the 45 KB, 9·10⁶-edge file in a
  child process), GraphML defaults against data, defaults multiplied by vertices and edge chains (the
  budget's exact crossing point), JSON objects and XML tags with many keys, and the writers'
  distinct-ID check. Costs are checked by timing two sizes eight times apart (the least of five
  interleaved runs; a linear reader takes about 8×, a quadratic one 64×). The many-keys ratio is
  meaningful only in release builds.
- **Bulk construction** (`GraphFormatsBulkBuildTests.swift`). The line readers collect a file and
  build in one step; on seeded files with repeats, loops and aliased IDs, each representation must
  equal the graph insertion builds (vertices, positions, every row in order), mutate correctly
  afterwards, and report each edge's attributes at its position (a simple target's repeat on its
  first copy).
- **Numbers** (`GraphFormatsNumberTests.swift`). Decimal columns against `Double(_:)` on random
  digits, near-ties and extremes, to the bit; written doubles with `description`'s digits and the
  writers' layout, read back to the same bits in the edge list, Matrix Market, GraphML and
  node-link JSON, on random bit patterns, both ends of every binade, subnormals and
  9·10¹⁵ – 2⁵⁴.
- **Identifiers** (`GraphFormatsIdentifierTests.swift`). IDs and attribute names compare by Unicode
  scalars: canonically equivalent IDs are two IDs (merged by a `String` target, kept apart by a
  scalar one), and two DOT default keys, two GraphML key names, two writer keys.
- **One-pass reads** (`GraphFormatsOnePassTests.swift`). Node-link JSON in the common layout is read
  in one pass, and GraphML's first walk reads the nodes and edges ahead, nested graphs (yEd groups)
  included; on seeded documents with errors of every kind, each must read as its general reader
  does (forced by an ignored member, or a key after the graph): the same graph, the same calls to
  every closure in order (the `vertex` mapping included, with merges and refusals), or the same
  error. Also the order of the attribute and label calls, which come after the build in document
  order.
- **Fast paths and parallel loops** (`GraphFormatsFastPathTests.swift`,
  `GraphFormatsParallelLoopTests.swift`). The `Int` edge- and adjacency-list readers and the
  Matrix Market entry reader against their general scanners, and parallel self-loops and parallel
  edges through every construction path into the multigraphs.

`UndirectedAdjacencyList` and `Pseudograph` as `MutableGraph` are tested in their own suites
(`AdjacencyListTests`, `MultigraphsTests`).

## Planted bugs

`scripts/mutants/GraphFormats.py` plants bugs in the scanners, every reader and writer, the limits,
the decimal parser, Schubfach and the bulk hooks (`just mutate GraphFormats`).
