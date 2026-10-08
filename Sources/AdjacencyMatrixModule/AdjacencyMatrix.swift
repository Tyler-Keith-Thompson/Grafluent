import BitCollections
import GraphProtocols

/// A directed graph on the vertices `0..<vertexCount`, stored as a square matrix of bits: the
/// cell in row `source`, column `target` is set when there is an edge from `source` to `target`.
///
/// Self-loops are allowed (they are the diagonal); parallel edges cannot be represented. Edge
/// queries and degrees are O(1). `successors(of:)` and `predecessors(of:)` return a `BitSet`, so
/// membership tests are O(1) and set operations work a word at a time. Storage is about n²/8 bytes.
/// Vertices can be appended but not removed, because removing one would renumber every vertex
/// after it.
///
/// Successors, predecessors and edges are always in ascending order (edges row by row).
@frozen
public struct AdjacencyMatrix {
    /// The number of vertices.
    @usableFromInline
    internal var _vertexCount: Int

    /// The number of words in each row. Rows have room for `_wordsPerRow × 64` columns; this
    /// doubles when the vertex count outgrows it.
    @usableFromInline
    internal var _wordsPerRow: Int

    /// `_vertexCount` rows of `_wordsPerRow` words. Every bit in a column at or past
    /// `_vertexCount` is zero, so whole words can be compared, hashed and counted.
    @usableFromInline
    internal var _words: ContiguousArray<UInt>

    /// The number of set cells in each row.
    @usableFromInline
    internal var _outDegrees: ContiguousArray<Int>

    /// The number of set cells in each column.
    @usableFromInline
    internal var _inDegrees: ContiguousArray<Int>

    @usableFromInline
    internal var _edgeCount: Int

    /// The matrix with no vertices.
    @inlinable
    public init() {
        _vertexCount = 0
        _wordsPerRow = 0
        _words = []
        _outDegrees = []
        _inDegrees = []
        _edgeCount = 0
    }

    /// A matrix of `vertexCount` vertices and no edges.
    ///
    /// - Precondition: `vertexCount` is not negative, and the matrix's storage
    ///   (`vertexCount × ⌈vertexCount / 64⌉` words) fits in memory addressable by `Int`.
    @inlinable
    public init(vertexCount: Int) {
        Self._checkStorage(for: vertexCount)
        _vertexCount = vertexCount
        _wordsPerRow = Self._wordsNeeded(forColumns: vertexCount)
        _words = ContiguousArray(repeating: 0, count: vertexCount * _wordsPerRow)
        _outDegrees = ContiguousArray(repeating: 0, count: vertexCount)
        _inDegrees = ContiguousArray(repeating: 0, count: vertexCount)
        _edgeCount = 0
    }

    /// A matrix of `vertexCount` vertices in which every cell is `value`: with `true`, the complete
    /// directed graph with a self-loop on every vertex.
    @inlinable
    public init(vertexCount: Int, repeating value: Bool) {
        self.init(vertexCount: vertexCount)
        guard value, vertexCount > 0 else { return }
        let lastWordMask = Self._lowBits(vertexCount - (Self._wordsNeeded(forColumns: vertexCount) - 1) * UInt.bitWidth)
        let used = Self._wordsNeeded(forColumns: vertexCount)
        for row in 0 ..< vertexCount {
            for word in 0 ..< used {
                _words[row * _wordsPerRow + word] = word == used - 1 ? lastWordMask : ~0
            }
            _outDegrees[row] = vertexCount
            _inDegrees[row] = vertexCount
        }
        _edgeCount = vertexCount * vertexCount
    }

    /// A matrix of `vertexCount` vertices with the given edges. Repeated edges are inserted once.
    ///
    /// - Precondition: every endpoint is in `0..<vertexCount`.
    @inlinable
    public init(vertexCount: Int, edges: some Sequence<DirectedEdge<Int>>) {
        self.init(vertexCount: vertexCount)
        for edge in edges { insert(edge: edge) }
    }
}

// MARK: - Storage

extension AdjacencyMatrix {
    @inlinable
    @inline(__always)
    internal static func _wordsNeeded(forColumns columns: Int) -> Int {
        (columns + UInt.bitWidth - 1) / UInt.bitWidth
    }

