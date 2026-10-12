import GraphProtocols

// The readers: a throwing initializer per format on every mutable representation, directed
// (`MutableDirectedGraph`) and undirected (`MutableGraph`). The target's type fixes the kind; a
// simple target merges parallel edges as it reads. Attributes are reported through setter
// closures, in document order; positions are the target's edge positions.
//
// `vertex` maps a file's ID to a vertex, once per new ID (`nil`: `ParseError.Kind.invalidVertex`
// at the ID); two IDs mapped to one vertex are that vertex. The overloads without it exist where
// `Vertex == String` (all formats but Matrix Market, whose IDs are indices) and where
// `Vertex == Int` (Matrix Market, node-link JSON, the edge and adjacency lists).

// MARK: - MutableDirectedGraph

extension MutableDirectedGraph {
    /// Reads DOT (Graphviz): `digraph` only; `node`/`edge` defaults, `strict` merging, every value a
    /// string. `vertex` maps each new ID once (`nil`: `invalidVertex` at the ID).
    @inlinable public init(
        dot input: some Sequence<UInt8>,
        vertex: (String) -> Vertex?,
        vertexAttribute: (Vertex, String, AttributeValue) -> Void = { _, _, _ in },
        edgeAttribute: (Edges.Index, String, AttributeValue) -> Void = { _, _, _ in },
        graphAttribute: (String, AttributeValue) -> Void = { _, _ in }
    ) throws(ParseError) {
        var target = _DirectedTarget<Self>()
        try _readInput(input) { (text) throws(ParseError) in
            try _readDOT(text, into: &target, map: { vertex(_string($0)) }, vertexAttribute: vertexAttribute,
                         edgeAttribute: edgeAttribute, graphAttribute: graphAttribute)
        }
        self = target.graph
    }

    /// Reads GraphML: one `<graph>` whose `edgedefault` is the target's kind, typed `<key>`s with
    /// defaults, node, edge and graph `<data>`. No DTD (any `<!DOCTYPE` is `doctypeNotAllowed`), no
    /// entities but the predefined five and character references.
    @inlinable public init(
        graphML input: some Sequence<UInt8>,
        vertex: (String) -> Vertex?,
        vertexAttribute: (Vertex, String, AttributeValue) -> Void = { _, _, _ in },
        edgeAttribute: (Edges.Index, String, AttributeValue) -> Void = { _, _, _ in },
        graphAttribute: (String, AttributeValue) -> Void = { _, _ in }
    ) throws(ParseError) {
        self = try Self._readBulk(input, xmlCharacters: true, names: [], vertexAttribute: vertexAttribute,
                                  edgeAttribute: edgeAttribute) { (text, target, buffer) throws(ParseError) in
            try _readGraphML(text, into: &target, buffer: &buffer, map: { vertex(_string($0)) }, graphAttribute: graphAttribute)
        }
    }

    /// Reads NetworkX's node-link JSON: `directed`, `multigraph`, `graph`, `nodes`, and `edges` (or
    /// `links`). `vertex` maps each node `id` (a string or an integer) once.
    @inlinable public init(
        nodeLinkJSON input: some Sequence<UInt8>,
        vertex: (AttributeValue) -> Vertex?,
        vertexAttribute: (Vertex, String, AttributeValue) -> Void = { _, _, _ in },
        edgeAttribute: (Edges.Index, String, AttributeValue) -> Void = { _, _, _ in },
        graphAttribute: (String, AttributeValue) -> Void = { _, _ in }
    ) throws(ParseError) {
        self = try _readInput(input) { (text) throws(ParseError) -> Self in
            try _readNodeLinkJSON(text, as: _BulkTarget<Vertex, _Directed>.self, map: vertex, vertexAttribute: vertexAttribute,
                                  edgeAttribute: edgeAttribute, graphAttribute: graphAttribute) { Self._built($0, reportingPositions: $1) }
        }
    }

    /// Reads a Matrix Market coordinate file: vertices `0..<n` (each index mapped once by `vertex`,
    /// at the size line), an edge per entry, its value under the key `"weight"`. A size line
    /// declaring more than `maximumVertexCount` vertices is `limitExceeded` at its first field,
    /// before anything is allocated: the vertices are inserted eagerly, so the count bounds the
    /// memory a small file can ask for.
    @inlinable public init(
        matrixMarket input: some Sequence<UInt8>,
        maximumVertexCount: Int = 1 << 24,
        vertex: (Int) -> Vertex?,
        edgeAttribute: (Edges.Index, String, AttributeValue) -> Void = { _, _, _ in }
    ) throws(ParseError) {
        self = try Self._readBulk(input, names: ["weight"], edgeAttribute: edgeAttribute) { (text, target, buffer) throws(ParseError) in
            try _readMatrixMarket(text, into: &target, maximumVertexCount: maximumVertexCount, identity: false, map: vertex,
                                  weight: { buffer.record($0, 0, $1) })
        }
    }

