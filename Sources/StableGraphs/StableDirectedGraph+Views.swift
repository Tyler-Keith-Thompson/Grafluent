import AdjacencyListModule
import GraphProtocols

// The collections a graph hands out. Each is a value: it holds the storage it reads, so later
// changes to the graph do not affect it. Positions increase along every one of them.

extension StableDirectedGraph {
    /// The live vertices, in position order. `Index` is the position; `endIndex` is the next
    /// position `insert(_:)` hands out. Not random-access: stepping over holes is a scan.
    @frozen
    public struct Vertices: BidirectionalCollection {
        @usableFromInline internal let _vertices: ContiguousArray<Vertex?>
        @usableFromInline internal let _slots: [Vertex: Int]
        @usableFromInline internal let _first: Int
        @usableFromInline internal let _count: Int

        @inlinable
        internal init(vertices: ContiguousArray<Vertex?>, slots: [Vertex: Int], first: Int, count: Int) {
            _vertices = vertices
            _slots = slots
            _first = first
            _count = count
        }

        public typealias Index = Int
        public typealias Element = Vertex

        /// The lowest live position, or `endIndex` when there is none. O(1).
        @inlinable
        public var startIndex: Int { _first }

        /// One past the highest position ever handed out (petgraph's `node_bound()`). O(1).
        @inlinable
        public var endIndex: Int { _vertices.count }

        /// The number of live vertices. O(1).
        @inlinable
        public var count: Int { _count }

        @inlinable
        public var isEmpty: Bool { _count == 0 }

        /// The vertex at `position`.
        ///
        /// - Precondition: `position` is a live vertex position.
        @inlinable
        public subscript(position: Int) -> Vertex {
            guard let vertex = _vertices[position] else { preconditionFailure("No vertex at position \(position): it was removed") }
            return vertex
        }

        /// The next live position after `i`, or `endIndex`. O(holes skipped).
        @inlinable
        public func index(after i: Int) -> Int {
            precondition(i < _vertices.count, "Cannot advance past endIndex")
            var j = i + 1
            while j < _vertices.count, _vertices[j] == nil { j += 1 }
            return j
        }

        /// The previous live position before `i`. O(holes skipped).
        @inlinable
        public func index(before i: Int) -> Int {
            var j = i - 1
            while j >= 0, _vertices[j] == nil { j -= 1 }
            precondition(j >= 0, "Cannot move before startIndex")
            return j
        }

        /// The position of `vertex`, or `nil` when it is not a vertex. O(1) expected.
        @inlinable
        public func firstIndex(of vertex: Vertex) -> Int? { _slots[vertex] }

        /// The position of `vertex`, or `nil` when it is not a vertex. O(1) expected.
        @inlinable
        public func lastIndex(of vertex: Vertex) -> Int? { _slots[vertex] }

        @inlinable
        public func _customContainsEquatableElement(_ element: Vertex) -> Bool? { _slots[element] != nil }

        @inlinable
        public func _customIndexOfEquatableElement(_ element: Vertex) -> Int?? { .some(_slots[element]) }

        @inlinable
        public func _customLastIndexOfEquatableElement(_ element: Vertex) -> Int?? { .some(_slots[element]) }

        /// The live positions.
        @inlinable
        public var indices: Indices { Indices(base: self, startIndex: _first, endIndex: _vertices.count) }

        /// Live vertex positions in a range, in increasing order; `contains(_:)` is O(1), so
        /// `vertices.indices.contains(p)` tells whether `p` still names a vertex.
        @frozen
        public struct Indices: BidirectionalCollection {
            @usableFromInline internal let _base: Vertices
            public let startIndex: Int
            public let endIndex: Int

            @inlinable
            internal init(base: Vertices, startIndex: Int, endIndex: Int) {
                _base = base
                self.startIndex = startIndex
                self.endIndex = endIndex
            }

            public typealias Index = Int
            public typealias Element = Int
            public typealias SubSequence = Indices

            @inlinable
            public subscript(position: Int) -> Int {
                precondition(contains(position), "No vertex at position \(position)")
                return position
            }

            @inlinable
            public subscript(bounds: Range<Int>) -> Indices {
                Indices(base: _base, startIndex: bounds.lowerBound, endIndex: bounds.upperBound)
            }

