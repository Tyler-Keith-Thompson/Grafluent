import GraphProtocols

extension Hypergraph {
    /// The hypergraph's incidence graph, Berge's bipartite graph of vertices and hyperedges (the
    /// Levi graph), as a lazy `Graph`: vertex index `i` is vertex `i`, `n + p` is hyperedge `p`, and
    /// each incidence is an edge, XGI's `to_bipartite_graph` numbering. Graph algorithms reach a
    /// hypergraph through it.
    ///
    /// - Precondition: both index bounds are non-nil.
    /// - Complexity: O(1) for `UndirectedIncidenceList` and `IncidenceMatrix` (O(m) for a conformer
    ///   that does not store its incidence count).
    @inlinable
    public var incidenceGraph: IncidenceGraphView<Self> { IncidenceGraphView(base: self) }
}

/// The incidence numbers of one vertex of an incidence graph view, which are its edge positions:
/// a stored row (shifted by a constant) or a contiguous range. Random access, O(1) per element.
@frozen
public struct IncidenceNumbers: RandomAccessCollection, Sendable {
    @usableFromInline internal let _row: ArraySlice<Int>
    @usableFromInline internal let _range: Range<Int>
    @usableFromInline internal let _shift: Int
    @usableFromInline internal let _isRange: Bool

    /// `row`'s entries plus `shift`.
    @inlinable
    internal init(row: ArraySlice<Int>, shift: Int) {
        _row = row
        _range = 0 ..< row.count
        _shift = shift
        _isRange = false
    }

    /// The numbers in `range`.
    @inlinable
    internal init(range: Range<Int>) {
        _row = []
        _range = range
        _shift = 0
        _isRange = true
    }

    @inlinable public var startIndex: Int { 0 }
    @inlinable public var endIndex: Int { _isRange ? _range.count : _row.count }
    @inlinable public func index(after i: Int) -> Int { i &+ 1 }
    @inlinable public func index(before i: Int) -> Int { i &- 1 }

    @inlinable
    public subscript(position: Int) -> Int {
        if _isRange {
            precondition(position >= 0 && position < _range.count, "Index out of range")
            return _range.lowerBound &+ position
        }
        return _row[_row.startIndex &+ position] &+ _shift
    }
}

/// An undirected hypergraph's incidence graph, read lazily from its storage: a `Graph` on
/// `0 ..< n + m` whose vertex `i < n` is the hypergraph's vertex index `i` and whose vertex `n + p`
/// is hyperedge `p`, with an edge `{i, n + p}` for each incidence. It is bipartite and simple
/// (vertices on the left, hyperedges on the right), an empty hyperedge is an isolated vertex, and
/// it loses nothing.
///
/// **Edges.** Edge position `q` is incidence number `q`: the incidences hyperedge by hyperedge, in
/// index order, members in index order. So `edges[q]` is `UndirectedEdge(i, n + p)`, the rows of
/// the hyperedge side are contiguous ranges, and a per-incidence array (a weight of a vertex in a
/// hyperedge) is indexed by edge position.
///
/// **The LabeledGraph law.** Every index member reads the base's stored rows:
/// `neighborIndices(ofIndex: i)` is `incidentHyperedges(ofIndex: i)` shifted by n, and of `n + p`
/// it is `memberIndices(ofHyperedgeAt: p)`; `endpointIndices(ofEdgeAt:)` and
/// `incidentEdgeIndices(ofIndex:)` read the stored incidences. So `Traversal`, `Connectivity`,
/// `ShortestPaths` and the rest run on the view without hashing a vertex. The view does not offer
/// `_withIncidentIndexRows`, because the vertex side's stored rows hold hyperedge positions
/// without the shift; an algorithm that needs raw rows copies the view in O(n + m + p).
///
/// `BipartiteGraph(h.incidenceGraph, left: 0 ..< h.vertexCount)` gives the bipartite structure,
/// and the view's components restricted to `0 ..< n` are the hypergraph's.
@frozen
public struct IncidenceGraphView<Base: Hypergraph>: Graph {
    public typealias Vertex = Int
    public typealias NeighborIndices = Neighbors
    public typealias IncidentEdgeIndices = IncidenceNumbers

