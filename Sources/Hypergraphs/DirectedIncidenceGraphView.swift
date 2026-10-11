import GraphProtocols

extension DirectedHypergraph {
    /// The directed hypergraph's incidence graph as a lazy `BidirectionalDirectedGraph`: vertex
    /// index `i` is vertex `i`, `n + p` is hyperedge `p`, an arc from each source to its hyperedge
    /// and from the hyperedge to each target (XGI's directed `to_bipartite_graph`). Plain directed
    /// reachability, Gallo et al.'s "connected", is `descendants(of:)` on it restricted to
    /// `0 ..< n`.
    ///
    /// - Precondition: both index bounds are non-nil.
    /// - Complexity: O(1) for `IncidenceList`; O(m) otherwise, for each side's first incidence
    ///   numbers (from the cached side sizes, for `OrientedIncidenceMatrix`).
    @inlinable
    public var incidenceGraph: DirectedIncidenceGraphView<Self> { DirectedIncidenceGraphView(base: self) }
}

/// A directed hypergraph's incidence graph, read lazily from its storage: a
/// `BidirectionalDirectedGraph` on `0 ..< n + m` whose vertex `i < n` is the hypergraph's vertex
/// index `i` and whose vertex `n + p` is hyperedge `p`, with an arc `i → n + p` for each source
/// `i` of `p` and `n + p → j` for each target `j`. A vertex on both sides of `p` gives the 2-cycle
/// `i → n + p → i`.
///
/// **Edges.** Positions `0 ..< P_s` are the source incidences, hyperedge by hyperedge in index
/// order and within one in `sourceIndices` order, and `P_s + q` is target incidence `q`, in the
/// same order. A per-incidence array is indexed by edge position. A view is a snapshot, so its own
/// positions never change, but they are valid for the hypergraph only until its next mutation:
/// the view of the mutated hypergraph numbers the incidences afresh (on `OrientedIncidenceMatrix`,
/// inserting one cell shifts every later incidence by one).
///
/// **The LabeledGraph law.** Every index member reads the base's rows, shifted where they hold
/// hyperedges: `successorIndices(ofIndex: i)` is `outHyperedgeIndices(ofIndex: i)` plus n, and
/// of `n + p` it is `targetIndices(ofHyperedgeAt: p)`; `predecessorIndices` is
/// `inHyperedgeIndices` plus n, or `sourceIndices`. So graph algorithms run on the view without
/// hashing a vertex. The view does not offer `_withSuccessorIndexRows`, whose contract needs edge
/// positions in row order.
///
/// **Costs.** As for `IncidenceGraphView`: O(1) reads on `IncidenceList`, which stores its
/// incidences; on another base a hyperedge's incidence numbers are a range, O(1), `edges[q]`
/// binary-searches and selects by rank, O(log m + ⌈n/64⌉) on `OrientedIncidenceMatrix`, and a vertex's `outEdges` or `inEdges` is computed from `_memberRank`, O(d·⌈n/64⌉) on
/// `OrientedIncidenceMatrix`.
@frozen
public struct DirectedIncidenceGraphView<Base: DirectedHypergraph>: BidirectionalDirectedGraph {
    public typealias Vertex = Int
    public typealias SuccessorIndices = Neighbors
    public typealias PredecessorIndices = Neighbors
    public typealias InEdges = OutEdges

    /// The directed hypergraph.
    public let base: Base

    @usableFromInline internal let _n: Int
    @usableFromInline internal let _m: Int
    /// The number of source incidences, P_s: the first target incidence's position.
    @usableFromInline internal let _sourceCount: Int
    @usableFromInline internal let _targetCount: Int
    /// The first source incidence number of each hyperedge, by index, and P_s at the end.
    @usableFromInline internal let _sourceOffsets: ContiguousArray<Int>
    /// The first target incidence number of each hyperedge, by index, and P_t at the end.
    @usableFromInline internal let _targetOffsets: ContiguousArray<Int>
    /// The positions by hyperedge index (empty for an `IncidenceList`).
    @usableFromInline internal let _positions: ContiguousArray<Base.Hyperedges.Index>
    /// The base's two planes when it is an `IncidenceList`, read directly.
    @usableFromInline internal let _sourcePlane: _IncidencePlane
    @usableFromInline internal let _targetPlane: _IncidencePlane
    /// Whether the planes are the base's storage (otherwise they are empty and unused).
    @usableFromInline internal let _hasPlanes: Bool

