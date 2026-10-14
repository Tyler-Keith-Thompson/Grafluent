import GraphProtocols

// The METIS graph format (Karypis, the METIS manual §4.1.1): a header `n m [fmt [ncon]]`, then one
// line per vertex listing its neighbours (1-based), each undirected edge on both endpoints' lines;
// `fmt` adds vertex sizes, vertex weights and edge weights. `%` lines are comments.

// MARK: - Readers

extension MutableGraph {
    /// Reads a METIS graph file: the vertices `0..<n`, then an edge `(u, v)` for each neighbour
    /// `v > u` on `u`'s line, in file order; vertex sizes and weights under `"size"` and `"weight"`,
    /// edge weights under `"weight"` (`.integer`).
    ///
    /// Every neighbour entry must be mirrored on the other endpoint's line with the same weight. The
    /// vertices are inserted eagerly, so `maximumVertexCount` caps the memory a short file can ask
    /// for.
    ///
    /// - Parameters:
    ///   - input: The bytes.
    ///   - maximumVertexCount: The most vertices the header may declare; `nil`, the default, allows
    ///     16 per input byte plus 4,096.
    ///   - vertex: Each index's vertex, called once per index in order, at the header.
    ///   - vertexAttribute: Called with each vertex, `"size"` or `"weight"` and its value, after the
    ///     build.
    ///   - edgeAttribute: Called with each edge's position, `"weight"` and its value, after the build.
    /// - Complexity: O(n + input size), plus sorting a line's later neighbours when the file does
    ///   not list them in order.
    /// - Throws: `ParseError`: `syntax` at a malformed header or field, or a field missing at a line's
    ///   end; `invalidValue` at a bad `fmt` or `ncon`, a value that is not an integer, a self-loop, or
    ///   an entry without its mirror; `unsupported` at `ncon` above 1; `indexOutOfRange` at a
    ///   neighbour outside `1...n`; `unexpectedEndOfInput` with fewer than `n` vertex lines;
    ///   `entryCountMismatch` at `m` when the edges are not `m`; `numberOutOfRange` at a number
    ///   outside `Int`; `limitExceeded` at n above `maximumVertexCount`; `invalidVertex` at n when
    ///   `vertex` returns `nil`.
    @inlinable public init(
        metis input: some Sequence<UInt8>,
        maximumVertexCount: Int? = nil,
        vertex: (Int) -> Vertex?,
        vertexAttribute: (Vertex, String, AttributeValue) -> Void = { _, _, _ in },
        edgeAttribute: (Edges.Index, String, AttributeValue) -> Void = { _, _, _ in }
    ) throws(ParseError) {
        self = try Self._readBulk(input, names: ["weight", "size"], vertexAttribute: vertexAttribute,
                                  edgeAttribute: edgeAttribute) { (text, target, buffer) throws(ParseError) in
            try _readMETIS(text, into: &target, buffer: &buffer, maximumVertexCount: maximumVertexCount, identity: false, map: vertex)
        }
    }
}

extension MutableGraph where Vertex == Int {
    /// Reads a METIS graph file onto the vertices `0..<n`; more than `maximumVertexCount` (by
    /// default 16 per input byte plus 4,096) is `limitExceeded` at n.
    ///
    /// - Parameters:
    ///   - input: The bytes.
    ///   - maximumVertexCount: The most vertices the header may declare.
    ///   - vertexAttribute: Called with each vertex, `"size"` or `"weight"` and its value.
    ///   - edgeAttribute: Called with each edge's position, `"weight"` and its value.
    /// - Complexity: O(n + input size).
    /// - Throws: `ParseError`, as `init(metis:maximumVertexCount:vertex:vertexAttribute:edgeAttribute:)`.
    @inlinable public init(
        metis input: some Sequence<UInt8>,
        maximumVertexCount: Int? = nil,
        vertexAttribute: (Vertex, String, AttributeValue) -> Void = { _, _, _ in },
        edgeAttribute: (Edges.Index, String, AttributeValue) -> Void = { _, _, _ in }
    ) throws(ParseError) {
        self = try Self._readBulk(input, names: ["weight", "size"], vertexAttribute: vertexAttribute,
                                  edgeAttribute: edgeAttribute) { (text, target, buffer) throws(ParseError) in
            try _readMETIS(text, into: &target, buffer: &buffer, maximumVertexCount: maximumVertexCount, identity: true, map: { $0 })
        }
    }
}

