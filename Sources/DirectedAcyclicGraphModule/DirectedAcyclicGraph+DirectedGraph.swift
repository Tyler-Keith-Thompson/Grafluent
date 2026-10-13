import GraphProtocols

// Every read requirement, `generation`, and over a `PropertyGraph` base the attached-map reads,
// are `GraphDelegator`'s defaults: the base's members, with the base's own types. Attaching,
// detaching and writing maps are below, on the stored base. Positions and indices are the base's,
// so data kept by position and the base's maps stay valid through the wrapper. Removing a vertex
// or an edge through the wrapper removes its values, as removing it from the base does.

extension DirectedAcyclicGraph: GraphDelegator, DirectedGraph, BidirectionalDirectedGraph {
    public typealias Vertex = Base.Vertex
    public typealias Vertices = Base.Vertices
    public typealias Edges = Base.Edges
    public typealias Successors = Base.Successors
    public typealias OutEdges = Base.OutEdges
    public typealias SuccessorIndices = Base.SuccessorIndices
    public typealias Predecessors = Base.Predecessors
    public typealias InEdges = Base.InEdges
    public typealias PredecessorIndices = Base.PredecessorIndices

    /// The wrapped graph, read-only: writing it directly could close a cycle or leave the order
    /// stale.
    @inlinable
    public var base: Base {
        _read { yield _base }
    }
}

extension DirectedAcyclicGraph: SparselyIndexedDirectedGraph where Base: SparselyIndexedDirectedGraph {}

extension DirectedAcyclicGraph: PropertyGraph where Base: PropertyGraph {
    public typealias EdgePosition = Base.EdgePosition

    /// Attaches a map from vertices to `Value`, every vertex's value `value`, to the base, and
    /// returns its handle. The base's cost.
    @inlinable
    public mutating func addVertexMap<Value: Sendable>(default value: Value) -> VertexMap<Value> {
        _base.addVertexMap(default: value)
    }

    /// Attaches a map from edge positions to `Value`, every edge's value `value`, to the base, and
    /// returns its handle. The base's cost.
    @inlinable
    public mutating func addEdgeMap<Value: Sendable>(default value: Value) -> EdgeMap<Value> {
        _base.addEdgeMap(default: value)
    }

    /// Detaches the vertex map from the base and frees its storage.
    ///
    /// - Precondition: `map` is attached to this graph.
    @inlinable
    public mutating func removeVertexMap<Value>(_ map: VertexMap<Value>) {
        _base.removeVertexMap(map)
    }

    /// Detaches the edge map from the base and frees its storage.
    ///
    /// - Precondition: `map` is attached to this graph.
    @inlinable
    public mutating func removeEdgeMap<Value>(_ map: EdgeMap<Value>) {
        _base.removeEdgeMap(map)
    }

    /// The base's value of the vertex at `position` in `map`. The base's cost.
    ///
    /// - Precondition: `map` is attached to this graph, and a vertex is at `position`.
    @inlinable
    public subscript<Value>(map: VertexMap<Value>, ofVertexAt position: Int) -> Value {
        get { _base[map, ofVertexAt: position] }
        set { _base[map, ofVertexAt: position] = newValue }
    }

    /// The base's value of `vertex` in `map`. The base's cost.
    ///
    /// - Precondition: `map` is attached to this graph, and `vertex` is a vertex.
    @inlinable
    public subscript<Value>(map: VertexMap<Value>, of vertex: Vertex) -> Value {
        get { _base[map, of: vertex] }
        set { _base[map, of: vertex] = newValue }
    }

    /// The base's value of the edge at `position` in `map`. The base's cost.
    ///
    /// - Precondition: `map` is attached to this graph, and an edge is at `position`.
    @inlinable
    public subscript<Value>(map: EdgeMap<Value>, ofEdgeAt position: EdgePosition) -> Value {
        get { _base[map, ofEdgeAt: position] }
        set { _base[map, ofEdgeAt: position] = newValue }
    }
}

// MARK: - checked: lookups

// Each throws `VertexNotFound` for a vertex that is not in the graph. Each is one hash and then
// the base's row, for every base, including one without `checked:` members of its own.

extension DirectedAcyclicGraph {
    /// `successors(of: vertex)`, throwing instead of trapping when `vertex` is not a vertex. One
    /// hash.
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not a vertex.
    @inlinable
    public func successors(checked vertex: Vertex) throws(VertexNotFound) -> Base.Successors {
        guard let key = _base._key(of: vertex) else { throw VertexNotFound() }
        return _base._successors(ofKey: key)
    }

    /// `predecessors(of: vertex)`, throwing instead of trapping when `vertex` is not a vertex. One
    /// hash.
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not a vertex.
    @inlinable
    public func predecessors(checked vertex: Vertex) throws(VertexNotFound) -> Base.Predecessors {
        guard let key = _base._key(of: vertex) else { throw VertexNotFound() }
        return _base._predecessors(ofKey: key)
    }

    /// `outEdges(of: vertex)`, throwing instead of trapping when `vertex` is not a vertex. One
    /// hash.
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not a vertex.
    @inlinable
    public func outEdges(checked vertex: Vertex) throws(VertexNotFound) -> Base.OutEdges {
        guard let key = _base._key(of: vertex) else { throw VertexNotFound() }
        return _base._outEdges(ofKey: key)
    }

