import GraphProtocols

// Complete multipartite and Turán graphs: the parts are consecutive ranges of vertices, in the
// order given, as NetworkX numbers them. The edges are computed as read (`_MultipartitePairs`).

/// The pair collection for parts of the given sizes, after checking the sizes and the counts.
@usableFromInline
func _multipartitePairs(_ sizes: [Int]) -> _MultipartitePairs {
    var ends: [Int] = []
    var n = 0, m = 0
    for size in sizes {
        _checkCount(size, "part size")
        guard size > 0 else { continue }
        // Each vertex of this part meets each of the n before it.
        precondition(_productFits(size, n) && m <= Int.max - size * n, "edge count overflows Int")
        m += size * n
        precondition(n <= Int.max - size, "vertex count overflows Int")
        n += size
        ends.append(n)
    }
    return _MultipartitePairs(ends: ends, count: m)
}

/// The part sizes of the Turán graph T(n, r): r − (n mod r) parts of ⌊n/r⌋, then n mod r parts of
/// ⌊n/r⌋ + 1, as NetworkX's `turan_graph` orders them.
@usableFromInline
func _turanPartSizes(_ n: Int, _ r: Int) -> [Int] {
    precondition(1 <= r && r <= n, "a Turán graph needs 1 ≤ partCount ≤ vertexCount, not \(r) and \(n)")
    let small = n / r, large = n % r
    return [Int](repeating: small, count: r - large) + [Int](repeating: small + 1, count: large)
}

extension _GraphConstruction {
    /// The complete multipartite graph with parts of the given sizes: part i is the next
    /// `partSizes[i]` vertices after the parts before it, and two vertices are adjacent exactly when
    /// they are in different parts (NetworkX `complete_multipartite_graph`, numbered the same way).
    /// Σ sᵢ vertices and Σᵢ<ⱼ sᵢsⱼ edges, sorted. `completeMultipartite(partSizes: [a, b])` is
    /// `completeBipartite(leftCount: a, rightCount: b)`, and n parts of size 1 make Kₙ. No sizes
    /// give the null graph. O(n + m), with no edge list allocated.
    ///
    /// - Precondition: no size is negative, and the counts fit in `Int`.
    @inlinable
    public static func completeMultipartite(partSizes: [Int]) -> Self {
        let pairs = _multipartitePairs(partSizes)
        return Self(_vertexCount: pairs.n, sortedEdges: pairs.lazy.map(_undirected), _ConstructionToken())
    }

    /// The Turán graph T(n, r): the complete multipartite graph on `vertexCount` vertices with
    /// `partCount` parts as equal as possible, the smaller parts first (NetworkX `turan_graph`,
    /// numbered the same way). The graph on n vertices with no K_{r+1} that has the most edges.
    /// O(n + m), with no edge list allocated.
    ///
    /// - Precondition: `1 ≤ partCount ≤ vertexCount`, as NetworkX requires.
    @inlinable
    public static func turan(vertexCount n: Int, partCount r: Int) -> Self {
        completeMultipartite(partSizes: _turanPartSizes(n, r))
    }
}

extension _DirectedGraphConstruction {
    /// The complete multipartite graph with both arcs of every edge: u → v for each u and v in
    /// different parts, Σᵢ≠ⱼ sᵢsⱼ arcs in row-major order (igraph's `Full_Multipartite` with
    /// `mode="all"`, the default). n parts of size 1 give `complete(vertexCount:)`, and two parts
    /// give `completeBipartite(leftCount:rightCount:)`. O(n + m), with no edge list allocated.
    ///
    /// - Precondition: no size is negative, and the counts fit in `Int`.
    @inlinable
    public static func completeMultipartite(partSizes: [Int]) -> Self {
        let arcs = _CrossPartArcs(_multipartitePairs(partSizes))
        return Self(_vertexCount: arcs.n, sortedEdges: arcs, _ConstructionToken())
    }

    /// The Turán graph with both arcs of every edge, as `completeMultipartite(partSizes:)`.
    /// O(n + m).
    ///
    /// - Precondition: `1 ≤ partCount ≤ vertexCount`.
    @inlinable
    public static func turan(vertexCount n: Int, partCount r: Int) -> Self {
        completeMultipartite(partSizes: _turanPartSizes(n, r))
    }
}
