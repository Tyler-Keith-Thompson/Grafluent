import GraphProtocols

/// The community of each vertex number from a caller's grouping, and the number of groups.
///
/// - Precondition: every vertex is listed exactly once, and nothing else is listed.
@inlinable
func _membership<C: Collection>(_ communities: C, count n: Int, _ number: (C.Element.Element) -> Int?) -> (labels: [Int], count: Int) where C.Element: Collection {
    var labels = [Int](repeating: -1, count: n)
    var c = 0
    for community in communities {
        for vertex in community {
            guard let v = number(vertex) else { preconditionFailure("A community lists \(vertex), which is not a vertex of the graph") }
            precondition(labels[v] < 0, "\(vertex) is listed in more than one community")
            labels[v] = c
        }
        c += 1
    }
    precondition(!labels.contains(-1), "The communities do not list every vertex")
    return (labels, c)
}

/// Modularity with NetworkX's arithmetic: Σ_c L_c/m − γ · out_c · in_c · norm, norm 1/m² directed
/// and 1/(2m)² undirected (each edge counted at both ends). 0 when m = 0.
@inlinable
func _modularity(_ graph: _CommunityGraph, _ weights: [Double]?, labels: [Int], count k: Int, resolution gamma: Double) -> Double {
    var m = 0.0
    if let weights { for w in weights { m += w } } else { m = Double(graph.edgeCount) }
    guard m != 0 else { return 0 }
    var inside = [Double](repeating: 0, count: k)
    var out = [Double](repeating: 0, count: k)
    var into = [Double](repeating: 0, count: k)
    for e in 0 ..< graph.edgeCount {
        let a = labels[graph.from[e]], b = labels[graph.to[e]]
        let w = weights?[e] ?? 1
        if a == b { inside[a] += w }
        out[a] += w
        into[b] += w
        if !graph.directed {
            out[b] += w
            into[a] += w
        }
    }
    let norm = graph.directed ? 1 / (m * m) : 1 / ((2 * m) * (2 * m))
    var q = 0.0
    for c in 0 ..< k { q += inside[c] / m - gamma * out[c] * into[c] * norm }
    return q
}

/// Undirected modularity straight from the rows, with no per-edge array: each slot adds its edge's
/// weight to its community's degree sum, and half of it to the inside weight when both ends share a
/// community (every edge is listed twice, a loop twice in its own row).
@frozen
@usableFromInline
struct _RowModularity: _UndirectedRowsAlgorithm {
    @usableFromInline let labels: [Int]
    @usableFromInline let count: Int
    @usableFromInline let weights: [Double]?
    @usableFromInline let resolution: Double

    @inlinable
    init(labels: [Int], count: Int, weights: [Double]?, resolution: Double) {
        self.labels = labels
        self.count = count
        self.weights = weights
        self.resolution = resolution
    }

    @inlinable
    var readsEdges: Bool { weights != nil }

    @inlinable
    func run<Rows: _IncidenceRowSource>(count n: Int, edgeCount: Int, _ rows: inout Rows) -> Double {
        var m = 0.0
        if let weights { for w in weights { m += w } } else { m = Double(edgeCount) }
        guard m != 0 else { return 0 }
        var inside = [Double](repeating: 0, count: count)
        var degree = [Double](repeating: 0, count: count)
        inside.withUnsafeMutableBufferPointer { inside in
            degree.withUnsafeMutableBufferPointer { degree in
                labels.withUnsafeBufferPointer { labels in
                    for v in 0 ..< n {
                        let c = labels[v]
                        var sum = 0.0, within = 0.0
                        for k in 0 ..< rows.count(v) {
                            let w = rows.neighbor(v, k)
                            precondition(UInt(bitPattern: w) < UInt(bitPattern: n), "A neighbor index is out of range")
                            let x = weights?[rows.edge(v, k)] ?? 1
                            sum += x
                            if labels[w] == c { within += x }
                        }
                        degree[c] += sum
                        inside[c] += within / 2
                    }
                }
            }
        }
        let norm = 1 / ((2 * m) * (2 * m))
        var q = 0.0
        for c in 0 ..< count { q += inside[c] / m - resolution * degree[c] * degree[c] * norm }
        return q
    }
}

/// Coverage and performance (NetworkX `partition_quality`, without its multigraph refusal and
/// with self-loops not counted as pairs).
@inlinable
func _partitionQuality(_ graph: _CommunityGraph, labels: [Int], count k: Int) -> PartitionQuality {
    let n = graph.count, m = graph.edgeCount
    var intra = 0
    for e in 0 ..< m {
        if labels[graph.from[e]] == labels[graph.to[e]] { intra += 1 }
    }
    let coverage = m == 0 ? Double.nan : Double(intra) / Double(m)
    guard n >= 2 else { return PartitionQuality(coverage: coverage, performance: .nan) }
    // Distinct adjacent pairs, as keys a·n + b (a < b undirected), loops left out.
    var keys: [Int] = []
    keys.reserveCapacity(m)
    for e in 0 ..< m {
        var a = graph.from[e], b = graph.to[e]
        if a == b { continue }
        if !graph.directed, a > b { swap(&a, &b) }
        keys.append(a * n + b)
    }
    keys.sort()
    var intraAdjacent = 0, interAdjacent = 0
    var previous = -1
    for key in keys where key != previous {
        previous = key
        if labels[key / n] == labels[key % n] { intraAdjacent += 1 } else { interAdjacent += 1 }
    }
    var sizes = [Int](repeating: 0, count: k)
    for c in labels { sizes[c] += 1 }
    let ordered = graph.directed
    var intraPairs = 0
    for s in sizes { intraPairs += ordered ? s * (s - 1) : s * (s - 1) / 2 }
    let pairs = ordered ? n * (n - 1) : n * (n - 1) / 2
    let good = intraAdjacent + (pairs - intraPairs - interAdjacent)
    return PartitionQuality(coverage: coverage, performance: Double(good) / Double(pairs))
}

