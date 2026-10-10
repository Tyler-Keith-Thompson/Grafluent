import AdjacencyListModule
import GraphProtocols

/// An undirected graph with two fixed sides, every edge joining a left vertex to a right vertex, so
/// no self-loop. Simple: an edge is inserted once, in either orientation. Each edge is stored left
/// endpoint first, so `edges[e].u` is its left end.
///
/// The invariant is the type: every initializer from unchecked input is failable, and a mutation
/// that would break it traps (whether an edge may be inserted is an O(1) test with `side(of:)`).
/// Storage and mutation costs are `UndirectedAdjacencyList`'s: vertex indices are slots
/// (`vertices` order), edge indices are positions, and a removal moves the last slot or edge into
/// the hole, so orders and positions change after a removal. Equality compares vertex sets, edge
/// sets and each vertex's side, not orders.
@frozen
public struct BipartiteGraph<Vertex: Hashable> {
    @usableFromInline var _graph: UndirectedAdjacencyList<Vertex>
    /// The side of each slot.
    @usableFromInline var _side: [BipartiteSide]
    /// The slots on each side, in side order.
    @usableFromInline var _left: [Int]
    @usableFromInline var _right: [Int]
    /// Each slot's offset in `_left` or `_right`.
    @usableFromInline var _sideOffset: [Int]

    /// The empty graph.
    @inlinable
    public init() {
        _graph = UndirectedAdjacencyList()
        _side = []
        _left = []
        _right = []
        _sideOffset = []
    }

    /// No edges; `left` then `right` in `vertices` order, repeats within a side dropped. nil when a
    /// vertex is on both sides.
    @inlinable
    public init?(left: some Sequence<Vertex>, right: some Sequence<Vertex>) {
        self.init()
        for v in left { insert(v, on: .left) }
        for v in right {
            if let slot = _graph._slotIfPresent(of: v), _side[slot] == .left { return nil }
            insert(v, on: .right)
        }
    }

    /// As `init?(left:right:)`, with these edges in order (a repeat, in either orientation, once).
    /// nil when a vertex is on both sides, or an edge has an endpoint on neither side or both
    /// endpoints on one side (a self-loop included). Endpoints are not inserted implicitly: their
    /// side would be unknown.
    @inlinable
    public init?(left: some Sequence<Vertex>, right: some Sequence<Vertex>, edges: some Sequence<UndirectedEdge<Vertex>>) {
        self.init(left: left, right: right)
        for edge in edges {
            guard let u = _graph._slotIfPresent(of: edge.u), let v = _graph._slotIfPresent(of: edge.v), _side[u] != _side[v] else { return nil }
            if _side[u] == .left { _graph._insertEdge(slots: u, v) } else { _graph._insertEdge(slots: v, u) }
        }
    }

    /// The graph's vertices (in order), edges (in position order, so at their positions when the
    /// graph has no parallel edges; repeats dropped), and the canonical sides of `bipartition()`.
    /// nil when the graph is not bipartite: `graph.findOddCycle()` is then the witness. O(n + m).
    @inlinable
    public init?(_ graph: some Graph<Vertex>) {
        guard let sides = graph._runOnUndirectedRows(_TwoColoring(witness: false)).sides else { return nil }
        // An adjacency list is the storage itself, each edge turned to put its left end first.
        if var list = graph as? UndirectedAdjacencyList<Vertex> {
            for position in 0 ..< list.edgeCount where sides[list._edgeSlots(at: position).u] != 0 {
                list._reverseEdge(at: position)
            }
            self.init()
            _graph = list
            _side = sides.map { $0 == 0 ? .left : .right }
            _sideOffset.reserveCapacity(sides.count)
            for (slot, s) in sides.enumerated() {
                if s == 0 {
                    _sideOffset.append(_left.count)
                    _left.append(slot)
                } else {
                    _sideOffset.append(_right.count)
                    _right.append(slot)
                }
            }
            return
        }
        self.init()
        reserveCapacity(vertexCount: graph.vertexCount, edgeCount: graph.edgeCount)
        for (k, v) in graph.vertices.enumerated() { insert(v, on: sides[k] == 0 ? .left : .right) }
        // Numbered as `vertices`, so the slots are the vertex numbers.
        for edge in graph.edges {
            let u = _graph.vertexIndex(of: edge.u), v = _graph.vertexIndex(of: edge.v)
            if _side[u] == .left { _graph._insertEdge(slots: u, v) } else { _graph._insertEdge(slots: v, u) }
        }
    }