    /// A word with its lowest `count` bits set (`count` in 1...64).
    @inlinable
    @inline(__always)
    internal static func _lowBits(_ count: Int) -> UInt {
        count >= UInt.bitWidth ? ~0 : (1 &<< UInt(count)) &- 1
    }

    @inlinable
    @inline(__always)
    internal static func _mask(_ column: Int) -> UInt {
        1 &<< UInt(column & (UInt.bitWidth - 1))
    }

    @inlinable
    @inline(__always)
    internal func _wordIndex(_ row: Int, _ column: Int) -> Int {
        row &* _wordsPerRow &+ (column / UInt.bitWidth)
    }

    @inlinable
    @inline(__always)
    internal func _bit(_ row: Int, _ column: Int) -> Bool {
        _words[_wordIndex(row, column)] & Self._mask(column) != 0
    }

    @inlinable
    internal static func _checkStorage(for vertexCount: Int) {
        precondition(vertexCount >= 0, "Negative vertex count")
        let words = vertexCount.multipliedReportingOverflow(by: _wordsNeeded(forColumns: vertexCount))
        precondition(!words.overflow && !words.partialValue.multipliedReportingOverflow(by: MemoryLayout<UInt>.size).overflow, "Vertex count \(vertexCount) is too large for a matrix")
    }

    @inlinable
    @inline(__always)
    internal func _checkVertex(_ vertex: Int) {
        precondition(vertex >= 0 && vertex < _vertexCount, "Vertex \(vertex) is out of range 0..<\(_vertexCount)")
    }

    /// Moves the rows into storage of `wordsPerRow` words each.
    @inlinable
    internal mutating func _restride(wordsPerRow: Int) {
        guard wordsPerRow != _wordsPerRow else { return }
        let used = Self._wordsNeeded(forColumns: _vertexCount)
        var words = ContiguousArray<UInt>(repeating: 0, count: _vertexCount * wordsPerRow)
        for row in 0 ..< _vertexCount {
            for word in 0 ..< used {
                words[row * wordsPerRow + word] = _words[row * _wordsPerRow + word]
            }
        }
        _words = words
        _wordsPerRow = wordsPerRow
    }

    /// Recounts every degree and the edge count from the words, after a whole-matrix operation.
    @inlinable
    internal mutating func _recountDegrees() {
        let n = _vertexCount
        let used = Self._wordsNeeded(forColumns: n)
        for column in 0 ..< n { _inDegrees[column] = 0 }
        var total = 0
        for row in 0 ..< n {
            var rowCount = 0
            for word in 0 ..< used {
                var bits = _words[row * _wordsPerRow + word]
                rowCount &+= bits.nonzeroBitCount
                while bits != 0 {
                    _inDegrees[word * UInt.bitWidth + bits.trailingZeroBitCount] &+= 1
                    bits &= bits &- 1
                }
            }
            _outDegrees[row] = rowCount
            total &+= rowCount
        }
        _edgeCount = total
    }

    /// Clears any bits in columns at or past `_vertexCount` (after a whole-row bitwise operation).
    @inlinable
    internal mutating func _clearPadding() {
        let n = _vertexCount
        guard n > 0 else { return }
        let used = Self._wordsNeeded(forColumns: n)
        let lastMask = Self._lowBits(n - (used - 1) * UInt.bitWidth)
        for row in 0 ..< n {
            _words[row * _wordsPerRow + used - 1] &= lastMask
            for word in used ..< _wordsPerRow {
                _words[row * _wordsPerRow + word] = 0
            }
        }
    }

    /// Applies `combine(self word, other word)` to every word of both matrices.
    @inlinable
    internal mutating func _combine(with other: AdjacencyMatrix, _ combine: (UInt, UInt) -> UInt) {
        precondition(other._vertexCount == _vertexCount, "Matrices have different vertex counts (\(_vertexCount) and \(other._vertexCount))")
        let used = Self._wordsNeeded(forColumns: _vertexCount)
        for row in 0 ..< _vertexCount {
            for word in 0 ..< used {
                let index = row * _wordsPerRow + word
                _words[index] = combine(_words[index], other._words[row * other._wordsPerRow + word])
            }
        }
        _clearPadding()
        _recountDegrees()
    }
}

// MARK: - Queries

extension AdjacencyMatrix {
    /// The number of vertices.
    @inlinable
    public var vertexCount: Int { _vertexCount }

    /// The number of edges.
    @inlinable
    public var edgeCount: Int { _edgeCount }

