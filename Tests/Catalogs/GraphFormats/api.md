# GraphFormats: API

Readers and writers for seven text formats: DOT, GraphML, node-link JSON, Matrix Market
(coordinate), edge list, adjacency list, and Mermaid flowcharts. A reader is a throwing initializer
on any mutable representation (`AdjacencyList`, `DirectedPseudograph`, `StableDirectedGraph`,
`UndirectedAdjacencyList`, `Pseudograph`). It reports vertex, edge and graph attributes through
closures, by vertex and by edge position. A writer is a method on any `DirectedGraph` or `Graph`
that streams canonical text into an `inout some TextOutputStream`, taking IDs and attributes from
closures. The module uses no Foundation: it has its own UTF-8, XML-subset and JSON scanners, and
builds on Linux with the standard library and `GraphProtocols` only. It draws nothing: a format's
styling statements are skipped on reading and never written, unless the caller passes them as
plain attributes.

`cases.md` (GF-001 – GF-259: 219 read rows, 110 of them errors, and 40 write rows) pins the values.
`ref.py` is an independent Python implementation of everything below. Every row is compared with
NetworkX 3.7 (GraphML, node-link JSON, edge list, adjacency list), SciPy 1.18.1 (Matrix Market) or
pydot 4.0.1 (DOT), where that library reads or writes the format. `ref.py` checks the write rows
byte for byte against `json.dumps(nx.node_link_data(G, edges="edges"))`, SciPy's `mmwrite`, and
NetworkX's `write_edgelist` and `write_adjlist` (header comments removed) on the graphs those
writers handle alike, and has NetworkX (GraphML) and pydot (DOT) read them back. The model also
reads back every write row. Rows where a library behaves differently are listed with the reason in
`KNOWN` and under Library disagreements below. `--stress` writes 400 random graphs per format
(strings with quotes, backslashes, newlines, `#`, `<&>`, non-ASCII; every value type; parallel
edges and loops), reads them back with the model and the libraries, and feeds 3,000 mutated inputs
to every model reader, which must return a graph or a `ParseError`. Run:

`uv run --quiet --no-project --with networkx==3.7 --with scipy==1.18.1 --with pydot==4.0.1 python3 Tests/Catalogs/GraphFormats/ref.py [--write] [--stress] [--bench]`

No DOT or Mermaid implementation is executed. The DOT rules below (quoting, escapes, defaults,
`strict`) follow the DOT language page and Graphviz's `lib/cgraph/scan.l`; the Mermaid rules
follow the flowchart syntax page and `flow.jison` of mermaid-js 11.

## Scope

| Format | Read | Write |
|---|---|---|
| DOT | `digraph`/`graph`, `strict`, node, edge and attribute statements, edge chains, `node [..]`/`edge [..]`/`graph [..]` defaults, `ID = ID`, quoted strings with `+`, HTML strings, comments | every vertex and edge with its attributes |
| GraphML | one `<graph>`, typed `<key>`s with `<default>`, node/edge/graph `<data>` | the same |
| node-link JSON | `directed`, `multigraph`, `graph`, `nodes`, and `edges` or `links` | the same, with `edges` |
| Matrix Market | `matrix coordinate`, `pattern`/`integer`/`real`, `general`/`symmetric`/`skew-symmetric` | `general` (directed) or `symmetric` (undirected) |
| Edge list | `u v [column …]` per line, `#` comments | the same |
| Adjacency list | `u v w …` per line (u, then its neighbours) | the same |
| Mermaid | `flowchart`/`graph` with a direction; vertices with every bracket shape (label kept, shape dropped), links `-->`, `---`, `-.->`, `==>`, `--o`, `--x`, longer links, `\|text\|` and in-link text, `&`, chains, `;`, `%%` comments, front matter; styling statements skipped | vertices with labels, edges with labels |

These are read as `unsupported`, at the construct:

| Format | Construct |
|---|---|
| DOT | subgraphs and clusters (`subgraph x { }`, `{ a b } -> c`), ports (`a:p:n`), several graphs per file |
| GraphML | nested graphs, several `<graph>`s, hyperedges, ports, an edge whose `directed` differs from `edgedefault` |
| node-link JSON | `null`, arrays and objects as attribute values |
| Matrix Market | `array` (dense) format, `complex` and `hermitian` fields, `vector` objects |
| Mermaid | `subgraph … end`, bidirectional links (`<-->`, `o--o`, `x--x`), invisible links (`~~~`), the `@{ shape: … }` syntax |

## Summary

