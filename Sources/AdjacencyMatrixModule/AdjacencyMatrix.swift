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
/// Attached edge maps (`addEdgeMap(default:)`) are dense: each stores one value for every cell,
/// n² values whatever the edge count, so a map of `Value` takes n² · `MemoryLayout<Value>.stride`
/// bytes.
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

    /// The edge count and the generation, then each vertex's out-degree (the set cells in its row)
    /// and in-degree (in its column), interleaved: see `_headerCount`. One array, so a mutation
    /// makes one buffer unique for all of them, and the generation is written where the degrees
    /// already are.
    @usableFromInline
    internal var _degrees: ContiguousArray<Int>

    /// The attached vertex maps (`addVertexMap(default:)`): dense, one value per vertex.
    @usableFromInline
    internal var _vertexMaps: _AttachedMaps

    /// The attached edge maps (`addEdgeMap(default:)`): dense, one value per cell at the cell's
    /// Szudzik offset (`_edgeMapOffset(of:)`). Every cell that holds no edge holds the default.
    @usableFromInline
    internal var _edgeMaps: _AttachedMaps

    /// The matrix with no vertices.
    @inlinable
    public init() {
        _vertexCount = 0
        _wordsPerRow = 0
        _words = []
        _degrees = Self._degreeStorage(wordsPerRow: 0)
        _vertexMaps = _AttachedMaps()
        _edgeMaps = _AttachedMaps()
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
        _degrees = Self._degreeStorage(wordsPerRow: _wordsPerRow)
        _vertexMaps = _AttachedMaps()
        _edgeMaps = _AttachedMaps()
    }

    /// A matrix of `vertexCount` vertices in which every cell is `value`. With `true`, it is the
    /// complete directed graph with a self-loop on every vertex.
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
            _degrees[Self._outSlot(row)] = vertexCount
            _degrees[_inSlot(row)] = vertexCount
        }
        _edgeCount = vertexCount * vertexCount
    }

    /// A matrix of `vertexCount` vertices with the given edges. Repeated edges are inserted once.
    ///
    /// - Precondition: Every endpoint is in `0..<vertexCount`.
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

    // `_degrees` holds the edge count in slot 0 and the generation in slots 1–3 (see
    // GraphGeneration.swift): the version, the lineage, and the address of the array's first
    // element after the last structural mutation (0: unknown). Then come the out-degrees, one slot
    // per column the rows have room for (`_wordsPerRow × 64`), then as many in-degrees. Appending a
    // vertex therefore writes no degree, and a degree's address is one shifted index. Every slot
    // past the last vertex holds 0. The array is the generation's identity array and the stamp
    // lives in it, so a mutation writes the version into the buffer it has already made unique for
    // the degrees.
    //
    // The stamp and the edge count stay out of stored properties because the optimizer splits a
    // struct into registers through a loop only when it has at most six scalar and reference fields
    // (SIL's `shouldExpand`). Only then does it check the arrays' uniqueness once for the loop
    // instead of on every insertion. The six are `_vertexCount`, `_wordsPerRow`, `_words`,
    // `_degrees` and the two map tables.

    /// The slots before the first degree.
    @inlinable
    @inline(__always)
    internal static var _headerCount: Int { 4 }

    /// The slot of `vertex`'s out-degree.
    @inlinable
    @inline(__always)
    internal static func _outSlot(_ vertex: Int) -> Int { _headerCount &+ vertex }

    /// The slot of `vertex`'s in-degree.
    @inlinable
    @inline(__always)
    internal func _inSlot(_ vertex: Int) -> Int { Self._headerCount &+ _wordsPerRow &* UInt.bitWidth &+ vertex }

    /// The degree array for rows of `wordsPerRow` words, with no edges and no generation.
    @inlinable
    internal static func _degreeStorage(wordsPerRow: Int) -> ContiguousArray<Int> {
        ContiguousArray(repeating: 0, count: _headerCount &+ 2 &* wordsPerRow &* UInt.bitWidth)
    }

    /// The degree array for rows of `wordsPerRow` words, with no edges and the generation of
    /// `old`, in a new buffer (so the generation's next advance starts a new lineage).
    @inlinable
    internal static func _degreeStorage(wordsPerRow: Int, stamp old: ContiguousArray<Int>) -> ContiguousArray<Int> {
        var degrees = _degreeStorage(wordsPerRow: wordsPerRow)
        degrees[1] = old[1]
        degrees[2] = old[2]
        degrees[3] = old[3]
        return degrees
    }

    /// The number of edges: slot 0 of `_degrees`.
    @inlinable
    internal var _edgeCount: Int {
        @inline(__always) get { _degrees.withUnsafeBufferPointer { $0.baseAddress.unsafelyUnwrapped[0] } }
        @inline(__always) set { _degrees.withUnsafeMutableBufferPointer { $0.baseAddress.unsafelyUnwrapped[0] = newValue } }
    }

    /// The degree in `slot` (`_outSlot(_:)` or `_inSlot(_:)` of a vertex), unchecked.
    @inlinable
    @inline(__always)
    internal func _degree(at slot: Int) -> Int {
        _degrees.withUnsafeBufferPointer { $0.baseAddress.unsafelyUnwrapped[slot] }
    }

    /// Starts a new generation after a structural mutation: makes `_degrees` unique (a copy that
    /// shared it is then told apart by the address) and advances the stamp in it.
    @inlinable
    @inline(__always)
    internal mutating func _advanceGeneration() {
        _degrees.withUnsafeMutableBufferPointer { Self._advanceGeneration(in: $0.baseAddress.unsafelyUnwrapped) }
    }

    /// Advances the stamp at the front of a unique `_degrees` buffer: one more version while the
    /// buffer is the one the stamp was last advanced in, else a new lineage at version 0.
    @inlinable
    @inline(__always)
    internal static func _advanceGeneration(in degrees: UnsafeMutablePointer<Int>) {
        if _slowPath(degrees[3] != Int(bitPattern: degrees)) { _startLineage(in: degrees) }
        degrees[1] &+= 1
    }

    /// Starts a new lineage in the stamp, one version before 0: `_advanceGeneration(in:)` then
    /// advances it to 0.
    @usableFromInline
    @inline(never)
    internal static func _startLineage(in degrees: UnsafeMutablePointer<Int>) {
        degrees[1] = -1
        degrees[2] = Int(truncatingIfNeeded: _GenerationStamp._newLineage())
        degrees[3] = Int(bitPattern: degrees)
    }

    /// Forgets the stamp's address if `_degrees` moved without a structural mutation (reserving
    /// capacity), so the freed buffer's address, reused later, can never match: the next
    /// structural mutation starts a new lineage.
    @inlinable
    internal mutating func _degreeStorageMayHaveMoved() {
        _degrees.withUnsafeMutableBufferPointer { buffer in
            let degrees = buffer.baseAddress.unsafelyUnwrapped
            if degrees[3] != Int(bitPattern: degrees) { degrees[3] = 0 }
        }
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
        var degrees = Self._degreeStorage(wordsPerRow: wordsPerRow, stamp: _degrees)
        degrees[0] = _edgeCount
        let inBase = Self._headerCount &+ wordsPerRow &* UInt.bitWidth
        for vertex in 0 ..< _vertexCount {
            degrees[Self._outSlot(vertex)] = _degree(at: Self._outSlot(vertex))
            degrees[inBase &+ vertex] = _degree(at: _inSlot(vertex))
        }
        _words = words
        _degrees = degrees
        _wordsPerRow = wordsPerRow
    }

    /// Recounts every degree and the edge count from the words, after a whole-matrix operation.
    @inlinable
    internal mutating func _recountDegrees() {
        let n = _vertexCount
        let used = Self._wordsNeeded(forColumns: n)
        for column in 0 ..< n { _degrees[_inSlot(column)] = 0 }
        var total = 0
        for row in 0 ..< n {
            var rowCount = 0
            for word in 0 ..< used {
                var bits = _words[row * _wordsPerRow + word]
                rowCount &+= bits.nonzeroBitCount
                while bits != 0 {
                    _degrees[_inSlot(word * UInt.bitWidth + bits.trailingZeroBitCount)] &+= 1
                    bits &= bits &- 1
                }
            }
            _degrees[Self._outSlot(row)] = rowCount
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
        // The cells before, to find the removed edges' values (the copy is made only with maps).
        let before = _edgeMaps.isEmpty ? nil : _words
        for row in 0 ..< _vertexCount {
            for word in 0 ..< used {
                let index = row * _wordsPerRow + word
                _words[index] = combine(_words[index], other._words[row * other._wordsPerRow + word])
            }
        }
        _clearPadding()
        _recountDegrees()
        if let before { _resetEdgeMaps(removedSince: before) }
        _advanceGeneration()
    }

    /// Sets every edge map's value back to the default at each edge leaving `vertex`, before its
    /// row is cleared.
    @usableFromInline
    internal mutating func _resetEdgeMaps(ofRow vertex: Int) {
        for word in 0 ..< Self._wordsNeeded(forColumns: _vertexCount) {
            _resetEdgeMaps(row: vertex, word: word, cleared: _words[vertex &* _wordsPerRow &+ word])
        }
    }

    /// Sets every edge map's value back to the default at each edge entering `vertex`, before its
    /// column is cleared.
    @usableFromInline
    internal mutating func _resetEdgeMaps(ofColumn vertex: Int) {
        for row in 0 ..< _vertexCount where _bit(row, vertex) {
            _edgeMaps.reset(at: Self._edgeMapOffset(row, vertex))
        }
    }

    /// Sets every edge map's value back to the default at each cell set in `before` (the words at
    /// the same stride) and clear now.
    @usableFromInline
    internal mutating func _resetEdgeMaps(removedSince before: ContiguousArray<UInt>) {
        let used = Self._wordsNeeded(forColumns: _vertexCount)
        for row in 0 ..< _vertexCount {
            for word in 0 ..< used {
                let index = row &* _wordsPerRow &+ word
                _resetEdgeMaps(row: row, word: word, cleared: before[index] & ~_words[index])
            }
        }
    }

    /// Sets every edge map's value back to the default at the cells of `row` whose bits are set in
    /// `cleared`, word `word` of the row: edges just removed. Keeps every non-edge cell at the
    /// default, so an insertion writes nothing to the maps.
    @usableFromInline
    internal mutating func _resetEdgeMaps(row: Int, word: Int, cleared: UInt) {
        var bits = cleared
        while bits != 0 {
            _edgeMaps.reset(at: Self._edgeMapOffset(row, word &* UInt.bitWidth &+ bits.trailingZeroBitCount))
            bits &= bits &- 1
        }
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
    /// - Precondition: Both are in `0..<vertexCount`.
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
        return _degree(at: Self._outSlot(vertex))
    }

    /// The number of edges entering `vertex`. O(1).
    ///
    /// - Precondition: `vertex` is in `0..<vertexCount`.
    @inlinable
    public func inDegree(of vertex: Int) -> Int {
        _checkVertex(vertex)
        return _degree(at: _inSlot(vertex))
    }

    /// `outDegree(of:) + inDegree(of:)`. A self-loop counts twice: once leaving and once entering.
    ///
    /// - Precondition: `vertex` is in `0..<vertexCount`.
    @inlinable
    public func degree(of vertex: Int) -> Int {
        _checkVertex(vertex)
        return _degree(at: Self._outSlot(vertex)) + _degree(at: _inSlot(vertex))
    }
}

