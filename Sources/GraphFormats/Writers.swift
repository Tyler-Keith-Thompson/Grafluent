import GraphProtocols

// The writers: a method per format on every `DirectedGraph` and `Graph`. Each writes canonical,
// deterministic text into a `TextOutputStream`, in pieces of at most 64 KiB, taking vertex IDs and
// attributes from closures (the attribute pairs in the order to write, each key once per element).
// Every writer but node-link JSON ends its output with a line feed; lines end in LF only.
//
// Data the format cannot represent throws a `WriteError`, and a writer that throws has written
// nothing to `output`. DOT, GraphML, the adjacency list and Mermaid check before they write, and
// stream; node-link JSON and the edge list check as they write, and hold their output until the
// end. A caller's closure that breaks its contract (a key twice for one element, a missing edge-list
// column, a node-link ID that is neither a string nor an integer) traps.

/// A vertex's ID by default: `String(describing:)`, with `Int` and `String` vertices taken
/// directly (in specialized code the casts are free).
@inlinable
internal func _defaultVertexID<Vertex>(_ vertex: Vertex) -> String {
    if let i = vertex as? Int { return String(i) }
    if let s = vertex as? String { return s }
    return String(describing: vertex)
}

// MARK: - DirectedGraph

extension DirectedGraph {
    /// Writes the graph as canonical DOT.
    ///
    /// The output is `digraph {`, the graph attributes, every vertex in `vertices` order, then every
    /// edge in position order, one tab of indent. An ID is bare when DOT allows it and quoted
    /// otherwise, so any string can be one.
    ///
    /// - Parameters:
    ///   - output: The stream the text is appended to.
    ///   - vertexID: Each vertex's ID, called once per vertex. Defaults to its description.
    ///   - vertexAttributes: Each vertex's attribute pairs, in the order to write; each key once.
    ///   - edgeAttributes: Each edge's attribute pairs, by position; each key once.
    ///   - graphAttributes: The graph's attribute pairs; each key once.
    /// - Complexity: O(n + m + output size), plus the closures' cost.
    /// - Throws: `WriteError.duplicateID` when two vertices have the same ID, compared by Unicode
    ///   scalars. Checked before anything is written.
    ///
    /// Traps when an attribute closure gives one key twice for one element.
    @inlinable public func writeDOT(
        to output: inout some TextOutputStream,
        vertexID: (Vertex) -> String = { _defaultVertexID($0) },
        vertexAttributes: (Vertex) -> [(key: String, value: AttributeValue)] = { _ in [] },
        edgeAttributes: (Edges.Index) -> [(key: String, value: AttributeValue)] = { _ in [] },
        graphAttributes: [(key: String, value: AttributeValue)] = []
    ) throws(WriteError) {
        try _withOutputBuffer(&output) { (out) throws(WriteError) in
            try _writeDOT(_DirectedSource(self), to: &out, vertexID: vertexID, vertexAttributes: vertexAttributes,
                          edgeAttributes: edgeAttributes, graphAttributes: graphAttributes)
        }
    }

    /// Writes the graph as GraphML.
    ///
    /// The output is a typed `<key>` per attribute name and domain, then every vertex and edge with
    /// its `<data>`. The attribute closures are called twice per element (to type the keys, then to
    /// write) and must return the same pairs both times; `vertexID` is called once per vertex.
    ///
    /// - Parameters:
    ///   - output: The stream the text is appended to.
    ///   - vertexID: Each vertex's ID, called once per vertex. Defaults to its description.
    ///   - vertexAttributes: Each vertex's attribute pairs, in the order to write; each key once.
    ///   - edgeAttributes: Each edge's attribute pairs, by position; each key once.
    ///   - graphAttributes: The graph's attribute pairs; each key once.
    /// - Complexity: O(n + m + output size), plus the closures' cost.
    /// - Throws: A `WriteError`, checked before anything is written:
    ///   - `duplicateID` when two vertices have the same ID, compared by Unicode scalars;
    ///   - `invalidID`, `invalidKey` or `invalidValue` when an ID, an attribute name or a string
    ///     value holds a character XML 1.0 cannot represent (a C0 control other than tab, line feed
    ///     and carriage return, U+FFFE or U+FFFF);
    ///   - `typeMismatch` when one attribute name holds values of two types other than integers and
    ///     doubles.
    ///
    /// Traps when an attribute closure gives one key twice for one element.
    @inlinable public func writeGraphML(
        to output: inout some TextOutputStream,
        vertexID: (Vertex) -> String = { _defaultVertexID($0) },
        vertexAttributes: (Vertex) -> [(key: String, value: AttributeValue)] = { _ in [] },
        edgeAttributes: (Edges.Index) -> [(key: String, value: AttributeValue)] = { _ in [] },
        graphAttributes: [(key: String, value: AttributeValue)] = []
    ) throws(WriteError) {
        try _withOutputBuffer(&output) { (out) throws(WriteError) in
            try _writeGraphML(_DirectedSource(self), to: &out, vertexID: vertexID, vertexAttributes: vertexAttributes,
                              edgeAttributes: edgeAttributes, graphAttributes: graphAttributes)
        }
    }

