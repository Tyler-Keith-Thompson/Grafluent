import CompressedSparseRowModule
import GraphProtocols

/// An immutable directed graph on the vertices `0..<n` whose rows of successors are Elias–Fano
/// coded (Elias 1974, Fano 1971; Vigna, "Quasi-succinct indices", WSDM 2013), as WebGraph's
/// `EFGraph` stores them: each row's ascending targets split into `l` low bits, packed, and the
/// high parts written in unary, so a row of `d` targets below `n` takes about `d · (2 + log₂(n/d))`
/// bits instead of `64 d`.
///
/// Reads decode a row from its start, so `successors(of:)` and the index-space walks cost O(1)
/// per target and `contains(edge:)`, `edgeIndex(of:)` and `target(ofEdgeAt:)` cost O(out-degree).
/// Edge positions are edge indices, `0..<m` in row-major order, as in `CompressedSparseRow`, and
/// the same graph has the same positions in both. Build one from any directed graph on `0..<n`,
/// from edges, or from a `CompressedSparseRow`; `CompressedSparseRow(graph)` decodes it back.
///
/// Every initializer collapses parallel edges and keeps self-loops.
@frozen
public struct EliasFanoGraph {
    /// Edge index offsets, `n + 1` entries: row `v` holds the edge indices
    /// `_offsets[v] ..< _offsets[v + 1]`.
    @usableFromInline internal var _offsets: [Int]
    /// The low `l` bits of every target, packed row after row, least significant bit first.
    @usableFromInline internal var _lower: [UInt64]
    /// The high parts in unary: in row `v`'s section, bit `high + i` is set for the `i`-th target.
    @usableFromInline internal var _upper: [UInt64]
    /// Where each row's low bits start in `_lower`, `n + 1` entries.
    @usableFromInline internal var _lowerStart: [Int]
    /// Where each row's unary section starts in `_upper`, `n + 1` entries.
    @usableFromInline internal var _upperStart: [Int]
    /// Each row's number of low bits, `l`.
    @usableFromInline internal var _width: [UInt8]
    @usableFromInline internal var _vertexMaps: _AttachedMaps
    @usableFromInline internal var _edgeMaps: _AttachedMaps
    @usableFromInline internal var _generation: _GenerationStamp
    @usableFromInline internal var _sourceGeneration: GraphGeneration

    /// Shared by every graph with no vertices, so creating one does not allocate.
    @usableFromInline
    internal static let _emptyOffsets: [Int] = [0]

    /// The graph with no vertices. Allocates nothing, so it has no generation.
    @inlinable
    public init() {
        _offsets = Self._emptyOffsets
        _lower = []
        _upper = []
        _lowerStart = Self._emptyOffsets
        _upperStart = Self._emptyOffsets
        _width = []
        _vertexMaps = _AttachedMaps()
        _edgeMaps = _AttachedMaps()
        _generation = _GenerationStamp()
        _sourceGeneration = .untracked
    }

    /// The graph with `vertexCount` vertices and no edges.
    ///
    /// - Precondition: `vertexCount >= 0`.
    @inlinable
    public init(vertexCount: Int) {
        self.init(CompressedSparseRow(vertexCount: vertexCount))
    }

    /// A graph with `vertexCount` vertices and the given edges, parallel edges collapsed. O(n + m)
    /// on edges in row-major order, O(n + m log m) otherwise.
    ///
    /// - Precondition: `vertexCount >= 0` and every endpoint is in `0..<vertexCount`.
    @inlinable
    public init(vertexCount: Int, edges: some Sequence<DirectedEdge<Int>>) {
        self.init(CompressedSparseRow(vertexCount: vertexCount, edges: edges))
    }

    /// The Elias–Fano form of any directed graph on the vertices `0..<graph.vertexCount`, with
    /// parallel edges collapsed. It records `graph`'s generation as `sourceGeneration`. The result
    /// has no attached maps, except that an `EliasFanoGraph` is returned as it is, maps included.
    ///
    /// - Precondition: The vertices are exactly `0..<graph.vertexCount`.
    @inlinable
    public init(_ graph: some DirectedGraph<Int>) {
        if let same = graph as? EliasFanoGraph {
            self = same
            _sourceGeneration = same.generation
            return
        }
        self.init(CompressedSparseRow(graph))
        _sourceGeneration = graph.generation
    }

