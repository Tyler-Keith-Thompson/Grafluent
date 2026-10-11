import GraphProtocols

extension DirectedHypergraph {
    /// The directed hypergraph's incidence graph as a lazy `BidirectionalDirectedGraph`: vertex
    /// index `i` is vertex `i`, `n + p` is hyperedge `p`, an arc from each source to its hyperedge
    /// and from the hyperedge to each target (XGI's directed `to_bipartite_graph`). Plain directed
    /// reachability, Gallo et al.'s "connected", is `descendants(of:)` on it restricted to
    /// `0 ..< n`.
    ///
    /// - Precondition: both index bounds are non-nil.
    /// - Complexity: O(1) for `IncidenceList` and `OrientedIncidenceMatrix` (O(m) for a conformer
    ///   that does not store its incidence counts).
    @inlinable
    public var incidenceGraph: DirectedIncidenceGraphView<Self> { DirectedIncidenceGraphView(base: self) }
}

/// A directed hypergraph's incidence graph, read lazily from its storage: a
/// `BidirectionalDirectedGraph` on `0 ..< n + m` whose vertex `i < n` is the hypergraph's vertex
/// index `i` and whose vertex `n + p` is hyperedge `p`, with an arc `i → n + p` for each source
/// `i` of `p` and `n + p → j` for each target `j`. A vertex on both sides of `p` gives the 2-cycle
/// `i → n + p → i`.
///
/// **Edges.** Positions `0 ..< P_s` are the source incidences, by hyperedge index and then vertex
/// index, and `P_s + q` is target incidence `q`, in the same order. A per-incidence array is
/// indexed by edge position.
///
/// **The LabeledGraph law.** Every index member reads the base's stored rows, shifted where they
/// hold hyperedges: `successorIndices(ofIndex: i)` is `outHyperedges(ofIndex: i)` plus n, and of
/// `n + p` it is `targetIndices(ofHyperedgeAt: p)`; `predecessorIndices` is `inHyperedges` plus n,
/// or `sourceIndices`. So graph algorithms run on the view without hashing a vertex. The view
/// does not offer `_withSuccessorIndexRows`, because the stored rows are not shifted.
@frozen
public struct DirectedIncidenceGraphView<Base: DirectedHypergraph>: BidirectionalDirectedGraph {
    public typealias Vertex = Int
    public typealias SuccessorIndices = Neighbors
    public typealias PredecessorIndices = Neighbors

    /// The directed hypergraph.
    public let base: Base