    /// Writes the graph as node-link JSON.
    ///
    /// The output is one line, with `", "` and `": "` between items, every character outside ASCII
    /// escaped, and no final line feed. The text reaches `output` once the whole document is made.
    ///
    /// - Parameters:
    ///   - output: The stream the text is appended to.
    ///   - vertexID: Each node's `id`, a string or an integer, called once per vertex. Defaults to
    ///     an `Int` vertex as a number and any other as its description.
    ///   - vertexAttributes: Each vertex's attribute pairs, in the order to write; each key once.
    ///   - edgeAttributes: Each edge's attribute pairs, by position; each key once.
    ///   - graphAttributes: The graph's attribute pairs; each key once.
    /// - Complexity: O(n + m + output size), plus the closures' cost.
    /// - Throws: A `WriteError`, and then nothing is written:
    ///   - `duplicateID` when two vertices have the same ID, compared by Unicode scalars;
    ///   - `invalidValue` when a value is a NaN or infinite double;
    ///   - `reservedKey` when a vertex has an attribute named `id`, or an edge one named `source`,
    ///     `target` or `key`.
    ///
    /// Traps when `vertexID` returns a double or a boolean, or when an attribute closure gives one
    /// key twice for one element.
    @inlinable public func writeNodeLinkJSON(
        to output: inout some TextOutputStream,
        vertexID: (Vertex) -> AttributeValue = { ($0 as? Int).map(AttributeValue.integer) ?? .string(_defaultVertexID($0)) },
        vertexAttributes: (Vertex) -> [(key: String, value: AttributeValue)] = { _ in [] },
        edgeAttributes: (Edges.Index) -> [(key: String, value: AttributeValue)] = { _ in [] },
        graphAttributes: [(key: String, value: AttributeValue)] = []
    ) throws(WriteError) {
        try _withHeldOutputBuffer(&output) { (out) throws(WriteError) in
            try _writeNodeLinkJSON(_DirectedSource(self), to: &out, vertexID: vertexID, vertexAttributes: vertexAttributes,
                                   edgeAttributes: edgeAttributes, graphAttributes: graphAttributes)
        }
    }

    /// Writes the graph as a Matrix Market `pattern` coordinate file, with 1-based indices in
    /// `vertices` order.
    ///
    /// - Parameter output: The stream the text is appended to.
    /// - Complexity: O(n + m + output size).
    @inlinable public func writeMatrixMarket(to output: inout some TextOutputStream) {
        _withOutputBuffer(&output) { out in
            _writeMatrixMarket(_DirectedSource(self), to: &out, field: "pattern", hasValue: false, value: { _, _ in })
        }
    }

    /// Writes the graph as a Matrix Market `integer` coordinate file, each edge's `weight` its value.
    ///
    /// - Parameters:
    ///   - output: The stream the text is appended to.
    ///   - weight: Each edge's value, by position.
    /// - Complexity: O(n + m + output size), plus the closure's cost.
    @inlinable public func writeMatrixMarket(to output: inout some TextOutputStream, weight: (Edges.Index) -> Int) {
        _withOutputBuffer(&output) { out in
            _writeMatrixMarket(_DirectedSource(self), to: &out, field: "integer", hasValue: true, value: { position, out in out.appendDecimal(weight(position)) })
        }
    }

    /// Writes the graph as a Matrix Market `real` coordinate file, each edge's `weight` its value.
    ///
    /// A value is written as its shortest round-trip digits in the form `d[.ddd]E<e>`; a NaN or
    /// infinity as `NaN`, `Infinity` or `-Infinity`.
    ///
    /// - Parameters:
    ///   - output: The stream the text is appended to.
    ///   - weight: Each edge's value, by position.
    /// - Complexity: O(n + m + output size), plus the closure's cost.
    @inlinable public func writeMatrixMarket(to output: inout some TextOutputStream, weight: (Edges.Index) -> Double) {
        _withOutputBuffer(&output) { out in
            _writeMatrixMarket(_DirectedSource(self), to: &out, field: "real", hasValue: true, value: { position, out in _appendMatrixMarketDouble(weight(position), to: &out) })
        }
    }