            @inlinable
            public func index(after i: Int) -> Int {
                precondition(i < endIndex, "Cannot advance past endIndex")
                return _base.index(after: i)
            }

            @inlinable
            public func index(before i: Int) -> Int {
                precondition(i > startIndex, "Cannot move before startIndex")
                return _base.index(before: i)
            }

            @inlinable
            public var indices: Indices { self }

            /// The number of live positions in range: O(1) for all of `vertices.indices`.
            @inlinable
            public var count: Int {
                if startIndex == _base.startIndex, endIndex == _base.endIndex { return _base.count }
                var n = 0
                var i = startIndex
                while i != endIndex {
                    n += 1
                    i = index(after: i)
                }
                return n
            }

            /// Whether `position` is a live vertex position in range. O(1); never traps.
            @inlinable
            public func contains(_ position: Int) -> Bool {
                position >= startIndex && position < endIndex && _base._vertices[position] != nil
            }

            @inlinable
            public func _customContainsEquatableElement(_ element: Int) -> Bool? { contains(element) }

            @inlinable
            public func _customIndexOfEquatableElement(_ element: Int) -> Int?? { .some(contains(element) ? element : nil) }

            @inlinable
            public func _customLastIndexOfEquatableElement(_ element: Int) -> Int?? { .some(contains(element) ? element : nil) }
        }
    }

    /// The live edges, in position order. `Index` is the position; `endIndex` is the next position
    /// `insert(edge:)` hands out. Not random-access: stepping over holes is a scan.
    @frozen
    public struct Edges: BidirectionalCollection {
        @usableFromInline internal let _vertices: ContiguousArray<Vertex?>
        @usableFromInline internal let _records: ContiguousArray<_EdgeRecord>
        @usableFromInline internal let _first: Int
        @usableFromInline internal let _count: Int

        @inlinable
        internal init(vertices: ContiguousArray<Vertex?>, records: ContiguousArray<_EdgeRecord>, first: Int, count: Int) {
            _vertices = vertices
            _records = records
            _first = first
            _count = count
        }

        public typealias Index = Int
        public typealias Element = DirectedEdge<Vertex>

        /// The lowest live position, or `endIndex` when there is none. O(1).
        @inlinable
        public var startIndex: Int { _first }

        /// One past the highest position ever handed out (petgraph's `edge_bound()`). O(1).
        @inlinable
        public var endIndex: Int { _records.count }

        /// The number of live edges. O(1).
        @inlinable
        public var count: Int { _count }

        @inlinable
        public var isEmpty: Bool { _count == 0 }

        /// The edge at `position`. O(1).
        ///
        /// - Precondition: `position` is a live edge position.
        @inlinable
        public subscript(position: Int) -> DirectedEdge<Vertex> {
            precondition(UInt(bitPattern: position) < UInt(bitPattern: _records.count), "Edge position out of range")
            let record = _records[position]
            precondition(record.source >= 0, "No edge at position \(position): it was removed")
            return DirectedEdge(from: _vertices[record.source].unsafelyUnwrapped, to: _vertices[record.target].unsafelyUnwrapped)
        }

        /// The next live position after `i`, or `endIndex`. O(holes skipped).
        @inlinable
        public func index(after i: Int) -> Int {
            precondition(i < _records.count, "Cannot advance past endIndex")
            var j = i + 1
            while j < _records.count, _records[j].source < 0 { j += 1 }
            return j
        }

        /// The previous live position before `i`. O(holes skipped).
        @inlinable
        public func index(before i: Int) -> Int {
            var j = i - 1
            while j >= 0, _records[j].source < 0 { j -= 1 }
            precondition(j >= 0, "Cannot move before startIndex")
            return j
        }

        /// The live positions.
        @inlinable
        public var indices: Indices { Indices(base: self, startIndex: _first, endIndex: _records.count) }

        /// Live edge positions in a range, in increasing order; `contains(_:)` is O(1), so
        /// `edges.indices.contains(p)` tells whether `p` still names an edge.
        @frozen
        public struct Indices: BidirectionalCollection {
            @usableFromInline internal let _base: Edges
            public let startIndex: Int
            public let endIndex: Int

            @inlinable
            internal init(base: Edges, startIndex: Int, endIndex: Int) {
                _base = base
                self.startIndex = startIndex
                self.endIndex = endIndex
            }