// MARK: - Mutation

extension AdjacencyMatrix {
    /// Writes the cell, its degrees and the edge count, advances the generation unless
    /// `advancing` is false (the caller then advances it once for many cells), and on a removal
    /// sets the edge maps' value back to the default.
    ///
    /// - Returns: Whether the cell changed.
    /// - Precondition: Both are in `0..<vertexCount`.
    @inlinable
    @discardableResult
    internal mutating func _setCell(_ source: Int, _ target: Int, to value: Bool, advancing: Bool = true) -> Bool {
        let index = _wordIndex(source, target)
        let mask = Self._mask(target)
        // Read before writing, so a write that changes nothing never copies shared storage.
        guard (_words[index] & mask != 0) != value else { return false }
        if value { _words[index] |= mask } else { _words[index] &= ~mask }
        // A degree is at most n, and the edge count at most n², which the bits already take
        // memory for: none can overflow.
        let change = value ? 1 : -1
        // The edge count through the subscript, which makes the buffer unique in a way the
        // optimizer hoists out of a caller's loop (`withUnsafeMutableBufferPointer` is not
        // hoisted); then the degrees and the stamp through that buffer's address, unchecked.
        _degrees[0] &+= change
        let degrees = _degrees._baseAddressIfContiguous.unsafelyUnwrapped
        degrees[Self._outSlot(source)] &+= change
        degrees[_inSlot(target)] &+= change
        if advancing { Self._advanceGeneration(in: degrees) }
        if !value, !_edgeMaps.isEmpty { _edgeMaps.reset(at: Self._edgeMapOffset(source, target)) }
        return true
    }

