import BitCollections
import GraphProtocols

/// The unoriented incidence matrix of a hypergraph: an n × m matrix of bits with cell (v, p) set
/// when vertex `v` is a member of column `p`. The vertices are `0..<vertexCount` and the columns,
/// the hyperedges, are at positions `0..<hyperedgeCount`. It conforms to `Hypergraph`, so the
/// `Hypergraphs` algorithms run on it unchanged; it is not a `Graph` even when built from one,
/// because a cell edit can give a column any number of bits.
///
/// A column is any set of vertices: empty columns and repeated columns are kept, and a graph's
/// self-loop is the one bit at its vertex, the hyperedge {v}. (NetworkX's `incidence_matrix` gives a
/// loop a zero column; Godsil–Royle's entry 2 is not a bit. A zero column would forget the loop.)
/// `OrientedIncidenceMatrix` is the directed form; `UndirectedIncidenceList` is the sparse
/// representation of the same hypergraphs.
///
/// **Storage.** Both orientations are stored, as `AdjacencyMatrix` stores its rows: n rows of
/// ⌈m/64⌉ words and m columns of ⌈n/64⌉ words, with the row and column popcounts cached. So
/// `members(ofHyperedgeAt:)` and `incidentHyperedges(of:)` are each one `BitSet` copy of
/// ⌈n/64⌉ or ⌈m/64⌉ words, a cell edit writes two bits in O(1), and `transposed()`, the dual,
/// swaps the two in O(1). The cost is 2·n·m/8 bytes: **the matrix is for dense or small
/// incidence** (spectral work at n·m up to about 10⁹, hypergraphs with large hyperedges). Sparse
/// incidence belongs in `UndirectedIncidenceList`.
///
/// Equality compares cell for cell, with equal shape: column order is observable, because a
/// column's position is what a spectral caller indexes by. (`UndirectedIncidenceList`'s equality
/// ignores positions; convert to compare that way.)
@frozen
public struct IncidenceMatrix {
    /// n rows over the m columns: row `v` is `incidentHyperedges(of: v)`.
    @usableFromInline internal var _rows: _BitRows
    /// m rows over the n vertices: row `p` is `members(ofHyperedgeAt: p)`.
    @usableFromInline internal var _columns: _BitRows
    /// The popcount of each row.
    @usableFromInline internal var _degrees: ContiguousArray<Int>
    /// The popcount of each column.
    @usableFromInline internal var _sizes: ContiguousArray<Int>
    /// The number of set cells.
    @usableFromInline internal var _cellCount: Int

    /// The matrix with no vertices and no columns.
    @inlinable
    public init() {
        self.init(_vertexCount: 0, hyperedgeCount: 0)
    }

    /// A zero matrix of the given shape.
    @inlinable
    internal init(_vertexCount n: Int, hyperedgeCount m: Int) {
        precondition(n >= 0, "Negative vertex count")
        _rows = _BitRows(rowCount: n, columnCount: m)
        _columns = _BitRows(rowCount: m, columnCount: n)
        _degrees = ContiguousArray(repeating: 0, count: n)
        _sizes = ContiguousArray(repeating: 0, count: m)
        _cellCount = 0
    }

    @inlinable
    internal init(_rows: _BitRows, _columns: _BitRows, _degrees: ContiguousArray<Int>, _sizes: ContiguousArray<Int>, _cellCount: Int) {
        self._rows = _rows
        self._columns = _columns
        self._degrees = _degrees
        self._sizes = _sizes
        self._cellCount = _cellCount
    }
}

// MARK: - Construction

extension IncidenceMatrix {
    /// A matrix of `vertexCount` vertices and no columns.
    ///
    /// - Precondition: `vertexCount >= 0`.
    /// - Complexity: O(n).
    @inlinable
    public init(vertexCount: Int) {
        self.init(_vertexCount: vertexCount, hyperedgeCount: 0)
    }

