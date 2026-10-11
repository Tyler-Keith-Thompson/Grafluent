import GraphProtocols

// Grids and hypercubes. Each vertex's neighbors are found from its coordinates, in order (at most
// two per dimension), and written as pairs: only the larger neighbors for the undirected form, all of
// them for the directed one, so both come out in order without a sort of the whole list.

@usableFromInline
func _gridPairs(_ dimensions: [Int], periodic: Bool, directed: Bool) -> (vertexCount: Int, pairs: [DirectedEdge<Int>]) {
    precondition(!dimensions.isEmpty, "grid needs at least one dimension")
    for d in dimensions { precondition(d >= 0, "dimension \(d) is negative") }
    var n = 1
    for d in dimensions {
        precondition(_productFits(n, d), "vertex count overflows Int")
        n *= d
    }
    guard n > 0 else { return (0, []) }
    // Σᵢ (dᵢ − 1, or dᵢ when dimension i wraps) · n / dᵢ; each term is at most n.
    var m = 0
    for d in dimensions {
        let term = (periodic && d >= 3 ? d : d - 1) * (n / d)
        precondition(m <= Int.max - term, "edge count overflows Int")
        m += term
    }
    if directed {
        precondition(m <= Int.max / 2, "edge count overflows Int")
        m *= 2
    }
    let k = dimensions.count
    var strides = [Int](repeating: 1, count: k)
    for i in stride(from: k - 2, through: 0, by: -1) { strides[i] = strides[i + 1] * dimensions[i + 1] }
    // Dimension i's offsets, s_i and (d_i − 1)·s_i, lie in [s_i, s_{i−1}), so the neighbors come
    // out in order with no sort: the smaller ones by dimension from the first (the wrap before the
    // step), then the larger ones by dimension from the last (the step before the wrap).
    var coordinates = [Int](repeating: 0, count: k)
    let pairs = [DirectedEdge<Int>](unsafeUninitializedCapacity: m) { pairs, initializedCount in
        var written = 0
        for v in 0 ..< n {
            if directed {
                for i in 0 ..< k {
                    let x = coordinates[i], d = dimensions[i], s = strides[i]
                    if periodic, d >= 3, x == d - 1 {
                        pairs.initializeElement(at: written, to: DirectedEdge(from: v, to: v - (d - 1) * s))
                        written += 1
                    }
                    if x > 0 {
                        pairs.initializeElement(at: written, to: DirectedEdge(from: v, to: v - s))
                        written += 1
                    }
                }
            }
            for i in stride(from: k - 1, through: 0, by: -1) {
                let x = coordinates[i], d = dimensions[i], s = strides[i]
                if x + 1 < d {
                    pairs.initializeElement(at: written, to: DirectedEdge(from: v, to: v + s))
                    written += 1
                }
                if periodic, d >= 3, x == 0 {
                    pairs.initializeElement(at: written, to: DirectedEdge(from: v, to: v + (d - 1) * s))
                    written += 1
                }
            }
            // The next coordinates, the last dimension fastest.
            var i = k - 1
            while i >= 0 {
                coordinates[i] += 1
                if coordinates[i] < dimensions[i] { break }
                coordinates[i] = 0
                i -= 1
            }
        }
        precondition(written == m, "grid edge count")
        initializedCount = written
    }
    return (n, pairs)
}

@usableFromInline
func _hypercubePairs(_ d: Int, directed: Bool) -> (vertexCount: Int, pairs: [DirectedEdge<Int>]) {
    precondition(d >= 0, "dimension \(d) is negative")
    precondition(d <= 62, "2^\(d) vertices overflow Int")
    let n = 1 << d
    // d · 2^(d − 1) edges, twice that as arcs.
    precondition(_productFits(d, directed ? n : n / 2), "edge count overflows Int")
    var pairs: [DirectedEdge<Int>] = []
    pairs.reserveCapacity(d * (directed ? n : n / 2))
    for v in 0 ..< n {
        if directed {
            // Clearing a set bit gives a smaller neighbor, smallest from the highest bit down.
            var bit = d - 1
            while bit >= 0 {
                if v >> bit & 1 == 1 { pairs.append(DirectedEdge(from: v, to: v ^ (1 << bit))) }
                bit -= 1
            }
        }
        for bit in 0 ..< d where v >> bit & 1 == 0 {
            pairs.append(DirectedEdge(from: v, to: v | (1 << bit)))
        }
    }
    return (n, pairs)
}

extension _GraphConstruction {
    /// The grid (lattice) graph with the given side lengths: vertex x = (x₀, …, x_{k−1}) is
    /// Σ xᵢ·Πⱼ₍ⱼ>ᵢ₎ dⱼ (row-major, the last dimension fastest), with an edge x–(x + eᵢ) for each
    /// dimension. With `periodic`, each dimension of length 3 or more also wraps around (a torus);
    /// a dimension of length 1 or 2 never wraps, so there is no self-loop or repeat. NetworkX's
    /// `grid_2d_graph(r, c)` node (i, j) is vertex i·c + j. A dimension of 0 gives the null graph.
    /// O(n + m), with m = Σᵢ (dᵢ − 1, or dᵢ when it wraps)·Πⱼ≠ᵢ dⱼ.
    ///
    /// - Precondition: at least one dimension, none negative, and the vertex and edge counts fit
    ///   in `Int`.
    @inlinable
    public static func grid(dimensions: [Int], periodic: Bool = false) -> Self {
        let (n, pairs) = _gridPairs(dimensions, periodic: periodic, directed: false)
        return Self(_vertexCount: n, sortedEdges: pairs.lazy.map(_undirected), _ConstructionToken())
    }

    /// The hypercube Q_d on `0..<2^d`: bit k of a vertex is its coordinate k, and u–v when they
    /// differ in one bit (NetworkX `hypercube_graph`, numbered by bits). d·2^(d − 1) edges.
    /// `hypercube(dimension: 0)` is K₁, as in igraph. O(n + m).
    ///
    /// - Precondition: `0 ≤ dimension ≤ 62`, and the edge count fits in `Int`.
    @inlinable
    public static func hypercube(dimension d: Int) -> Self {
        let (n, pairs) = _hypercubePairs(d, directed: false)
        return Self(_vertexCount: n, sortedEdges: pairs.lazy.map(_undirected), _ConstructionToken())
    }
}

extension _DirectedGraphConstruction {
    /// The grid with both arcs for every edge (NetworkX's `grid_2d_graph` as a `DiGraph`), in
    /// row-major order; numbering as the undirected `grid(dimensions:periodic:)`. O(n + m).
    ///
    /// - Precondition: as for the undirected grid, with twice the edge count fitting in `Int`.
    @inlinable
    public static func grid(dimensions: [Int], periodic: Bool = false) -> Self {
        let (n, pairs) = _gridPairs(dimensions, periodic: periodic, directed: true)
        return Self(_vertexCount: n, sortedEdges: pairs, _ConstructionToken())
    }

    /// The hypercube with both arcs for every edge, in row-major order. O(n + m).
    ///
    /// - Precondition: `0 ≤ dimension ≤ 62`, and d·2^d fits in `Int`.
    @inlinable
    public static func hypercube(dimension d: Int) -> Self {
        let (n, pairs) = _hypercubePairs(d, directed: true)
        return Self(_vertexCount: n, sortedEdges: pairs, _ConstructionToken())
    }
}