    /// Inserts `edge`, if it is not already an edge.
    ///
    /// - Precondition: Both endpoints are in `0..<vertexCount`. The matrix never grows to fit an
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

    /// Inserts `edge`, if it is not already an edge, only when both endpoints are in
    /// `0..<vertexCount`, and otherwise throws and changes nothing. O(1).
    ///
    /// Use it when the vertices may come from another graph. `insert(edge:)` traps on an
    /// out-of-range endpoint, because the matrix never grows to fit an edge.
    ///
    /// - Throws: `VertexNotFound` when either endpoint is not in `0..<vertexCount`.
    @inlinable
    @discardableResult
    public mutating func insert(checked edge: DirectedEdge<Int>) throws(VertexNotFound) -> (inserted: Bool, memberAfterInsert: DirectedEdge<Int>) {
        guard contains(edge.source), contains(edge.target) else { throw VertexNotFound() }
        return insert(edge: edge)
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
            _setCell(source, target, to: true, advancing: false)
            inserted += 1
        }
        if inserted > 0 { _advanceGeneration() }
        return inserted
    }

    /// Removes every edge leaving `vertex`: clears its row.
    ///
    /// - Returns: The number of edges removed.
    @inlinable
    @discardableResult
    public mutating func removeEdges(from vertex: Int) -> Int {
        _checkVertex(vertex)
        let removed = _degree(at: Self._outSlot(vertex))
        guard removed > 0 else { return 0 }
        if !_edgeMaps.isEmpty { _resetEdgeMaps(ofRow: vertex) }
        let start = vertex * _wordsPerRow
        for word in 0 ..< Self._wordsNeeded(forColumns: _vertexCount) {
            var bits = _words[start + word]
            while bits != 0 {
                _degrees[_inSlot(word * UInt.bitWidth + bits.trailingZeroBitCount)] -= 1
                bits &= bits &- 1
            }
            _words[start + word] = 0
        }
        _degrees[Self._outSlot(vertex)] = 0
        _edgeCount -= removed
        _advanceGeneration()
        return removed
    }

    /// Removes every edge entering `vertex`: clears its column.
    ///
    /// - Returns: The number of edges removed.
    @inlinable
    @discardableResult
    public mutating func removeEdges(to vertex: Int) -> Int {
        _checkVertex(vertex)
        let removed = _degree(at: _inSlot(vertex))
        guard removed > 0 else { return 0 }
        if !_edgeMaps.isEmpty { _resetEdgeMaps(ofColumn: vertex) }
        let mask = Self._mask(vertex)
        let wordInRow = vertex / UInt.bitWidth
        for row in 0 ..< _vertexCount {
            let index = row * _wordsPerRow + wordInRow
            if _words[index] & mask != 0 {
                _words[index] &= ~mask
                _degrees[Self._outSlot(row)] -= 1
            }
        }
        _degrees[_inSlot(vertex)] = 0
        _edgeCount -= removed
        _advanceGeneration()
        return removed
    }

    /// Removes every edge leaving or entering `vertex`, keeping the vertex.
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
    /// - Complexity: Amortized O(n / 64), plus O(n) for each attached edge map, which gains the
    ///   2n + 1 cells of the new row and column. Rows are appended; the rows are moved only when
    ///   the number of columns outgrows the words per row, which then doubles.
    @inlinable
    @discardableResult
    public mutating func appendVertex() -> Int {
        let vertex = _vertexCount
        Self._checkStorage(for: vertex + 1)
        if vertex + 1 > _wordsPerRow * UInt.bitWidth {
            _restride(wordsPerRow: Swift.max(1, _wordsPerRow * 2))
        }
        // The new column is already zero, as every bit past the last column is.
        _words.append(contentsOf: repeatElement(0, count: _wordsPerRow))
        _vertexCount += 1
        // The new cells are the Szudzik offsets vertex² ..< (vertex + 1)²: 2·vertex + 1 defaults.
        if !_vertexMaps.isEmpty { _vertexMaps.appendDefaults(count: 1) }
        if !_edgeMaps.isEmpty { _edgeMaps.appendDefaults(count: 2 &* vertex &+ 1) }
        _advanceGeneration()
        return vertex
    }

    /// Removes every edge, keeping every vertex. Every attached edge map stays attached, with
    /// every cell at its default.
    ///
    /// - Parameter keepingCapacity: When false, any spare row capacity is released.
    @inlinable
    public mutating func removeAllEdges(keepingCapacity: Bool = false) {
        let n = _vertexCount
        let hadEdges = _edgeCount > 0
        if keepingCapacity {
            guard hadEdges else { return }
            for index in _words.indices { _words[index] = 0 }
            for slot in Self._headerCount ..< _degrees.count { _degrees[slot] = 0 }
            _edgeCount = 0
        } else {
            // Fresh zeroed storage: never copies shared words just to overwrite them. The stamp
            // moves to the new buffer, whose address does not match it: a new lineage.
            _wordsPerRow = Self._wordsNeeded(forColumns: n)
            _words = ContiguousArray(repeating: 0, count: n * _wordsPerRow)
            _degrees = Self._degreeStorage(wordsPerRow: _wordsPerRow, stamp: _degrees)
        }
        if hadEdges, !_edgeMaps.isEmpty {
            _edgeMaps.removeAll(keepingCapacity: keepingCapacity)
            _edgeMaps.appendDefaults(count: n &* n)
        }
        _advanceGeneration()
    }

    /// Removes every vertex and edge. Every attached map stays attached, empty.
    @inlinable
    public mutating func removeAll(keepingCapacity: Bool = false) {
        if keepingCapacity {
            _words.removeAll(keepingCapacity: true)
            for slot in Self._headerCount ..< _degrees.count { _degrees[slot] = 0 }
            _edgeCount = 0
        } else {
            _wordsPerRow = 0
            _words = []
            _degrees = Self._degreeStorage(wordsPerRow: 0, stamp: _degrees)
        }
        _vertexCount = 0
        if !_vertexMaps.isEmpty { _vertexMaps.removeAll(keepingCapacity: keepingCapacity) }
        if !_edgeMaps.isEmpty { _edgeMaps.removeAll(keepingCapacity: keepingCapacity) }
        _advanceGeneration()
    }

    /// Reserves storage for at least `vertexCount` vertices, and room for their values in every
    /// attached map.
    @inlinable
    public mutating func reserveCapacity(vertexCount: Int) {
        Self._checkStorage(for: vertexCount)
        let wordsPerRow = Self._wordsNeeded(forColumns: vertexCount)
        if wordsPerRow > _wordsPerRow {
            _restride(wordsPerRow: wordsPerRow)
        }
        _words.reserveCapacity(vertexCount * _wordsPerRow)
        // The degrees already have a slot per column the rows have room for.
        _degreeStorageMayHaveMoved()
        if !_vertexMaps.isEmpty { _vertexMaps.reserveCapacity(vertexCount) }
        if !_edgeMaps.isEmpty { _edgeMaps.reserveCapacity(vertexCount &* vertexCount) }
    }
}