    /// The view of `base`.
    ///
    /// - Precondition: both of `base`'s index bounds are non-nil.
    /// - Complexity: O(1) for `IncidenceList`, O(m) otherwise.
    @inlinable
    public init(base: Base) {
        guard let n = base.vertexIndexBound, let m = base.hyperedgeIndexBound else {
            preconditionFailure("The incidence graph needs vertex and hyperedge indices")
        }
        self.base = base
        _n = n
        _m = m
        if let list = base as? IncidenceList<Base.Vertex> {
            _sourcePlane = list._sources
            _targetPlane = list._targets
            _hasPlanes = true
            _sourceOffsets = list._sources.memberOffsets
            _targetOffsets = list._targets.memberOffsets
            _positions = []
        } else {
            _sourcePlane = _IncidencePlane()
            _targetPlane = _IncidencePlane()
            _hasPlanes = false
            var sourceOffsets = ContiguousArray<Int>(), targetOffsets = ContiguousArray<Int>()
            sourceOffsets.reserveCapacity(m &+ 1)
            targetOffsets.reserveCapacity(m &+ 1)
            sourceOffsets.append(0)
            targetOffsets.append(0)
            var sourceTotal = 0, targetTotal = 0
            for position in base.hyperedges.indices {
                sourceTotal &+= base.sourceSize(ofHyperedgeAt: position)
                targetTotal &+= base.targetSize(ofHyperedgeAt: position)
                sourceOffsets.append(sourceTotal)
                targetOffsets.append(targetTotal)
            }
            precondition(sourceOffsets.count == m &+ 1, "hyperedgeIndexBound differs from the number of hyperedges")
            _sourceOffsets = sourceOffsets
            _targetOffsets = targetOffsets
            _positions = ContiguousArray(base.hyperedges.indices)
        }
        _sourceCount = _sourceOffsets[m]
        _targetCount = _targetOffsets[m]
    }

    /// The incidence numbers at one vertex of a directed incidence graph view, its edge
    /// positions: a stored or computed row (shifted by a constant), or a contiguous range. Random
    /// access, O(1) per element. Also the view's `InEdges`.
    @frozen
    public struct OutEdges: RandomAccessCollection, Sendable {
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

    /// Every incidence as an arc: the source incidences, then the target incidences.
    @frozen
    public struct Edges: RandomAccessCollection {
        @usableFromInline internal let _view: DirectedIncidenceGraphView

        @inlinable
        internal init(_view: DirectedIncidenceGraphView) { self._view = _view }

        @inlinable public var startIndex: Int { 0 }
        @inlinable public var endIndex: Int { _view._sourceCount &+ _view._targetCount }
        @inlinable public func index(after i: Int) -> Int { i &+ 1 }
        @inlinable public func index(before i: Int) -> Int { i &- 1 }

        @inlinable
        public subscript(position: Int) -> DirectedEdge<Int> {
            let (source, target) = _view._endpoints(ofEdgeAt: position)
            return DirectedEdge(from: source, to: target)
        }

        /// Walks the source sides in hyperedge order, then the target sides, so a full pass
        /// costs O(m + p) reads of the base (plus its member scans), not a search per edge.
        @frozen
        public struct Iterator: IteratorProtocol {
            @usableFromInline internal let _view: DirectedIncidenceGraphView
            @usableFromInline internal var _q: Int
            @usableFromInline internal var _h: Int
            @usableFromInline internal var _onTargets: Bool
            @usableFromInline internal var _members: Base.MemberIndices.Iterator?

            @inlinable
            internal init(_view: DirectedIncidenceGraphView) {
                self._view = _view
                _q = 0
                _h = -1
                _onTargets = false
                _members = nil
            }

            @inlinable
            public mutating func next() -> DirectedEdge<Int>? {
                if !_onTargets, _q == _view._sourceCount {
                    _onTargets = true
                    _q = 0
                    _h = -1
                    _members = nil
                }
                guard _q < (_onTargets ? _view._targetCount : _view._sourceCount) else { return nil }
                defer { _q &+= 1 }
                let i: Int, h: Int
                if _view._hasPlanes {
                    (i, h) = _view._incidence(_q, targets: _onTargets)
                } else {
                    let offsets = _onTargets ? _view._targetOffsets : _view._sourceOffsets
                    while _h < 0 || _q >= offsets[_h &+ 1] {
                        _h &+= 1
                        _members = nil
                    }
                    if _members == nil {
                        let position = _view._positionOfIndex(_h)
                        _members = (_onTargets ? _view.base.targetIndices(ofHyperedgeAt: position) : _view.base.sourceIndices(ofHyperedgeAt: position)).makeIterator()
                    }
                    guard let member = _members!.next() else {
                        preconditionFailure("The hypergraph changed size since the view was made")
                    }
                    (i, h) = (member, _h)
                }
                return _onTargets ? DirectedEdge(from: _view._n &+ h, to: i) : DirectedEdge(from: i, to: _view._n &+ h)
            }
        }

