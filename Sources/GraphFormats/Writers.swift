import GraphProtocols

// The writers: a method per format on every `DirectedGraph` and `Graph`. Each streams canonical,
// deterministic text into a `TextOutputStream`, in pieces of at most 64 KiB, taking vertex IDs and
// attributes from closures (the attribute pairs in the order to write, each key once per element).
// Every writer but node-link JSON ends its output with a line feed; lines end in LF only.

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
    /// Writes canonical DOT: `digraph {`, the graph attributes, every vertex in `vertices` order,
    /// every edge in position order, one tab of indent. IDs are bare when DOT allows, else quoted.
    @inlinable public func writeDOT(
        to output: inout some TextOutputStream,
        vertexID: (Vertex) -> String = { _defaultVertexID($0) },
        vertexAttributes: (Vertex) -> [(key: String, value: AttributeValue)] = { _ in [] },
        edgeAttributes: (Edges.Index) -> [(key: String, value: AttributeValue)] = { _ in [] },
        graphAttributes: [(key: String, value: AttributeValue)] = []
    ) {
        _withOutputBuffer(&output) { out in
            _writeDOT(_DirectedSource(self), to: &out, vertexID: vertexID, vertexAttributes: vertexAttributes,
                      edgeAttributes: edgeAttributes, graphAttributes: graphAttributes)
        }
    }

    /// Writes GraphML: a typed `<key>` per attribute name and domain, then every vertex and edge
    /// with its `<data>`. The attribute closures are called twice per element (to type the keys,
    /// then to write), and must return the same pairs both times; `vertexID` once per vertex.
    @inlinable public func writeGraphML(
        to output: inout some TextOutputStream,
        vertexID: (Vertex) -> String = { _defaultVertexID($0) },
        vertexAttributes: (Vertex) -> [(key: String, value: AttributeValue)] = { _ in [] },
        edgeAttributes: (Edges.Index) -> [(key: String, value: AttributeValue)] = { _ in [] },
        graphAttributes: [(key: String, value: AttributeValue)] = []
    ) {
        _withOutputBuffer(&output) { out in
            _writeGraphML(_DirectedSource(self), to: &out, vertexID: vertexID, vertexAttributes: vertexAttributes,
                          edgeAttributes: edgeAttributes, graphAttributes: graphAttributes)
        }
    }

    /// Writes node-link JSON byte-equal to Python's `json.dumps(nx.node_link_data(G))` for the same
    /// graph: one line, no final line feed. `vertexID` gives each node's `id` (by default an
    /// `Int` vertex as a number, any other as its description).
    @inlinable public func writeNodeLinkJSON(
        to output: inout some TextOutputStream,
        vertexID: (Vertex) -> AttributeValue = { ($0 as? Int).map(AttributeValue.integer) ?? .string(_defaultVertexID($0)) },
        vertexAttributes: (Vertex) -> [(key: String, value: AttributeValue)] = { _ in [] },
        edgeAttributes: (Edges.Index) -> [(key: String, value: AttributeValue)] = { _ in [] },
        graphAttributes: [(key: String, value: AttributeValue)] = []
    ) {
        _withOutputBuffer(&output) { out in
            _writeNodeLinkJSON(_DirectedSource(self), to: &out, vertexID: vertexID, vertexAttributes: vertexAttributes,
                               edgeAttributes: edgeAttributes, graphAttributes: graphAttributes)
        }
    }

    /// Writes a Matrix Market `pattern` coordinate file, byte-equal to SciPy's `mmwrite`, with
    /// 1-based indices in `vertices` order.
    @inlinable public func writeMatrixMarket(to output: inout some TextOutputStream) {
        _withOutputBuffer(&output) { out in
            _writeMatrixMarket(_DirectedSource(self), to: &out, field: "pattern", hasValue: false, value: { _, _ in })
        }
    }

    /// Writes a Matrix Market `integer` coordinate file, each edge's `weight` its value.
    @inlinable public func writeMatrixMarket(to output: inout some TextOutputStream, weight: (Edges.Index) -> Int) {
        _withOutputBuffer(&output) { out in
            _writeMatrixMarket(_DirectedSource(self), to: &out, field: "integer", hasValue: true, value: { position, out in out.appendDecimal(weight(position)) })
        }
    }

    /// Writes a Matrix Market `real` coordinate file, each edge's `weight` its value, in SciPy's
    /// number form.
    @inlinable public func writeMatrixMarket(to output: inout some TextOutputStream, weight: (Edges.Index) -> Double) {
        _withOutputBuffer(&output) { out in
            _writeMatrixMarket(_DirectedSource(self), to: &out, field: "real", hasValue: true, value: { position, out in _appendMatrixMarketDouble(weight(position), to: &out) })
        }
    }

    /// Writes an edge list: `u v` and the value of each of `columns` per edge, in position order
    /// (isolated vertices are not written).
    @inlinable public func writeEdgeList(
        to output: inout some TextOutputStream,
        vertexID: (Vertex) -> String = { _defaultVertexID($0) },
        columns: [String] = [],
        edgeAttributes: (Edges.Index) -> [(key: String, value: AttributeValue)] = { _ in [] }
    ) {
        _withOutputBuffer(&output) { out in
            _writeEdgeList(_DirectedSource(self), to: &out, vertexID: vertexID, columns: columns, edgeAttributes: edgeAttributes)
        }
    }

    /// Writes an adjacency list: one line per vertex in `vertices` order, the vertex and then the far
    /// end of each of its edges.
    @inlinable public func writeAdjacencyList(
        to output: inout some TextOutputStream,
        vertexID: (Vertex) -> String = { _defaultVertexID($0) }
    ) {
        _withOutputBuffer(&output) { out in
            _writeAdjacencyList(_DirectedSource(self), to: &out, vertexID: vertexID)
        }
    }

    /// Writes a Mermaid flowchart (`flowchart TD`): every vertex, with its label when it has one,
    /// then every edge. IDs must be `[A-Za-z0-9_]+` and not a Mermaid keyword.
    @inlinable public func writeMermaid(
        to output: inout some TextOutputStream,
        vertexID: (Vertex) -> String = { _defaultVertexID($0) },
        vertexLabel: (Vertex) -> String? = { _ in nil },
        edgeLabel: (Edges.Index) -> String? = { _ in nil }
    ) {
        _withOutputBuffer(&output) { out in
            _writeMermaid(_DirectedSource(self), to: &out, vertexID: vertexID, vertexLabel: vertexLabel, edgeLabel: edgeLabel)
        }
    }
}

