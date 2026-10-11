import GraphProtocols

extension ComplementView: DirectedGraph where Base: DirectedGraph {
    @inlinable
    var _n: Int { base.vertexIndexBound.unsafelyUnwrapped }

    /// The complement's row `i` in index space.
    @inlinable
    func _row(_ i: Int) -> IndexRow<Base.SuccessorIndices> {
        IndexRow(row: base.successorIndices(ofIndex: i), index: i, count: _n)
    }

    /// The base's vertices.
    @inlinable
    public var vertices: Base.Vertices { base.vertices }

    /// Every edge of the complement, row by row, at its cell.
    @inlinable
    public var edges: DirectedEdges { DirectedEdges(view: self) }

    /// The edges of a directed `ComplementView`, in row-major order of their cells. Iterating
    /// walks the rows; `index(after:)` alone rescans the current row.
    @frozen
    public struct DirectedEdges: Collection {
        @usableFromInline let view: ComplementView
        public let startIndex: Cell

        @inlinable
        init(view: ComplementView) {
            self.view = view
            startIndex = view._nextCell(row: 0, after: -1)
        }

        @inlinable public var endIndex: Cell { Cell(row: view._n, column: 0) }
        @inlinable public var count: Int { view.edgeCount }

        @inlinable
        public func index(after i: Cell) -> Cell { view._nextCell(row: i.row, after: i.column) }

        @inlinable
        public subscript(position: Cell) -> DirectedEdge<Base.Vertex> {
            DirectedEdge(from: view.base.vertex(atIndex: position.row), to: view.base.vertex(atIndex: position.column))
        }

        @inlinable
        public func makeIterator() -> Iterator { Iterator(view: view) }

        @frozen
        public struct Iterator: IteratorProtocol {
            @usableFromInline let view: ComplementView
            @usableFromInline var row: Int
            @usableFromInline var columns: IndexRow<Base.SuccessorIndices>.Iterator?

            @inlinable
            init(view: ComplementView) {
                self.view = view
                row = -1
                columns = nil
            }

            @inlinable
            public mutating func next() -> DirectedEdge<Base.Vertex>? {
                let n = view._n
                while true {
                    if columns != nil, let j = columns!.next() {
                        return DirectedEdge(from: view.base.vertex(atIndex: row), to: view.base.vertex(atIndex: j))
                    }
                    row += 1
                    guard row < n else { return nil }
                    columns = view._row(row).makeIterator()
                }
            }
        }
    }

    /// The first cell of the complement in row `row` or a later one, with a column above `after`
    /// in row `row`; the end cell when there is none.
    @inlinable
    func _nextCell(row: Int, after column: Int) -> Cell {
        let n = _n
        var i = row
        var floor = column
        while i < n {
            for j in _row(i) where j > floor { return Cell(row: i, column: j) }
            i += 1
            floor = -1
        }
        return Cell(row: n, column: 0)
    }

    /// Every index other than `index` that the base's row lacks, ascending. O(deg + n/64 + output).
    @inlinable
    public func successorIndices(ofIndex index: Int) -> IndexRow<Base.SuccessorIndices> { _row(index) }

    /// The cells `(index, j)` of `successorIndices(ofIndex:)`.
    @inlinable
    public func outEdges(ofIndex index: Int) -> CellRow<Base.SuccessorIndices> { CellRow(indices: _row(index), orientation: 0) }

    @inlinable
    public func successors(of vertex: Base.Vertex) -> LazyMapSequence<IndexRow<Base.SuccessorIndices>, Base.Vertex> {
        let base = base
        return _row(base.vertexIndex(of: vertex)).lazy.map { base.vertex(atIndex: $0) }
    }

    @inlinable
    public func outEdges(of vertex: Base.Vertex) -> CellRow<Base.SuccessorIndices> { outEdges(ofIndex: base.vertexIndex(of: vertex)) }

    @inlinable
    public func source(ofEdgeAt position: Cell) -> Base.Vertex { base.vertex(atIndex: position.row) }

    @inlinable
    public func target(ofEdgeAt position: Cell) -> Base.Vertex { base.vertex(atIndex: position.column) }

    @inlinable public var vertexCount: Int { base.vertexCount }