extension Graph {
    /// Modularity (Newman and Girvan; NetworkX `modularity`, with Reichardt and Bornholdt's
    /// resolution γ): Σ_c [L_c/m − γ (d_c/2m)²], L_c the number of edges inside community c, d_c
    /// its degree sum (a self-loop counts twice), m the number of edges. 0 without edges. Takes any
    /// grouping of the vertices, such as a `Partition` or `connectedComponents()`. O(n + m) after
    /// looking the vertices up.
    ///
    /// - Precondition: `communities` lists every vertex exactly once (empty communities are
    ///   allowed); `resolution` is finite and at least zero.
    @inlinable
    public func modularity<C: Collection>(of communities: C, resolution: Double = 1) -> Double where C.Element: Collection, C.Element.Element == Vertex {
        let numbers = _communityNumbers()
        let (labels, k) = _membership(communities, count: vertexCount) { _communityNumber(of: $0, numbers) }
        _checkResolution(resolution)
        return _runOnUndirectedRows(_RowModularity(labels: labels, count: k, weights: nil, resolution: resolution))
    }

    /// Weighted modularity: L_c, d_c and m are sums of weights. `weight` is called once per edge,
    /// in position order.
    ///
    /// - Precondition: `communities` lists every vertex exactly once; every weight is finite and
    ///   at least zero; `resolution` is finite and at least zero.
    @inlinable
    public func modularity<C: Collection, W: BinaryFloatingPoint>(of communities: C, weight: (Edges.Index) -> W, resolution: Double = 1) -> Double where C.Element: Collection, C.Element.Element == Vertex {
        let numbers = _communityNumbers()
        let (labels, k) = _membership(communities, count: vertexCount) { _communityNumber(of: $0, numbers) }
        let weights = _communityWeights(weight)
        _checkResolution(resolution)
        return _runOnUndirectedRows(_RowModularity(labels: labels, count: k, weights: weights, resolution: resolution))
    }

    /// Coverage and performance of a grouping of the vertices (NetworkX `partition_quality`).
    /// O(n + m log m).
    ///
    /// - Precondition: `communities` lists every vertex exactly once (empty communities are
    ///   allowed).
    @inlinable
    public func partitionQuality<C: Collection>(of communities: C) -> PartitionQuality where C.Element: Collection, C.Element.Element == Vertex {
        let numbers = _communityNumbers()
        let (labels, k) = _membership(communities, count: vertexCount) { _communityNumber(of: $0, numbers) }
        return _partitionQuality(_communityGraph(), labels: labels, count: k)
    }
}

extension DirectedGraph {
    /// Directed modularity (Leicht and Newman; NetworkX `modularity`): Σ_c [L_c/m − γ out_c in_c/m²],
    /// out_c and in_c the community's out- and in-degree sums. 0 without edges. O(n + m) after
    /// looking the vertices up.
    ///
    /// - Precondition: `communities` lists every vertex exactly once (empty communities are
    ///   allowed); `resolution` is finite and at least zero.
    @inlinable
    public func modularity<C: Collection>(of communities: C, resolution: Double = 1) -> Double where C.Element: Collection, C.Element.Element == Vertex {
        let numbers = _communityNumbers()
        let (labels, k) = _membership(communities, count: vertexCount) { _communityNumber(of: $0, numbers) }
        _checkResolution(resolution)
        return _modularity(_communityGraph(numbers), nil, labels: labels, count: k, resolution: resolution)
    }

    /// Weighted directed modularity. `weight` is called once per edge, in position order.
    ///
    /// - Precondition: `communities` lists every vertex exactly once; every weight is finite and
    ///   at least zero; `resolution` is finite and at least zero.
    @inlinable
    public func modularity<C: Collection, W: BinaryFloatingPoint>(of communities: C, weight: (Edges.Index) -> W, resolution: Double = 1) -> Double where C.Element: Collection, C.Element.Element == Vertex {
        let numbers = _communityNumbers()
        let (labels, k) = _membership(communities, count: vertexCount) { _communityNumber(of: $0, numbers) }
        let weights = _communityWeights(weight)
        _checkResolution(resolution)
        return _modularity(_communityGraph(numbers), weights, labels: labels, count: k, resolution: resolution)
    }

    /// Coverage and performance over ordered pairs (NetworkX `partition_quality`). O(n + m log m).
    ///
    /// - Precondition: `communities` lists every vertex exactly once (empty communities are
    ///   allowed).
    @inlinable
    public func partitionQuality<C: Collection>(of communities: C) -> PartitionQuality where C.Element: Collection, C.Element.Element == Vertex {
        let numbers = _communityNumbers()
        let (labels, k) = _membership(communities, count: vertexCount) { _communityNumber(of: $0, numbers) }
        return _partitionQuality(_communityGraph(numbers), labels: labels, count: k)
    }
}