    /// The hypergraph.
    public let base: Base

    /// The base's vertex count, n: the first hyperedge vertex.
    @usableFromInline internal let _n: Int
    @usableFromInline internal let _m: Int
    @usableFromInline internal let _p: Int
    /// The base's storage when it is an `UndirectedIncidenceList`, read directly: rows without a
    /// copy of the base per row.
    @usableFromInline internal let _plane: _IncidencePlane
    /// Whether `_plane` is the base's storage (otherwise it is empty and unused).
    @usableFromInline internal let _hasPlane: Bool

    /// The view of `base`.
    ///
    /// - Precondition: both of `base`'s index bounds are non-nil.
    @inlinable
    public init(base: Base) {
        guard let n = base.vertexIndexBound, let m = base.hyperedgeIndexBound else {
            preconditionFailure("The incidence graph needs vertex and hyperedge indices")
        }
        self.base = base
        _n = n
        _m = m
        _p = base._incidenceCount
        if let list = base as? UndirectedIncidenceList<Base.Vertex> {
            _plane = list._plane
            _hasPlane = true
        } else {
            _plane = _IncidencePlane()
            _hasPlane = false
        }
    }

    /// Every incidence as an edge, at its incidence number.
    @frozen
    public struct Edges: RandomAccessCollection {
        @usableFromInline internal let _base: Base
        @usableFromInline internal let _n: Int
        @usableFromInline internal let _p: Int

        @inlinable
        internal init(_base: Base, _n: Int, _p: Int) {
            self._base = _base
            self._n = _n
            self._p = _p
        }

        @inlinable public var startIndex: Int { 0 }
        @inlinable public var endIndex: Int { _p }
        @inlinable public func index(after i: Int) -> Int { i &+ 1 }
        @inlinable public func index(before i: Int) -> Int { i &- 1 }

        @inlinable
        public subscript(position: Int) -> UndirectedEdge<Int> {
            precondition(position >= 0 && position < _p, "Edge position \(position) is out of range 0..<\(_p)")
            let (i, p) = _base._incidence(position)
            return UndirectedEdge(i, _n &+ p)
        }
    }

    /// The neighbors of one vertex of the view: a vertex's hyperedges shifted by n, or a
    /// hyperedge's members.
    @frozen
    public struct Neighbors: Sequence {
        /// The stored row, its entries shifted by `_shift`: a vertex's hyperedge positions
        /// shifted by n, or a hyperedge's vertex indices unshifted.
        @usableFromInline internal let _row: ArraySlice<Int>
        @usableFromInline internal let _shift: Int
        /// For a base whose storage the view does not read directly: the base's own row, boxed,
        /// so the iterator stays small enough for callers to inline.
        @usableFromInline internal let _fallback: AnySequence<Int>?

        @inlinable
        internal init(row: ArraySlice<Int>, shift: Int) {
            _row = row
            _shift = shift
            _fallback = nil
        }

        @inlinable
        internal init(_fallback: AnySequence<Int>) {
            _row = []
            _shift = 0
            self._fallback = _fallback
        }

        @frozen
        public struct Iterator: IteratorProtocol {
            @usableFromInline internal let _row: ArraySlice<Int>
            @usableFromInline internal let _shift: Int
            @usableFromInline internal var _cursor: Int
            @usableFromInline internal var _fallback: AnyIterator<Int>?

            @inlinable
            internal init(_ neighbors: Neighbors) {
                _row = neighbors._row
                _shift = neighbors._shift
                _cursor = neighbors._row.startIndex
                _fallback = neighbors._fallback?.makeIterator()
            }

            @inlinable
            public mutating func next() -> Int? {
                if _fallback != nil { return _fallback!.next() }
                guard _cursor < _row.endIndex else { return nil }
                let entry = _row[_cursor]
                _cursor &+= 1
                return entry &+ _shift
            }
        }

        @inlinable
        public func makeIterator() -> Iterator { Iterator(self) }

