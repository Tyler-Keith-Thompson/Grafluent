import GraphProtocols

/// A finite directed graph on the vertices `0..<vertexCount` whose out-neighbors come from a
/// closure, called on demand and never stored: an implicit graph (Boost's `grid_graph`, LEMON's
/// `GridGraph` and `FullGraph`). It is a lawful `DirectedGraph`, so every generic algorithm runs
/// on it, including those that need the whole vertex set (components, centrality), with no edge
/// storage.
///
/// For a state space with no vertex collection (an unbounded grid, a puzzle), use the closure
/// searches instead: Traversal's `breadthFirstSearch(from:successors:)` and ShortestPaths'
/// `dijkstraShortestPath(from:cutoff:successors:success:)` and `aStarShortestPath(from:cutoff:
/// successors:heuristic:success:)`. For `Hashable` states over a finite set, number them and use
/// `LabeledGraph<State, ImplicitDirectedGraph<Row>>`; a grid is numbered row-major.
///
/// **The closure.** `successors(v)` lists the targets of the edges leaving `v`, once per edge, as
/// any `Sequence<Int>` (an array, a lazy filter over a fixed neighbor list), so a specialized build
/// inlines it with no type erasure. Each read of a row calls it once: `successors(of:)`,
/// `outEdges(of:)`, `outDegree(of:)` and `contains(edge:)` once each, `edges` and `edgeCount` once
/// per vertex. It must return the same sequence each time it is asked about the same vertex (the
/// protocol's "asking again gives the same answer"); this is documented, not checked, and a
/// closure that breaks it breaks every algorithm, as a mutating `==` breaks `Set`. Each target is
/// checked to be a vertex when it is read, not when the row is formed.
///
/// On a hot path, return a small struct that computes the row up front into fixed slots and
/// yields them by count, rather than a `lazy.filter` over a fixed neighbor list: the filter calls
/// its predicate per element and keeps the unfiltered iterator's state, and in the benchmarks on a
/// 1000 × 1000 grid it cost 1.2–1.8× the precomputed row (breadth-first layers, components,
/// Dijkstra).
///
/// **Positions.** An edge's position is `Edges.Index`: its source, its rank in the source's row,
/// and its target. Equality, order and hashing use `(source, rank)`, unique even among parallel
/// edges and self-loops; the target rides along, so `source(ofEdgeAt:)`, `target(ofEdgeAt:)` and a
/// weight closure reading `$0.target` call nothing. There are no dense edge indices.
///
/// **No attached maps.** It is not a `PropertyGraph`: an edge map needs a dense offset for each
/// position, which `(source, rank)` has only after counting every earlier row. Vertex values fit
/// an array of `vertexCount` indexed by vertex, which nothing ever invalidates, and edge values
/// come from the position (`$0.source`, `$0.target`), as a grid's weights do.
///
/// Not `Equatable`, `Hashable`, `Codable` or `Sendable`: a closure has no identity and is not
/// `@Sendable`.
@frozen
public struct ImplicitDirectedGraph<Row: Sequence<Int>> {
    @usableFromInline
    internal let _vertexCount: Int

    @usableFromInline
    internal let _successors: (Int) -> Row

    /// The generation: stamped once by the initializer, and never advanced.
    @usableFromInline
    internal var _generation: _GenerationStamp

    /// The graph on `0..<vertexCount` whose out-neighbors of `v` are `successors(v)`. O(1): calls
    /// nothing.
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

    /// The generation of this graph, which never changes: the graph is immutable, and its closure
    /// must answer the same each time. A structure derived from this graph is current for it and
    /// its copies, and for no other graph, even one built from the same closure.
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

    /// The closure's row for one vertex, each target checked to be a vertex as it is read (not
    /// when the row is formed). A struct rather than a lazy map, so an algorithm that keeps an
    /// iterator per vertex on its stack (Tarjan's) allocates nothing for it.
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

        /// Holds no more than the row's iterator and the vertex count: Tarjan's algorithm keeps one
        /// per vertex on its search path, and a word more each cost it measurably.
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
            /// - Precondition: the target is in `0..<vertexCount`.
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
