import GraphProtocols

extension DirectedAcyclicGraph {
    /// Inserts `vertex` with no edges, if it is not already a vertex, and places it last in the
    /// order. O(1) amortized, plus the base's insertion.
    ///
    /// - Returns: Whether it was inserted, and the vertex now in the graph that is equal to
    ///   `vertex` (the existing one, if there was one).
    @inlinable
    @discardableResult
    public mutating func insert(_ vertex: Vertex) -> (inserted: Bool, memberAfterInsert: Vertex) {
        if let key = _base._key(of: vertex) { return (false, _base._vertex(atKey: key)) }
        _ = _appendVertex(vertex)
        return (true, vertex)
    }

    /// Inserts `edge`, unless it would close a cycle, inserting either endpoint that is not already
    /// a vertex (source first, each placed last). A self-loop closes a cycle and is rejected
    /// before anything is inserted.
    ///
    /// When the source is already placed before the target, the cost is two array reads plus the
    /// base's insertion. Otherwise Pearce and Kelly's reordering runs, O(‖δ‖ + δ log δ) for the δ
    /// vertices it visits between the endpoints' places; see the type's documentation.
    ///
    /// - Returns: The edge's position: a new one, or on `AdjacencyList`, which is simple, the
    ///   existing edge's. `nil` when the edge would close a cycle; then nothing changes, and
    ///   `bidirectionalShortestPath(from: edge.target, to: edge.source)` (Traversal) is a path
    ///   the edge would close.
    @inlinable
    @discardableResult
    public mutating func insert(edge: DirectedEdge<Vertex>) -> Edges.Index? {
        if edge.source == edge.target { return nil }
        let source = _base._key(of: edge.source) ?? _appendVertex(edge.source)
        let target = _base._key(of: edge.target) ?? _appendVertex(edge.target)
        return _insertEdge(source, target)
    }

    /// Inserts `edge` only when both endpoints are already vertices and the edge would not close a
    /// cycle; otherwise returns `nil` and changes nothing. The `safe:` spelling of README Principle
    /// 6: JGraphT's `addEdge` requires the endpoints (it throws `IllegalArgumentException`), as
    /// petgraph's `Acyclic::try_add_edge` does (`AcyclicEdgeError::InvalidEdge`). Costs as
    /// `insert(edge:)`.
    ///
    /// - Returns: The edge's position, as `insert(edge:)`'s, or `nil` when an endpoint is missing
    ///   or the edge would close a cycle (a self-loop included).
    @inlinable
    @discardableResult
    public mutating func insert(safe edge: DirectedEdge<Vertex>) -> Edges.Index? {
        guard let source = _base._key(of: edge.source), let target = _base._key(of: edge.target), source != target else { return nil }
        return _insertEdge(source, target)
    }

    /// Appends `vertex`, which is not a vertex, to the base and to the order.
    @inlinable
    internal mutating func _appendVertex(_ vertex: Vertex) -> Int {
        let key = _base._insertVertex(vertex)
        _table.insert(key, label: _nextLabel)
        _nextLabel &+= 1
        _order.append(key)
        return key
    }

    /// Inserts the edge between two distinct keys, reordering first when it goes backward.
    @inlinable
    @inline(__always)
    internal mutating func _insertEdge(_ source: Int, _ target: Int) -> Edges.Index? {
        if _table.label(source) > _table.label(target) {
            guard _reorder(source: source, target: target) else { return nil }
        }
        return _base._insertEdge(fromKey: source, toKey: target)
    }