// MARK: - Writers

extension Graph {
    /// Writes the graph as a METIS graph file: `n m`, then one line per vertex in `vertices` order
    /// listing its neighbours (1-based) in the order of its edges' positions.
    ///
    /// - Parameter output: The stream the text is appended to.
    /// - Complexity: O(n + m + output size).
    /// - Throws: `WriteError.selfLoop` for a self-loop and `WriteError.parallelEdge` for two edges
    ///   between one pair, which METIS does not allow; checked before anything is written.
    @inlinable public func writeMETIS(to output: inout some TextOutputStream) throws(WriteError) {
        try _withOutputBuffer(&output) { (out) throws(WriteError) in
            try _writeMETIS(_UndirectedSource(self), to: &out, hasWeight: false, weight: { _ in 0 })
        }
    }

    /// Writes the graph as a METIS graph file with edge weights: `n m 1`, then one line per vertex
    /// listing each neighbour (1-based) and the edge's weight.
    ///
    /// - Parameters:
    ///   - output: The stream the text is appended to.
    ///   - weight: Each edge's weight, by position; called twice per edge (once per endpoint's line).
    /// - Complexity: O(n + m + output size), plus the closure's cost.
    /// - Throws: `WriteError.selfLoop` and `WriteError.parallelEdge`, as `writeMETIS(to:)`.
    @inlinable public func writeMETIS(to output: inout some TextOutputStream, weight: (Edges.Index) -> Int) throws(WriteError) {
        try _withOutputBuffer(&output) { (out) throws(WriteError) in
            try _writeMETIS(_UndirectedSource(self), to: &out, hasWeight: true, weight: weight)
        }
    }
}

// MARK: - Reading

/// The later neighbours (`v > u`) of the lines read so far, each line's sorted by neighbour (stably),
/// with a cursor per line for the earlier neighbours of later lines to consume their mirrors.
@usableFromInline internal struct _METISMirrors {
    /// Per line `u`: where its entries start in the arrays (one more entry than lines).
    @usableFromInline var start: [Int] = [0]
    @usableFromInline var neighbour: [Int] = []
    @usableFromInline var weight: [Int] = []
    @usableFromInline var offset: [Int] = []
    /// The entry's number in document order among the later-neighbour entries.
    @usableFromInline var order: [Int] = []
    @usableFromInline var consumed: [Bool] = []
    @usableFromInline var cursor: [Int] = []

    @inlinable init() {}

    /// Ends line `u` (whose entries were appended since the last call): sorts them by neighbour.
    @inlinable mutating func endLine() {
        let first = start[start.count &- 1], end = neighbour.count
        var sorted = true
        if end &- first > 1 {
            for k in (first &+ 1) ..< end where neighbour[k &- 1] > neighbour[k] {
                sorted = false
                break
            }
        }
        if !sorted {
            let permutation = (first ..< end).sorted { neighbour[$0] != neighbour[$1] ? neighbour[$0] < neighbour[$1] : $0 < $1 }
            let n = permutation.map { neighbour[$0] }, w = permutation.map { weight[$0] }
            let o = permutation.map { offset[$0] }, d = permutation.map { order[$0] }
            neighbour.replaceSubrange(first ..< end, with: n)
            weight.replaceSubrange(first ..< end, with: w)
            offset.replaceSubrange(first ..< end, with: o)
            order.replaceSubrange(first ..< end, with: d)
        }
        consumed.append(contentsOf: repeatElement(false, count: end &- first))
        cursor.append(first)
        start.append(end)
    }

    /// Consumes the mirror of the entry `v` (with `w`) on line `u`, `v < u`: the earliest unconsumed
    /// entry `u` on line `v` with weight `w`. Whether there was one.
    @inlinable mutating func consume(line v: Int, neighbour u: Int, weight w: Int) -> Bool {
        let end = start[v &+ 1]
        var k = cursor[v]
        while k < end && neighbour[k] < u { k &+= 1 }
        cursor[v] = k
        while k < end && neighbour[k] == u {
            if !consumed[k] && weight[k] == w {
                consumed[k] = true
                return true
            }
            k &+= 1
        }
        return false
    }