    /// The Elias–Fano coding of a compressed sparse row graph's rows: the same vertices, edges and
    /// edge positions. O(n + m).
    @inlinable
    public init(_ graph: CompressedSparseRow) {
        let n = graph.vertexCount
        let offsets = graph.offsets
        let targets = graph.targets
        var width = [UInt8](repeating: 0, count: n)
        var lowerStart = [Int](repeating: 0, count: n &+ 1)
        var upperStart = [Int](repeating: 0, count: n &+ 1)
        // Pass 1: each row's width and the two sections' starts.
        for v in 0 ..< n {
            let degree = offsets[v &+ 1] &- offsets[v]
            let l = Self._width(vertexCount: n, degree: degree)
            width[v] = UInt8(l)
            lowerStart[v &+ 1] = lowerStart[v] &+ degree &* l
            upperStart[v &+ 1] = upperStart[v] &+ (degree == 0 ? 0 : degree &+ ((n &- 1) >> l) &+ 1)
        }
        var lower = [UInt64](repeating: 0, count: (lowerStart[n] &+ 63) >> 6)
        var upper = [UInt64](repeating: 0, count: (upperStart[n] &+ 63) >> 6)
        // Pass 2: the bits.
        lower.withUnsafeMutableBufferPointer { lower in
            upper.withUnsafeMutableBufferPointer { upper in
                for v in 0 ..< n {
                    let l = Int(width[v])
                    let mask: UInt64 = l == 0 ? 0 : (1 << UInt64(l)) &- 1
                    var lowBit = lowerStart[v]
                    let upBit = upperStart[v]
                    var i = 0
                    for k in offsets[v] ..< offsets[v &+ 1] {
                        let target = UInt64(targets[k])
                        if l > 0 {
                            Self._write(target & mask, width: l, at: lowBit, into: lower)
                            lowBit &+= l
                        }
                        let high = Int(target >> UInt64(l))
                        let bit = upBit &+ high &+ i
                        upper[bit >> 6] |= 1 << UInt64(bit & 63)
                        i &+= 1
                    }
                }
            }
        }
        _offsets = offsets
        _lower = lower
        _upper = upper
        _lowerStart = lowerStart
        _upperStart = upperStart
        _width = width
        _vertexMaps = _AttachedMaps()
        _edgeMaps = _AttachedMaps()
        _generation = _GenerationStamp()
        _sourceGeneration = .untracked
        _generation.stamp()
    }

    /// The number of low bits for a row of `degree` targets below `vertexCount`:
    /// ⌊log₂(vertexCount / degree)⌋, 0 for an empty row. The targets are distinct, so the ratio
    /// is at least 1.
    @inlinable
    internal static func _width(vertexCount n: Int, degree: Int) -> Int {
        guard degree > 0 else { return 0 }
        return Int.bitWidth &- 1 &- (n / degree).leadingZeroBitCount
    }

    /// Writes the low `width` bits of `value` at bit `position`, across a word boundary if need be.
    @inlinable
    internal static func _write(_ value: UInt64, width: Int, at position: Int, into words: UnsafeMutableBufferPointer<UInt64>) {
        let word = position >> 6, shift = UInt64(position & 63)
        words[word] |= value << shift
        if shift &+ UInt64(width) > 64 {
            words[word &+ 1] |= value >> (64 &- shift)
        }
    }

    /// Reads `width` bits at bit `position`.
    @inlinable
    internal static func _read(width: Int, at position: Int, from words: UnsafeBufferPointer<UInt64>) -> UInt64 {
        let word = position >> 6, shift = UInt64(position & 63)
        var value = words[word] >> shift
        if shift &+ UInt64(width) > 64 {
            value |= words[word &+ 1] << (64 &- shift)
        }
        return value & ((1 << UInt64(width)) &- 1)
    }

