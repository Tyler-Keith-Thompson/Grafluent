import GraphProtocols
import Walks

/// A graph's vertices numbered `0..<count` in `vertices` order: its own vertex indices when it has
/// them, otherwise positions in `vertices`, listed once with a map back.
@usableFromInline
struct _NumberedVertices<G: Graph> {
    @usableFromInline let graph: G
    /// Without vertex indices: the vertices by number, and each one's number.
    @usableFromInline let listed: [G.Vertex]?
    @usableFromInline let numbers: [G.Vertex: Int]

    @inlinable
    init(_ graph: G, _ numbering: (listed: [G.Vertex], numbers: [G.Vertex: Int])?) {
        self.graph = graph
        listed = numbering?.listed
        numbers = numbering?.numbers ?? [:]
    }

    @inlinable
    var count: Int { listed?.count ?? graph.vertexIndexBound! }

    @inlinable
    func vertex(_ number: Int) -> G.Vertex { listed?[number] ?? graph.vertex(atIndex: number) }

    /// The number of `vertex`, trapping when it is not a vertex.
    @inlinable
    func number(of vertex: G.Vertex) -> Int {
        guard listed != nil else { return graph._requiredVertexIndex(of: vertex, "\(vertex) is not a vertex of the graph") }
        guard let number = numbers[vertex] else { preconditionFailure("\(vertex) is not a vertex of the graph") }
        return number
    }

    /// The number of `vertex`, or nil when it is not a vertex.
    @inlinable
    func number(safe vertex: G.Vertex) -> Int? {
        guard listed != nil else { return graph.contains(vertex) ? graph.vertexIndex(of: vertex) : nil }
        return numbers[vertex]
    }
}

extension _NumberedVertices: @unchecked Sendable where G: Sendable, G.Vertex: Sendable {}

/// A planar embedding of a graph: a rotation system, the clockwise order of the edges around each
/// vertex, over every edge position (NetworkX's `PlanarEmbedding`, LEMON's `PlanarEmbedding`,
/// OGDF's `CombinatorialEmbedding`). Its faces satisfy Euler's formula, n − m + f = 2, in every
/// connected component with an edge.
///
/// A self-loop appears twice in its vertex's order, its two ends adjacent, enclosing a face of
/// length 1. Parallel copies sit side by side, each consecutive pair enclosing a face of length 2.
/// Each clockwise order starts at the first edge of `incidentEdges(of:)`.
///
/// **Faces.** The face after the half-edge from u along edge e to w continues with the half-edge
/// before e in the clockwise order at w (NetworkX's `next_face_half_edge`), so a face lies to the
/// right of each of its half-edges. Faces are counted per connected component, and an isolated
/// vertex has none: two disjoint triangles have four faces.
///
/// The embedding keeps the graph it was made from (copy-on-write, so O(1)); mutating the graph
/// afterwards does not change it. When a graph has several embeddings, which one is returned is
/// not specified, but it depends only on the graph's rows: graphs with the same vertices, the same
/// edge positions and the same incidence order get the same embedding.
@frozen
public struct PlanarEmbedding<G: Graph> {
    @usableFromInline let _vertices: _NumberedVertices<G>
    /// Without edge indices: each position's edge number.
    @usableFromInline let _edgeNumbers: [G.Edges.Index: Int]
    @usableFromInline let _layout: _EmbeddingLayout
    /// The positions of `_layout.rowEdges`, and each edge number's position (empty when positions
    /// are the edge numbers themselves, `Int`s from 0).
    @usableFromInline let _rowPositions: [G.Edges.Index]
    @usableFromInline let _positions: [G.Edges.Index]

    @inlinable
    init(_ graph: G, _ numbering: (listed: [G.Vertex], numbers: [G.Vertex: Int])?, edgeNumbers: [G.Edges.Index: Int], layout: _EmbeddingLayout) {
        _vertices = _NumberedVertices(graph, numbering)
        _edgeNumbers = edgeNumbers
        _layout = layout
        let edges = graph.edges, m = layout.edgeCount
        // m increasing Int positions from 0 below m are exactly 0..<m.
        if G.Edges.Index.self == Int.self && edges.startIndex as? Int == 0 && edges.endIndex as? Int == m && edges.count == m {
            // Positions 0..<m are the edge numbers: share the rows rather than map them.
            _positions = []
            _rowPositions = unsafeBitCast(layout.rowEdges, to: [G.Edges.Index].self)
        } else {
            let positions = Array(edges.indices)
            _positions = positions
            _rowPositions = layout.rowEdges.map { positions[$0] }
        }
    }