// MARK: - Whole-matrix operations

extension AdjacencyMatrix {
    /// Inserts every edge of `other`.
    ///
    /// - Precondition: Both have the same vertex count.
    @inlinable
    public mutating func formUnion(_ other: AdjacencyMatrix) {
        _combine(with: other) { $0 | $1 }
    }

    /// The edges in either matrix. The result carries this matrix's attached maps.
    @inlinable
    public func union(_ other: AdjacencyMatrix) -> AdjacencyMatrix {
        var result = self
        result.formUnion(other)
        return result
    }

    /// Keeps only the edges also in `other`.
    ///
    /// - Precondition: Both have the same vertex count.
    @inlinable
    public mutating func formIntersection(_ other: AdjacencyMatrix) {
        _combine(with: other) { $0 & $1 }
    }

    /// The edges in both matrices. The result carries this matrix's attached maps, with the
    /// removed edges' values gone.
    @inlinable
    public func intersection(_ other: AdjacencyMatrix) -> AdjacencyMatrix {
        var result = self
        result.formIntersection(other)
        return result
    }

    /// Removes every edge that is in `other`.
    ///
    /// - Precondition: Both have the same vertex count.
    @inlinable
    public mutating func subtract(_ other: AdjacencyMatrix) {
        _combine(with: other) { $0 & ~$1 }
    }

