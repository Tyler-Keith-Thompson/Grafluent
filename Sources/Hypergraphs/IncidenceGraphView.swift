import GraphProtocols

extension Hypergraph {
    /// The hypergraph's incidence graph, Berge's bipartite graph of vertices and hyperedges (the
    /// Levi graph), as a lazy `Graph`: vertex index `i` is vertex `i`, `n + p` is hyperedge `p`, and
    /// each incidence is an edge, XGI's `to_bipartite_graph` numbering. Graph algorithms reach a
    /// hypergraph through it.
    ///
    /// - Precondition: both index bounds are non-nil.
    /// - Complexity: O(1) for `UndirectedIncidenceList`; O(m) otherwise, for the hyperedges'
    ///   first incidence numbers (from the cached sizes, for `IncidenceMatrix`).
    @inlinable
    public var incidenceGraphView: IncidenceGraphView<Self> { IncidenceGraphView(base: self) }
}

/// An undirected hypergraph's incidence graph, read lazily from its storage: a `Graph` on
/// `0 ..< n + m` whose vertex `i < n` is the hypergraph's vertex index `i` and whose vertex `n + p`
/// is hyperedge `p`, with an edge `{i, n + p}` for each incidence. It is bipartite and simple
/// (vertices on the left, hyperedges on the right), an empty hyperedge is an isolated vertex, and
/// it loses nothing.
///
/// **Edges.** Edge position `q` is incidence number `q`: the incidences hyperedge by hyperedge, in
/// index order, and within a hyperedge in `memberIndices` order. So `edges[q]` is
/// `UndirectedEdge(i, n + p)`, the rows of the hyperedge side are contiguous ranges, and a
/// per-incidence array (a weight of a vertex in a hyperedge) is indexed by edge position. A view
/// is a snapshot, so its own positions never change, but they are valid for the hypergraph only
/// until its next mutation: the view of the mutated hypergraph numbers the incidences afresh (on
/// `IncidenceMatrix`, inserting one cell shifts every later incidence by one), and a
/// per-incidence array must be rebuilt for it.
///
/// **The LabeledGraph law.** Every index member reads the base's rows:
/// `neighborIndices(ofIndex: i)` is `incidentHyperedgeIndices(ofIndex: i)` shifted by n, and of
/// `n + p` it is `memberIndices(ofHyperedgeAt: p)`. So `Traversal`, `Connectivity`,
/// `ShortestPaths` and the rest run on the view without hashing a vertex. `_withIncidentIndexRows`
/// writes the view's rows out once per call from the base's `_withIncidenceRows`, in
/// O(n + m + p), so whole-graph algorithms (components, bridges, cut vertices) run at an
/// adjacency-list copy's speed on every base.
///
/// **Costs.** The view keeps each hyperedge's first incidence number, so a hyperedge's
/// `incidentEdges` is a range, O(1). On `UndirectedIncidenceList`, which stores its incidences,
/// every read is O(1) plus the row. On any other base, `edges[q]` and `endpointIndices(ofEdgeAt:)`
/// binary-search the hyperedge and find the member by its rank (`_memberIndex(atRank:…)`),
/// O(log m + ⌈n/64⌉) on `IncidenceMatrix` and O(log m + k) by default, and a vertex's
/// `incidentEdges` finds its place in each of its hyperedges: O(d·⌈n/64⌉) on `IncidenceMatrix`,
/// which counts bits, and O(Σ k) over them on a base without a faster `_memberRank`.
///
/// `BipartiteGraph(h.incidenceGraphView, left: 0 ..< h.vertexCount)` gives the bipartite structure,
/// and the view's components restricted to `0 ..< n` are the hypergraph's.
@frozen
public struct IncidenceGraphView<Base: Hypergraph>: Graph {
    public typealias Vertex = Int
    public typealias NeighborIndices = Neighbors
    public typealias IncidentEdges = IncidentEdgeIndices

    /// The hypergraph.
    public let base: Base

    /// The base's vertex count, n: the first hyperedge vertex.
    @usableFromInline internal let _n: Int
    @usableFromInline internal let _m: Int
    /// The number of incidences, p.
    @usableFromInline internal let _p: Int
    /// The first incidence number of each hyperedge, by index, and p at the end.
    @usableFromInline internal let _memberOffsets: ContiguousArray<Int>
    /// The positions by hyperedge index (empty for an `UndirectedIncidenceList`, whose positions
    /// are the indices).
    @usableFromInline internal let _positions: ContiguousArray<Base.Hyperedges.Index>
    /// The base's storage when it is an `UndirectedIncidenceList`, read directly.
    @usableFromInline internal let _plane: _IncidencePlane
    /// Whether `_plane` is the base's storage (otherwise it is empty and unused).
    @usableFromInline internal let _hasPlane: Bool

