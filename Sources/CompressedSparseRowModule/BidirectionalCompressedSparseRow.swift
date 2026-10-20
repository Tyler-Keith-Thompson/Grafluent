import GraphProtocols

/// A `CompressedSparseRow` with its in-edges too: predecessors and in-edges read as fast as
/// successors and out-edges, at the same edge positions.
///
/// It wraps the row form and adds the column form, the transpose's offsets and sources, with each
/// in-entry's edge position, so `inEdges(of:)` are positions of `edges` and attached edge maps
/// read through them. Everything else is the wrapped graph's: vertices `0..<vertexCount`,
/// canonical rows, edge positions `0..<edgeCount` in row-major order, no parallel edges. It is
/// immutable, like its base; building the column form is one counting sort, O(n + m), and the
/// graph takes about twice the memory of a `CompressedSparseRow`.
///
/// Use it where an algorithm walks arcs backwards: dominators, ancestors, pull-direction
/// PageRank, a Kosaraju pass. `base` is the row form, `transposed()` the column form as its own
/// graph.
@frozen
public struct BidirectionalCompressedSparseRow {
    @usableFromInline
    internal var _base: CompressedSparseRow

    /// The column form: `_inOffsets[v] ..< _inOffsets[v + 1]` are the in-entries of `v`, each a
    /// source in `_inSources` and the edge's position in `_inPositions`, in ascending source order.
    @usableFromInline
    internal let _inOffsets: [Int]

    @usableFromInline
    internal let _inSources: [Int]

    @usableFromInline
    internal let _inPositions: [Int]

    /// The graph `rows` describes, with its column form built. O(n + m). The attached maps of
    /// `rows` are kept.
    @inlinable
    public init(_ rows: CompressedSparseRow) {
        var positions: [Int] = []
        let column = rows._transposed(forwardEdgeIndices: &positions, recording: true)
        _base = rows
        _inOffsets = column._offsets
        _inSources = column._targets
        _inPositions = positions
    }

    /// The graph with no vertices.
    @inlinable
    public init() {
        self.init(CompressedSparseRow())
    }

    /// `vertexCount` vertices and no edges.
    @inlinable
    public init(vertexCount: Int) {
        self.init(CompressedSparseRow(vertexCount: vertexCount))
    }

    /// The graph with these edges, in any order; repeats collapse to one edge.
    ///
    /// - Precondition: every endpoint is in `0..<vertexCount`.
    @inlinable
    public init(vertexCount: Int, edges: some Sequence<DirectedEdge<Int>>) {
        self.init(CompressedSparseRow(vertexCount: vertexCount, edges: edges))
    }

    /// The graph with these edges, in any order; repeats collapse to one edge.
    ///
    /// - Precondition: every endpoint is in `0..<vertexCount`.
    @inlinable
    public init(vertexCount: Int, edges: some Collection<DirectedEdge<Int>>) {
        self.init(CompressedSparseRow(vertexCount: vertexCount, edges: edges))
    }

    /// Any directed graph with vertex indices, copied into row and column form: vertex `v` of
    /// this graph is the vertex at index `v` there. O(n + m) plus sorting the rows.
    @inlinable
    public init(_ graph: some DirectedGraph<Int>) {
        self.init(CompressedSparseRow(graph))
    }

    /// The row form, which this graph wraps.
    @inlinable
    public var base: CompressedSparseRow {
        _read { yield _base }
    }

    /// The column form as its own graph: every edge reversed, rows canonical. O(1).
    @inlinable
    public func transposed() -> CompressedSparseRow {
        CompressedSparseRow(_offsets: _inOffsets, _targets: _inSources)
    }
}

extension BidirectionalCompressedSparseRow: GraphDelegator, DirectedGraph, BidirectionalDirectedGraph {
    public typealias Vertex = Int
    public typealias Vertices = CompressedSparseRow.Vertices
    public typealias Edges = CompressedSparseRow.Edges
    public typealias Successors = CompressedSparseRow.Successors
    public typealias OutEdges = CompressedSparseRow.OutEdges
    public typealias SuccessorIndices = CompressedSparseRow.SuccessorIndices
    public typealias Predecessors = ArraySlice<Int>
    public typealias InEdges = ArraySlice<Int>
    public typealias PredecessorIndices = ArraySlice<Int>

    /// The sources of the edges entering `vertex`, ascending. O(1).
    ///
    /// - Precondition: `vertex` is in `0..<vertexCount`.
    @inlinable
    public func predecessors(of vertex: Int) -> ArraySlice<Int> {
        precondition(UInt(bitPattern: vertex) < UInt(bitPattern: vertexCount), "Vertex \(vertex) is not in 0..<\(vertexCount)")
        return _inSources[_inOffsets[vertex] ..< _inOffsets[vertex &+ 1]]
    }

    /// The positions of the edges entering `vertex`, in the order of `predecessors(of:)`. O(1).
    ///
    /// - Precondition: `vertex` is in `0..<vertexCount`.
    @inlinable
    public func inEdges(of vertex: Int) -> ArraySlice<Int> {
        precondition(UInt(bitPattern: vertex) < UInt(bitPattern: vertexCount), "Vertex \(vertex) is not in 0..<\(vertexCount)")
        return _inPositions[_inOffsets[vertex] ..< _inOffsets[vertex &+ 1]]
    }