    /// `inEdges(of: vertex)`, throwing instead of trapping when `vertex` is not a vertex. One
    /// hash.
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not a vertex.
    @inlinable
    public func inEdges(checked vertex: Vertex) throws(VertexNotFound) -> Base.InEdges {
        guard let key = _base._key(of: vertex) else { throw VertexNotFound() }
        return _base._inEdges(ofKey: key)
    }

    /// `outDegree(of: vertex)`, throwing instead of trapping when `vertex` is not a vertex. One
    /// hash.
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not a vertex.
    @inlinable
    public func outDegree(checked vertex: Vertex) throws(VertexNotFound) -> Int {
        guard let key = _base._key(of: vertex) else { throw VertexNotFound() }
        return _base._outDegree(ofKey: key)
    }

    /// `inDegree(of: vertex)`, throwing instead of trapping when `vertex` is not a vertex. One
    /// hash.
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not a vertex.
    @inlinable
    public func inDegree(checked vertex: Vertex) throws(VertexNotFound) -> Int {
        guard let key = _base._key(of: vertex) else { throw VertexNotFound() }
        return _base._inDegree(ofKey: key)
    }
}

// MARK: - The order

extension DirectedAcyclicGraph {
    /// Every vertex once, each edge going from an earlier vertex to a later one. O(1).
    ///
    /// A value that shares the graph's storage: while it is alive, the graph's next mutation
    /// copies the base and the order once, as holding a copy of the graph would. Read it and drop
    /// it before mutating, or copy it to an `Array`.
    @inlinable
    public var topologicalOrder: TopologicalOrder {
        TopologicalOrder(base: _base, order: _order, table: _table)
    }

    /// The place of `vertex` in `topologicalOrder`, in `0..<vertexCount`.
    ///
    /// - Complexity: One hash, then O(1) while the order has no holes and O(log n) otherwise (see
    ///   the type's documentation).
    ///
    /// - Precondition: `vertex` is a vertex.
    @inlinable
    public func topologicalPosition(of vertex: Vertex) -> Int {
        guard let key = _base._key(of: vertex) else { preconditionFailure("\(vertex) is not a vertex of this graph") }
        return _position(ofKey: key)
    }

    /// `topologicalPosition(of: vertex)`, throwing instead of trapping when `vertex` is not a
    /// vertex.
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not a vertex.
    @inlinable
    public func topologicalPosition(checked vertex: Vertex) throws(VertexNotFound) -> Int {
        guard let key = _base._key(of: vertex) else { throw VertexNotFound() }
        return _position(ofKey: key)
    }

    /// The vertices in topological order. `topologicalOrder[i]` is the vertex at place `i`.
    ///
    /// A value, unaffected by later changes to the graph. The subscript is O(1) without holes and
    /// O(log n) with them. Iteration is O(1) per vertex either way.
    @frozen
    public struct TopologicalOrder: RandomAccessCollection {
        @usableFromInline let base: Base
        @usableFromInline let order: _TopologicalSlots
        @usableFromInline let table: _KeyTable

        @inlinable
        init(base: Base, order: _TopologicalSlots, table: _KeyTable) {
            self.base = base
            self.order = order
            self.table = table
        }

        public typealias Index = Int
        public typealias Element = Base.Vertex
        public typealias Indices = Range<Int>

        @inlinable public var startIndex: Int { 0 }
        @inlinable public var endIndex: Int { order.count }

        /// The vertex at place `position`.
        ///
        /// - Precondition: `position` is in `0..<count`.
        @inlinable
        public subscript(position: Int) -> Base.Vertex {
            precondition(UInt(bitPattern: position) < UInt(bitPattern: order.count), "Index out of range")
            return base._vertex(atKey: order.slots[order.slot(atPlace: position)])
        }

        /// The vertices in order, skipping holes.
        @frozen
        public struct Iterator: IteratorProtocol {
            @usableFromInline let base: Base
            @usableFromInline let slots: ContiguousArray<Int>
            @usableFromInline var slot: Int

            @inlinable
            init(base: Base, slots: ContiguousArray<Int>, slot: Int) {
                self.base = base
                self.slots = slots
                self.slot = slot
            }

            @inlinable
            public mutating func next() -> Base.Vertex? {
                while slot < slots.count {
                    let key = slots[slot]
                    slot &+= 1
                    if key >= 0 { return base._vertex(atKey: key) }
                }
                return nil
            }
        }

        @inlinable
        public func makeIterator() -> Iterator { Iterator(base: base, slots: order.slots, slot: order.first) }

        @inlinable
        public var underestimatedCount: Int { order.count }

        /// The vertex's place: one hash, then as `topologicalPosition(of:)`.
        @inlinable
        public func firstIndex(of element: Base.Vertex) -> Int? {
            base._key(of: element).map { order.place(ofSlot: table.label($0)) }
        }

        /// `firstIndex(of:)`: each vertex appears once.
        @inlinable
        public func lastIndex(of element: Base.Vertex) -> Int? { firstIndex(of: element) }

        @inlinable
        public func _customContainsEquatableElement(_ element: Base.Vertex) -> Bool? {
            base._key(of: element) != nil
        }

        @inlinable
        public func _customIndexOfEquatableElement(_ element: Base.Vertex) -> Int?? {
            .some(firstIndex(of: element))
        }

        @inlinable
        public func _customLastIndexOfEquatableElement(_ element: Base.Vertex) -> Int?? {
            .some(firstIndex(of: element))
        }
    }
}

extension DirectedAcyclicGraph.TopologicalOrder: Sendable where Base: Sendable {}
extension DirectedAcyclicGraph.TopologicalOrder.Iterator: Sendable where Base: Sendable {}