    /// Calls `body` with the `k`-th target of row `v` for `k` in `0 ..< count`, decoding the row
    /// from its start. O(count + count's upper bits).
    @inlinable
    @inline(__always)
    internal func _decodeRow(_ v: Int, count: Int, _ body: (Int) -> Void) {
        guard count > 0 else { return }
        let l = Int(_width[v])
        var lowBit = _lowerStart[v]
        let upStart = _upperStart[v]
        _lower.withUnsafeBufferPointer { lower in
            _upper.withUnsafeBufferPointer { upper in
                var bit = upStart
                var word = upper[bit >> 6] & (UInt64.max << UInt64(bit & 63))
                var wordBase = bit & ~63
                var i = 0
                while i < count {
                    while word == 0 {
                        wordBase &+= 64
                        word = upper[wordBase >> 6]
                    }
                    bit = wordBase &+ word.trailingZeroBitCount
                    word &= word &- 1
                    let high = bit &- upStart &- i
                    var target = high << l
                    if l > 0 {
                        target |= Int(Self._read(width: l, at: lowBit, from: lower))
                        lowBit &+= l
                    }
                    body(target)
                    i &+= 1
                }
            }
        }
    }

    /// The targets of row `v` as an array. O(out-degree).
    @inlinable
    internal func _row(_ v: Int) -> [Int] {
        let count = _offsets[v &+ 1] &- _offsets[v]
        var row: [Int] = []
        row.reserveCapacity(count)
        _decodeRow(v, count: count) { row.append($0) }
        return row
    }

    @inlinable
    internal func _checkVertex(_ vertex: Int) {
        precondition(vertex >= 0 && vertex < vertexCount, "Vertex \(vertex) is out of range 0..<\(vertexCount)")
    }

    /// The row holding edge index `edgeIndex`, by binary search of the offsets.
    @inlinable
    internal static func _source(ofEdgeAt edgeIndex: Int, offsets: [Int]) -> Int {
        var low = 0
        var high = offsets.count &- 1
        while low < high {
            let middle = low &+ (high &- low &+ 1) / 2
            if offsets[middle] <= edgeIndex { low = middle } else { high = middle &- 1 }
        }
        return low
    }
}

// MARK: - Queries

extension EliasFanoGraph {
    /// The number of vertices.
    @inlinable
    public var vertexCount: Int { _offsets.count &- 1 }

    /// The number of edges.
    @inlinable
    public var edgeCount: Int { _offsets[_offsets.count &- 1] }

    /// The vertices, `0..<vertexCount`.
    @inlinable
    public var vertices: Range<Int> { 0 ..< vertexCount }

    /// The edge index offsets, `vertexCount + 1` entries: row `v` holds the edge indices
    /// `offsets[v] ..< offsets[v + 1]`. O(1).
    @inlinable
    public var offsets: [Int] { _offsets }

    /// The bits the coded rows take per edge, over the low and high bit arrays. Not counting the
    /// offsets and the per-row starts, which are O(n) words. NaN with no edges.
    @inlinable
    public var bitsPerEdge: Double {
        Double(_lowerStart[vertexCount] &+ _upperStart[vertexCount]) / Double(edgeCount)
    }

    @inlinable
    public func contains(_ vertex: Int) -> Bool { vertex >= 0 && vertex < vertexCount }

    /// The vertices `vertex` has an edge to, ascending, decoded as they are read. O(1) per target.
    ///
    /// - Precondition: `vertex` is in `0..<vertexCount`.
    @inlinable
    public func successors(of vertex: Int) -> Successors {
        _checkVertex(vertex)
        return Successors(graph: self, row: vertex)
    }

    /// The number of edges leaving `vertex`. O(1).
    ///
    /// - Precondition: `vertex` is in `0..<vertexCount`.
    @inlinable
    public func outDegree(of vertex: Int) -> Int {
        _checkVertex(vertex)
        return _offsets[vertex &+ 1] &- _offsets[vertex]
    }

    /// The edge index of `edge`, or `nil` when the graph does not contain it: the row decoded up
    /// to the target. O(out-degree of the source).
    @inlinable
    public func edgeIndex(of edge: DirectedEdge<Int>) -> Int? {
        let n = vertexCount
        guard edge.source >= 0, edge.source < n, edge.target >= 0, edge.target < n else { return nil }
        let start = _offsets[edge.source]
        let count = _offsets[edge.source &+ 1] &- start
        var found = -1
        var k = 0
        _decodeRow(edge.source, count: count) { target in
            if found < 0 && target == edge.target { found = start &+ k }
            k &+= 1
        }
        return found < 0 ? nil : found
    }