        @inlinable
        public var underestimatedCount: Int { _fallback == nil ? _row.count : 0 }
    }

    @inlinable
    @inline(__always)
    internal func _check(_ x: Int) {
        precondition(x >= 0 && x < _n &+ _m, "Vertex \(x) is out of range 0..<\(_n &+ _m)")
    }

    /// `0 ..< n + m`. O(1).
    @inlinable
    public var vertices: Range<Int> { 0 ..< _n &+ _m }

    /// Every incidence, at its number. O(1).
    @inlinable
    public var edges: Edges { Edges(_base: base, _n: _n, _p: _p) }

    /// n + m. O(1).
    @inlinable
    public var vertexCount: Int { _n &+ _m }

    /// The number of incidences. O(1).
    @inlinable
    public var edgeCount: Int { _p }

    /// The base's rows: a vertex's hyperedges shifted by n, or a hyperedge's members.
    ///
    /// - Precondition: `vertex` is in `0 ..< n + m`.
    @inlinable
    public func neighbors(of vertex: Int) -> Neighbors {
        _check(vertex)
        if _hasPlane {
            if vertex < _n { return Neighbors(row: _plane.hyperedgeRow(vertex), shift: _n) }
            return Neighbors(row: _plane.memberIndices(of: vertex &- _n), shift: 0)
        }
        if vertex < _n {
            return Neighbors(_fallback: AnySequence(base.incidentHyperedges(ofIndex: vertex).lazy.map { [base = self.base, n = self._n] in n &+ base.hyperedgeIndex(of: $0) }))
        }
        return Neighbors(_fallback: AnySequence(base.memberIndices(ofHyperedgeAt: base._hyperedgePosition(ofIndex: vertex &- _n))))
    }

    /// The incidence numbers at `vertex`: a vertex's stored row, or a hyperedge's range.
    ///
    /// - Precondition: `vertex` is in `0 ..< n + m`.
    @inlinable
    public func incidentEdges(of vertex: Int) -> IncidenceNumbers {
        _check(vertex)
        if _hasPlane {
            if vertex < _n { return IncidenceNumbers(row: _plane.row(vertex), shift: 0) }
            return IncidenceNumbers(range: _plane.range(of: vertex &- _n))
        }
        if vertex < _n { return IncidenceNumbers(row: base._incidences(ofIndex: vertex), shift: 0) }
        return IncidenceNumbers(range: base._incidences(ofHyperedgeIndex: vertex &- _n))
    }

    /// The base's degree of a vertex, or size of a hyperedge.
    @inlinable
    public func degree(of vertex: Int) -> Int {
        _check(vertex)
        if _hasPlane { return vertex < _n ? _plane.degree(vertex) : _plane.size(of: vertex &- _n) }
        if vertex < _n { return base.degree(ofIndex: vertex) }
        return base.size(ofHyperedgeAt: base._hyperedgePosition(ofIndex: vertex &- _n))
    }

    @inlinable
    public func contains(_ vertex: Int) -> Bool {
        vertex >= 0 && vertex < _n &+ _m
    }

    /// Whether the edge joins a vertex and a hyperedge it is a member of. O(d) in the vertex's
    /// degree.
    @inlinable
    public func contains(edge: UndirectedEdge<Int>) -> Bool {
        guard contains(edge.u), contains(edge.v) else { return false }
        let (i, h) = edge.u < edge.v ? (edge.u, edge.v) : (edge.v, edge.u)
        guard i < _n, h >= _n else { return false }
        for position in base.incidentHyperedges(ofIndex: i) where base.hyperedgeIndex(of: position) == h &- _n { return true }
        return false
    }

    @inlinable
    public func oppositeVertex(to vertex: Int, acrossEdgeAt position: Int) -> Int {
        let (u, v) = endpointIndices(ofEdgeAt: position)
        return vertex == u ? v : u
    }

    @inlinable
    public var vertexIndexBound: Int? { _n &+ _m }

    @inlinable
    public func vertexIndex(of vertex: Int) -> Int {
        _check(vertex)
        return vertex
    }