    /// The edges in this matrix but not in `other`. The result carries this matrix's attached
    /// maps, with the removed edges' values gone.
    @inlinable
    public func subtracting(_ other: AdjacencyMatrix) -> AdjacencyMatrix {
        var result = self
        result.subtract(other)
        return result
    }

    /// Keeps the edges in exactly one of the two matrices.
    ///
    /// - Precondition: Both have the same vertex count.
    @inlinable
    public mutating func formSymmetricDifference(_ other: AdjacencyMatrix) {
        _combine(with: other) { $0 ^ $1 }
    }

    /// The edges in exactly one of the two matrices. The result carries this matrix's attached
    /// maps, with the removed edges' values gone.
    @inlinable
    public func symmetricDifference(_ other: AdjacencyMatrix) -> AdjacencyMatrix {
        var result = self
        result.formSymmetricDifference(other)
        return result
    }

    /// The complement graph, with an edge exactly where this matrix has none. The result carries
    /// none of this matrix's attached maps.
    ///
    /// - Parameter includingSelfLoops: Whether the diagonal is complemented too. By default it is
    ///   not, and the result has no self-loops.
    @inlinable
    public func complement(includingSelfLoops: Bool = false) -> AdjacencyMatrix {
        var result = self
        result._vertexMaps = _AttachedMaps()
        result._edgeMaps = _AttachedMaps()
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
        // A new graph, with no generation, like one just built.
        result._degrees[1] = 0
        result._degrees[2] = 0
        result._degrees[3] = 0
        return result
    }