    /// Whether the graph contains `edge`. O(out-degree of the source).
    @inlinable
    public func contains(edge: DirectedEdge<Int>) -> Bool { edgeIndex(of: edge) != nil }

    /// The source of the edge at `edgeIndex`: the row holding it, by binary search. O(log n).
    ///
    /// - Precondition: `edgeIndex` is in `0..<edgeCount`.
    @inlinable
    public func source(ofEdgeAt edgeIndex: Int) -> Int {
        precondition(edgeIndex >= 0 && edgeIndex < edgeCount, "Edge index \(edgeIndex) is out of range 0..<\(edgeCount)")
        return Self._source(ofEdgeAt: edgeIndex, offsets: _offsets)
    }

    /// The target of the edge at `edgeIndex`: its row decoded up to it. O(log n + out-degree).
    ///
    /// - Precondition: `edgeIndex` is in `0..<edgeCount`.
    @inlinable
    public func target(ofEdgeAt edgeIndex: Int) -> Int {
        let v = source(ofEdgeAt: edgeIndex)
        let wanted = edgeIndex &- _offsets[v]
        // The row is decoded up to the wanted target, which is the last one reported.
        var found = 0
        _decodeRow(v, count: wanted &+ 1) { found = $0 }
        return found
    }

    /// The graph with every edge reversed, coded again. O(n + m).
    @inlinable
    public func transposed() -> EliasFanoGraph {
        EliasFanoGraph(CompressedSparseRow(self).transposed())
    }

    /// The rows decoded into compressed sparse row arrays. O(n + m).
    @inlinable
    internal func _decodedRows() -> (offsets: [Int], targets: [Int]) {
        let n = vertexCount
        var targets = [Int](repeating: 0, count: edgeCount)
        targets.withUnsafeMutableBufferPointer { targets in
            var k = 0
            for v in 0 ..< n {
                _decodeRow(v, count: _offsets[v &+ 1] &- _offsets[v]) { target in
                    targets[k] = target
                    k &+= 1
                }
            }
        }
        return (_offsets, targets)
    }

    /// The generation of the graph `init(_:)` built this one from, when that graph tracks
    /// generations, or `.untracked`. Not part of equality.
    @inlinable
    public var sourceGeneration: GraphGeneration { _sourceGeneration }

    /// Whether this graph was built by `init(_:)` from `graph`'s storage and that storage has not
    /// been structurally mutated since. O(1).
    @inlinable
    public func isCurrent(for graph: some DirectedGraph) -> Bool {
        _sourceGeneration.isCurrent(for: graph)
    }

    /// The generation of this graph, which never changes because the graph is immutable.
    /// `init()`'s empty graph has no generation and is current for nothing.
    @inlinable
    public var generation: GraphGeneration { _generation.generation }
}

// MARK: - Rows and edges as collections

extension EliasFanoGraph {
    /// A row of successors, decoded as it is iterated. It holds the two bit arrays, not the graph,
    /// so making one costs two retains. `underestimatedCount` is the exact count, O(1);
    /// everything else walks the row.
    @frozen
    public struct Successors: Sequence {
        @usableFromInline let _lower: [UInt64]
        @usableFromInline let _upper: [UInt64]
        @usableFromInline let _lowStart: Int
        @usableFromInline let _upStart: Int
        @usableFromInline let _width: Int
        @usableFromInline let _count: Int

        @inlinable
        init(graph: EliasFanoGraph, row: Int) {
            _lower = graph._lower
            _upper = graph._upper
            _lowStart = graph._lowerStart[row]
            _upStart = graph._upperStart[row]
            _width = Int(graph._width[row])
            _count = graph._offsets[row &+ 1] &- graph._offsets[row]
        }

        /// The number of successors. O(1).
        @inlinable
        public var underestimatedCount: Int { _count }

        @inlinable
        public func makeIterator() -> Iterator { Iterator(self) }

        /// Decodes one target per step: the next set bit of the row's unary section and the
        /// next `l` low bits.
        @frozen
        public struct Iterator: IteratorProtocol {
            @usableFromInline let _lower: [UInt64]
            @usableFromInline let _upper: [UInt64]
            @usableFromInline let _upStart: Int
            @usableFromInline let _width: Int
            @usableFromInline var _lowBit: Int
            @usableFromInline var _word: UInt64
            @usableFromInline var _wordBase: Int
            @usableFromInline var _remaining: Int
            @usableFromInline var _index: Int