    /// The vertices: `0..<vertexCount`.
    @inlinable
    public var vertices: Range<Int> { 0 ..< _vertexCount }

    /// Whether `vertex` is in `0..<vertexCount`.
    @inlinable
    public func contains(_ vertex: Int) -> Bool {
        vertex >= 0 && vertex < _vertexCount
    }

    /// Whether `edge` is an edge. False when either endpoint is out of range.
    @inlinable
    public func contains(edge: DirectedEdge<Int>) -> Bool {
        guard contains(edge.source), contains(edge.target) else { return false }
        return _bit(edge.source, edge.target)
    }

    /// Whether there is an edge from `source` to `target`. Setting the cell inserts or removes
    /// that edge.
    ///
    /// - Precondition: both are in `0..<vertexCount`.
    @inlinable
    public subscript(source: Int, target: Int) -> Bool {
        get {
            _checkVertex(source)
            _checkVertex(target)
            return _bit(source, target)
        }
        set {
            _checkVertex(source)
            _checkVertex(target)
            _setCell(source, target, to: newValue)
        }
        _modify {
            _checkVertex(source)
            _checkVertex(target)
            var value = _bit(source, target)
            defer { _setCell(source, target, to: value) }
            yield &value
        }
    }

    /// The vertices `vertex` has an edge to, in ascending order: its row. O(n / 64).
    ///
    /// - Precondition: `vertex` is in `0..<vertexCount`.
    @inlinable
    public func successors(of vertex: Int) -> BitSet {
        _checkVertex(vertex)
        let start = vertex * _wordsPerRow
        return BitSet(words: _words[start ..< start + Self._wordsNeeded(forColumns: _vertexCount)])
    }

    /// The vertices that have an edge to `vertex`, in ascending order: its column. O(n).
    ///
    /// - Precondition: `vertex` is in `0..<vertexCount`.
    @inlinable
    public func predecessors(of vertex: Int) -> BitSet {
        _checkVertex(vertex)
        var words = [UInt](repeating: 0, count: Self._wordsNeeded(forColumns: _vertexCount))
        let mask = Self._mask(vertex)
        let wordInRow = vertex / UInt.bitWidth
        for row in 0 ..< _vertexCount where _words[row &* _wordsPerRow &+ wordInRow] & mask != 0 {
            words[row / UInt.bitWidth] |= Self._mask(row)
        }
        return BitSet(words: words)
    }

    /// The number of edges leaving `vertex`. O(1).
    ///
    /// - Precondition: `vertex` is in `0..<vertexCount`.
    @inlinable
    public func outDegree(of vertex: Int) -> Int {
        _checkVertex(vertex)
        return _outDegrees[vertex]
    }

    /// The number of edges entering `vertex`. O(1).
    ///
    /// - Precondition: `vertex` is in `0..<vertexCount`.
    @inlinable
    public func inDegree(of vertex: Int) -> Int {
        _checkVertex(vertex)
        return _inDegrees[vertex]
    }

    /// `outDegree(of:) + inDegree(of:)`. A self-loop counts twice: once leaving and once entering.
    ///
    /// - Precondition: `vertex` is in `0..<vertexCount`.
    @inlinable
    public func degree(of vertex: Int) -> Int {
        _checkVertex(vertex)
        return _outDegrees[vertex] + _inDegrees[vertex]
    }
}

// MARK: - Mutation

extension AdjacencyMatrix {
    @inlinable
    internal mutating func _setCell(_ source: Int, _ target: Int, to value: Bool) {
        let index = _wordIndex(source, target)
        let mask = Self._mask(target)
        // Read before writing, so a write that changes nothing never copies shared storage.
        guard (_words[index] & mask != 0) != value else { return }
        if value {
            _words[index] |= mask
            _outDegrees[source] += 1
            _inDegrees[target] += 1
            _edgeCount += 1
        } else {
            _words[index] &= ~mask
            _outDegrees[source] -= 1
            _inDegrees[target] -= 1
            _edgeCount -= 1
        }
    }

