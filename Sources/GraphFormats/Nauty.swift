import GraphProtocols

// The nauty formats (McKay's formats.txt): graph6 for simple undirected graphs, sparse6 for
// undirected graphs with loops and parallel edges, digraph6 for directed graphs with loops. Each is
// one line of bytes 63…126 holding six bits each, after an optional `>>graph6<<`-style header:
// the vertex count N(n), then the edges.

// MARK: - Readers

extension MutableGraph {
    /// Reads graph6: the vertices `0..<n`, then an edge `(i, j)`, `i < j`, for each set bit, in bit
    /// order (by `j`, then by `i`).
    ///
    /// The input is one graph: an optional `>>graph6<<` header, N(n), exactly ⌈n(n − 1) / 12⌉ data
    /// bytes, and an optional line feed (or CR LF) that nothing follows.
    ///
    /// - Parameters:
    ///   - input: The bytes.
    ///   - vertex: Each index's vertex, called once per index in order, after the data is checked.
    /// - Complexity: O(n² + m): the data holds one bit per pair.
    /// - Throws: `ParseError`: `syntax` at a byte outside 63…126 or past the data, or at anything
    ///   after the line feed; `unexpectedEndOfInput` when the size or the data is cut short;
    ///   `invalidValue` at the last data byte when a padding bit is set; `invalidVertex` at N(n) when
    ///   `vertex` returns `nil`.
    @inlinable public init(graph6 input: some Sequence<UInt8>, vertex: (Int) -> Vertex?) throws(ParseError) {
        self = try Self._readBulk(input, names: [], edgeAttribute: { _, _, _ in }) { (text, target, _) throws(ParseError) in
            try _readGraph6(text, into: &target, identity: false, map: vertex)
        }
    }

    /// Reads sparse6: the vertices `0..<n`, then the edges in the order the file lists them (each
    /// stored smaller endpoint first), loops and parallel edges kept.
    ///
    /// The input is one graph: an optional `>>sparse6<<` header, `:`, N(n), the data, and an optional
    /// line feed (or CR LF) that nothing follows. The vertices are inserted eagerly, so
    /// `maximumVertexCount` caps the memory a short file can ask for.
    ///
    /// - Parameters:
    ///   - input: The bytes.
    ///   - maximumVertexCount: The most vertices the file may declare; `nil`, the default, allows
    ///     16 per input byte plus 4,096.
    ///   - vertex: Each index's vertex, called once per index in order, after the data is checked.
    /// - Complexity: O(n + input size).
    /// - Throws: `ParseError`: `syntax` at a byte outside 63…126, at a first byte other than `:`, or
    ///   at anything after the line feed; `unsupported` at `;` (incremental sparse6);
    ///   `unexpectedEndOfInput` when the size is cut short; `limitExceeded` at N(n) when n is above
    ///   `maximumVertexCount`; `invalidVertex` at N(n) when `vertex` returns `nil`.
    @inlinable public init(
        sparse6 input: some Sequence<UInt8>, maximumVertexCount: Int? = nil, vertex: (Int) -> Vertex?
    ) throws(ParseError) {
        self = try Self._readBulk(input, names: [], edgeAttribute: { _, _, _ in }) { (text, target, _) throws(ParseError) in
            try _readSparse6(text, into: &target, maximumVertexCount: maximumVertexCount, identity: false, map: vertex)
        }
    }
}

extension MutableGraph where Vertex == Int {
    /// Reads graph6 onto the vertices `0..<n`.
    ///
    /// - Parameter input: The bytes.
    /// - Complexity: O(n² + m).
    /// - Throws: `ParseError`, as `init(graph6:vertex:)`.
    @inlinable public init(graph6 input: some Sequence<UInt8>) throws(ParseError) {
        self = try Self._readBulk(input, names: [], edgeAttribute: { _, _, _ in }) { (text, target, _) throws(ParseError) in
            try _readGraph6(text, into: &target, identity: true, map: { $0 })
        }
    }