    /// The view of `base`.
    ///
    /// - Precondition: both of `base`'s index bounds are non-nil.
    /// - Complexity: O(1) for `UndirectedIncidenceList`, O(m) otherwise.
    @inlinable
    public init(base: Base) {
        guard let n = base.vertexIndexBound, let m = base.hyperedgeIndexBound else {
            preconditionFailure("The incidence graph needs vertex and hyperedge indices")
        }
        self.base = base
        _n = n
        _m = m
        if let list = base as? UndirectedIncidenceList<Base.Vertex> {
            _plane = list._plane
            _hasPlane = true
            _memberOffsets = list._plane.memberOffsets
            _positions = []
        } else {
            _plane = _IncidencePlane()
            _hasPlane = false
            var offsets = ContiguousArray<Int>()
            offsets.reserveCapacity(m &+ 1)
            offsets.append(0)
            var total = 0
            for position in base.hyperedges.indices {
                total &+= base.size(ofHyperedgeAt: position)
                offsets.append(total)
            }
            precondition(offsets.count == m &+ 1, "hyperedgeIndexBound differs from the number of hyperedges")
            _memberOffsets = offsets
            _positions = ContiguousArray(base.hyperedges.indices)
        }
        _p = _memberOffsets[m]
    }

    /// The incidence numbers at one vertex of an incidence graph view, its edge positions: a
    /// stored or computed row, or a contiguous range. Random access,
    /// O(1) per element.
    @frozen
    public struct IncidentEdgeIndices: RandomAccessCollection, Sendable {
        @usableFromInline internal let _row: ArraySlice<Int>
        @usableFromInline internal let _range: Range<Int>
        @usableFromInline internal let _isRange: Bool

        /// `row`'s entries.
        @inlinable
        internal init(row: ArraySlice<Int>) {
            _row = row
            _range = 0 ..< row.count
            _isRange = false
        }

        /// The numbers in `range`.
        @inlinable
        internal init(range: Range<Int>) {
            _row = []
            _range = range
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
            return _row[_row.startIndex &+ position]
        }
    }

    /// Every incidence as an edge, at its incidence number.
    @frozen
    public struct Edges: RandomAccessCollection {
        @usableFromInline internal let _view: IncidenceGraphView

        @inlinable
        internal init(_view: IncidenceGraphView) { self._view = _view }

        @inlinable public var startIndex: Int { 0 }
        @inlinable public var endIndex: Int { _view._p }
        @inlinable public func index(after i: Int) -> Int { i &+ 1 }
        @inlinable public func index(before i: Int) -> Int { i &- 1 }

        @inlinable
        public subscript(position: Int) -> UndirectedEdge<Int> {
            let (i, h) = _view.endpointIndices(ofEdgeAt: position)
            return UndirectedEdge(i, h)
        }

        /// Walks the hyperedges in order and each one's members, so a full pass costs
        /// O(m + p) reads of the base (plus its member scans), not a search per edge.
        @frozen
        public struct Iterator: IteratorProtocol {
            @usableFromInline internal let _view: IncidenceGraphView
            @usableFromInline internal var _q: Int
            @usableFromInline internal var _h: Int
            @usableFromInline internal var _members: Base.MemberIndices.Iterator?

            @inlinable
            internal init(_view: IncidenceGraphView) {
                self._view = _view
                _q = 0
                _h = -1
                _members = nil
            }

            @inlinable
            public mutating func next() -> UndirectedEdge<Int>? {
                guard _q < _view._p else { return nil }
                defer { _q &+= 1 }
                if _view._hasPlane {
                    return UndirectedEdge(_view._plane.members[_q], _view._n &+ _view._plane.hyperedgeOfIncidence[_q])
                }
                while _h < 0 || _q >= _view._memberOffsets[_h &+ 1] {
                    _h &+= 1
                    _members = nil
                }
                if _members == nil { _members = _view.base.memberIndices(ofHyperedgeAt: _view._position(_h)).makeIterator() }
                guard let i = _members!.next() else {
                    preconditionFailure("The hypergraph changed size since the view was made")
                }
                return UndirectedEdge(i, _view._n &+ _h)
            }
        }

        @inlinable
        public func makeIterator() -> Iterator { Iterator(_view: _view) }
    }

    /// The neighbors of one vertex of the view: a vertex's hyperedge indices shifted by n, or a
    /// hyperedge's member indices, read from the base without boxing.
    @frozen
    public struct Neighbors: Sequence {
        @usableFromInline internal let _hyperedges: Base.IncidentHyperedgeIndices?
        @usableFromInline internal let _members: Base.MemberIndices?
        @usableFromInline internal let _shift: Int

