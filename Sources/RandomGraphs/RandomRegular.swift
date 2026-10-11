import GraphProtocols
import NamedGraphs

/// The pairing procedure of NetworkX's `random_regular_graph(d, n)`, draw for draw: the stubs
/// (every vertex d times, `0..<n` repeated) are shuffled by Fisher–Yates (CPython's `shuffle`:
/// i from the last index down to 1, swapped with `below(i + 1)`) and paired off in order. A pair
/// that is a self-loop or a repeat is not added; both its stubs are kept, by vertex in the order
/// the vertices were first kept, for the next round. A round whose kept stubs can no longer form a
/// new edge restarts the whole attempt. Pairs sorted, smaller end first.
@inlinable
func _randomRegularPairs<G: RandomNumberGenerator>(_ n: Int, _ d: Int, _ g: inout G) -> [DirectedEdge<Int>] {
    _checkCount(n)
    precondition(d >= 0 && d < n, "degree \(d) is not in 0..<\(n)")
    precondition(_productFits(n, d), "edge count overflows Int")
    precondition((n * d).isMultiple(of: 2), "vertexCount × degree \(n * d) is odd")
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
            // Whether a new edge can still be formed from the kept vertices, as NetworkX's
            // `_suitable` decides it, quirk included: its swap of s1 and s2 rebinds s1 for the rest
            // of the inner loop, so after meeting a smaller vertex it walks on from that one.
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
    /// regular graphs", STOC 2003, 213–222); NetworkX cites both papers. nd/2 edges, sorted.
    /// The draws are NetworkX's `random_regular_graph(d, n)` on the same stream. O(nd) expected for
    /// small d; an attempt fails, and starts over, with probability that grows with d, so a d near
    /// n can take many attempts. d = 0 gives no edges and no draws.
    ///
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
    /// `grid` have them: the undirected form's draws and edges, so every vertex has in- and
    /// out-degree d. Arcs in row-major order. O(nd) expected for small d.
    ///
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
