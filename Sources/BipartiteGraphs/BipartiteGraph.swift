import AdjacencyListModule
import GraphProtocols

/// An undirected graph with two fixed sides, every edge joining a left vertex to a right vertex.
///
/// The graph is simple and has no self-loop. An edge is inserted once, in either orientation, and
/// is stored left endpoint first, so `edges[e].u` is its left end.
///
/// Every initializer from unchecked input is failable, and a mutation that would break the
/// bipartition throws `BipartitionError` and changes nothing. Whether an edge may be inserted is an
/// O(1) test with `side(of:)`.
///
/// `BipartiteGraph` wraps an `UndirectedAdjacencyList` as a `GraphDelegator` (`base` reads it), and
/// storage and mutation costs are the list's. Vertex indices are slots (`vertices` order) and edge
/// indices are positions. A removal moves the last slot or edge into the hole, so orders and
/// positions change after a removal. Every read is the base's, and so are attached maps
/// (`PropertyGraph`, which follow those moves) and `generation`. Equality compares vertex sets,
/// edge sets and each vertex's side, not orders, and ignores maps.
@frozen
public struct BipartiteGraph<Vertex: Hashable> {
    /// The wrapped graph. Writable only inside this module, where every write keeps the
    /// bipartition; `base` reads it.
    @usableFromInline var _base: UndirectedAdjacencyList<Vertex>
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
        _base = UndirectedAdjacencyList()
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
        for v in left where _base._slotIfPresent(of: v) == nil { _appendVertex(v, on: .left) }
        for v in right {
            if let slot = _base._slotIfPresent(of: v) {
                if _side[slot] == .left { return nil }
            } else {
                _appendVertex(v, on: .right)
            }
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
            guard let u = _base._slotIfPresent(of: edge.u), let v = _base._slotIfPresent(of: edge.v), _side[u] != _side[v] else { return nil }
            if _side[u] == .left { _base._insertEdge(slots: u, v) } else { _base._insertEdge(slots: v, u) }
        }
    }

    /// The graph's vertices (in order), edges (in position order, so at their positions when the
    /// graph has no parallel edges; repeats dropped), and the canonical sides of `bipartition()`.
    /// nil when the graph is not bipartite: `graph.findOddCycle()` is then the witness. O(n + m).
    /// An `UndirectedAdjacencyList` keeps its storage, attached maps included, with each edge
    /// turned to put its left end first; `base` reads it back.
    @inlinable
    public init?(_ graph: some Graph<Vertex>) {
        guard let sides = graph._runOnUndirectedRows(_TwoColoring(witness: false)).sides else { return nil }
        // An adjacency list is the storage itself, each edge turned to put its left end first.
        if var list = graph as? UndirectedAdjacencyList<Vertex> {
            for position in 0 ..< list.edgeCount where sides[list._edgeSlots(at: position).u] != 0 {
                list._reverseEdge(at: position)
            }
            self.init()
            _base = list
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
        for (k, v) in graph.vertices.enumerated() { _appendVertex(v, on: sides[k] == 0 ? .left : .right) }
        // Numbered as `vertices`, so the slots are the vertex numbers: with vertex indices, which
        // follow `vertices` order, the graph's own ends without a lookup.
        let indexed = graph.vertexIndexBound != nil
        for position in graph.edges.indices {
            let u: Int, v: Int
            if indexed {
                (u, v) = graph.endpointIndices(ofEdgeAt: position)
            } else {
                let edge = graph.edges[position]
                (u, v) = (_base.vertexIndex(of: edge.u), _base.vertexIndex(of: edge.v))
            }
            if _side[u] == .left { _base._insertEdge(slots: u, v) } else { _base._insertEdge(slots: v, u) }
        }
    }

    /// The graph's vertices and edges with `left` as the left side and every other vertex on the
    /// right. Repeats in `left` are one vertex. `nil` unless every edge goes across, or when `left`
    /// names a non-vertex.
    @inlinable
    public init?(_ graph: some Graph<Vertex>, left: some Sequence<Vertex>) {
        var leftSet = Set<Vertex>()
        for v in left {
            guard graph.contains(v) else { return nil }
            leftSet.insert(v)
        }
        self.init()
        reserveCapacity(vertexCount: graph.vertexCount, edgeCount: graph.edgeCount)
        for v in graph.vertices { _appendVertex(v, on: leftSet.contains(v) ? .left : .right) }
        for edge in graph.edges {
            guard leftSet.contains(edge.u) != leftSet.contains(edge.v) else { return nil }
            _insertCrossEdge(_base.vertexIndex(of: edge.u), _base.vertexIndex(of: edge.v))
        }
    }

    /// The left vertices, in insertion order (a removal moves the side's last vertex into the hole).
    @inlinable
    public var left: SideVertices { SideVertices(graph: _base, slots: _left) }

    /// The right vertices, in insertion order (a removal moves the side's last vertex into the hole).
    @inlinable
    public var right: SideVertices { SideVertices(graph: _base, slots: _right) }

    /// The side of `vertex`. O(1).
    ///
    /// - Precondition: `vertex` is a vertex of the graph.
    @inlinable
    public func side(of vertex: Vertex) -> BipartiteSide {
        guard let slot = _base._slotIfPresent(of: vertex) else { preconditionFailure("\(vertex) is not a vertex of the graph") }
        return _side[slot]
    }

    /// Inserts `vertex` on `side` with no edges.
    ///
    /// - Returns: Whether it was inserted, and the vertex now in the graph (the existing one when it
    ///   was already on `side`).
    /// - Throws: `BipartitionError.onOtherSide(s)` when `vertex` is already a vertex on the other
    ///   side `s`; then nothing changes.
    @inlinable
    @discardableResult
    public mutating func insert(_ vertex: Vertex, on side: BipartiteSide) throws(BipartitionError) -> (inserted: Bool, memberAfterInsert: Vertex) {
        if let slot = _base._slotIfPresent(of: vertex) {
            guard _side[slot] == side else { throw .onOtherSide(_side[slot]) }
            return (false, _base.vertex(atIndex: slot))
        }
        _appendVertex(vertex, on: side)
        return (true, vertex)
    }

    /// Appends `vertex`, which is not a vertex, on `side`.
    @inlinable
    internal mutating func _appendVertex(_ vertex: Vertex, on side: BipartiteSide) {
        _base.insert(vertex)
        let slot = _side.count
        _side.append(side)
        if side == .left {
            _sideOffset.append(_left.count)
            _left.append(slot)
        } else {
            _sideOffset.append(_right.count)
            _right.append(slot)
        }
    }

    /// Inserts `edge`, stored left endpoint first.
    ///
    /// - Returns: Whether it was inserted, and the edge now in the graph, left endpoint first (the
    ///   existing one when it was already an edge, in either orientation).
    /// - Throws: `BipartitionError.sameSide(s)` when both endpoints are on side `s`, a self-loop
    ///   included; then nothing changes.
    /// - Precondition: Both endpoints are vertices. `insert(checked:)` throws instead.
    @inlinable
    @discardableResult
    public mutating func insert(edge: UndirectedEdge<Vertex>) throws(BipartitionError) -> (inserted: Bool, memberAfterInsert: UndirectedEdge<Vertex>) {
        guard let u = _base._slotIfPresent(of: edge.u), let v = _base._slotIfPresent(of: edge.v) else {
            preconditionFailure("An endpoint of \(edge) is not a vertex")
        }
        guard _side[u] != _side[v] else { throw .sameSide(_side[u]) }
        return _insertCrossEdge(u, v)
    }

    /// Inserts `edge`, stored left endpoint first, when both endpoints are vertices on different
    /// sides. Costs as `insert(edge:)`.
    ///
    /// - Returns: As `insert(edge:)`.
    /// - Throws: `BipartitionError.missingEndpoint` when an endpoint is not a vertex (checked
    ///   first), then `.sameSide(s)` as `insert(edge:)` does. Nothing changes when it throws.
    @inlinable
    @discardableResult
    public mutating func insert(checked edge: UndirectedEdge<Vertex>) throws(BipartitionError) -> (inserted: Bool, memberAfterInsert: UndirectedEdge<Vertex>) {
        guard let u = _base._slotIfPresent(of: edge.u), let v = _base._slotIfPresent(of: edge.v) else {
            throw .missingEndpoint
        }
        guard _side[u] != _side[v] else { throw .sameSide(_side[u]) }
        return _insertCrossEdge(u, v)
    }

    /// Inserts the edge between slots `u` and `v`, which are on different sides, left one first.
    @inlinable
    @discardableResult
    internal mutating func _insertCrossEdge(_ u: Int, _ v: Int) -> (inserted: Bool, memberAfterInsert: UndirectedEdge<Vertex>) {
        _side[u] == .left ? _base._insertEdge(slots: u, v) : _base._insertEdge(slots: v, u)
    }

    /// Removes `vertex` and its edges. O(degree), plus the degree of the vertex that moves into its
    /// slot.
    ///
    /// - Returns: The removed vertex, or nil if it was not a vertex.
    @inlinable
    @discardableResult
    public mutating func remove(_ vertex: Vertex) -> Vertex? {
        guard let slot = _base._slotIfPresent(of: vertex) else { return nil }
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
        let removed = _base.remove(vertex)
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
        _base.remove(edge: edge)
    }

    /// Removes every vertex and edge.
    @inlinable
    public mutating func removeAll(keepingCapacity: Bool = false) {
        _base.removeAll(keepingCapacity: keepingCapacity)
        _side.removeAll(keepingCapacity: keepingCapacity)
        _left.removeAll(keepingCapacity: keepingCapacity)
        _right.removeAll(keepingCapacity: keepingCapacity)
        _sideOffset.removeAll(keepingCapacity: keepingCapacity)
    }

    /// Removes every edge; the vertices keep their sides.
    @inlinable
    public mutating func removeAllEdges(keepingCapacity: Bool = false) {
        _base.removeAllEdges(keepingCapacity: keepingCapacity)
    }

    /// Reserves room for this many vertices and edges.
    @inlinable
    public mutating func reserveCapacity(vertexCount: Int, edgeCount: Int) {
        _base.reserveCapacity(vertexCount: vertexCount, edgeCount: edgeCount)
        _side.reserveCapacity(vertexCount)
        _sideOffset.reserveCapacity(vertexCount)
        _left.reserveCapacity(vertexCount)
        _right.reserveCapacity(vertexCount)
    }

    /// The graph on one side's vertices (in `left` or `right` order, isolated ones included), with an
    /// edge between two vertices that share a neighbor, once however many they share.
    ///
    /// Edges are inserted as found: for each vertex u in side order, each neighbor w in u's row,
    /// each x ≠ u in w's row.
    ///
    /// - Complexity: O(Σ_{u ∈ side} Σ_{w ∈ N(u)} deg(w)).
    @inlinable
    public func projectedGraph(onto side: BipartiteSide) -> UndirectedAdjacencyList<Vertex> {
        let slots = side == .left ? _left : _right
        // Each pair once, from its earlier vertex in side order: x is skipped unless it comes
        // after u, so `insert(edge:)` runs once per projected edge.
        var lastSeen = [Int](repeating: -1, count: _side.count)
        // The bounds in 64 bits: Σ deg(w)² and c(c − 1)/2 pass a 32-bit `Int` long before the
        // projection itself would.
        var bound: Int64 = 0
        for u in slots { for w in _base.neighborIndices(ofIndex: u) { bound += Int64(_base.neighborIndices(ofIndex: w).count - 1) } }
        let pairs = Int64(slots.count) * Int64(max(slots.count - 1, 0)) / 2
        var result = UndirectedAdjacencyList<Vertex>()
        result.reserveCapacity(vertexCount: slots.count, edgeCount: Int(clamping: min(bound / 2, pairs)))
        for u in slots { result.insert(_base.vertex(atIndex: u)) }
        // In `result`, side position k is slot k.
        for (k, u) in slots.enumerated() {
            for w in _base.neighborIndices(ofIndex: u) {
                for x in _base.neighborIndices(ofIndex: w) {
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

// `GraphDelegator`'s defaults would forward these too, but its base is another module's type: a
// call to a default from inlinable code in a module that does not import AdjacencyListModule
// (MatchingModule, ColoringModule, Covering) would need `UndirectedAdjacencyList`'s conformance,
// which that file cannot name. Concrete members forward without it, at the same speed.

extension BipartiteGraph: GraphDelegator, Graph {
    public typealias Base = UndirectedAdjacencyList<Vertex>
    public typealias Vertices = Base.Vertices
    public typealias Edges = Base.Edges
    public typealias Neighbors = Base.Neighbors
    public typealias IncidentEdges = Base.IncidentEdges
    public typealias NeighborIndices = Base.NeighborIndices
    public typealias IncidentEdgeIndices = Base.IncidentEdgeIndices

    /// The wrapped graph, read-only: writing it directly could join two vertices on one side.
    @inlinable public var base: Base { _read { yield _base } }
    /// The base's generation: every insertion and removal starts a new one; reserving capacity,
    /// a mutation that throws, and attaching or writing maps do not.
    @inlinable public var generation: GraphGeneration { _base.generation }
    @inlinable public var vertices: Vertices { _base.vertices }
    @inlinable public var edges: Edges { _base.edges }
    @inlinable public var vertexCount: Int { _base.vertexCount }
    @inlinable public var edgeCount: Int { _base.edgeCount }
    @inlinable public func contains(_ vertex: Vertex) -> Bool { _base.contains(vertex) }
    @inlinable public func contains(edge: UndirectedEdge<Vertex>) -> Bool { _base.contains(edge: edge) }
    @inlinable public func neighbors(of vertex: Vertex) -> Neighbors { _base.neighbors(of: vertex) }
    @inlinable public func incidentEdges(of vertex: Vertex) -> IncidentEdges { _base.incidentEdges(of: vertex) }
    @inlinable public func oppositeVertex(to vertex: Vertex, acrossEdgeAt position: Int) -> Vertex { _base.oppositeVertex(to: vertex, acrossEdgeAt: position) }
    @inlinable public func degree(of vertex: Vertex) -> Int { _base.degree(of: vertex) }
    @inlinable public var vertexIndexBound: Int? { _base.vertexIndexBound }
    @inlinable public func vertexIndex(of vertex: Vertex) -> Int { _base.vertexIndex(of: vertex) }
    @inlinable public func vertex(atIndex index: Int) -> Vertex { _base.vertex(atIndex: index) }
    @inlinable public func neighborIndices(ofIndex index: Int) -> NeighborIndices { _base.neighborIndices(ofIndex: index) }
    @inlinable public var edgeIndexBound: Int? { _base.edgeIndexBound }
    @inlinable public func edgeIndex(of position: Int) -> Int { position }
    @inlinable public func incidentEdges(ofIndex index: Int) -> IncidentEdges { _base.incidentEdges(ofIndex: index) }
    @inlinable public func incidentEdgeIndices(ofIndex index: Int) -> IncidentEdgeIndices { _base.incidentEdgeIndices(ofIndex: index) }
    @inlinable public func degree(ofIndex index: Int) -> Int { _base.degree(ofIndex: index) }
    @inlinable public func endpointIndices(ofEdgeAt position: Int) -> (u: Int, v: Int) { _base.endpointIndices(ofEdgeAt: position) }

    /// The base's: the rows are the base's.
    @inlinable
    public static var _lendsIncidentRowsInConstantTime: Bool { UndirectedAdjacencyList<Vertex>._lendsIncidentRowsInConstantTime }

    @inlinable
    public func _withIncidentIndexRows<Result>(
        _ body: (
            _ neighbors: UnsafeBufferPointer<Int>, _ neighborRows: UnsafeBufferPointer<Int>,
            _ edges: UnsafeBufferPointer<Int>, _ edgeRows: UnsafeBufferPointer<Int>
        ) -> Result
    ) -> Result? {
        _base._withIncidentIndexRows(body)
    }
}

// MARK: - Attached maps

// The base's maps (`UndirectedAdjacencyList`'s: dense, one value per slot and per edge position),
// so they move with every removal as the base's arrays do. Concrete for the reason above.

extension BipartiteGraph: PropertyGraph {
    public typealias EdgePosition = Int

    @inlinable public static var _vertexMapLayout: _MapLayout { Base._vertexMapLayout }
    @inlinable public static var _edgeMapLayout: _MapLayout { Base._edgeMapLayout }
    @inlinable public static func _edgeMapOffset(of position: Int) -> Int { Base._edgeMapOffset(of: position) }

    /// Attaches a map from edge positions to `Value`, every edge's value `value`, and returns its
    /// handle: the base's `addEdgeMap(default:)`. A new edge has `value`, and when a removal moves
    /// the last edge into the removed one's position, its value moves too. O(`edgeCount`).
    ///
    /// Map contents take no part in equality, hashing or `Codable`.
    @inlinable
    public mutating func addEdgeMap<Value: Sendable>(default value: Value) -> EdgeMap<Value> { _base.addEdgeMap(default: value) }

    /// Attaches a map from vertices to `Value`, every vertex's value `value`, and returns its
    /// handle; it moves with the vertices' slots, on either side. O(`vertexCount`).
    @inlinable
    public mutating func addVertexMap<Value: Sendable>(default value: Value) -> VertexMap<Value> { _base.addVertexMap(default: value) }

    /// Detaches the edge map and frees its storage.
    ///
    /// - Precondition: `map` is attached to this graph.
    @inlinable
    public mutating func removeEdgeMap<Value>(_ map: EdgeMap<Value>) { _base.removeEdgeMap(map) }

    /// Detaches the vertex map and frees its storage.
    ///
    /// - Precondition: `map` is attached to this graph.
    @inlinable
    public mutating func removeVertexMap<Value>(_ map: VertexMap<Value>) { _base.removeVertexMap(map) }

    /// The value of the edge at `position` in `map`. O(1).
    ///
    /// - Precondition: `map` is attached to this graph, and `position` is in `0..<edgeCount`.
    @inlinable
    public subscript<Value>(_ map: EdgeMap<Value>, ofEdgeAt position: Int) -> Value {
        get { _base[map, ofEdgeAt: position] }
        set { _base[map, ofEdgeAt: position] = newValue }
    }

    /// The value of the vertex in slot `position` in `map`. O(1).
    ///
    /// - Precondition: `map` is attached to this graph, and `position` is in `0..<vertexCount`.
    @inlinable
    public subscript<Value>(_ map: VertexMap<Value>, ofVertexAt position: Int) -> Value {
        get { _base[map, ofVertexAt: position] }
        set { _base[map, ofVertexAt: position] = newValue }
    }

    /// The value of `vertex` in `map`. One hash.
    ///
    /// - Precondition: `map` is attached to this graph, and `vertex` is a vertex.
    @inlinable
    public subscript<Value>(_ map: VertexMap<Value>, of vertex: Vertex) -> Value {
        get { _base[map, of: vertex] }
        set { _base[map, of: vertex] = newValue }
    }

    /// The value of the edge at `position` in `map`, throwing instead of trapping when no edge is
    /// there.
    ///
    /// - Precondition: `map` is attached to this graph.
    /// - Throws: `EdgeNotFound` when `position` is not in `0..<edgeCount`.
    @inlinable
    public subscript<Value>(_ map: EdgeMap<Value>, checkedEdgeAt position: Int) -> Value {
        get throws(EdgeNotFound) { try _base[map, checkedEdgeAt: position] }
    }

    /// The value of the vertex in slot `position` in `map`, throwing instead of trapping when no
    /// vertex is there.
    ///
    /// - Precondition: `map` is attached to this graph.
    /// - Throws: `VertexNotFound` when `position` is not in `0..<vertexCount`.
    @inlinable
    public subscript<Value>(_ map: VertexMap<Value>, checkedVertexAt position: Int) -> Value {
        get throws(VertexNotFound) { try _base[map, checkedVertexAt: position] }
    }

    /// The value of `vertex` in `map`, throwing instead of trapping when `vertex` is not a vertex.
    /// One hash.
    ///
    /// - Precondition: `map` is attached to this graph.
    /// - Throws: `VertexNotFound` when `vertex` is not a vertex.
    @inlinable
    public subscript<Value>(_ map: VertexMap<Value>, checked vertex: Vertex) -> Value {
        get throws(VertexNotFound) { try _base[map, checked: vertex] }
    }

    /// The values of `map` by edge position: a snapshot, O(1) to make, read as a plain array.
    ///
    /// - Precondition: `map` is attached to this graph.
    @inlinable
    public func values<Value>(of map: EdgeMap<Value>) -> EdgeValues<Self, Value> { EdgeValues(_base.values(of: map)) }

    /// The values of `map` by vertex index (slot): a snapshot, O(1) to make.
    ///
    /// - Precondition: `map` is attached to this graph.
    @inlinable
    public func values<Value>(of map: VertexMap<Value>) -> VertexValues<Self, Value> { VertexValues(_base.values(of: map)) }
}

// MARK: - checked: lookups

// Each throws `VertexNotFound` for a vertex that is not in the graph. Each is one hash, the same
// as its trapping spelling, and then the underlying list's row.

extension BipartiteGraph {
    /// `side(of: vertex)`, throwing instead of trapping when `vertex` is not a vertex. O(1).
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not a vertex.
    @inlinable
    public func side(checked vertex: Vertex) throws(VertexNotFound) -> BipartiteSide {
        guard let slot = _base._slotIfPresent(of: vertex) else { throw VertexNotFound() }
        return _side[slot]
    }

    /// `neighbors(of: vertex)`, throwing instead of trapping when `vertex` is not a vertex. O(1) to
    /// make.
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not a vertex.
    @inlinable
    public func neighbors(checked vertex: Vertex) throws(VertexNotFound) -> Neighbors {
        try _base.neighbors(checked: vertex)
    }

    /// `incidentEdges(of: vertex)`, throwing instead of trapping when `vertex` is not a vertex.
    /// O(1).
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not a vertex.
    @inlinable
    public func incidentEdges(checked vertex: Vertex) throws(VertexNotFound) -> ArraySlice<Int> {
        try _base.incidentEdges(checked: vertex)
    }

    /// `degree(of: vertex)`, throwing instead of trapping when `vertex` is not a vertex. O(1).
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not a vertex.
    @inlinable
    public func degree(checked vertex: Vertex) throws(VertexNotFound) -> Int {
        try _base.degree(checked: vertex)
    }

    /// `vertexIndex(of: vertex)`, throwing instead of trapping when `vertex` is not a vertex. O(1).
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not a vertex.
    @inlinable
    public func vertexIndex(checked vertex: Vertex) throws(VertexNotFound) -> Int {
        try _base.vertexIndex(checked: vertex)
    }
}

// MARK: - Equatable, Hashable

extension BipartiteGraph: Equatable {
    /// Equal vertex sets, edge sets, and each vertex on the same side. Orders do not matter.
    @inlinable
    public static func == (lhs: BipartiteGraph, rhs: BipartiteGraph) -> Bool {
        guard lhs._left.count == rhs._left.count, lhs._base == rhs._base else { return false }
        // The same slots (a copy, or the same insertions): compare sides by slot, without hashing.
        if lhs._side == rhs._side, lhs.vertices.elementsEqual(rhs.vertices) { return true }
        for slot in lhs._left where rhs._side[rhs._base.vertexIndex(of: lhs._base.vertex(atIndex: slot))] != .left { return false }
        return true
    }
}

extension BipartiteGraph: Hashable {
    /// Hashes the graph and the left side, independently of order.
    @inlinable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(_base)
        var leftHashes = 0
        for slot in _left {
            var h = Hasher()
            h.combine(_base.vertex(atIndex: slot))
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
            let (u, v) = _base._edgeSlots(at: position)
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
            _appendVertex(v, on: .left)
        }
        for v in rightVertices {
            guard !contains(v) else { throw DecodingError.dataCorruptedError(forKey: .right, in: container, debugDescription: "Repeated vertex or a vertex on both sides") }
            _appendVertex(v, on: .right)
        }
        let all = leftVertices + rightVertices
        for i in stride(from: 0, to: pairs.count, by: 2) {
            guard all.indices.contains(pairs[i]), all.indices.contains(pairs[i + 1]) else {
                throw DecodingError.dataCorruptedError(forKey: .edges, in: container, debugDescription: "Edge endpoint out of range")
            }
            guard (pairs[i] < leftVertices.count) != (pairs[i + 1] < leftVertices.count) else {
                throw DecodingError.dataCorruptedError(forKey: .edges, in: container, debugDescription: "Edge inside a side")
            }
            guard _insertCrossEdge(_base.vertexIndex(of: all[pairs[i]]), _base.vertexIndex(of: all[pairs[i + 1]])).inserted else {
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