```swift
// Values carried by every format. Scalars only.
@frozen
public enum AttributeValue: Hashable, Sendable, CustomStringConvertible,
    ExpressibleByStringLiteral, ExpressibleByIntegerLiteral,
    ExpressibleByFloatLiteral, ExpressibleByBooleanLiteral {
    case string(String)
    case integer(Int)
    case double(Double)
    case boolean(Bool)
}

public struct ParseError: Error, Hashable, Sendable, CustomStringConvertible {
    public var kind: Kind
    public var line: Int        // 1-based
    public var column: Int      // 1-based, in Unicode scalars
    public var byteOffset: Int  // 0-based, into the input (after a byte-order mark, if one was skipped)
    @frozen public enum Kind: Hashable, Sendable {
        case invalidUTF8, syntax, unexpectedEndOfInput, nestingTooDeep, numberOutOfRange,
             invalidValue, invalidVertex, duplicateVertex, undeclaredVertex, duplicateKey,
             undeclaredKey, kindMismatch, entryCountMismatch, indexOutOfRange, notSquare,
             doctypeNotAllowed, entityNotAllowed, mismatchedTag, unsupported, limitExceeded
    }
}

// Readers. Each is an initializer on every mutable representation of the right kind.
// `vertex` maps a file's vertex ID to a vertex (nil: ParseError.invalidVertex at the ID);
// the overloads without it exist where Vertex == String (or Int: Matrix Market, node-link, and
// the edge and adjacency lists, which then parse decimal IDs without building Strings).
extension MutableDirectedGraph {
    public init(
        dot input: some Sequence<UInt8>,
        vertex: (String) -> Vertex?,
        vertexAttribute: (Vertex, String, AttributeValue) -> Void = { _, _, _ in },
        edgeAttribute: (Edges.Index, String, AttributeValue) -> Void = { _, _, _ in },
        graphAttribute: (String, AttributeValue) -> Void = { _, _ in }
    ) throws(ParseError)
    public init(graphML input: some Sequence<UInt8>, vertex:, vertexAttribute:, edgeAttribute:, graphAttribute:) throws(ParseError)
    public init(nodeLinkJSON input: some Sequence<UInt8>,
                vertex: (AttributeValue) -> Vertex?,                 // id: .string or .integer
                vertexAttribute:, edgeAttribute:, graphAttribute:) throws(ParseError)
    public init(matrixMarket input: some Sequence<UInt8>,
                maximumVertexCount: Int? = nil,                      // above it: limitExceeded; nil: 16 × bytes + 4096
                vertex: (Int) -> Vertex?,                            // 0-based index
                edgeAttribute: (Edges.Index, String, AttributeValue) -> Void = …) throws(ParseError) // key "weight"
    public init(edgeList input: some Sequence<UInt8>, columns: [String] = [], vertex:, edgeAttribute:) throws(ParseError)
    public init(adjacencyList input: some Sequence<UInt8>, vertex:) throws(ParseError)
    public init(mermaid input: some Sequence<UInt8>, vertex:,
                vertexLabel: (Vertex, String) -> Void = { _, _ in },
                edgeLabel: (Edges.Index, String) -> Void = { _, _ in }) throws(ParseError)
}
extension MutableDirectedGraph where Vertex == String { /* the same, without vertex:, for all but matrixMarket */ }
extension MutableDirectedGraph where Vertex == Int    { /* matrixMarket, nodeLinkJSON, edgeList, adjacencyList without vertex: */ }
extension MutableGraph { /* the same seven, undirected */ }

// Writers. Closures are called once per vertex and edge, in order (GraphML: twice, see below).
extension DirectedGraph {
    public func writeDOT(
        to output: inout some TextOutputStream,
        vertexID: (Vertex) -> String = { String(describing: $0) },
        vertexAttributes: (Vertex) -> [(key: String, value: AttributeValue)] = { _ in [] },
        edgeAttributes: (Edges.Index) -> [(key: String, value: AttributeValue)] = { _ in [] },
        graphAttributes: [(key: String, value: AttributeValue)] = []
    )
    public func writeGraphML(to:, vertexID:, vertexAttributes:, edgeAttributes:, graphAttributes:)
    public func writeNodeLinkJSON(to:, vertexID: (Vertex) -> AttributeValue = …, vertexAttributes:, edgeAttributes:, graphAttributes:)
        // default vertexID: .integer for Vertex == Int, .string(String(describing:)) otherwise
    public func writeMatrixMarket(to output: inout some TextOutputStream)                                       // pattern
    public func writeMatrixMarket(to output: inout some TextOutputStream, weight: (Edges.Index) -> Int)          // integer
    public func writeMatrixMarket(to output: inout some TextOutputStream, weight: (Edges.Index) -> Double)       // real
    public func writeEdgeList(to:, vertexID:, columns: [String] = [], edgeAttributes:)
    public func writeAdjacencyList(to:, vertexID:)
    public func writeMermaid(to:, vertexID:,
                             vertexLabel: (Vertex) -> String? = { _ in nil },
                             edgeLabel: (Edges.Index) -> String? = { _ in nil })
}
extension Graph { /* the same nine */ }
```

Call sites:

```swift
var weight: [Int: Double] = [:]
let g = try DirectedPseudograph<String>(graphML: bytes, edgeAttribute: { e, key, value in
    if key == "weight", case .double(let w) = value { weight[e] = w }
})

var text = ""
g.writeDOT(to: &text, edgeAttributes: { e in [("weight", .double(weight[e] ?? 1))] })

let csr = try AdjacencyList<Int>(matrixMarket: file)        // then CompressedSparseRow(csr)
```

**Targets.** The undirected readers extend `MutableGraph` in `GraphProtocols`, the undirected
counterpart of `MutableDirectedGraph`, which `UndirectedAdjacencyList` and `Pseudograph` conform
to. Both protocols have the bulk hook the readers build through (Implementation, below).
`GraphFormats` depends on `GraphProtocols` alone. `Multigraph` and `DirectedMultigraph` (no loops)
and `CompressedSparseRow` (immutable) are read through a mutable representation and converted
(`CompressedSparseRow(adjacencyList)`, `LabeledGraph(...)`).

## Semantics

### Input and output

- **Input** is `some Sequence<UInt8>`: `text.utf8`, `[UInt8]`, a memory-mapped buffer. The reader
  takes `withContiguousStorageIfAvailable` (no copy for `String.UTF8View`, `Array`,
  `UnsafeBufferPointer`) and otherwise copies the sequence into one `[UInt8]` once. The whole
  input is read; there is no incremental reading.
- **Encoding.** UTF-8, validated as the scanner goes (`invalidUTF8` at the first bad byte, GF-041).
  One leading byte-order mark is skipped (GF-025). XML that declares another encoding is
  `unsupported` (GF-077); UTF-16 files are `invalidUTF8` at byte 0.
- **Output** is `inout some TextOutputStream` (`String`, a file handle wrapper, a socket
  wrapper). The writer fills a 64 KiB `String` buffer and calls `write(_:)` per full buffer, so a
  stream's per-call cost is paid 16 times per MiB. Every writer but node-link JSON ends its
  output with a line feed; lines end in LF only.
- Readers and writers do no file I/O: no Foundation, and the caller chooses the file API.

### Targets, vertices and edges

- **Kind.** The target's type fixes directed or undirected. A file of the other kind is
  `kindMismatch` at the token that decides it (`digraph`, `edgedefault`, `"directed"`, the Matrix
  Market symmetry, a Mermaid link; GF-027, GF-065, GF-092, GF-131, GF-175). Edge and adjacency
  lists carry no kind and read into either.