    /// A matrix of `vertexCount` vertices with one column per hyperedge, in order. A member listed
    /// twice is one bit; empty and repeated columns are kept.
    ///
    /// - Precondition: `vertexCount >= 0`, and every member is in `0..<vertexCount`.
    /// - Complexity: O(n·⌈m/64⌉ + m·⌈n/64⌉ + p): the zeroed storage, then a bit per member.
    @inlinable
    public init(vertexCount: Int, hyperedges: some Sequence<some Sequence<Int>>) {
        precondition(vertexCount >= 0, "Negative vertex count")
        var offsets = [0]
        var flat: [Int] = []
        for hyperedge in hyperedges {
            for v in hyperedge {
                precondition(v >= 0 && v < vertexCount, "Member \(v) is out of range 0..<\(vertexCount)")
                flat.append(v)
            }
            offsets.append(flat.count)
        }
        self.init(_vertexCount: vertexCount, hyperedgeCount: offsets.count - 1)
        for p in 0 ..< offsets.count - 1 {
            for k in offsets[p] ..< offsets[p + 1] { _setCell(flat[k], p, to: true) }
        }
    }

    /// The incidence matrix of an undirected graph: a row per vertex, by `vertexIndex(of:)`, and a
    /// column per edge, in `edges` order (NetworkX's `nodelist` and `edgelist` defaults). Parallel
    /// edges keep a column each; a self-loop's column is the one bit at its vertex.
    ///
    /// - Precondition: `graph.vertexIndexBound` is not `nil`.
    /// - Complexity: O(n·⌈m/64⌉ + m·⌈n/64⌉): the zeroed storage, then two bits per edge.
    @inlinable
    public init(_ graph: some Graph) {
        guard let n = graph.vertexIndexBound else {
            preconditionFailure("IncidenceMatrix(_:) needs a graph with vertex indices")
        }
        self.init(_vertexCount: n, hyperedgeCount: graph.edgeCount)
        var p = 0
        for position in graph.edges.indices {
            let (u, v) = graph.endpointIndices(ofEdgeAt: position)
            _setCell(u, p, to: true)
            _setCell(v, p, to: true)
            p += 1
        }
    }

    /// The unoriented incidence matrix of a directed graph: each edge's column has both ends
    /// (NetworkX's `oriented=False`), a self-loop's one bit. Rows by vertex index, columns in
    /// `edges` order.
    ///
    /// - Precondition: `graph.vertexIndexBound` is not `nil`.
    @inlinable
    public init(_ graph: some DirectedGraph) {
        guard let n = graph.vertexIndexBound else {
            preconditionFailure("IncidenceMatrix(_:) needs a graph with vertex indices")
        }
        self.init(_vertexCount: n, hyperedgeCount: graph.edgeCount)
        var p = 0
        for position in graph.edges.indices {
            _setCell(graph.sourceIndex(ofEdgeAt: position), p, to: true)
            _setCell(graph.targetIndex(ofEdgeAt: position), p, to: true)
            p += 1
        }
    }

    /// The incidence matrix of a hypergraph: rows by vertex index, a column per hyperedge in
    /// `hyperedges` order.
    ///
    /// - Precondition: `hypergraph.vertexIndexBound` is not `nil`.
    @inlinable
    public init(_ hypergraph: some Hypergraph) {
        self.init(_copying: hypergraph)
    }

    @inlinable
    internal init(_copying hypergraph: some Hypergraph) {
        if let same = hypergraph as? IncidenceMatrix {
            self = same
            return
        }
        guard let n = hypergraph.vertexIndexBound else {
            preconditionFailure("IncidenceMatrix(_:) needs a hypergraph with vertex indices")
        }
        self.init(_vertexCount: n, hyperedgeCount: hypergraph.hyperedgeCount)
        var p = 0
        for position in hypergraph.hyperedges.indices {
            for v in hypergraph.memberIndices(ofHyperedgeAt: position) { _setCell(v, p, to: true) }
            p += 1
        }
    }

    /// The unoriented matrix of a directed hypergraph: each column the union of its hyperedge's
    /// sources and targets.
    ///
    /// - Precondition: `hypergraph.vertexIndexBound` is not `nil`.
    @inlinable
    public init(_ hypergraph: some DirectedHypergraph) {
        self.init(_copying: hypergraph)
    }

    @inlinable
    internal init(_copying hypergraph: some DirectedHypergraph) {
        guard let n = hypergraph.vertexIndexBound else {
            preconditionFailure("IncidenceMatrix(_:) needs a hypergraph with vertex indices")
        }
        self.init(_vertexCount: n, hyperedgeCount: hypergraph.hyperedgeCount)
        var p = 0
        for position in hypergraph.hyperedges.indices {
            for v in hypergraph.sourceIndices(ofHyperedgeAt: position) { _setCell(v, p, to: true) }
            for v in hypergraph.targetIndices(ofHyperedgeAt: position) { _setCell(v, p, to: true) }
            p += 1
        }
    }