    /// Reads sparse6 onto the vertices `0..<n`; more than `maximumVertexCount` (by default 16 per
    /// input byte plus 4,096) is `limitExceeded` at N(n).
    ///
    /// - Parameters:
    ///   - input: The bytes.
    ///   - maximumVertexCount: The most vertices the file may declare.
    /// - Complexity: O(n + input size).
    /// - Throws: `ParseError`, as `init(sparse6:maximumVertexCount:vertex:)`.
    @inlinable public init(sparse6 input: some Sequence<UInt8>, maximumVertexCount: Int? = nil) throws(ParseError) {
        self = try Self._readBulk(input, names: [], edgeAttribute: { _, _, _ in }) { (text, target, _) throws(ParseError) in
            try _readSparse6(text, into: &target, maximumVertexCount: maximumVertexCount, identity: true, map: { $0 })
        }
    }
}

extension MutableDirectedGraph {
    /// Reads digraph6: the vertices `0..<n`, then an arc `i → j` for each set bit of the adjacency
    /// matrix, row by row (loops allowed).
    ///
    /// The input is one graph: an optional `>>digraph6<<` header, `&`, N(n), exactly ⌈n² / 6⌉ data
    /// bytes, and an optional line feed (or CR LF) that nothing follows.
    ///
    /// - Parameters:
    ///   - input: The bytes.
    ///   - vertex: Each index's vertex, called once per index in order, after the data is checked.
    /// - Complexity: O(n² + m): the data holds one bit per ordered pair.
    /// - Throws: `ParseError`: `syntax` at a byte outside 63…126, at a first byte other than `&`, past
    ///   the data or after the line feed; `unexpectedEndOfInput` when the size or the data is cut
    ///   short; `invalidValue` at the last data byte when a padding bit is set; `invalidVertex` at
    ///   N(n) when `vertex` returns `nil`.
    @inlinable public init(digraph6 input: some Sequence<UInt8>, vertex: (Int) -> Vertex?) throws(ParseError) {
        self = try Self._readBulk(input, names: [], edgeAttribute: { _, _, _ in }) { (text, target, _) throws(ParseError) in
            try _readDigraph6(text, into: &target, identity: false, map: vertex)
        }
    }
}

extension MutableDirectedGraph where Vertex == Int {
    /// Reads digraph6 onto the vertices `0..<n`.
    ///
    /// - Parameter input: The bytes.
    /// - Complexity: O(n² + m).
    /// - Throws: `ParseError`, as `init(digraph6:vertex:)`.
    @inlinable public init(digraph6 input: some Sequence<UInt8>) throws(ParseError) {
        self = try Self._readBulk(input, names: [], edgeAttribute: { _, _, _ in }) { (text, target, _) throws(ParseError) in
            try _readDigraph6(text, into: &target, identity: true, map: { $0 })
        }
    }
}

// MARK: - Writers

extension Graph {
    /// Writes the graph as graph6: N(n), then one bit per pair of the vertices numbered `0..<n` in
    /// `vertices` order, and a line feed.
    ///
    /// - Parameters:
    ///   - output: The stream the text is appended to.
    ///   - header: Whether to start with `>>graph6<<`.
    /// - Complexity: O(n² + m).
    /// - Throws: `WriteError.selfLoop` for a self-loop and `WriteError.parallelEdge` for two edges
    ///   between one pair, checked before anything is written.
    @inlinable public func writeGraph6(to output: inout some TextOutputStream, header: Bool = false) throws(WriteError) {
        try _withOutputBuffer(&output) { (out) throws(WriteError) in
            try _writeNautyMatrix(_UndirectedSource(self), to: &out, header: header ? ">>graph6<<" : nil)
        }
    }

    /// Writes the graph as sparse6: `:`, N(n), every edge (loops and parallel edges included) in the
    /// order of (larger, smaller) endpoint numbers in `vertices` order, padded as nauty pads, and a
    /// line feed.
    ///
    /// - Parameters:
    ///   - output: The stream the text is appended to.
    ///   - header: Whether to start with `>>sparse6<<`.
    /// - Complexity: O(n + m).
    @inlinable public func writeSparse6(to output: inout some TextOutputStream, header: Bool = false) {
        _withOutputBuffer(&output) { out in
            _writeSparse6(_UndirectedSource(self), to: &out, header: header)
        }
    }
}

