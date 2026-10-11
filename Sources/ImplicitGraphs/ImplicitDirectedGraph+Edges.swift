import GraphProtocols

extension ImplicitDirectedGraph {
    /// Every edge, row by row from vertex 0, each row in the closure's order.
    ///
    /// Iterating, `count` and `Array(edges)` call the closure once per vertex. `startIndex` calls
    /// it for each row up to the first non-empty one, and `index(after:)` re-reads the row of its
    /// position (and each later row up to a non-empty one), so stepping through the edges by index
    /// costs O(d) per step: iterate instead. `underestimatedCount` is 0, so copying the edges never
    /// counts them first.
    @frozen
    public struct Edges: Collection {
        public typealias Element = DirectedEdge<Int>

        /// An edge's position: its source, its rank in the source's row, and its target. Equality,
        /// order and hashing use `(source, rank)`; the target is a function of them under the
        /// closure's determinism law, and is carried so that reading it calls nothing.
        @frozen
        public struct Index: Comparable, Hashable, Sendable, CustomStringConvertible {
            /// The vertex the edge leaves.
            public let source: Int
            /// The edge's place in the source's row, from 0.
            public let rank: Int
            /// The vertex the edge enters.
            public let target: Int

            @inlinable
            internal init(source: Int, rank: Int, target: Int) {
                self.source = source
                self.rank = rank
                self.target = target
            }

            @inlinable
            public static func == (lhs: Index, rhs: Index) -> Bool {
                lhs.source == rhs.source && lhs.rank == rhs.rank
            }

            @inlinable
            public static func < (lhs: Index, rhs: Index) -> Bool {
                (lhs.source, lhs.rank) < (rhs.source, rhs.rank)
            }

            @inlinable
            public func hash(into hasher: inout Hasher) {
                hasher.combine(source)
                hasher.combine(rank)
            }

            /// `source.rank→target`.
            public var description: String { "\(source).\(rank)→\(target)" }
        }

        @usableFromInline
        internal let _vertexCount: Int

        @usableFromInline
        internal let _successors: (Int) -> Row

        @inlinable
        internal init(_vertexCount: Int, _successors: @escaping (Int) -> Row) {
            self._vertexCount = _vertexCount
            self._successors = _successors
        }

        /// The row of `vertex`, each element range-checked as it is read. One call.
        @inlinable
        internal func _row(_ vertex: Int) -> Successors {
            Successors(_base: _successors(vertex), _source: vertex, _vertexCount: _vertexCount)
        }

        /// The first edge of the first non-empty row from `vertex` on, or `endIndex`.
        @inlinable
        internal func _firstEdge(from vertex: Int) -> Index {
            var v = vertex
            while v < _vertexCount {
                var row = _row(v).makeIterator()
                if let target = row.next() { return Index(source: v, rank: 0, target: target) }
                v &+= 1
            }
            return endIndex
        }

        /// The first edge. Calls the closure once per row up to the first non-empty one.
        @inlinable
        public var startIndex: Index { _firstEdge(from: 0) }

        /// Past the last edge: source `vertexCount`, rank 0. O(1).
        @inlinable
        public var endIndex: Index { Index(source: _vertexCount, rank: 0, target: 0) }

        /// The next edge: re-reads the row of `i` (one call, O(d)), and each later row up to a
        /// non-empty one.
        ///
        /// - Precondition: `i` is a position of an edge, not `endIndex`.
        @inlinable
        public func index(after i: Index) -> Index {
            precondition(i.source >= 0 && i.source < _vertexCount, "Cannot advance past endIndex")
            var row = _row(i.source).makeIterator()
            var rank = 0
            while let target = row.next() {
                if rank == i.rank &+ 1 { return Index(source: i.source, rank: rank, target: target) }
                rank &+= 1
            }
            return _firstEdge(from: i.source &+ 1)
        }

        /// The edge at `position`, read from the position. O(1); calls nothing.
        ///
        /// - Precondition: `position` is a position of an edge, not `endIndex`.
        @inlinable
        public subscript(position: Index) -> DirectedEdge<Int> {
            precondition(position.source >= 0 && position.source < _vertexCount, "Edge position out of range")
            return DirectedEdge(from: position.source, to: position.target)
        }

        /// The number of edges. O(n + m): one call per vertex.
        @inlinable
        public var count: Int {
            var total = 0
            for v in 0 ..< _vertexCount {
                for _ in _row(v) { total &+= 1 }
            }
            return total
        }

        /// 0: counting the edges calls the closure for every vertex.
        @inlinable
        public var underestimatedCount: Int { 0 }

        /// Iterates the rows in order: one call per vertex.
        @frozen
        public struct Iterator: IteratorProtocol {
            @usableFromInline
            internal let _edges: Edges
            @usableFromInline
            internal var _source: Int
            @usableFromInline
            internal var _row: Successors.Iterator?

            @inlinable
            internal init(_edges: Edges) {
                self._edges = _edges
                self._source = 0
                self._row = nil
            }

            @inlinable
            public mutating func next() -> DirectedEdge<Int>? {
                while true {
                    if _row != nil, let target = _row!.next() {
                        return DirectedEdge(from: _source &- 1, to: target)
                    }
                    guard _source < _edges._vertexCount else {
                        _row = nil
                        return nil
                    }
                    _row = _edges._row(_source).makeIterator()
                    _source &+= 1
                }
            }
        }

        @inlinable
        public func makeIterator() -> Iterator { Iterator(_edges: self) }

        /// The edges in one pass, one call per vertex (`Array(edges)` uses it).
        @inlinable
        public func _copyToContiguousArray() -> ContiguousArray<DirectedEdge<Int>> {
            var result = ContiguousArray<DirectedEdge<Int>>()
            for edge in self { result.append(edge) }
            return result
        }

        /// The edges transformed, in one pass: one call per vertex, where the `Collection` default
        /// would count them and then step by index.
        @inlinable
        public func map<T, E: Error>(_ transform: (DirectedEdge<Int>) throws(E) -> T) throws(E) -> [T] {
            var result: [T] = []
            for edge in self { result.append(try transform(edge)) }
            return result
        }
    }
}
