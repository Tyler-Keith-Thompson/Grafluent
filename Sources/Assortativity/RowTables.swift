import GraphProtocols

// The unweighted measures read rows where the representation stores them: an undirected graph's
// lent incidence rows, a directed graph's pooled out-rows or its compressed sparse rows. Each row
// is a block of one flat target buffer, found through a row table; a copy into compressed rows
// serves the representations that lend nothing. The kernels walk each block with one cursor.

/// Where vertex `v`'s row lies in a flat target buffer.
@usableFromInline
protocol _RowTable {
    func start(_ v: Int) -> Int
    func end(_ v: Int) -> Int
}

/// A pooled row table: three entries per vertex, its row's start and length (and one unused).
@frozen
@usableFromInline
struct _PooledRowTable: _RowTable {
    @usableFromInline let table: UnsafeBufferPointer<Int>

    @inlinable
    init(_ table: UnsafeBufferPointer<Int>) { self.table = table }

    @inlinable @inline(__always)
    func start(_ v: Int) -> Int { table[3 &* v] }

    @inlinable @inline(__always)
    func end(_ v: Int) -> Int { table[3 &* v] &+ table[3 &* v &+ 1] }
}

/// Compressed sparse row offsets: row `v` is `offsets[v] ..< offsets[v + 1]`.
@frozen
@usableFromInline
struct _OffsetRowTable: _RowTable {
    @usableFromInline let offsets: UnsafeBufferPointer<Int>

    @inlinable
    init(_ offsets: UnsafeBufferPointer<Int>) { self.offsets = offsets }

    @inlinable @inline(__always)
    func start(_ v: Int) -> Int { offsets[v] }

    @inlinable @inline(__always)
    func end(_ v: Int) -> Int { offsets[v &+ 1] }
}

/// A computation over flat rows on `0..<n`, whose tables have been checked to lie in bounds; the
/// targets are not checked yet.
@usableFromInline
protocol _FlatRowsBody {
    associatedtype Output
    func run<T: _RowTable>(_ targets: UnsafeBufferPointer<Int>, _ rows: T, _ n: Int) -> Output
}

/// Runs `body` over undirected incidence rows as `_UndirectedRowsAlgorithm` hands them over: the
/// lent rows themselves, or a copy of the others.
@inlinable
func _runOnIncidenceRows<Rows: _IncidenceRowSource, B: _FlatRowsBody>(_ body: B, count n: Int, edgeCount: Int, _ rows: inout Rows) -> B.Output {
    if let lent = rows as? _IncidenceRows { return body.run(lent.neighbors, _PooledRowTable(lent.neighborRows), n) }
    let copied = _CopyRows(readsEdges: false, dropsLoops: false).run(count: n, edgeCount: edgeCount, &rows)
    return copied.offsets.withUnsafeBufferPointer { offsets in
        copied.targets.withUnsafeBufferPointer { targets in body.run(targets, _OffsetRowTable(offsets), n) }
    }
}

/// An undirected graph's rows handed to a flat-rows body.
@frozen
@usableFromInline
struct _IncidenceRowsAlgorithm<B: _FlatRowsBody>: _UndirectedRowsAlgorithm {
    @usableFromInline let body: B

    @inlinable
    init(_ body: B) { self.body = body }

    @inlinable
    var readsEdges: Bool { false }

    @inlinable
    func run<Rows: _IncidenceRowSource>(count n: Int, edgeCount: Int, _ rows: inout Rows) -> B.Output {
        _runOnIncidenceRows(body, count: n, edgeCount: edgeCount, &rows)
    }
}

extension DirectedGraph {
    /// Runs `body` over the out-rows, every arc kept: the pooled rows or the compressed sparse rows
    /// the representation stores, with their tables checked, or else a copy. Also the vertex
    /// numbers when the graph has no vertex indices.
    @inlinable
    func _runOnArcRows<B: _FlatRowsBody>(_ body: B) -> (output: B.Output, numbers: [Vertex: Int]?) {
        if let n = vertexIndexBound {
            if let output = _withCheckedOutIndexRows({ targets, targetRows, _, _ in body.run(targets, _PooledRowTable(targetRows), n) }) {
                return (output, nil)
            }
            if let output = _withSuccessorIndexRows({ offsets, targets -> B.Output in
                precondition(offsets.count == n + 1 && (n == 0 || offsets[0] >= 0) && offsets[n] <= targets.count, "The successor row offsets are out of bounds")
                for v in 0 ..< n { precondition(offsets[v] <= offsets[v + 1], "The successor row offsets are out of order") }
                return body.run(targets, _OffsetRowTable(offsets), n)
            }) {
                return (output, nil)
            }
        }
        let copied = _compressedRows(readsEdges: false, dropsLoops: false)
        let output = copied.rows.offsets.withUnsafeBufferPointer { offsets in
            copied.rows.targets.withUnsafeBufferPointer { targets in body.run(targets, _OffsetRowTable(offsets), copied.rows.count) }
        }
        return (output, copied.numbering?.numbers)
    }
}