    /// The position of edge number `k`.
    @inlinable
    func _position(_ k: Int) -> G.Edges.Index { _positions.isEmpty ? unsafeBitCast(k, to: G.Edges.Index.self) : _positions[k] }

    /// The edges at `vertex` in clockwise order, starting at the first edge of
    /// `incidentEdges(of:)`; a self-loop's position twice (NetworkX's `neighbors_cw_order`, with
    /// edge positions). O(1).
    ///
    /// - Precondition: `vertex` is a vertex of the graph.
    @inlinable
    public func clockwiseIncidentEdges(of vertex: G.Vertex) -> ArraySlice<G.Edges.Index> {
        let v = _vertices.number(of: vertex)
        return _rowPositions[_layout.rowOffsets[v] ..< _layout.rowOffsets[v + 1]]
    }

    /// `clockwiseIncidentEdges(of:)`, or nil when `vertex` is not a vertex of the graph.
    @inlinable
    public func clockwiseIncidentEdges(safe vertex: G.Vertex) -> ArraySlice<G.Edges.Index>? {
        guard let v = _vertices.number(safe: vertex) else { return nil }
        return _rowPositions[_layout.rowOffsets[v] ..< _layout.rowOffsets[v + 1]]
    }

    /// The vertices across the edges at `vertex`, in clockwise order: the vertex across each entry
    /// of `clockwiseIncidentEdges(of:)`, `vertex` itself twice for a self-loop. O(1).
    ///
    /// - Precondition: `vertex` is a vertex of the graph.
    @inlinable
    public func clockwiseNeighbors(of vertex: G.Vertex) -> ClockwiseNeighbors {
        let v = _vertices.number(of: vertex)
        return ClockwiseNeighbors(_numbers: _layout.rowNeighbors[_layout.rowOffsets[v] ..< _layout.rowOffsets[v + 1]], _vertices: _vertices)
    }

    /// `clockwiseNeighbors(of:)`, or nil when `vertex` is not a vertex of the graph.
    @inlinable
    public func clockwiseNeighbors(safe vertex: G.Vertex) -> ClockwiseNeighbors? {
        guard let v = _vertices.number(safe: vertex) else { return nil }
        return ClockwiseNeighbors(_numbers: _layout.rowNeighbors[_layout.rowOffsets[v] ..< _layout.rowOffsets[v + 1]], _vertices: _vertices)
    }

    /// `clockwiseNeighbors(of:)` in index space: the numbers of the neighbours of vertex number
    /// `index`. A vertex's number is its vertex index, or, for a graph without vertex indices, its
    /// position in `vertices`. O(1).
    ///
    /// - Precondition: `index` is in `0..<vertexCount`.
    @inlinable
    public func clockwiseNeighborIndices(ofIndex index: Int) -> ArraySlice<Int> {
        precondition(index >= 0 && index + 1 < _layout.rowOffsets.count, "Vertex index \(index) out of range")
        return _layout.rowNeighbors[_layout.rowOffsets[index] ..< _layout.rowOffsets[index + 1]]
    }

    /// The number of faces: Σ (2 − n_c + m_c) over the connected components with an edge.
    @inlinable
    public var faceCount: Int { _layout.faceOffsets.count - 1 }

    /// The faces, each a closed walk along the half-edges with the face on their right, in the
    /// order a walk of the vertices in order, and of each clockwise order in order, first reaches
    /// them (NetworkX's `faces()`); each starts at the tail of that first half-edge. Every edge
    /// position is on two sides of faces, once on each, or twice on one face (a bridge).
    @inlinable
    public var faces: Faces { Faces(_embedding: self) }