    /// Reads an edge list: `u v` and one field per column on each line, `#` comments; each column's
    /// value typed by its text.
    @inlinable public init(
        edgeList input: some Sequence<UInt8>,
        columns: [String] = [],
        vertex: (String) -> Vertex?,
        edgeAttribute: (Edges.Index, String, AttributeValue) -> Void = { _, _, _ in }
    ) throws(ParseError) {
        self = try Self._readBulk(input, names: columns, edgeAttribute: edgeAttribute) { (text, target, buffer) throws(ParseError) in
            try _readEdgeList(text, columnCount: columns.count, into: &target, map: { vertex(_string($0)) },
                              value: { buffer.record($0, $1, $2) })
        }
    }

    /// Reads an adjacency list: a vertex, then its neighbours, on each line; `#` comments.
    @inlinable public init(
        adjacencyList input: some Sequence<UInt8>,
        vertex: (String) -> Vertex?
    ) throws(ParseError) {
        self = try Self._readBulk(input, names: [], edgeAttribute: { _, _, _ in }) { (text, target, _) throws(ParseError) in
            try _readAdjacencyList(text, into: &target, map: { vertex(_string($0)) })
        }
    }

    /// Reads a Mermaid flowchart: vertices with their labels, links with theirs; shapes and styling
    /// are dropped.
    @inlinable public init(
        mermaid input: some Sequence<UInt8>,
        vertex: (String) -> Vertex?,
        vertexLabel: (Vertex, String) -> Void = { _, _ in },
        edgeLabel: (Edges.Index, String) -> Void = { _, _ in }
    ) throws(ParseError) {
        self = try Self._readBulk(input, names: ["label"], vertexAttribute: { vertex, _, label in
            if case .string(let label) = label { vertexLabel(vertex, label) }
        }, edgeAttribute: { position, _, label in
            if case .string(let label) = label { edgeLabel(position, label) }
        }) { (text, target, buffer) throws(ParseError) in
            try _readMermaid(text, into: &target, buffer: &buffer, map: { vertex(_string($0)) })
        }
    }
}

extension MutableDirectedGraph where Vertex == String {
    /// Reads DOT, each ID its own vertex.
    @inlinable public init(
        dot input: some Sequence<UInt8>,
        vertexAttribute: (Vertex, String, AttributeValue) -> Void = { _, _, _ in },
        edgeAttribute: (Edges.Index, String, AttributeValue) -> Void = { _, _, _ in },
        graphAttribute: (String, AttributeValue) -> Void = { _, _ in }
    ) throws(ParseError) {
        var target = _DirectedTarget<Self>()
        try _readInput(input) { (text) throws(ParseError) in
            try _readDOT(text, into: &target, map: _string, vertexAttribute: vertexAttribute,
                         edgeAttribute: edgeAttribute, graphAttribute: graphAttribute)
        }
        self = target.graph
    }

    /// Reads GraphML, each node `id` its own vertex.
    @inlinable public init(
        graphML input: some Sequence<UInt8>,
        vertexAttribute: (Vertex, String, AttributeValue) -> Void = { _, _, _ in },
        edgeAttribute: (Edges.Index, String, AttributeValue) -> Void = { _, _, _ in },
        graphAttribute: (String, AttributeValue) -> Void = { _, _ in }
    ) throws(ParseError) {
        self = try Self._readBulk(input, xmlCharacters: true, names: [], vertexAttribute: vertexAttribute,
                                  edgeAttribute: edgeAttribute) { (text, target, buffer) throws(ParseError) in
            try _readGraphML(text, into: &target, buffer: &buffer, map: _string, graphAttribute: graphAttribute)
        }
    }