        @inlinable
        internal init(hyperedges: Base.IncidentHyperedgeIndices, shift: Int) {
            _hyperedges = hyperedges
            _members = nil
            _shift = shift
        }

        @inlinable
        internal init(members: Base.MemberIndices) {
            _hyperedges = nil
            _members = members
            _shift = 0
        }

        @frozen
        public struct Iterator: IteratorProtocol {
            @usableFromInline internal var _hyperedges: Base.IncidentHyperedgeIndices.Iterator?
            @usableFromInline internal var _members: Base.MemberIndices.Iterator?
            @usableFromInline internal let _shift: Int

            @inlinable
            internal init(_ neighbors: Neighbors) {
                _hyperedges = neighbors._hyperedges?.makeIterator()
                _members = neighbors._members?.makeIterator()
                _shift = neighbors._shift
            }

            @inlinable
            public mutating func next() -> Int? {
                if _members != nil { return _members!.next() }
                guard let p = _hyperedges!.next() else { return nil }
                return p &+ _shift
            }
        }

        @inlinable
        public func makeIterator() -> Iterator { Iterator(self) }

        @inlinable
        public var underestimatedCount: Int {
            _members?.underestimatedCount ?? _hyperedges!.underestimatedCount
        }
    }

    @inlinable
    @inline(__always)
    internal func _check(_ x: Int) {
        precondition(x >= 0 && x < _n &+ _m, "Vertex \(x) is out of range 0..<\(_n &+ _m)")
    }

    /// The hyperedge index holding incidence `q`: the last hyperedge whose first incidence number
    /// is at most `q`. O(log m).
    @inlinable
    internal func _hyperedge(ofIncidence q: Int) -> Int {
        var low = 0, high = _m
        while high &- low > 1 {
            let middle = low &+ (high &- low) / 2
            if _memberOffsets[middle] <= q { low = middle } else { high = middle }
        }
        return low
    }

    /// The position of hyperedge index `h`.
    @inlinable
    internal func _position(_ h: Int) -> Base.Hyperedges.Index {
        // On the incidence list (`_hasPlane`) the positions are the indices, `Int`s.
        _hasPlane ? unsafeBitCast(h, to: Base.Hyperedges.Index.self) : _positions[h]
    }

    /// The incidence numbers of vertex index `i`: its place in each of its hyperedges
    /// (`_memberRank`), after that hyperedge's first number. O(d·⌈n/64⌉) on `IncidenceMatrix`,
    /// O(Σ k) over its hyperedges on a base with the default rank.
    @inlinable
    internal func _computedIncidences(ofIndex i: Int) -> [Int] {
        var numbers: [Int] = []
        numbers.reserveCapacity(base.degree(ofIndex: i))
        for h in base.incidentHyperedgeIndices(ofIndex: i) {
            numbers.append(_memberOffsets[h] &+ base._memberRank(ofIndex: i, inHyperedgeAt: _position(h)))
        }
        return numbers
    }

    /// `0 ..< n + m`. O(1).
    @inlinable
    public var vertices: Range<Int> { 0 ..< _n &+ _m }

    /// Every incidence, at its number. O(1).
    @inlinable
    public var edges: Edges { Edges(_view: self) }

    /// n + m. O(1).
    @inlinable
    public var vertexCount: Int { _n &+ _m }

    /// The number of incidences. O(1).
    @inlinable
    public var edgeCount: Int { _p }

    /// The base's rows: a vertex's hyperedge indices shifted by n, or a hyperedge's members.
    ///
    /// - Precondition: `vertex` is in `0 ..< n + m`.
    @inlinable
    public func neighbors(of vertex: Int) -> Neighbors {
        _check(vertex)
        if vertex < _n { return Neighbors(hyperedges: base.incidentHyperedgeIndices(ofIndex: vertex), shift: _n) }
        return Neighbors(members: base.memberIndices(ofHyperedgeAt: _position(vertex &- _n)))
    }

    /// The incidence numbers at `vertex`: a hyperedge's range, O(1); a vertex's stored row on
    /// `UndirectedIncidenceList`, O(1), or its computed row on another base (O(d·⌈n/64⌉) on
    /// `IncidenceMatrix`).
    ///
    /// - Precondition: `vertex` is in `0 ..< n + m`.
    @inlinable
    public func incidentEdges(of vertex: Int) -> IncidentEdgeIndices {
        _check(vertex)
        if vertex >= _n {
            let h = vertex &- _n
            return IncidentEdgeIndices(range: _memberOffsets[h] ..< _memberOffsets[h &+ 1])
        }
        if _hasPlane { return IncidentEdgeIndices(row: _plane.row(vertex)) }
        return IncidentEdgeIndices(row: _computedIncidences(ofIndex: vertex)[...])
    }

