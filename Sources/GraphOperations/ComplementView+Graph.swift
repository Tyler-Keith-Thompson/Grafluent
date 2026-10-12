import GraphProtocols

extension ComplementView: Graph where Base: Graph {
    @inlinable
    var _order: Int { base.vertexIndexBound.unsafelyUnwrapped }

    /// The complement's row `i` in index space.
    @inlinable
    func _neighborRow(_ i: Int) -> IndexRow<Base.NeighborIndices> {
        IndexRow(row: base.neighborIndices(ofIndex: i), index: i, count: _order)
    }

    /// The base's vertices.
    @inlinable
    public var vertices: Base.Vertices { base.vertices }

    /// Every edge of the complement once, at its cell `(u, v)` with `u < v`, in row-major order.
    @inlinable
    public var edges: UndirectedEdges { UndirectedEdges(view: self) }

    /// The edges of an undirected `ComplementView`, in row-major order of their cells, each with
    /// `source < target`. Iterating walks the rows; `index(after:)` tests the columns after the
    /// current one with the base's `contains(edge:)`, as for a directed complement.
    @frozen
    public struct UndirectedEdges: Collection {
        @usableFromInline let view: ComplementView
        public let startIndex: Cell

        @inlinable
        init(view: ComplementView) {
            self.view = view
            startIndex = view._nextUpperCell(row: 0, after: -1)
        }

        @inlinable public var endIndex: Cell { Cell(source: view._order, target: 0) }
        @inlinable public var count: Int { view.edgeCount }

        @inlinable
        public func index(after i: Cell) -> Cell { view._nextUpperCell(row: i.source, after: i.target) }

        @inlinable
        public subscript(position: Cell) -> UndirectedEdge<Base.Vertex> {
            UndirectedEdge(view.base.vertex(atIndex: position.source), view.base.vertex(atIndex: position.target))
        }

        @inlinable
        public func makeIterator() -> Iterator { Iterator(view: view) }

        @frozen
        public struct Iterator: IteratorProtocol {
            @usableFromInline let view: ComplementView
            @usableFromInline var row: Int
            @usableFromInline var columns: IndexRow<Base.NeighborIndices>.Iterator?

            @inlinable
            init(view: ComplementView) {
                self.view = view
                row = -1
                columns = nil
            }

            @inlinable
            public mutating func next() -> UndirectedEdge<Base.Vertex>? {
                let n = view._order
                while true {
                    if columns != nil {
                        while let j = columns!.next() {
                            if j > row { return UndirectedEdge(view.base.vertex(atIndex: row), view.base.vertex(atIndex: j)) }
                        }
                    }
                    row += 1
                    guard row < n else { return nil }
                    columns = view._neighborRow(row).makeIterator()
                }
            }
        }
    }

    /// The first cell `(i, j)` with `i < j` in row `row` above column `after`, or in a later row;
    /// the end cell when there is none. One `contains(edge:)` per column passed, as `_nextCell`.
    @inlinable
    func _nextUpperCell(row: Int, after column: Int) -> Cell {
        let n = _order
        var i = row
        var j = Swift.max(column, row) &+ 1
        while i < n {
            let u = base.vertex(atIndex: i)
            while j < n {
                if !base.contains(edge: UndirectedEdge(u, base.vertex(atIndex: j))) { return Cell(source: i, target: j) }
                j &+= 1
            }
            i &+= 1
            j = i &+ 1
        }
        return Cell(source: n, target: 0)
    }

    /// Every index other than `index` that the base's row lacks, ascending. O(deg + n/64 + output).
    @inlinable
    public func neighborIndices(ofIndex index: Int) -> IndexRow<Base.NeighborIndices> { _neighborRow(index) }

    /// The cells of `neighborIndices(ofIndex:)`, smaller end first.
    @inlinable
    public func incidentEdges(ofIndex index: Int) -> CellRow<Base.NeighborIndices> {
        CellRow(indices: _neighborRow(index), orientation: 2)
    }

    @inlinable
    public func neighbors(of vertex: Base.Vertex) -> LazyMapSequence<IndexRow<Base.NeighborIndices>, Base.Vertex> {
        let base = base
        return _neighborRow(base.vertexIndex(of: vertex)).lazy.map { base.vertex(atIndex: $0) }
    }

    @inlinable
    public func incidentEdges(of vertex: Base.Vertex) -> CellRow<Base.NeighborIndices> {
        incidentEdges(ofIndex: base.vertexIndex(of: vertex))
    }

    @inlinable
    public func oppositeVertex(to vertex: Base.Vertex, acrossEdgeAt position: Cell) -> Base.Vertex {
        let u = base.vertex(atIndex: position.source)
        if vertex == u { return base.vertex(atIndex: position.target) }
        let v = base.vertex(atIndex: position.target)
        precondition(vertex == v, "\(vertex) is not an endpoint of the edge at \(position)")
        return u
    }

    @inlinable public var vertexCount: Int { base.vertexCount }

    /// n(n − 1)/2 less the distinct non-loop pairs of the base. O(n + m).
    @inlinable
    public var edgeCount: Int {
        let n = _order
        return (n * (n - 1) - _distinctOthersTotal(count: n) { base.neighborIndices(ofIndex: $0) }) / 2
    }

    @inlinable public func contains(_ vertex: Base.Vertex) -> Bool { base.contains(vertex) }

    /// Whether the ends are distinct vertices that the base does not join. It looks both vertices
    /// up.
    @inlinable
    public func contains(edge: UndirectedEdge<Base.Vertex>) -> Bool {
        edge.u != edge.v && base.contains(edge.u) && base.contains(edge.v) && !base.contains(edge: edge)
    }

    @inlinable
    public func degree(of vertex: Base.Vertex) -> Int { degree(ofIndex: base.vertexIndex(of: vertex)) }

    @inlinable public var vertexIndexBound: Int? { base.vertexIndexBound }
    @inlinable public func vertexIndex(of vertex: Base.Vertex) -> Int { base.vertexIndex(of: vertex) }
    @inlinable public func vertex(atIndex index: Int) -> Base.Vertex { base.vertex(atIndex: index) }

    /// n − 1 less the distinct others in the base's row. O(deg + n/64).
    @inlinable
    public func degree(ofIndex index: Int) -> Int {
        let n = _order
        return n - 1 - _distinctOthers(base.neighborIndices(ofIndex: index), index: index, count: n)
    }

    @inlinable
    public func endpointIndices(ofEdgeAt position: Cell) -> (u: Int, v: Int) { (position.source, position.target) }

    /// `nil`: a complement has no edge indices.
    @inlinable public var edgeIndexBound: Int? { nil }

    @inlinable
    public func edgeIndex(of position: Cell) -> Int {
        preconditionFailure("A complement has no edge indices; check edgeIndexBound first")
    }

    /// Never called: a complement has no edge indices.
    @inlinable
    public func incidentEdgeIndices(ofIndex index: Int) -> LazyMapSequence<CellRow<Base.NeighborIndices>, Int> {
        preconditionFailure("A complement has no edge indices; check edgeIndexBound first")
    }

    /// `nil`: the view's rows are computed.
    @inlinable
    public func _withIncidentIndexRows<Result>(
        _ body: (
            _ neighbors: UnsafeBufferPointer<Int>, _ neighborRows: UnsafeBufferPointer<Int>,
            _ edges: UnsafeBufferPointer<Int>, _ edgeRows: UnsafeBufferPointer<Int>
        ) -> Result
    ) -> Result? {
        nil
    }
}

extension ComplementView.UndirectedEdges: Sendable where Base: Sendable {}