    /// Writes the graph as an edge list: `u v` and the value of each of `columns`, one line per edge
    /// in position order, the fields separated by a space or by `delimiter`.
    ///
    /// Isolated vertices are not written, and `vertexID` is called only for the vertices an edge
    /// names. The text reaches `output` once the whole list is made.
    ///
    /// - Parameters:
    ///   - output: The stream the text is appended to.
    ///   - vertexID: Each vertex's ID, called once per vertex an edge names. Defaults to its
    ///     description.
    ///   - columns: The attribute names whose values follow the endpoints, in order.
    ///   - delimiter: The field separator; `nil`, the default, is a space. It must be ASCII and not
    ///     a letter, a digit, `.`, `+`, `-`, `#`, LF or CR.
    ///   - edgeAttributes: Each edge's attribute pairs, by position; each key once, and a value for
    ///     every name in `columns`.
    /// - Complexity: O(n + m + output size), plus the closures' cost.
    /// - Throws: A `WriteError`, and then nothing is written:
    ///   - `duplicateID` when two vertices have the same ID, compared by Unicode scalars;
    ///   - `invalidID` when an ID is empty or holds whitespace or `#` (with a delimiter: holds the
    ///     delimiter, `#`, LF or CR);
    ///   - `invalidValue` when a column's value is a boolean, or a string that could not be one
    ///     field in the same way.
    ///
    /// Traps when an edge's attributes have no value for one of `columns`, or give one key twice,
    /// or when `delimiter` is not allowed.
    @inlinable public func writeEdgeList(
        to output: inout some TextOutputStream,
        vertexID: (Vertex) -> String = { _defaultVertexID($0) },
        columns: [String] = [],
        delimiter: Unicode.Scalar? = nil,
        edgeAttributes: (Edges.Index) -> [(key: String, value: AttributeValue)] = { _ in [] }
    ) throws(WriteError) {
        try _withHeldOutputBuffer(&output) { (out) throws(WriteError) in
            try _writeEdgeList(_DirectedSource(self), to: &out, vertexID: vertexID, columns: columns,
                               delimiter: _listDelimiter(delimiter), edgeAttributes: edgeAttributes)
        }
    }

    /// Writes the graph as an adjacency list: one line per vertex in `vertices` order, the vertex
    /// and then the far end of each of its edges.
    ///
    /// - Parameters:
    ///   - output: The stream the text is appended to.
    ///   - vertexID: Each vertex's ID, called once per vertex. Defaults to its description.
    /// - Complexity: O(n + m + output size), plus the closures' cost.
    /// - Throws: A `WriteError`, checked before anything is written:
    ///   - `duplicateID` when two vertices have the same ID, compared by Unicode scalars;
    ///   - `invalidID` when an ID is empty or holds whitespace or `#`.
    @inlinable public func writeAdjacencyList(
        to output: inout some TextOutputStream,
        vertexID: (Vertex) -> String = { _defaultVertexID($0) }
    ) throws(WriteError) {
        try _withOutputBuffer(&output) { (out) throws(WriteError) in
            try _writeAdjacencyList(_DirectedSource(self), to: &out, vertexID: vertexID)
        }
    }

    /// Writes the graph as a Mermaid flowchart (`flowchart TD`): every vertex, with its label when
    /// it has one, then every edge.
    ///
    /// A label may hold any text. A caller whose vertices have arbitrary names passes IDs such as
    /// indices through `vertexID` and the names through `vertexLabel`.
    ///
    /// - Parameters:
    ///   - output: The stream the text is appended to.
    ///   - vertexID: Each vertex's ID, called once per vertex. Defaults to its description.
    ///   - vertexLabel: Each vertex's label, or `nil` for none.
    ///   - edgeLabel: Each edge's label, by position, or `nil` for none.
    /// - Complexity: O(n + m + output size), plus the closures' cost.
    /// - Throws: A `WriteError`, checked before anything is written:
    ///   - `duplicateID` when two vertices have the same ID;
    ///   - `invalidID` when an ID is not `[A-Za-z0-9_]+` or is a Mermaid keyword (`end`, `graph`,
    ///     `flowchart`, `subgraph`, `style`, `classDef`, `class`, `click`, `linkStyle`,
    ///     `direction`).
    @inlinable public func writeMermaid(
        to output: inout some TextOutputStream,
        vertexID: (Vertex) -> String = { _defaultVertexID($0) },
        vertexLabel: (Vertex) -> String? = { _ in nil },
        edgeLabel: (Edges.Index) -> String? = { _ in nil }
    ) throws(WriteError) {
        try _withOutputBuffer(&output) { (out) throws(WriteError) in
            try _writeMermaid(_DirectedSource(self), to: &out, vertexID: vertexID, vertexLabel: vertexLabel, edgeLabel: edgeLabel)
        }
    }
}

