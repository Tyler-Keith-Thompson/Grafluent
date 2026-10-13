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
    /// The classes of the edges at positions `0..<firsts.count`, `(firsts[p], seconds[p])`
    /// (unordered when `undirected`), as appending them in order would leave them: copies found by
    /// `_firstCopies` (a counting sort, no hashing), then one bulk insertion per distinct pair.
    @inlinable
    init(firsts: [Int], seconds: [Int], vertexCount n: Int, undirected: Bool) {
        self.init()
        let m = firsts.count
        let group = _firstCopies(firsts, seconds, vertexCount: n, undirected: undirected)
        links = ContiguousArray(repeating: _ParallelLinks(previous: -1, next: -1), count: m)
        var pairs: [_SlotPair] = []
        var values: [Int] = []
        pairs.reserveCapacity(m)
        values.reserveCapacity(m)
        var slot = [Int](repeating: 0, count: m)
        for p in 0 ..< m {
            let g = group[p]
            if g == p {
                slot[p] = values.count
                let a = firsts[p], b = seconds[p]
                pairs.append(undirected && b < a ? _SlotPair(b, a) : _SlotPair(a, b))
                values.append(p)
            } else {
                Self._append(p, to: &values[slot[g]], links: &links, multi: &multi, freeMulti: &freeMulti)
            }
        }
        classes._insertDistinct(count: pairs.count) { (pairs[$0], values[$0]) }
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
        graph._parallel = _ParallelClasses(firsts: sourceKeys, seconds: targetKeys, vertexCount: n, undirected: false)
        graph._generation.stamp()
        return (graph, reportingPositions ? Array(sourceKeys.indices) : [])
    }
}

extension Pseudograph {
    /// See `MutableGraph._built`: the rows by counting sort, then one parallel-class entry per
    /// edge class. O(n + m) expected.
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
        graph._parallel = _ParallelClasses(firsts: uKeys, seconds: vKeys, vertexCount: n, undirected: true)
        graph._generation.stamp()
        return (graph, reportingPositions ? Array(uKeys.indices) : [])
    }
}
