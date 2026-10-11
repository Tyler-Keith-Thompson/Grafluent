import GraphProtocols
import Trees

// Paths, cycles, stars and wheels. Each edge list is built by a non-generic function, once, as
// pairs smaller end first (undirected) or source first (directed), already sorted; only the final
// bulk initializer is specialized per representation.

@usableFromInline
func _pathPairs(_ n: Int) -> [DirectedEdge<Int>] {
    _checkCount(n)
    guard n >= 2 else { return [] }
    return (0 ..< n - 1).map { DirectedEdge(from: $0, to: $0 + 1) }
}

@usableFromInline
func _cyclePairs(_ n: Int, directed: Bool) -> [DirectedEdge<Int>] {
    precondition(n >= 3, "a cycle needs at least 3 vertices, not \(n)")
    var pairs: [DirectedEdge<Int>] = []
    pairs.reserveCapacity(n)
    if directed {
        // i → i + 1, and the closing arc n − 1 → 0 last, in row n − 1.
        for i in 0 ..< n - 1 { pairs.append(DirectedEdge(from: i, to: i + 1)) }
        pairs.append(DirectedEdge(from: n - 1, to: 0))
    } else {
        // The closing edge 0–(n − 1) sorts second, in row 0.
        pairs.append(DirectedEdge(from: 0, to: 1))
        pairs.append(DirectedEdge(from: 0, to: n - 1))
        for i in 1 ..< n - 1 { pairs.append(DirectedEdge(from: i, to: i + 1)) }
    }
    return pairs
}

@usableFromInline
func _starPairs(_ n: Int) -> [DirectedEdge<Int>] {
    precondition(n >= 1, "a star needs its hub: vertexCount \(n) < 1")
    return (1 ..< n).map { DirectedEdge(from: 0, to: $0) }
}

@usableFromInline
func _wheelPairs(_ n: Int, directed: Bool) -> [DirectedEdge<Int>] {
    precondition(n >= 4, "a wheel needs a hub and a rim of at least 3: vertexCount \(n) < 4")
    precondition(n - 1 <= Int.max / 2, "edge count overflows Int")
    var pairs: [DirectedEdge<Int>] = []
    pairs.reserveCapacity(2 * (n - 1))
    for i in 1 ..< n { pairs.append(DirectedEdge(from: 0, to: i)) }
    if directed {
        // Rim i → i + 1, and the closing arc n − 1 → 1 in the last row.
        for i in 1 ..< n - 1 { pairs.append(DirectedEdge(from: i, to: i + 1)) }
        pairs.append(DirectedEdge(from: n - 1, to: 1))
    } else {
        // The rim's closing edge 1–(n − 1) sorts second in row 1.
        pairs.append(DirectedEdge(from: 1, to: 2))
        pairs.append(DirectedEdge(from: 1, to: n - 1))
        for i in 2 ..< n - 1 { pairs.append(DirectedEdge(from: i, to: i + 1)) }
    }
    return pairs
}

extension _GraphConstruction {
    /// The path Pₙ on `0..<vertexCount`: edges i–(i + 1), in order (NetworkX `path_graph`).
    /// max(n − 1, 0) edges. O(n). As a `Tree`, `Tree.path(vertexCount:)`.
    ///
    /// - Precondition: `vertexCount ≥ 0`.
    @inlinable
    public static func path(vertexCount n: Int) -> Self {
        Self(_vertexCount: n, sortedEdges: _pathPairs(n).lazy.map(_undirected), _ConstructionToken())
    }

    /// The cycle Cₙ on `0..<vertexCount`: edges i–(i + 1 mod n), sorted, so the closing edge
    /// `UndirectedEdge(0, n − 1)` is second (NetworkX `cycle_graph`). n edges. O(n).
    ///
    /// - Precondition: `vertexCount ≥ 3`. C₁ and C₂ would need a self-loop or a parallel edge;
    ///   NetworkX returns those, and we trap.
    @inlinable
    public static func cycle(vertexCount n: Int) -> Self {
        Self(_vertexCount: n, sortedEdges: _cyclePairs(n, directed: false).lazy.map(_undirected), _ConstructionToken())
    }

