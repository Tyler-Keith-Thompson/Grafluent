import GraphProtocols

// The collections a `StableUndirectedGraph` hands out. Each is a value: it holds the pages it
// reads, so later changes to the graph do not affect it. Positions increase along every one of
// them.

extension StableUndirectedGraph {
    /// The live edges, in position order, each in its stored orientation. `Index` is the position;
    /// `endIndex` is the next position `insert(edge:)` hands out, and `indices.contains(_:)` is
    /// O(1). Not random-access: stepping over holes is a scan.
    @frozen
    public struct Edges: BidirectionalCollection {
        @usableFromInline internal let _arcs: StableDirectedGraph<Vertex>.Edges

        @inlinable
        internal init(_ arcs: StableDirectedGraph<Vertex>.Edges) { _arcs = arcs }

        public typealias Index = Int
        public typealias Element = UndirectedEdge<Vertex>
        public typealias Indices = StableDirectedGraph<Vertex>.Edges.Indices

        /// The lowest live position, or `endIndex` when there is none. O(1).
        @inlinable
        public var startIndex: Int { _arcs.startIndex }

        /// One past the highest position ever handed out. O(1).
        @inlinable
        public var endIndex: Int { _arcs.endIndex }

        /// The number of live edges. O(1).
        @inlinable
        public var count: Int { _arcs.count }

        @inlinable
        public var isEmpty: Bool { _arcs.isEmpty }

        /// The edge at `position`, in its stored orientation. O(1).
        ///
        /// - Precondition: `position` is a live edge position.
        @inlinable
        public subscript(position: Int) -> UndirectedEdge<Vertex> {
            let arc = _arcs[position]
            return UndirectedEdge(arc.source, arc.target)
        }

        /// The next live position after `i`, or `endIndex`. O(holes skipped), a freed page
        /// skipped whole.
        @inlinable
        public func index(after i: Int) -> Int { _arcs.index(after: i) }

        /// The previous live position before `i`. O(holes skipped), a freed page skipped whole.
        ///
        /// - Precondition: `i` is at most `endIndex`, and a live position is below it.
        @inlinable
        public func index(before i: Int) -> Int { _arcs.index(before: i) }

        /// The live positions. `contains(_:)` is O(1).
        @inlinable
        public var indices: Indices { _arcs.indices }

        @inlinable
        public func makeIterator() -> Iterator { Iterator(_arcs.makeIterator()) }

        /// The live edges in position order, page by page.
        @frozen
        public struct Iterator: IteratorProtocol {
            @usableFromInline internal var _arcs: StableDirectedGraph<Vertex>.Edges.Iterator

            @inlinable
            internal init(_ arcs: StableDirectedGraph<Vertex>.Edges.Iterator) { _arcs = arcs }

            @inlinable
            public mutating func next() -> UndirectedEdge<Vertex>? {
                guard let arc = _arcs.next() else { return nil }
                return UndirectedEdge(arc.source, arc.target)
            }
        }
    }

    /// The far end of every edge end at one vertex, in the order of `IncidentEdges`: a vertex once
    /// per edge, and the vertex itself twice per self-loop. `underestimatedCount` is the degree.
    @frozen
    public struct Neighbors: Sequence {
        @usableFromInline internal let _pages: ContiguousArray<_VertexPage<Vertex>>
        @usableFromInline internal let _base: Int
        @usableFromInline internal let _ends: _LiveRow.Ends

        @inlinable
        internal init(pages: ContiguousArray<_VertexPage<Vertex>>, base: Int, ends: _LiveRow.Ends) {
            _pages = pages
            _base = base
            _ends = ends
        }

        /// The degree. O(1).
        @inlinable
        public var underestimatedCount: Int { _ends.underestimatedCount }

        @inlinable
        public func makeIterator() -> Iterator { Iterator(pages: _pages, base: _base, ends: _ends.makeIterator()) }

        @frozen
        public struct Iterator: IteratorProtocol {
            @usableFromInline internal let _pages: ContiguousArray<_VertexPage<Vertex>>
            @usableFromInline internal let _base: Int
            @usableFromInline internal var _ends: _LiveRow.EndIterator

            @inlinable
            internal init(pages: ContiguousArray<_VertexPage<Vertex>>, base: Int, ends: _LiveRow.EndIterator) {
                _pages = pages
                _base = base
                _ends = ends
            }

            @inlinable
            public mutating func next() -> Vertex? {
                guard let slot = _ends.next() else { return nil }
                return _pagedVertex(atSlot: slot, _pages, base: _base)
            }
        }
    }

    /// The positions of the edges at one vertex, increasing, a self-loop twice in a row: the stored
    /// row. `underestimatedCount` is the degree.
    @frozen
    public struct IncidentEdges: Sequence {
        @usableFromInline internal let _row: _LiveRow

        @inlinable
        internal init(row: _LiveRow) { _row = row }

        /// The degree. O(1).
        @inlinable
        public var underestimatedCount: Int { _row.count }

        @inlinable
        public func makeIterator() -> _LiveRow.PositionIterator { _row.makePositionIterator() }
    }

    /// The vertex indices of one vertex's neighbors, in the order of `neighbors(of:)`: its stored
    /// row of far-end slots, which are the indices while the graph has vertex indices.
    public typealias NeighborIndices = _LiveRow.Ends

    /// The positions of the copies joining two vertices, in either orientation, oldest first: the
    /// shorter end's row filtered by the other end, a self-loop's two entries once.
    @frozen
    public struct EdgesConnecting: Sequence {
        @usableFromInline internal let _ends: ArraySlice<Int>
        @usableFromInline internal let _positions: ArraySlice<Int>
        /// The far end's slot.
        @usableFromInline internal let _other: Int

        @inlinable
        internal init(ends: ArraySlice<Int>, positions: ArraySlice<Int>, other: Int) {
            _ends = ends
            _positions = positions
            _other = other
        }

        @inlinable
        public func makeIterator() -> Iterator { Iterator(ends: _ends, positions: _positions, other: _other) }

        @frozen
        public struct Iterator: IteratorProtocol {
            @usableFromInline internal let _ends: ArraySlice<Int>
            @usableFromInline internal let _positions: ArraySlice<Int>
            @usableFromInline internal let _other: Int
            @usableFromInline internal var _offset: Int
            @usableFromInline internal var _last: Int

            @inlinable
            internal init(ends: ArraySlice<Int>, positions: ArraySlice<Int>, other: Int) {
                _ends = ends
                _positions = positions
                _other = other
                _offset = 0
                _last = -1
            }

            @inlinable
            public mutating func next() -> Int? {
                while _offset < _ends.count {
                    let k = _offset
                    _offset &+= 1
                    guard _ends[_ends.startIndex &+ k] == _other else { continue }
                    let position = _positions[_positions.startIndex &+ k]
                    // A self-loop's second entry repeats the position just returned.
                    if position == _last { continue }
                    _last = position
                    return position
                }
                return nil
            }
        }
    }
}

extension StableUndirectedGraph.Edges: Sendable where Vertex: Sendable {}
extension StableUndirectedGraph.Neighbors: Sendable where Vertex: Sendable {}
extension StableUndirectedGraph.IncidentEdges: Sendable {}
extension StableUndirectedGraph.EdgesConnecting: Sendable {}
