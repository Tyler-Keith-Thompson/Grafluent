import GraphProtocols

/// The simple graph underlying an undirected graph with its edges numbered: each vertex's distinct
/// other neighbors in ascending order (a transpose of the deduplicated rows), each slot's simple edge (numbered by its lesser end, then
/// its greater one), each simple edge's ends (lesser first, two entries per edge), and each edge
/// number's simple edge (−1 for a self-loop).
@frozen
@usableFromInline
struct _SimpleEdgeRows: _UndirectedRowsAlgorithm {
    @inlinable
    init() {}

    @inlinable
    func run<Rows: _IncidenceRowSource>(count n: Int, edgeCount: Int, _ rows: inout Rows) -> (rows: _CompressedRows, ends: [Int], simpleEdge: [Int]) {
        var offsets = [Int](repeating: 0, count: n + 1)
        var targets: [Int] = []
        targets.reserveCapacity(2 * edgeCount)
        var stamp = [Int](repeating: -1, count: n)
        for v in 0 ..< n {
            for k in 0 ..< rows.count(v) {
                let w = rows.neighbor(v, k)
                precondition(UInt(bitPattern: w) < UInt(bitPattern: n), "A neighbor index is out of range")
                if w == v || stamp[w] == v { continue }
                stamp[w] = v
                targets.append(w)
            }
            offsets[v + 1] = targets.count
        }
        // The simple graph is symmetric, so listing each v in the rows of its neighbors, v
        // ascending, sorts every row without a comparison.
        var fill = Array(offsets.dropLast())
        var sorted = [Int](repeating: 0, count: targets.count)
        for v in 0 ..< n {
            for k in offsets[v] ..< offsets[v + 1] {
                let w = targets[k]
                sorted[fill[w]] = v
                fill[w] += 1
            }
        }
        targets = sorted
        var slotEdge = [Int](repeating: 0, count: targets.count)
        var ends: [Int] = []
        ends.reserveCapacity(targets.count)
        for v in 0 ..< n {
            for s in offsets[v] ..< offsets[v + 1] {
                let w = targets[s]
                if w > v {
                    slotEdge[s] = ends.count >> 1
                    ends.append(v)
                    ends.append(w)
                } else {
                    slotEdge[s] = slotEdge[_slot(of: v, inRowOf: w, offsets, targets)]
                }
            }
        }
        var simpleEdge = [Int](repeating: -1, count: edgeCount)
        for v in 0 ..< n {
            for k in 0 ..< rows.count(v) {
                let w = rows.neighbor(v, k)
                guard w > v else { continue }
                let e = rows.edge(v, k)
                precondition(UInt(bitPattern: e) < UInt(bitPattern: edgeCount), "An edge index is out of range")
                simpleEdge[e] = slotEdge[_slot(of: w, inRowOf: v, offsets, targets)]
            }
        }
        return (_CompressedRows(offsets: offsets, targets: targets, edges: slotEdge), ends, simpleEdge)
    }
}

/// The slot of `w` in `v`'s ascending row, or −1 when they are not adjacent. O(log deg v).
@inlinable @inline(__always)
func _slot(of w: Int, inRowOf v: Int, _ offsets: [Int], _ targets: [Int]) -> Int {
    var low = offsets[v], high = offsets[v + 1]
    while low < high {
        let mid = (low + high) >> 1
        if targets[mid] < w { low = mid + 1 } else { high = mid }
    }
    return low < offsets[v + 1] && targets[low] == w ? low : -1
}