extension DirectedGraph {
    /// Writes the graph as digraph6: `&`, N(n), then the adjacency matrix of the vertices numbered
    /// `0..<n` in `vertices` order, row by row, and a line feed.
    ///
    /// - Parameters:
    ///   - output: The stream the text is appended to.
    ///   - header: Whether to start with `>>digraph6<<`.
    /// - Complexity: O(n² + m).
    /// - Throws: `WriteError.parallelEdge` for two arcs from one vertex to another, checked before
    ///   anything is written.
    @inlinable public func writeDigraph6(to output: inout some TextOutputStream, header: Bool = false) throws(WriteError) {
        try _withOutputBuffer(&output) { (out) throws(WriteError) in
            try _writeNautyMatrix(_DirectedSource(self), to: &out, header: header ? ">>digraph6<<" : nil)
        }
    }
}

// MARK: - Reading

/// The offset past `header` when `text` starts with it, else 0.
@inlinable func _nautyHeader(_ text: UnsafeBufferPointer<UInt8>, _ header: StaticString) -> Int {
    let k = header.utf8CodeUnitCount
    guard text.count >= k else { return 0 }
    let matches = header.withUTF8Buffer { h in
        for i in 0 ..< k where text[i] != h[i] { return false }
        return true
    }
    return matches ? k : 0
}

/// Whether `byte` is a data byte, 63…126.
@inline(__always)
@inlinable func _isNautyByte(_ byte: UInt8) -> Bool { byte &- 63 <= 63 }

/// N(n) at `p`, within the data ending at `end`: one byte below 126, or 126 and three bytes, or
/// 126 126 and six bytes (six bits each, big-endian). Returns n and the offset past it.
@inlinable func _nautySize(_ text: UnsafeBufferPointer<UInt8>, at p: Int, end: Int) throws(ParseError) -> (n: Int, end: Int) {
    guard p < end else { throw ParseError(.unexpectedEndOfInput, at: end) }
    let first = text[p]
    guard _isNautyByte(first) else { throw ParseError(.syntax, at: p) }
    if first < 126 { return (Int(first &- 63), p &+ 1) }
    var q = p &+ 1
    guard q < end else { throw ParseError(.unexpectedEndOfInput, at: end) }
    guard _isNautyByte(text[q]) else { throw ParseError(.syntax, at: q) }
    var width = 3
    if text[q] == 126 {
        width = 6
        q &+= 1
    }
    var n = 0
    for _ in 0 ..< width {
        guard q < end else { throw ParseError(.unexpectedEndOfInput, at: end) }
        guard _isNautyByte(text[q]) else { throw ParseError(.syntax, at: q) }
        n = n << 6 | Int(text[q] &- 63)
        q &+= 1
    }
    return (n, q)
}

/// The end of the data from `p`: before the line feed (or a CR LF) that ends it, or the end of the
/// input.
@inlinable func _nautyDataEnd(_ text: UnsafeBufferPointer<UInt8>, from p: Int) -> Int {
    var lineFeed = p
    while lineFeed < text.count && text[lineFeed] != 0x0A { lineFeed &+= 1 }
    return lineFeed < text.count && lineFeed > p && text[lineFeed &- 1] == 0x0D ? lineFeed &- 1 : lineFeed
}

/// Checks the data `text[p..<end]`: every byte 63…126, and at most `limit` of them (a byte past
/// them is `syntax`).
@inlinable func _checkNautyData(_ text: UnsafeBufferPointer<UInt8>, from p: Int, to end: Int, limit: Int) throws(ParseError) {
    var q = p
    while q < end {
        if q &- p == limit || !_isNautyByte(text[q]) { throw ParseError(.syntax, at: q) }
        q &+= 1
    }
}

/// Checks that nothing but a CR LF or an LF follows the data ending at `end`.
@inlinable func _checkNautyEnd(_ text: UnsafeBufferPointer<UInt8>, dataEnd end: Int) throws(ParseError) {
    let count = text.count
    var q = end
    if q < count && text[q] == 0x0D { q &+= 1 }
    if q < count && text[q] == 0x0A { q &+= 1 }
    if q < count { throw ParseError(.syntax, at: q) }
}