    /// The offset of the first entry, in document order, that no mirror consumed.
    @inlinable func firstUnconsumed() -> Int? {
        var best = -1, at = 0
        for k in consumed.indices where !consumed[k] && (best < 0 || order[k] < best) {
            best = order[k]
            at = offset[k]
        }
        return best < 0 ? nil : at
    }
}

/// Reads a METIS graph file into `target`, in one pass: the header inserts the vertices; each
/// vertex line reports its size and weight, inserts an edge per later neighbour, and consumes the
/// mirror of each earlier one. A missing mirror is reported once every line is read.
@inlinable func _readMETIS<Vertex>(
    _ text: UnsafeBufferPointer<UInt8>, into target: inout _BulkTarget<Vertex, _Undirected>, buffer: inout _AttributeBuffer,
    maximumVertexCount: Int?, identity: Bool, map: (Int) -> Vertex?
) throws(ParseError) {
    var fields: [(Int, Int)] = []
    var start = 0
    // The header: the first line that is neither a comment nor blank.
    var header: _Line?
    while let line = _line(text, from: start) {
        start = line.next
        if line.end > line.start && text[line.start] == UInt8(ascii: "%") { continue }
        _fields(text, line.start, line.end, into: &fields, limit: 5)
        if fields.isEmpty { continue }
        header = line
        break
    }
    guard let header else { throw ParseError(.unexpectedEndOfInput, at: text.count) }
    if fields.count < 2 { throw ParseError(.syntax, at: header.end) }
    if fields.count > 4 { throw ParseError(.syntax, at: fields[4].0) }
    let n = try _matrixMarketCount(text, fields[0].0, fields[0].1)
    let m = try _matrixMarketCount(text, fields[1].0, fields[1].1)
    let countOffset = fields[0].0, edgeCountOffset = fields[1].0
    var hasSize = false, hasVertexWeight = false, hasEdgeWeight = false
    if fields.count > 2 {
        let (s, e) = fields[2]
        guard e &- s <= 3 else { throw ParseError(.invalidValue, at: s) }
        for q in s ..< e {
            let d = text[q]
            guard d == UInt8(ascii: "0") || d == UInt8(ascii: "1") else { throw ParseError(.invalidValue, at: s) }
            let place = e &- 1 &- q
            if d == UInt8(ascii: "1") {
                if place == 0 { hasEdgeWeight = true } else if place == 1 { hasVertexWeight = true } else { hasSize = true }
            }
        }
    }
    if fields.count > 3 {
        let (s, e) = fields[3]
        let ncon = try _matrixMarketCount(text, s, e)
        if !hasVertexWeight || ncon == 0 { throw ParseError(.invalidValue, at: s) }
        if ncon > 1 { throw ParseError(.unsupported, at: s) }
    }
    if n > _vertexBound(maximumVertexCount, inputCount: text.count) { throw ParseError(.limitExceeded, at: countOffset) }
    let keys = try _insertIndexVertices(n, into: &target, identity: identity, map: map, at: countOffset)
    // Each later neighbour takes at least 2 bytes.
    target.reserve(vertexCount: 0, edgeCount: min(m, (text.count &- start) / 4))

    var mirrors = _METISMirrors()
    // The first earlier-neighbour entry without a mirror, reported once every line is read.
    var unmirrored: Int?
    var later = 0
    var u = 0
    while u < n {
        guard let line = _line(text, from: start) else { throw ParseError(.unexpectedEndOfInput, at: text.count) }
        start = line.next
        if line.end > line.start && text[line.start] == UInt8(ascii: "%") { continue }
        var q = line.start
        // The next field, or `nil` at the line's end.
        @inline(__always) func next(_ q: inout Int) -> (Int, Int)? {
            while q < line.end && _isBlank(text[q]) { q &+= 1 }
            guard q < line.end else { return nil }
            let s = q
            while q < line.end && !_isBlank(text[q]) { q &+= 1 }
            return (s, q)
        }
        if hasSize {
            guard let field = next(&q) else { throw ParseError(.syntax, at: line.end) }
            buffer.recordVertex(keys[u], 1, .integer(try _integerValue(text, field)))
        }
        if hasVertexWeight {
            guard let field = next(&q) else { throw ParseError(.syntax, at: line.end) }
            buffer.recordVertex(keys[u], 0, .integer(try _integerValue(text, field)))
        }
        while let field = next(&q) {
            let v: Int
            if let value = _fastDecimal(text, field, signed: false), value >= 1 && value <= n {
                v = value &- 1
            } else {
                v = try _oneBasedIndex(text, field, count: n)
            }
            if v == u { throw ParseError(.invalidValue, at: field.0) }
            var w = 0
            if hasEdgeWeight {
                guard let weightField = next(&q) else { throw ParseError(.syntax, at: line.end) }
                w = try _integerValue(text, weightField)
            }
            if v > u {
                mirrors.neighbour.append(v)
                mirrors.weight.append(w)
                mirrors.offset.append(field.0)
                mirrors.order.append(later)
                later &+= 1
                let edge = target.insertEdge(keys[u], keys[v])
                if hasEdgeWeight { buffer.record(edge, 0, .integer(w)) }
            } else if !mirrors.consume(line: v, neighbour: u, weight: w) && unmirrored == nil {
                unmirrored = field.0
            }
        }
        mirrors.endLine()
        u &+= 1
    }
    // After the vertex lines, only blank lines and comments.
    while let line = _line(text, from: start) {
        start = line.next
        if line.end > line.start && text[line.start] == UInt8(ascii: "%") { continue }
        var q = line.start
        while q < line.end && _isBlank(text[q]) { q &+= 1 }
        if q < line.end { throw ParseError(.syntax, at: q) }
    }
    if let offset = unmirrored ?? mirrors.firstUnconsumed() { throw ParseError(.invalidValue, at: offset) }
    if later != m { throw ParseError(.entryCountMismatch, at: edgeCountOffset) }
}