    /// Inserts `edge`, if it is not already an edge.
    ///
    /// - Precondition: both endpoints are in `0..<vertexCount`. The matrix never grows to fit an
    ///   edge; use `appendVertex()`.
    @inlinable
    @discardableResult
    public mutating func insert(edge: DirectedEdge<Int>) -> (inserted: Bool, memberAfterInsert: DirectedEdge<Int>) {
        _checkVertex(edge.source)
        _checkVertex(edge.target)
        if _bit(edge.source, edge.target) { return (false, edge) }
        _setCell(edge.source, edge.target, to: true)
        return (true, edge)
    }

    /// Removes `edge`.
    ///
    /// - Returns: The removed edge, or `nil` if it was not an edge (including when an endpoint is
    ///   out of range).
    @inlinable
    @discardableResult
    public mutating func remove(edge: DirectedEdge<Int>) -> DirectedEdge<Int>? {
        guard contains(edge: edge) else { return nil }
        _setCell(edge.source, edge.target, to: false)
        return edge
    }

    /// Inserts an edge from `source` to each vertex in `targets`: the row becomes the union of
    /// itself and `targets`.
    ///
    /// - Returns: The number of edges inserted.
    /// - Precondition: `source` and every member of `targets` are in `0..<vertexCount`.
    @inlinable
    @discardableResult
    public mutating func insertEdges(from source: Int, to targets: BitSet) -> Int {
        _checkVertex(source)
        if let last = targets.last { _checkVertex(last) }
        var inserted = 0
        for target in targets where !_bit(source, target) {
            _setCell(source, target, to: true)
            inserted += 1
        }
        return inserted
    }

    /// Removes every edge leaving `vertex`: clears its row.
    ///
    /// - Returns: The number of edges removed.
    @inlinable
    @discardableResult
    public mutating func removeEdges(from vertex: Int) -> Int {
        _checkVertex(vertex)
        let removed = _outDegrees[vertex]
        guard removed > 0 else { return 0 }
        let start = vertex * _wordsPerRow
        for word in 0 ..< Self._wordsNeeded(forColumns: _vertexCount) {
            var bits = _words[start + word]
            while bits != 0 {
                _inDegrees[word * UInt.bitWidth + bits.trailingZeroBitCount] -= 1
                bits &= bits &- 1
            }
            _words[start + word] = 0
        }
        _outDegrees[vertex] = 0
        _edgeCount -= removed
        return removed
    }

    /// Removes every edge entering `vertex`: clears its column.
    ///
    /// - Returns: The number of edges removed.
    @inlinable
    @discardableResult
    public mutating func removeEdges(to vertex: Int) -> Int {
        _checkVertex(vertex)
        let removed = _inDegrees[vertex]
        guard removed > 0 else { return 0 }
        let mask = Self._mask(vertex)
        let wordInRow = vertex / UInt.bitWidth
        for row in 0 ..< _vertexCount {
            let index = row * _wordsPerRow + wordInRow
            if _words[index] & mask != 0 {
                _words[index] &= ~mask
                _outDegrees[row] -= 1
            }
        }
        _inDegrees[vertex] = 0
        _edgeCount -= removed
        return removed
    }

    /// Removes every edge leaving or entering `vertex`, keeping the vertex. (Boost.Graph calls this
    /// `clear_vertex`.)
    ///
    /// - Returns: The number of edges removed. A self-loop counts once.
    @inlinable
    @discardableResult
    public mutating func removeEdges(incidentTo vertex: Int) -> Int {
        removeEdges(from: vertex) + removeEdges(to: vertex)
    }

    /// Adds a vertex with no edges.
    ///
    /// - Returns: The new vertex, which is the old `vertexCount`.
    /// - Complexity: Amortized O(n / 64). Rows are appended; the rows are moved only when the
    ///   number of columns outgrows the words per row, which then doubles.
    @inlinable
    @discardableResult
    public mutating func appendVertex() -> Int {
        let vertex = _vertexCount
        Self._checkStorage(for: vertex + 1)
        if vertex + 1 > _wordsPerRow * UInt.bitWidth {
            _restride(wordsPerRow: Swift.max(1, _wordsPerRow * 2))
        }
        // The new column is already zero: every bit past the last column is.
        _words.append(contentsOf: repeatElement(0, count: _wordsPerRow))
        _outDegrees.append(0)
        _inDegrees.append(0)
        _vertexCount += 1
        return vertex
    }