    /// Reads node-link JSON, a string `id` as itself and an integer `id` as its decimal text.
    @inlinable public init(
        nodeLinkJSON input: some Sequence<UInt8>,
        vertexAttribute: (Vertex, String, AttributeValue) -> Void = { _, _, _ in },
        edgeAttribute: (Edges.Index, String, AttributeValue) -> Void = { _, _, _ in },
        graphAttribute: (String, AttributeValue) -> Void = { _, _ in }
    ) throws(ParseError) {
        self = try _readInput(input) { (text) throws(ParseError) -> Self in
            try _readNodeLinkJSON(text, as: _BulkTarget<Vertex, _Directed>.self, map: _stringNodeID, vertexAttribute: vertexAttribute,
                                  edgeAttribute: edgeAttribute, graphAttribute: graphAttribute) { Self._built($0, reportingPositions: $1) }
        }
    }

    /// Reads an edge list, each field its own vertex.
    @inlinable public init(
        edgeList input: some Sequence<UInt8>,
        columns: [String] = [],
        edgeAttribute: (Edges.Index, String, AttributeValue) -> Void = { _, _, _ in }
    ) throws(ParseError) {
        self = try Self._readBulk(input, names: columns, edgeAttribute: edgeAttribute) { (text, target, buffer) throws(ParseError) in
            try _readEdgeList(text, columnCount: columns.count, into: &target, map: _string,
                              value: { buffer.record($0, $1, $2) })
        }
    }

    /// Reads an adjacency list, each field its own vertex.
    @inlinable public init(adjacencyList input: some Sequence<UInt8>) throws(ParseError) {
        self = try Self._readBulk(input, names: [], edgeAttribute: { _, _, _ in }) { (text, target, _) throws(ParseError) in
            try _readAdjacencyList(text, into: &target, map: _string)
        }
    }

    /// Reads a Mermaid flowchart, each vertex ID its own vertex.
    @inlinable public init(
        mermaid input: some Sequence<UInt8>,
        vertexLabel: (Vertex, String) -> Void = { _, _ in },
        edgeLabel: (Edges.Index, String) -> Void = { _, _ in }
    ) throws(ParseError) {
        self = try Self._readBulk(input, names: ["label"], vertexAttribute: { vertex, _, label in
            if case .string(let label) = label { vertexLabel(vertex, label) }
        }, edgeAttribute: { position, _, label in
            if case .string(let label) = label { edgeLabel(position, label) }
        }) { (text, target, buffer) throws(ParseError) in
            try _readMermaid(text, into: &target, buffer: &buffer, map: _string)
        }
    }
}

extension MutableDirectedGraph where Vertex == Int {
    /// Reads node-link JSON whose node ids are integers (a string id is `invalidVertex`).
    @inlinable public init(
        nodeLinkJSON input: some Sequence<UInt8>,
        vertexAttribute: (Vertex, String, AttributeValue) -> Void = { _, _, _ in },
        edgeAttribute: (Edges.Index, String, AttributeValue) -> Void = { _, _, _ in },
        graphAttribute: (String, AttributeValue) -> Void = { _, _ in }
    ) throws(ParseError) {
        self = try _readInput(input) { (text) throws(ParseError) -> Self in
            try _readNodeLinkJSON(text, as: _BulkTarget<Vertex, _Directed>.self, map: _integerNodeID, vertexAttribute: vertexAttribute,
                                  edgeAttribute: edgeAttribute, graphAttribute: graphAttribute) { Self._built($0, reportingPositions: $1) }
        }
    }

    /// Reads a Matrix Market file onto the vertices `0..<n`; more than `maximumVertexCount` is
    /// `limitExceeded` at the size line's first field.
    @inlinable public init(
        matrixMarket input: some Sequence<UInt8>,
        maximumVertexCount: Int = 1 << 24,
        edgeAttribute: (Edges.Index, String, AttributeValue) -> Void = { _, _, _ in }
    ) throws(ParseError) {
        self = try Self._readBulk(input, names: ["weight"], edgeAttribute: edgeAttribute) { (text, target, buffer) throws(ParseError) in
            try _readMatrixMarket(text, into: &target, maximumVertexCount: maximumVertexCount, identity: true, map: { $0 },
                                  weight: { buffer.record($0, 0, $1) })
        }
    }

    /// Reads an edge list whose fields are decimal integers (as `Int(_:)` reads them; anything
    /// else is `invalidVertex`).
    @inlinable public init(
        edgeList input: some Sequence<UInt8>,
        columns: [String] = [],
        edgeAttribute: (Edges.Index, String, AttributeValue) -> Void = { _, _, _ in }
    ) throws(ParseError) {
        self = try Self._readBulk(input, names: columns, edgeAttribute: edgeAttribute) { (text, target, buffer) throws(ParseError) in
            try _readIntegerEdgeList(text, columnCount: columns.count, into: &target, value: { buffer.record($0, $1, $2) })
        }
    }

