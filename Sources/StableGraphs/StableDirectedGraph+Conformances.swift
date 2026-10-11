import AdjacencyListModule
import GraphProtocols

// MARK: - DirectedGraph

extension StableDirectedGraph: BidirectionalDirectedGraph {
    /// While no vertex has been removed since the last reset: `vertexCount`, and each vertex's
    /// position is its index. While vertex holes exist: `nil`, because indices must be dense; the
    /// positions are then reported by `SparselyIndexedDirectedGraph`.
    @inlinable
    public var vertexIndexBound: Int? { _vertexCount == _vertices.count ? _vertexCount : nil }

    /// The position of `vertex`. O(1) expected.
    ///
    /// - Precondition: `vertexIndexBound` is not `nil`, and `vertex` is a vertex of the graph.
    @inlinable
    public func vertexIndex(of vertex: Vertex) -> Int {
        precondition(_vertexCount == _vertices.count, "The graph has vertex holes, so no vertex indices; check vertexIndexBound first")
        return _slot(of: vertex)
    }

    /// The vertex at index `index`. O(1).
    ///
    /// - Precondition: `vertexIndexBound` is not `nil`, and `index` is in `0..<vertexIndexBound`.
    @inlinable
    public func vertex(atIndex index: Int) -> Vertex {
        precondition(_vertexCount == _vertices.count, "The graph has vertex holes, so no vertex indices; check vertexIndexBound first")
        return _vertices[index].unsafelyUnwrapped
    }

    /// The indices of the successors of the vertex at `index`: the stored row. O(1).
    ///
    /// - Precondition: `vertexIndexBound` is not `nil`, and `index` is in `0..<vertexIndexBound`.
    @inlinable
    public func successorIndices(ofIndex index: Int) -> SuccessorIndices { _LiveRow.Ends(ends: _out[row: index], count: _outDegree(index)) }

    /// The indices of the predecessors of the vertex at `index`: the stored row. O(1).
    ///
    /// - Precondition: `vertexIndexBound` is not `nil`, and `index` is in `0..<vertexIndexBound`.
    @inlinable
    public func predecessorIndices(ofIndex index: Int) -> PredecessorIndices { _LiveRow.Ends(ends: _in[row: index], count: _inDegree(index)) }

    /// `outEdges(of: vertex(atIndex: index))`, without the hash. O(1).
    @inlinable
    public func outEdges(ofIndex index: Int) -> OutEdges { _outEdges(slot: index) }

    /// `inEdges(of: vertex(atIndex: index))`, without the hash. O(1).
    @inlinable
    public func inEdges(ofIndex index: Int) -> InEdges { _inEdges(slot: index) }

    /// While no edge has been removed since the last reset: `edgeCount`, and each position is its
    /// index. While edge holes exist: `nil`.
    @inlinable
    public var edgeIndexBound: Int? { _edgeCount == _records.count ? _edgeCount : nil }

    /// The position itself. O(1).
    ///
    /// - Precondition: `edgeIndexBound` is not `nil`, and `position` is in `0..<edgeIndexBound`.
    @inlinable
    public func edgeIndex(of position: Int) -> Int {
        precondition(_edgeCount == _records.count, "The graph has edge holes, so no edge indices; check edgeIndexBound first")
        precondition(UInt(bitPattern: position) < UInt(bitPattern: _records.count), "Edge position out of range")
        return position
    }
}

// MARK: - SparselyIndexedDirectedGraph

extension StableDirectedGraph: SparselyIndexedDirectedGraph {
    /// `vertices.endIndex`. O(1).
    @inlinable
    public var vertexPositionBound: Int { _vertices.count }