/// The number of data bytes `bits` bits take, or `Int.max` when `count × (count − 1) / 2`
/// (`triangle`) or `count²` bits would overflow (no input holds that many bytes).
@inlinable func _nautyDataBytes(_ count: Int, triangle: Bool) -> Int {
    guard count <= 3_037_000_499 else { return .max }
    let bits = triangle ? count &* (count &- 1) / 2 : count &* count
    return bits / 6 &+ (bits % 6 == 0 ? 0 : 1)
}

/// Reads graph6 or digraph6 (`triangle`: graph6's upper triangle by columns; else digraph6's
/// matrix by rows) into `target`.
@inlinable func _readNautyMatrix<Vertex, Direction>(
    _ text: UnsafeBufferPointer<UInt8>, into target: inout _BulkTarget<Vertex, Direction>, triangle: Bool,
    identity: Bool, map: (Int) -> Vertex?
) throws(ParseError) {
    var p = _nautyHeader(text, triangle ? ">>graph6<<" : ">>digraph6<<")
    let end = _nautyDataEnd(text, from: p)
    if !triangle {
        guard p < end else { throw ParseError(.unexpectedEndOfInput, at: end) }
        guard text[p] == UInt8(ascii: "&") else { throw ParseError(.syntax, at: p) }
        p &+= 1
    }
    let sizeOffset = p
    let (n, dataStart) = try _nautySize(text, at: p, end: end)
    let needed = _nautyDataBytes(n, triangle: triangle)
    try _checkNautyData(text, from: dataStart, to: end, limit: needed)
    if end &- dataStart < needed { throw ParseError(.unexpectedEndOfInput, at: end) }
    let bits = triangle ? n &* (n &- 1) / 2 : n &* n
    let padding = needed &* 6 &- bits
    var edgeCount = 0
    for q in dataStart ..< end { edgeCount &+= Int((text[q] &- 63).nonzeroBitCount) }
    if needed > 0 && (text[end &- 1] &- 63) & UInt8((1 << padding) &- 1) != 0 { throw ParseError(.invalidValue, at: end &- 1) }
    try _checkNautyEnd(text, dataEnd: end)
    let keys = try _insertIndexVertices(n, into: &target, identity: identity, map: map, at: sizeOffset)
    target.reserve(vertexCount: 0, edgeCount: edgeCount)
    guard edgeCount > 0 else { return }
    keys.withUnsafeBufferPointer { keys in
        // The pair of the next bit: (i, j) is column j, row i of the upper triangle for graph6,
        // row i, column j for digraph6.
        var i = 0, j = triangle ? 1 : 0
        for q in dataStart ..< end {
            let d = text[q] &- 63
            if d == 0 {
                if triangle {
                    i &+= 6
                    while i >= j {
                        i &-= j
                        j &+= 1
                    }
                } else {
                    j &+= 6
                    while j >= n {
                        j &-= n
                        i &+= 1
                    }
                }
                continue
            }
            var mask: UInt8 = 32
            while mask != 0 {
                if d & mask != 0 { _ = target.insertEdge(keys[i], keys[j]) }
                if triangle {
                    i &+= 1
                    if i == j {
                        i = 0
                        j &+= 1
                    }
                } else {
                    j &+= 1
                    if j == n {
                        j = 0
                        i &+= 1
                    }
                }
                mask >>= 1
            }
        }
    }
}

@inlinable func _readGraph6<Vertex, Direction>(
    _ text: UnsafeBufferPointer<UInt8>, into target: inout _BulkTarget<Vertex, Direction>, identity: Bool, map: (Int) -> Vertex?
) throws(ParseError) {
    try _readNautyMatrix(text, into: &target, triangle: true, identity: identity, map: map)
}

@inlinable func _readDigraph6<Vertex, Direction>(
    _ text: UnsafeBufferPointer<UInt8>, into target: inout _BulkTarget<Vertex, Direction>, identity: Bool, map: (Int) -> Vertex?
) throws(ParseError) {
    try _readNautyMatrix(text, into: &target, triangle: false, identity: identity, map: map)
}

/// The bits of nauty data, six to a byte, most significant first, read through a 64-bit window.
@usableFromInline internal struct _SixBitReader {
    @usableFromInline let text: UnsafeBufferPointer<UInt8>
    @usableFromInline var next: Int
    @usableFromInline let end: Int
    @usableFromInline var window: UInt64 = 0
    @usableFromInline var available = 0