    /// The graph's vertices and edges with `left` as the left side and every other vertex on the
    /// right (NetworkX `is_bipartite_node_set`, as a constructor; repeats in `left` are one
    /// vertex). nil unless every edge goes across, or when `left` names a non-vertex.
    @inlinable
    public init?(_ graph: some Graph<Vertex>, left: some Sequence<Vertex>) {
        var leftSet = Set<Vertex>()
        for v in left {
            guard graph.contains(v) else { return nil }
            leftSet.insert(v)
        }
        self.init()
        reserveCapacity(vertexCount: graph.vertexCount, edgeCount: graph.edgeCount)
        for v in graph.vertices { insert(v, on: leftSet.contains(v) ? .left : .right) }
        for edge in graph.edges {
            guard leftSet.contains(edge.u) != leftSet.contains(edge.v) else { return nil }
            insert(edge: edge)
        }
    }

    /// The left vertices, in insertion order (a removal moves the side's last vertex into the hole).
    @inlinable
    public var left: SideVertices { SideVertices(graph: _graph, slots: _left) }

    /// The right vertices, in insertion order (a removal moves the side's last vertex into the hole).
    @inlinable
    public var right: SideVertices { SideVertices(graph: _graph, slots: _right) }

    /// The side of `vertex`. O(1).
    ///
    /// - Precondition: `vertex` is a vertex of the graph.
    @inlinable
    public func side(of vertex: Vertex) -> BipartiteSide {
        guard let slot = _graph._slotIfPresent(of: vertex) else { preconditionFailure("\(vertex) is not a vertex of the graph") }
        return _side[slot]
    }

    /// Inserts `vertex` on `side` with no edges.
    ///
    /// - Returns: Whether it was inserted, and the vertex now in the graph (the existing one when it
    ///   was already on `side`).
    /// - Precondition: `vertex` is not a vertex on the other side.
    @inlinable
    @discardableResult
    public mutating func insert(_ vertex: Vertex, on side: BipartiteSide) -> (inserted: Bool, memberAfterInsert: Vertex) {
        if let slot = _graph._slotIfPresent(of: vertex) {
            precondition(_side[slot] == side, "\(vertex) is already a vertex on the other side")
            return (false, _graph.vertex(atIndex: slot))
        }
        _graph.insert(vertex)
        let slot = _side.count
        _side.append(side)
        if side == .left {
            _sideOffset.append(_left.count)
            _left.append(slot)
        } else {
            _sideOffset.append(_right.count)
            _right.append(slot)
        }
        return (true, vertex)
    }

    /// Inserts `edge`, stored left endpoint first.
    ///
    /// - Returns: Whether it was inserted, and the edge now in the graph, left endpoint first (the
    ///   existing one when it was already an edge, in either orientation).
    /// - Precondition: Both endpoints are vertices, on different sides.
    @inlinable
    @discardableResult
    public mutating func insert(edge: UndirectedEdge<Vertex>) -> (inserted: Bool, memberAfterInsert: UndirectedEdge<Vertex>) {
        guard let u = _graph._slotIfPresent(of: edge.u), let v = _graph._slotIfPresent(of: edge.v) else {
            preconditionFailure("An endpoint of \(edge) is not a vertex")
        }
        precondition(_side[u] != _side[v], "Both endpoints of \(edge) are on the same side")
        return _side[u] == .left ? _graph._insertEdge(slots: u, v) : _graph._insertEdge(slots: v, u)
    }

    /// Removes `vertex` and its edges. O(degree), plus the degree of the vertex that moves into its
    /// slot.
    ///
    /// - Returns: The removed vertex, or nil if it was not a vertex.
    @inlinable
    @discardableResult
    public mutating func remove(_ vertex: Vertex) -> Vertex? {
        guard let slot = _graph._slotIfPresent(of: vertex) else { return nil }
        // Out of its side list: the side's last vertex moves into its place.
        let offset = _sideOffset[slot]
        if _side[slot] == .left {
            let moved = _left.removeLast()
            if moved != slot {
                _left[offset] = moved
                _sideOffset[moved] = offset
            }
        } else {
            let moved = _right.removeLast()
            if moved != slot {
                _right[offset] = moved
                _sideOffset[moved] = offset
            }
        }
        let removed = _graph.remove(vertex)
        // The graph moved its last slot into `slot`: rename it here too.
        let last = _side.count - 1
        if slot != last {
            _side[slot] = _side[last]
            _sideOffset[slot] = _sideOffset[last]
            if _side[slot] == .left { _left[_sideOffset[slot]] = slot } else { _right[_sideOffset[slot]] = slot }
        }
        _side.removeLast()
        _sideOffset.removeLast()
        return removed
    }