// MARK: - Graph

extension Graph {
    /// Writes canonical DOT: `graph {`, the graph attributes, every vertex in `vertices` order,
    /// every edge in position order, one tab of indent. IDs are bare when DOT allows, else quoted.
    @inlinable public func writeDOT(
        to output: inout some TextOutputStream,
        vertexID: (Vertex) -> String = { _defaultVertexID($0) },
        vertexAttributes: (Vertex) -> [(key: String, value: AttributeValue)] = { _ in [] },
        edgeAttributes: (Edges.Index) -> [(key: String, value: AttributeValue)] = { _ in [] },
        graphAttributes: [(key: String, value: AttributeValue)] = []
    ) {
        _withOutputBuffer(&output) { out in
            _writeDOT(_UndirectedSource(self), to: &out, vertexID: vertexID, vertexAttributes: vertexAttributes,
                      edgeAttributes: edgeAttributes, graphAttributes: graphAttributes)
        }
    }

    /// Writes GraphML: a typed `<key>` per attribute name and domain, then every vertex and edge
    /// with its `<data>`. The attribute closures are called twice per element (to type the keys,
    /// then to write), and must return the same pairs both times; `vertexID` once per vertex.
    @inlinable public func writeGraphML(
        to output: inout some TextOutputStream,
        vertexID: (Vertex) -> String = { _defaultVertexID($0) },
        vertexAttributes: (Vertex) -> [(key: String, value: AttributeValue)] = { _ in [] },
        edgeAttributes: (Edges.Index) -> [(key: String, value: AttributeValue)] = { _ in [] },
        graphAttributes: [(key: String, value: AttributeValue)] = []
    ) {
        _withOutputBuffer(&output) { out in
            _writeGraphML(_UndirectedSource(self), to: &out, vertexID: vertexID, vertexAttributes: vertexAttributes,
                          edgeAttributes: edgeAttributes, graphAttributes: graphAttributes)
        }
    }