    @inlinable init(_ text: UnsafeBufferPointer<UInt8>, from start: Int, to end: Int) {
        self.text = text
        next = start
        self.end = end
    }

    /// The next `width` (≤ 36) bits as a number, or `nil` when fewer remain.
    @inline(__always)
    @inlinable mutating func read(_ width: Int) -> Int? {
        if available < width {
            while available <= 57 && next < end {
                window = window << 6 | UInt64(text[next] &- 63)
                available &+= 6
                next &+= 1
            }
            if available < width { return nil }
        }
        available &-= width
        return Int(truncatingIfNeeded: (window >> UInt64(available)) & ((1 << UInt64(width)) &- 1))
    }
}

/// The number of bits sparse6 gives a vertex number: those of n − 1, 0 when n ≤ 1.
@inlinable func _sparse6Width(_ n: Int) -> Int { n <= 1 ? 0 : Int.bitWidth &- (n &- 1).leadingZeroBitCount }

/// Reads sparse6 into `target`.
@inlinable func _readSparse6<Vertex, Direction>(
    _ text: UnsafeBufferPointer<UInt8>, into target: inout _BulkTarget<Vertex, Direction>, maximumVertexCount: Int?,
    identity: Bool, map: (Int) -> Vertex?
) throws(ParseError) {
    var p = _nautyHeader(text, ">>sparse6<<")
    let end = _nautyDataEnd(text, from: p)
    guard p < end else { throw ParseError(.unexpectedEndOfInput, at: end) }
    if text[p] == UInt8(ascii: ";") { throw ParseError(.unsupported, at: p) }
    guard text[p] == UInt8(ascii: ":") else { throw ParseError(.syntax, at: p) }
    p &+= 1
    let sizeOffset = p
    let (n, dataStart) = try _nautySize(text, at: p, end: end)
    if n > _vertexBound(maximumVertexCount, inputCount: text.count) { throw ParseError(.limitExceeded, at: sizeOffset) }
    try _checkNautyData(text, from: dataStart, to: end, limit: .max)
    try _checkNautyEnd(text, dataEnd: end)
    let keys = try _insertIndexVertices(n, into: &target, identity: identity, map: map, at: sizeOffset)
    let width = _sparse6Width(n)
    // Each edge takes at least 1 + width bits.
    target.reserve(vertexCount: 0, edgeCount: (end &- dataStart) &* 6 / (1 &+ width))
    var bits = _SixBitReader(text, from: dataStart, to: end)
    var v = 0
    keys.withUnsafeBufferPointer { keys in
        while let b = bits.read(1), let x = bits.read(width) {
            if b == 1 { v &+= 1 }
            if x >= n || v >= n { break }
            if x > v {
                v = x
            } else {
                _ = target.insertEdge(keys[x], keys[v])
            }
        }
    }
}

// MARK: - Writing

/// Appends N(n): one byte up to 62, four up to 258,047, else eight.
@inlinable func _appendNautySize(_ n: Int, to out: inout _OutputBuffer) {
    precondition(n < 1 << 36, "The nauty formats hold fewer than 2^36 vertices")
    if n <= 62 {
        out.append(UInt8(truncatingIfNeeded: n) &+ 63)
        return
    }
    out.append(126)
    var shift = 12
    if n > 258_047 {
        out.append(126)
        shift = 30
    }
    while shift >= 0 {
        out.append(UInt8(truncatingIfNeeded: (n >> shift) & 63) &+ 63)
        shift &-= 6
    }
}