    /// Removes every edge, keeping every vertex.
    ///
    /// - Parameter keepingCapacity: When false, any spare row capacity is released.
    @inlinable
    public mutating func removeAllEdges(keepingCapacity: Bool = false) {
        if keepingCapacity {
            guard _edgeCount > 0 else { return }
            for index in _words.indices { _words[index] = 0 }
            for vertex in 0 ..< _vertexCount {
                _outDegrees[vertex] = 0
                _inDegrees[vertex] = 0
            }
            _edgeCount = 0
        } else {
            // Fresh zeroed storage: never copies shared words just to overwrite them.
            self = AdjacencyMatrix(vertexCount: _vertexCount)
        }
    }

    /// Removes every vertex and edge.
    @inlinable
    public mutating func removeAll(keepingCapacity: Bool = false) {
        if keepingCapacity {
            _words.removeAll(keepingCapacity: true)
            _outDegrees.removeAll(keepingCapacity: true)
            _inDegrees.removeAll(keepingCapacity: true)
            _vertexCount = 0
            _edgeCount = 0
        } else {
            self = AdjacencyMatrix()
        }
    }

    /// Reserves storage for at least `vertexCount` vertices.
    @inlinable
    public mutating func reserveCapacity(vertexCount: Int) {
        Self._checkStorage(for: vertexCount)
        let wordsPerRow = Self._wordsNeeded(forColumns: vertexCount)
        if wordsPerRow > _wordsPerRow {
            _restride(wordsPerRow: wordsPerRow)
        }
        _words.reserveCapacity(vertexCount * _wordsPerRow)
        _outDegrees.reserveCapacity(vertexCount)
        _inDegrees.reserveCapacity(vertexCount)
    }
}

// MARK: - Whole-matrix operations

extension AdjacencyMatrix {
    /// Inserts every edge of `other`.
    ///
    /// - Precondition: both have the same vertex count.
    @inlinable
    public mutating func formUnion(_ other: AdjacencyMatrix) {
        _combine(with: other) { $0 | $1 }
    }

    /// The edges in either matrix.
    @inlinable
    public func union(_ other: AdjacencyMatrix) -> AdjacencyMatrix {
        var result = self
        result.formUnion(other)
        return result
    }

    /// Keeps only the edges also in `other`.
    ///
    /// - Precondition: both have the same vertex count.
    @inlinable
    public mutating func formIntersection(_ other: AdjacencyMatrix) {
        _combine(with: other) { $0 & $1 }
    }

    /// The edges in both matrices.
    @inlinable
    public func intersection(_ other: AdjacencyMatrix) -> AdjacencyMatrix {
        var result = self
        result.formIntersection(other)
        return result
    }

    /// Removes every edge that is in `other`.
    ///
    /// - Precondition: both have the same vertex count.
    @inlinable
    public mutating func subtract(_ other: AdjacencyMatrix) {
        _combine(with: other) { $0 & ~$1 }
    }

    /// The edges in this matrix but not in `other`.
    @inlinable
    public func subtracting(_ other: AdjacencyMatrix) -> AdjacencyMatrix {
        var result = self
        result.subtract(other)
        return result
    }

    /// Keeps the edges in exactly one of the two matrices.
    ///
    /// - Precondition: both have the same vertex count.
    @inlinable
    public mutating func formSymmetricDifference(_ other: AdjacencyMatrix) {
        _combine(with: other) { $0 ^ $1 }
    }

    /// The edges in exactly one of the two matrices.
    @inlinable
    public func symmetricDifference(_ other: AdjacencyMatrix) -> AdjacencyMatrix {
        var result = self
        result.formSymmetricDifference(other)
        return result
    }

    /// The complement graph: an edge exactly where this matrix has none.
    ///
    /// - Parameter includingSelfLoops: Whether the diagonal is complemented too. NetworkX's
    ///   `complement` leaves self-loops out, which is the default here.
    @inlinable
    public func complement(includingSelfLoops: Bool = false) -> AdjacencyMatrix {
        var result = self
        let used = Self._wordsNeeded(forColumns: _vertexCount)
        for row in 0 ..< _vertexCount {
            for word in 0 ..< used {
                result._words[row * _wordsPerRow + word] = ~_words[row * _wordsPerRow + word]
            }
        }
        result._clearPadding()
        if !includingSelfLoops {
            for v in 0 ..< _vertexCount {
                result._words[result._wordIndex(v, v)] &= ~Self._mask(v)
            }
        }
        result._recountDegrees()
        return result
    }