    /// The base's degree of a vertex, or size of a hyperedge.
    @inlinable
    public func degree(of vertex: Int) -> Int {
        _check(vertex)
        if vertex < _n { return base.degree(ofIndex: vertex) }
        let h = vertex &- _n
        return _memberOffsets[h &+ 1] &- _memberOffsets[h]
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
        for p in base.incidentHyperedgeIndices(ofIndex: i) where p == h &- _n { return true }
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
    public func incidentEdgeIndices(ofIndex index: Int) -> IncidentEdgeIndices { incidentEdges(of: index) }

    @inlinable
    public func incidentEdges(ofIndex index: Int) -> IncidentEdgeIndices { incidentEdges(of: index) }

    @inlinable
    public func degree(ofIndex index: Int) -> Int { degree(of: index) }

    /// The incidence's vertex index and n plus its hyperedge index, without hashing: two loads on
    /// `UndirectedIncidenceList`, a binary search and a walk of the hyperedge's members otherwise.
    @inlinable
    public func endpointIndices(ofEdgeAt position: Int) -> (u: Int, v: Int) {
        precondition(position >= 0 && position < _p, "Edge position \(position) is out of range 0..<\(_p)")
        if _hasPlane { return (_plane.members[position], _n &+ _plane.hyperedgeOfIncidence[position]) }
        let h = _hyperedge(ofIncidence: position)
        return (base._memberIndex(atRank: position &- _memberOffsets[h], inHyperedgeAt: _position(h)), _n &+ h)
    }
}

extension IncidenceGraphView {
    /// The view's rows in index space, written out once for the call from the base's
    /// `_withIncidenceRows`: the vertex side's hyperedge indices shifted by n, the hyperedge
    /// side's members, and the incidence numbers beside them. O(n + m + p) and two arrays of 2p
    /// entries, which a whole-graph algorithm (components, bridges, cut vertices) recovers many
    /// times over against reading row by row. Algorithms that may stop early read
    /// `neighborIndices(ofIndex:)` instead.
    @inlinable
    public func _withIncidentIndexRows<Result>(
        _ body: (
            _ neighbors: UnsafeBufferPointer<Int>, _ neighborRows: UnsafeBufferPointer<Int>,
            _ edges: UnsafeBufferPointer<Int>, _ edgeRows: UnsafeBufferPointer<Int>
        ) -> Result
    ) -> Result? {
        let n = _n, m = _m, count = n &+ m, p = _p
        var neighbors = [Int](repeating: 0, count: 2 &* p)
        var edges = [Int](repeating: 0, count: 2 &* p)
        var rows = [Int](repeating: 0, count: 3 &* count)
        base._withIncidenceRows { memberOffsets, members, incidences, incidenceRows, hyperedges, hyperedgeRows in
            precondition(memberOffsets.count == m &+ 1 && members.count == p, "The hypergraph changed size since the view was made")
            neighbors.withUnsafeMutableBufferPointer { neighbors in
                edges.withUnsafeMutableBufferPointer { edges in
                    rows.withUnsafeMutableBufferPointer { rows in
                        var k = 0
                        for x in 0 ..< n {
                            rows[3 &* x] = k
                            let incidenceStart = incidenceRows[3 &* x], hyperedgeStart = hyperedgeRows[3 &* x]
                            let length = incidenceRows[3 &* x &+ 1]
                            for j in 0 ..< length {
                                neighbors[k] = n &+ hyperedges[hyperedgeStart &+ j]
                                edges[k] = incidences[incidenceStart &+ j]
                                k &+= 1
                            }
                            rows[3 &* x &+ 1] = length
                        }
                        for h in 0 ..< m {
                            let x = n &+ h
                            rows[3 &* x] = k
                            for q in memberOffsets[h] ..< memberOffsets[h &+ 1] {
                                neighbors[k] = members[q]
                                edges[k] = q
                                k &+= 1
                            }
                            rows[3 &* x &+ 1] = k &- rows[3 &* x]
                        }
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

extension IncidenceGraphView: Sendable where Base: Sendable, Base.Hyperedges.Index: Sendable {}
extension IncidenceGraphView.Edges: Sendable where Base: Sendable, Base.Hyperedges.Index: Sendable {}
extension IncidenceGraphView.Neighbors: Sendable where Base.IncidentHyperedgeIndices: Sendable, Base.MemberIndices: Sendable {}