/// Writes graph6 (an undirected source: one bit per pair `i < j`, by `j` then `i`) or digraph6 (a
/// directed source: one bit per ordered pair, by rows). The bits are set first, so a loop or a
/// repeated pair throws before anything is written.
@inlinable func _writeNautyMatrix<Source: _WriteSource>(
    _ source: Source, to out: inout _OutputBuffer, header: StaticString?
) throws(WriteError) {
    let n = source.vertexCount
    precondition(n < 1 << 36, "The nauty formats hold fewer than 2^36 vertices")
    let directed = Source.isDirected
    var data = [UInt8](repeating: 0, count: _nautyDataBytes(n, triangle: !directed))
    try data.withUnsafeMutableBufferPointer { (data) throws(WriteError) in
        try source.forEachEdge { (_, u, v) throws(WriteError) in
            let k: Int
            if directed {
                k = u &* n &+ v
            } else {
                if u == v { throw .selfLoop }
                let (i, j) = u < v ? (u, v) : (v, u)
                k = j &* (j &- 1) / 2 &+ i
            }
            let byte = k / 6, mask = UInt8(32) >> UInt8(k % 6)
            if data[byte] & mask != 0 { throw .parallelEdge }
            data[byte] |= mask
        }
        for q in data.indices { data[q] &+= 63 }
    }
    if let header { out.appendASCII(header) }
    if directed { out.append(UInt8(ascii: "&")) }
    _appendNautySize(n, to: &out)
    data.withUnsafeBufferPointer { out.append($0) }
    out.append(0x0A)
}

/// The bits of nauty data being written, six to a byte, most significant first.
@usableFromInline internal struct _SixBitWriter {
    @usableFromInline var window: UInt64 = 0
    /// The bits in `window` not yet written, fewer than 6 between calls.
    @usableFromInline var pending = 0

    @inlinable init() {}

    /// Appends the low `width` (≤ 36) bits of `value`.
    @inline(__always)
    @inlinable mutating func put(_ value: Int, _ width: Int, to out: inout _OutputBuffer) {
        window = window << UInt64(width) | UInt64(truncatingIfNeeded: value)
        pending &+= width
        while pending >= 6 {
            pending &-= 6
            out.append(UInt8(truncatingIfNeeded: (window >> UInt64(pending)) & 63) &+ 63)
        }
        window &= (1 << UInt64(pending)) &- 1
    }
}

/// Writes sparse6 as nauty's `ntos6`: the edges sorted by (larger, smaller) endpoint by two stable
/// counting sorts, then one unit per edge (a skip unit first when the larger endpoint jumps), then
/// the padding.
@inlinable func _writeSparse6<Source: _WriteSource>(_ source: Source, to out: inout _OutputBuffer, header: Bool) {
    let n = source.vertexCount, m = source.edgeCount
    var low = [Int](repeating: 0, count: m), high = [Int](repeating: 0, count: m)
    var count = 0
    source.forEachEdge { _, u, v in
        low[count] = min(u, v)
        high[count] = max(u, v)
        count &+= 1
    }
    // By the smaller end, then (stably) by the larger.
    func countingOrder(_ keys: [Int], _ order: [Int]) -> [Int] {
        var start = [Int](repeating: 0, count: n &+ 1)
        for k in keys { start[k &+ 1] &+= 1 }
        for v in 0 ..< n { start[v &+ 1] &+= start[v] }
        var sorted = [Int](repeating: 0, count: order.count)
        for e in order {
            let k = keys[e]
            sorted[start[k]] = e
            start[k] &+= 1
        }
        return sorted
    }
    let order = countingOrder(high, countingOrder(low, Array(0 ..< count)))
    if header { out.appendASCII(">>sparse6<<") }
    out.append(UInt8(ascii: ":"))
    _appendNautySize(n, to: &out)
    let width = _sparse6Width(n)
    var bits = _SixBitWriter()
    var last = 0
    for e in order {
        let i = low[e], j = high[e]
        if j == last {
            bits.put(0, 1, to: &out)
        } else {
            bits.put(1, 1, to: &out)
            if j > last &+ 1 {
                bits.put(j, width, to: &out)
                bits.put(0, 1, to: &out)
            }
            last = j
        }
        bits.put(i, width, to: &out)
    }
    if bits.pending > 0 {
        let k = 6 &- bits.pending
        // All ones could read as one more edge, (n − 1, n − 1), when the last edge's larger end is
        // n − 2 and k + 1 bits fit: then a 0 first.
        let fill = k >= width &+ 1 && last == n &- 2 && n == 1 << width ? (1 << (k &- 1)) &- 1 : (1 << k) &- 1
        bits.put(fill, k, to: &out)
    }
    out.append(0x0A)
}
