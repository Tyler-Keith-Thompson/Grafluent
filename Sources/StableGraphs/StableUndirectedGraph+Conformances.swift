import GraphProtocols

// MARK: - Graph

extension StableUndirectedGraph: Graph {
    /// The current generation (see `GraphGeneration`): every insertion and removal, and both
    /// resets, start a new one. O(1).
    @inlinable
    public var generation: GraphGeneration { _generation.generation }

    /// While no vertex has been removed since the last reset: `vertexCount`, and each vertex's
    /// position is its index. While vertex holes exist: `nil`, because indices must be dense; the
    /// positions are then reported by `SparselyIndexedGraph`.
    @inlinable
    public var vertexIndexBound: Int? { _vertexCount == _vertexEnd ? _vertexCount : nil }

    /// The position of `vertex`. O(1) expected.
    ///
    /// - Precondition: `vertexIndexBound` is not `nil`, and `vertex` is a vertex of the graph.
    @inlinable
    public func vertexIndex(of vertex: Vertex) -> Int {
        precondition(_vertexCount == _vertexEnd, "The graph has vertex holes, so no vertex indices; check vertexIndexBound first")
        return _slot(of: vertex)
    }

    /// The vertex at index `index`. O(1).
    ///
    /// - Precondition: `vertexIndexBound` is not `nil`, and `index` is in `0..<vertexIndexBound`.
    @inlinable
    public func vertex(atIndex index: Int) -> Vertex {
        _checkIndex(index)
        return _vertex(atSlot: index)
    }

    /// The indices of the neighbors of the vertex at `index`: the stored row. O(1).
    ///
    /// - Precondition: `vertexIndexBound` is not `nil`, and `index` is in `0..<vertexIndexBound`.
    @inlinable
    public func neighborIndices(ofIndex index: Int) -> NeighborIndices {
        _checkIndex(index)
        // Without holes, every slot below the end is live, so its page and row exist.
        return _ends(index)
    }

    /// Calls `body` with each of `neighborIndices(ofIndex: index)`, in order, reading the stored
    /// row in place. O(degree).
    ///
    /// - Precondition: `vertexIndexBound` is not `nil`, and `index` is in `0..<vertexIndexBound`.
    @inlinable
    public func _forEachNeighborIndex(ofIndex index: Int, _ body: (Int) -> Void) {
        _checkIndex(index)
        let k = _vk(index), l = index & _PositionPage.mask
        _rowPages.withUnsafeBufferPointer { pages in
            pages[k].rows.withUnsafeBufferPointer { rows in
                pages[k].ends.withUnsafeBufferPointer { ends in
                    let start = rows[l].start
                    for j in start ..< start &+ rows[l].count where ends[j] >= 0 { body(ends[j]) }
                }
            }
        }
    }

    /// `incidentEdges(of: vertex(atIndex: index))`, without the hash. O(1).
    ///
    /// - Precondition: `vertexIndexBound` is not `nil`, and `index` is in `0..<vertexIndexBound`.
    @inlinable
    public func incidentEdges(ofIndex index: Int) -> IncidentEdges {
        _checkIndex(index)
        return IncidentEdges(row: _row(index))
    }

    /// The edge indices of `incidentEdges(ofIndex: index)`, which are its positions while the
    /// graph has edge indices. O(1).
    ///
    /// - Precondition: `vertexIndexBound` and `edgeIndexBound` are not `nil`, and `index` is in
    ///   `0..<vertexIndexBound`.
    @inlinable
    public func incidentEdgeIndices(ofIndex index: Int) -> IncidentEdges {
        precondition(_edgeCount == _edgeEnd, "The graph has edge holes, so no edge indices; check edgeIndexBound first")
        _checkIndex(index)
        return IncidentEdges(row: _row(index))
    }

    /// The stored degree of the vertex at `index`, without the hash. O(1).
    ///
    /// - Precondition: `vertexIndexBound` is not `nil`, and `index` is in `0..<vertexIndexBound`.
    @inlinable
    public func degree(ofIndex index: Int) -> Int {
        _checkIndex(index)
        return _degree(index)
    }

    /// The indices of the edge's first and second ends, read from its record without a hash.
    /// O(1).
    ///
    /// - Precondition: `vertexIndexBound` is not `nil`, and an edge is at `position`.
    @inlinable
    public func endpointIndices(ofEdgeAt position: Int) -> (u: Int, v: Int) {
        precondition(_vertexCount == _vertexEnd, "The graph has vertex holes, so no vertex indices; check vertexIndexBound first")
        let record = _liveRecord(position)
        return (record.source, record.target)
    }