- **Vertices** are inserted in order of first appearance in the file (declarations first where the
  format declares them: GraphML and node-link nodes; Matrix Market inserts `0..<n` at once). The
  `vertex` closure maps each ID once (a dictionary from ID bytes to key, so a repeated ID costs one
  lookup, no closure call). If two IDs map to the same vertex they are one vertex.
- **Edges** are inserted in file order with the target's `_insertEdge(fromKey:toKey:)`, which
  returns the position the attribute callbacks get (every reader but DOT builds the same graph in
  one step, below). A simple target (`AdjacencyList`, `UndirectedAdjacencyList`) returns the existing position for a repeated pair, so a parallel
  edge in the file merges and its attributes are set again: last value wins (GF-019, GF-051,
  GF-119, GF-151).
- **Merging that the file demands.** DOT `strict` and node-link `"multigraph": false` merge
  parallel edges in any target (GF-020, GF-021, GF-087); the reader keeps a table from vertex-key
  pair to position for this, only when the file asks for it. Node-link `"multigraph": true` merges
  on `(u, v, key)`: an edge whose `key` is already taken between the same pair is that edge, its
  attributes set again (GF-233, GF-234).
- **IDs compare by Unicode scalars.** `"é"` precomposed and `"e"` + U+0301 are two IDs, two DOT
  default keys, two GraphML key names, two writer keys, and two writer IDs. Each ID is then mapped
  through the `vertex` closure: a `String` vertex merges the two, since `String`'s `==` is
  canonical equivalence (a declared GraphML or node-link node is then `duplicateVertex`), while a
  vertex type that compares scalars (`[Unicode.Scalar]`, `vertex: { Array($0.unicodeScalars) }`)
  keeps them apart. The reader does not normalize names.
- **Undirected orientation.** An undirected edge is inserted as written (`b -- a` is stored
  `UndirectedEdge(b, a)`), so writing it again gives the same text.

### Attributes

- **Values** are `AttributeValue` scalars. Per format: DOT values are all `.string` (DOT is
  untyped; `w=1` reads as `"1"`, GF-003); GraphML values take their key's `attr.type`
  (`boolean`; `int` and `long` → `.integer`; `float` and `double` → `.double`; `string`); JSON
  values keep their JSON type (an integer literal is `.integer`, a number with `.` or an exponent
  `.double`); Matrix Market weights are `.integer` or `.double` under the key `"weight"`; edge-list
  columns are typed by their text (an integer that fits `Int`; else a decimal double, infinite
  beyond `Double`, or `inf`, `infinity`, `nan` in any case with a sign, so that every double the
  writer prints reads back; else a string: GF-149, GF-152, GF-237); Mermaid labels are strings.
- **Read callbacks are setters**, called in document order, once per value set. For DOT that
  includes defaults: a vertex created after `node [k=v]` gets `k` before its explicit attributes
  (GF-005, GF-006). GraphML `<default>` values are reported for every element of
  that domain that has no `<data>` for the key, after its explicit data (GF-046). Repeated keys
  call again; a caller storing into a dictionary keeps the last. The readers that build in one step
  (all but DOT) report a vertex's or an edge's attributes once the whole file is read and the
  graph built, in document order, and not at all when the file holds an error: the line formats'
  edge values, GraphML's node and edge data (interleaved as the elements are), Mermaid's labels.
  Node-link JSON reports each node's attributes as the node is read (after its `id` is mapped, as
  before any edge) and the edges' after the build, so its order is the document's. Graph
  attributes are reported when read: before any vertex is mapped.
- **Defaults are applied, within a budget.** DOT's scoping (`node [..]` reaches only vertices
  created after it) means a default is reported to each vertex it reaches. The calls a file can
  multiply are bounded by its size, with the same budget as Mermaid's `&` groups: DOT
  `node`/`edge` defaults and edge-chain attribute lists (set on every hop), and GraphML
  `<default>`s, at most 16 calls per input byte plus 4,096; Mermaid `&` groups at most one edge per
  input byte plus 4,096. Past it a reader throws `limitExceeded` at the statement or element that
  crosses it. Without the bound, 2000 defaults and 50,000 vertices would be 10⁸ calls from 354 KB.
  A real file stays far inside (a vertex statement is several bytes, a Mermaid edge at least
  three).
