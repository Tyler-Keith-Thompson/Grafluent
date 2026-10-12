import GraphProtocols

// Every requirement is the base's, `@inlinable`, with the base's own types (`SuccessorIndices`,
// `OutEdges`, `Edges`, …), as `DirectedGraph` requires of a wrapper: a protocol default would map
// each neighbor through `vertexIndex(of:)`, a hash per edge, or ignore the base's faster member.
// Positions and indices are the base's, so data kept by position stays valid through the wrapper.

extension DirectedAcyclicGraph: DirectedGraph {
    public typealias Vertex = Base.Vertex
    public typealias Vertices = Base.Vertices
    public typealias Edges = Base.Edges
    public typealias Successors = Base.Successors
    public typealias OutEdges = Base.OutEdges
    public typealias SuccessorIndices = Base.SuccessorIndices

    /// The base's vertices, in the base's order (not the topological order). O(1).
    @inlinable public var vertices: Base.Vertices { _base.vertices }
    /// The base's edges, at the base's positions. O(1).
    @inlinable public var edges: Base.Edges { _base.edges }
    @inlinable public func successors(of vertex: Vertex) -> Base.Successors { _base.successors(of: vertex) }
    @inlinable public func outEdges(of vertex: Vertex) -> Base.OutEdges { _base.outEdges(of: vertex) }
    @inlinable public func source(ofEdgeAt position: Edges.Index) -> Vertex { _base.source(ofEdgeAt: position) }
    @inlinable public func target(ofEdgeAt position: Edges.Index) -> Vertex { _base.target(ofEdgeAt: position) }
    @inlinable public var vertexCount: Int { _base.vertexCount }
    @inlinable public var edgeCount: Int { _base.edgeCount }
    @inlinable public func contains(_ vertex: Vertex) -> Bool { _base.contains(vertex) }
    @inlinable public func contains(edge: DirectedEdge<Vertex>) -> Bool { _base.contains(edge: edge) }
    @inlinable public func outDegree(of vertex: Vertex) -> Int { _base.outDegree(of: vertex) }
    @inlinable public var vertexIndexBound: Int? { _base.vertexIndexBound }
    @inlinable public func vertexIndex(of vertex: Vertex) -> Int { _base.vertexIndex(of: vertex) }
    @inlinable public func vertex(atIndex index: Int) -> Vertex { _base.vertex(atIndex: index) }
    @inlinable public func successorIndices(ofIndex index: Int) -> Base.SuccessorIndices { _base.successorIndices(ofIndex: index) }
    @inlinable public func outEdges(ofIndex index: Int) -> Base.OutEdges { _base.outEdges(ofIndex: index) }
    @inlinable public func outDegree(ofIndex index: Int) -> Int { _base.outDegree(ofIndex: index) }
    @inlinable public func sourceIndex(ofEdgeAt position: Edges.Index) -> Int { _base.sourceIndex(ofEdgeAt: position) }
    @inlinable public func targetIndex(ofEdgeAt position: Edges.Index) -> Int { _base.targetIndex(ofEdgeAt: position) }
    @inlinable public var edgeIndexBound: Int? { _base.edgeIndexBound }
    @inlinable public func edgeIndex(of position: Edges.Index) -> Int { _base.edgeIndex(of: position) }

    @inlinable
    public func _withSuccessorIndexRows<Result>(
        _ body: (_ offsets: UnsafeBufferPointer<Int>, _ targets: UnsafeBufferPointer<Int>) -> Result
    ) -> Result? {
        _base._withSuccessorIndexRows(body)
    }

    @inlinable
    public func _withOutIndexRows<Result>(
        _ body: (
            _ targets: UnsafeBufferPointer<Int>, _ targetRows: UnsafeBufferPointer<Int>,
            _ edges: UnsafeBufferPointer<Int>, _ edgeRows: UnsafeBufferPointer<Int>
        ) -> Result
    ) -> Result? {
        _base._withOutIndexRows(body)
    }
}

extension DirectedAcyclicGraph: BidirectionalDirectedGraph {
    public typealias Predecessors = Base.Predecessors
    public typealias InEdges = Base.InEdges
    public typealias PredecessorIndices = Base.PredecessorIndices

    @inlinable public func predecessors(of vertex: Vertex) -> Base.Predecessors { _base.predecessors(of: vertex) }
    @inlinable public func inEdges(of vertex: Vertex) -> Base.InEdges { _base.inEdges(of: vertex) }
    @inlinable public func inDegree(of vertex: Vertex) -> Int { _base.inDegree(of: vertex) }
    @inlinable public func degree(of vertex: Vertex) -> Int { _base.degree(of: vertex) }
    @inlinable public func inDegree(ofIndex index: Int) -> Int { _base.inDegree(ofIndex: index) }
    @inlinable public func predecessorIndices(ofIndex index: Int) -> Base.PredecessorIndices { _base.predecessorIndices(ofIndex: index) }
    @inlinable public func inEdges(ofIndex index: Int) -> Base.InEdges { _base.inEdges(ofIndex: index) }
}

extension DirectedAcyclicGraph: SparselyIndexedDirectedGraph where Base: SparselyIndexedDirectedGraph {
    @inlinable public var vertexPositionBound: Int { _base.vertexPositionBound }
    @inlinable public var edgePositionBound: Int { _base.edgePositionBound }
    @inlinable public func vertexPosition(of vertex: Vertex) -> Int { _base.vertexPosition(of: vertex) }
    @inlinable public func vertex(atPosition position: Int) -> Vertex { _base.vertex(atPosition: position) }
    @inlinable public func containsVertex(atPosition position: Int) -> Bool { _base.containsVertex(atPosition: position) }
    @inlinable public func containsEdge(atPosition position: Int) -> Bool { _base.containsEdge(atPosition: position) }
    @inlinable public func _numberedRows(outward: Bool, edges withEdges: Bool) -> _NumberedRows {
        _base._numberedRows(outward: outward, edges: withEdges)
    }
}

// MARK: - checked: lookups

// README Principle 6: `VertexNotFound` for a vertex that is not in the graph. Each is one hash and
// then the base's row, for every base, including one without `checked:` members of its own.

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

    /// The place of `vertex` in `topologicalOrder`, in `0..<vertexCount`. One hash, then O(1)
    /// while no vertex has been removed since the slots were last compacted, and O(log n), a
    /// Fenwick tree count of the holes before its slot, otherwise (see the type's documentation).
    /// petgraph's `get_position` returns its label instead, which is not a place.
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

    /// The vertices in topological order: `topologicalOrder[i]` is the vertex at place `i`
    /// (petgraph's `at_position`). A value: unaffected by later changes to the graph. The
    /// subscript is O(1) without holes and O(log n) with them; iteration is O(1) per vertex
    /// either way.
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