    @usableFromInline internal let _n: Int
    @usableFromInline internal let _m: Int
    /// The number of source incidences, P_s: the first target incidence's position.
    @usableFromInline internal let _sourceCount: Int
    @usableFromInline internal let _targetCount: Int
    /// The base's two planes when it is an `IncidenceList`, read directly.
    @usableFromInline internal let _sourcePlane: _IncidencePlane
    @usableFromInline internal let _targetPlane: _IncidencePlane
    /// Whether the planes are the base's storage (otherwise they are empty and unused).
    @usableFromInline internal let _hasPlanes: Bool

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
        _sourceCount = base._incidenceCount(targets: false)
        _targetCount = base._incidenceCount(targets: true)
        if let list = base as? IncidenceList<Base.Vertex> {
            _sourcePlane = list._sources
            _targetPlane = list._targets
            _hasPlanes = true
        } else {
            _sourcePlane = _IncidencePlane()
            _targetPlane = _IncidencePlane()
            _hasPlanes = false
        }
    }

    /// Every incidence as an arc: the source incidences, then the target incidences.
    @frozen
    public struct Edges: RandomAccessCollection {
        @usableFromInline internal let _base: Base
        @usableFromInline internal let _n: Int
        @usableFromInline internal let _sourceCount: Int
        @usableFromInline internal let _count: Int

        @inlinable
        internal init(_base: Base, _n: Int, _sourceCount: Int, _count: Int) {
            self._base = _base
            self._n = _n
            self._sourceCount = _sourceCount
            self._count = _count
        }

        @inlinable public var startIndex: Int { 0 }
        @inlinable public var endIndex: Int { _count }
        @inlinable public func index(after i: Int) -> Int { i &+ 1 }
        @inlinable public func index(before i: Int) -> Int { i &- 1 }

        @inlinable
        public subscript(position: Int) -> DirectedEdge<Int> {
            precondition(position >= 0 && position < _count, "Edge position \(position) is out of range 0..<\(_count)")
            if position < _sourceCount {
                let (i, p) = _base._incidence(position, targets: false)
                return DirectedEdge(from: i, to: _n &+ p)
            }
            let (j, p) = _base._incidence(position &- _sourceCount, targets: true)
            return DirectedEdge(from: _n &+ p, to: j)
        }
    }

    /// The successors or predecessors of one vertex of the view: a vertex's out- or
    /// in-hyperedges shifted by n, or a hyperedge's targets or sources.
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

    @inlinable
    internal func _position(_ x: Int) -> Base.Hyperedges.Index {
        base._hyperedgePosition(ofIndex: x &- _n)
    }

    /// `0 ..< n + m`. O(1).
    @inlinable
    public var vertices: Range<Int> { 0 ..< _n &+ _m }

    /// Every incidence as an arc. O(1).
    @inlinable
    public var edges: Edges { Edges(_base: base, _n: _n, _sourceCount: _sourceCount, _count: _sourceCount &+ _targetCount) }

    @inlinable
    public var vertexCount: Int { _n &+ _m }

    @inlinable
    public var edgeCount: Int { _sourceCount &+ _targetCount }

    /// A vertex's out-hyperedges shifted by n, or a hyperedge's targets.
    @inlinable
    public func successors(of vertex: Int) -> Neighbors {
        _check(vertex)
        if _hasPlanes {
            if vertex < _n { return Neighbors(row: _sourcePlane.hyperedgeRow(vertex), shift: _n) }
            return Neighbors(row: _targetPlane.memberIndices(of: vertex &- _n), shift: 0)
        }
        if vertex < _n {
            return Neighbors(_fallback: AnySequence(base.outHyperedges(ofIndex: vertex).lazy.map { [base = self.base, n = self._n] in n &+ base.hyperedgeIndex(of: $0) }))
        }
        return Neighbors(_fallback: AnySequence(base.targetIndices(ofHyperedgeAt: _position(vertex))))
    }

    /// A vertex's in-hyperedges shifted by n, or a hyperedge's sources.
    @inlinable
    public func predecessors(of vertex: Int) -> Neighbors {
        _check(vertex)
        if _hasPlanes {
            if vertex < _n { return Neighbors(row: _targetPlane.hyperedgeRow(vertex), shift: _n) }
            return Neighbors(row: _sourcePlane.memberIndices(of: vertex &- _n), shift: 0)
        }
        if vertex < _n {
            return Neighbors(_fallback: AnySequence(base.inHyperedges(ofIndex: vertex).lazy.map { [base = self.base, n = self._n] in n &+ base.hyperedgeIndex(of: $0) }))
        }
        return Neighbors(_fallback: AnySequence(base.sourceIndices(ofHyperedgeAt: _position(vertex))))
    }

    /// A vertex's source incidences, or `P_s` plus a hyperedge's target incidences.
    @inlinable
    public func outEdges(of vertex: Int) -> IncidenceNumbers {
        _check(vertex)
        if _hasPlanes {
            if vertex < _n { return IncidenceNumbers(row: _sourcePlane.row(vertex), shift: 0) }
            let range = _targetPlane.range(of: vertex &- _n)
            return IncidenceNumbers(range: _sourceCount &+ range.lowerBound ..< _sourceCount &+ range.upperBound)
        }
        if vertex < _n { return IncidenceNumbers(row: base._incidences(ofIndex: vertex, targets: false), shift: 0) }
        let range = base._incidences(ofHyperedgeIndex: vertex &- _n, targets: true)
        return IncidenceNumbers(range: _sourceCount &+ range.lowerBound ..< _sourceCount &+ range.upperBound)
    }

    /// `P_s` plus a vertex's target incidences, or a hyperedge's source incidences.
    @inlinable
    public func inEdges(of vertex: Int) -> IncidenceNumbers {
        _check(vertex)
        if _hasPlanes {
            if vertex < _n { return IncidenceNumbers(row: _targetPlane.row(vertex), shift: _sourceCount) }
            return IncidenceNumbers(range: _sourcePlane.range(of: vertex &- _n))
        }
        if vertex < _n { return IncidenceNumbers(row: base._incidences(ofIndex: vertex, targets: true), shift: _sourceCount) }
        return IncidenceNumbers(range: base._incidences(ofHyperedgeIndex: vertex &- _n, targets: false))
    }

    @inlinable
    public func source(ofEdgeAt position: Int) -> Int { sourceIndex(ofEdgeAt: position) }

    @inlinable
    public func target(ofEdgeAt position: Int) -> Int { targetIndex(ofEdgeAt: position) }

    /// The base's out-degree of a vertex, or the number of targets of a hyperedge.
    @inlinable
    public func outDegree(of vertex: Int) -> Int {
        _check(vertex)
        if _hasPlanes { return vertex < _n ? _sourcePlane.degree(vertex) : _targetPlane.size(of: vertex &- _n) }
        if vertex < _n { return base.outDegree(ofIndex: vertex) }
        return base.targets(ofHyperedgeAt: _position(vertex)).count
    }

    /// The base's in-degree of a vertex, or the number of sources of a hyperedge.
    @inlinable
    public func inDegree(of vertex: Int) -> Int {
        _check(vertex)
        if _hasPlanes { return vertex < _n ? _targetPlane.degree(vertex) : _sourcePlane.size(of: vertex &- _n) }
        if vertex < _n { return base.inDegree(ofIndex: vertex) }
        return base.sources(ofHyperedgeAt: _position(vertex)).count
    }

    @inlinable
    public func degree(of vertex: Int) -> Int { outDegree(of: vertex) &+ inDegree(of: vertex) }

    @inlinable
    public func contains(_ vertex: Int) -> Bool { vertex >= 0 && vertex < _n &+ _m }

    /// Whether the arc joins a source to its hyperedge or a hyperedge to a target. O(d).
    @inlinable
    public func contains(edge: DirectedEdge<Int>) -> Bool {
        guard contains(edge.source), contains(edge.target) else { return false }
        if edge.source < _n, edge.target >= _n {
            for position in base.outHyperedges(ofIndex: edge.source) where base.hyperedgeIndex(of: position) == edge.target &- _n { return true }
        } else if edge.source >= _n, edge.target < _n {
            for position in base.inHyperedges(ofIndex: edge.target) where base.hyperedgeIndex(of: position) == edge.source &- _n { return true }
        }
        return false
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
    public func successorIndices(ofIndex index: Int) -> Neighbors { successors(of: index) }

    @inlinable
    public func predecessorIndices(ofIndex index: Int) -> Neighbors { predecessors(of: index) }

    @inlinable
    public func outEdges(ofIndex index: Int) -> IncidenceNumbers { outEdges(of: index) }

    @inlinable
    public func inEdges(ofIndex index: Int) -> IncidenceNumbers { inEdges(of: index) }

    @inlinable
    public func outDegree(ofIndex index: Int) -> Int { outDegree(of: index) }

    @inlinable
    public func inDegree(ofIndex index: Int) -> Int { inDegree(of: index) }

    /// The arc's tail, read from the stored incidence, without hashing.
    @inlinable
    public func sourceIndex(ofEdgeAt position: Int) -> Int {
        precondition(position >= 0 && position < _sourceCount &+ _targetCount, "Edge position \(position) is out of range")
        if position < _sourceCount { return base._incidence(position, targets: false).vertexIndex }
        return _n &+ base._incidence(position &- _sourceCount, targets: true).hyperedgeIndex
    }

    /// The arc's head, read from the stored incidence, without hashing.
    @inlinable
    public func targetIndex(ofEdgeAt position: Int) -> Int {
        precondition(position >= 0 && position < _sourceCount &+ _targetCount, "Edge position \(position) is out of range")
        if position < _sourceCount { return _n &+ base._incidence(position, targets: false).hyperedgeIndex }
        return base._incidence(position &- _sourceCount, targets: true).vertexIndex
    }

    @inlinable
    public var edgeIndexBound: Int? { _sourceCount &+ _targetCount }

    @inlinable
    public func edgeIndex(of position: Int) -> Int {
        precondition(position >= 0 && position < _sourceCount &+ _targetCount, "Edge position \(position) is out of range")
        return position
    }
}

extension DirectedIncidenceGraphView: Sendable where Base: Sendable {}
extension DirectedIncidenceGraphView.Edges: Sendable where Base: Sendable {}
