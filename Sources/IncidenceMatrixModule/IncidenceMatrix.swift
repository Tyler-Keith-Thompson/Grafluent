import BitCollections
import GraphProtocols

/// The unoriented incidence matrix of a hypergraph, an n × m matrix of bits with cell (v, p) set
/// when vertex `v` is a member of column `p`.
///
/// The vertices are `0..<vertexCount`, and the columns, the hyperedges, are at positions
/// `0..<hyperedgeCount`. The matrix conforms to `Hypergraph`, so the `Hypergraphs` algorithms run
/// on it unchanged. It is not a `Graph`, even when built from one, because a cell edit can give a
/// column any number of bits.
///
/// A column is any set of vertices. Empty columns and repeated columns are kept. A graph's
/// self-loop becomes the one bit at its vertex, the hyperedge {v}. `OrientedIncidenceMatrix` is
/// the directed form, and `UndirectedIncidenceList` is the sparse representation of the same
/// hypergraphs.
///
/// ## Storage
///
/// Both orientations are stored: n rows of ⌈m/64⌉ words and m columns of ⌈n/64⌉ words, with the
/// row and column popcounts cached. `members(ofHyperedgeAt:)` and `incidentHyperedges(of:)` are
/// each one `BitSet` copy of ⌈n/64⌉ or ⌈m/64⌉ words, a cell edit writes two bits in O(1), and
/// `transposed()`, the dual, swaps the two orientations in O(1). The storage is 2·n·m/8 bytes, so
/// the matrix suits dense or small incidence, such as spectral work or hypergraphs with large
/// hyperedges. Use `UndirectedIncidenceList` for sparse incidence.
///
/// Equality compares cell for cell, with equal shape, so column order counts.
/// `UndirectedIncidenceList`'s equality ignores positions.
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
    /// The attached vertex maps (`addVertexMap(default:)`): dense, one value per row.
    @usableFromInline internal var _vertexMaps: _AttachedMaps
    /// The attached hyperedge maps (`addEdgeMap(default:)`): dense, one value per column.
    @usableFromInline internal var _edgeMaps: _AttachedMaps
    /// The generation, advanced by every structural mutation, which first makes `_degrees` (the
    /// identity array of `_GenerationStamp`) unique. An `OrientedIncidenceMatrix` keeps its own
    /// maps and generation; its planes' stay empty and unadvanced.
    @usableFromInline internal var _generation: _GenerationStamp

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
        _vertexMaps = _AttachedMaps()
        _edgeMaps = _AttachedMaps()
        _generation = _GenerationStamp()
    }

    @inlinable
    internal init(_rows: _BitRows, _columns: _BitRows, _degrees: ContiguousArray<Int>, _sizes: ContiguousArray<Int>, _cellCount: Int) {
        self._rows = _rows
        self._columns = _columns
        self._degrees = _degrees
        self._sizes = _sizes
        self._cellCount = _cellCount
        _vertexMaps = _AttachedMaps()
        _edgeMaps = _AttachedMaps()
        _generation = _GenerationStamp()
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
            flat.append(contentsOf: hyperedge)
            offsets.append(flat.count)
        }
        self.init(_vertexCount: vertexCount, hyperedgeCount: offsets.count - 1)
        for p in 0 ..< offsets.count - 1 {
            for k in offsets[p] ..< offsets[p + 1] { _setCell(flat[k], p, to: true) }
        }
    }

    /// The incidence matrix of an undirected graph, with a row per vertex by `vertexIndex(of:)` and
    /// a column per edge in `edges` order. Parallel edges keep a column each. A self-loop's column
    /// is the one bit at its vertex.
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

    /// The unoriented incidence matrix of a directed graph. Each edge's column has both ends, and a
    /// self-loop's column has one bit. Rows are by vertex index and columns in `edges` order.
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

    /// The union of the oriented matrix's planes, each column its sources and targets together.
    /// The result carries none of `oriented`'s attached maps.
    ///
    /// - Complexity: O(n·⌈m/64⌉ + m·⌈n/64⌉): the planes' words ORed, then the counts recounted.
    @inlinable
    public init(_ oriented: OrientedIncidenceMatrix) {
        self = oriented._sources
        let targets = oriented._targets
        _rows.formUnion(targets._rows)
        _columns.formUnion(targets._columns)
        var total = 0
        for v in 0 ..< _rows.rowCount {
            let count = _rows.popCount(ofRow: v)
            _degrees[v] = count
            total &+= count
        }
        for p in 0 ..< _columns.rowCount { _sizes[p] = _columns.popCount(ofRow: p) }
        _cellCount = total
    }

    /// The hypergraph conversion for a type that is both a graph and a hypergraph. It reads
    /// `hypergraph` as a hypergraph.
    @inlinable
    public init<H: Graph & Hypergraph>(_ hypergraph: H) {
        self.init(_copying: hypergraph)
    }

    /// The hypergraph conversion for a type that is both a directed graph and a directed
    /// hypergraph. It reads `hypergraph` as a hypergraph.
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
    /// copy. The `Hypergraphs` algorithms iterate this. O(1) to make, O(⌈n/64⌉ + k) to iterate.
    ///
    /// - Precondition: `position` is in `0..<hyperedgeCount`.
    @inlinable
    public func memberIndices(ofHyperedgeAt position: Int) -> MemberIndices {
        _checkHyperedge(position)
        return MemberIndices(_words: _columns.words(ofRow: position))
    }

    /// The columns that vertex `index` is a member of, ascending, read from the stored row without a
    /// copy. O(1) to make, O(⌈m/64⌉ + d) to iterate.
    ///
    /// - Precondition: `index` is in `0..<vertexCount`.
    @inlinable
    public func incidentHyperedgeIndices(ofIndex index: Int) -> MemberIndices {
        _checkVertex(index)
        return MemberIndices(_words: _rows.words(ofRow: index))
    }

    /// The set bits of the column below `index`.
    @inlinable
    public func _memberRank(ofIndex index: Int, inHyperedgeAt position: Int) -> Int {
        _checkVertex(index)
        _checkHyperedge(position)
        precondition(_columns.bit(position, index), "Vertex \(index) is not a member of column \(position)")
        return _columns.popCount(ofRow: position, before: index)
    }

    /// The column's member at offset `rank`: whole words skipped by popcount.
    @inlinable
    public func _memberIndex(atRank rank: Int, inHyperedgeAt position: Int) -> Int {
        _checkHyperedge(position)
        precondition(rank >= 0 && rank < _sizes[position], "Rank \(rank) is out of range 0..<\(_sizes[position])")
        return _columns.column(ofRow: position, atRank: rank)
    }

    /// The column's members, one word at a time.
    @inlinable
    public func _forEachMemberIndex(ofHyperedgeAt position: Int, _ body: (Int) -> Void) {
        _checkHyperedge(position)
        let start = position &* _columns.wordsPerRow, used = _BitRows.wordsNeeded(_columns.columnCount)
        _columns.words.withUnsafeBufferPointer { words in
            for k in 0 ..< used {
                var word = words[start &+ k]
                while word != 0 {
                    body(k &* UInt.bitWidth &+ word.trailingZeroBitCount)
                    word &= word &- 1
                }
            }
        }
    }

    /// The columns `vertex` is a member of, ascending. O(⌈m/64⌉): one `BitSet` copy.
    ///
    /// - Precondition: `vertex` is in `0..<vertexCount`.
    @inlinable
    public func incidentHyperedges(of vertex: Int) -> BitSet {
        _checkVertex(vertex)
        return _rows.row(vertex)
    }

    /// `incidentHyperedges(of:)`, throwing instead of trapping when `vertex` is not in
    /// `0..<vertexCount`. O(⌈m/64⌉).
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not in `0..<vertexCount`.
    @inlinable
    public func incidentHyperedges(checked vertex: Int) throws(VertexNotFound) -> BitSet {
        guard contains(vertex) else { throw VertexNotFound() }
        return incidentHyperedges(of: vertex)
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

    /// `degree(of:)`, throwing instead of trapping when `vertex` is not in `0..<vertexCount`.
    /// O(1).
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not in `0..<vertexCount`.
    @inlinable
    public func degree(checked vertex: Int) throws(VertexNotFound) -> Int {
        guard contains(vertex) else { throw VertexNotFound() }
        return degree(of: vertex)
    }

    @inlinable
    public func degree(ofIndex index: Int) -> Int { degree(of: index) }

    /// Whether `vertex` is in `0..<vertexCount`. Never traps.
    @inlinable
    public func contains(_ vertex: Int) -> Bool { vertex >= 0 && vertex < _rows.rowCount }

    /// Whether some column has exactly the members of `members`, ignoring order and repeats.
    /// False, without trapping, when a member is out of range.
    ///
    /// - Complexity: O(k + d·⌈n/64⌉). The columns at the first member are compared word by word.
    ///   The empty set scans the m cached sizes.
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

    /// `vertex` itself, throwing instead of trapping when it is not in `0..<vertexCount`. O(1).
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not in `0..<vertexCount`.
    @inlinable
    public func vertexIndex(checked vertex: Int) throws(VertexNotFound) -> Int {
        guard contains(vertex) else { throw VertexNotFound() }
        return vertexIndex(of: vertex)
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

extension IncidenceMatrix {
    /// The indices of the set bits of one stored row, ascending, read in place. These are a
    /// column's member indices, or a vertex's column indices (`IncidentHyperedgeIndices`).
    ///
    /// Reading allocates nothing. It shares the matrix's words copy-on-write, so a later mutation
    /// of the matrix leaves it unchanged.
    @frozen
    public struct MemberIndices: Sequence, Sendable {
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

    /// A vertex's column indices: its stored row, read in place.
    public typealias IncidentHyperedgeIndices = MemberIndices
}

extension IncidenceMatrix: Hypergraph {}

// MARK: - Mutation

extension IncidenceMatrix {
    /// Appends a vertex with no memberships, a zero row.
    ///
    /// - Returns: The new vertex, the old `vertexCount`.
    /// - Complexity: Amortized O(⌈m/64⌉). The columns move only when the vertex count outgrows
    ///   their words, which then double.
    @inlinable
    @discardableResult
    public mutating func appendVertex() -> Int {
        let vertex = _appendRow()
        if !_vertexMaps.isEmpty { _vertexMaps.appendDefaults(count: 1) }
        _generation.advance(writing: _degrees)
        return vertex
    }

    /// Appends a zero row, leaving the maps and the generation alone (a plane's step).
    @inlinable
    internal mutating func _appendRow() -> Int {
        let vertex = _rows.rowCount
        _rows.appendRow()
        _columns.appendColumn()
        _degrees.append(0)
        return vertex
    }

    /// Appends a column with `members`. A member listed twice is one bit. An empty sequence
    /// appends an empty column.
    ///
    /// - Returns: The new column's position, the old `hyperedgeCount`.
    /// - Precondition: Every member is in `0..<vertexCount`.
    /// - Complexity: Amortized O(n·⌈m/64⌉/m + ⌈n/64⌉ + k).
    @inlinable
    @discardableResult
    public mutating func insert(hyperedge members: some Sequence<Int>) -> Int {
        let position = _appendColumn(members)
        if !_edgeMaps.isEmpty { _edgeMaps.appendDefaults(count: 1) }
        // A member's cell writes `_degrees`; an empty column writes nothing there.
        if _sizes[position] == 0 { _generation.advance(owning: &_degrees) } else { _generation.advance(writing: _degrees) }
        return position
    }

    /// Appends a column with `members`, leaving the maps and the generation alone (a plane's step).
    @inlinable
    internal mutating func _appendColumn(_ members: some Sequence<Int>) -> Int {
        let position = _columns.rowCount
        _rows.appendColumn()
        _columns.appendRow()
        _sizes.append(0)
        for v in members { _setCell(v, position, to: true) }
        return position
    }

    /// Appends a column with `members` if every member is in `0..<vertexCount`; otherwise throws
    /// and changes nothing. A member listed twice is one bit.
    ///
    /// - Returns: The new column's position, the old `hyperedgeCount`.
    /// - Throws: `VertexNotFound` when a member is not in `0..<vertexCount`.
    /// - Complexity: `insert(hyperedge:)`'s, plus one pass over the members to check them first.
    @inlinable
    @discardableResult
    public mutating func insert(checked members: some Sequence<Int>) throws(VertexNotFound) -> Int {
        let members = Array(members)
        for v in members where !contains(v) { throw VertexNotFound() }
        return insert(hyperedge: members)
    }

    /// Sets cell (`vertex`, `position`). O(1).
    ///
    /// - Returns: Whether it changed, which is false when it was already set.
    /// - Precondition: `vertex` is in `0..<vertexCount` and `position` in `0..<hyperedgeCount`.
    @inlinable
    @discardableResult
    public mutating func insert(_ vertex: Int, intoHyperedgeAt position: Int) -> Bool {
        _checkVertex(vertex)
        _checkHyperedge(position)
        guard _setCell(vertex, position, to: true) else { return false }
        _generation.advance(writing: _degrees)
        return true
    }

    /// Clears cell (`vertex`, `position`). O(1).
    ///
    /// - Returns: Whether it changed, which is false when it was already clear.
    /// - Precondition: `vertex` is in `0..<vertexCount` and `position` in `0..<hyperedgeCount`.
    @inlinable
    @discardableResult
    public mutating func remove(_ vertex: Int, fromHyperedgeAt position: Int) -> Bool {
        _checkVertex(vertex)
        _checkHyperedge(position)
        guard _setCell(vertex, position, to: false) else { return false }
        _generation.advance(writing: _degrees)
        return true
    }

    /// Removes every vertex and column. Every attached map stays attached, empty.
    @inlinable
    public mutating func removeAll(keepingCapacity: Bool = false) {
        _removeAllCells(keepingCapacity: keepingCapacity)
        if !_vertexMaps.isEmpty { _vertexMaps.removeAll(keepingCapacity: keepingCapacity) }
        if !_edgeMaps.isEmpty { _edgeMaps.removeAll(keepingCapacity: keepingCapacity) }
        _generation.advance(owning: &_degrees)
    }

    /// Removes every vertex and column, leaving the maps and the generation alone (a plane's step).
    @inlinable
    internal mutating func _removeAllCells(keepingCapacity: Bool) {
        _rows.removeAll(keepingCapacity: keepingCapacity)
        _columns.removeAll(keepingCapacity: keepingCapacity)
        _degrees.removeAll(keepingCapacity: keepingCapacity)
        _sizes.removeAll(keepingCapacity: keepingCapacity)
        _cellCount = 0
    }

    /// Reserves storage for `vertexCount` vertices and `hyperedgeCount` columns, and room for
    /// their values in every attached map.
    @inlinable
    public mutating func reserveCapacity(vertexCount: Int, hyperedgeCount: Int) {
        _rows.reserveCapacity(rows: vertexCount, columns: hyperedgeCount)
        _columns.reserveCapacity(rows: hyperedgeCount, columns: vertexCount)
        _degrees.reserveCapacity(vertexCount)
        _generation.storageMayHaveMoved(_degrees)
        _sizes.reserveCapacity(hyperedgeCount)
        if !_vertexMaps.isEmpty { _vertexMaps.reserveCapacity(vertexCount) }
        if !_edgeMaps.isEmpty { _edgeMaps.reserveCapacity(hyperedgeCount) }
    }

    /// The transpose, which is the dual. Row `p` of the result is column `p` of this matrix, so its
    /// vertices are this matrix's columns. The result carries none of this matrix's attached maps.
    ///
    /// - Complexity: O(1). The two stored orientations swap.
    @inlinable
    public func transposed() -> IncidenceMatrix {
        IncidenceMatrix(_rows: _columns, _columns: _rows, _degrees: _sizes, _sizes: _degrees, _cellCount: _cellCount)
    }
}

// MARK: - Equatable, Hashable, Sendable

extension IncidenceMatrix: Equatable {
    /// Equal when the shapes and every cell are equal. Column order counts, and capacity does not.
    /// O(n·⌈m/64⌉).
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
internal let _defaultMaximumDecodedWordCount = 1 << 24

extension IncidenceMatrix: Codable {
    @usableFromInline
    internal enum _CodingKeys: String, CodingKey {
        case vertexCount
        case hyperedges
    }

    /// The `userInfo` key for the most words of storage a decoded matrix may take. Its value is
    /// an `Int`.
    public static let maximumDecodedWordCountKey = CodingUserInfoKey(rawValue: "IncidenceMatrix.maximumDecodedWordCount")!

    /// The most words (8 bytes each) a decoded matrix may take by default, 2²⁴ words or 128 MiB.
    ///
    /// An n × m matrix stores n·⌈m/64⌉ + m·⌈n/64⌉ words of bits and n + m counts, and an
    /// `OrientedIncidenceMatrix` twice that. A short payload can name a large shape, so decoding
    /// refuses a matrix whose storage would pass the limit unless the decoder's
    /// `userInfo[maximumDecodedWordCountKey]` allows it.
    public static let defaultMaximumDecodedWordCount = _defaultMaximumDecodedWordCount

    /// Encodes `{"vertexCount": n, "hyperedges": [[v, …], …]}`, with each column in position order
    /// as its members in ascending order. Equal matrices encode identically.
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
        let maximum = decoder.userInfo[Self.maximumDecodedWordCountKey] as? Int ?? Self.defaultMaximumDecodedWordCount
        try Self._checkDecodedShape(n, columns.count, planes: 1, maximum: maximum, key: .vertexCount, in: container)
        self.init(_vertexCount: n, hyperedgeCount: columns.count)
        for (p, column) in columns.enumerated() {
            try Self._checkDecodedColumn(column, vertexCount: n, key: .hyperedges, in: container)
            for v in column { _setCell(v, p, to: true) }
        }
    }

    /// Throws unless `n >= 0` and `planes` n × m planes fit in `maximum` words.
    internal static func _checkDecodedShape<Key: CodingKey>(_ n: Int, _ m: Int, planes: Int, maximum: Int, key: Key, in container: KeyedDecodingContainer<Key>) throws {
        guard n >= 0 else {
            throw DecodingError.dataCorruptedError(forKey: key, in: container, debugDescription: "Negative vertex count")
        }
        guard let words = _storedWordCount(n, m, planes: planes), words <= maximum else {
            throw DecodingError.dataCorruptedError(forKey: key, in: container, debugDescription: "A \(n) × \(m) matrix exceeds the decoding limit of \(maximum) words")
        }
    }

    /// `planes · (n·⌈m/64⌉ + m·⌈n/64⌉ + n + m)`, the words the planes store, or `nil` when it
    /// overflows.
    internal static func _storedWordCount(_ n: Int, _ m: Int, planes: Int) -> Int? {
        let width = UInt.bitWidth
        let wordsPerRow = m / width + (m % width == 0 ? 0 : 1)
        let wordsPerColumn = n / width + (n % width == 0 ? 0 : 1)
        guard wordsPerRow == 0 || n <= Int.max / wordsPerRow else { return nil }
        let rowWords = n * wordsPerRow
        guard wordsPerColumn == 0 || m <= Int.max / wordsPerColumn else { return nil }
        let columnWords = m * wordsPerColumn
        var total = 0
        for part in [rowWords, columnWords, n, m] {
            guard part <= Int.max - total else { return nil }
            total += part
        }
        guard planes <= 1 || total <= Int.max / planes else { return nil }
        return total * planes
    }

    internal static func _checkDecodedColumn<Key: CodingKey>(_ column: [Int], vertexCount n: Int, key: Key, in container: KeyedDecodingContainer<Key>) throws {
        var previous = -1
        for v in column {
            guard v < n else {
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
    /// The shape, then the rows as strings of `1` and `0` with column 0 leftmost, at most 16 rows
    /// of 64 columns, as in `3×2 [10, 01, 11]`. The empty matrix is `0×0 []`.
    public var description: String {
        _matrixDescription(vertexCount: vertexCount, hyperedgeCount: hyperedgeCount) { _rows.bit($0, $1) ? "1" : "0" }
    }
}