    /// The matrix with every edge reversed, so cell (i, j) of the result is cell (j, i) of this one.
    /// The result carries none of this matrix's attached maps.
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
        for vertex in 0 ..< _vertexCount {
            result._degrees[Self._outSlot(vertex)] = _degree(at: _inSlot(vertex))
            result._degrees[result._inSlot(vertex)] = _degree(at: Self._outSlot(vertex))
        }
        result._edgeCount = _edgeCount
        return result
    }
}

extension AdjacencyMatrix: ExpressibleByArrayLiteral {
    /// A matrix from rows of 0s and 1s: row `i`, column `j` is 1 when there is an edge from `i`
    /// to `j`.
    ///
    /// - Precondition: The rows form a square, and every entry is 0 or 1.
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

    /// Every edge, in row-major order, as a value that later changes to the matrix do not affect.
    /// Holding one while mutating the matrix makes the mutation copy the matrix.
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

    /// The largest vertex count decoded by default, 16,384 vertices or 32 MiB of cells. A tiny
    /// payload can name an enormous vertex count, so decoding refuses anything larger unless the
    /// decoder's `userInfo[maximumDecodedVertexCountKey]` allows it.
    public static let defaultMaximumDecodedVertexCount = 16_384

    /// Encodes `{"vertexCount": n, "edges": [source₀, target₀, source₁, target₁, …]}`, with the
    /// edges in row-major order, so equal matrices encode identically.
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

extension AdjacencyMatrix: CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable {
    /// The vertices and the edges, at most 16 of each, as in `[0, 1, 2]; [0→1, 1→2]`. Every
    /// representation uses this form, and equal matrices print alike.
    public var description: String {
        GraphDescription.graph(vertices: vertices, vertexCount: _vertexCount, edges: edges, edgeCount: _edgeCount)
    }

    /// The type, the counts, and at most 16 edges.
    public var debugDescription: String {
        "AdjacencyMatrix(vertexCount: \(_vertexCount), edgeCount: \(_edgeCount), edges: "
            + GraphDescription.list(edges, count: _edgeCount) { GraphDescription.edge($0) }
            + ")"
    }