    /// n(n − 1) less the distinct non-loop pairs of the base. O(n + m).
    @inlinable
    public var edgeCount: Int {
        let n = _n
        return n * (n - 1) - _distinctOthersTotal(count: n) { base.successorIndices(ofIndex: $0) }
    }

    @inlinable public func contains(_ vertex: Base.Vertex) -> Bool { base.contains(vertex) }

    /// Whether the ends are distinct vertices that the base does not join: the base's
    /// `contains(edge:)`, negated. It looks both vertices up.
    @inlinable
    public func contains(edge: DirectedEdge<Base.Vertex>) -> Bool {
        edge.source != edge.target && base.contains(edge.source) && base.contains(edge.target) && !base.contains(edge: edge)
    }

    @inlinable
    public func outDegree(of vertex: Base.Vertex) -> Int { outDegree(ofIndex: base.vertexIndex(of: vertex)) }

    @inlinable public var vertexIndexBound: Int? { base.vertexIndexBound }
    @inlinable public func vertexIndex(of vertex: Base.Vertex) -> Int { base.vertexIndex(of: vertex) }
    @inlinable public func vertex(atIndex index: Int) -> Base.Vertex { base.vertex(atIndex: index) }

    /// n − 1 less the distinct others in the base's row. O(deg + n/64).
    @inlinable
    public func outDegree(ofIndex index: Int) -> Int {
        let n = _n
        return n - 1 - _distinctOthers(base.successorIndices(ofIndex: index), index: index, count: n)
    }

    @inlinable public func sourceIndex(ofEdgeAt position: Cell) -> Int { position.row }
    @inlinable public func targetIndex(ofEdgeAt position: Cell) -> Int { position.column }

    /// `nil`: a complement has no edge indices.
    @inlinable public var edgeIndexBound: Int? { nil }

    @inlinable
    public func edgeIndex(of position: Cell) -> Int {
        preconditionFailure("A complement has no edge indices; check edgeIndexBound first")
    }

    /// `nil`: the view's rows are computed.
    @inlinable
    public func _withSuccessorIndexRows<Result>(
        _ body: (_ offsets: UnsafeBufferPointer<Int>, _ targets: UnsafeBufferPointer<Int>) -> Result
    ) -> Result? {
        nil
    }
}

extension ComplementView: BidirectionalDirectedGraph where Base: BidirectionalDirectedGraph {
    /// Every index other than `index` that the base's in-row lacks, ascending.
    @inlinable
    public func predecessorIndices(ofIndex index: Int) -> IndexRow<Base.PredecessorIndices> {
        IndexRow(row: base.predecessorIndices(ofIndex: index), index: index, count: _n)
    }

    /// The cells `(j, index)` of `predecessorIndices(ofIndex:)`.
    @inlinable
    public func inEdges(ofIndex index: Int) -> CellRow<Base.PredecessorIndices> {
        CellRow(indices: predecessorIndices(ofIndex: index), orientation: 1)
    }

    @inlinable
    public func predecessors(of vertex: Base.Vertex) -> LazyMapSequence<IndexRow<Base.PredecessorIndices>, Base.Vertex> {
        let base = base
        return predecessorIndices(ofIndex: base.vertexIndex(of: vertex)).lazy.map { base.vertex(atIndex: $0) }
    }

    @inlinable
    public func inEdges(of vertex: Base.Vertex) -> CellRow<Base.PredecessorIndices> { inEdges(ofIndex: base.vertexIndex(of: vertex)) }

    @inlinable
    public func inDegree(of vertex: Base.Vertex) -> Int { inDegree(ofIndex: base.vertexIndex(of: vertex)) }

    @inlinable
    public func degree(of vertex: Base.Vertex) -> Int {
        let index = base.vertexIndex(of: vertex)
        return outDegree(ofIndex: index) + inDegree(ofIndex: index)
    }

    @inlinable
    public func inDegree(ofIndex index: Int) -> Int {
        let n = _n
        return n - 1 - _distinctOthers(base.predecessorIndices(ofIndex: index), index: index, count: n)
    }
}

extension ComplementView.DirectedEdges: Sendable where Base: Sendable {}
