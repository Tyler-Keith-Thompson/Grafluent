import GraphProtocols

// MARK: - MutableGraph

extension UndirectedAdjacencyList: MutableGraph {
    /// The slot of `vertex`, or `nil`. One hash.
    @inlinable public func _key(of vertex: Vertex) -> Int? { _slots[vertex] }

    /// The vertex in slot `key`.
    @inlinable public func _vertex(atKey key: Int) -> Vertex { _vertices[key] }

    @inlinable public mutating func _insertVertex(_ vertex: Vertex) -> Int { _appendSlot(for: vertex) }

    /// The new edge's position, which is `edgeCount` before the call. When an edge already joins the
    /// two slots, in either orientation, nothing is inserted and its position is returned.
    @inlinable
    public mutating func _insertEdge(fromKey u: Int, toKey v: Int) -> Int {
        if let position = _positions[u <= v ? _SlotPair(u, v) : _SlotPair(v, u)] { return position }
        let position = _records.count
        _insertEdge(slots: u, v)
        return position
    }
}