    /// The matrix with every edge reversed: cell (i, j) of the result is cell (j, i) of this one.
    @inlinable
    public func transposed() -> AdjacencyMatrix {
        var result = AdjacencyMatrix(vertexCount: _vertexCount)
        let used = Self._wordsNeeded(forColumns: _vertexCount)
        for row in 0 ..< _vertexCount {
            for word in 0 ..< used {
                var bits = _words[row * _wordsPerRow + word]
                while bits != 0 {
                    let column = word * UInt.bitWidth + bits.trailingZeroBitCount
                    result._words[result._wordIndex(column, row)] |= Self._mask(row)
                    bits &= bits &- 1
                }
            }
        }
        result._outDegrees = _inDegrees
        result._inDegrees = _outDegrees
        result._edgeCount = _edgeCount
        return result
    }
}

extension AdjacencyMatrix: ExpressibleByArrayLiteral {
    /// A matrix from rows of 0s and 1s: row `i`, column `j` is 1 when there is an edge from `i`
    /// to `j`.
    ///
    /// - Precondition: the rows form a square, and every entry is 0 or 1.
    @inlinable
    public init(arrayLiteral rows: [Int]...) {
        self.init(vertexCount: rows.count)
        for (source, row) in rows.enumerated() {
            precondition(row.count == rows.count, "Row \(source) has \(row.count) entries; a \(rows.count)-row matrix needs \(rows.count)")
            for (target, entry) in row.enumerated() {
                precondition(entry == 0 || entry == 1, "Entry [\(source), \(target)] is \(entry); entries must be 0 or 1")
                if entry == 1 { _setCell(source, target, to: true) }
            }
        }
    }
}

// MARK: - Edges

extension AdjacencyMatrix {
    /// The edges, row by row, each row in ascending column order.
    @inlinable
    public var edges: Edges { Edges(matrix: self) }

    /// Every edge, in row-major order. A value: unaffected by later changes to the matrix (holding
    /// one while mutating the matrix makes the mutation copy the matrix, as with any copy).
    @frozen
    public struct Edges: BidirectionalCollection {
        @usableFromInline let matrix: AdjacencyMatrix
        @usableFromInline let _startIndex: Index

        @inlinable
        init(matrix: AdjacencyMatrix) {
            self.matrix = matrix
            self._startIndex = Self._next(in: matrix, atOrAfter: Index(source: 0, target: 0))
        }

        /// A position is a cell: an edge's source and target. Positions compare row-major, and a
        /// position names the same cell after the matrix grows.
        @frozen
        public struct Index: Comparable, Hashable, Sendable {
            public let source: Int
            public let target: Int

            @inlinable
            init(source: Int, target: Int) {
                self.source = source
                self.target = target
            }

            @inlinable
            public static func < (lhs: Index, rhs: Index) -> Bool {
                (lhs.source, lhs.target) < (rhs.source, rhs.target)
            }
        }

        /// The first set cell at or after `position`, scanning a word at a time, or `endIndex`.
        @inlinable
        static func _next(in matrix: AdjacencyMatrix, atOrAfter position: Index) -> Index {
            let n = matrix._vertexCount
            let used = AdjacencyMatrix._wordsNeeded(forColumns: n)
            var row = position.source
            var column = position.target
            while row < n {
                if column < n {
                    var word = column / UInt.bitWidth
                    var bits = matrix._words[row * matrix._wordsPerRow + word] & ~(AdjacencyMatrix._mask(column) &- 1)
                    while true {
                        if bits != 0 {
                            return Index(source: row, target: word * UInt.bitWidth + bits.trailingZeroBitCount)
                        }
                        word += 1
                        if word >= used { break }
                        bits = matrix._words[row * matrix._wordsPerRow + word]
                    }
                }
                row += 1
                column = 0
            }
            return Index(source: n, target: 0)
        }

