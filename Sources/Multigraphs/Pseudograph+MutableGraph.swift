import AdjacencyListModule
import GraphProtocols

// MARK: - MutableGraph

extension Pseudograph: MutableGraph {
    /// The slot of `vertex`, or `nil`. One hash.
    @inlinable public func _key(of vertex: Vertex) -> Int? { _slots[vertex] }

    /// The vertex in slot `key`.
    @inlinable public func _vertex(atKey key: Int) -> Vertex { _vertices[key] }

    @inlinable public mutating func _insertVertex(_ vertex: Vertex) -> Int { _appendSlot(for: vertex) }

    /// Always a new copy, at position `edgeCount`, stored `u` first.
    @inlinable
    public mutating func _insertEdge(fromKey u: Int, toKey v: Int) -> Int {
        _insertEdge(slots: u, v)
    }
}

// MARK: - Bulk construction

extension _ParallelClasses {
    /// The classes of `count` edges at positions `0..<count`, keyed by `key(position)`, as
    /// appending them in order would leave them.
    @inlinable
    init(appending count: Int, key: (Int) -> _SlotPair) {
        self.init()
        links.reserveCapacity(count)
        classes.reserveCapacity(count)
        for position in 0 ..< count { append(position, key: key(position)) }
    }
}

extension DirectedPseudograph {
    /// See `MutableDirectedGraph._built`: the rows by counting sort, then one parallel-class entry
    /// per edge. O(n + m) expected.
    @inlinable
    public static func _built(
        vertices: ContiguousArray<Vertex>, sourceKeys: [Int], targetKeys: [Int], reportingPositions: Bool, _: _ConstructionToken
    ) -> (graph: Self, positions: [Int]) {
        precondition(sourceKeys.count == targetKeys.count, "Unpaired keys")
        let n = vertices.count
        precondition(sourceKeys.allSatisfy { UInt(bitPattern: $0) < UInt(n) } && targetKeys.allSatisfy { UInt(bitPattern: $0) < UInt(n) },
                     "Key out of range")
        let rows = _ArcRows(vertexCount: n, sources: sourceKeys, targets: targetKeys)
        var graph = Self()
        graph._slots = _vertexSlots(of: vertices)
        graph._vertices = vertices
        graph._out = rows.out
        graph._outEdges = rows.outEdges
        graph._in = rows.in
        graph._inEdges = rows.inEdges
        graph._records = rows.records
        graph._parallel = _ParallelClasses(appending: sourceKeys.count) { _SlotPair(sourceKeys[$0], targetKeys[$0]) }
        return (graph, reportingPositions ? Array(sourceKeys.indices) : [])
    }
}

extension Pseudograph {
    /// See `MutableGraph._built`: the rows by counting sort, then one parallel-class entry per
    /// edge. O(n + m) expected.
    @inlinable
    public static func _built(
        vertices: ContiguousArray<Vertex>, uKeys: [Int], vKeys: [Int], reportingPositions: Bool, _: _ConstructionToken
    ) -> (graph: Self, positions: [Int]) {
        precondition(uKeys.count == vKeys.count, "Unpaired keys")
        let n = vertices.count
        precondition(uKeys.allSatisfy { UInt(bitPattern: $0) < UInt(n) } && vKeys.allSatisfy { UInt(bitPattern: $0) < UInt(n) },
                     "Key out of range")
        let rows = _EdgeRows(vertexCount: n, us: uKeys, vs: vKeys)
        var graph = Self()
        graph._slots = _vertexSlots(of: vertices)
        graph._vertices = vertices
        graph._neighbors = rows.neighbors
        graph._incident = rows.incident
        graph._records = rows.records
        graph._parallel = _ParallelClasses(appending: uKeys.count) {
            let u = uKeys[$0], v = vKeys[$0]
            return u <= v ? _SlotPair(u, v) : _SlotPair(v, u)
        }
        return (graph, reportingPositions ? Array(uKeys.indices) : [])
    }
}
