import GraphProtocols

// MARK: - DirectedGraph

extension StableDirectedGraph: BidirectionalDirectedGraph {
    /// While no vertex has been removed since the last reset: `vertexCount`, and each vertex's
    /// position is its index. While vertex holes exist: `nil`, because indices must be dense; the
    /// positions are then reported by `SparselyIndexedDirectedGraph`.
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
        precondition(_vertexCount == _vertexEnd, "The graph has vertex holes, so no vertex indices; check vertexIndexBound first")
        precondition(UInt(bitPattern: index) < UInt(bitPattern: _vertexEnd), "Vertex index out of range")
        return _vertex(atSlot: index)
    }

    /// The indices of the successors of the vertex at `index`: the stored row. O(1).
    ///
    /// - Precondition: `vertexIndexBound` is not `nil`, and `index` is in `0..<vertexIndexBound`.
    @inlinable
    public func successorIndices(ofIndex index: Int) -> SuccessorIndices {
        let k = _vk(index), l = index & _PositionPage.mask
        return _outPages.withUnsafeBufferPointer { pages in
            precondition(k >= 0 && k < pages.count, "Vertex index out of range")
            return _LiveRow.Ends(ends: pages[k].endSlice(l), count: pages[k].degree(l))
        }
    }

    /// The indices of the predecessors of the vertex at `index`: the stored row. O(1).
    ///
    /// - Precondition: `vertexIndexBound` is not `nil`, and `index` is in `0..<vertexIndexBound`.
    @inlinable
    public func predecessorIndices(ofIndex index: Int) -> PredecessorIndices {
        let k = _vk(index), l = index & _PositionPage.mask
        return _inPages.withUnsafeBufferPointer { pages in
            precondition(k >= 0 && k < pages.count, "Vertex index out of range")
            return _LiveRow.Ends(ends: pages[k].endSlice(l), count: pages[k].degree(l))
        }
    }

    /// `outEdges(of: vertex(atIndex: index))`, without the hash. O(1).
    @inlinable
    public func outEdges(ofIndex index: Int) -> OutEdges { _outEdges(slot: index) }

    /// `inEdges(of: vertex(atIndex: index))`, without the hash. O(1).
    @inlinable
    public func inEdges(ofIndex index: Int) -> InEdges { _inEdges(slot: index) }

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
}

// MARK: - SparselyIndexedDirectedGraph

extension StableDirectedGraph: SparselyIndexedDirectedGraph {
    /// `vertices.endIndex`: an upper bound only; nothing allocates by it. O(1).
    @inlinable
    public var vertexPositionBound: Int { _vertexEnd }

    /// `edges.endIndex`: an upper bound only; nothing allocates by it. O(1).
    @inlinable
    public var edgePositionBound: Int { _edgeEnd }

    /// The position of `vertex`: `vertices.firstIndex(of: vertex)!`. O(1) expected.
    ///
    /// - Precondition: `vertex` is a vertex of the graph.
    @inlinable
    public func vertexPosition(of vertex: Vertex) -> Int { _slot(of: vertex) }

    /// `vertices[position]`. O(1).
    ///
    /// - Precondition: a vertex is at `position`.
    @inlinable
    public func vertex(atPosition position: Int) -> Vertex { vertices[position] }

    /// `vertices.indices.contains(position)`. O(1).
    @inlinable
    public func containsVertex(atPosition position: Int) -> Bool {
        guard position >= 0, position < _vertexEnd else { return false }
        let k = _vk(position), l = position & _PositionPage.mask
        return _outPages.withUnsafeBufferPointer { pages in k >= 0 && k < pages.count && l < pages[k].rows.count && pages[k].rows[l].dead >= 0 }
    }

    /// `edges.indices.contains(position)`. O(1).
    @inlinable
    public func containsEdge(atPosition position: Int) -> Bool {
        _isLiveEdge(position, _edgePages, base: _edgeBase, end: _edgeEnd)
    }