    /// The star on `vertexCount` vertices: hub 0 and leaves `1..<n`, edges 0–i. Counts every
    /// vertex, as igraph's `Star` does (NetworkX's `star_graph(n)` has n + 1 vertices). n − 1 edges.
    /// O(n). As a `Tree`, `Tree.star(vertexCount:)`.
    ///
    /// - Precondition: `vertexCount ≥ 1`, for the hub.
    @inlinable
    public static func star(vertexCount n: Int) -> Self {
        Self(_vertexCount: n, sortedEdges: _starPairs(n).lazy.map(_undirected), _ConstructionToken())
    }

    /// The wheel on `vertexCount` vertices: hub 0, the spokes 0–i, and the rim cycle
    /// 1–2–…–(n − 1)–1 (NetworkX `wheel_graph`). 2(n − 1) edges, sorted. O(n).
    ///
    /// - Precondition: `vertexCount ≥ 4`, so the rim is a cycle.
    @inlinable
    public static func wheel(vertexCount n: Int) -> Self {
        Self(_vertexCount: n, sortedEdges: _wheelPairs(n, directed: false).lazy.map(_undirected), _ConstructionToken())
    }
}

extension _DirectedGraphConstruction {
    /// The directed path on `0..<vertexCount`: arcs i → i + 1 (NetworkX `path_graph(n,
    /// create_using=nx.DiGraph)`). O(n).
    ///
    /// - Precondition: `vertexCount ≥ 0`.
    @inlinable
    public static func path(vertexCount n: Int) -> Self {
        Self(_vertexCount: n, sortedEdges: _pathPairs(n), _ConstructionToken())
    }

    /// The directed cycle on `0..<vertexCount`: arcs i → (i + 1 mod n), in row-major order. O(n).
    ///
    /// - Precondition: `vertexCount ≥ 3`, as for the undirected cycle.
    @inlinable
    public static func cycle(vertexCount n: Int) -> Self {
        Self(_vertexCount: n, sortedEdges: _cyclePairs(n, directed: true), _ConstructionToken())
    }

    /// The out-star: arcs from hub 0 to each leaf in `1..<n`. O(n).
    ///
    /// - Precondition: `vertexCount ≥ 1`.
    @inlinable
    public static func star(vertexCount n: Int) -> Self {
        Self(_vertexCount: n, sortedEdges: _starPairs(n), _ConstructionToken())
    }

    /// The directed wheel: the out-star from hub 0 and the rim cycle 1 → 2 → … → n − 1 → 1, in
    /// row-major order (the star and the cycle composed; NetworkX has no directed wheel). O(n).
    ///
    /// - Precondition: `vertexCount ≥ 4`.
    @inlinable
    public static func wheel(vertexCount n: Int) -> Self {
        Self(_vertexCount: n, sortedEdges: _wheelPairs(n, directed: true), _ConstructionToken())
    }
}

extension Tree where Vertex == Int {
    /// The path on `0..<vertexCount` as a tree: edge k is k–(k + 1). Built on the dense layout
    /// with no vertex dictionary, as `Tree(pruferSequence:)` is. O(n).
    ///
    /// - Precondition: `vertexCount ≥ 1`: a tree is never empty.
    @inlinable
    public static func path(vertexCount n: Int) -> Tree {
        precondition(n >= 1, "a Tree has at least one vertex")
        var ends: [Int] = []
        ends.reserveCapacity(2 * (n - 1))
        for k in 0 ..< n - 1 {
            ends.append(k)
            ends.append(k + 1)
        }
        return Tree(_vertexCount: n, treeEnds: ends)
    }

    /// The star on `0..<vertexCount` as a tree: hub 0, edge k is 0–(k + 1). O(n).
    ///
    /// - Precondition: `vertexCount ≥ 1`.
    @inlinable
    public static func star(vertexCount n: Int) -> Tree {
        precondition(n >= 1, "a Tree has at least one vertex")
        var ends: [Int] = []
        ends.reserveCapacity(2 * (n - 1))
        for k in 1 ..< n {
            ends.append(0)
            ends.append(k)
        }
        return Tree(_vertexCount: n, treeEnds: ends)
    }
}