            @inlinable
            init(_ row: Successors) {
                _lower = row._lower
                _upper = row._upper
                _upStart = row._upStart
                _width = row._width
                _lowBit = row._lowStart
                _remaining = row._count
                _index = 0
                _wordBase = row._upStart & ~63
                _word = row._count == 0 ? 0 : row._upper[row._upStart >> 6] & (UInt64.max << UInt64(row._upStart & 63))
            }

            @inlinable
            public mutating func next() -> Int? {
                guard _remaining > 0 else { return nil }
                while _word == 0 {
                    _wordBase &+= 64
                    _word = _upper[_wordBase >> 6]
                }
                let bit = _wordBase &+ _word.trailingZeroBitCount
                _word &= _word &- 1
                var target = (bit &- _upStart &- _index) << _width
                if _width > 0 {
                    // The low bits: a word and, across a boundary, the next.
                    let word = _lowBit >> 6, shift = UInt64(_lowBit & 63)
                    var low = _lower[word] >> shift
                    if shift &+ UInt64(_width) > 64 { low |= _lower[word &+ 1] << (64 &- shift) }
                    target |= Int(low & ((1 << UInt64(_width)) &- 1))
                    _lowBit &+= _width
                }
                _index &+= 1
                _remaining &-= 1
                return target
            }
        }
    }

    /// Every edge in row-major order; the position of an edge is its index.
    @inlinable
    public var edges: Edges { Edges(graph: self, bounds: 0 ..< edgeCount) }

    /// The edges of a graph, or a contiguous run of them. Positions are edge indices. Iterating
    /// decodes each row once, O(1) amortized per edge; subscripting one position is O(log n +
    /// out-degree), so prefer iteration to index loops.
    @frozen
    public struct Edges: RandomAccessCollection {
        @usableFromInline let _graph: EliasFanoGraph
        public let startIndex: Int
        public let endIndex: Int

        @inlinable
        init(graph: EliasFanoGraph, bounds: Range<Int>) {
            _graph = graph
            startIndex = bounds.lowerBound
            endIndex = bounds.upperBound
        }

        public typealias Indices = Range<Int>
        public typealias SubSequence = Edges

        @inlinable public var indices: Range<Int> { startIndex ..< endIndex }

        @inlinable
        public subscript(position: Int) -> DirectedEdge<Int> {
            precondition(position >= startIndex && position < endIndex, "Index \(position) is out of bounds \(startIndex)..<\(endIndex)")
            return DirectedEdge(from: _graph.source(ofEdgeAt: position), to: _graph.target(ofEdgeAt: position))
        }

        @inlinable
        public subscript(bounds: Range<Int>) -> Edges {
            precondition(bounds.lowerBound >= startIndex && bounds.upperBound <= endIndex, "Range \(bounds) is out of bounds \(startIndex)..<\(endIndex)")
            return Edges(graph: _graph, bounds: bounds)
        }

        @inlinable
        func _position(of element: DirectedEdge<Int>) -> Int? {
            guard let k = _graph.edgeIndex(of: element), k >= startIndex, k < endIndex else { return nil }
            return k
        }

        @inlinable
        public func _customContainsEquatableElement(_ element: DirectedEdge<Int>) -> Bool? { _position(of: element) != nil }

        @inlinable
        public func _customIndexOfEquatableElement(_ element: DirectedEdge<Int>) -> Int?? { .some(_position(of: element)) }

        @inlinable
        public func _customLastIndexOfEquatableElement(_ element: DirectedEdge<Int>) -> Int?? { .some(_position(of: element)) }

        @inlinable
        public func makeIterator() -> Iterator { Iterator(graph: _graph, bounds: startIndex ..< endIndex) }

        /// Walks the rows in order from one search for the first source, decoding each row once
        /// and skipping the targets before the first position.
        @frozen
        public struct Iterator: IteratorProtocol {
            @usableFromInline let _graph: EliasFanoGraph
            @usableFromInline var _source: Int
            @usableFromInline var _rowEnd: Int
            @usableFromInline var _position: Int
            @usableFromInline let _end: Int
            @usableFromInline var _row: EliasFanoGraph.Successors.Iterator