            public typealias Index = Int
            public typealias Element = Int
            public typealias SubSequence = Indices

            @inlinable
            public subscript(position: Int) -> Int {
                precondition(contains(position), "No edge at position \(position)")
                return position
            }

            @inlinable
            public subscript(bounds: Range<Int>) -> Indices {
                Indices(base: _base, startIndex: bounds.lowerBound, endIndex: bounds.upperBound)
            }

            @inlinable
            public func index(after i: Int) -> Int {
                precondition(i < endIndex, "Cannot advance past endIndex")
                return _base.index(after: i)
            }

            @inlinable
            public func index(before i: Int) -> Int {
                precondition(i > startIndex, "Cannot move before startIndex")
                return _base.index(before: i)
            }

            @inlinable
            public var indices: Indices { self }

            /// The number of live positions in range: O(1) for all of `edges.indices`.
            @inlinable
            public var count: Int {
                if startIndex == _base.startIndex, endIndex == _base.endIndex { return _base.count }
                var n = 0
                var i = startIndex
                while i != endIndex {
                    n += 1
                    i = index(after: i)
                }
                return n
            }

            /// Whether `position` is a live edge position in range. O(1); never traps.
            @inlinable
            public func contains(_ position: Int) -> Bool {
                position >= startIndex && position < endIndex && _base._records[position].source >= 0
            }

            @inlinable
            public func _customContainsEquatableElement(_ element: Int) -> Bool? { contains(element) }

            @inlinable
            public func _customIndexOfEquatableElement(_ element: Int) -> Int?? { .some(contains(element) ? element : nil) }

            @inlinable
            public func _customLastIndexOfEquatableElement(_ element: Int) -> Int?? { .some(contains(element) ? element : nil) }
        }
    }

    /// The positions of the edges leaving one vertex, increasing (oldest first), read from the stored
    /// row. `Index` is the position itself, `endIndex` is `Int.max`; `count` is O(1). Iterating steps
    /// in O(1); `index(after:)` and `index(before:)` find the position in the row by binary search,
    /// O(log d).
    @frozen
    public struct OutEdges: BidirectionalCollection {
        @usableFromInline internal let _row: _LiveRow

        @inlinable
        internal init(row: _LiveRow) { _row = row }

        public typealias Index = Int
        public typealias Element = Int

        /// The first position, or `endIndex` when the row is empty.
        @inlinable
        public var startIndex: Int { _row.startIndex }

        /// `Int.max`.
        @inlinable
        public var endIndex: Int { Int.max }

        /// The number of edges. O(1).
        @inlinable
        public var count: Int { _row.count }

        @inlinable
        public var isEmpty: Bool { _row.count == 0 }

        /// The position itself.
        @inlinable
        public subscript(position: Int) -> Int {
            precondition(position != Int.max, "Index out of range")
            return position
        }

        /// The next position in the row, or `Int.max`. O(log d): the index is the position, found in
        /// the row by binary search. Iterating (`for`-`in`, `makeIterator()`) steps in O(1).
        @inlinable
        public func index(after i: Int) -> Int { _row.index(after: i) }

        /// The previous position in the row. O(log d), by binary search.
        @inlinable
        public func index(before i: Int) -> Int { _row.index(before: i) }

        @inlinable
        public func makeIterator() -> _LiveRow.PositionIterator { _row.makePositionIterator() }
    }

    /// The positions of the edges entering one vertex, increasing (oldest first), read from the stored
    /// row. `Index` is the position itself, `endIndex` is `Int.max`; `count` is O(1). Iterating steps
    /// in O(1); `index(after:)` and `index(before:)` find the position in the row by binary search,
    /// O(log d).
    @frozen
    public struct InEdges: BidirectionalCollection {
        @usableFromInline internal let _row: _LiveRow

        @inlinable
        internal init(row: _LiveRow) { _row = row }

        public typealias Index = Int
        public typealias Element = Int

        /// The first position, or `endIndex` when the row is empty.
        @inlinable
        public var startIndex: Int { _row.startIndex }

        /// `Int.max`.
        @inlinable
        public var endIndex: Int { Int.max }

        /// The number of edges. O(1).
        @inlinable
        public var count: Int { _row.count }

        @inlinable
        public var isEmpty: Bool { _row.count == 0 }