// MARK: - Graph

extension Graph {
    /// Writes the graph as canonical DOT.
    ///
    /// The output is `graph {`, the graph attributes, every vertex in `vertices` order, then every
    /// edge in position order, one tab of indent. An ID is bare when DOT allows it and quoted
    /// otherwise, so any string can be one.
    ///
    /// - Parameters:
    ///   - output: The stream the text is appended to.
    ///   - vertexID: Each vertex's ID, called once per vertex. Defaults to its description.
    ///   - vertexAttributes: Each vertex's attribute pairs, in the order to write; each key once.
    ///   - edgeAttributes: Each edge's attribute pairs, by position; each key once.
    ///   - graphAttributes: The graph's attribute pairs; each key once.
    /// - Complexity: O(n + m + output size), plus the closures' cost.
    /// - Throws: `WriteError.duplicateID` when two vertices have the same ID, compared by Unicode
    ///   scalars. Checked before anything is written.
    ///
    /// Traps when an attribute closure gives one key twice for one element.
    @inlinable public func writeDOT(
        to output: inout some TextOutputStream,
        vertexID: (Vertex) -> String = { _defaultVertexID($0) },
        vertexAttributes: (Vertex) -> [(key: String, value: AttributeValue)] = { _ in [] },
        edgeAttributes: (Edges.Index) -> [(key: String, value: AttributeValue)] = { _ in [] },
        graphAttributes: [(key: String, value: AttributeValue)] = []
    ) throws(WriteError) {
        try _withOutputBuffer(&output) { (out) throws(WriteError) in
            try _writeDOT(_UndirectedSource(self), to: &out, vertexID: vertexID, vertexAttributes: vertexAttributes,
                          edgeAttributes: edgeAttributes, graphAttributes: graphAttributes)
        }
    }

    /// Writes the graph as GraphML.
    ///
    /// The output is a typed `<key>` per attribute name and domain, then every vertex and edge with
    /// its `<data>`. The attribute closures are called twice per element (to type the keys, then to
    /// write) and must return the same pairs both times; `vertexID` is called once per vertex.
    ///
    /// - Parameters:
    ///   - output: The stream the text is appended to.
    ///   - vertexID: Each vertex's ID, called once per vertex. Defaults to its description.
    ///   - vertexAttributes: Each vertex's attribute pairs, in the order to write; each key once.
    ///   - edgeAttributes: Each edge's attribute pairs, by position; each key once.
    ///   - graphAttributes: The graph's attribute pairs; each key once.
    /// - Complexity: O(n + m + output size), plus the closures' cost.
    /// - Throws: A `WriteError`, checked before anything is written:
    ///   - `duplicateID` when two vertices have the same ID, compared by Unicode scalars;
    ///   - `invalidID`, `invalidKey` or `invalidValue` when an ID, an attribute name or a string
    ///     value holds a character XML 1.0 cannot represent (a C0 control other than tab, line feed
    ///     and carriage return, U+FFFE or U+FFFF);
    ///   - `typeMismatch` when one attribute name holds values of two types other than integers and
    ///     doubles.
    ///
    /// Traps when an attribute closure gives one key twice for one element.
    @inlinable public func writeGraphML(
        to output: inout some TextOutputStream,
        vertexID: (Vertex) -> String = { _defaultVertexID($0) },
        vertexAttributes: (Vertex) -> [(key: String, value: AttributeValue)] = { _ in [] },
        edgeAttributes: (Edges.Index) -> [(key: String, value: AttributeValue)] = { _ in [] },
        graphAttributes: [(key: String, value: AttributeValue)] = []
    ) throws(WriteError) {
        try _withOutputBuffer(&output) { (out) throws(WriteError) in
            try _writeGraphML(_UndirectedSource(self), to: &out, vertexID: vertexID, vertexAttributes: vertexAttributes,
                              edgeAttributes: edgeAttributes, graphAttributes: graphAttributes)
        }
    }