    /// The union of the oriented matrix's planes: each column its sources and targets together.
    ///
    /// - Complexity: O(n·⌈m/64⌉ + P_t).
    @inlinable
    public init(_ oriented: OrientedIncidenceMatrix) {
        self = oriented._sources
        let targets = oriented._targets
        for p in 0 ..< targets.hyperedgeCount {
            for v in targets._columns.row(p) { _setCell(v, p, to: true) }
        }
    }

    /// The one hypergraph conversion for a type that is both a graph and a hypergraph: read as a
    /// hypergraph.
    @inlinable
    public init<H: Graph & Hypergraph>(_ hypergraph: H) {
        self.init(_copying: hypergraph)
    }

    /// The one hypergraph conversion for a type that is both a directed graph and a directed
    /// hypergraph: read as a hypergraph.
    @inlinable
    public init<H: DirectedGraph & DirectedHypergraph>(_ hypergraph: H) {
        self.init(_copying: hypergraph)
    }
}

// MARK: - Storage

extension IncidenceMatrix {
    @inlinable
    @inline(__always)
    internal func _checkVertex(_ vertex: Int) {
        precondition(vertex >= 0 && vertex < _rows.rowCount, "Vertex \(vertex) is out of range 0..<\(_rows.rowCount)")
    }

    @inlinable
    @inline(__always)
    internal func _checkHyperedge(_ position: Int) {
        precondition(position >= 0 && position < _columns.rowCount, "Column \(position) is out of range 0..<\(_columns.rowCount)")
    }

    /// Writes cell (v, p) in both orientations and the counts; returns whether it changed.
    @inlinable
    @discardableResult
    internal mutating func _setCell(_ v: Int, _ p: Int, to value: Bool) -> Bool {
        guard _rows.set(v, p, to: value) else { return false }
        _columns.set(p, v, to: value)
        let delta = value ? 1 : -1
        _degrees[v] &+= delta
        _sizes[p] &+= delta
        _cellCount &+= delta
        return true
    }
}

// MARK: - Reads

extension IncidenceMatrix {
    /// The number of vertices, the rows. O(1).
    @inlinable
    public var vertexCount: Int { _rows.rowCount }

    /// The number of columns, the hyperedges. O(1).
    @inlinable
    public var hyperedgeCount: Int { _columns.rowCount }

    /// The vertices: `0..<vertexCount`.
    @inlinable
    public var vertices: Range<Int> { 0 ..< _rows.rowCount }

    /// Whether `vertex` is a member of the column at `position`. O(1).
    ///
    /// - Precondition: `vertex` is in `0..<vertexCount` and `position` in `0..<hyperedgeCount`.
    @inlinable
    public subscript(vertex vertex: Int, hyperedge position: Int) -> Bool {
        _checkVertex(vertex)
        _checkHyperedge(position)
        return _rows.bit(vertex, position)
    }

    /// The members of the column at `position`, ascending. O(⌈n/64⌉): one `BitSet` copy.
    ///
    /// - Precondition: `position` is in `0..<hyperedgeCount`.
    @inlinable
    public func members(ofHyperedgeAt position: Int) -> BitSet {
        _checkHyperedge(position)
        return _columns.row(position)
    }

    /// The members of the column at `position`, ascending, read from the stored words without a
    /// copy: what the `Hypergraphs` algorithms iterate. O(1) to make, O(⌈n/64⌉ + k) to iterate.
    ///
    /// - Precondition: `position` is in `0..<hyperedgeCount`.
    @inlinable
    public func memberIndices(ofHyperedgeAt position: Int) -> SetBits {
        _checkHyperedge(position)
        return SetBits(_words: _columns.words(ofRow: position))
    }

    /// The columns `vertex` is a member of, ascending. O(⌈m/64⌉): one `BitSet` copy.
    ///
    /// - Precondition: `vertex` is in `0..<vertexCount`.
    @inlinable
    public func incidentHyperedges(of vertex: Int) -> BitSet {
        _checkVertex(vertex)
        return _rows.row(vertex)
    }

    @inlinable
    public func incidentHyperedges(ofIndex index: Int) -> BitSet { incidentHyperedges(of: index) }

    /// The number of members of the column at `position`. O(1), cached.
    ///
    /// - Precondition: `position` is in `0..<hyperedgeCount`.
    @inlinable
    public func size(ofHyperedgeAt position: Int) -> Int {
        _checkHyperedge(position)
        return _sizes[position]
    }