            @inlinable
            init(graph: EliasFanoGraph, bounds: Range<Int>) {
                _graph = graph
                _position = bounds.lowerBound
                _end = bounds.upperBound
                if bounds.isEmpty {
                    _source = 0
                    _rowEnd = 0
                    _row = EliasFanoGraph.Successors(graph: graph, row: 0).makeIterator()
                    _remainingSkip = 0
                } else {
                    let source = EliasFanoGraph._source(ofEdgeAt: bounds.lowerBound, offsets: graph._offsets)
                    _source = source
                    _rowEnd = graph._offsets[source &+ 1]
                    _row = EliasFanoGraph.Successors(graph: graph, row: source).makeIterator()
                    _remainingSkip = bounds.lowerBound &- graph._offsets[source]
                }
            }

            /// Targets of the first row before the first position, skipped on the first step.
            @usableFromInline var _remainingSkip: Int

            @inlinable
            public mutating func next() -> DirectedEdge<Int>? {
                guard _position < _end else { return nil }
                while _remainingSkip > 0 {
                    _ = _row.next()
                    _remainingSkip &-= 1
                }
                while _rowEnd <= _position {
                    _source &+= 1
                    _rowEnd = _graph._offsets[_source &+ 1]
                    _row = EliasFanoGraph.Successors(graph: _graph, row: _source).makeIterator()
                }
                _position &+= 1
                return DirectedEdge(from: _source, to: _row.next().unsafelyUnwrapped)
            }
        }
    }
}

// MARK: - Conformances

extension EliasFanoGraph: Hashable {
    /// Equal when the vertex counts and the edges are equal: the coding is canonical, so that is
    /// exactly when the arrays are equal.
    @inlinable
    public static func == (lhs: EliasFanoGraph, rhs: EliasFanoGraph) -> Bool {
        lhs._offsets == rhs._offsets && lhs._lower == rhs._lower && lhs._upper == rhs._upper
    }

    @inlinable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(_offsets)
        hasher.combine(_lower)
        hasher.combine(_upper)
    }
}

extension EliasFanoGraph: Sendable {}
extension EliasFanoGraph.Successors: Sendable {}
extension EliasFanoGraph.Successors.Iterator: Sendable {}
extension EliasFanoGraph.Edges: Sendable {}
extension EliasFanoGraph.Edges.Iterator: Sendable {}

extension EliasFanoGraph: Codable {
    /// Encodes the rows decoded, as `CompressedSparseRow` does: `{"offsets": [...], "targets":
    /// [...]}`, so the two forms read each other's payloads.
    public func encode(to encoder: any Encoder) throws {
        try CompressedSparseRow(self).encode(to: encoder)
    }

    /// Decodes `CompressedSparseRow`'s payload and codes its rows; its validation errors are
    /// `DecodingError.dataCorrupted`.
    public init(from decoder: any Decoder) throws {
        self.init(try CompressedSparseRow(from: decoder))
    }
}

extension EliasFanoGraph: CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable {
    /// The vertices and the edges, at most 16 of each, as in `[0, 1, 2]; [0→1, 1→2]`.
    public var description: String {
        GraphDescription.graph(vertices: vertices, vertexCount: vertexCount, edges: edges, edgeCount: edgeCount)
    }

    /// The type, the counts, the bits per edge, and at most 16 edges.
    public var debugDescription: String {
        "EliasFanoGraph(vertexCount: \(vertexCount), edgeCount: \(edgeCount), edges: "
            + GraphDescription.list(edges, count: edgeCount) { GraphDescription.edge($0) }
            + ")"
    }

    /// Shows the offsets, the row widths and the two bit arrays, so a debugger can browse them.
    public var customMirror: Mirror {
        Mirror(self, children: ["offsets": _offsets, "widths": _width, "lower": _lower, "upper": _upper], displayStyle: .struct)
    }
}

extension CompressedSparseRow {
    /// The compressed sparse row form of an Elias–Fano coded graph: the same vertices, edges and
    /// edge positions, the rows decoded in one pass. O(n + m). Its `sourceGeneration` is
    /// `.untracked`.
    @inlinable
    public init(_ graph: EliasFanoGraph) {
        let (offsets, targets) = graph._decodedRows()
        self.init(_offsets: offsets, _targets: targets)
    }
}