    /// While no edge has been removed since the last reset: `edgeCount`, and each position is its
    /// index. While edge holes exist: `nil`.
    @inlinable
    public var edgeIndexBound: Int? { _edgeCount == _edgeEnd ? _edgeCount : nil }

    /// The position itself. O(1).
    ///
    /// - Precondition: `edgeIndexBound` is not `nil`, and `position` is in `0..<edgeIndexBound`.
    @inlinable
    public func edgeIndex(of position: Int) -> Int {
        precondition(_edgeCount == _edgeEnd, "The graph has edge holes, so no edge indices; check edgeIndexBound first")
        precondition(UInt(bitPattern: position) < UInt(bitPattern: _edgeEnd), "Edge position out of range")
        return position
    }

    /// While the graph has vertex and edge indices: its rows copied once into flat storage, in
    /// O(n + m), the entries slots and positions, which are the indices. `nil` while holes exist,
    /// without calling `body`.
    @inlinable
    public func _withIncidentIndexRows<Result>(
        _ body: (
            _ neighbors: UnsafeBufferPointer<Int>, _ neighborRows: UnsafeBufferPointer<Int>,
            _ edges: UnsafeBufferPointer<Int>, _ edgeRows: UnsafeBufferPointer<Int>
        ) -> Result
    ) -> Result? {
        guard _vertexCount == _vertexEnd, _edgeCount == _edgeEnd else { return nil }
        return _numberedIncidenceRows()._withIncidenceTables(body)
    }

    @inlinable
    @inline(__always)
    internal func _checkIndex(_ index: Int) {
        precondition(_vertexCount == _vertexEnd, "The graph has vertex holes, so no vertex indices; check vertexIndexBound first")
        precondition(UInt(bitPattern: index) < UInt(bitPattern: _vertexEnd), "Vertex index out of range")
    }
}

// MARK: - SparselyIndexedGraph

extension StableUndirectedGraph: SparselyIndexedGraph {
    /// One more than the highest vertex position ever handed out: `vertices.endIndex`. O(1).
    @inlinable
    public var vertexPositionBound: Int { _vertexEnd }

    /// One more than the highest edge position ever handed out: `edges.endIndex`. O(1).
    @inlinable
    public var edgePositionBound: Int { _edgeEnd }

    /// The position of `vertex`. O(1) expected.
    ///
    /// - Precondition: `vertex` is a vertex of the graph.
    @inlinable
    public func vertexPosition(of vertex: Vertex) -> Int { _slot(of: vertex) }

    /// The vertex at `position`. O(1).
    ///
    /// - Precondition: `position` is a live vertex position.
    @inlinable
    public func vertex(atPosition position: Int) -> Vertex { vertices[position] }

    /// `vertices.indices.contains(position)`. O(1).
    @inlinable
    public func containsVertex(atPosition position: Int) -> Bool {
        guard position >= 0, position < _vertexEnd else { return false }
        let k = _vk(position), l = position & _PositionPage.mask
        return _rowPages.withUnsafeBufferPointer { pages in k >= 0 && k < pages.count && l < pages[k].rows.count && pages[k].rows[l].dead >= 0 }
    }

    /// `edges.indices.contains(position)`. O(1).
    @inlinable
    public func containsEdge(atPosition position: Int) -> Bool {
        _isLiveEdge(position, _edgePages, base: _edgeBase, end: _edgeEnd)
    }