/// Wang–Cheng's truss decomposition of a simple graph given by `_SimpleEdgeRows`: each simple
/// edge's truss number. Supports (triangles per edge) come from Latapy's compact-forward listing;
/// edges are then peeled in a bucket order by support, each removal lowering the support of the
/// two other edges of every triangle it still closes, found from the end of lesser degree by a
/// binary search in the other end's row. O(m^1.5 log Δ).
@inlinable
func _trussNumbers(_ rows: _CompressedRows, ends: [Int]) -> [Int] {
    let n = rows.count, m = ends.count >> 1
    guard m > 0 else { return [] }
    // Forward rows by (degree, index), with each slot's edge.
    // Ranks by (degree, index): a stable counting sort.
    let maxDegree = (0 ..< n).map { rows.degree($0) }.max()!
    var start = [Int](repeating: 0, count: maxDegree + 2)
    for v in 0 ..< n { start[rows.degree(v) + 1] += 1 }
    for d in 0 ... maxDegree { start[d + 1] += start[d] }
    var rank = [Int](repeating: 0, count: n)
    for v in 0 ..< n {
        rank[v] = start[rows.degree(v)]
        start[rows.degree(v)] += 1
    }
    var forwardOffsets = [Int](repeating: 0, count: n + 1)
    var forward: [Int] = [], forwardEdge: [Int] = []
    forward.reserveCapacity(m)
    forwardEdge.reserveCapacity(m)
    for v in 0 ..< n {
        for k in rows.offsets[v] ..< rows.offsets[v + 1] where rank[rows.targets[k]] > rank[v] {
            forward.append(rows.targets[k])
            forwardEdge.append(rows.edges[k])
        }
        forwardOffsets[v + 1] = forward.count
    }
    var support = [Int](repeating: 0, count: m)
    var mark = [Int](repeating: -1, count: n), markEdge = [Int](repeating: 0, count: n)
    for v in 0 ..< n {
        for k in forwardOffsets[v] ..< forwardOffsets[v + 1] {
            mark[forward[k]] = v
            markEdge[forward[k]] = forwardEdge[k]
        }
        for k in forwardOffsets[v] ..< forwardOffsets[v + 1] {
            let w = forward[k], vw = forwardEdge[k]
            for j in forwardOffsets[w] ..< forwardOffsets[w + 1] where mark[forward[j]] == v {
                support[vw] += 1
                support[forwardEdge[j]] += 1
                support[markEdge[forward[j]]] += 1
            }
        }
    }
    // Bucket the edges by support, as Batagelj–Zaversnik buckets vertices by degree.
    let maxSupport = support.max()!
    var bin = [Int](repeating: 0, count: maxSupport + 1)
    for s in support { bin[s] += 1 }
    var first = 0
    for s in 0 ... maxSupport {
        let count = bin[s]
        bin[s] = first
        first += count
    }
    var sorted = [Int](repeating: 0, count: m), pos = [Int](repeating: 0, count: m)
    var fill = bin
    for e in 0 ..< m {
        pos[e] = fill[support[e]]
        sorted[pos[e]] = e
        fill[support[e]] += 1
    }
    var removed = [Bool](repeating: false, count: m)
    var truss = [Int](repeating: 0, count: m)
    for i in 0 ..< m {
        let e = sorted[i]
        let s = support[e]
        truss[e] = s + 2
        removed[e] = true
        var a = ends[2 * e], b = ends[2 * e + 1]
        if rows.degree(a) > rows.degree(b) { swap(&a, &b) }
        for k in rows.offsets[a] ..< rows.offsets[a + 1] {
            let w = rows.targets[k]
            let aw = rows.edges[k]
            guard w != b, !removed[aw] else { continue }
            let slot = _slot(of: w, inRowOf: b, rows.offsets, rows.targets)
            guard slot >= 0 else { continue }
            let bw = rows.edges[slot]
            guard !removed[bw] else { continue }
            for side in 0 ..< 2 {
                let f = side == 0 ? aw : bw
                guard support[f] > s else { continue }
                // Move f to the front of its bucket, then shrink the bucket past it.
                let sf = support[f], pf = pos[f]
                let pg = bin[sf], g = sorted[pg]
                if f != g {
                    pos[f] = pg
                    sorted[pf] = g
                    pos[g] = pf
                    sorted[pg] = f
                }
                bin[sf] += 1
                support[f] -= 1
            }
        }
    }
    return truss
}