    /// `edges.endIndex`. O(1).
    @inlinable
    public var edgePositionBound: Int { _records.count }

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
        position >= 0 && position < _vertices.count && _outDead[position] >= 0
    }

    /// `edges.indices.contains(position)`. O(1).
    @inlinable
    public func containsEdge(atPosition position: Int) -> Bool {
        position >= 0 && position < _records.count && _records[position].source >= 0
    }

    public func _numberedRows(outward: Bool, edges withEdges: Bool) -> _NumberedRows {
        let bound = _vertices.count
        let m = _edgeCount
        var numbers = [Int](repeating: -1, count: bound)
        _outDead.withUnsafeBufferPointer { outDead in
            numbers.withUnsafeMutableBufferPointer { numbers in
                var n = 0
                for slot in 0 ..< bound where outDead[slot] >= 0 {
                    numbers[slot] = n
                    n &+= 1
                }
            }
        }
        let ends = outward ? _out : _in
        let positions = outward ? _outEdges : _inEdges
        var offsets = [Int](unsafeUninitializedCapacity: _vertexCount + 1) { offsets, initialized in
            offsets[0] = 0
            initialized = _vertexCount + 1
        }
        var edges: [Int] = []
        let neighbors = [Int](unsafeUninitializedCapacity: m) { neighbors, initialized in
            numbers.withUnsafeBufferPointer { numbers in
                ends.withUnsafeRows { endStorage, endRows in
                    offsets.withUnsafeMutableBufferPointer { offsets in
                        var k = 0
                        var v = 0
                        for slot in 0 ..< bound where numbers[slot] >= 0 {
                            let start = endRows[3 &* slot], count = endRows[3 &* slot &+ 1]
                            for j in start ..< start &+ count {
                                let end = endStorage[j]
                                if end >= 0 {
                                    neighbors[k] = numbers[end]
                                    k &+= 1
                                }
                            }
                            v &+= 1
                            offsets[v] = k
                        }
                        initialized = k
                    }
                }
            }
        }
        if withEdges {
            edges = [Int](unsafeUninitializedCapacity: m) { edges, initialized in
                numbers.withUnsafeBufferPointer { numbers in
                    ends.withUnsafeRows { endStorage, endRows in
                        positions.withUnsafeRows { positionStorage, positionRows in
                            var k = 0
                            for slot in 0 ..< bound where numbers[slot] >= 0 {
                                let start = endRows[3 &* slot], count = endRows[3 &* slot &+ 1], positionStart = positionRows[3 &* slot]
                                for j in 0 ..< count where endStorage[start &+ j] >= 0 {
                                    edges[k] = positionStorage[positionStart &+ j]
                                    k &+= 1
                                }
                            }
                            initialized = k
                        }
                    }
                }
            }
        }
        return _NumberedRows(numbers: numbers, offsets: offsets, neighbors: neighbors, edges: edges)
    }
}

// MARK: - Equatable and Hashable