    /// Writes the graph as node-link JSON.
    ///
    /// The output is one line, with `", "` and `": "` between items, every character outside ASCII
    /// escaped, and no final line feed. The text reaches `output` once the whole document is made.
    ///
    /// - Parameters:
    ///   - output: The stream the text is appended to.
    ///   - vertexID: Each node's `id`, a string or an integer, called once per vertex. Defaults to
    ///     an `Int` vertex as a number and any other as its description.
    ///   - vertexAttributes: Each vertex's attribute pairs, in the order to write; each key once.
    ///   - edgeAttributes: Each edge's attribute pairs, by position; each key once.
    ///   - graphAttributes: The graph's attribute pairs; each key once.
    /// - Complexity: O(n + m + output size), plus the closures' cost.
    /// - Throws: A `WriteError`, and then nothing is written:
    ///   - `duplicateID` when two vertices have the same ID, compared by Unicode scalars;
    ///   - `invalidValue` when a value is a NaN or infinite double;
    ///   - `reservedKey` when a vertex has an attribute named `id`, or an edge one named `source`,
    ///     `target` or `key`.
    ///
    /// Traps when `vertexID` returns a double or a boolean, or when an attribute closure gives one
    /// key twice for one element.
    @inlinable public func writeNodeLinkJSON(
        to output: inout some TextOutputStream,
        vertexID: (Vertex) -> AttributeValue = { ($0 as? Int).map(AttributeValue.integer) ?? .string(_defaultVertexID($0)) },
        vertexAttributes: (Vertex) -> [(key: String, value: AttributeValue)] = { _ in [] },
        edgeAttributes: (Edges.Index) -> [(key: String, value: AttributeValue)] = { _ in [] },
        graphAttributes: [(key: String, value: AttributeValue)] = []
    ) throws(WriteError) {
        try _withHeldOutputBuffer(&output) { (out) throws(WriteError) in
            try _writeNodeLinkJSON(_UndirectedSource(self), to: &out, vertexID: vertexID, vertexAttributes: vertexAttributes,
                                   edgeAttributes: edgeAttributes, graphAttributes: graphAttributes)
        }
    }

    /// Writes the graph as a Matrix Market `pattern` coordinate file, with 1-based indices in
    /// `vertices` order.
    ///
    /// - Parameter output: The stream the text is appended to.
    /// - Complexity: O(n + m + output size).
    @inlinable public func writeMatrixMarket(to output: inout some TextOutputStream) {
        _withOutputBuffer(&output) { out in
            _writeMatrixMarket(_UndirectedSource(self), to: &out, field: "pattern", hasValue: false, value: { _, _ in })
        }
    }

    /// Writes the graph as a Matrix Market `integer` coordinate file, each edge's `weight` its value.
    ///
    /// - Parameters:
    ///   - output: The stream the text is appended to.
    ///   - weight: Each edge's value, by position.
    /// - Complexity: O(n + m + output size), plus the closure's cost.
    @inlinable public func writeMatrixMarket(to output: inout some TextOutputStream, weight: (Edges.Index) -> Int) {
        _withOutputBuffer(&output) { out in
            _writeMatrixMarket(_UndirectedSource(self), to: &out, field: "integer", hasValue: true, value: { position, out in out.appendDecimal(weight(position)) })
        }
    }

    /// Writes the graph as a Matrix Market `real` coordinate file, each edge's `weight` its value.
    ///
    /// A value is written as its shortest round-trip digits in the form `d[.ddd]E<e>`; a NaN or
    /// infinity as `NaN`, `Infinity` or `-Infinity`.
    ///
    /// - Parameters:
    ///   - output: The stream the text is appended to.
    ///   - weight: Each edge's value, by position.
    /// - Complexity: O(n + m + output size), plus the closure's cost.
    @inlinable public func writeMatrixMarket(to output: inout some TextOutputStream, weight: (Edges.Index) -> Double) {
        _withOutputBuffer(&output) { out in
            _writeMatrixMarket(_UndirectedSource(self), to: &out, field: "real", hasValue: true, value: { position, out in _appendMatrixMarketDouble(weight(position), to: &out) })
        }
    }