    /// Reads an adjacency list whose fields are decimal integers.
    @inlinable public init(adjacencyList input: some Sequence<UInt8>) throws(ParseError) {
        self = try Self._readBulk(input, names: [], edgeAttribute: { _, _, _ in }) { (text, target, _) throws(ParseError) in
            try _readIntegerAdjacencyList(text, into: &target)
        }
    }
}

// MARK: - MutableGraph

extension MutableGraph {
    /// Reads DOT (Graphviz): `graph` only; `node`/`edge` defaults, `strict` merging, every value a
    /// string. `vertex` maps each new ID once (`nil`: `invalidVertex` at the ID).
    @inlinable public init(
        dot input: some Sequence<UInt8>,
        vertex: (String) -> Vertex?,
        vertexAttribute: (Vertex, String, AttributeValue) -> Void = { _, _, _ in },
        edgeAttribute: (Edges.Index, String, AttributeValue) -> Void = { _, _, _ in },
        graphAttribute: (String, AttributeValue) -> Void = { _, _ in }
    ) throws(ParseError) {
        var target = _UndirectedTarget<Self>()
        try _readInput(input) { (text) throws(ParseError) in
            try _readDOT(text, into: &target, map: { vertex(_string($0)) }, vertexAttribute: vertexAttribute,
                         edgeAttribute: edgeAttribute, graphAttribute: graphAttribute)
        }
        self = target.graph
    }

    /// Reads GraphML: one `<graph>` whose `edgedefault` is the target's kind, typed `<key>`s with
    /// defaults, node, edge and graph `<data>`. No DTD (any `<!DOCTYPE` is `doctypeNotAllowed`), no
    /// entities but the predefined five and character references.
    @inlinable public init(
        graphML input: some Sequence<UInt8>,
        vertex: (String) -> Vertex?,
        vertexAttribute: (Vertex, String, AttributeValue) -> Void = { _, _, _ in },
        edgeAttribute: (Edges.Index, String, AttributeValue) -> Void = { _, _, _ in },
        graphAttribute: (String, AttributeValue) -> Void = { _, _ in }
    ) throws(ParseError) {
        self = try Self._readBulk(input, xmlCharacters: true, names: [], vertexAttribute: vertexAttribute,
                                  edgeAttribute: edgeAttribute) { (text, target, buffer) throws(ParseError) in
            try _readGraphML(text, into: &target, buffer: &buffer, map: { vertex(_string($0)) }, graphAttribute: graphAttribute)
        }
    }

    /// Reads NetworkX's node-link JSON: `directed`, `multigraph`, `graph`, `nodes`, and `edges` (or
    /// `links`). `vertex` maps each node `id` (a string or an integer) once.
    @inlinable public init(
        nodeLinkJSON input: some Sequence<UInt8>,
        vertex: (AttributeValue) -> Vertex?,
        vertexAttribute: (Vertex, String, AttributeValue) -> Void = { _, _, _ in },
        edgeAttribute: (Edges.Index, String, AttributeValue) -> Void = { _, _, _ in },
        graphAttribute: (String, AttributeValue) -> Void = { _, _ in }
    ) throws(ParseError) {
        self = try _readInput(input) { (text) throws(ParseError) -> Self in
            try _readNodeLinkJSON(text, as: _BulkTarget<Vertex, _Undirected>.self, map: vertex, vertexAttribute: vertexAttribute,
                                  edgeAttribute: edgeAttribute, graphAttribute: graphAttribute) { Self._built($0, reportingPositions: $1) }
        }
    }

    /// Reads a Matrix Market coordinate file: vertices `0..<n` (each index mapped once by `vertex`,
    /// at the size line), an edge per entry, its value under the key `"weight"`. A size line
    /// declaring more than `maximumVertexCount` vertices is `limitExceeded` at its first field,
    /// before anything is allocated: the vertices are inserted eagerly, so the count bounds the
    /// memory a small file can ask for.
    @inlinable public init(
        matrixMarket input: some Sequence<UInt8>,
        maximumVertexCount: Int = 1 << 24,
        vertex: (Int) -> Vertex?,
        edgeAttribute: (Edges.Index, String, AttributeValue) -> Void = { _, _, _ in }
    ) throws(ParseError) {
        self = try Self._readBulk(input, names: ["weight"], edgeAttribute: edgeAttribute) { (text, target, buffer) throws(ParseError) in
            try _readMatrixMarket(text, into: &target, maximumVertexCount: maximumVertexCount, identity: false, map: vertex,
                                  weight: { buffer.record($0, 0, $1) })
        }
    }