/// Every vertex's in-degree: its count among the targets, which are checked as they are read.
@inlinable
func _flatInDegrees<T: _RowTable>(_ targets: UnsafeBufferPointer<Int>, _ rows: T, _ n: Int) -> [Int] {
    var degree = [Int](repeating: 0, count: n)
    degree.withUnsafeMutableBufferPointer { degree in
        for v in 0 ..< n {
            for slot in rows.start(v) ..< rows.end(v) {
                let w = targets[slot]
                precondition(UInt(bitPattern: w) < UInt(bitPattern: n), "A successor index is out of range")
                degree[w] &+= 1
            }
        }
    }
    return degree
}

/// Pearson's r of the pairs (x[v], y[w]), one per target w in row v: nil with no pairs or a
/// constant x or y over them. `heads` counts each vertex's appearances among the targets, so the
/// heads' sums take O(n); nil for an undirected graph's rows, whose heads are its tails (and y is
/// x). One pass over the targets, which are checked as they are read.
@inlinable
func _flatPearson<T: _RowTable>(_ targets: UnsafeBufferPointer<Int>, _ rows: T, _ n: Int, _ x: [Double], _ y: [Double], heads: [Int]?) -> Double? {
    x.withUnsafeBufferPointer { x in
        y.withUnsafeBufferPointer { y -> Double? in
            var m = 0, sumX = 0.0, sumY = 0.0
            var leastX = Double.infinity, greatestX = -Double.infinity
            var leastY = Double.infinity, greatestY = -Double.infinity
            for v in 0 ..< n {
                let count = rows.end(v) &- rows.start(v)
                guard count > 0 else { continue }
                m &+= count
                let value = x[v]
                sumX += Double(count) * value
                if value < leastX { leastX = value }
                if value > greatestX { greatestX = value }
            }
            if let heads {
                for w in 0 ..< n {
                    let count = heads[w]
                    guard count > 0 else { continue }
                    let value = y[w]
                    sumY += Double(count) * value
                    if value < leastY { leastY = value }
                    if value > greatestY { greatestY = value }
                }
            } else {
                (sumY, leastY, greatestY) = (sumX, leastX, greatestX)
            }
            guard m > 0, leastX < greatestX, leastY < greatestY else { return nil }
            let meanX = sumX / Double(m), meanY = sumY / Double(m)
            var cross = 0.0, squaresX = 0.0, squaresY = 0.0
            for v in 0 ..< n {
                let start = rows.start(v), end = rows.end(v)
                guard start < end else { continue }
                var row = 0.0
                for slot in start ..< end {
                    let w = targets[slot]
                    precondition(UInt(bitPattern: w) < UInt(bitPattern: n), "A target index is out of range")
                    row += y[w] - meanY
                }
                let dx = x[v] - meanX
                cross += dx * row
                squaresX += Double(end &- start) * dx * dx
            }
            guard let heads else { return min(1, max(-1, cross / squaresX)) }
            for w in 0 ..< n {
                let dy = y[w] - meanY
                squaresY += Double(heads[w]) * dy * dy
            }
            return min(1, max(-1, cross / (squaresX.squareRoot() * squaresY.squareRoot())))
        }
    }
}

/// Degree assortativity over flat rows: the `source` degree of each row's vertex against the
/// `target` degree of each of its targets; `symmetric` for an undirected graph's rows, whose
/// degrees are the row lengths.
@frozen
@usableFromInline
struct _DegreePearson: _FlatRowsBody {
    @usableFromInline let source: DegreeType
    @usableFromInline let target: DegreeType
    @usableFromInline let symmetric: Bool

    @inlinable
    init(source: DegreeType, target: DegreeType, symmetric: Bool) {
        self.source = source
        self.target = target
        self.symmetric = symmetric
    }

