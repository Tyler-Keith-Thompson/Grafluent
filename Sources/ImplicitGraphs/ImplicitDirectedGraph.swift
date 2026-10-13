import GraphProtocols

/// A finite directed graph on the vertices `0..<vertexCount` whose out-neighbors come from a
/// closure, called on demand and never stored.
///
/// It is a lawful `DirectedGraph`, so every generic algorithm runs on it, including those that need
/// the whole vertex set (components, centrality), with no edge storage.
///
/// For a state space with no vertex collection (an unbounded grid, a puzzle), use the closure
/// searches instead: Traversal's `breadthFirstSearch(from:successors:)` and ShortestPaths'
/// `dijkstraShortestPath(from:cutoff:successors:success:)` and `aStarShortestPath(from:cutoff:
/// successors:heuristic:success:)`. For `Hashable` states over a finite set, number them and use
/// `LabeledGraph<State, ImplicitDirectedGraph<Row>>`. A grid is numbered row-major.
///
/// ## The closure
///
/// `successors(v)` lists the targets of the edges leaving `v`, once per edge, as any
/// `Sequence<Int>`, such as an array or a lazy filter over a fixed neighbor list. A specialized
/// build inlines it with no type erasure. Each read of a row calls it once. `successors(of:)`,
/// `outEdges(of:)`, `outDegree(of:)` and `contains(edge:)` call it once each, and `edges` and
/// `edgeCount` once per vertex.
///
/// The closure must return the same sequence each time it is asked about the same vertex. This is
/// not checked, and a closure that breaks it breaks every algorithm. Each target is checked to be a
/// vertex when it is read, not when the row is formed.
///
/// On a hot path, return a small struct that computes the row up front into fixed slots and yields
/// them by count. A `lazy.filter` calls its predicate per element and carries the unfiltered
/// iterator's state, which costs more per edge.
///
/// ## Positions
///
/// An edge's position is `Edges.Index`, which holds its source, its rank in the source's row, and
/// its target. Equality, order and hashing use `(source, rank)`, which is unique even among
/// parallel edges and self-loops. Because the position carries the target, `source(ofEdgeAt:)`,
/// `target(ofEdgeAt:)` and a weight closure reading `$0.target` call nothing. There are no dense
/// edge indices.
///
/// ## Attached values
///
/// The graph is not a `PropertyGraph`, because `(source, rank)` has a dense offset only after every
/// earlier row is counted. Keep vertex values in an array of `vertexCount` indexed by vertex, and
/// compute edge values from the position (`$0.source`, `$0.target`).
///
/// The graph is not `Equatable`, `Hashable`, `Codable` or `Sendable`, because a closure has no
/// identity and is not `@Sendable`.
@frozen
public struct ImplicitDirectedGraph<Row: Sequence<Int>> {
    @usableFromInline
    internal let _vertexCount: Int

    @usableFromInline
    internal let _successors: (Int) -> Row

    /// The generation: stamped once by the initializer, and never advanced.
    @usableFromInline
    internal var _generation: _GenerationStamp

    /// The graph on `0..<vertexCount` in which the out-neighbors of `v` are `successors(v)`. O(1).
    /// The closure is not called.
    ///
    /// - Precondition: `vertexCount >= 0`. Every element of every row is in `0..<vertexCount`,
    ///   checked as it is read.
    @inlinable
    public init(vertexCount: Int, successors: @escaping (Int) -> Row) {
        precondition(vertexCount >= 0, "negative vertex count \(vertexCount)")
        self._vertexCount = vertexCount
        self._successors = successors
        _generation = _GenerationStamp()
        _generation.stamp()
    }

    /// The generation of this graph, which never changes. A structure derived from this graph is
    /// current for it, its copies and the views and adaptors over them, and for no other graph,
    /// even one built from the same closure.
    @inlinable
    public var generation: GraphGeneration { _generation.generation }

    @inlinable
    @inline(__always)
    internal func _check(_ vertex: Int) {
        precondition(UInt(bitPattern: vertex) < UInt(bitPattern: _vertexCount), "\(vertex) is not a vertex of the graph")
    }

    /// The row of `vertex`, each element range-checked as it is read. One call.
    @inlinable
    internal func _row(_ vertex: Int) -> Successors {
        Successors(_base: _successors(vertex), _source: vertex, _vertexCount: _vertexCount)
    }

    /// The closure's row for one vertex, each target checked to be a vertex as it is read.
    ///
    /// An algorithm that keeps an iterator per vertex on its stack, such as Tarjan's, allocates
    /// nothing for it.
    @frozen
    public struct Successors: Sequence {
        @usableFromInline let _base: Row
        @usableFromInline let _source: Int
        @usableFromInline let _vertexCount: Int

        @inlinable
        init(_base: Row, _source: Int, _vertexCount: Int) {
            self._base = _base
            self._source = _source
            self._vertexCount = _vertexCount
        }

        /// Holds only the row's iterator and the vertex count. Tarjan's algorithm keeps one per
        /// vertex on its search path, so every word counts.
        @frozen
        public struct Iterator: IteratorProtocol {
            @usableFromInline var _base: Row.Iterator
            @usableFromInline let _vertexCount: Int

            @inlinable
            init(_base: Row.Iterator, _vertexCount: Int) {
                self._base = _base
                self._vertexCount = _vertexCount
            }

            /// The next target. One compare beyond the row's own `next()`.
            ///
            /// - Precondition: The target is in `0..<vertexCount`.
            @inlinable
            public mutating func next() -> Int? {
                guard let target = _base.next() else { return nil }
                precondition(UInt(bitPattern: target) < UInt(bitPattern: _vertexCount), "successor \(target) is not a vertex (0..<\(_vertexCount))")
                return target
            }
        }

        @inlinable
        public func makeIterator() -> Iterator {
            Iterator(_base: _base.makeIterator(), _vertexCount: _vertexCount)
        }

        /// The row's own estimate. Calls nothing.
        @inlinable
        public var underestimatedCount: Int { _base.underestimatedCount }
    }

    /// The positions of the edges leaving one vertex, in row order: ranks 0, 1, …, each with its
    /// target, checked to be a vertex as it is read.
    @frozen
    public struct OutEdges: Sequence {
        @usableFromInline let _row: Successors

        @inlinable
        init(_row: Successors) {
            self._row = _row
        }

        @frozen
        public struct Iterator: IteratorProtocol {
            @usableFromInline var _row: Successors.Iterator
            @usableFromInline let _source: Int
            @usableFromInline var _rank: Int

            @inlinable
            init(_row: Successors.Iterator, _source: Int) {
                self._row = _row
                self._source = _source
                self._rank = 0
            }

            @inlinable
            public mutating func next() -> Edges.Index? {
                guard let target = _row.next() else { return nil }
                defer { _rank &+= 1 }
                return Edges.Index(source: _source, rank: _rank, target: target)
            }
        }

        @inlinable
        public func makeIterator() -> Iterator { Iterator(_row: _row.makeIterator(), _source: _row._source) }

        /// The row's own estimate. Calls nothing.
        @inlinable
        public var underestimatedCount: Int { _row.underestimatedCount }
    }
}