        @inlinable
        public func makeIterator() -> Iterator { Iterator(_view: _view) }
    }

    /// The successors or predecessors of one vertex of the view: a vertex's out- or
    /// in-hyperedge indices shifted by n, or a hyperedge's target or source indices, read from
    /// the base without boxing.
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

    /// The position of the hyperedge whose view vertex is `x`.
    @inlinable
    internal func _position(_ x: Int) -> Base.Hyperedges.Index {
        _positionOfIndex(x &- _n)
    }

    /// The position of hyperedge index `h`.
    @inlinable
    internal func _positionOfIndex(_ h: Int) -> Base.Hyperedges.Index {
        // On the incidence list (`_hasPlanes`) the positions are the indices, `Int`s.
        _hasPlanes ? unsafeBitCast(h, to: Base.Hyperedges.Index.self) : _positions[h]
    }

    /// The hyperedge index holding incidence `q` of one side: the last hyperedge whose first
    /// number is at most `q`. O(log m).
    @inlinable
    internal func _hyperedge(ofIncidence q: Int, offsets: ContiguousArray<Int>) -> Int {
        var low = 0, high = _m
        while high &- low > 1 {
            let middle = low &+ (high &- low) / 2
            if offsets[middle] <= q { low = middle } else { high = middle }
        }
        return low
    }

    /// The vertex index and hyperedge index of incidence `q` of one side.
    @inlinable
    internal func _incidence(_ q: Int, targets: Bool) -> (vertexIndex: Int, hyperedgeIndex: Int) {
        if _hasPlanes {
            if targets { return (_targetPlane.members[q], _targetPlane.hyperedgeOfIncidence[q]) }
            return (_sourcePlane.members[q], _sourcePlane.hyperedgeOfIncidence[q])
        }
        let h = _hyperedge(ofIncidence: q, offsets: targets ? _targetOffsets : _sourceOffsets)
        let rank = q &- (targets ? _targetOffsets[h] : _sourceOffsets[h])
        return (base._memberIndex(atRank: rank, inHyperedgeAt: _positionOfIndex(h), targets: targets), h)
    }

    /// The incidence numbers of vertex index `i` on one side: its place in each of its
    /// hyperedges' side (`_memberRank`), after that side's first number: O(d·⌈n/64⌉) on
    /// `OrientedIncidenceMatrix`, O(Σ k) on a base with the default rank.
    @inlinable
    internal func _computedIncidences(ofIndex i: Int, targets: Bool) -> [Int] {
        var numbers: [Int] = []
        numbers.reserveCapacity(targets ? base.inDegree(ofIndex: i) : base.outDegree(ofIndex: i))
        for h in targets ? base.inHyperedgeIndices(ofIndex: i) : base.outHyperedgeIndices(ofIndex: i) {
            let rank = base._memberRank(ofIndex: i, inHyperedgeAt: _positionOfIndex(h), targets: targets)
            numbers.append((targets ? _targetOffsets[h] : _sourceOffsets[h]) &+ rank)
        }
        return numbers
    }

    /// The vertex's incidence numbers on one side, stored or computed.
    @inlinable
    internal func _incidences(ofIndex i: Int, targets: Bool) -> ArraySlice<Int> {
        if _hasPlanes { return targets ? _targetPlane.row(i) : _sourcePlane.row(i) }
        return _computedIncidences(ofIndex: i, targets: targets)[...]
    }

    @inlinable
    internal func _endpoints(ofEdgeAt position: Int) -> (source: Int, target: Int) {
        precondition(position >= 0 && position < _sourceCount &+ _targetCount, "Edge position \(position) is out of range 0..<\(_sourceCount &+ _targetCount)")
        if position < _sourceCount {
            let (i, h) = _incidence(position, targets: false)
            return (i, _n &+ h)
        }
        let (j, h) = _incidence(position &- _sourceCount, targets: true)
        return (_n &+ h, j)
    }

    /// `0 ..< n + m`. O(1).
    @inlinable
    public var vertices: Range<Int> { 0 ..< _n &+ _m }

    /// Every incidence as an arc. O(1).
    @inlinable
    public var edges: Edges { Edges(_view: self) }

    @inlinable
    public var vertexCount: Int { _n &+ _m }

    @inlinable
    public var edgeCount: Int { _sourceCount &+ _targetCount }