        /// The position itself.
        @inlinable
        public subscript(position: Int) -> Int {
            precondition(position != Int.max, "Index out of range")
            return position
        }

        /// The next position in the row, or `Int.max`. O(log d): the index is the position, found in
        /// the row by binary search. Iterating (`for`-`in`, `makeIterator()`) steps in O(1).
        @inlinable
        public func index(after i: Int) -> Int { _row.index(after: i) }

        /// The previous position in the row. O(log d), by binary search.
        @inlinable
        public func index(before i: Int) -> Int { _row.index(before: i) }

        @inlinable
        public func makeIterator() -> _LiveRow.PositionIterator { _row.makePositionIterator() }
    }

    /// A neighborhood: the targets along `OutEdges` or the sources along `InEdges`, a vertex once
    /// per edge. `Index` is the edge position; `count` is O(1).
    @frozen
    public struct Neighbors: BidirectionalCollection {
        @usableFromInline internal let _vertices: ContiguousArray<Vertex?>
        @usableFromInline internal let _row: _LiveRow

        @inlinable
        internal init(vertices: ContiguousArray<Vertex?>, row: _LiveRow) {
            _vertices = vertices
            _row = row
        }

        public typealias Index = Int
        public typealias Element = Vertex

        @inlinable
        public var startIndex: Int { _row.startIndex }

        @inlinable
        public var endIndex: Int { Int.max }

        @inlinable
        public var count: Int { _row.count }

        @inlinable
        public var isEmpty: Bool { _row.count == 0 }

        /// The far end of the edge at `position`. O(log d).
        @inlinable
        public subscript(position: Int) -> Vertex {
            _vertices[_row.end(atPosition: position)].unsafelyUnwrapped
        }

        /// The next position in the row, or `Int.max`. O(log d), by binary search; iterating steps
        /// in O(1).
        @inlinable
        public func index(after i: Int) -> Int { _row.index(after: i) }

        /// The previous position in the row. O(log d), by binary search.
        @inlinable
        public func index(before i: Int) -> Int { _row.index(before: i) }

        @inlinable
        public func makeIterator() -> Iterator { Iterator(vertices: _vertices, ends: _row.makeEndIterator()) }

        @frozen
        public struct Iterator: IteratorProtocol {
            @usableFromInline internal let _vertices: ContiguousArray<Vertex?>
            @usableFromInline internal var _ends: _LiveRow.EndIterator

            @inlinable
            internal init(vertices: ContiguousArray<Vertex?>, ends: _LiveRow.EndIterator) {
                _vertices = vertices
                _ends = ends
            }

            @inlinable
            public mutating func next() -> Vertex? {
                guard let slot = _ends.next() else { return nil }
                return _vertices[slot].unsafelyUnwrapped
            }
        }
    }

    /// The vertex indices of one vertex's successors: its stored row of far-end
    /// slots, which are the indices while the graph has vertex indices.
    public typealias SuccessorIndices = _LiveRow.Ends

    /// The vertex indices of one vertex's predecessors: its stored row of source slots.
    public typealias PredecessorIndices = _LiveRow.Ends

    /// The positions of the copies from one vertex to another, oldest first: the source's out-row
    /// filtered by target, or the target's in-row filtered by source, whichever is shorter.
    @frozen
    public struct EdgesConnecting: Sequence {
        @usableFromInline internal let _ends: ArraySlice<Int>
        @usableFromInline internal let _positions: ArraySlice<Int>
        /// The far end's slot: the target in an out-row, the source in an in-row.
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

            @inlinable
            internal init(ends: ArraySlice<Int>, positions: ArraySlice<Int>, other: Int) {
                _ends = ends
                _positions = positions
                _other = other
                _offset = 0
            }

            @inlinable
            public mutating func next() -> Int? {
                while _offset < _ends.count {
                    let k = _offset
                    _offset += 1
                    if _ends[_ends.startIndex &+ k] == _other { return _positions[_positions.startIndex &+ k] }
                }
                return nil
            }
        }
    }
}

extension StableDirectedGraph.Vertices: Sendable where Vertex: Sendable {}
extension StableDirectedGraph.Vertices.Indices: Sendable where Vertex: Sendable {}
extension StableDirectedGraph.Edges: Sendable where Vertex: Sendable {}
extension StableDirectedGraph.Edges.Indices: Sendable where Vertex: Sendable {}
extension StableDirectedGraph.OutEdges: Sendable {}
extension StableDirectedGraph.InEdges: Sendable {}
extension StableDirectedGraph.Neighbors: Sendable where Vertex: Sendable {}
extension StableDirectedGraph.EdgesConnecting: Sendable {}