    /// The number of edges entering `vertex`. O(1).
    ///
    /// - Precondition: `vertex` is in `0..<vertexCount`.
    @inlinable
    public func inDegree(of vertex: Int) -> Int {
        precondition(UInt(bitPattern: vertex) < UInt(bitPattern: vertexCount), "Vertex \(vertex) is not in 0..<\(vertexCount)")
        return _inOffsets[vertex &+ 1] &- _inOffsets[vertex]
    }

    /// `outDegree(of:) + inDegree(of:)`; a self-loop counts twice. O(1).
    @inlinable
    public func degree(of vertex: Int) -> Int { outDegree(of: vertex) &+ inDegree(of: vertex) }

    @inlinable
    public func inDegree(ofIndex index: Int) -> Int { inDegree(of: index) }

    @inlinable
    public func predecessorIndices(ofIndex index: Int) -> ArraySlice<Int> { predecessors(of: index) }

    @inlinable
    public func inEdges(ofIndex index: Int) -> ArraySlice<Int> { inEdges(of: index) }

    @inlinable
    public func _forEachPredecessorIndex(ofIndex index: Int, _ body: (Int) -> Void) {
        for v in predecessors(of: index) { body(v) }
    }

    /// `predecessors(of:)`, throwing instead of trapping.
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not in `0..<vertexCount`.
    @inlinable
    public func predecessors(checked vertex: Int) throws(VertexNotFound) -> ArraySlice<Int> {
        guard UInt(bitPattern: vertex) < UInt(bitPattern: vertexCount) else { throw VertexNotFound() }
        return predecessors(of: vertex)
    }

    /// `inEdges(of:)`, throwing instead of trapping.
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not in `0..<vertexCount`.
    @inlinable
    public func inEdges(checked vertex: Int) throws(VertexNotFound) -> ArraySlice<Int> {
        guard UInt(bitPattern: vertex) < UInt(bitPattern: vertexCount) else { throw VertexNotFound() }
        return inEdges(of: vertex)
    }

    /// `inDegree(of:)`, throwing instead of trapping.
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not in `0..<vertexCount`.
    @inlinable
    public func inDegree(checked vertex: Int) throws(VertexNotFound) -> Int {
        guard UInt(bitPattern: vertex) < UInt(bitPattern: vertexCount) else { throw VertexNotFound() }
        return inDegree(of: vertex)
    }
}

extension BidirectionalCompressedSparseRow: PropertyGraph {
    public typealias EdgePosition = Int

    @inlinable
    public mutating func addVertexMap<Value: Sendable>(default value: Value) -> VertexMap<Value> {
        _base.addVertexMap(default: value)
    }

    @inlinable
    public mutating func addEdgeMap<Value: Sendable>(default value: Value) -> EdgeMap<Value> {
        _base.addEdgeMap(default: value)
    }

    @inlinable
    public mutating func removeVertexMap<Value>(_ map: VertexMap<Value>) {
        _base.removeVertexMap(map)
    }

    @inlinable
    public mutating func removeEdgeMap<Value>(_ map: EdgeMap<Value>) {
        _base.removeEdgeMap(map)
    }

    @inlinable
    public subscript<Value>(map: VertexMap<Value>, ofVertexAt position: Int) -> Value {
        get { _base[map, ofVertexAt: position] }
        set { _base[map, ofVertexAt: position] = newValue }
    }

    @inlinable
    public subscript<Value>(map: VertexMap<Value>, of vertex: Int) -> Value {
        get { _base[map, of: vertex] }
        set { _base[map, of: vertex] = newValue }
    }

    @inlinable
    public subscript<Value>(map: EdgeMap<Value>, ofEdgeAt position: Int) -> Value {
        get { _base[map, ofEdgeAt: position] }
        set { _base[map, ofEdgeAt: position] = newValue }
    }
}

extension BidirectionalCompressedSparseRow: _DirectedGraphConstruction {
    @inlinable
    public init(_vertexCount: Int, sortedEdges: some Collection<DirectedEdge<Int>>, _ token: _ConstructionToken) {
        self.init(CompressedSparseRow(_vertexCount: _vertexCount, sortedEdges: sortedEdges, token))
    }
}

extension BidirectionalCompressedSparseRow: Hashable {
    /// Equal when the row forms are equal: the same vertex count and edges.
    @inlinable
    public static func == (lhs: BidirectionalCompressedSparseRow, rhs: BidirectionalCompressedSparseRow) -> Bool {
        lhs._base == rhs._base
    }

    @inlinable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(_base)
    }
}

extension BidirectionalCompressedSparseRow: Sendable {}

extension BidirectionalCompressedSparseRow: Codable {
    /// Encodes as the row form, `{"offsets": [...], "targets": [...]}`.
    public func encode(to encoder: any Encoder) throws {
        try _base.encode(to: encoder)
    }

    /// Decodes the row form, validating it as `CompressedSparseRow` does, and builds the column
    /// form.
    public init(from decoder: any Decoder) throws {
        self.init(try CompressedSparseRow(from: decoder))
    }
}

extension BidirectionalCompressedSparseRow: CustomStringConvertible, CustomDebugStringConvertible {
    /// The vertices and the edges, as `CompressedSparseRow` prints them.
    public var description: String { _base.description }
    public var debugDescription: String { "BidirectionalCompressedSparseRow(\(_base.debugDescription))" }
}