extension StableDirectedGraph: Equatable {
    /// Two graphs are equal when they have equal vertex sets and equal edge multisets: each edge
    /// with the same number of copies. Positions, holes and insertion order do not matter
    /// (compare `Array(g.edges.indices)` too to compare identities). This is not isomorphism:
    /// vertices are compared by value. O(V + E log Δ).
    @inlinable
    public static func == (lhs: StableDirectedGraph, rhs: StableDirectedGraph) -> Bool {
        guard lhs._vertexCount == rhs._vertexCount, lhs._edgeCount == rhs._edgeCount else { return false }
        // A copy shares every buffer: equal without any lookup.
        let same = lhs._vertices.withUnsafeBufferPointer { l in rhs._vertices.withUnsafeBufferPointer { r in l.baseAddress == r.baseAddress } }
            && lhs._records.withUnsafeBufferPointer { l in rhs._records.withUnsafeBufferPointer { r in l.baseAddress == r.baseAddress } }
            && lhs._vertices.count == rhs._vertices.count && lhs._records.count == rhs._records.count
        if same { return true }
        // Each live slot of `lhs` mapped to its slot in `rhs`.
        var map = [Int](repeating: -1, count: lhs._vertices.count)
        for slot in lhs._vertices.indices {
            guard let v = lhs._vertices[slot] else { continue }
            guard let other = rhs._slots[v] else { return false }
            map[slot] = other
        }
        // The vertex sets are equal; compare each vertex's out-targets as multisets of rhs slots.
        var left: [Int] = []
        var right: [Int] = []
        for slot in lhs._vertices.indices where map[slot] >= 0 {
            let other = map[slot]
            let degree = lhs._outDegree(slot)
            guard degree == rhs._outDegree(other) else { return false }
            if degree == 0 { continue }
            left.removeAll(keepingCapacity: true)
            right.removeAll(keepingCapacity: true)
            for target in lhs._out[row: slot] where target >= 0 { left.append(map[target]) }
            for target in rhs._out[row: other] where target >= 0 { right.append(target) }
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
        var offsets = [Int](repeating: -1, count: _vertices.count)
        listed.reserveCapacity(_vertexCount)
        positions.reserveCapacity(_vertexCount)
        for slot in _vertices.indices {
            guard let v = _vertices[slot] else { continue }
            offsets[slot] = listed.count
            listed.append(v)
            positions.append(slot)
        }
        var ends: [Int] = []
        var edgePositions: [Int] = []
        ends.reserveCapacity(2 * _edgeCount)
        edgePositions.reserveCapacity(_edgeCount)
        for position in _records.indices {
            let r = _records[position]
            guard r.source >= 0 else { continue }
            ends.append(offsets[r.source])
            ends.append(offsets[r.target])
            edgePositions.append(position)
        }
        try container.encode(listed, forKey: .vertices)
        try container.encode(positions, forKey: .vertexPositions)
        try container.encode(_vertices.count, forKey: .vertexEnd)
        try container.encode(ends, forKey: .edges)
        try container.encode(edgePositions, forKey: .edgePositions)
        try container.encode(_records.count, forKey: .edgeEnd)
    }
}

extension StableDirectedGraph: Decodable where Vertex: Decodable {
    /// Decodes the format `encode(to:)` writes, every position and both ends restored. Throws
    /// `DecodingError.dataCorrupted` for a positions/values count mismatch, a repeated vertex,
    /// positions that do not strictly increase or that reach past their end, an odd-length edge
    /// list, or an endpoint out of range.
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
        var slots: [Vertex: Int] = [:]
        slots.reserveCapacity(listed.count)
        for (k, v) in listed.enumerated() {
            guard slots.updateValue(positions[k], forKey: v) == nil else {
                throw DecodingError.dataCorruptedError(forKey: .vertices, in: container, debugDescription: "Repeated vertex")
            }
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
        guard Self._isIncreasing(edgePositions, within: edgeEnd) else {
            throw DecodingError.dataCorruptedError(forKey: .edgePositions, in: container, debugDescription: "Positions not increasing within edgeEnd")
        }

        self.init()
        _vertices = ContiguousArray(repeating: nil, count: vertexEnd)
        reserveCapacity(vertexCount: vertexEnd, edgeCount: edgePositions.count)
        _outDead = ContiguousArray(repeating: -1, count: vertexEnd)
        _inDead = ContiguousArray(repeating: 0, count: vertexEnd)
        for _ in 0 ..< vertexEnd {
            _out.appendRow()
            _outEdges.appendRow()
            _in.appendRow()
            _inEdges.appendRow()
        }
        for (k, v) in listed.enumerated() {
            _vertices[positions[k]] = v
            _outDead[positions[k]] = 0
        }
        _slots = slots
        _vertexCount = listed.count
        _firstVertex = positions.first ?? vertexEnd
        _records.reserveCapacity(edgeEnd)
        for (k, position) in edgePositions.enumerated() {
            while _records.count < position { _records.append(.hole) }
            // Positions increase, so each edge appends at the tails, in position order.
            _insertEdge(slots: positions[ends[2 * k]], positions[ends[2 * k + 1]])
        }
        while _records.count < edgeEnd { _records.append(.hole) }
        _packRows()
        _firstEdge = edgePositions.first ?? edgeEnd
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
