import GraphProtocols

/// The incidence matrix from each edge's endpoint numbers (column j for the j-th edge): with
/// `oriented`, −1 at `tails[j]` and +1 at `heads[j]` and an empty column for a loop; without,
/// 1 at both ends and 2 at a loop's vertex.
@usableFromInline
func _incidenceMatrix(rowCount n: Int, tails: [Int], heads: [Int], oriented: Bool) -> SparseMatrix {
    let m = tails.count
    var offsets = [Int](repeating: 0, count: n + 1)
    for j in 0 ..< m {
        let u = tails[j], v = heads[j]
        if u == v {
            if !oriented { offsets[u + 1] += 1 }
        } else {
            offsets[u + 1] += 1
            offsets[v + 1] += 1
        }
    }
    for v in 0 ..< n { offsets[v + 1] += offsets[v] }
    var fill = offsets
    var columns = [Int](repeating: 0, count: offsets[n])
    var values = [Double](repeating: 0, count: offsets[n])
    for j in 0 ..< m {
        let u = tails[j], v = heads[j]
        if u == v {
            if !oriented {
                columns[fill[u]] = j
                values[fill[u]] = 2
                fill[u] += 1
            }
        } else {
            columns[fill[u]] = j
            values[fill[u]] = oriented ? -1 : 1
            fill[u] += 1
            columns[fill[v]] = j
            values[fill[v]] = 1
            fill[v] += 1
        }
    }
    return SparseMatrix(_offsets: offsets, _columns: columns, _values: values, columnCount: m)
}

extension _MergedRows {
    /// B = A − k_out k_inᵀ / W, dense rows, with k_out the row sums, k_in the column sums and W
    /// the sum of every entry (A itself when W is 0). For symmetric rows this is A − k kᵀ / vol.
    @usableFromInline
    func modularityMatrix() -> [[Double]] {
        let n = count
        var outgoing = [Double](repeating: 0, count: n)
        var incoming = [Double](repeating: 0, count: n)
        var total = 0.0
        var b = [[Double]](repeating: [Double](repeating: 0, count: n), count: n)
        for v in 0 ..< n {
            for k in offsets[v] ..< offsets[v + 1] {
                let u = columns[k], w = values[k]
                b[v][u] = w
                outgoing[v] += w
                incoming[u] += w
                total += w
            }
        }
        precondition(total.isFinite, "A sum of weights overflows Double")
        // Without a positive weight every row sum is 0 and B is A.
        for v in 0 ..< n where outgoing[v] != 0 {
            let scale = outgoing[v] / total
            for u in 0 ..< n { b[v][u] -= scale * incoming[u] }
        }
        return b
    }
}

extension Graph {
    /// The incidence matrix: a row per vertex (in vertex-index order, or `vertices` order) and a
    /// column per edge (the j-th edge in `edges` order). Unoriented, an edge has 1 at both ends and
    /// a self-loop 2 at its vertex, so B Bᵀ is the signless Laplacian Q; with `oriented`, the edge
    /// u–v (as `UndirectedEdge` stores it) has −1 at u and +1 at v and a self-loop an empty
    /// column, so B Bᵀ is the Laplacian L. Parallel edges are separate columns.
    ///
    /// - Parameter oriented: Whether to give each edge a direction, from `u` to `v`.
    /// - Returns: The vertexCount × edgeCount matrix, storing exactly its nonzero entries.
    /// - Complexity: O(n + m), and one vertex lookup per endpoint.
    @inlinable
    public func incidenceMatrix(oriented: Bool = false) -> SparseMatrix {
        let numbering = _vertexNumbering()
        var tails: [Int] = [], heads: [Int] = []
        tails.reserveCapacity(edgeCount)
        heads.reserveCapacity(edgeCount)
        for edge in edges {
            tails.append(_spectralNumber(of: edge.u, numbering))
            heads.append(_spectralNumber(of: edge.v, numbering))
        }
        return _incidenceMatrix(rowCount: vertexCount, tails: tails, heads: heads, oriented: oriented)
    }

    /// The modularity matrix B = A − k kᵀ / vol (Newman 2006), dense: A the adjacency matrix
    /// (`adjacencyMatrix()`, a self-loop adding 2 to A[v][v]), k its row sums (the degrees) and
    /// vol their sum, so every row of B sums to 0 and the modularity of a partition is
    /// Σ B[u][v] / vol over the pairs in one community. A itself (all zeros) without edges. Rows
    /// and columns follow vertex indices, or `vertices` order.
    ///
    /// - Returns: The rows of B.
    /// - Complexity: O(n² + m) time and n² `Double`s.
    @inlinable
    public func modularityMatrix() -> [[Double]] {
        _spectralAdjacency(nil, numbering: nil).merged().modularityMatrix()
    }

    /// The modularity matrix B = A − k kᵀ / vol (Newman 2006), dense: A the weighted adjacency
    /// matrix (`adjacencyMatrix(weight:)`, a self-loop adding 2w to A[v][v]), k its row sums (the
    /// weighted degrees) and vol their sum, so every row of B sums to 0. A itself (all zeros)
    /// without an edge of positive weight. Rows and columns follow vertex indices, or `vertices`
    /// order.
    ///
    /// - Parameter weight: The weight of the edge at each position, read once per position; a
    ///   weight of 0 is no edge.
    /// - Returns: The rows of B.
    /// - Complexity: O(n² + m) time and n² `Double`s.
    /// - Precondition: every weight is finite and nonnegative.
    @inlinable
    public func modularityMatrix<W: BinaryInteger>(weight: (Edges.Index) -> W) -> [[Double]] {
        _spectralAdjacency(_spectralWeights(weight), numbering: nil).merged().modularityMatrix()
    }