    /// Numbers the live vertices page by page and copies their rows in that numbering:
    /// O(`vertexCount` + `edgeCount` + pages), with no hashing. Liveness is read from the
    /// out-pages' dead counts (-1 at a hole), not from a `Vertex?`: this runs unspecialized,
    /// through the existential.
    public func _numberedRows(outward: Bool, edges withEdges: Bool) -> _NumberedRows {
        let size = _PositionPage.size, mask = _PositionPage.mask, shift = _PositionPage.shift
        let tableCount = _outPages.count
        let base = _vertexBase
        let n = _vertexCount, m = _edgeCount
        var pageOffsets = [Int](repeating: -1, count: tableCount)
        var blocks = 0
        for k in 0 ..< tableCount where !_outPages[k].isFreed {
            pageOffsets[k] = blocks &* size
            blocks &+= 1
        }
        var numbers = [Int](repeating: -1, count: blocks &* size)
        numbers.withUnsafeMutableBufferPointer { numbers in
            var v = 0
            for k in 0 ..< tableCount where pageOffsets[k] >= 0 {
                let offset = pageOffsets[k]
                _outPages[k].rows.withUnsafeBufferPointer { rows in
                    for l in 0 ..< rows.count where rows[l].dead >= 0 {
                        numbers[offset &+ l] = v
                        v &+= 1
                    }
                }
            }
        }
        let pages = outward ? _outPages : _inPages
        var offsets = [Int](unsafeUninitializedCapacity: n + 1) { offsets, initialized in
            offsets[0] = 0
            initialized = n + 1
        }
        var edges: [Int] = []
        let neighbors = [Int](unsafeUninitializedCapacity: m) { neighbors, initialized in
            numbers.withUnsafeBufferPointer { numbers in
                pageOffsets.withUnsafeBufferPointer { pageOffsets in
                    offsets.withUnsafeMutableBufferPointer { offsets in
                        var i = 0
                        var v = 0
                        for k in 0 ..< tableCount where pageOffsets[k] >= 0 {
                            _outPages[k].rows.withUnsafeBufferPointer { live in
                                pages[k].rows.withUnsafeBufferPointer { rows in
                                    pages[k].ends.withUnsafeBufferPointer { storage in
                                        for l in 0 ..< live.count where live[l].dead >= 0 {
                                            let start = rows[l].start, count = rows[l].count
                                            for j in start ..< start &+ count {
                                                let end = storage[j]
                                                if end >= 0 {
                                                    neighbors[i] = numbers[pageOffsets[(end &>> shift) &- base] &+ (end & mask)]
                                                    i &+= 1
                                                }
                                            }
                                            v &+= 1
                                            offsets[v] = i
                                        }
                                    }
                                }
                            }
                        }
                        initialized = i
                    }
                }
            }
        }
        if withEdges {
            edges = [Int](unsafeUninitializedCapacity: m) { edges, initialized in
                var i = 0
                for k in 0 ..< tableCount where pageOffsets[k] >= 0 {
                    _outPages[k].rows.withUnsafeBufferPointer { live in
                        pages[k].rows.withUnsafeBufferPointer { rows in
                            pages[k].ends.withUnsafeBufferPointer { endStorage in
                                pages[k].positions.withUnsafeBufferPointer { positionStorage in
                                    for l in 0 ..< live.count where live[l].dead >= 0 {
                                        let start = rows[l].start, count = rows[l].count
                                        for j in start ..< start &+ count where endStorage[j] >= 0 {
                                            edges[i] = positionStorage[j]
                                            i &+= 1
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                initialized = i
            }
        }
        let positionNumbers = _PositionNumbers(firstPage: base, pageOffsets: pageOffsets, numbers: numbers)
        return _NumberedRows(numbers: positionNumbers, offsets: offsets, neighbors: neighbors, edges: edges)
    }
}

// MARK: - Equatable and Hashable

extension StableDirectedGraph: Equatable {
    /// Two graphs are equal when they have equal vertex sets and equal edge multisets: each edge
    /// with the same number of copies. Positions, holes and insertion order do not matter
    /// (compare `Array(g.edges.indices)` too to compare identities). This is not isomorphism:
    /// vertices are compared by value. O(V + E log Δ + pages).
    @inlinable
    public static func == (lhs: StableDirectedGraph, rhs: StableDirectedGraph) -> Bool {
        guard lhs._vertexCount == rhs._vertexCount, lhs._edgeCount == rhs._edgeCount else { return false }
        // A copy shares every page table: equal without any lookup.
        let same = lhs._vertexPages.withUnsafeBufferPointer { l in rhs._vertexPages.withUnsafeBufferPointer { r in l.baseAddress == r.baseAddress } }
            && lhs._outPages.withUnsafeBufferPointer { l in rhs._outPages.withUnsafeBufferPointer { r in l.baseAddress == r.baseAddress } }
            && lhs._edgePages.withUnsafeBufferPointer { l in rhs._edgePages.withUnsafeBufferPointer { r in l.baseAddress == r.baseAddress } }
            && lhs._vertexPages.count == rhs._vertexPages.count && lhs._edgePages.count == rhs._edgePages.count
            && lhs._vertexBase == rhs._vertexBase && lhs._vertexEnd == rhs._vertexEnd && lhs._edgeEnd == rhs._edgeEnd
        if same { return true }
        // Each live slot of `lhs` mapped to its slot in `rhs`.
        var builder = _PositionNumbers.Builder()
        var slots: [Int] = []
        slots.reserveCapacity(lhs._vertexCount)
        for k in lhs._vertexPages.indices {
            let first = (lhs._vertexBase &+ k) &<< _PositionPage.shift
            for l in lhs._vertexPages[k].vertices.indices {
                guard let v = lhs._vertexPages[k].vertices[l] else { continue }
                guard let other = rhs._slots[v] else { return false }
                builder.append(first | l, number: other)
                slots.append(first | l)
            }
        }
        let map = builder.build()
        // The vertex sets are equal; compare each vertex's out-targets as multisets of rhs slots.
        var left: [Int] = []
        var right: [Int] = []
        for slot in slots {
            let other = map[slot]
            let degree = lhs._outDegree(slot)
            guard degree == rhs._outDegree(other) else { return false }
            if degree == 0 { continue }
            left.removeAll(keepingCapacity: true)
            right.removeAll(keepingCapacity: true)
            for target in lhs._outRow(slot).ends where target >= 0 { left.append(map[target]) }
            for target in rhs._outRow(other).ends where target >= 0 { right.append(target) }
            if degree > 1 {
                left.sort()
                right.sort()
            }
            guard left == right else { return false }
        }
        return true
    }
}

extension StableDirectedGraph: Hashable {
    /// Hashes the vertex set and the edge multiset, independently of positions and order.
    @inlinable
    public func hash(into hasher: inout Hasher) {
        // Each element is hashed on its own and the results combined with a commutative sum, the
        // same technique `Set` uses, with one term per copy.
        var vertexHashes = 0
        for v in vertices {
            var h = Hasher()
            h.combine(v)
            vertexHashes &+= h.finalize()
        }
        var edgeHashes = 0
        for edge in edges {
            var h = Hasher()
            h.combine(edge.source)
            h.combine(edge.target)
            edgeHashes &+= h.finalize()
        }
        hasher.combine(_vertexCount)
        hasher.combine(_edgeCount)
        hasher.combine(vertexHashes)
        hasher.combine(edgeHashes)
    }
}

// MARK: - Codable

@usableFromInline
internal enum _StableCodingKeys: String, CodingKey {
    case vertices, vertexPositions, vertexEnd, edges, edgePositions, edgeEnd
}

extension StableDirectedGraph: Encodable where Vertex: Encodable {
    /// Encodes the live vertices and their positions, the live edges as pairs of offsets into that
    /// vertex list with their positions, and both ends, so that a round trip keeps every position
    /// and the next insert gets the same fresh position:
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

extension StableDirectedGraph: Decodable where Vertex: Decodable {
    /// Decodes the format `encode(to:)` writes, every position and both ends restored. Throws
    /// `DecodingError.dataCorrupted` for a positions/values count mismatch, a repeated vertex,
    /// positions that do not strictly increase or that reach past their end, an odd-length edge
    /// list, an endpoint out of range, or an implausible end.
    ///
    /// Decoding allocates a page table entry for every page of 1024 positions from the first listed
    /// position to the end, and a page for each page holding a listed element; positions before the
    /// first listed one cost nothing. An end is implausible when that span is more than
    /// `16 × count + 64` pages, where `count` is the number of vertices (or edges) listed: at most
    /// 16 page table entries per listed element (about 2 KB for a vertex, 256 bytes for an edge)
    /// plus 64. So `"vertexEnd": 4611686018427387903` with no vertices decodes, in O(1), while a
    /// payload cannot make decoding allocate without limit. A graph that has run more than that
    /// many empty pages past its live elements does not round-trip.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: _StableCodingKeys.self)
        let listed = try container.decode([Vertex].self, forKey: .vertices)
        let positions = try container.decode([Int].self, forKey: .vertexPositions)
        let vertexEnd = try container.decode(Int.self, forKey: .vertexEnd)
        let ends = try container.decode([Int].self, forKey: .edges)
        let edgePositions = try container.decode([Int].self, forKey: .edgePositions)
        let edgeEnd = try container.decode(Int.self, forKey: .edgeEnd)

        guard listed.count == positions.count else {
            throw DecodingError.dataCorruptedError(forKey: .vertexPositions, in: container, debugDescription: "Count differs from vertices")
        }
        var seen = Set<Vertex>()
        seen.reserveCapacity(listed.count)
        for v in listed {
            guard seen.insert(v).inserted else {
                throw DecodingError.dataCorruptedError(forKey: .vertices, in: container, debugDescription: "Repeated vertex")
            }
        }
        guard Self._isPlausible(end: vertexEnd, first: positions.first, count: listed.count) else {
            throw DecodingError.dataCorruptedError(forKey: .vertexEnd, in: container, debugDescription: "End leaves too many empty pages")
        }
        guard Self._isIncreasing(positions, within: vertexEnd) else {
            throw DecodingError.dataCorruptedError(forKey: .vertexPositions, in: container, debugDescription: "Positions not increasing within vertexEnd")
        }
        guard ends.count.isMultiple(of: 2) else {
            throw DecodingError.dataCorruptedError(forKey: .edges, in: container, debugDescription: "Edge list has odd length")
        }
        guard ends.count / 2 == edgePositions.count else {
            throw DecodingError.dataCorruptedError(forKey: .edgePositions, in: container, debugDescription: "Count differs from edges")
        }
        guard ends.allSatisfy({ $0 >= 0 && $0 < listed.count }) else {
            throw DecodingError.dataCorruptedError(forKey: .edges, in: container, debugDescription: "Edge endpoint out of range")
        }
        guard Self._isPlausible(end: edgeEnd, first: edgePositions.first, count: edgePositions.count) else {
            throw DecodingError.dataCorruptedError(forKey: .edgeEnd, in: container, debugDescription: "End leaves too many empty pages")
        }
        guard Self._isIncreasing(edgePositions, within: edgeEnd) else {
            throw DecodingError.dataCorruptedError(forKey: .edgePositions, in: container, debugDescription: "Positions not increasing within edgeEnd")
        }

        self.init()
        _slots.reserveCapacity(listed.count)
        for (k, v) in listed.enumerated() {
            _skipVertexPositions(to: positions[k])
            _appendSlot(for: v)
        }
        _skipVertexPositions(to: vertexEnd)
        _firstVertex = positions.first ?? vertexEnd
        for (k, position) in edgePositions.enumerated() {
            _skipEdgePositions(to: position)
            // Positions increase, so each edge appends at the tails, in position order.
            _insertEdge(slots: positions[ends[2 * k]], positions[ends[2 * k + 1]])
        }
        _skipEdgePositions(to: edgeEnd)
        _packRows()
        _firstEdge = edgePositions.first ?? edgeEnd
    }

    /// Whether the pages from the first listed position (or the end, with none listed) to the end
    /// number at most `16 × count + 64`; a negative or too-small end is left to `_isIncreasing`.
    internal static func _isPlausible(end: Int, first: Int?, count: Int) -> Bool {
        guard end >= 0 else { return true }
        let firstPage = Swift.max(first ?? end, 0) >> _PositionPage.shift
        let span = (end >> _PositionPage.shift) - firstPage + 1
        // Written as comparisons: no multiplication to overflow.
        return count >= (Int.max - 64) / 16 || span <= 16 * count + 64
    }

    /// Whether `positions` strictly increase and lie in `0..<end`, and there are at most `end`.
    internal static func _isIncreasing(_ positions: [Int], within end: Int) -> Bool {
        guard end >= positions.count else { return false }
        var previous = -1
        for p in positions {
            guard p > previous else { return false }
            previous = p
        }
        return previous < end
    }
}

extension StableDirectedGraph {
    /// Hands out every vertex position below `end` as a hole. A page wholly in the gap costs a
    /// freed table entry, or nothing before the first page; a partial page is filled with holes.
    internal mutating func _skipVertexPositions(to end: Int) {
        let size = _PositionPage.size
        while _vertexEnd < end {
            if _vertexEnd & _PositionPage.mask == 0, end - _vertexEnd >= size {
                if _vertexPages.isEmpty {
                    // Before the first page: no table entry, so jump the whole gap.
                    _vertexEnd = end & ~_PositionPage.mask
                    continue
                }
                _vertexPages.append(_VertexPage())
                _outPages.append(_RowPage())
                _inPages.append(_RowPage())
                _vertexEnd += size
                continue
            }
            if _vertexEnd & _PositionPage.mask == 0 { _appendVertexPage() }
            let k = _vertexPages.count - 1
            _vertexPages[k].vertices.append(nil)
            _outPages[k].appendRow(dead: -1)
            _inPages[k].appendRow(dead: 0)
            _vertexEnd += 1
            if _vertexPages[k].live == 0, _vertexPages[k].vertices.count == size {
                _vertexPages[k] = _VertexPage()
                _outPages[k] = _RowPage()
                _inPages[k] = _RowPage()
            }
        }
        if _vertexPages.isEmpty { _vertexBase = _vertexEnd >> _PositionPage.shift }
        _vertexFront = 0
        while _vertexFront < _vertexPages.count, _vertexPages[_vertexFront].vertices.isEmpty { _vertexFront += 1 }
    }

    /// Hands out every edge position below `end` as a hole, as `_skipVertexPositions(to:)` does.
    internal mutating func _skipEdgePositions(to end: Int) {
        let size = _PositionPage.size
        while _edgeEnd < end {
            if _edgeEnd & _PositionPage.mask == 0, end - _edgeEnd >= size {
                if _edgePages.isEmpty {
                    // Before the first page: no table entry, so jump the whole gap.
                    _edgeEnd = end & ~_PositionPage.mask
                    continue
                }
                _edgePages.append(_EdgePage())
                _edgeEnd += size
                continue
            }
            if _edgeEnd & _PositionPage.mask == 0 { _appendEdgePage() }
            let k = _edgePages.count - 1
            _edgePages[k].records.append(.hole)
            _edgeEnd += 1
            if _edgePages[k].live == 0, _edgePages[k].records.count == size { _edgePages[k] = _EdgePage() }
        }
        if _edgePages.isEmpty { _edgeBase = _edgeEnd >> _PositionPage.shift }
        _edgeFront = 0
        while _edgeFront < _edgePages.count, _edgePages[_edgeFront].records.isEmpty { _edgeFront += 1 }
    }
}

// MARK: - Descriptions

extension StableDirectedGraph: CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable {
    /// The live vertices and edges, at most 16 of each: `[0, 1, 2]; [1→2]`. The same form as every
    /// other directed representation; positions are not shown.
    public var description: String {
        GraphDescription.graph(vertices: vertices, vertexCount: vertexCount, edges: edges, edgeCount: edgeCount)
    }

    /// The type, the counts, and at most 16 vertices and edges.
    public var debugDescription: String {
        "StableDirectedGraph<\(Vertex.self)>(vertexCount: \(vertexCount), edgeCount: \(edgeCount), vertices: "
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

// MARK: - MutableDirectedGraph

extension StableDirectedGraph: MutableDirectedGraph {
    /// The position of `vertex`, or `nil`. One hash.
    @inlinable public func _key(of vertex: Vertex) -> Int? { _slots[vertex] }
    @inlinable public func _vertex(atKey key: Int) -> Vertex { _vertex(atSlot: key) }
    @inlinable public func _successors(ofKey key: Int) -> Neighbors { Neighbors(pages: _vertexPages, base: _vertexBase, row: _outRow(key)) }
    @inlinable public func _predecessors(ofKey key: Int) -> Neighbors { Neighbors(pages: _vertexPages, base: _vertexBase, row: _inRow(key)) }

    /// The stored row's live far ends, which are positions; valid with holes, unlike
    /// `successorIndices(ofIndex:)`'s contract.
    @inlinable
    public func _successorKeys(ofKey key: Int) -> SuccessorIndices {
        let k = _vk(key), l = key & _PositionPage.mask
        return _outPages.withUnsafeBufferPointer { _LiveRow.Ends(ends: $0[k].endSlice(l), count: $0[k].degree(l)) }
    }

    /// The stored row's live far ends, which are positions.
    @inlinable
    public func _predecessorKeys(ofKey key: Int) -> PredecessorIndices {
        let k = _vk(key), l = key & _PositionPage.mask
        return _inPages.withUnsafeBufferPointer { _LiveRow.Ends(ends: $0[k].endSlice(l), count: $0[k].degree(l)) }
    }

    @inlinable public func _outEdges(ofKey key: Int) -> OutEdges { _outEdges(slot: key) }
    @inlinable public func _inEdges(ofKey key: Int) -> InEdges { _inEdges(slot: key) }
    @inlinable public func _outDegree(ofKey key: Int) -> Int { _outDegree(key) }
    @inlinable public func _inDegree(ofKey key: Int) -> Int { _inDegree(key) }
    @inlinable public func _sourceKey(ofEdgeAt position: Int) -> Int { _liveRecord(position).source }
    @inlinable public func _targetKey(ofEdgeAt position: Int) -> Int { _liveRecord(position).target }
    @inlinable public mutating func _insertVertex(_ vertex: Vertex) -> Int { _appendSlot(for: vertex) }

    /// Always a new copy, at position `edges.endIndex`.
    @inlinable
    public mutating func _insertEdge(fromKey source: Int, toKey target: Int) -> Int {
        _insertEdge(slots: source, target)
    }

    /// Removes the vertex at position `key`, leaving a hole: nothing moves, so always `nil`.
    @inlinable
    public mutating func _removeVertex(atKey key: Int) -> Int? {
        _slots.removeValue(forKey: _vertex(atSlot: key))
        _ = _removeSlot(key)
        return nil
    }

    /// `remove(edgeAt:)`: a hole; traps at a position with no live edge.
    @inlinable
    public mutating func _removeEdge(at position: Int) -> DirectedEdge<Vertex> { remove(edgeAt: position) }
}