    /// Pearce and Kelly's reordering for an edge `source → target` with `source` placed after
    /// `target`: true once the order fits the edge, false, with the order unchanged, when `target`
    /// reaches `source`. Places are compared by label. One inline loop per search, on scratch kept
    /// in the value (a nested function would box the scratch it captures).
    @inlinable
    internal mutating func _reorder(source: Int, target: Int) -> Bool {
        let upper = _table.label(source), lower = _table.label(target)
        _stamp &+= 2
        let forwardMark = _stamp, backwardMark = _stamp &+ 1

        // Forward: depth-first from the target, through vertices placed before the source.
        _forward.removeAll(keepingCapacity: true)
        _stack.removeAll(keepingCapacity: true)
        _table.marks[_table.slot(target)] = forwardMark
        _forward.append(_Placed(label: lower, key: target))
        _stack.append(target)
        while let key = _stack.popLast() {
            for next in _base._successorKeys(ofKey: key) {
                if next == source { return false }
                let slot = _table.slot(next)
                let label = _table.labels[slot]
                if label < upper, _table.marks[slot] != forwardMark {
                    _table.marks[slot] = forwardMark
                    _forward.append(_Placed(label: label, key: next))
                    _stack.append(next)
                }
            }
        }

        // Backward: from the source, through vertices placed after the target. No vertex is in
        // both sets: one would make the target reach the source.
        _backward.removeAll(keepingCapacity: true)
        _table.marks[_table.slot(source)] = backwardMark
        _backward.append(_Placed(label: upper, key: source))
        _stack.append(source)
        while let key = _stack.popLast() {
            for previous in _base._predecessorKeys(ofKey: key) {
                let slot = _table.slot(previous)
                let label = _table.labels[slot]
                if label > lower, _table.marks[slot] != backwardMark {
                    _table.marks[slot] = backwardMark
                    _backward.append(_Placed(label: label, key: previous))
                    _stack.append(previous)
                }
            }
        }

        // Each set in its old order; the pooled labels, merged in increasing order, go to the
        // backward set and then the forward set, and the keys to those labels' places.
        _forward.sort { $0.label < $1.label }
        _backward.sort { $0.label < $1.label }
        _labels.removeAll(keepingCapacity: true)
        _places.removeAll(keepingCapacity: true)
        var f = 0, b = 0
        while f < _forward.count || b < _backward.count {
            let moved: _Placed
            if b == _backward.count || (f < _forward.count && _forward[f].label < _backward[b].label) {
                moved = _forward[f]
                f &+= 1
            } else {
                moved = _backward[b]
                b &+= 1
            }
            _labels.append(moved.label)
            _places.append(_table.position(ofLabel: moved.label, key: moved.key, in: _order))
        }
        var i = 0
        for moved in _backward {
            _table.setLabel(moved.key, _labels[i])
            _order[_places[i]] = moved.key
            i &+= 1
        }
        for moved in _forward {
            _table.setLabel(moved.key, _labels[i])
            _order[_places[i]] = moved.key
            i &+= 1
        }
        return true
    }

    /// Removes `vertex` and every edge at it, closing its gap in the order: the vertices after it
    /// move up one place, in one memmove, and keep their labels (see the type's documentation).
    /// On a base that fills the hole by moving its last vertex in (`AdjacencyList`,
    /// `DirectedPseudograph`), the moved vertex keeps its place. O(n − place) for the memmove,
    /// O(log n) to find the place, amortized O(1) for renumbering, plus the base's removal.
    ///
    /// - Returns: The removed vertex instance, or `nil` if `vertex` was not a vertex.
    @inlinable
    @discardableResult
    public mutating func remove(_ vertex: Vertex) -> Vertex? {
        guard let key = _base._key(of: vertex) else { return nil }
        let removed = _base._vertex(atKey: key)
        _order.remove(at: _position(ofKey: key))
        _table.remove(key)
        if let moved = _base._removeVertex(atKey: key) {
            let label = _table.label(moved)
            let place = _position(ofKey: moved)
            _table.remove(moved)
            _table.insert(key, label: label)
            _order[place] = key
        }
        // Renumbered once the labels span twice the vertices: after at least as many removals as
        // vertices remain, so O(1) amortized.
        if _nextLabel > _order.count &* 2 &+ 1024 { _renumber() }
        return removed
    }

    /// Removes one copy of `edge`, the newest on a base with parallel edges (NetworkX's
    /// `remove_edge(u, v)`), as the base removes it. The order is kept. The base's cost.
    ///
    /// - Returns: The removed edge, or `nil` if no copy of `edge` was an edge.
    @inlinable
    @discardableResult
    public mutating func remove(edge: DirectedEdge<Vertex>) -> DirectedEdge<Vertex>? {
        _base.remove(edge: edge)
    }

    /// Removes the edge at `position`, as the base removes it: the dense bases move their last
    /// edge into the position, and `StableDirectedGraph` leaves a hole. The order is kept. The
    /// base's cost, O(1) or O(1) amortized.
    ///
    /// - Returns: The removed edge.
    /// - Precondition: `position` is the position of an edge.
    @inlinable
    @discardableResult
    public mutating func remove(edgeAt position: Edges.Index) -> DirectedEdge<Vertex> {
        _base._removeEdge(at: position)
    }

    /// Removes every vertex and edge.
    @inlinable
    public mutating func removeAll(keepingCapacity: Bool = false) {
        _base.removeAll(keepingCapacity: keepingCapacity)
        _order.removeAll(keepingCapacity: keepingCapacity)
        _table.removeAll(keepingCapacity: keepingCapacity)
        _nextLabel = 0
    }

    /// Removes every edge, keeping every vertex and the order (any order fits an edgeless graph).
    @inlinable
    public mutating func removeAllEdges(keepingCapacity: Bool = false) {
        _base.removeAllEdges(keepingCapacity: keepingCapacity)
    }

    /// Reserves space for at least `vertexCount` vertices and `edgeCount` edges.
    @inlinable
    public mutating func reserveCapacity(vertexCount: Int, edgeCount: Int) {
        _base.reserveCapacity(vertexCount: vertexCount, edgeCount: edgeCount)
        _order.reserveCapacity(vertexCount)
    }
}