    /// The face to the right of edge `position` crossed from `vertex` (NetworkX's
    /// `traverse_face(v, w)`): a closed walk starting and ending at `vertex`. For a self-loop, the
    /// end listed first in `clockwiseIncidentEdges(of: vertex)`. O(face length).
    ///
    /// - Precondition: `vertex` is a vertex of the graph and an end of the edge at `position`.
    @inlinable
    public func face(from vertex: G.Vertex, alongEdgeAt position: G.Edges.Index) -> Walk<G.Vertex, G.Edges.Index> {
        let v = _vertices.number(of: vertex)
        let graph = _vertices.graph
        let e: Int
        if graph.edgeIndexBound != nil {
            e = graph.edgeIndex(of: position)
        } else {
            guard let number = _edgeNumbers[position] else { preconditionFailure("\(position) is not an edge position of the graph") }
            e = number
        }
        precondition(e >= 0 && e < _layout.edgeCount, "\(position) is not an edge position of the graph")
        let first = _layout.firstSlot(ofEdge: e), second = _layout.twinSlot(first)
        let start: Int
        if _layout.rowNeighbors[second] == v {
            start = first
        } else if _layout.rowNeighbors[first] == v {
            start = second
        } else {
            preconditionFailure("The edge at \(position) is not incident to \(vertex)")
        }
        let found = _layout.face(fromSlot: start)
        return _walk(found.vertices, found.edges)
    }

    @inlinable
    func _walk(_ vertexNumbers: some Collection<Int>, _ edgeNumbers: some Collection<Int>) -> Walk<G.Vertex, G.Edges.Index> {
        var vertices: [G.Vertex] = []
        vertices.reserveCapacity(vertexNumbers.count + 1)
        for v in vertexNumbers { vertices.append(_vertices.vertex(v)) }
        if let first = vertices.first { vertices.append(first) }
        return Walk(_uncheckedVertices: vertices, edges: edgeNumbers.map { _position($0) })
    }

    /// The vertices across the edges at a vertex, in clockwise order.
    @frozen
    public struct ClockwiseNeighbors: RandomAccessCollection {
        @usableFromInline let _numbers: ArraySlice<Int>
        @usableFromInline let _vertices: _NumberedVertices<G>

        @inlinable
        init(_numbers: ArraySlice<Int>, _vertices: _NumberedVertices<G>) {
            self._numbers = _numbers
            self._vertices = _vertices
        }

        @inlinable public var startIndex: Int { 0 }
        @inlinable public var endIndex: Int { _numbers.count }

        @inlinable
        public subscript(position: Int) -> G.Vertex {
            precondition(position >= 0 && position < _numbers.count, "Index out of range")
            return _vertices.vertex(_numbers[_numbers.startIndex + position])
        }
    }

    /// The faces of an embedding, each a closed walk.
    @frozen
    public struct Faces: RandomAccessCollection {
        @usableFromInline let _embedding: PlanarEmbedding

        @inlinable
        init(_embedding: PlanarEmbedding) { self._embedding = _embedding }

        @inlinable public var startIndex: Int { 0 }
        @inlinable public var endIndex: Int { _embedding.faceCount }

        /// The face at `position`. O(its length).
        @inlinable
        public subscript(position: Int) -> Walk<G.Vertex, G.Edges.Index> {
            precondition(position >= 0 && position < endIndex, "Face position out of range")
            let layout = _embedding._layout
            let range = layout.faceOffsets[position] ..< layout.faceOffsets[position + 1]
            return _embedding._walk(layout.faceVertices[range], layout.faceEdges[range])
        }
    }
}

extension PlanarEmbedding: @unchecked Sendable where G: Sendable, G.Vertex: Sendable, G.Edges.Index: Sendable {}
extension PlanarEmbedding.ClockwiseNeighbors: @unchecked Sendable where G: Sendable, G.Vertex: Sendable {}
extension PlanarEmbedding.Faces: @unchecked Sendable where G: Sendable, G.Vertex: Sendable, G.Edges.Index: Sendable {}

extension PlanarEmbedding: CustomStringConvertible {
    /// Each vertex with its neighbours in clockwise order, and the face count.
    public var description: String {
        let rows = (0 ..< _vertices.count).map { v in
            "\(_vertices.vertex(v)): [" + clockwiseNeighborIndices(ofIndex: v).map { "\(_vertices.vertex($0))" }.joined(separator: ", ") + "]"
        }
        return "PlanarEmbedding([" + rows.joined(separator: ", ") + "], faces: \(faceCount))"
    }
}