    /// The whole matrix as rows of 0s and 1s, column 0 leftmost, one row per line, no trailing
    /// newline. It has n² characters, so it is meant for small matrices.
    public var rowsDescription: String {
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

    /// Shows `vertexCount` and `edges` as children, so a debugger can browse them.
    public var customMirror: Mirror {
        Mirror(self, children: ["vertexCount": _vertexCount, "edges": Array(edges)], displayStyle: .struct)
    }
}

// MARK: - DirectedGraph

extension AdjacencyMatrix: BidirectionalDirectedGraph {
    /// The positions (cells) in `edges` of the edges leaving `vertex`, ascending by target.
    ///
    /// - Precondition: `vertex` is in `0..<vertexCount`.
    @inlinable
    public func outEdges(of vertex: Int) -> LazyMapSequence<BitSet, Edges.Index> {
        successors(of: vertex).lazy.map { Edges.Index(source: vertex, target: $0) }
    }

    /// The positions (cells) in `edges` of the edges entering `vertex`, ascending by source.
    ///
    /// - Precondition: `vertex` is in `0..<vertexCount`.
    @inlinable
    public func inEdges(of vertex: Int) -> LazyMapSequence<BitSet, Edges.Index> {
        predecessors(of: vertex).lazy.map { Edges.Index(source: $0, target: vertex) }
    }

    /// The source of the edge in a cell: its row. O(1).
    ///
    /// - Precondition: The cell holds an edge, as for `edges[position]`.
    @inlinable
    public func source(ofEdgeAt position: Edges.Index) -> Int {
        _checkEdge(at: position)
        return position.source
    }

    /// The target of the edge in a cell: its column. O(1).
    ///
    /// - Precondition: The cell holds an edge, as for `edges[position]`.
    @inlinable
    public func target(ofEdgeAt position: Edges.Index) -> Int {
        _checkEdge(at: position)
        return position.target
    }

    @inlinable
    @inline(__always)
    internal func _checkEdge(at position: Edges.Index) {
        precondition(
            contains(edge: DirectedEdge(from: position.source, to: position.target)),
            "Invalid index: no edge at \(position.source), \(position.target)"
        )
    }

    /// The vertices are their own indices.
    @inlinable
    public var vertexIndexBound: Int? { _vertexCount }

    /// `vertex` itself.
    ///
    /// - Precondition: `vertex` is in `0..<vertexCount`.
    @inlinable
    public func vertexIndex(of vertex: Int) -> Int {
        _checkVertex(vertex)
        return vertex
    }

    /// `index` itself.
    ///
    /// - Precondition: `index` is in `0..<vertexCount`.
    @inlinable
    public func vertex(atIndex index: Int) -> Int {
        _checkVertex(index)
        return index
    }

    /// The successors themselves, since vertices are their own indices.
    @inlinable
    public func successorIndices(ofIndex index: Int) -> BitSet { successors(of: index) }

    /// The predecessors themselves, since vertices are their own indices.
    @inlinable
    public func predecessorIndices(ofIndex index: Int) -> BitSet { predecessors(of: index) }

    /// `outDegree(of: index)`: vertices are their own indices. O(1).
    @inlinable
    public func outDegree(ofIndex index: Int) -> Int { outDegree(of: index) }

    /// `inDegree(of: index)`: vertices are their own indices. O(1).
    @inlinable
    public func inDegree(ofIndex index: Int) -> Int { inDegree(of: index) }

    /// `source(ofEdgeAt:)`: vertices are their own indices. O(1).
    @inlinable
    public func sourceIndex(ofEdgeAt position: Edges.Index) -> Int { source(ofEdgeAt: position) }

    /// `target(ofEdgeAt:)`: vertices are their own indices. O(1).
    @inlinable
    public func targetIndex(ofEdgeAt position: Edges.Index) -> Int { target(ofEdgeAt: position) }
}

// MARK: - checked: lookups

// These throw `VertexNotFound` for a vertex outside `0..<vertexCount` and `EdgeNotFound` for a cell
// that holds no edge. Each checks the range once and then calls its trapping spelling.

extension AdjacencyMatrix {
    /// `successors(of: vertex)`, throwing instead of trapping when `vertex` is not in
    /// `0..<vertexCount`. O(n / 64).
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not in `0..<vertexCount`.
    @inlinable
    public func successors(checked vertex: Int) throws(VertexNotFound) -> BitSet {
        guard contains(vertex) else { throw VertexNotFound() }
        return successors(of: vertex)
    }

    /// `predecessors(of: vertex)`, throwing instead of trapping when `vertex` is not in
    /// `0..<vertexCount`. O(n).
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not in `0..<vertexCount`.
    @inlinable
    public func predecessors(checked vertex: Int) throws(VertexNotFound) -> BitSet {
        guard contains(vertex) else { throw VertexNotFound() }
        return predecessors(of: vertex)
    }