    /// Reads an edge list: `u v` and one field per column on each line, `#` comments; each column's
    /// value typed by its text.
    @inlinable public init(
        edgeList input: some Sequence<UInt8>,
        columns: [String] = [],
        vertex: (String) -> Vertex?,
        edgeAttribute: (Edges.Index, String, AttributeValue) -> Void = { _, _, _ in }
    ) throws(ParseError) {
        self = try Self._readBulk(input, names: columns, edgeAttribute: edgeAttribute) { (text, target, buffer) throws(ParseError) in
            try _readEdgeList(text, columnCount: columns.count, into: &target, map: { vertex(_string($0)) },
                              value: { buffer.record($0, $1, $2) })
        }
    }

    /// Reads an adjacency list: a vertex, then its neighbours, on each line; `#` comments.
    @inlinable public init(
        adjacencyList input: some Sequence<UInt8>,
        vertex: (String) -> Vertex?
    ) throws(ParseError) {
        self = try Self._readBulk(input, names: [], edgeAttribute: { _, _, _ in }) { (text, target, _) throws(ParseError) in
            try _readAdjacencyList(text, into: &target, map: { vertex(_string($0)) })
        }
    }

    /// Reads a Mermaid flowchart: vertices with their labels, links with theirs; shapes and styling
    /// are dropped.
    @inlinable public init(
        mermaid input: some Sequence<UInt8>,
        vertex: (String) -> Vertex?,
        vertexLabel: (Vertex, String) -> Void = { _, _ in },
        edgeLabel: (Edges.Index, String) -> Void = { _, _ in }
    ) throws(ParseError) {
        self = try Self._readBulk(input, names: ["label"], vertexAttribute: { vertex, _, label in
            if case .string(let label) = label { vertexLabel(vertex, label) }
        }, edgeAttribute: { position, _, label in
            if case .string(let label) = label { edgeLabel(position, label) }
        }) { (text, target, buffer) throws(ParseError) in
            try _readMermaid(text, into: &target, buffer: &buffer, map: { vertex(_string($0)) })
        }
    }
}

extension MutableGraph where Vertex == String {
    /// Reads DOT, each ID its own vertex.
    @inlinable public init(
        dot input: some Sequence<UInt8>,
        vertexAttribute: (Vertex, String, AttributeValue) -> Void = { _, _, _ in },
        edgeAttribute: (Edges.Index, String, AttributeValue) -> Void = { _, _, _ in },
        graphAttribute: (String, AttributeValue) -> Void = { _, _ in }
    ) throws(ParseError) {
        var target = _UndirectedTarget<Self>()
        try _readInput(input) { (text) throws(ParseError) in
            try _readDOT(text, into: &target, map: _string, vertexAttribute: vertexAttribute,
                         edgeAttribute: edgeAttribute, graphAttribute: graphAttribute)
        }
        self = target.graph
    }

    /// Reads GraphML, each node `id` its own vertex.
    @inlinable public init(
        graphML input: some Sequence<UInt8>,
        vertexAttribute: (Vertex, String, AttributeValue) -> Void = { _, _, _ in },
        edgeAttribute: (Edges.Index, String, AttributeValue) -> Void = { _, _, _ in },
        graphAttribute: (String, AttributeValue) -> Void = { _, _ in }
    ) throws(ParseError) {
        self = try Self._readBulk(input, xmlCharacters: true, names: [], vertexAttribute: vertexAttribute,
                                  edgeAttribute: edgeAttribute) { (text, target, buffer) throws(ParseError) in
            try _readGraphML(text, into: &target, buffer: &buffer, map: _string, graphAttribute: graphAttribute)
        }
    }

    /// Reads node-link JSON, a string `id` as itself and an integer `id` as its decimal text.
    @inlinable public init(
        nodeLinkJSON input: some Sequence<UInt8>,
        vertexAttribute: (Vertex, String, AttributeValue) -> Void = { _, _, _ in },
        edgeAttribute: (Edges.Index, String, AttributeValue) -> Void = { _, _, _ in },
        graphAttribute: (String, AttributeValue) -> Void = { _, _ in }
    ) throws(ParseError) {
        self = try _readInput(input) { (text) throws(ParseError) -> Self in
            try _readNodeLinkJSON(text, as: _BulkTarget<Vertex, _Undirected>.self, map: _stringNodeID, vertexAttribute: vertexAttribute,
                                  edgeAttribute: edgeAttribute, graphAttribute: graphAttribute) { Self._built($0, reportingPositions: $1) }
        }
    }