    /// Removes `edge`, in either orientation. O(1).
    ///
    /// - Returns: The removed edge, left endpoint first, or nil if it was not an edge.
    @inlinable
    @discardableResult
    public mutating func remove(edge: UndirectedEdge<Vertex>) -> UndirectedEdge<Vertex>? {
        _graph.remove(edge: edge)
    }

    /// Removes every vertex and edge.
    @inlinable
    public mutating func removeAll(keepingCapacity: Bool = false) {
        _graph.removeAll(keepingCapacity: keepingCapacity)
        _side.removeAll(keepingCapacity: keepingCapacity)
        _left.removeAll(keepingCapacity: keepingCapacity)
        _right.removeAll(keepingCapacity: keepingCapacity)
        _sideOffset.removeAll(keepingCapacity: keepingCapacity)
    }

    /// Removes every edge; the vertices keep their sides.
    @inlinable
    public mutating func removeAllEdges(keepingCapacity: Bool = false) {
        _graph.removeAllEdges(keepingCapacity: keepingCapacity)
    }

    /// Reserves room for this many vertices and edges.
    @inlinable
    public mutating func reserveCapacity(vertexCount: Int, edgeCount: Int) {
        _graph.reserveCapacity(vertexCount: vertexCount, edgeCount: edgeCount)
        _side.reserveCapacity(vertexCount)
        _sideOffset.reserveCapacity(vertexCount)
        _left.reserveCapacity(vertexCount)
        _right.reserveCapacity(vertexCount)
    }

    /// The graph on one side's vertices (in `left` or `right` order, isolated ones included), with an
    /// edge between two vertices that share a neighbor, once however many they share (NetworkX
    /// `projected_graph`). Edges are inserted as found: for each vertex u in side order, each
    /// neighbor w in u's row, each x ≠ u in w's row. O(Σ_{u ∈ side} Σ_{w ∈ N(u)} deg(w)).
    @inlinable
    public func projectedGraph(onto side: BipartiteSide) -> UndirectedAdjacencyList<Vertex> {
        let slots = side == .left ? _left : _right
        // Each pair once, from its earlier vertex in side order: x is skipped unless it comes
        // after u, so `insert(edge:)` runs once per projected edge.
        var lastSeen = [Int](repeating: -1, count: _side.count)
        var bound = 0
        for u in slots { for w in _graph.neighborIndices(ofIndex: u) { bound += _graph.neighborIndices(ofIndex: w).count - 1 } }
        var result = UndirectedAdjacencyList<Vertex>()
        result.reserveCapacity(vertexCount: slots.count, edgeCount: min(bound / 2, slots.count * max(slots.count - 1, 0) / 2))
        for u in slots { result.insert(_graph.vertex(atIndex: u)) }
        // In `result`, side position k is slot k.
        for (k, u) in slots.enumerated() {
            for w in _graph.neighborIndices(ofIndex: u) {
                for x in _graph.neighborIndices(ofIndex: w) {
                    if x == u || lastSeen[x] == u { continue }
                    lastSeen[x] = u
                    let other = _sideOffset[x]
                    if other < k { continue }
                    result._insertEdge(slots: k, other)
                }
            }
        }
        return result
    }

    /// A side's vertices: a value, unaffected by later changes to the graph. It holds a copy of the
    /// graph's storage (copy-on-write), so mutating the graph while one is alive copies the graph.
    @frozen
    public struct SideVertices: RandomAccessCollection {
        @usableFromInline let graph: UndirectedAdjacencyList<Vertex>
        @usableFromInline let slots: [Int]

        @inlinable
        init(graph: UndirectedAdjacencyList<Vertex>, slots: [Int]) {
            self.graph = graph
            self.slots = slots
        }

        @inlinable public var startIndex: Int { 0 }
        @inlinable public var endIndex: Int { slots.count }