    /// The number of columns `vertex` is a member of. O(1), cached.
    ///
    /// - Precondition: `vertex` is in `0..<vertexCount`.
    @inlinable
    public func degree(of vertex: Int) -> Int {
        _checkVertex(vertex)
        return _degrees[vertex]
    }

    @inlinable
    public func degree(ofIndex index: Int) -> Int { degree(of: index) }

    /// Whether `vertex` is in `0..<vertexCount`. Never traps.
    @inlinable
    public func contains(_ vertex: Int) -> Bool { vertex >= 0 && vertex < _rows.rowCount }

    /// Whether some column has exactly the members of `members`, ignoring order and repeats.
    /// False, without trapping, when a member is out of range.
    ///
    /// - Complexity: O(k + d·⌈n/64⌉): the columns at the first member are compared word by word;
    ///   the empty set scans the m cached sizes.
    @inlinable
    public func contains(hyperedge members: some Sequence<Int>) -> Bool {
        var wanted = BitSet()
        for v in members {
            guard contains(v) else { return false }
            wanted.insert(v)
        }
        guard let first = wanted.first else { return _sizes.contains(0) }
        let count = wanted.count
        for p in _rows.row(first) where _sizes[p] == count && _columns.row(p) == wanted { return true }
        return false
    }

    /// `vertexCount`.
    @inlinable
    public var vertexIndexBound: Int? { _rows.rowCount }

    @inlinable
    public func vertexIndex(of vertex: Int) -> Int {
        _checkVertex(vertex)
        return vertex
    }

    @inlinable
    public func vertex(atIndex index: Int) -> Int {
        _checkVertex(index)
        return index
    }

    /// `hyperedgeCount`.
    @inlinable
    public var hyperedgeIndexBound: Int? { _columns.rowCount }

    @inlinable
    public func hyperedgeIndex(of position: Int) -> Int {
        _checkHyperedge(position)
        return position
    }

    /// The number of set cells, cached. O(1).
    @inlinable
    public var _incidenceCount: Int { _cellCount }

    /// Every column, at its position.
    @frozen
    public struct Hyperedges: RandomAccessCollection, Sendable {
        @usableFromInline internal let _columns: _BitRows

        @inlinable
        internal init(_columns: _BitRows) { self._columns = _columns }

        @inlinable public var startIndex: Int { 0 }
        @inlinable public var endIndex: Int { _columns.rowCount }
        @inlinable public func index(after i: Int) -> Int { i &+ 1 }
        @inlinable public func index(before i: Int) -> Int { i &- 1 }

        @inlinable
        public subscript(position: Int) -> BitSet {
            precondition(position >= 0 && position < _columns.rowCount, "Column \(position) is out of range 0..<\(_columns.rowCount)")
            return _columns.row(position)
        }
    }

    /// Every column, at its position. O(1).
    @inlinable
    public var hyperedges: Hyperedges { Hyperedges(_columns: _columns) }
}

/// The indices of the set bits of one stored row of a matrix, ascending, read in place: no copy
/// and no allocation, unlike a `BitSet`.
@frozen
public struct SetBits: Sequence, Sendable {
    @usableFromInline internal let _words: ArraySlice<UInt>

    @inlinable
    internal init(_words: ArraySlice<UInt>) { self._words = _words }

    @frozen
    public struct Iterator: IteratorProtocol, Sendable {
        @usableFromInline internal let _words: ArraySlice<UInt>
        @usableFromInline internal var _wordIndex: Int
        @usableFromInline internal var _current: UInt

        @inlinable
        internal init(_words: ArraySlice<UInt>) {
            self._words = _words
            _wordIndex = _words.startIndex
            _current = _words.isEmpty ? 0 : _words[_words.startIndex]
        }

        @inlinable
        public mutating func next() -> Int? {
            while _current == 0 {
                _wordIndex &+= 1
                guard _wordIndex < _words.endIndex else { return nil }
                _current = _words[_wordIndex]
            }
            let bit = _current.trailingZeroBitCount
            _current &= _current &- 1
            return (_wordIndex &- _words.startIndex) &* UInt.bitWidth &+ bit
        }
    }

    @inlinable
    public func makeIterator() -> Iterator { Iterator(_words: _words) }
}

extension IncidenceMatrix: Hypergraph {}

// MARK: - Mutation