    /// Reads an edge list, each field its own vertex.
    @inlinable public init(
        edgeList input: some Sequence<UInt8>,
        columns: [String] = [],
        edgeAttribute: (Edges.Index, String, AttributeValue) -> Void = { _, _, _ in }
    ) throws(ParseError) {
        self = try Self._readBulk(input, names: columns, edgeAttribute: edgeAttribute) { (text, target, buffer) throws(ParseError) in
            try _readEdgeList(text, columnCount: columns.count, into: &target, map: _string,
                              value: { buffer.record($0, $1, $2) })
        }
    }

    /// Reads an adjacency list, each field its own vertex.
    @inlinable public init(adjacencyList input: some Sequence<UInt8>) throws(ParseError) {
        self = try Self._readBulk(input, names: [], edgeAttribute: { _, _, _ in }) { (text, target, _) throws(ParseError) in
            try _readAdjacencyList(text, into: &target, map: _string)
        }
    }

    /// Reads a Mermaid flowchart, each vertex ID its own vertex.
    @inlinable public init(
        mermaid input: some Sequence<UInt8>,
        vertexLabel: (Vertex, String) -> Void = { _, _ in },
        edgeLabel: (Edges.Index, String) -> Void = { _, _ in }
    ) throws(ParseError) {
        self = try Self._readBulk(input, names: ["label"], vertexAttribute: { vertex, _, label in
            if case .string(let label) = label { vertexLabel(vertex, label) }
        }, edgeAttribute: { position, _, label in
            if case .string(let label) = label { edgeLabel(position, label) }
        }) { (text, target, buffer) throws(ParseError) in
            try _readMermaid(text, into: &target, buffer: &buffer, map: _string)
        }
    }
}

extension MutableGraph where Vertex == Int {
    /// Reads node-link JSON whose node ids are integers (a string id is `invalidVertex`).
    @inlinable public init(
        nodeLinkJSON input: some Sequence<UInt8>,
        vertexAttribute: (Vertex, String, AttributeValue) -> Void = { _, _, _ in },
        edgeAttribute: (Edges.Index, String, AttributeValue) -> Void = { _, _, _ in },
        graphAttribute: (String, AttributeValue) -> Void = { _, _ in }
    ) throws(ParseError) {
        self = try _readInput(input) { (text) throws(ParseError) -> Self in
            try _readNodeLinkJSON(text, as: _BulkTarget<Vertex, _Undirected>.self, map: _integerNodeID, vertexAttribute: vertexAttribute,
                                  edgeAttribute: edgeAttribute, graphAttribute: graphAttribute) { Self._built($0, reportingPositions: $1) }
        }
    }

    /// Reads a Matrix Market file onto the vertices `0..<n`; more than `maximumVertexCount` is
    /// `limitExceeded` at the size line's first field.
    @inlinable public init(
        matrixMarket input: some Sequence<UInt8>,
        maximumVertexCount: Int = 1 << 24,
        edgeAttribute: (Edges.Index, String, AttributeValue) -> Void = { _, _, _ in }
    ) throws(ParseError) {
        self = try Self._readBulk(input, names: ["weight"], edgeAttribute: edgeAttribute) { (text, target, buffer) throws(ParseError) in
            try _readMatrixMarket(text, into: &target, maximumVertexCount: maximumVertexCount, identity: true, map: { $0 },
                                  weight: { buffer.record($0, 0, $1) })
        }
    }

    /// Reads an edge list whose fields are decimal integers (as `Int(_:)` reads them; anything
    /// else is `invalidVertex`).
    @inlinable public init(
        edgeList input: some Sequence<UInt8>,
        columns: [String] = [],
        edgeAttribute: (Edges.Index, String, AttributeValue) -> Void = { _, _, _ in }
    ) throws(ParseError) {
        self = try Self._readBulk(input, names: columns, edgeAttribute: edgeAttribute) { (text, target, buffer) throws(ParseError) in
            try _readIntegerEdgeList(text, columnCount: columns.count, into: &target, value: { buffer.record($0, $1, $2) })
        }
    }

    /// Reads an adjacency list whose fields are decimal integers.
    @inlinable public init(adjacencyList input: some Sequence<UInt8>) throws(ParseError) {
        self = try Self._readBulk(input, names: [], edgeAttribute: { _, _, _ in }) { (text, target, _) throws(ParseError) in
            try _readIntegerAdjacencyList(text, into: &target)
        }
    }
}