    /// A vertex's out-hyperedge indices shifted by n, or a hyperedge's targets.
    @inlinable
    public func successors(of vertex: Int) -> Neighbors {
        _check(vertex)
        if vertex < _n { return Neighbors(hyperedges: base.outHyperedgeIndices(ofIndex: vertex), shift: _n) }
        return Neighbors(members: base.targetIndices(ofHyperedgeAt: _position(vertex)))
    }

    /// A vertex's in-hyperedge indices shifted by n, or a hyperedge's sources.
    @inlinable
    public func predecessors(of vertex: Int) -> Neighbors {
        _check(vertex)
        if vertex < _n { return Neighbors(hyperedges: base.inHyperedgeIndices(ofIndex: vertex), shift: _n) }
        return Neighbors(members: base.sourceIndices(ofHyperedgeAt: _position(vertex)))
    }

    /// A vertex's source incidences, or `P_s` plus a hyperedge's target incidences.
    @inlinable
    public func outEdges(of vertex: Int) -> OutEdges {
        _check(vertex)
        if vertex < _n { return OutEdges(row: _incidences(ofIndex: vertex, targets: false), shift: 0) }
        let h = vertex &- _n
        return OutEdges(range: _sourceCount &+ _targetOffsets[h] ..< _sourceCount &+ _targetOffsets[h &+ 1])
    }

    /// `P_s` plus a vertex's target incidences, or a hyperedge's source incidences.
    @inlinable
    public func inEdges(of vertex: Int) -> OutEdges {
        _check(vertex)
        if vertex < _n { return OutEdges(row: _incidences(ofIndex: vertex, targets: true), shift: _sourceCount) }
        let h = vertex &- _n
        return OutEdges(range: _sourceOffsets[h] ..< _sourceOffsets[h &+ 1])
    }

    @inlinable
    public func source(ofEdgeAt position: Int) -> Int { sourceIndex(ofEdgeAt: position) }

    @inlinable
    public func target(ofEdgeAt position: Int) -> Int { targetIndex(ofEdgeAt: position) }

    /// The base's out-degree of a vertex, or the number of targets of a hyperedge.
    @inlinable
    public func outDegree(of vertex: Int) -> Int {
        _check(vertex)
        if vertex < _n { return base.outDegree(ofIndex: vertex) }
        let h = vertex &- _n
        return _targetOffsets[h &+ 1] &- _targetOffsets[h]
    }

    /// The base's in-degree of a vertex, or the number of sources of a hyperedge.
    @inlinable
    public func inDegree(of vertex: Int) -> Int {
        _check(vertex)
        if vertex < _n { return base.inDegree(ofIndex: vertex) }
        let h = vertex &- _n
        return _sourceOffsets[h &+ 1] &- _sourceOffsets[h]
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
            for p in base.outHyperedgeIndices(ofIndex: edge.source) where p == edge.target &- _n { return true }
        } else if edge.source >= _n, edge.target < _n {
            for p in base.inHyperedgeIndices(ofIndex: edge.target) where p == edge.source &- _n { return true }
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
    public func outEdges(ofIndex index: Int) -> OutEdges { outEdges(of: index) }

    @inlinable
    public func inEdges(ofIndex index: Int) -> OutEdges { inEdges(of: index) }

    @inlinable
    public func outDegree(ofIndex index: Int) -> Int { outDegree(of: index) }

    @inlinable
    public func inDegree(ofIndex index: Int) -> Int { inDegree(of: index) }

    /// The arc's tail, read from the incidence, without hashing.
    @inlinable
    public func sourceIndex(ofEdgeAt position: Int) -> Int { _endpoints(ofEdgeAt: position).source }

    /// The arc's head, read from the incidence, without hashing.
    @inlinable
    public func targetIndex(ofEdgeAt position: Int) -> Int { _endpoints(ofEdgeAt: position).target }

    @inlinable
    public var edgeIndexBound: Int? { _sourceCount &+ _targetCount }

    @inlinable
    public func edgeIndex(of position: Int) -> Int {
        precondition(position >= 0 && position < _sourceCount &+ _targetCount, "Edge position \(position) is out of range")
        return position
    }
}

extension DirectedIncidenceGraphView: Sendable where Base: Sendable, Base.Hyperedges.Index: Sendable {}
extension DirectedIncidenceGraphView.Edges: Sendable where Base: Sendable, Base.Hyperedges.Index: Sendable {}
extension DirectedIncidenceGraphView.Neighbors: Sendable where Base.IncidentHyperedgeIndices: Sendable, Base.MemberIndices: Sendable {}