    /// Writes node-link JSON byte-equal to Python's `json.dumps(nx.node_link_data(G))` for the same
    /// graph: one line, no final line feed. `vertexID` gives each node's `id` (by default an
    /// `Int` vertex as a number, any other as its description).
    @inlinable public func writeNodeLinkJSON(
        to output: inout some TextOutputStream,
        vertexID: (Vertex) -> AttributeValue = { ($0 as? Int).map(AttributeValue.integer) ?? .string(_defaultVertexID($0)) },
        vertexAttributes: (Vertex) -> [(key: String, value: AttributeValue)] = { _ in [] },
        edgeAttributes: (Edges.Index) -> [(key: String, value: AttributeValue)] = { _ in [] },
        graphAttributes: [(key: String, value: AttributeValue)] = []
    ) {
        _withOutputBuffer(&output) { out in
            _writeNodeLinkJSON(_UndirectedSource(self), to: &out, vertexID: vertexID, vertexAttributes: vertexAttributes,
                               edgeAttributes: edgeAttributes, graphAttributes: graphAttributes)
        }
    }

    /// Writes a Matrix Market `pattern` coordinate file, byte-equal to SciPy's `mmwrite`, with
    /// 1-based indices in `vertices` order.
    @inlinable public func writeMatrixMarket(to output: inout some TextOutputStream) {
        _withOutputBuffer(&output) { out in
            _writeMatrixMarket(_UndirectedSource(self), to: &out, field: "pattern", hasValue: false, value: { _, _ in })
        }
    }

    /// Writes a Matrix Market `integer` coordinate file, each edge's `weight` its value.
    @inlinable public func writeMatrixMarket(to output: inout some TextOutputStream, weight: (Edges.Index) -> Int) {
        _withOutputBuffer(&output) { out in
            _writeMatrixMarket(_UndirectedSource(self), to: &out, field: "integer", hasValue: true, value: { position, out in out.appendDecimal(weight(position)) })
        }
    }

    /// Writes a Matrix Market `real` coordinate file, each edge's `weight` its value, in SciPy's
    /// number form.
    @inlinable public func writeMatrixMarket(to output: inout some TextOutputStream, weight: (Edges.Index) -> Double) {
        _withOutputBuffer(&output) { out in
            _writeMatrixMarket(_UndirectedSource(self), to: &out, field: "real", hasValue: true, value: { position, out in _appendMatrixMarketDouble(weight(position), to: &out) })
        }
    }

    /// Writes an edge list: `u v` and the value of each of `columns` per edge, in position order
    /// (isolated vertices are not written).
    @inlinable public func writeEdgeList(
        to output: inout some TextOutputStream,
        vertexID: (Vertex) -> String = { _defaultVertexID($0) },
        columns: [String] = [],
        edgeAttributes: (Edges.Index) -> [(key: String, value: AttributeValue)] = { _ in [] }
    ) {
        _withOutputBuffer(&output) { out in
            _writeEdgeList(_UndirectedSource(self), to: &out, vertexID: vertexID, columns: columns, edgeAttributes: edgeAttributes)
        }
    }

    /// Writes an adjacency list: one line per vertex in `vertices` order, the vertex and then the far
    /// end of each of its edges.
    @inlinable public func writeAdjacencyList(
        to output: inout some TextOutputStream,
        vertexID: (Vertex) -> String = { _defaultVertexID($0) }
    ) {
        _withOutputBuffer(&output) { out in
            _writeAdjacencyList(_UndirectedSource(self), to: &out, vertexID: vertexID)
        }
    }

    /// Writes a Mermaid flowchart (`flowchart TD`): every vertex, with its label when it has one,
    /// then every edge. IDs must be `[A-Za-z0-9_]+` and not a Mermaid keyword.
    @inlinable public func writeMermaid(
        to output: inout some TextOutputStream,
        vertexID: (Vertex) -> String = { _defaultVertexID($0) },
        vertexLabel: (Vertex) -> String? = { _ in nil },
        edgeLabel: (Edges.Index) -> String? = { _ in nil }
    ) {
        _withOutputBuffer(&output) { out in
            _writeMermaid(_UndirectedSource(self), to: &out, vertexID: vertexID, vertexLabel: vertexLabel, edgeLabel: edgeLabel)
        }
    }
}