    /// The modularity matrix B = A − k kᵀ / vol (Newman 2006), dense: A the weighted adjacency
    /// matrix (`adjacencyMatrix(weight:)`, a self-loop adding 2w to A[v][v]), k its row sums (the
    /// weighted degrees) and vol their sum, so every row of B sums to 0. A itself (all zeros)
    /// without an edge of positive weight. Rows and columns follow vertex indices, or `vertices`
    /// order.
    ///
    /// - Parameter weight: The weight of the edge at each position, read once per position; a
    ///   weight of 0 is no edge.
    /// - Returns: The rows of B.
    /// - Complexity: O(n² + m) time and n² `Double`s.
    /// - Precondition: every weight is finite and nonnegative.
    @inlinable
    public func modularityMatrix<W: BinaryFloatingPoint>(weight: (Edges.Index) -> W) -> [[Double]] {
        _spectralAdjacency(_spectralWeights(weight), numbering: nil).merged().modularityMatrix()
    }
}

extension DirectedGraph {
    /// The incidence matrix: a row per vertex (in vertex-index order, or `vertices` order) and a
    /// column per arc (the j-th arc in `edges` order). With `oriented`, the arc u → v has −1 at u
    /// and +1 at v and a loop an empty column, so B Bᵀ is the Laplacian of the underlying
    /// multigraph; unoriented, 1 at both ends and 2 at a loop's vertex. Parallel arcs are separate
    /// columns.
    ///
    /// - Parameter oriented: Whether to sign the entries by direction.
    /// - Returns: The vertexCount × edgeCount matrix, storing exactly its nonzero entries.
    /// - Complexity: O(n + m), and one vertex lookup per endpoint.
    @inlinable
    public func incidenceMatrix(oriented: Bool = false) -> SparseMatrix {
        let numbers = vertexIndexBound == nil ? _vertexNumbers(Array(vertices)) : nil
        var tails: [Int] = [], heads: [Int] = []
        tails.reserveCapacity(edgeCount)
        heads.reserveCapacity(edgeCount)
        for edge in edges {
            tails.append(_vertexNumber(of: edge.source, numbers, "The vertex is not in the graph"))
            heads.append(_vertexNumber(of: edge.target, numbers, "The vertex is not in the graph"))
        }
        return _incidenceMatrix(rowCount: vertexCount, tails: tails, heads: heads, oriented: oriented)
    }

    /// The directed modularity matrix B = A − k_out k_inᵀ / m (Leicht and Newman 2008), dense: A
    /// the adjacency matrix (`adjacencyMatrix()`), k_out and k_in the out- and in-degrees and m
    /// the number of arcs, so every row and column of B sums to 0. A itself (all zeros) without
    /// arcs. Rows and columns follow vertex indices, or `vertices` order.
    ///
    /// - Returns: The rows of B.
    /// - Complexity: O(n² + m) time and n² `Double`s.
    @inlinable
    public func modularityMatrix() -> [[Double]] {
        _spectralAdjacency(nil).modularityMatrix()
    }

    /// The directed modularity matrix B = A − k_out k_inᵀ / W (Leicht and Newman 2008), dense: A
    /// the weighted adjacency matrix (`adjacencyMatrix(weight:)`), k_out and k_in the weighted
    /// out- and in-degrees and W the total weight, so every row and column of B sums to 0. A
    /// itself (all zeros) without an arc of positive weight. Rows and columns follow vertex
    /// indices, or `vertices` order.
    ///
    /// - Parameter weight: The weight of the arc at each position, read once per position; a
    ///   weight of 0 is no arc.
    /// - Returns: The rows of B.
    /// - Complexity: O(n² + m) time and n² `Double`s.
    /// - Precondition: every weight is finite and nonnegative.
    @inlinable
    public func modularityMatrix<W: BinaryInteger>(weight: (Edges.Index) -> W) -> [[Double]] {
        _spectralAdjacency(_spectralWeights(weight)).modularityMatrix()
    }

    /// The directed modularity matrix B = A − k_out k_inᵀ / W (Leicht and Newman 2008), dense: A
    /// the weighted adjacency matrix (`adjacencyMatrix(weight:)`), k_out and k_in the weighted
    /// out- and in-degrees and W the total weight, so every row and column of B sums to 0. A
    /// itself (all zeros) without an arc of positive weight. Rows and columns follow vertex
    /// indices, or `vertices` order.
    ///
    /// - Parameter weight: The weight of the arc at each position, read once per position; a
    ///   weight of 0 is no arc.
    /// - Returns: The rows of B.
    /// - Complexity: O(n² + m) time and n² `Double`s.
    /// - Precondition: every weight is finite and nonnegative.
    @inlinable
    public func modularityMatrix<W: BinaryFloatingPoint>(weight: (Edges.Index) -> W) -> [[Double]] {
        _spectralAdjacency(_spectralWeights(weight)).modularityMatrix()
    }
}