        @inlinable
        public subscript(position: Int) -> Vertex {
            precondition(position >= 0 && position < slots.count, "Index out of range")
            return graph.vertex(atIndex: slots[position])
        }
    }
}

// MARK: - Graph

extension BipartiteGraph: Graph {
    public typealias Vertices = UndirectedAdjacencyList<Vertex>.Vertices
    public typealias Edges = UndirectedAdjacencyList<Vertex>.Edges
    public typealias Neighbors = UndirectedAdjacencyList<Vertex>.Neighbors

    @inlinable public var vertices: Vertices { _graph.vertices }
    @inlinable public var edges: Edges { _graph.edges }
    @inlinable public var vertexCount: Int { _graph.vertexCount }
    @inlinable public var edgeCount: Int { _graph.edgeCount }
    @inlinable public func contains(_ vertex: Vertex) -> Bool { _graph.contains(vertex) }
    @inlinable public func contains(edge: UndirectedEdge<Vertex>) -> Bool { _graph.contains(edge: edge) }
    @inlinable public func neighbors(of vertex: Vertex) -> Neighbors { _graph.neighbors(of: vertex) }
    @inlinable public func incidentEdges(of vertex: Vertex) -> ArraySlice<Int> { _graph.incidentEdges(of: vertex) }
    @inlinable public func oppositeVertex(to vertex: Vertex, acrossEdgeAt position: Int) -> Vertex { _graph.oppositeVertex(to: vertex, acrossEdgeAt: position) }
    @inlinable public func degree(of vertex: Vertex) -> Int { _graph.degree(of: vertex) }
    @inlinable public var vertexIndexBound: Int? { _graph.vertexIndexBound }
    @inlinable public func vertexIndex(of vertex: Vertex) -> Int { _graph.vertexIndex(of: vertex) }
    @inlinable public func vertex(atIndex index: Int) -> Vertex { _graph.vertex(atIndex: index) }
    @inlinable public func neighborIndices(ofIndex index: Int) -> ArraySlice<Int> { _graph.neighborIndices(ofIndex: index) }
    @inlinable public var edgeIndexBound: Int? { _graph.edgeIndexBound }
    @inlinable public func edgeIndex(of position: Int) -> Int { position }
    @inlinable public func incidentEdges(ofIndex index: Int) -> ArraySlice<Int> { _graph.incidentEdges(ofIndex: index) }
    @inlinable public func incidentEdgeIndices(ofIndex index: Int) -> ArraySlice<Int> { _graph.incidentEdgeIndices(ofIndex: index) }

    @inlinable
    public func _withIncidentIndexRows<Result>(
        _ body: (
            _ neighbors: UnsafeBufferPointer<Int>, _ neighborRows: UnsafeBufferPointer<Int>,
            _ edges: UnsafeBufferPointer<Int>, _ edgeRows: UnsafeBufferPointer<Int>
        ) -> Result
    ) -> Result? {
        _graph._withIncidentIndexRows(body)
    }
}

// MARK: - Equatable, Hashable

extension BipartiteGraph: Equatable {
    /// Equal vertex sets, edge sets, and each vertex on the same side. Orders do not matter.
    @inlinable
    public static func == (lhs: BipartiteGraph, rhs: BipartiteGraph) -> Bool {
        guard lhs._left.count == rhs._left.count, lhs._graph == rhs._graph else { return false }
        // The same slots (a copy, or the same insertions): compare sides by slot, without hashing.
        if lhs._side == rhs._side, lhs.vertices.elementsEqual(rhs.vertices) { return true }
        for slot in lhs._left where rhs._side[rhs._graph.vertexIndex(of: lhs._graph.vertex(atIndex: slot))] != .left { return false }
        return true
    }
}

extension BipartiteGraph: Hashable {
    /// Hashes the graph and the left side, independently of order.
    @inlinable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(_graph)
        var leftHashes = 0
        for slot in _left {
            var h = Hasher()
            h.combine(_graph.vertex(atIndex: slot))
            leftHashes &+= h.finalize()
        }
        hasher.combine(_left.count)
        hasher.combine(leftHashes)
    }
}

extension BipartiteGraph: Sendable where Vertex: Sendable {}
extension BipartiteGraph.SideVertices: Sendable where Vertex: Sendable {}

// MARK: - Codable