    /// Numbers the live vertices and edges page by page and copies each vertex's row in that
    /// numbering: O(`vertexCount` + `edgeCount` + pages), with no hashing. Liveness is read from
    /// the rows' dead counts and the edge records, not from a `Vertex?`: this runs unspecialized,
    /// through the existential.
    public func _numberedIncidenceRows() -> _NumberedRows {
        let size = _PositionPage.size
        let tableCount = _rowPages.count, base = _vertexBase
        let n = _vertexCount, m = _edgeCount
        // Vertex numbers, one block of `size` per page with a live vertex.
        var pageOffsets = [Int](repeating: -1, count: tableCount)
        var blocks = 0
        for k in 0 ..< tableCount where !_rowPages[k].isFreed {
            pageOffsets[k] = blocks &* size
            blocks &+= 1
        }
        var numbers = [Int](repeating: -1, count: blocks &* size)
        numbers.withUnsafeMutableBufferPointer { numbers in
            var v = 0
            for k in 0 ..< tableCount where pageOffsets[k] >= 0 {
                let offset = pageOffsets[k]
                _rowPages[k].rows.withUnsafeBufferPointer { rows in
                    for l in 0 ..< rows.count where rows[l].dead >= 0 {
                        numbers[offset &+ l] = v
                        v &+= 1
                    }
                }
            }
        }
        // Edge numbers, only while edge holes exist: otherwise a position is its number.
        let denseEdges = _edgeCount == _edgeEnd
        var edgePageOffsets: [Int] = []
        var edgeNumbers: [Int] = []
        if !denseEdges {
            edgePageOffsets = [Int](repeating: -1, count: _edgePages.count)
            var edgeBlocks = 0
            for k in _edgePages.indices where !_edgePages[k].records.isEmpty {
                edgePageOffsets[k] = edgeBlocks &* size
                edgeBlocks &+= 1
            }
            edgeNumbers = [Int](repeating: -1, count: edgeBlocks &* size)
            edgeNumbers.withUnsafeMutableBufferPointer { edgeNumbers in
                var e = 0
                for k in _edgePages.indices where edgePageOffsets[k] >= 0 {
                    let offset = edgePageOffsets[k]
                    _edgePages[k].records.withUnsafeBufferPointer { records in
                        for l in 0 ..< records.count where records[l].source >= 0 {
                            edgeNumbers[offset &+ l] = e
                            e &+= 1
                        }
                    }
                }
            }
        }
        let numberOf = _NumberLookup(numbers: numbers, pageOffsets: pageOffsets, base: base)
        let edgeNumberOf = _NumberLookup(numbers: edgeNumbers, pageOffsets: edgePageOffsets, base: _edgeBase)
        var offsets = [Int](repeating: 0, count: n &+ 1)
        var neighbors = [Int](repeating: 0, count: 2 &* m)
        var edges = [Int](repeating: 0, count: 2 &* m)
        neighbors.withUnsafeMutableBufferPointer { neighbors in
            edges.withUnsafeMutableBufferPointer { edges in
                offsets.withUnsafeMutableBufferPointer { offsets in
                    var i = 0, v = 0
                    for k in 0 ..< tableCount where pageOffsets[k] >= 0 {
                        _rowPages[k].rows.withUnsafeBufferPointer { rows in
                            _rowPages[k].ends.withUnsafeBufferPointer { ends in
                                _rowPages[k].positions.withUnsafeBufferPointer { positions in
                                    for l in 0 ..< rows.count where rows[l].dead >= 0 {
                                        let start = rows[l].start
                                        for j in start ..< start &+ rows[l].count where ends[j] >= 0 {
                                            neighbors[i] = numberOf[ends[j]]
                                            edges[i] = denseEdges ? positions[j] : edgeNumberOf[positions[j]]
                                            i &+= 1
                                        }
                                        v &+= 1
                                        offsets[v] = i
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        let positionNumbers = _PositionNumbers(firstPage: base, pageOffsets: pageOffsets, numbers: numbers)
        return _NumberedRows(numbers: positionNumbers, offsets: offsets, neighbors: neighbors, edges: edges)
    }
}

/// A paged number lookup over arrays known to cover every position looked up.
@usableFromInline
internal struct _NumberLookup {
    let numbers: [Int]
    let pageOffsets: [Int]
    let base: Int

    @inline(__always)
    subscript(position: Int) -> Int {
        numbers.withUnsafeBufferPointer { numbers in
            pageOffsets.withUnsafeBufferPointer { pageOffsets in
                numbers[pageOffsets[(position &>> _PositionPage.shift) &- base] &+ (position & _PositionPage.mask)]
            }
        }
    }
}

// MARK: - MutableGraph

extension StableUndirectedGraph: MutableGraph {
    /// The position of `vertex`, or `nil`. One hash.
    @inlinable public func _key(of vertex: Vertex) -> Int? { _slots[vertex] }

    /// The vertex at position `key`; traps unless a vertex is there.
    @inlinable
    public func _vertex(atKey key: Int) -> Vertex {
        precondition(containsVertex(atPosition: key), "No vertex at position \(key)")
        return _vertex(atSlot: key)
    }

    @inlinable public mutating func _insertVertex(_ vertex: Vertex) -> Int { _appendSlot(for: vertex) }

    /// Inserts an edge stored from the vertex at position `u` to the one at `v`, and returns its
    /// position: always a new copy, at `edges.endIndex`.
    @inlinable
    public mutating func _insertEdge(fromKey u: Int, toKey v: Int) -> Int { _insertEdge(slots: u, v) }

    /// One pass for the vertices, then the rows laid out at once.
    @inlinable
    public static func _built(
        vertices: ContiguousArray<Vertex>, uKeys: [Int], vKeys: [Int], reportingPositions: Bool, _: _ConstructionToken
    ) -> (graph: Self, positions: [Int]) {
        precondition(uKeys.count == vKeys.count, "Unpaired keys")
        var graph = Self()
        graph.reserveCapacity(vertexCount: vertices.count, edgeCount: uKeys.count)
        for vertex in vertices { graph._appendSlot(for: vertex) }
        graph._appendEdgesToEmpty(us: uKeys, vs: vKeys)
        return (graph, reportingPositions ? Array(0 ..< uKeys.count) : [])
    }
}

// MARK: - PropertyGraph

// The maps are paged like the graph, as `StableDirectedGraph`'s: a map's page is allocated on its
// first write and freed when the graph frees the matching page of its own.

extension StableUndirectedGraph: PropertyGraph {
    public typealias EdgePosition = Int

    @inlinable public static var _vertexMapLayout: _MapLayout { .paged }
    @inlinable public static var _edgeMapLayout: _MapLayout { .paged }

    /// Attaches a map from edge positions to `Value`, with every edge's value `value`, and returns
    /// its handle. Removing an edge removes its value in every attached map, in the same mutation.
    /// Copies of the graph carry the map, copy-on-write by page. O(1). Storage is allocated a page
    /// (1024 positions) at a time as values are set.
    ///
    /// Map contents take no part in equality, hashing or `Codable`: a decoded graph has no maps.
    @inlinable
    public mutating func addEdgeMap<Value: Sendable>(default value: Value) -> EdgeMap<Value> {
        let (token, hint) = _edgeMaps.add(default: value, layout: .paged, count: 0)
        _edgeMapsRelease = _edgeMaps.releases
        return EdgeMap(_token: token, hint: hint)
    }

    /// Attaches a map from vertex positions to `Value`, with every vertex's value `value`, and
    /// returns its handle. Removing a vertex removes its value. O(1).
    @inlinable
    public mutating func addVertexMap<Value: Sendable>(default value: Value) -> VertexMap<Value> {
        let (token, hint) = _vertexMaps.add(default: value, layout: .paged, count: 0)
        return VertexMap(_token: token, hint: hint)
    }

    /// Detaches the edge map and frees its storage; the handle traps from then on (on this graph).
    ///
    /// - Precondition: `map` is attached to this graph.
    @inlinable
    public mutating func removeEdgeMap<Value>(_ map: EdgeMap<Value>) {
        _edgeMaps.remove(map._token, hint: map._hint)
        _edgeMapsRelease = _edgeMaps.releases
    }

    /// Detaches the vertex map and frees its storage.
    ///
    /// - Precondition: `map` is attached to this graph.
    @inlinable
    public mutating func removeVertexMap<Value>(_ map: VertexMap<Value>) {
        _vertexMaps.remove(map._token, hint: map._hint)
    }

    /// The value of the edge at `position` in `map`. O(1); the first value set in a page of 1024
    /// positions allocates the page.
    ///
    /// - Precondition: `map` is attached to this graph, and `position` is a live edge position.
    @inlinable
    public subscript<Value>(_ map: EdgeMap<Value>, ofEdgeAt position: Int) -> Value {
        get {
            let k = _edgeMaps.index(of: map._token, hint: map._hint)
            precondition(_isLiveEdge(position, _edgePages, base: _edgeBase, end: _edgeEnd), "No edge at position \(position): it was removed")
            return _edgeMaps.value(Value.self, at: position, in: k, layout: .paged)
        }
        set {
            let k = _edgeMaps.index(of: map._token, hint: map._hint)
            precondition(_isLiveEdge(position, _edgePages, base: _edgeBase, end: _edgeEnd), "No edge at position \(position) to hold a value")
            _edgeMaps.setValue(newValue, at: position, in: k, layout: .paged)
        }
    }

    /// The value of the vertex at `position` in `map`. O(1).
    ///
    /// - Precondition: `map` is attached to this graph, and `position` is a live vertex position.
    @inlinable
    public subscript<Value>(_ map: VertexMap<Value>, ofVertexAt position: Int) -> Value {
        get {
            let k = _vertexMaps.index(of: map._token, hint: map._hint)
            precondition(containsVertex(atPosition: position), "No vertex at position \(position): it was removed")
            return _vertexMaps.value(Value.self, at: position, in: k, layout: .paged)
        }
        set {
            let k = _vertexMaps.index(of: map._token, hint: map._hint)
            precondition(containsVertex(atPosition: position), "No vertex at position \(position) to hold a value")
            _vertexMaps.setValue(newValue, at: position, in: k, layout: .paged)
        }
    }

    /// The value of `vertex` in `map`. One hash.
    ///
    /// - Precondition: `map` is attached to this graph, and `vertex` is a vertex of it.
    @inlinable
    public subscript<Value>(_ map: VertexMap<Value>, of vertex: Vertex) -> Value {
        get {
            let k = _vertexMaps.index(of: map._token, hint: map._hint)
            return _vertexMaps.value(Value.self, at: _slot(of: vertex), in: k, layout: .paged)
        }
        set {
            let k = _vertexMaps.index(of: map._token, hint: map._hint)
            _vertexMaps.setValue(newValue, at: _slot(of: vertex), in: k, layout: .paged)
        }
    }

    /// The value of the edge at `position` in `map`, throwing instead of trapping when no edge is
    /// there. O(1).
    ///
    /// - Precondition: `map` is attached to this graph.
    /// - Throws: `EdgeNotFound` when `position` is out of range or its edge was removed.
    @inlinable
    public subscript<Value>(_ map: EdgeMap<Value>, checkedEdgeAt position: Int) -> Value {
        get throws(EdgeNotFound) {
            let k = _edgeMaps.index(of: map._token, hint: map._hint)
            guard _isLiveEdge(position, _edgePages, base: _edgeBase, end: _edgeEnd) else { throw EdgeNotFound() }
            return _edgeMaps.value(Value.self, at: position, in: k, layout: .paged)
        }
    }

    /// The value of the vertex at `position` in `map`, throwing instead of trapping when no vertex
    /// is there. O(1).
    ///
    /// - Precondition: `map` is attached to this graph.
    /// - Throws: `VertexNotFound` when `position` is out of range or its vertex was removed.
    @inlinable
    public subscript<Value>(_ map: VertexMap<Value>, checkedVertexAt position: Int) -> Value {
        get throws(VertexNotFound) {
            let k = _vertexMaps.index(of: map._token, hint: map._hint)
            guard containsVertex(atPosition: position) else { throw VertexNotFound() }
            return _vertexMaps.value(Value.self, at: position, in: k, layout: .paged)
        }
    }

    /// The value of `vertex` in `map`, throwing instead of trapping when `vertex` is not a vertex.
    /// One hash.
    ///
    /// - Precondition: `map` is attached to this graph.
    /// - Throws: `VertexNotFound` when `vertex` is not a vertex.
    @inlinable
    public subscript<Value>(_ map: VertexMap<Value>, checked vertex: Vertex) -> Value {
        get throws(VertexNotFound) {
            let k = _vertexMaps.index(of: map._token, hint: map._hint)
            guard let slot = _slots[vertex] else { throw VertexNotFound() }
            return _vertexMaps.value(Value.self, at: slot, in: k, layout: .paged)
        }
    }

    /// A snapshot of `map`'s values by edge position. O(1).
    ///
    /// - Precondition: `map` is attached to this graph.
    @inlinable
    public func values<Value>(of map: EdgeMap<Value>) -> EdgeValues<Self, Value> {
        EdgeValues(_storage: _edgeMaps.storage(Value.self, of: map._token, hint: map._hint))
    }

    /// A snapshot of `map`'s values by vertex position. O(1).
    ///
    /// - Precondition: `map` is attached to this graph.
    @inlinable
    public func values<Value>(of map: VertexMap<Value>) -> VertexValues<Self, Value> {
        VertexValues(_storage: _vertexMaps.storage(Value.self, of: map._token, hint: map._hint))
    }
}

// MARK: - Equatable and Hashable

extension StableUndirectedGraph: Equatable {
    /// Two graphs are equal when they have equal vertex sets and equal edge multisets: each edge,
    /// in either orientation, with the same number of copies. Positions, holes, orientations and
    /// insertion order do not matter (compare `Array(g.edges.indices)` too to compare identities).
    /// This is not isomorphism: vertices are compared by value. O(V + E log Δ + pages).
    @inlinable
    public static func == (lhs: StableUndirectedGraph, rhs: StableUndirectedGraph) -> Bool {
        guard lhs._vertexCount == rhs._vertexCount, lhs._edgeCount == rhs._edgeCount else { return false }
        // A copy shares every page table: equal without any lookup.
        let same = lhs._vertexPages.withUnsafeBufferPointer { l in rhs._vertexPages.withUnsafeBufferPointer { r in l.baseAddress == r.baseAddress } }
            && lhs._rowPages.withUnsafeBufferPointer { l in rhs._rowPages.withUnsafeBufferPointer { r in l.baseAddress == r.baseAddress } }
            && lhs._edgePages.withUnsafeBufferPointer { l in rhs._edgePages.withUnsafeBufferPointer { r in l.baseAddress == r.baseAddress } }
            && lhs._vertexPages.count == rhs._vertexPages.count && lhs._edgePages.count == rhs._edgePages.count
            && lhs._vertexBase == rhs._vertexBase && lhs._vertexEnd == rhs._vertexEnd && lhs._edgeEnd == rhs._edgeEnd
        if same { return true }
        // Each live slot of `lhs` mapped to its slot in `rhs`.
        var builder = _PositionNumbers.Builder()
        var slots: [Int] = []
        slots.reserveCapacity(lhs._vertexCount)
        for position in lhs.vertices.indices {
            guard let other = rhs._slots[lhs._vertex(atSlot: position)] else { return false }
            builder.append(position, number: other)
            slots.append(position)
        }
        let map = builder.build()
        // The vertex sets are equal; compare each vertex's neighbors as multisets of rhs slots.
        var left: [Int] = []
        var right: [Int] = []
        for slot in slots {
            let other = map[slot]
            let degree = lhs._degree(slot)
            guard degree == rhs._degree(other) else { return false }
            if degree == 0 { continue }
            left.removeAll(keepingCapacity: true)
            right.removeAll(keepingCapacity: true)
            for end in lhs._row(slot).ends where end >= 0 { left.append(map[end]) }
            for end in rhs._row(other).ends where end >= 0 { right.append(end) }
            if degree > 1 {
                left.sort()
                right.sort()
            }
            guard left == right else { return false }
        }
        return true
    }
}

extension StableUndirectedGraph: Hashable {
    /// Hashes the vertex set and the edge multiset, independently of positions, orientations and
    /// order.
    @inlinable
    public func hash(into hasher: inout Hasher) {
        // Each element is hashed on its own and the results combined with a commutative sum, the
        // same technique `Set` uses, with one term per copy. `UndirectedEdge` hashes symmetrically.
        var vertexHashes = 0
        for v in vertices {
            var h = Hasher()
            h.combine(v)
            vertexHashes &+= h.finalize()
        }
        var edgeHashes = 0
        for edge in edges {
            var h = Hasher()
            h.combine(edge)
            edgeHashes &+= h.finalize()
        }
        hasher.combine(vertexCount)
        hasher.combine(edgeCount)
        hasher.combine(vertexHashes)
        hasher.combine(edgeHashes)
    }
}

// MARK: - Codable

extension StableUndirectedGraph: Encodable where Vertex: Encodable {
    /// Encodes `StableDirectedGraph`'s format, each edge as its first end then its second, so that
    /// a round trip keeps every position, every orientation, and the next insert's fresh position:
    /// `{"vertices":[0,2],"vertexPositions":[0,2],"vertexEnd":3,"edges":[1,0],"edgePositions":[2],"edgeEnd":3}`.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: _StableCodingKeys.self)
        var listed: [Vertex] = []
        var positions: [Int] = []
        var builder = _PositionNumbers.Builder()
        listed.reserveCapacity(_vertexCount)
        positions.reserveCapacity(_vertexCount)
        for position in vertices.indices {
            builder.append(position, number: listed.count)
            listed.append(vertices[position])
            positions.append(position)
        }
        let offsets = builder.build()
        var ends: [Int] = []
        var edgePositions: [Int] = []
        ends.reserveCapacity(2 * _edgeCount)
        edgePositions.reserveCapacity(_edgeCount)
        for position in edges.indices {
            let r = _record(position)
            ends.append(offsets[r.source])
            ends.append(offsets[r.target])
            edgePositions.append(position)
        }
        try container.encode(listed, forKey: .vertices)
        try container.encode(positions, forKey: .vertexPositions)
        try container.encode(_vertexEnd, forKey: .vertexEnd)
        try container.encode(ends, forKey: .edges)
        try container.encode(edgePositions, forKey: .edgePositions)
        try container.encode(_edgeEnd, forKey: .edgeEnd)
    }
}

extension StableUndirectedGraph: Decodable where Vertex: Decodable {
    /// Decodes the format `encode(to:)` writes, every position and both ends restored. Throws
    /// `DecodingError.dataCorrupted` as `StableDirectedGraph`'s decoder does: for a
    /// positions/values count mismatch, a repeated vertex, positions that do not strictly increase
    /// or that reach past their end, an odd-length edge list, an endpoint out of range, or an
    /// implausible end.
    public init(from decoder: any Decoder) throws {
        self.init(_converting: try StableDirectedGraph(from: decoder))
    }
}

extension StableUndirectedGraph {
    /// The graph with `arcs`'s vertices, edges, positions and ends, each arc an edge from its
    /// source to its target, and no maps: the pages copied, the rows rebuilt from the records in
    /// position order. O(n + m + pages).
    internal init(_converting arcs: StableDirectedGraph<Vertex>) {
        self.init()
        _vertexPages = arcs._vertexPages
        _vertexBase = arcs._vertexBase
        _vertexFront = arcs._vertexFront
        _slots = arcs._slots
        _edgePages = arcs._edgePages
        _edgeBase = arcs._edgeBase
        _edgeFront = arcs._edgeFront
        _vertexEnd = arcs._vertexEnd
        _edgeEnd = arcs._edgeEnd
        _vertexCount = arcs._vertexCount
        _edgeCount = arcs._edgeCount
        _firstVertex = arcs._firstVertex
        _firstEdge = arcs._firstEdge
        _rowPages.reserveCapacity(arcs._outPages.count)
        for k in arcs._outPages.indices {
            var page = _RowPage()
            for row in arcs._outPages[k].rows { page.appendRow(dead: row.dead < 0 ? -1 : 0) }
            _rowPages.append(page)
        }
        for k in _edgePages.indices {
            for l in _edgePages[k].records.indices {
                let r = _edgePages[k].records[l]
                if r.source < 0 { continue }
                let position = (_edgeBase &+ k) &<< _PositionPage.shift | l
                let out = _rowPages[_vk(r.source)].append(end: r.target, position: position, toRow: r.source & _PositionPage.mask)
                let into = _rowPages[_vk(r.target)].append(end: r.source, position: position, toRow: r.target & _PositionPage.mask)
                _edgePages[k].records[l].out = out
                _edgePages[k].records[l].in = into
            }
        }
        for k in _rowPages.indices where !_rowPages[k].isFreed { _rowPages[k].pack() }
        _generation.stamp()
    }
}

// MARK: - Descriptions

extension StableUndirectedGraph: CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable {
    /// The live vertices and edges, at most 16 of each: `[0, 1, 2]; [1–2]`. The same form as every
    /// other undirected representation; positions are not shown.
    public var description: String {
        GraphDescription.graph(vertices: vertices, vertexCount: vertexCount, edges: edges, edgeCount: edgeCount)
    }

    /// The type, the counts, and at most 16 vertices and edges.
    public var debugDescription: String {
        "StableUndirectedGraph<\(Vertex.self)>(vertexCount: \(vertexCount), edgeCount: \(edgeCount), vertices: "
            + GraphDescription.list(vertices, count: vertexCount) { String(reflecting: $0) }
            + ", edges: "
            + GraphDescription.list(edges, count: edgeCount) { GraphDescription.edge($0) }
            + ")"
    }

    /// Shows `vertices` and `edges` as children, so a debugger can browse them.
    public var customMirror: Mirror {
        Mirror(self, children: ["vertices": Array(vertices), "edges": Array(edges)], displayStyle: .struct)
    }
}
