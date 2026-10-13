import GraphProtocols

// Ladders and circular ladders: two paths (or cycles) on `0..<n` and `n..<2n`, and the rungs
// i–(i + n). Each row's edges are written in order, so the list needs no sort.

@usableFromInline
func _ladderPairs(_ n: Int, circular: Bool) -> [DirectedEdge<Int>] {
    if circular {
        precondition(n >= 3, "a circular ladder needs at least 3 rungs, not \(n)")
    } else {
        _checkCount(n, "rungCount")
    }
    // 2n vertices; n − 1 edges per rail (n when circular) and n rungs.
    precondition(n <= Int.max / 3, "count overflows Int")
    guard n >= 1 else { return [] }
    var pairs: [DirectedEdge<Int>] = []
    pairs.reserveCapacity(circular ? 3 * n : 3 * n - 2)
    for rail in 0 ..< 2 {
        let first = rail * n, last = first + n - 1
        for i in first ... last {
            if i < last { pairs.append(DirectedEdge(from: i, to: i + 1)) }
            // The rail's closing edge sorts second in its first row.
            if circular, i == first { pairs.append(DirectedEdge(from: first, to: last)) }
            if rail == 0 { pairs.append(DirectedEdge(from: i, to: i + n)) }
        }
    }
    return pairs
}

extension _GraphConstruction {
    /// The ladder graph L_n with `rungCount` rungs: the paths 0–1–…–(n − 1) and n–(n + 1)–…–(2n − 1),
    /// and the rungs i–(i + n). 2n vertices and
    /// 3n − 2 edges (none when n = 0), sorted. `ladder(rungCount: 1)` is K₂. O(n).
    ///
    /// - Precondition: `rungCount ≥ 0`, and 2n fits in `Int`.
    @inlinable
    public static func ladder(rungCount n: Int) -> Self {
        let pairs = _ladderPairs(n, circular: false)
        return Self(_vertexCount: 2 * n, sortedEdges: pairs.lazy.map(_undirected), _ConstructionToken())
    }

    /// The circular ladder graph CL_n (the n-prism) with `rungCount` rungs: the cycles
    /// 0–1–…–(n − 1)–0 and n–(n + 1)–…–(2n − 1)–n, and the rungs i–(i + n). 2n vertices, 3n
    /// edges, sorted. O(n).
    ///
    /// - Precondition: `rungCount ≥ 3`, so that each rail is a cycle, as for `cycle(vertexCount:)`.
    @inlinable
    public static func circularLadder(rungCount n: Int) -> Self {
        let pairs = _ladderPairs(n, circular: true)
        return Self(_vertexCount: 2 * n, sortedEdges: pairs.lazy.map(_undirected), _ConstructionToken())
    }
}

extension _DirectedGraphConstruction {
    /// The ladder with both arcs for every edge, in row-major order; numbering as the undirected
    /// `ladder(rungCount:)`. O(n).
    ///
    /// - Precondition: `rungCount ≥ 0`, and 2n fits in `Int`.
    @inlinable
    public static func ladder(rungCount n: Int) -> Self {
        let pairs = _ladderPairs(n, circular: false)
        return Self(_vertexCount: 2 * n, sortedEdges: _bothArcs(vertexCount: 2 * n, pairs), _ConstructionToken())
    }

    /// The circular ladder with both arcs for every edge, in row-major order. O(n).
    ///
    /// - Precondition: `rungCount ≥ 3`.
    @inlinable
    public static func circularLadder(rungCount n: Int) -> Self {
        let pairs = _ladderPairs(n, circular: true)
        return Self(_vertexCount: 2 * n, sortedEdges: _bothArcs(vertexCount: 2 * n, pairs), _ConstructionToken())
    }
}