extension BipartiteGraph: Encodable where Vertex: Encodable {
    /// Encodes `left`, `right`, then the edges as pairs of positions in `left` followed by `right`,
    /// left endpoint first. Decoding inserts `left` then `right`, so the decoded graph's `vertices`
    /// (and its vertex indices) are in that order; edge positions are kept.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: _BipartiteCodingKeys.self)
        try container.encode(Array(left), forKey: .left)
        try container.encode(Array(right), forKey: .right)
        var pairs: [Int] = []
        pairs.reserveCapacity(2 * edgeCount)
        for position in 0 ..< edgeCount {
            let (u, v) = _graph._edgeSlots(at: position)
            pairs.append(_sideOffset[u])
            pairs.append(_left.count + _sideOffset[v])
        }
        try container.encode(pairs, forKey: .edges)
    }
}

extension BipartiteGraph: Decodable where Vertex: Decodable {
    /// Throws `DecodingError.dataCorrupted` when the data breaks the invariant: a vertex on both
    /// sides or repeated, an index out of range, an edge inside a side, or a repeated edge.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: _BipartiteCodingKeys.self)
        let leftVertices = try container.decode([Vertex].self, forKey: .left)
        let rightVertices = try container.decode([Vertex].self, forKey: .right)
        let pairs = try container.decode([Int].self, forKey: .edges)
        guard pairs.count.isMultiple(of: 2) else {
            throw DecodingError.dataCorruptedError(forKey: .edges, in: container, debugDescription: "Edge list has odd length")
        }
        self.init()
        reserveCapacity(vertexCount: leftVertices.count + rightVertices.count, edgeCount: pairs.count / 2)
        for v in leftVertices {
            guard !contains(v) else { throw DecodingError.dataCorruptedError(forKey: .left, in: container, debugDescription: "Repeated vertex") }
            insert(v, on: .left)
        }
        for v in rightVertices {
            guard !contains(v) else { throw DecodingError.dataCorruptedError(forKey: .right, in: container, debugDescription: "Repeated vertex or a vertex on both sides") }
            insert(v, on: .right)
        }
        let all = leftVertices + rightVertices
        for i in stride(from: 0, to: pairs.count, by: 2) {
            guard all.indices.contains(pairs[i]), all.indices.contains(pairs[i + 1]) else {
                throw DecodingError.dataCorruptedError(forKey: .edges, in: container, debugDescription: "Edge endpoint out of range")
            }
            guard (pairs[i] < leftVertices.count) != (pairs[i + 1] < leftVertices.count) else {
                throw DecodingError.dataCorruptedError(forKey: .edges, in: container, debugDescription: "Edge inside a side")
            }
            guard insert(edge: UndirectedEdge(all[pairs[i]], all[pairs[i + 1]])).inserted else {
                throw DecodingError.dataCorruptedError(forKey: .edges, in: container, debugDescription: "Repeated edge")
            }
        }
    }
}

@usableFromInline
enum _BipartiteCodingKeys: String, CodingKey {
    case left
    case right
    case edges
}

// MARK: - Descriptions

extension BipartiteGraph: CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable {
    /// `[a, b] | [x]; [a–x, b–x]`: the left vertices, the right ones, and the edges, at most 16 of
    /// each.
    public var description: String {
        GraphDescription.list(left, count: left.count) { GraphDescription.vertex($0) } + " | "
            + GraphDescription.list(right, count: right.count) { GraphDescription.vertex($0) } + "; "
            + GraphDescription.list(edges, count: edgeCount) { GraphDescription.edge($0) }
    }

    /// The type, the counts, and at most 16 vertices of each side and edges.
    public var debugDescription: String {
        "BipartiteGraph<\(Vertex.self)>(vertexCount: \(vertexCount), edgeCount: \(edgeCount), left: "
            + GraphDescription.list(left, count: left.count) { String(reflecting: $0) }
            + ", right: "
            + GraphDescription.list(right, count: right.count) { String(reflecting: $0) }
            + ", edges: "
            + GraphDescription.list(edges, count: edgeCount) { GraphDescription.edge($0) }
            + ")"
    }

    /// Shows `left`, `right` and `edges` as children.
    public var customMirror: Mirror {
        Mirror(self, children: ["left": Array(left), "right": Array(right), "edges": Array(edges)], displayStyle: .struct)
    }
}