    @inlinable
    func run<T: _RowTable>(_ targets: UnsafeBufferPointer<Int>, _ rows: T, _ n: Int) -> Double? {
        let outs = (0 ..< n).map { Double(rows.end($0) &- rows.start($0)) }
        if symmetric { return _flatPearson(targets, rows, n, outs, outs, heads: nil) }
        let ins = _flatInDegrees(targets, rows, n)
        func degrees(_ type: DegreeType) -> [Double] {
            switch type {
            case .out: outs
            case .in: ins.map { Double($0) }
            case .total: (0 ..< n).map { outs[$0] + Double(ins[$0]) }
            }
        }
        let x = degrees(source)
        return _flatPearson(targets, rows, n, x, source == target ? x : degrees(target), heads: ins)
    }
}

/// Numeric assortativity over flat rows: the values at each row's vertex and at its targets;
/// `symmetric` for an undirected graph's rows.
@frozen
@usableFromInline
struct _ValuePearson: _FlatRowsBody {
    @usableFromInline let values: [Double]
    @usableFromInline let symmetric: Bool

    @inlinable
    init(_ values: [Double], symmetric: Bool) {
        self.values = values
        self.symmetric = symmetric
    }

    @inlinable
    func run<T: _RowTable>(_ targets: UnsafeBufferPointer<Int>, _ rows: T, _ n: Int) -> Double? {
        _flatPearson(targets, rows, n, values, values, heads: symmetric ? nil : _flatInDegrees(targets, rows, n))
    }
}

/// Each vertex's sum of `k` over the arcs `source` names (its row, the rows naming it, or both)
/// and how many arcs that is; for an undirected graph's rows, `.out` with `k` the row lengths.
@frozen
@usableFromInline
struct _DegreeSums: _FlatRowsBody {
    @usableFromInline let source: DegreeType
    @usableFromInline let target: DegreeType
    /// An undirected graph's rows: the target degree is the row length.
    @usableFromInline let undirected: Bool

    @inlinable
    init(source: DegreeType, target: DegreeType, undirected: Bool) {
        self.source = source
        self.target = target
        self.undirected = undirected
    }

    @inlinable
    func run<T: _RowTable>(_ targets: UnsafeBufferPointer<Int>, _ rows: T, _ n: Int) -> (sums: [Int], counts: [Int]) {
        let outs = (0 ..< n).map { rows.end($0) &- rows.start($0) }
        let ins = undirected || (source == .out && target == .out) ? [] : _flatInDegrees(targets, rows, n)
        let k: [Int]
        switch target {
        case _ where undirected, .out: k = outs
        case .in: k = ins
        case .total: k = zip(outs, ins).map { $0 &+ $1 }
        }
        var sums = [Int](repeating: 0, count: n)
        let outgoing = undirected || source != .in, incoming = !undirected && source != .out
        k.withUnsafeBufferPointer { k in
            sums.withUnsafeMutableBufferPointer { sums in
                for v in 0 ..< n {
                    var sum = 0
                    let kv = k[v]
                    for slot in rows.start(v) ..< rows.end(v) {
                        let w = targets[slot]
                        precondition(UInt(bitPattern: w) < UInt(bitPattern: n), "A target index is out of range")
                        if outgoing { sum &+= k[w] }
                        if incoming { sums[w] &+= kv }
                    }
                    sums[v] &+= sum
                }
            }
        }
        let counts: [Int]
        switch source {
        case _ where undirected, .out: counts = outs
        case .in: counts = ins
        case .total: counts = zip(outs, ins).map { $0 &+ $1 }
        }
        return (sums, counts)
    }
}

/// The averages: each sum over its count, 0 where the count is 0.
@inlinable
func _averages(_ sums: (sums: [Int], counts: [Int])) -> [Double] {
    zip(sums.sums, sums.counts).map { $1 == 0 ? 0 : Double($0) / Double($1) }
}

/// k_nn(k) from integer sums: for each count k that occurs, the summed sums over the summed
/// counts, 0 for k = 0.
@inlinable
func _connectivity(_ sums: (sums: [Int], counts: [Int])) -> [Int: Double] {
    var total: [Int: Int] = [:], norm: [Int: Int] = [:]
    for v in sums.sums.indices {
        total[sums.counts[v], default: 0] &+= sums.sums[v]
        norm[sums.counts[v], default: 0] &+= sums.counts[v]
    }
    var result: [Int: Double] = [:]
    result.reserveCapacity(total.count)
    for (k, sum) in total {
        let z = norm[k]!
        result[k] = z == 0 ? Double(sum) : Double(sum) / Double(z)
    }
    return result
}