- **Writers take closures** returning `[(key: String, value: AttributeValue)]`, the pairs in the
  order to write. Within one element a key appears once (precondition). The writers never invent
  attributes; `label` is an attribute like any other (except Mermaid's dedicated closures).
- A caller filling a `StableDirectedGraph`'s `EdgeMap` collects values into an array during the
  read and assigns them after, since the graph is being initialized.
- **Scalars only.** JSON's `null`, arrays and objects are `unsupported` (GF-097, GF-098).

### Errors and hostile input

- `ParseError` holds no vertex or attribute (it is `Sendable` and the vertex type need not be);
  `line`/`column` are 1-based, the column in Unicode scalars from the line start, LF ends a line
  (CR LF counts once; a lone CR is not a break), at the **first offending character** (the
  token that starts the problem). Tests pin `kind`, `line` and `column`; `description`
  (`"syntax error at 3:7"`) is not pinned.

| Kind | When |
|---|---|
| `invalidUTF8` | bytes that are not UTF-8 |
| `syntax` | anything the grammar does not allow, including a missing required attribute (`edgedefault`, `id`) |
| `unexpectedEndOfInput` | the input ends inside a token or construct: at the token's start (an unterminated string, comment, element) or at the end |
| `nestingTooDeep` | more than 64 nested XML elements or JSON containers, at the opening that exceeds it |
| `numberOutOfRange` | an integer outside `Int`, a double that overflows to infinity (GraphML `long`, JSON, Matrix Market) |
| `invalidValue` | a value the grammar admits but the format does not: a GraphML `int` that is `1.5`, a boolean `True`, a character reference to `&#0;`, a JSON lone surrogate, a Matrix Market fraction in an `integer` file, a hexadecimal float, a skew-symmetric diagonal entry |
| `invalidVertex` | the `vertex` closure returned `nil` (at the ID; Matrix Market: at the size line's first field, where the indices are mapped), or a node-link id that is a string or an integer but not of the target's type under the default mapping (a string id into an `Int` target, GF-095). A node-link id that is neither a string nor an integer (a double, a boolean, `null`, a container) is `invalidValue` at the id, before any mapping (GF-228) |
| `duplicateVertex` | a GraphML or node-link node declared twice |
| `undeclaredVertex` | an edge endpoint that is not a declared node (GraphML, node-link) |
| `duplicateKey` | a repeated XML attribute, GraphML key id or JSON object key |
| `undeclaredKey` | GraphML `<data>` whose key is not declared for that element kind |
| `kindMismatch` | the file's kind is not the target's |
| `entryCountMismatch` | Matrix Market entries fewer or more than the size line says |
| `indexOutOfRange` | a Matrix Market index outside `1...n` |
| `notSquare` | a Matrix Market matrix whose rows and columns differ |
| `doctypeNotAllowed`, `entityNotAllowed` | any `<!DOCTYPE`; any entity reference but `&lt; &gt; &amp; &quot; &apos;` and character references |
| `mismatchedTag` | an end tag that does not close the open element, or comes with no element open (`</a>` first, GF-227) |
| `unsupported` | a construct listed under Scope, another diagram or object type, another encoding |
| `limitExceeded` | a Matrix Market size line over `maximumVertexCount` (at its first field, GF-232, GF-257); a file over the expansion budget (DOT and GraphML defaults, DOT edge-chain attributes, Mermaid `&` groups; at the statement or element that crosses it) |

- **Error order.** A reader reports the first error in this order: invalid UTF-8 anywhere (the
  whole input is checked first, so a scalar cut at the end is `invalidUTF8` at its lead byte); for
  GraphML, then a character XML forbids anywhere (`syntax`); then the grammar, in document order
  (DOT lexes the whole input before parsing, so a lexical error anywhere comes before a grammar
  error; GraphML and JSON check the whole document's well-formedness before reading its meaning);
  then the meaning, in `ref.py`'s order: GraphML keys, the graph element, its own `<data>`, then
  nodes and edges in document order with every edge's resolution (undeclared endpoint, data values)
  after every node's checks; node-link `directed`, `multigraph`, `graph`, the presence and type of
  `nodes` and `edges`, every node, every edge. The line formats (Matrix Market, edge and adjacency
  lists, Mermaid) read in one pass, so their errors come in document order.
- **Limits.** Nesting depth 64 (a constant, documented, not a parameter). No DTD, so no entity
  expansion of any size (billion laughs, external entities). Integers are parsed with overflow
  checks. No reader reserves memory from a count in the file beyond what the input could hold: the
  Matrix Market entry count reserves at most `remaining bytes / 4` entries, so a 30-byte file
  claiming 10¹⁸ entries allocates nothing. The Matrix Market vertex count is inserted eagerly,
  because isolated vertices are part of the graph, and is bounded by `maximumVertexCount`. Its
  default, `nil`, bounds it by the input's size, 16 vertices per byte plus 4,096 (the expansion
  budget's rate), so a 69-byte file claiming 2²⁴ vertices (GF-257) or a 79-byte file claiming 10¹²
  is `limitExceeded` before anything is allocated; an explicit bound replaces it, for a matrix that
  is mostly isolated vertices. The work a file can multiply is
  bounded by its size (Attributes, the budget). Strings, lines and files have no length limit beyond memory: each
  costs memory linear in the input.
- **Strict.** Where a format leaves room, readers reject rather than guess: a single-token
  edge-list line, extra columns, Matrix Market comments after the size line, a signed index,
  hexadecimal floats, JSON `NaN`, duplicate keys, undeclared nodes. Accepting any of them would
  lose or invent data silently.

### DOT

- **Grammar**: `[strict] (graph | digraph) [ID] { stmt* }`, where a
  statement is `ID = ID`, `(graph | node | edge) attr_list`, `ID [attr_list]`, or `ID (op ID)+
  [attr_list]`; `attr_list` is one or more `[ (ID = ID [;|,])* ]`; statements may end in `;`
  or nothing (GF-026). Keywords are case-insensitive (GF-015). An `ID` is an identifier (letters,
  `_`, digits not first, any non-ASCII scalar), a numeral `-?(.[0-9]+ | [0-9]+(.[0-9]*)?)` of ASCII digits (a non-ASCII digit starts an identifier, GF-226), a
  quoted string (several joined by `+`, GF-012), or an HTML string `<…>` with balanced brackets
  (read as `.string` of its contents, GF-013). A numeral directly followed by an identifier
  character is `syntax` (GF-037). Comments: `//`, `/* */`, and lines
  starting with `#` (preprocessor output).
- **Quoted strings**: `\"` is a quote; backslash-newline is removed (line
  continuation, GF-011); every other backslash is kept as is (GF-010: `\n` is two characters, a
  label escape left to the caller).
- **Edge operators**: `->` in a digraph and `--` in a graph; the other is `syntax` (GF-029).
- **Strict** merges parallel edges, loops kept (GF-020, GF-021); attributes accumulate.
- **Writer** (canonical):

  ```
  digraph {                         graph { for a Graph; never strict
  	graph [k=v, …];               only when graphAttributes is not empty
  	ID [k=v, …];                  every vertex, in vertices order (brackets only with attributes)
  	ID -> ID [k=v, …];            every edge, in position order
  }
  ```

  One tab of indent, `, ` between attributes, LF line ends (GF-186 – GF-192). An ID is written
  bare when it is an ASCII identifier that is not a keyword (any case) or a numeral, otherwise
  quoted (GF-191: `"node"`, `1.5`, `"-x"`, `"é"`). Quoting escapes `"` as `\"`, and a backslash that
  ends the string or precedes a line feed is followed by a line continuation (backslash, line
  feed), so that it is not read as escaping the closing quote or the newline: every string round-
  trips exactly (GF-191, `"tail\\⏎"`). Values: `.string` as an ID; `.integer` as a numeral;
  `.double` in the short form (Numbers), bare when it is a numeral, quoted
  otherwise (`2.0`, `"1e-05"`, `"inf"`); `.boolean` as `true`/`false`. Isolated vertices and order
  are kept because every vertex is declared before any edge. A DOT HTML string reads as `.string`
  of its contents, so it comes back as a quoted string. No writer emits `strict`.

### GraphML and the XML subset

- **XML** (the subset GraphML needs, well-formedness per XML 1.0): an optional declaration
  (`version`, `encoding` = UTF-8 only, `standalone`), comments, processing instructions (skipped),
  elements with single- or double-quoted attributes, character data, CDATA sections, the five
  predefined entities and decimal or hexadecimal character references to XML `Char`s. No DTD
  (`<!DOCTYPE` anywhere is `doctypeNotAllowed`, GF-059), no other entity (`entityNotAllowed`,
  GF-060). C0 controls other than tab, LF, CR are `syntax` (GF-082). Attribute values are
  normalized (literal tab, LF and CR become spaces; a character reference is not, GF-054); CR LF
  in text becomes LF. Element names match by local name, attribute names as written; namespace prefixes and
  `xmlns` declarations are accepted and not checked.
- **GraphML**: the root's local name is `graphml`. `<key id for attr.name attr.type>`, `for`
  defaulting to `all`, `attr.type` to `string`, `attr.name` to the key id (GF-047); a `<default>`
  child gives the default. Exactly one `<graph>`, whose `edgedefault` is required (graphml.xsd:
  `use="required"`, GF-064). `<node id>` in document order; `<edge source target>` in document
  order, endpoints resolved after the whole graph is read (an edge may precede its nodes, GF-049).
  An edge's `directedView` attribute (an `xs:boolean`: `true`, `false`, `1`, `0`, surrounding
  whitespace collapsed, GF-241, GF-242) must equal `edgedefault` (`unsupported` otherwise, GF-076);
  `edgedefault` is an enumeration of tokens, so whitespace around it is collapsed too (GF-243). `<data>`
  with element content (graphics) is skipped (GF-055); unknown elements (`<desc>`, foreign
  namespaces) are skipped with their subtrees (GF-056). Typed values: `boolean` is `true`,
  `false`, `1`, `0` (XML Schema, GF-072); numbers allow surrounding whitespace (XML Schema
  collapse, GF-045); `double` accepts `INF`, `-INF`, `NaN`; a string keeps its whitespace.
- **Writer**:

  ```
  <?xml version="1.0" encoding="UTF-8"?>
  <graphml xmlns="http://graphml.graphdrawing.org/xmlns" xmlns:xsi="…" xsi:schemaLocation="…">
    <key id="d0" for="graph" attr.name="…" attr.type="…"/>    graph keys, then node, then edge keys
    <graph edgedefault="directed">
      <data key="d0">…</data>
      <node id="a"/>                                            no data: an empty element
      <node id="b">
        <data key="d1">…</data>
      </node>
      <edge source="a" target="b"/>
    </graph>
  </graphml>
  ```

  Two-space indent. Key ids `d0, d1, …` in order of first appearance per domain, graph keys
  first. Types: `.string` → `string`, `.integer` → `long` (64-bit), `.double` → `double`,
  `.boolean` → `boolean`; a key with both integers and doubles is `double` (GF-198); any other mix
  is a precondition failure. The closures are called **twice** per element (once to collect key
  types, once to write) and must return the same pairs both times; the writer holds no copy of
  the attributes. `vertexID` is called once per vertex: the
  IDs are kept, escaped, for the edges. Escaping: text `& < >` and CR as
  `&#13;`; attribute values also `"`, tab, LF, CR as references (so they survive normalization,
  GF-197). Doubles in the short form, `INF`, `-INF`, `NaN`. A string containing a character XML
  1.0 cannot represent (C0 controls other than tab, LF, CR; U+FFFE, U+FFFF) is a precondition
  failure.

### Node-link JSON

- **JSON** per RFC 8259, strictly: no `NaN`/`Infinity`, no trailing commas, no leading zeros, no raw
  control characters in strings, `\u` escapes with surrogate pairs (a lone surrogate is
  `invalidValue`), duplicate object keys `duplicateKey`, depth ≤ 64.
- **Layout**: `directed` (default `false`), `multigraph` (default `true`), `graph` (an object of
  scalars), `nodes` (required), and `edges` or, when `edges` is absent, `links` (GF-089): one of
  the two is required; a file with neither is `syntax` at the top-level object (GF-229). Each node
  has `id` (string or integer), the rest are attributes. Each edge has `source`, `target`, an
  optional `key`, and attributes. Other top-level members are ignored (GF-091). `multigraph: false`
  merges parallel edges, later attributes winning, and ignores keys (GF-087). `multigraph: true`
  merges on `(u, v, key)`: a key already taken between the pair is that edge, its attributes set
  again. An edge without a key, or with `null`, gets the number of keys between the pair, raised
  past any taken (GF-248, GF-258, GF-259). Keys compare as numbers where they are numbers (`true` is 1, an integral double
  its integer; the string `"1"` is not 1); an array or object key is `unsupported` (GF-233 –
  GF-236).
- **Writer** (GF-200 – GF-206): `", "` and `": "` separators, one line, and no final line feed
  (the one writer whose output does not end in LF). Member order `directed, multigraph, graph,
  nodes, edges`; a node is its attributes then `id`; an edge its attributes, `source`, `target`,
  then `key` when the graph is written as a multigraph. `multigraph` is `true` exactly when the
  graph has a parallel edge, and then each edge's `key` is the number of earlier edges between the
  same ordered (directed) or unordered pair (GF-204). Strings escape `"`, `\`, the C0 controls
  (`\n \r \t \b \f`, else `\u00XX`) and everything outside ASCII as `\uXXXX` with surrogate
  pairs (GF-206). Doubles in the short form; a non-finite double, an `id` that is neither
  `.string` nor `.integer`, or an attribute named `id` (node) or `source`/`target`/`key` (edge), is
  a precondition failure. Edges are written in position order. `ref.py` compares the write rows
  byte for byte with `json.dumps(nx.node_link_data(G, edges="edges"))` for the same graph built in
  the same order; NetworkX orders edges by adjacency, so on a graph whose edges are not grouped by
  source `ref.py` compares the edges as sets.

### Matrix Market

- **Readers** take `vertex: (Int) -> Vertex?` (the 0-based index), with an overload without it where
  `Vertex == Int`. There is no `Vertex == String` overload: the IDs are indices, and a `String`
  target names them through `vertex:` (`{ String($0) }`).
- **Banner** `%%MatrixMarket` exactly (GF-126), then `matrix
  coordinate (pattern | integer | real) (general | symmetric | skew-symmetric)`, case-insensitive
  (GF-121). Comment lines (`%`) and blank lines until the size line `n n entries`; after it,
  blank lines are allowed and comments are `syntax` (GF-142). Fields are separated
  by spaces or tabs; CR LF and a missing final newline are fine (GF-113, GF-124). Each entry has
  exactly 2 (`pattern`) or 3 fields; indices are unsigned decimals in `1...n`; `integer` values fit
  `Int`; `real` values are decimal floats or `inf`, `infinity`, `nan` in any case with a sign.
- **Graph**: vertices `0..<n` (the `vertex` closure maps the index), even with no entries
  (GF-117), at most `maximumVertexCount` of them (default `nil`: 16 per input byte plus 4,096,
  which every file with an entry per 64 vertices meets, as each entry takes at least 4 bytes;
  above it `limitExceeded` at the size line's first field, GF-232, GF-257). Directed target: `general` → an arc row → column per entry; `symmetric` → arcs (r, c) then (c, r), one arc for a
  diagonal entry (GF-115); `skew-symmetric` → the mirrored arc gets the negated weight (GF-116).
  Undirected target: `symmetric` only, one edge per entry as written (GF-114); either triangle is
  accepted (GF-122). Duplicate entries are parallel edges (GF-118). An integer entry of `Int.min` in a skew-symmetric file has no mirror in `Int`: `numberOutOfRange` at the value (GF-230). An entry is an edge whatever
  its value (an explicit `0` too).
- **Writer**: `general` (directed) or `symmetric` (undirected, entries in the lower triangle,
  row ≥ column): banner, a `%` line, `n n m`, then one entry per edge in position order with
  1-based indices in `vertices` order (GF-207 – GF-214). `pattern` without `weight:`, `integer`
  with an `Int` closure, `real` with a `Double` closure. Reals as the shortest round-trip digits in
  the form `d[.ddd]E<e>`, the exponent omitted when it is 0 (`1`, `1E-1`, `1.2345E3`, `-2`, `1E20`,
  `1.152921504606847E18`, `-0`, `Infinity`, `NaN`; GF-209, GF-210). `ref.py` compares the write
  rows byte for byte with SciPy 1.18's `mmwrite` (`symmetry="general"` or `"symmetric"`).

### Edge list and adjacency list

- Lines split at LF; `#` starts a comment anywhere on a line; fields are runs of characters that
  are not Unicode whitespace: tab, LF, VT, FF, CR, U+001C – U+001F, space, U+0085, NBSP, U+1680,
  U+2000 – U+200A, U+2028, U+2029, U+202F, U+205F, U+3000 (GF-238 – GF-240); blank lines are
  skipped. (Matrix Market fields are separated by spaces and tabs only.) Edge list: exactly
  `2 + columns.count` fields (GF-153 – GF-155). Adjacency list: the first field is a vertex (inserted
  even alone, GF-156), the others its neighbours, one edge each in order.
- **Writers**: edge list `u v [values]` per edge in position order (isolated vertices are not
  written, GF-215); adjacency list one line per vertex in `vertices` order, directed: its
  out-edges' targets in position order; undirected: each edge on the line of its endpoint that
  comes first in `vertices` order, a loop once (GF-219 – GF-221). `ref.py` compares both byte for
  byte with NetworkX's `write_edgelist` and `write_adjlist` (minus its three `#` header lines) on
  simple graphs. IDs and string values must be non-empty and contain no whitespace (in the
  readers' sense above) or `#` (precondition). Booleans cannot be written to an edge list (they
  would read back as strings): precondition. So is an edge whose attributes lack one of
  `columns`; its short line would read back as a syntax error. `edgeAttributes` is called once per edge even without columns.

### Mermaid

- **Reader**: optional front matter (`---` … `---`), `%%` comment lines (also `%%{init}%%`
  directives), then the header `flowchart` or `graph` with an optional `TB TD BT RL LR` (dropped:
  layout). Another diagram keyword is `unsupported`, anything else `syntax` (GF-181, GF-182).
  Statements end at LF, `;` or a carriage return (CR LF counts once, GF-231). `classDef`, `class`, `style`, `linkStyle` and `click` lines are
  skipped (styling), as is `:::class` after a vertex (GF-171), when the keyword is followed by
  blanks and then a name (a vertex, a class, a link number); followed by anything else
  (`style --> B`, `class & A --> C`) the keyword is a vertex (GF-244). A vertex is `[A-Za-z0-9_]+`, not
  `end`, which closes a subgraph in Mermaid (`unsupported`, GF-184), with an optional shape `[…] (…) ([…]) [[…]] [(…)]
  ((…)) (((…))) {…} {{…}} >…] [/…/] [\…\] [/…\] [\…/]` whose text is the label (quoted text verbatim,
  unquoted text trimmed), the shape dropped (GF-165). A later label replaces an earlier one
  (GF-167). Labels decode Mermaid's entity codes `#quot; #amp; #lt; #gt;` and decimal `#NNN;`
  (GF-166). Links: `-{2,}[>ox]`, `-.+-[>ox]`, `={2,}[>ox]` are directed (arrow, circle and cross
  heads are all heads); `-{3,}`, `-.+-`, `={3,}` are open (undirected); a label follows as
  `|text|` or sits inside as `-- text -->`, `-. text .->`, `== text ==>` (GF-168, GF-169). A head
  letter directly after the dashes belongs to the link (`A---oB` is A to B, GF-174). `A & B --> C & D` adds every source–target pair, sources outer (GF-164).
  A directed target rejects open links, an undirected one rejects heads (`kindMismatch`), so a
  flowchart that mixes `-->` and `---` reads into neither. A simple target merges a repeated link,
  its last label winning (GF-245, GF-246). The edges `&` groups add are bounded by the input's
  size (Attributes, the budget): without the bound, 3000 × 3000 from 45 KB would be 9·10⁶ edges.
- **Writer**:

  ```
  flowchart TD
      ID                          every vertex in vertices order; ID["label"] when it has one
      ID --> ID                   every edge in position order; --- for a Graph
      ID -->|"label"| ID
  ```

  Four-space indent. Labels are always quoted, with `#` `"` `&` `<` `>` LF CR written as
  `#35; #quot; #amp; #lt; #gt; #10; #13;`, so any string round-trips through the reader (GF-222).
  IDs must match `[A-Za-z0-9_]+` and not be `end graph flowchart subgraph style classDef class
  click linkStyle direction` (precondition); a caller with arbitrary vertex names passes
  `vertexID:` (indices) and `vertexLabel:` (the names).
- **Every writer that names vertices** requires distinct IDs (precondition): two vertices with one
  ID would read back as one. IDs compare by Unicode scalars, so canonically equivalent but
  different IDs are distinct.

### Round trips

What `read(write(g))` gives back, into a target of the same kind and type:

| Format | Vertices and order | Edges, positions, parallel edges, loops | Attributes |
|---|---|---|---|
| DOT | all, same order | same | every key; values come back as `.string` (`.integer(2)` → `"2"`, `.double(2.0)` → `"2.0"`, `.boolean(true)` → `"true"`) |
| GraphML | all, same order | same | exact, typed; an integer under a key that also holds doubles comes back `.double` |
| node-link JSON | all, same order | same | exact, typed |
| Matrix Market | all as indices `0..<n` in `vertices` order | same; undirected edges come back as (larger index, smaller index) | `weight` only, exact (reals print shortest round-trip digits) |
| edge list | isolated vertices lost; order = first appearance in edges | same | the `columns`, re-typed by their text (`.string("12")` → `.integer(12)`) |
| adjacency list | all; order = first appearance on lines | same edges; positions grouped by line | none |
| Mermaid | all, same order (IDs restricted) | same | `label` only, exact |

## Numbers

- **Doubles, written**: DOT, GraphML, node-link JSON and the edge list use the short form: the
  shortest digits that round-trip, positional when the decimal exponent is in `-4 ..< 16`,
  otherwise `d.ddde±XX` with at least two exponent digits (`2.0`, `0.0001`, `1e-05`, `1e+16`). The
  digits come from the module's own Schubfach (below), the same digits as `description`, which
  switches to exponent form at 2⁵³ instead of 10¹⁶ (`description` gives `9.5e+15` where the
  writers give `9500000000000000.0`).
  Matrix Market uses its own form (above).
- **Doubles, read**: the grammar is checked first (decimal only: no hexadecimal floats, no
  `nan(…)` payloads), then Eisel–Lemire over a table of 128-bit powers of five: the first 19
  significant digits give the answer whenever it is decided, and when digits were dropped the
  truncated and the next value must agree; the rare input it cannot decide goes to the standard
  library's `Double(_:)` (correctly rounded). A test compares every result with `Double(_:)` on
  random digits, near-ties and the extremes. Overflow to infinity is `numberOutOfRange` in JSON,
  GraphML and Matrix Market, and an infinite value in an edge-list column.
- **Integers** are parsed by hand with overflow checks, to `Int` (64-bit). GraphML `int` is 32-bit
  in XML Schema; it is read as `Int` and written as `long`.

## Implementation

- **Scanners.** The module has its own scanners over the UTF-8 bytes: an XML subset for GraphML
  that rejects a DTD before any expansion can happen, and JSON. Every error has a position.
- **One scanner style for all formats**: an index into the contiguous buffer, `@inline(__always)`
  byte tests, IDs compared as byte slices and hashed with the standard `Hasher` over the bytes (an
  open-addressing table whose slots hold a hash tag and an ID's first 8 bytes, so a short ID is
  found without touching the arena of ID bytes). A `String` is created only for a new ID, and for
  `Vertex == Int` never. Line and column are computed only when an error is thrown, from the byte
  offset.
- **Writers** format integers and doubles into a stack buffer and append bytes to a 64 KiB
  `String` buffer flushed through `TextOutputStream.write(_:)`; no intermediate `String` per
  value. A double's shortest digits come from Schubfach (Giulietti, "The Schubfach way to render
  doubles"): 64-bit multiplications against a table of 617 126-bit entries, generated from its
  definition with exact rational arithmetic (`scripts/schubfach_table.py`), and the digits written
  two at a time. A property test checks its digits against `description` on random bit patterns,
  both ends of every binade, subnormals and the 9·10¹⁵ – 2⁵⁴ band.
- **The readers build in one step.** Matrix Market, the edge list and the adjacency list read the
  whole file into a list of vertices and `(uKey, vKey)` pairs in file order (one pass that parses
  each field as it scans it), then hand them to the representation's bulk hook
  (`MutableDirectedGraph._built` / `MutableGraph._built`, callable only from inside the package
  through `_ConstructionToken`). The dense representations lay out every row at its exact size by
  a stable counting sort, O(n + m), so each row lists its edges in position order, as one
  insertion per edge would; the simple lists first drop repeated pairs and map each pair to its
  first copy's position; the multigraphs keep every pair. Edge attributes are buffered during the
  read and replayed with the built graph's positions. Any other conformer
  (`StableDirectedGraph`) gets the default: one insertion per edge. GraphML, node-link JSON and
  Mermaid build the same way: their nodes and edges go into the same bulk target, their vertex and
  edge attributes (or labels) into the same buffer, replayed after the build in document order.
  DOT inserts as it reads.
- **Node-link JSON in the common layout is read in one pass.** The top-level members in the order
  `directed`, `multigraph`, `graph`, `nodes`, then `edges` or `links`, each once; keys without
  escapes; scalar node and edge members; and edges naming nodes declared before them. That
  document is checked as `validateDocument` checks it while its nodes and edges are read. Anything
  else, and any error, goes to the two-pass reader (the document checked first), which reports
  every error; the one pass has called nothing by then. Its `id` mapping comes after the pass, in
  node order with each node's attributes, which is when and how the two-pass reader makes it.
- **GraphML reads its nodes and edges in the first walk when it can.** The walk that checks the
  document also notes the first graph's nodes and edges (`_GraphMLLookahead`: their IDs and values
  where they are in the text), with their keys checked and defaults spent, and after the walk looks
  up the IDs and reads the values, without the `vertex` mapping. It goes on while it can tell the
  second walk would read the graph the same way: keys all before the graph, every node and edge
  check and value passing, edges naming nodes declared before them; otherwise the second walk
  reads the graph. When the lookahead holds, the keys, graph and graph-data checks run, and then
  the IDs are mapped in node order. `GraphFormatsOnePassTests.swift` and `FuzzGraphFormats` read
  documents both ways.
- **Specialization.** The readers and writers are `@inlinable` down to the scanners, so a call on a
  concrete representation (`DirectedPseudograph<Int>`) is specialized in the caller's module: the
  target's insertions, the edge iteration and the attribute closures are direct calls.
- The representations' `Codable` conformances (vertices and position pairs) are separate from
  these formats.

## Complexity

| Operation | Time | Extra memory |
|---|---|---|
| every reader | O(input bytes + n + m) expected (one hash per ID occurrence), plus the calls and edges defaults and `&` groups add, at most 16 (DOT, GraphML) or 1 (Mermaid) per input byte | O(n) ID table; O(m) pair table only for DOT `strict` and node-link `multigraph: false`, and an O(m) table of `(u, v, key)` for node-link `multigraph: true`; GraphML holds the edges until the graph's nodes are known (O(m)); the line formats hold the vertices and key pairs (O(n + m)) and their edge attributes until the build. A GraphML element costs O(its data + the defaults of its domain); a JSON object or XML tag of k keys O(k) (one shared index with generation stamps) |
| every writer | O(n + m + output bytes), plus the closures' cost (GraphML: called twice) | O(n) for the vertex IDs, kept as escaped bytes, beyond a 64 KiB buffer; node-link JSON O(m) for the parallel-edge keys (a table of pairs and one `Int32` per edge, found in one pass); the adjacency list O(n + m) to group the edges by line; GraphML O(keys) |
| error position | O(offset of the error), once | O(1) |

## Library disagreements

`ref.py` lists these rows in `KNOWN`; each is a place where the library named reads or writes
differently from this module.

| Where | What | Catalog |
|---|---|---|
| GraphML `<default>` | NetworkX stores defaults in `G.graph["node_default"]` and does not give them to nodes; GraphML says a default applies where no data is given. Here: applied | GF-046 |
| GraphML entities | NetworkX (expat) expands internal DTD entities: `<!ENTITY e "zz">` makes a node `zz`. Here: `doctypeNotAllowed` before anything is expanded | GF-059 |
| GraphML `edgedefault` | NetworkX reads a missing `edgedefault` as undirected; graphml.xsd declares it `use="required"`. Here: `syntax` | GF-064 |
| GraphML integrity | NetworkX adds an undeclared edge endpoint as a node, merges a duplicate node id, flattens nested graphs, reads only the first `<graph>`, requires `attr.name`, decodes ISO-8859-1, and has no depth limit | GF-047, GF-066, GF-067, GF-073, GF-074, GF-077, GF-079 |
| GraphML writer | NetworkX writes two `<key>`s with the same `attr.name` (`long` and `double`) when one attribute holds Python ints and floats; here one `double` key | GF-198 |
| node-link JSON | NetworkX 3.7 raises `KeyError: 'edges'` on files with `links` (its own pre-3.4 default) unless told `edges="links"`; here either is read | GF-089 |
| JSON parsing | Python's `json.loads` accepts `NaN`/`Infinity`, keeps the last of duplicate keys, keeps lone surrogates, and reads integers of any size; NetworkX adds undeclared edge endpoints, keeps `null`/list attributes, and names a node without `id` `None` | GF-093 – GF-104, GF-110 |
| Matrix Market | SciPy truncates `3.5` in an `integer` file to `3`, reads `0x1p3` as `0.0`, ignores extra columns, accepts `+1` as an index, a skew-symmetric diagonal, and `pattern skew-symmetric` (which the spec forbids); writes field `real` for any empty matrix, even with `field="pattern"` | GF-137 – GF-146, GF-213 |
| Matrix Market symmetry | SciPy's `mmwrite(A)` without `symmetry=` detects a symmetric matrix and writes `symmetric`; here `general` for every directed graph (so the kind is the type's, not the data's) | `ref.py` passes `symmetry="general"` |
| Matrix Market vertex count | SciPy makes a 2²⁴ or 2²⁴ + 1 square empty matrix lazily; here: `limitExceeded` above `maximumVertexCount` (by default 16 per input byte plus 4,096) | GF-232, GF-257 |
| GraphML `edgedefault` | NetworkX compares `edgedefault` without collapsing whitespace, so `" directed "` reads undirected; here it is collapsed (an enumeration of tokens) | GF-243 |
| Edge list | NetworkX skips lines with fewer than two fields, ignores fields past the declared data, and accepts a line without its data; here: `syntax` | GF-153 – GF-155 |
| Adjacency list | NetworkX `read_adjlist` raises `IndexError` on a line that is only a comment | GF-160 |
| DOT (pydot 4.0.1) | pydot accepts `--` in a digraph, `[k]` without a value, and either kind in any context; keeps a port in the vertex name (`a:p`); splits `1a`; rejects a negative numeral after an edge operator, `;` inside `[ ]`, a second `[ ]`, and a byte-order mark; does not apply `node`/`edge` defaults; does not merge `strict` edges; keeps a backslash before a quote and drops line continuations; crashes on a graph attribute called `name` and on some quoted IDs that start with `-`. Graphviz's scan.l is the reference here, not pydot | GF-014 – GF-038, GF-191 |