extension IncidenceMatrix {
    /// Appends a vertex with no memberships, a zero row.
    ///
    /// - Returns: The new vertex, the old `vertexCount`.
    /// - Complexity: Amortized O(⌈m/64⌉): a row is appended, and the columns move only when the
    ///   vertex count outgrows their words, which then double.
    @inlinable
    @discardableResult
    public mutating func appendVertex() -> Int {
        let vertex = _rows.rowCount
        _rows.appendRow()
        _columns.appendColumn()
        _degrees.append(0)
        return vertex
    }

    /// Appends a column with `members`. A member listed twice is one bit; an empty sequence
    /// appends an empty column.
    ///
    /// - Returns: The new column's position, the old `hyperedgeCount`.
    /// - Precondition: every member is in `0..<vertexCount`.
    /// - Complexity: Amortized O(n·⌈m/64⌉/m + ⌈n/64⌉ + k).
    @inlinable
    @discardableResult
    public mutating func insert(hyperedge members: some Sequence<Int>) -> Int {
        let list = Array(members)
        for v in list { _checkVertex(v) }
        let position = _columns.rowCount
        _rows.appendColumn()
        _columns.appendRow()
        _sizes.append(0)
        for v in list { _setCell(v, position, to: true) }
        return position
    }

    /// Sets cell (`vertex`, `position`). O(1).
    ///
    /// - Returns: Whether it changed: false when it was already set.
    /// - Precondition: `vertex` is in `0..<vertexCount` and `position` in `0..<hyperedgeCount`.
    @inlinable
    @discardableResult
    public mutating func insert(_ vertex: Int, intoHyperedgeAt position: Int) -> Bool {
        _checkVertex(vertex)
        _checkHyperedge(position)
        return _setCell(vertex, position, to: true)
    }

    /// Clears cell (`vertex`, `position`). O(1).
    ///
    /// - Returns: Whether it changed: false when it was already clear.
    /// - Precondition: `vertex` is in `0..<vertexCount` and `position` in `0..<hyperedgeCount`.
    @inlinable
    @discardableResult
    public mutating func remove(_ vertex: Int, fromHyperedgeAt position: Int) -> Bool {
        _checkVertex(vertex)
        _checkHyperedge(position)
        return _setCell(vertex, position, to: false)
    }

    /// Removes every vertex and column.
    @inlinable
    public mutating func removeAll(keepingCapacity: Bool = false) {
        _rows.removeAll(keepingCapacity: keepingCapacity)
        _columns.removeAll(keepingCapacity: keepingCapacity)
        _degrees.removeAll(keepingCapacity: keepingCapacity)
        _sizes.removeAll(keepingCapacity: keepingCapacity)
        _cellCount = 0
    }

    /// Reserves storage for `vertexCount` vertices and `hyperedgeCount` columns.
    @inlinable
    public mutating func reserveCapacity(vertexCount: Int, hyperedgeCount: Int) {
        _rows.reserveCapacity(rows: vertexCount, columns: hyperedgeCount)
        _columns.reserveCapacity(rows: hyperedgeCount, columns: vertexCount)
        _degrees.reserveCapacity(vertexCount)
        _sizes.reserveCapacity(hyperedgeCount)
    }

    /// The transpose, which is the dual: row `p` of the result is column `p` of this matrix, so
    /// its vertices are this matrix's columns. O(1): the two stored orientations swap.
    @inlinable
    public func transposed() -> IncidenceMatrix {
        IncidenceMatrix(_rows: _columns, _columns: _rows, _degrees: _sizes, _sizes: _degrees, _cellCount: _cellCount)
    }
}

// MARK: - Equatable, Hashable, Sendable

extension IncidenceMatrix: Equatable {
    /// Equal when the shapes and every cell are equal; column order counts. Capacity is not
    /// compared. O(n·⌈m/64⌉).
    @inlinable
    public static func == (lhs: IncidenceMatrix, rhs: IncidenceMatrix) -> Bool {
        lhs._cellCount == rhs._cellCount && lhs._rows.sameBits(as: rhs._rows)
    }
}

extension IncidenceMatrix: Hashable {
    /// The shape and every row's used words. O(n·⌈m/64⌉).
    @inlinable
    public func hash(into hasher: inout Hasher) {
        _rows.hashBits(into: &hasher)
    }
}

extension IncidenceMatrix: Sendable {}

// MARK: - Codable

/// The decoding limit both matrices share.
@usableFromInline
internal let _defaultMaximumDecodedCellCount = 1 << 28

extension IncidenceMatrix: Codable {
    @usableFromInline
    internal enum _CodingKeys: String, CodingKey {
        case vertexCount
        case hyperedges
    }