        /// The last set cell before `position`, scanning a word at a time, or nil.
        @inlinable
        static func _previous(in matrix: AdjacencyMatrix, before position: Index) -> Index? {
            let n = matrix._vertexCount
            let used = AdjacencyMatrix._wordsNeeded(forColumns: n)
            var row = Swift.min(position.source, n)
            // The number of columns of `row` still to consider, counting from column 0.
            var limit = row == n ? 0 : position.target
            while true {
                if limit > 0 {
                    var word = (limit - 1) / UInt.bitWidth
                    let topBit = (limit - 1) % UInt.bitWidth
                    var bits = matrix._words[row * matrix._wordsPerRow + word] & AdjacencyMatrix._lowBits(topBit + 1)
                    while true {
                        if bits != 0 {
                            return Index(source: row, target: word * UInt.bitWidth + (UInt.bitWidth - 1 - bits.leadingZeroBitCount))
                        }
                        if word == 0 { break }
                        word -= 1
                        bits = matrix._words[row * matrix._wordsPerRow + word]
                    }
                }
                if row == 0 { return nil }
                row -= 1
                limit = used * UInt.bitWidth
            }
        }

        @inlinable public var startIndex: Index { _startIndex }
        @inlinable public var endIndex: Index { Index(source: matrix._vertexCount, target: 0) }
        @inlinable public var count: Int { matrix._edgeCount }
        @inlinable public var isEmpty: Bool { matrix._edgeCount == 0 }

        @inlinable
        public func index(after i: Index) -> Index {
            precondition(i >= _startIndex && i < endIndex, "Index out of bounds")
            return Self._next(in: matrix, atOrAfter: Index(source: i.source, target: i.target + 1))
        }

        @inlinable
        public func index(before i: Index) -> Index {
            precondition(i > _startIndex && i <= endIndex, "Index out of bounds")
            guard let previous = Self._previous(in: matrix, before: i) else {
                preconditionFailure("Index out of bounds")
            }
            return previous
        }

        @inlinable
        public subscript(position: Index) -> DirectedEdge<Int> {
            let edge = DirectedEdge(from: position.source, to: position.target)
            precondition(matrix.contains(edge: edge), "Invalid index: no edge at \(position.source), \(position.target)")
            return edge
        }

        @inlinable
        public func _customContainsEquatableElement(_ element: DirectedEdge<Int>) -> Bool? {
            matrix.contains(edge: element)
        }

        @inlinable
        public func makeIterator() -> Iterator {
            Iterator(matrix: matrix)
        }

        /// Walks the set bits a word at a time.
        @frozen
        public struct Iterator: IteratorProtocol {
            @usableFromInline let matrix: AdjacencyMatrix
            @usableFromInline var row: Int
            @usableFromInline var word: Int
            @usableFromInline var bits: UInt

            @inlinable
            init(matrix: AdjacencyMatrix) {
                self.matrix = matrix
                self.row = 0
                self.word = 0
                self.bits = matrix._vertexCount > 0 ? matrix._words[0] : 0
            }

            @inlinable
            public mutating func next() -> DirectedEdge<Int>? {
                let n = matrix._vertexCount
                let used = AdjacencyMatrix._wordsNeeded(forColumns: n)
                while bits == 0 {
                    word += 1
                    if word >= used {
                        word = 0
                        row += 1
                        if row >= n { return nil }
                    }
                    bits = matrix._words[row * matrix._wordsPerRow + word]
                }
                let target = word * UInt.bitWidth + bits.trailingZeroBitCount
                bits &= bits &- 1
                return DirectedEdge(from: row, to: target)
            }
        }
    }
}

// MARK: - Equatable and Hashable

extension AdjacencyMatrix: Equatable {
    /// Equal when the vertex counts and every cell are equal. Capacity is not compared.
    @inlinable
    public static func == (lhs: AdjacencyMatrix, rhs: AdjacencyMatrix) -> Bool {
        guard lhs._vertexCount == rhs._vertexCount, lhs._edgeCount == rhs._edgeCount else { return false }
        let used = _wordsNeeded(forColumns: lhs._vertexCount)
        for row in 0 ..< lhs._vertexCount {
            for word in 0 ..< used where lhs._words[row * lhs._wordsPerRow + word] != rhs._words[row * rhs._wordsPerRow + word] {
                return false
            }
        }
        return true
    }
}

extension AdjacencyMatrix: Hashable {
    @inlinable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(_vertexCount)
        let used = Self._wordsNeeded(forColumns: _vertexCount)
        _words.withUnsafeBytes { bytes in
            let rowBytes = _wordsPerRow * MemoryLayout<UInt>.size
            for row in 0 ..< _vertexCount {
                hasher.combine(bytes: UnsafeRawBufferPointer(rebasing: bytes[row * rowBytes ..< row * rowBytes + used * MemoryLayout<UInt>.size]))
            }
        }
    }
}

