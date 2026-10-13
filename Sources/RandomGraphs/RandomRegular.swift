import GraphProtocols
import NamedGraphs

/// The pairing procedure. The stubs (every vertex d times, `0..<n` repeated) are shuffled by
/// Fisher–Yates (i from the last index down to 1, swapped with `below(i + 1)`) and paired off in
/// order. A pair
/// that is a self-loop or a repeat is not added; both its stubs are kept, by vertex in the order
/// the vertices were first kept, for the next round. A round whose kept stubs can no longer form a
/// new edge restarts the whole attempt. For d > (n − 1) / 2 the procedure runs for n − 1 − d and the
/// complement is returned. Pairs sorted, smaller end first.
@inlinable
func _randomRegularPairs<G: RandomNumberGenerator>(_ n: Int, _ d: Int, _ g: inout G) -> [DirectedEdge<Int>] {
    _checkCount(n)
    precondition(d >= 0 && d < n, "degree \(d) is not in 0..<\(n)")
    precondition(_productFits(n, d), "edge count overflows Int")
    precondition((n * d).isMultiple(of: 2), "vertexCount × degree \(n * d) is odd")
    // n(n − 1) is even, so n(n − 1 − d) is even whenever nd is.
    if d > (n - 1) / 2 { return _complementPairs(n, n * d / 2, _randomRegularPairs(n, n - 1 - d, &g)) }
    if d == 0 { return [] }
    let m = n * d / 2
    var edges: [DirectedEdge<Int>] = []
    edges.reserveCapacity(m)
    var stubs: [Int] = []
    stubs.reserveCapacity(n * d)
    // `kept[v]` stubs of v go to the next round; `order` lists those vertices by first kept stub.
    var kept = [Int](repeating: 0, count: n)
    var order: [Int] = []
    while true {
        var chosen = _PairSet(capacity: m)
        edges.removeAll(keepingCapacity: true)
        stubs.removeAll(keepingCapacity: true)
        for _ in 0 ..< d { stubs.append(contentsOf: 0 ..< n) }
        var failed = false
        while !stubs.isEmpty {
            stubs.withUnsafeMutableBufferPointer { stubs in
                var i = stubs.count - 1
                while i >= 1 {
                    stubs.swapAt(i, _below(i + 1, &g))
                    i -= 1
                }
            }
            order.removeAll(keepingCapacity: true)
            var k = 0
            while k + 1 < stubs.count {
                let a = stubs[k], b = stubs[k + 1]
                let (u, v) = a < b ? (a, b) : (b, a)
                if u != v, chosen.insert(u, v) {
                    edges.append(DirectedEdge(from: u, to: v))
                } else {
                    if kept[u] == 0 { order.append(u) }
                    kept[u] += 1
                    if kept[v] == 0 { order.append(v) }
                    kept[v] += 1
                }
                k += 2
            }
            // Whether a new edge can still be formed from the kept vertices. After meeting a smaller
            // vertex, s1 walks on from that one for the rest of the inner loop; the catalog pins
            // this check draw for draw, so it stays as is.
            var suitable = order.isEmpty
            search: for x in order {
                var s1 = x
                for y in order {
                    if s1 == y { break }
                    let (a, b) = s1 < y ? (s1, y) : (y, s1)
                    s1 = a
                    if !chosen.contains(a, b) {
                        suitable = true
                        break search
                    }
                }
            }
            stubs.removeAll(keepingCapacity: true)
            for v in order {
                stubs.append(contentsOf: repeatElement(v, count: kept[v]))
                kept[v] = 0
            }
            if !suitable {
                failed = true
                break
            }
        }
        if !failed { break }
    }
    return _sortedRowMajor(n, edges)
}

/// The pairs u < v on `0..<n` that are not in `pairs`, in lexicographic order; `pairs` is sorted the
/// same way and `count` is the complement's size.
@inlinable
func _complementPairs(_ n: Int, _ count: Int, _ pairs: [DirectedEdge<Int>]) -> [DirectedEdge<Int>] {
    var complement: [DirectedEdge<Int>] = []
    complement.reserveCapacity(count)
    var k = 0
    var next = pairs.first
    for u in 0 ..< n {
        var v = u + 1
        while v < n {
            if let pair = next, pair.source == u, pair.target == v {
                k += 1
                next = k < pairs.count ? pairs[k] : nil
            } else {
                complement.append(DirectedEdge(from: u, to: v))
            }
            v += 1
        }
    }
    return complement
}

extension _GraphConstruction {
    /// A random d-regular graph on `0..<vertexCount`: every vertex has degree d, by the pairing
    /// (configuration) model with Steger and Wormald's repair, which pairs the remaining stubs
    /// again instead of rejecting the whole pairing at the first collision:
    ///
    /// > Angelika Steger and Nicholas C. Wormald. Generating random regular graphs quickly.
    /// > *Combinatorics, Probability and Computing* 8(4), 377–396 (1999).
    /// > doi:10.1017/S0963548399003867
    ///
    /// Kim and Vu showed the result asymptotically uniform for d = o(n^(1/28)) ("Generating random
    /// regular graphs", STOC 2003, 213–222). The result has nd/2 edges. For d > (n − 1) / 2 it is
    /// the complement of the random (n − 1 − d)-regular graph this procedure draws, since
    /// complementing maps the d-regular graphs on `0..<vertexCount` one to one onto the
    /// (n − 1 − d)-regular ones. d = 0 gives no edges and d = n − 1 the complete graph, both with
    /// no draws.
    ///
    /// - Complexity: O(n·min(d, n − 1 − d)) expected for d or n − 1 − d small, plus O(n²) for the
    ///   complement when d > (n − 1) / 2.
    /// - Precondition: `degree` in `0..<vertexCount`, and n·d even.
    @inlinable
    public static func randomRegular(vertexCount n: Int, degree d: Int, using generator: inout some RandomNumberGenerator) -> Self {
        Self(_vertexCount: n, sortedEdges: _randomRegularPairs(n, d, &generator).lazy.map(_undirected), _ConstructionToken())
    }

    /// `randomRegular(vertexCount:degree:using:)` with the system's random number generator.
    @inlinable
    public static func randomRegular(vertexCount n: Int, degree d: Int) -> Self {
        var generator = SystemRandomNumberGenerator()
        return randomRegular(vertexCount: n, degree: d, using: &generator)
    }
}

extension _DirectedGraphConstruction {
    /// The random d-regular graph with both arcs for every edge, as the directed `complete` and
    /// `grid` have them. It makes the undirected form's draws, and every vertex has in- and
    /// out-degree d.
    ///
    /// - Complexity: O(n·min(d, n − 1 − d)) expected for d or n − 1 − d small, plus O(n²) for the
    ///   complement when d > (n − 1) / 2.
    /// - Precondition: `degree` in `0..<vertexCount`, and n·d even.
    @inlinable
    public static func randomRegular(vertexCount n: Int, degree d: Int, using generator: inout some RandomNumberGenerator) -> Self {
        Self(_vertexCount: n, sortedEdges: _bothArcs(n, _randomRegularPairs(n, d, &generator)), _ConstructionToken())
    }

    /// `randomRegular(vertexCount:degree:using:)` with the system's random number generator.
    @inlinable
    public static func randomRegular(vertexCount n: Int, degree d: Int) -> Self {
        var generator = SystemRandomNumberGenerator()
        return randomRegular(vertexCount: n, degree: d, using: &generator)
    }
}