// MARK: - Writing

/// Writes a METIS graph file: each vertex's line lists the far end of each of its edges in
/// position order (a stable counting sort of the edge ends by vertex). Loops and repeated pairs are
/// found first, from the sorted rows.
@inlinable func _writeMETIS<Source: _WriteSource>(
    _ source: Source, to out: inout _OutputBuffer, hasWeight: Bool, weight: (Source.Position) -> Int
) throws(WriteError) {
    let n = source.vertexCount, m = source.edgeCount
    var rowStart = [Int](repeating: 0, count: n &+ 1)
    var ends: [(Int, Int)] = []
    ends.reserveCapacity(m)
    var positions: [Source.Position] = []
    if hasWeight { positions.reserveCapacity(m) }
    var firstLoop = Int.max
    source.forEachEdge { position, u, v in
        if u == v && firstLoop == .max { firstLoop = ends.count }
        ends.append((u, v))
        if hasWeight { positions.append(position) }
        rowStart[u &+ 1] &+= 1
        rowStart[v &+ 1] &+= 1
    }
    for k in 0 ..< n { rowStart[k &+ 1] &+= rowStart[k] }
    // Each row: (far end, edge number).
    var far = [Int](repeating: 0, count: 2 &* ends.count), edge = [Int](repeating: 0, count: 2 &* ends.count)
    var fill = rowStart
    for (e, (u, v)) in ends.enumerated() {
        far[fill[u]] = v
        edge[fill[u]] = e
        fill[u] &+= 1
        far[fill[v]] = u
        edge[fill[v]] = e
        fill[v] &+= 1
    }
    // The first edge that repeats a pair: rows list their edges in position order, so a repeated far
    // end is the later copy. A loop is listed twice on its row and is not a repeat.
    var stamp = [Int](repeating: -1, count: n)
    var firstRepeat = Int.max
    for u in 0 ..< n {
        for k in rowStart[u] ..< rowStart[u &+ 1] where far[k] != u {
            if stamp[far[k]] == u { firstRepeat = min(firstRepeat, edge[k]) }
            stamp[far[k]] = u
        }
    }
    if firstLoop < firstRepeat { throw .selfLoop }
    if firstRepeat < .max { throw .parallelEdge }
    out.appendDecimal(n)
    out.append(0x20)
    out.appendDecimal(ends.count)
    out.appendASCII(hasWeight ? " 1\n" : "\n")
    for u in 0 ..< n {
        var first = true
        for k in rowStart[u] ..< rowStart[u &+ 1] {
            if !first { out.append(0x20) }
            first = false
            out.appendDecimal(far[k] &+ 1)
            if hasWeight {
                out.append(0x20)
                out.appendDecimal(weight(positions[edge[k]]))
            }
        }
        out.append(0x0A)
    }
}