    @inlinable
    public func vertex(atIndex index: Int) -> Int {
        _check(index)
        return index
    }

    @inlinable
    public func neighborIndices(ofIndex index: Int) -> Neighbors { neighbors(of: index) }

    @inlinable
    public var edgeIndexBound: Int? { _p }

    @inlinable
    public func edgeIndex(of position: Int) -> Int {
        precondition(position >= 0 && position < _p, "Edge position \(position) is out of range 0..<\(_p)")
        return position
    }

    @inlinable
    public func incidentEdgeIndices(ofIndex index: Int) -> IncidenceNumbers { incidentEdges(of: index) }

    @inlinable
    public func incidentEdges(ofIndex index: Int) -> IncidenceNumbers { incidentEdges(of: index) }

    @inlinable
    public func degree(ofIndex index: Int) -> Int { degree(of: index) }

    /// The incidence's vertex index and n plus its hyperedge index, without hashing.
    @inlinable
    public func endpointIndices(ofEdgeAt position: Int) -> (u: Int, v: Int) {
        precondition(position >= 0 && position < _p, "Edge position \(position) is out of range 0..<\(_p)")
        let (i, p) = base._incidence(position)
        return (i, _n &+ p)
    }
}

extension IncidenceGraphView {
    /// The view's rows in index space, written out once for the call: the vertex side's stored
    /// rows shifted by n, the hyperedge side's members, and the incidence numbers beside them.
    /// The view stores no such rows (the shift is not stored), so this costs O(n + m + p) and two
    /// arrays of 2p entries, which a whole-graph algorithm (components, bridges, cut vertices)
    /// recovers many times over against reading row by row. Algorithms that may stop early read
    /// `neighborIndices(ofIndex:)` instead.
    @inlinable
    public func _withIncidentIndexRows<Result>(
        _ body: (
            _ neighbors: UnsafeBufferPointer<Int>, _ neighborRows: UnsafeBufferPointer<Int>,
            _ edges: UnsafeBufferPointer<Int>, _ edgeRows: UnsafeBufferPointer<Int>
        ) -> Result
    ) -> Result? {
        let count = _n &+ _m
        var neighbors = [Int](repeating: 0, count: 2 &* _p)
        var edges = [Int](repeating: 0, count: 2 &* _p)
        var rows = [Int](repeating: 0, count: 3 &* count)
        neighbors.withUnsafeMutableBufferPointer { neighbors in
            edges.withUnsafeMutableBufferPointer { edges in
                rows.withUnsafeMutableBufferPointer { rows in
                    var k = 0
                    for x in 0 ..< count {
                        rows[3 &* x] = k
                        if _hasPlane {
                            if x < _n {
                                let row = _plane.row(x), hyperedgeRow = _plane.hyperedgeRow(x)
                                for (q, p) in zip(row, hyperedgeRow) {
                                    neighbors[k] = _n &+ p
                                    edges[k] = q
                                    k &+= 1
                                }
                            } else {
                                let range = _plane.range(of: x &- _n)
                                for q in range {
                                    neighbors[k] = _plane.members[q]
                                    edges[k] = q
                                    k &+= 1
                                }
                            }
                        } else {
                            let start = k
                            for w in neighborIndices(ofIndex: x) {
                                neighbors[k] = w
                                k &+= 1
                            }
                            var e = start
                            for q in incidentEdges(of: x) {
                                edges[e] = q
                                e &+= 1
                            }
                            precondition(e == k, "The incidence rows of vertex \(x) differ in length")
                        }
                        rows[3 &* x &+ 1] = k &- rows[3 &* x]
                    }
                }
            }
        }
        return neighbors.withUnsafeBufferPointer { neighbors in
            edges.withUnsafeBufferPointer { edges in
                rows.withUnsafeBufferPointer { rows in body(neighbors, rows, edges, rows) }
            }
        }
    }
}

extension IncidenceGraphView: Sendable where Base: Sendable {}
extension IncidenceGraphView.Edges: Sendable where Base: Sendable {}
