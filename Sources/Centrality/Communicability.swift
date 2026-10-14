import GraphProtocols

/// e^A for a symmetric n × n matrix with entries 0 and 1 (row-major), by scaling and squaring: A
/// scaled by 2^(−s) to norm at most ½, its Taylor series to 18 terms (its terms are all at least
/// zero, so the sum loses nothing to cancellation; the remainder is below 2^(−63) relative), then
/// squared s times.
@inlinable
func _exponential(_ a: [Double], count n: Int) -> [Double] {
    guard n > 0 else { return [] }
    // The ∞-norm bounds the spectral radius.
    var norm = 0.0
    for i in 0 ..< n {
        var row = 0.0
        for j in 0 ..< n { row += abs(a[i * n + j]) }
        norm = max(norm, row)
    }
    var s = 0
    var scale = 1.0
    while norm * scale > 0.5 {
        scale /= 2
        s += 1
    }
    let x = a.map { $0 * scale }
    var result = [Double](repeating: 0, count: n * n)
    var term = [Double](repeating: 0, count: n * n)
    for i in 0 ..< n {
        result[i * n + i] = 1
        term[i * n + i] = 1
    }
    var next = [Double](repeating: 0, count: n * n)
    for k in 1 ... 18 {
        _multiply(term, x, into: &next, count: n)
        let inverse = 1 / Double(k)
        for i in 0 ..< n * n {
            term[i] = next[i] * inverse
            result[i] += term[i]
        }
    }
    for _ in 0 ..< s {
        _multiply(result, result, into: &next, count: n)
        swap(&result, &next)
    }
    return result
}

/// c = a b for n × n row-major matrices.
@inlinable
func _multiply(_ a: [Double], _ b: [Double], into c: inout [Double], count n: Int) {
    c.withUnsafeMutableBufferPointer { c in
        a.withUnsafeBufferPointer { a in
            b.withUnsafeBufferPointer { b in
                for i in 0 ..< n * n { c[i] = 0 }
                for i in 0 ..< n {
                    for p in 0 ..< n {
                        let x = a[i * n + p]
                        if x == 0 { continue }
                        for j in 0 ..< n { c[i * n + j] += x * b[p * n + j] }
                    }
                }
            }
        }
    }
}

/// The communicability of every pair of vertices (Estrada and Hatano 2008): the entries of e^A,
/// stored densely by vertex index.
@frozen
public struct Communicability<G: DirectedGraph> {
    @usableFromInline let _graph: G
    /// Vertex numbers when the graph has no vertex indices.
    @usableFromInline let _numbers: [G.Vertex: Int]?
    @usableFromInline let _count: Int
    /// Row-major, `_count` × `_count`.
    @usableFromInline let _values: [Double]

    @inlinable
    init(_ graph: G, numbers: [G.Vertex: Int]?, count: Int, values: [Double]) {
        _graph = graph
        _numbers = numbers
        _count = count
        _values = values
    }

    /// The communicability of `u` and `v`: Σ_k (A^k)_uv / k!, the walks from `u` to `v` weighted
    /// by the inverse factorial of their lengths; symmetric, and the subgraph centrality of `u`
    /// when `u == v`. O(1) after looking them up.
    ///
    /// - Precondition: `u` and `v` are vertices of the graph.
    @inlinable
    public func communicability(of u: G.Vertex, and v: G.Vertex) -> Double {
        let a = _graph._vertexNumber(of: u, _numbers, "The vertex is not in the graph")
        let b = _graph._vertexNumber(of: v, _numbers, "The vertex is not in the graph")
        return _values[a * _count + b]
    }

    /// The communicability of `u` and `v`, throwing instead of trapping when either is not a
    /// vertex of the graph.
    ///
    /// - Throws: `VertexNotFound` when `u` or `v` is not a vertex of the graph.
    @inlinable
    public func communicability(checked u: G.Vertex, and v: G.Vertex) throws(VertexNotFound) -> Double {
        guard _graph.contains(u), _graph.contains(v) else { throw VertexNotFound() }
        return communicability(of: u, and: v)
    }

    /// The communicability of the vertices at `i` and `j` (their vertex indices, or their positions
    /// in `vertices` when the graph has no vertex indices).
    ///
    /// - Precondition: `i` and `j` are in `0..<vertexCount`.
    @inlinable
    public func communicability(ofIndex i: Int, andIndex j: Int) -> Double {
        precondition(i >= 0 && i < _count && j >= 0 && j < _count, "Vertex index out of range")
        return _values[i * _count + j]
    }
}

extension Communicability: Sendable where G: Sendable, G.Vertex: Sendable {}

extension Graph {
    /// The 0/1 adjacency matrix: 1 where two vertices are adjacent (parallel edges count once), and
    /// on the diagonal of a vertex with a self-loop.
    @inlinable
    func _binaryAdjacency() -> [Double] {
        let rows = _runOnUndirectedRows(_CopyRows(readsEdges: false, dropsLoops: false))
        let n = rows.count
        var a = [Double](repeating: 0, count: n * n)
        for v in 0 ..< n {
            for slot in rows.offsets[v] ..< rows.offsets[v + 1] { a[v * n + rows.targets[slot]] = 1 }
        }
        return a
    }

    /// Subgraph centrality (Estrada and Rodríguez-Velázquez 2005): (e^A)_vv = Σ_k (A^k)_vv / k!,
    /// the closed walks at each vertex weighted by the inverse factorial of their lengths, A the 0/1
    /// adjacency matrix (parallel edges count once; a self-loop puts 1 on the diagonal).
    ///
    /// - Complexity: O(n³ log ‖A‖) for the matrix exponential; O(n²) memory.
    @inlinable
    public func subgraphCentrality() -> CentralityScores<DirectedView<Self>> {
        let n = vertexCount
        let e = _exponential(_binaryAdjacency(), count: n)
        return CentralityScores(directedView, numbers: _vertexNumbering()?.numbers, scores: (0 ..< n).map { e[$0 * n + $0] })
    }

    /// Communicability (Estrada and Hatano 2008): e^A, the walks between each pair weighted by the
    /// inverse factorial of their lengths, A the 0/1 adjacency matrix as `subgraphCentrality()`
    /// reads it.
    ///
    /// - Complexity: O(n³ log ‖A‖) for the matrix exponential; O(n²) memory.
    @inlinable
    public func communicability() -> Communicability<DirectedView<Self>> {
        let n = vertexCount
        return Communicability(directedView, numbers: _vertexNumbering()?.numbers, count: n, values: _exponential(_binaryAdjacency(), count: n))
    }
}
