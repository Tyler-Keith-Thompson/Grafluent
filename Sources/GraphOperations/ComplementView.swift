import GraphProtocols

extension DirectedGraph {
    /// The complement: the same vertices, and an edge u→v for every ordered pair of distinct
    /// vertices that the graph does not join. Self-loops and parallel edges of the graph are
    /// ignored. The complement is simple and loop-free, and the complement of the complement is
    /// the graph made simple and loop-free. O(1); a lazy view.
    ///
    /// - Precondition: the graph has vertex indices.
    @inlinable
    public var complementView: ComplementView<Self> {
        precondition(vertexIndexBound != nil, "The base has no vertex indices (vertexIndexBound is nil); a complement view needs them")
        return ComplementView(base: self)
    }
}

extension Graph {
    /// The complement: the same vertices, and an edge {u, v} for every pair of distinct vertices
    /// that the graph does not join. Self-loops and parallel edges are ignored. O(1); a lazy view.
    ///
    /// - Precondition: the graph has vertex indices.
    @inlinable
    public var complementView: ComplementView<Self> {
        precondition(vertexIndexBound != nil, "The base has no vertex indices (vertexIndexBound is nil); a complement view needs them")
        return ComplementView(base: self)
    }
}

/// The complement of a graph, as a lazy view. Made by `complementView`.
///
/// The vertices and their indices are the base's. Row `i` lists every index `j ≠ i` that the
/// base's row `i` lacks, in ascending order. Producing a row costs O(deg + n/64 + output) and one
/// allocation. The complement of a sparse graph has Θ(n²) edges, so a full traversal is Θ(n²).
///
/// An edge's position is its cell of the adjacency matrix, `Cell(source: i, target: j)`, ordered
/// row-major as `AdjacencyMatrix`'s positions are. An undirected edge has `source < target`. There
/// are no edge indices.
///
/// As a `GraphAdaptor`, its generation is the base's, and it reads the base's attached vertex
/// maps (`[map, of:]`, `values(of:)`). Its edges are not the base's, so edge maps don't read
/// through.
@frozen
public struct ComplementView<Base>: GraphAdaptor {
    /// The graph the view complements.
    public let base: Base

    @inlinable
    init(base: Base) { self.base = base }

    /// The position of an edge of a complement: the cell of the adjacency matrix at row `source`
    /// and column `target`, both vertex indices, as `AdjacencyMatrix.Edges.Index`. Directed, the
    /// edge runs from the vertex at `source` to the one at `target`; undirected, `source < target`.
    /// Ordered row-major.
    @frozen
    public struct Cell: Hashable, Comparable, Sendable, CustomStringConvertible {
        /// The index of the source (undirected: the smaller end).
        public let source: Int
        /// The index of the target (undirected: the larger end).
        public let target: Int

        @inlinable
        public init(source: Int, target: Int) {
            self.source = source
            self.target = target
        }

        @inlinable
        public static func < (lhs: Cell, rhs: Cell) -> Bool {
            (lhs.source, lhs.target) < (rhs.source, rhs.target)
        }

        public var description: String { "(\(source), \(target))" }
    }

    /// A row of a complement in index space: every index in `0..<n` other than `index` that
    /// `row` does not list, ascending.
    @frozen
    public struct IndexRow<Row: Sequence<Int>>: Sequence {
        @usableFromInline let row: Row
        @usableFromInline let index: Int
        @usableFromInline let count: Int

        @inlinable
        init(row: Row, index: Int, count: Int) {
            self.row = row
            self.index = index
            self.count = count
        }

        @inlinable
        public func makeIterator() -> Iterator { Iterator(row: row, index: index, count: count) }

        @frozen
        public struct Iterator: IteratorProtocol {
            /// The base row as a mask, the vertex itself included.
            @usableFromInline let words: [UInt64]
            @usableFromInline let count: Int
            @usableFromInline var word: Int
            /// The clear bits of the current word still to yield, as set bits.
            @usableFromInline var pending: UInt64

