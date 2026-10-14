import GraphProtocols

// Circulant graphs and generalized Petersen graphs: rings of vertices joined at fixed offsets.

/// The circulant graph's edges: i – (i ± o) mod n for each offset o, smaller end first, sorted,
/// each once.
@usableFromInline
func _circulantPairs(_ n: Int, _ offsets: [Int]) -> [DirectedEdge<Int>] {
    precondition(n >= 1, "a circulant graph needs at least 1 vertex, not \(n)")
    // Each offset as its residue s in 1 … n/2: o and n − o give the same edges.
    var steps: [Int] = []
    for o in offsets {
        let r = ((o % n) + n) % n
        precondition(r != 0, "offset \(o) is a multiple of vertexCount \(n): a self-loop")
        steps.append(Swift.min(r, n - r))
    }
    steps.sort()
    var distinct: [Int] = []
    for s in steps where distinct.last != s { distinct.append(s) }
    precondition(_productFits(n, distinct.count), "edge count overflows Int")
    var pairs: [DirectedEdge<Int>] = []
    pairs.reserveCapacity(n * distinct.count)
    for u in 0 ..< n {
        for s in distinct {
            pairs.append(DirectedEdge(from: u, to: (u + s) % n))
        }
    }
    return _sortedPairs(vertexCount: n, pairs)
}

/// The generalized Petersen graph GP(n, k): the outer cycle 0 … n − 1, the spokes i – (n + i), and
/// the inner star polygon (n + i) – (n + (i + k) mod n), sorted.
@usableFromInline
func _generalizedPetersenPairs(_ n: Int, _ k: Int) -> [DirectedEdge<Int>] {
    precondition(n >= 3, "a generalized Petersen graph needs an outer cycle of at least 3, not \(n)")
    precondition(k >= 1 && 2 * k < n, "step \(k) is not in 1 ..< \(n)/2")
    precondition(n <= Int.max / 3, "edge count overflows Int")
    var pairs: [DirectedEdge<Int>] = []
    pairs.reserveCapacity(3 * n)
    for i in 0 ..< n {
        pairs.append(DirectedEdge(from: i, to: (i + 1) % n))
        pairs.append(DirectedEdge(from: i, to: n + i))
        pairs.append(DirectedEdge(from: n + i, to: n + (i + k) % n))
    }
    return _sortedPairs(vertexCount: 2 * n, pairs)
}

extension _GraphConstruction {
    /// The circulant graph Cₙ(o₁, …, o_k) on `0..<vertexCount`: i – (i + o) mod n and
    /// i – (i − o) mod n for each offset o. Offsets are taken mod n, so o and n − o give the same
    /// edges, and a repeated offset adds nothing. `circulant(vertexCount: n, offsets: [1])` is the
    /// cycle Cₙ for n ≥ 3. Sorted. O(n·k) for k offsets.
    ///
    /// - Precondition: `vertexCount ≥ 1`, and no offset is a multiple of `vertexCount` (a
    ///   self-loop).
    @inlinable
    public static func circulant(vertexCount n: Int, offsets: [Int]) -> Self {
        Self(_vertexCount: n, sortedEdges: _circulantPairs(n, offsets).lazy.map(_undirected), _ConstructionToken())
    }

    /// The generalized Petersen graph GP(n, k): the outer cycle 0 – 1 – … – (n − 1) – 0, the
    /// spokes i – (n + i), and the inner edges (n + i) – (n + (i + k) mod n). 2n vertices, 3n
    /// edges, 3-regular, sorted. `generalizedPetersen(outerCycleLength: 5, step: 2)` is
    /// `petersen()`, and `generalizedPetersen(outerCycleLength: n, step: 1)` is the prism
    /// `circularLadder(rungCount: n)`. O(n).
    ///
    /// > Mark E. Watkins. A theorem on Tait colorings with an application to the generalized
    /// > Petersen graphs. *Journal of Combinatorial Theory* 6(2), 152–164 (1969).
    /// > doi:10.1016/S0021-9800(69)80116-X
    ///
    /// - Precondition: `outerCycleLength ≥ 3` and 1 ≤ `step` < n/2.
    @inlinable
    public static func generalizedPetersen(outerCycleLength n: Int, step k: Int) -> Self {
        let pairs = _generalizedPetersenPairs(n, k)
        return Self(_vertexCount: 2 * n, sortedEdges: pairs.lazy.map(_undirected), _ConstructionToken())
    }
}

extension _DirectedGraphConstruction {
    /// The circulant graph with both arcs of every edge: i → (i ± o) mod n for each offset o, in
    /// row-major order. O(n·k).
    ///
    /// - Precondition: as for the undirected form.
    @inlinable
    public static func circulant(vertexCount n: Int, offsets: [Int]) -> Self {
        Self(_vertexCount: n, sortedEdges: _bothArcs(vertexCount: n, _circulantPairs(n, offsets)), _ConstructionToken())
    }

    /// The generalized Petersen graph with both arcs of every edge, in row-major order. O(n).
    ///
    /// - Precondition: as for the undirected form.
    @inlinable
    public static func generalizedPetersen(outerCycleLength n: Int, step k: Int) -> Self {
        let pairs = _generalizedPetersenPairs(n, k)
        return Self(_vertexCount: 2 * n, sortedEdges: _bothArcs(vertexCount: 2 * n, pairs), _ConstructionToken())
    }
}