// MARK: - Sendable

extension AdjacencyMatrix: Sendable {}
extension AdjacencyMatrix.Edges: Sendable {}
extension AdjacencyMatrix.Edges.Iterator: Sendable {}

// MARK: - Codable

extension AdjacencyMatrix: Codable {
    @usableFromInline
    internal enum _CodingKeys: String, CodingKey {
        case vertexCount
        case edges
    }

    /// The `userInfo` key for the largest vertex count a decoder accepts. Its value is an `Int`.
    public static let maximumDecodedVertexCountKey = CodingUserInfoKey(rawValue: "AdjacencyMatrix.maximumDecodedVertexCount")!

    /// The largest vertex count decoded by default: 16,384 vertices, 32 MiB of cells. A tiny payload
    /// can name an enormous vertex count, so decoding refuses anything larger unless the decoder's
    /// `userInfo[maximumDecodedVertexCountKey]` allows it.
    public static let defaultMaximumDecodedVertexCount = 16_384

    /// Encodes `{"vertexCount": n, "edges": [source₀, target₀, source₁, target₁, …]}`, with the
    /// edges in row-major order, so the encoding of a matrix is always the same.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: _CodingKeys.self)
        try container.encode(_vertexCount, forKey: .vertexCount)
        var flat: [Int] = []
        flat.reserveCapacity(2 * _edgeCount)
        for edge in edges {
            flat.append(edge.source)
            flat.append(edge.target)
        }
        try container.encode(flat, forKey: .edges)
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: _CodingKeys.self)
        let vertexCount = try container.decode(Int.self, forKey: .vertexCount)
        let maximum = decoder.userInfo[Self.maximumDecodedVertexCountKey] as? Int ?? Self.defaultMaximumDecodedVertexCount
        guard vertexCount >= 0 else {
            throw DecodingError.dataCorruptedError(forKey: .vertexCount, in: container, debugDescription: "Negative vertex count")
        }
        guard vertexCount <= maximum else {
            throw DecodingError.dataCorruptedError(forKey: .vertexCount, in: container, debugDescription: "Vertex count \(vertexCount) exceeds the decoding limit of \(maximum)")
        }
        let flat = try container.decode([Int].self, forKey: .edges)
        guard flat.count.isMultiple(of: 2) else {
            throw DecodingError.dataCorruptedError(forKey: .edges, in: container, debugDescription: "Edge list has odd length")
        }
        self.init(vertexCount: vertexCount)
        for i in stride(from: 0, to: flat.count, by: 2) {
            let edge = DirectedEdge(from: flat[i], to: flat[i + 1])
            guard contains(edge.source), contains(edge.target) else {
                throw DecodingError.dataCorruptedError(forKey: .edges, in: container, debugDescription: "Edge endpoint out of range")
            }
            guard insert(edge: edge).inserted else {
                throw DecodingError.dataCorruptedError(forKey: .edges, in: container, debugDescription: "Repeated edge")
            }
        }
    }
}

// MARK: - Descriptions

extension AdjacencyMatrix: CustomStringConvertible, CustomDebugStringConvertible {
    /// The largest matrix whose `description` is the full grid of cells.
    public static let maximumDescribedVertexCount = 64

    /// For up to 64 vertices, the rows of the matrix as 0s and 1s, column 0 leftmost, one row per
    /// line. Larger matrices are summarized, so printing one (as a failed test does) stays small.
    public var description: String {
        guard _vertexCount <= Self.maximumDescribedVertexCount else {
            return "AdjacencyMatrix(vertexCount: \(_vertexCount), edgeCount: \(_edgeCount))"
        }
        var result = ""
        result.reserveCapacity(_vertexCount * (_vertexCount + 1))
        for row in 0 ..< _vertexCount {
            if row > 0 { result.append("\n") }
            for column in 0 ..< _vertexCount {
                result.append(_bit(row, column) ? "1" : "0")
            }
        }
        return result
    }

    /// The counts and the first 16 edges.
    public var debugDescription: String {
        let shown = edges.prefix(16).map { "\($0)" }.joined(separator: ", ")
        let more = _edgeCount > 16 ? ", …" : ""
        return "AdjacencyMatrix(vertexCount: \(_vertexCount), edgeCount: \(_edgeCount), edges: [\(shown)\(more)])"
    }
}