            @inlinable
            init(row: Row, index: Int, count n: Int) {
                var words = [UInt64](repeating: 0, count: (n + 63) >> 6)
                words.withUnsafeMutableBufferPointer { words in
                    for j in row { words[j >> 6] |= 1 << UInt64(j & 63) }
                    words[index >> 6] |= 1 << UInt64(index & 63)
                }
                self.words = words
                count = n
                word = 0
                pending = words.isEmpty ? 0 : Iterator.clear(words[0], word: 0, count: n)
            }

            /// The bits of word `w` that are clear and below `count`, set.
            @inlinable
            @inline(__always)
            static func clear(_ bits: UInt64, word w: Int, count n: Int) -> UInt64 {
                let valid = n - (w << 6)
                let inRange: UInt64 = valid >= 64 ? ~0 : (1 << UInt64(valid)) &- 1
                return ~bits & inRange
            }

            @inlinable
            public mutating func next() -> Int? {
                while pending == 0 {
                    word += 1
                    guard word < words.count else { return nil }
                    pending = Iterator.clear(words[word], word: word, count: count)
                }
                let bit = pending.trailingZeroBitCount
                pending &= pending &- 1
                return (word << 6) | bit
            }
        }
    }

    /// A row of a complement's positions: `IndexRow`'s indices as cells.
    @frozen
    public struct CellRow<Row: Sequence<Int>>: Sequence {
        @usableFromInline let indices: IndexRow<Row>
        /// 0: out-edges `(index, j)`; 1: in-edges `(j, index)`; 2: undirected, smaller end first.
        @usableFromInline let orientation: Int

        @inlinable
        init(indices: IndexRow<Row>, orientation: Int) {
            self.indices = indices
            self.orientation = orientation
        }

        @inlinable
        public func makeIterator() -> Iterator { Iterator(base: indices.makeIterator(), index: indices.index, orientation: orientation) }

        @frozen
        public struct Iterator: IteratorProtocol {
            @usableFromInline var base: IndexRow<Row>.Iterator
            @usableFromInline let index: Int
            @usableFromInline let orientation: Int

            @inlinable
            init(base: IndexRow<Row>.Iterator, index: Int, orientation: Int) {
                self.base = base
                self.index = index
                self.orientation = orientation
            }

            @inlinable
            public mutating func next() -> Cell? {
                guard let j = base.next() else { return nil }
                switch orientation {
                case 0: return Cell(source: index, target: j)
                case 1: return Cell(source: j, target: index)
                default: return index < j ? Cell(source: index, target: j) : Cell(source: j, target: index)
                }
            }
        }
    }
}

extension ComplementView: Sendable where Base: Sendable {}
extension ComplementView.IndexRow: Sendable where Row: Sendable {}
extension ComplementView.CellRow: Sendable where Row: Sendable {}

/// The number of distinct indices other than `index` in `row`, by a mask of ⌈n/64⌉ words.
@inlinable
func _distinctOthers(_ row: some Sequence<Int>, index: Int, count n: Int) -> Int {
    var words = [UInt64](repeating: 0, count: (n + 63) >> 6)
    return words.withUnsafeMutableBufferPointer { words in
        for j in row { words[j >> 6] |= 1 << UInt64(j & 63) }
        words[index >> 6] &= ~(1 << UInt64(index & 63))
        var total = 0
        for w in words { total &+= w.nonzeroBitCount }
        return total
    }
}

/// The number of distinct indices other than the row's own, summed over every row. One stamp
/// array; O(n + m).
@inlinable
func _distinctOthersTotal<Row: Sequence<Int>>(count n: Int, row: (Int) -> Row) -> Int {
    var stamp = [Int](repeating: -1, count: n)
    var total = 0
    for i in 0 ..< n {
        for j in row(i) where j != i && stamp[j] != i {
            stamp[j] = i
            total &+= 1
        }
    }
    return total
}