    /// `outEdges(of: vertex)`, throwing instead of trapping when `vertex` is not in
    /// `0..<vertexCount`. O(n / 64) to make.
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not in `0..<vertexCount`.
    @inlinable
    public func outEdges(checked vertex: Int) throws(VertexNotFound) -> LazyMapSequence<BitSet, Edges.Index> {
        guard contains(vertex) else { throw VertexNotFound() }
        return outEdges(of: vertex)
    }

    /// `inEdges(of: vertex)`, throwing instead of trapping when `vertex` is not in
    /// `0..<vertexCount`. O(n) to make.
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not in `0..<vertexCount`.
    @inlinable
    public func inEdges(checked vertex: Int) throws(VertexNotFound) -> LazyMapSequence<BitSet, Edges.Index> {
        guard contains(vertex) else { throw VertexNotFound() }
        return inEdges(of: vertex)
    }

    /// `outDegree(of: vertex)`, throwing instead of trapping when `vertex` is not in
    /// `0..<vertexCount`. O(1).
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not in `0..<vertexCount`.
    @inlinable
    public func outDegree(checked vertex: Int) throws(VertexNotFound) -> Int {
        guard contains(vertex) else { throw VertexNotFound() }
        return outDegree(of: vertex)
    }

    /// `inDegree(of: vertex)`, throwing instead of trapping when `vertex` is not in
    /// `0..<vertexCount`. O(1).
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not in `0..<vertexCount`.
    @inlinable
    public func inDegree(checked vertex: Int) throws(VertexNotFound) -> Int {
        guard contains(vertex) else { throw VertexNotFound() }
        return inDegree(of: vertex)
    }

    /// `degree(of: vertex)`, throwing instead of trapping when `vertex` is not in
    /// `0..<vertexCount`. O(1).
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not in `0..<vertexCount`.
    @inlinable
    public func degree(checked vertex: Int) throws(VertexNotFound) -> Int {
        guard contains(vertex) else { throw VertexNotFound() }
        return degree(of: vertex)
    }

    /// `vertexIndex(of: vertex)`, throwing instead of trapping when `vertex` is not in
    /// `0..<vertexCount`. O(1).
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not in `0..<vertexCount`.
    @inlinable
    public func vertexIndex(checked vertex: Int) throws(VertexNotFound) -> Int {
        guard contains(vertex) else { throw VertexNotFound() }
        return vertexIndex(of: vertex)
    }

    /// `source(ofEdgeAt: position)`, throwing instead of trapping when the cell holds no edge.
    /// O(1).
    ///
    /// - Throws: `EdgeNotFound` when the cell is out of range or holds no edge.
    @inlinable
    public func source(checkedEdgeAt position: Edges.Index) throws(EdgeNotFound) -> Int {
        guard contains(edge: DirectedEdge(from: position.source, to: position.target)) else { throw EdgeNotFound() }
        return source(ofEdgeAt: position)
    }

    /// `target(ofEdgeAt: position)`, throwing instead of trapping when the cell holds no edge.
    /// O(1).
    ///
    /// - Throws: `EdgeNotFound` when the cell is out of range or holds no edge.
    @inlinable
    public func target(checkedEdgeAt position: Edges.Index) throws(EdgeNotFound) -> Int {
        guard contains(edge: DirectedEdge(from: position.source, to: position.target)) else { throw EdgeNotFound() }
        return target(ofEdgeAt: position)
    }
}

extension AdjacencyMatrix {
    /// The matrix of any directed graph on the vertices `0..<graph.vertexCount`, with parallel
    /// edges collapsed.
    ///
    /// - Precondition: The vertices are exactly `0..<graph.vertexCount`. Other numberings are not
    ///   renumbered; use `init(vertexCount:edges:)` for them.
    @inlinable
    public init(_ graph: some DirectedGraph<Int>) {
        if let same = graph as? AdjacencyMatrix {
            self = same
            return
        }
        let n = graph.vertexCount
        for v in graph.vertices {
            precondition(v >= 0 && v < n, "Vertex \(v) is not in 0..<\(n); the vertices must be exactly 0..<vertexCount")
        }
        self.init(vertexCount: n, edges: graph.edges)
    }
}