    /// The `userInfo` key for the largest n × m a decoder accepts. Its value is an `Int`.
    public static let maximumDecodedCellCountKey = CodingUserInfoKey(rawValue: "IncidenceMatrix.maximumDecodedCellCount")!

    /// The largest n × m decoded by default: 2²⁸ cells, 32 MiB per stored orientation. A short
    /// payload can name a large vertex count, so decoding refuses a larger shape unless the
    /// decoder's `userInfo[maximumDecodedCellCountKey]` allows it.
    public static let defaultMaximumDecodedCellCount = _defaultMaximumDecodedCellCount

    /// Encodes `{"vertexCount": n, "hyperedges": [[v, …], …]}`: the shape, and each column, by
    /// position, as its members in ascending order. The encoding of a matrix is always the same.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: _CodingKeys.self)
        try container.encode(vertexCount, forKey: .vertexCount)
        try container.encode((0 ..< hyperedgeCount).map { Array(_columns.row($0)) }, forKey: .hyperedges)
    }

    /// Decodes the form `encode(to:)` writes, throwing `DecodingError.dataCorrupted` for a negative
    /// vertex count, a shape over the limit, a member out of range, or a column whose members are
    /// not strictly ascending.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: _CodingKeys.self)
        let n = try container.decode(Int.self, forKey: .vertexCount)
        let columns = try container.decode([[Int]].self, forKey: .hyperedges)
        let maximum = decoder.userInfo[Self.maximumDecodedCellCountKey] as? Int ?? Self.defaultMaximumDecodedCellCount
        try Self._checkDecodedShape(n, columns.count, maximum: maximum, key: .vertexCount, in: container)
        self.init(_vertexCount: n, hyperedgeCount: columns.count)
        for (p, column) in columns.enumerated() {
            try Self._checkDecodedColumn(column, vertexCount: n, key: .hyperedges, in: container)
            for v in column { _setCell(v, p, to: true) }
        }
    }

    internal static func _checkDecodedShape<Key: CodingKey>(_ n: Int, _ m: Int, maximum: Int, key: Key, in container: KeyedDecodingContainer<Key>) throws {
        guard n >= 0 else {
            throw DecodingError.dataCorruptedError(forKey: key, in: container, debugDescription: "Negative vertex count")
        }
        let cells = n.multipliedReportingOverflow(by: m)
        guard !cells.overflow, cells.partialValue <= maximum else {
            throw DecodingError.dataCorruptedError(forKey: key, in: container, debugDescription: "A \(n) × \(m) matrix exceeds the decoding limit of \(maximum) cells")
        }
    }

    internal static func _checkDecodedColumn<Key: CodingKey>(_ column: [Int], vertexCount n: Int, key: Key, in container: KeyedDecodingContainer<Key>) throws {
        var previous = -1
        for v in column {
            guard v >= 0, v < n else {
                throw DecodingError.dataCorruptedError(forKey: key, in: container, debugDescription: "Member \(v) is out of range 0..<\(n)")
            }
            guard v > previous else {
                throw DecodingError.dataCorruptedError(forKey: key, in: container, debugDescription: "Members are not strictly ascending")
            }
            previous = v
        }
    }
}

// MARK: - Description

/// `n×m [row, row, …]`, each row a string of `cell(v, p)` for p in order, at most 16 rows and 64
/// columns before `…`.
internal func _matrixDescription(vertexCount n: Int, hyperedgeCount m: Int, _ cell: (Int, Int) -> Character) -> String {
    let limit = 16, columnLimit = 64
    var rows: [String] = []
    for v in 0 ..< Swift.min(n, limit) {
        var row = String((0 ..< Swift.min(m, columnLimit)).map { cell(v, $0) })
        if m > columnLimit { row.append("…") }
        rows.append(row)
    }
    if n > limit { rows.append("…") }
    return "\(n)×\(m) [" + rows.joined(separator: ", ") + "]"
}

extension IncidenceMatrix: CustomStringConvertible {
    /// The shape, then the rows as strings of `1` and `0`, column 0 leftmost, at most 16 rows of
    /// 64 columns: `3×2 [10, 01, 11]`. The empty matrix is `0×0 []`.
    public var description: String {
        _matrixDescription(vertexCount: vertexCount, hyperedgeCount: hyperedgeCount) { _rows.bit($0, $1) ? "1" : "0" }
    }
}