/// The truss decomposition of an undirected graph (Cohen; Wang–Cheng), over its simple graph. An
/// edge's truss number is the largest k such that it lies in a subgraph where every edge is in at
/// least k − 2 triangles: 2 for an edge in no triangle, k for an edge of a k-clique. Parallel
/// edges share their simple edge's number, and a self-loop has none.
@frozen
public struct TrussNumbers<G: Graph> {
    /// Every edge position, in `edges` order.
    @usableFromInline let _positions: [G.Edges.Index]
    /// Whether the positions are the integers `0..<m`, each its own edge number.
    @usableFromInline let _isIdentity: Bool
    /// Each edge's truss number by edge number, 0 for a self-loop.
    @usableFromInline let _truss: [Int]

    @inlinable
    init(_ graph: G) {
        let positions = Array(graph.edges.indices)
        _positions = positions
        if G.Edges.Index.self == Int.self, let first = positions.first {
            _isIdentity = unsafeBitCast(first, to: Int.self) == 0 && unsafeBitCast(positions[positions.count - 1], to: Int.self) == positions.count - 1
        } else {
            _isIdentity = G.Edges.Index.self == Int.self
        }
        let (rows, ends, simpleEdge) = graph._runOnUndirectedRows(_SimpleEdgeRows())
        let simple = _trussNumbers(rows, ends: ends)
        _truss = simpleEdge.map { $0 < 0 ? 0 : simple[$0] }
    }

    /// The edge number of `position`, or nil when it is not an edge position.
    @inlinable
    func _number(of position: G.Edges.Index) -> Int? {
        if _isIdentity {
            let e = unsafeBitCast(position, to: Int.self)
            return e >= 0 && e < _truss.count ? e : nil
        }
        var low = 0, high = _positions.count
        while low < high {
            let mid = (low + high) >> 1
            if _positions[mid] < position { low = mid + 1 } else { high = mid }
        }
        return low < _positions.count && _positions[low] == position ? low : nil
    }

    /// The truss number of the edge at `position`, or nil for a self-loop. O(1) when the positions
    /// are `0..<m`, O(log m) otherwise.
    ///
    /// - Precondition: `position` is an edge position of the graph.
    @inlinable
    public func trussNumber(ofEdgeAt position: G.Edges.Index) -> Int? {
        guard let e = _number(of: position) else { preconditionFailure("\(position) is not an edge position of the graph") }
        return _truss[e] == 0 ? nil : _truss[e]
    }

    /// The truss number of the edge at `position`, or nil for a self-loop, throwing instead of
    /// trapping when `position` is not an edge position of the graph.
    ///
    /// - Throws: `EdgeNotFound` when `position` is not a position in the graph's `edges`.
    @inlinable
    public func trussNumber(checkedEdgeAt position: G.Edges.Index) throws(EdgeNotFound) -> Int? {
        guard let e = _number(of: position) else { throw EdgeNotFound() }
        return _truss[e] == 0 ? nil : _truss[e]
    }

    /// The edges of the k-truss (truss number at least k), in `edges` order; every edge but the
    /// self-loops when k ≤ 2. O(m).
    ///
    /// - Precondition: `k >= 0`.
    @inlinable
    public func kTruss(_ k: Int) -> [G.Edges.Index] {
        precondition(k >= 0, "k must be nonnegative")
        let least = max(k, 2)
        return _truss.indices.filter { _truss[$0] >= least }.map { _positions[$0] }
    }
}

extension TrussNumbers: Sendable where G.Edges.Index: Sendable {}

extension Graph {
    /// The truss decomposition of the simple graph underlying this one (self-loops in no truss,
    /// parallel edges sharing one number), by Wang–Cheng's peeling. O(m^1.5 log Δ) time, O(n + m)
    /// memory.
    @inlinable
    public func trussNumbers() -> TrussNumbers<Self> { TrussNumbers(self) }
}
