import GraphProtocols

/// The binomial coefficients C(a, b) for a in 0…n and b in 0…k, row a at a·(k + 1), with
/// `Int.max` for those that overflow. A coefficient that fits is exact: both terms of its sum are
/// at most it.
@usableFromInline
func _binomialTable(_ n: Int, _ k: Int) -> [Int] {
    var table = [Int](repeating: 0, count: (n + 1) * (k + 1))
    for a in 0 ... n {
        table[a * (k + 1)] = 1
        guard a > 0, k > 0 else { continue }
        for b in 1 ... Swift.min(a, k) {
            let x = table[(a - 1) * (k + 1) + b - 1], y = table[(a - 1) * (k + 1) + b]
            table[a * (k + 1) + b] = x <= Int.max - y ? x + y : Int.max
        }
    }
    return table
}

/// The Kneser graph's vertex count C(n, k) and edges, sorted. Vertex r is the r-th k-subset of
/// `0..<n` in lexicographic order. Each subset's neighbors are the k-subsets of its complement,
/// enumerated in lexicographic order, which is the order of their ranks; those of larger rank are
/// kept.
@usableFromInline
func _kneserPairs(_ n: Int, _ k: Int) -> (vertexCount: Int, pairs: [DirectedEdge<Int>]) {
    precondition(k >= 1 && k <= n, "subsetSize \(k) is not in 1...\(n)")
    let binomial = _binomialTable(n, k)
    let stride = k + 1
    let vertexCount = binomial[n * stride + k]
    precondition(vertexCount < Int.max, "vertex count overflows Int")
    // Each vertex has C(n − k, k) neighbors, so m = C(n, k)·C(n − k, k)/2.
    let degree = n - k >= k ? binomial[(n - k) * stride + k] : 0
    precondition(_productFits(vertexCount, degree), "edge count overflows Int")
    var pairs: [DirectedEdge<Int>] = []
    pairs.reserveCapacity(vertexCount * degree / 2)
    guard degree > 0 else { return (vertexCount, pairs) }
    // The rank of c₀ < … < c_{k−1} in lexicographic order is C(n, k) − 1 − Σᵢ C(n − 1 − cᵢ, k − i).
    var subset = Array(0 ..< k)
    var complement = [Int](repeating: 0, count: n - k)
    var pick = [Int](repeating: 0, count: k)
    var prefix = [Int](repeating: 0, count: k + 1)
    for u in 0 ..< vertexCount {
        // The complement of `subset`, ascending.
        var j = 0, c = 0
        for x in 0 ..< n {
            if j < k, subset[j] == x {
                j += 1
            } else {
                complement[c] = x
                c += 1
            }
        }
        // Every k-subset of the complement, as positions into it, in lexicographic order. The rank's
        // sum is kept as prefix sums, so a step recomputes only the terms from the first position
        // it changed.
        for i in 0 ..< k { pick[i] = i }
        var from = 0
        while true {
            for i in from ..< k { prefix[i + 1] = prefix[i] + binomial[(n - 1 - complement[pick[i]]) * stride + (k - i)] }
            let rank = vertexCount - 1 - prefix[k]
            if rank > u { pairs.append(DirectedEdge(from: u, to: rank)) }
            var i = k - 1
            while i >= 0, pick[i] == n - k - k + i { i -= 1 }
            if i < 0 { break }
            pick[i] += 1
            for t in i + 1 ..< k { pick[t] = pick[t - 1] + 1 }
            from = i
        }
        // The next k-subset of 0..<n in lexicographic order.
        var i = k - 1
        while i >= 0, subset[i] == n - k + i { i -= 1 }
        if i < 0 { break }
        subset[i] += 1
        for t in i + 1 ..< k { subset[t] = subset[t - 1] + 1 }
    }
    return (vertexCount, pairs)
}

extension _GraphConstruction {
    /// The Kneser graph KG(n, k): a vertex for each k-element subset of `0..<setSize`, and an edge
    /// between two subsets when they are disjoint. Vertex r is the r-th subset in lexicographic
    /// order, so 0 is {0, …, k − 1}. C(n, k) vertices, each of degree C(n − k, k); no edges when
    /// n < 2k. `kneser(setSize: 5, subsetSize: 2)` is the Petersen graph, and
    /// `kneser(setSize: n, subsetSize: 1)` is Kₙ. Sorted. O(C(n, k)·C(n − k, k)·k).
    ///
    /// > László Lovász. Kneser's conjecture, chromatic number, and homotopy. *Journal of
    /// > Combinatorial Theory, Series A* 25(3), 319–324 (1978). doi:10.1016/0097-3165(78)90022-5
    ///
    /// - Precondition: 1 ≤ `subsetSize` ≤ `setSize`, and the vertex and edge counts fit in `Int`.
    @inlinable
    public static func kneser(setSize n: Int, subsetSize k: Int) -> Self {
        let (count, pairs) = _kneserPairs(n, k)
        return Self(_vertexCount: count, sortedEdges: pairs.lazy.map(_undirected), _ConstructionToken())
    }
}

extension _DirectedGraphConstruction {
    /// The Kneser graph with both arcs of every edge, in row-major order; numbering as the
    /// undirected `kneser(setSize:subsetSize:)`.
    ///
    /// - Precondition: as for the undirected form.
    @inlinable
    public static func kneser(setSize n: Int, subsetSize k: Int) -> Self {
        let (count, pairs) = _kneserPairs(n, k)
        return Self(_vertexCount: count, sortedEdges: _bothArcs(vertexCount: count, pairs), _ConstructionToken())
    }
}