    /// Writes the graph as an edge list: `u v` and the value of each of `columns`, one line per edge
    /// in position order, the fields separated by a space or by `delimiter`.
    ///
    /// Isolated vertices are not written, and `vertexID` is called only for the vertices an edge
    /// names. The text reaches `output` once the whole list is made.
    ///
    /// - Parameters:
    ///   - output: The stream the text is appended to.
    ///   - vertexID: Each vertex's ID, called once per vertex an edge names. Defaults to its
    ///     description.
    ///   - columns: The attribute names whose values follow the endpoints, in order.
    ///   - delimiter: The field separator; `nil`, the default, is a space. It must be ASCII and not
    ///     a letter, a digit, `.`, `+`, `-`, `#`, LF or CR.
    ///   - edgeAttributes: Each edge's attribute pairs, by position; each key once, and a value for
    ///     every name in `columns`.
    /// - Complexity: O(n + m + output size), plus the closures' cost.
    /// - Throws: A `WriteError`, and then nothing is written:
    ///   - `duplicateID` when two vertices have the same ID, compared by Unicode scalars;
    ///   - `invalidID` when an ID is empty or holds whitespace or `#` (with a delimiter: holds the
    ///     delimiter, `#`, LF or CR);
    ///   - `invalidValue` when a column's value is a boolean, or a string that could not be one
    ///     field in the same way.
    ///
    /// Traps when an edge's attributes have no value for one of `columns`, or give one key twice,
    /// or when `delimiter` is not allowed.
    @inlinable public func writeEdgeList(
        to output: inout some TextOutputStream,
        vertexID: (Vertex) -> String = { _defaultVertexID($0) },
        columns: [String] = [],
        delimiter: Unicode.Scalar? = nil,
        edgeAttributes: (Edges.Index) -> [(key: String, value: AttributeValue)] = { _ in [] }
    ) throws(WriteError) {
        try _withHeldOutputBuffer(&output) { (out) throws(WriteError) in
            try _writeEdgeList(_UndirectedSource(self), to: &out, vertexID: vertexID, columns: columns,
                               delimiter: _listDelimiter(delimiter), edgeAttributes: edgeAttributes)
        }
    }

    /// Writes the graph as an adjacency list: one line per vertex in `vertices` order, the vertex
    /// and then the far end of each of its edges.
    ///
    /// - Parameters:
    ///   - output: The stream the text is appended to.
    ///   - vertexID: Each vertex's ID, called once per vertex. Defaults to its description.
    /// - Complexity: O(n + m + output size), plus the closures' cost.
    /// - Throws: A `WriteError`, checked before anything is written:
    ///   - `duplicateID` when two vertices have the same ID, compared by Unicode scalars;
    ///   - `invalidID` when an ID is empty or holds whitespace or `#`.
    @inlinable public func writeAdjacencyList(
        to output: inout some TextOutputStream,
        vertexID: (Vertex) -> String = { _defaultVertexID($0) }
    ) throws(WriteError) {
        try _withOutputBuffer(&output) { (out) throws(WriteError) in
            try _writeAdjacencyList(_UndirectedSource(self), to: &out, vertexID: vertexID)
        }
    }

    /// Writes the graph as a Mermaid flowchart (`flowchart TD`): every vertex, with its label when
    /// it has one, then every edge.
    ///
    /// A label may hold any text. A caller whose vertices have arbitrary names passes IDs such as
    /// indices through `vertexID` and the names through `vertexLabel`.
    ///
    /// - Parameters:
    ///   - output: The stream the text is appended to.
    ///   - vertexID: Each vertex's ID, called once per vertex. Defaults to its description.
    ///   - vertexLabel: Each vertex's label, or `nil` for none.
    ///   - edgeLabel: Each edge's label, by position, or `nil` for none.
    /// - Complexity: O(n + m + output size), plus the closures' cost.
    /// - Throws: A `WriteError`, checked before anything is written:
    ///   - `duplicateID` when two vertices have the same ID;
    ///   - `invalidID` when an ID is not `[A-Za-z0-9_]+` or is a Mermaid keyword (`end`, `graph`,
    ///     `flowchart`, `subgraph`, `style`, `classDef`, `class`, `click`, `linkStyle`,
    ///     `direction`).
    @inlinable public func writeMermaid(
        to output: inout some TextOutputStream,
        vertexID: (Vertex) -> String = { _defaultVertexID($0) },
        vertexLabel: (Vertex) -> String? = { _ in nil },
        edgeLabel: (Edges.Index) -> String? = { _ in nil }
    ) throws(WriteError) {
        try _withOutputBuffer(&output) { (out) throws(WriteError) in
            try _writeMermaid(_UndirectedSource(self), to: &out, vertexID: vertexID, vertexLabel: vertexLabel, edgeLabel: edgeLabel)
        }
    }
}