/// One stored row: far-end slots (-1 at a dead entry) and edge positions (increasing), side by
/// side, and the number of live entries. Dead entries are at most half the row.
@frozen
public struct _LiveRow: Sendable {
    @usableFromInline internal let ends: ArraySlice<Int>
    @usableFromInline internal let positions: ArraySlice<Int>
    @usableFromInline internal let count: Int

    @inlinable
    internal init(ends: ArraySlice<Int>, positions: ArraySlice<Int>, count: Int) {
        self.ends = ends
        self.positions = positions
        self.count = count
    }

    @inlinable
    internal func _position(_ k: Int) -> Int { positions[positions.startIndex &+ k] }

    @inlinable
    internal func _end(_ k: Int) -> Int { ends[ends.startIndex &+ k] }

    @inlinable
    internal var startIndex: Int {
        var k = 0
        while k < ends.count, _end(k) < 0 { k += 1 }
        return k < ends.count ? _position(k) : Int.max
    }

    /// The offset of the live entry at `position`.
    @inlinable
    internal func _offset(of position: Int) -> Int {
        var low = 0
        var high = positions.count
        while low < high {
            let middle = (low + high) / 2
            if _position(middle) < position { low = middle + 1 } else { high = middle }
        }
        precondition(low < positions.count && _position(low) == position && _end(low) >= 0, "Position \(position) is not in this row")
        return low
    }

    @inlinable
    internal func end(atPosition position: Int) -> Int { _end(_offset(of: position)) }

    @inlinable
    internal func index(after i: Int) -> Int {
        precondition(i != Int.max, "Cannot advance past endIndex")
        var k = _offset(of: i) + 1
        while k < ends.count, _end(k) < 0 { k += 1 }
        return k < ends.count ? _position(k) : Int.max
    }

    @inlinable
    internal func index(before i: Int) -> Int {
        var k = i == Int.max ? ends.count - 1 : _offset(of: i) - 1
        while k >= 0, _end(k) < 0 { k -= 1 }
        precondition(k >= 0, "Cannot move before startIndex")
        return _position(k)
    }

    @inlinable
    internal func makePositionIterator() -> PositionIterator { PositionIterator(ends: ends, positions: positions) }

    @inlinable
    internal func makeEndIterator() -> EndIterator { EndIterator(ends: ends) }

    /// The positions of the live entries.
    @frozen
    public struct PositionIterator: IteratorProtocol, Sendable {
        @usableFromInline internal let _ends: ArraySlice<Int>
        @usableFromInline internal let _positions: ArraySlice<Int>
        @usableFromInline internal var _k: Int

        @inlinable
        internal init(ends: ArraySlice<Int>, positions: ArraySlice<Int>) {
            _ends = ends
            _positions = positions
            _k = 0
        }

        @inlinable
        public mutating func next() -> Int? {
            while _k < _ends.count {
                let k = _k
                _k &+= 1
                if _ends[_ends.startIndex &+ k] >= 0 { return _positions[_positions.startIndex &+ k] }
            }
            return nil
        }
    }

    /// The far-end slots of the live entries.
    @frozen
    public struct EndIterator: IteratorProtocol, Sendable {
        @usableFromInline internal var _ends: IndexingIterator<ArraySlice<Int>>

        @inlinable
        internal init(ends: ArraySlice<Int>) { _ends = ends.makeIterator() }

        @inlinable
        public mutating func next() -> Int? {
            while let slot = _ends.next() {
                if slot >= 0 { return slot }
            }
            return nil
        }
    }

    /// The far-end slots of a row's live entries, as a sequence.
    @frozen
    public struct Ends: Sequence, Sendable {
        @usableFromInline internal let _ends: ArraySlice<Int>
        @usableFromInline internal let _count: Int

        @inlinable
        internal init(ends: ArraySlice<Int>, count: Int) {
            _ends = ends
            _count = count
        }

        @inlinable
        public var underestimatedCount: Int { _count }

        @inlinable
        public func makeIterator() -> EndIterator { EndIterator(ends: _ends) }
    }
}
