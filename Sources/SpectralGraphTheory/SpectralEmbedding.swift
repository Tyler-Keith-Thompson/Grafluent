import GraphProtocols

/// A spectral embedding (Laplacian eigenmaps; Belkin and Niyogi 2003): `dimensions` coordinates
/// per vertex, from the eigenvectors x₂, …, x_{k+1} of the normalized Laplacian N for its
/// smallest eigenvalues after the first, each entry divided by √d(v) (0 at a vertex of degree 0),
/// so that the coordinates are the generalized eigenvectors of L y = λ D y.
///
/// On a graph with c components the first c eigenvalues of N are 0, and the eigenvectors after
/// the first include the other components' null vectors.
@frozen
public struct SpectralEmbedding<G: Graph> {
    @usableFromInline let _graph: G
    /// Vertex numbers when the graph has no vertex indices.
    @usableFromInline let _numbers: [G.Vertex: Int]?
    /// The coordinates of vertex number v at v · dimensions.
    @usableFromInline let _coordinates: [Double]

    /// The number of coordinates per vertex.
    public let dimensions: Int

    /// The eigenvalues of N whose eigenvectors give the coordinates, ascending: λ₂, …, λ_{k+1}.
    public let eigenvalues: [Double]

    @inlinable
    init(_ graph: G, numbers: [G.Vertex: Int]?, eigenvalues: [Double], coordinates: [Double]) {
        _graph = graph
        _numbers = numbers
        dimensions = eigenvalues.count
        self.eigenvalues = eigenvalues
        _coordinates = coordinates
    }

    /// The coordinates of `vertex`, one per dimension. O(dimensions) after looking it up.
    ///
    /// - Precondition: `vertex` is a vertex of the graph.
    @inlinable
    public func coordinates(of vertex: G.Vertex) -> [Double] {
        if let _numbers {
            guard let v = _numbers[vertex] else { preconditionFailure("The vertex is not in the graph") }
            return coordinates(ofIndex: v)
        }
        return coordinates(ofIndex: _graph._requiredVertexIndex(of: vertex, "The vertex is not in the graph"))
    }

    /// The coordinates of `vertex`, throwing instead of trapping when it is not a vertex of the
    /// graph.
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not a vertex of the graph.
    @inlinable
    public func coordinates(checked vertex: G.Vertex) throws(VertexNotFound) -> [Double] {
        if let _numbers {
            guard let v = _numbers[vertex] else { throw VertexNotFound() }
            return coordinates(ofIndex: v)
        }
        guard _graph.contains(vertex) else { throw VertexNotFound() }
        return coordinates(of: vertex)
    }

    /// The coordinates of the vertex at `index` (its vertex index, or its position in `vertices`
    /// when the graph has no vertex indices).
    ///
    /// - Precondition: `index` is in `0..<vertexCount`.
    @inlinable
    public func coordinates(ofIndex index: Int) -> [Double] {
        precondition(index >= 0 && index * dimensions < _coordinates.count, "Vertex index out of range")
        return Array(_coordinates[index * dimensions ..< (index + 1) * dimensions])
    }
}

extension SpectralEmbedding: Sendable where G: Sendable, G.Vertex: Sendable {}

extension _WeightedAdjacency {
    /// The Laplacian-eigenmap coordinates (`SpectralEmbedding`), vertex v's at v · dimensions,
    /// and the eigenvalues used.
    @usableFromInline
    func spectralEmbedding(dimensions k: Int, tolerance: Double, maxIterations: Int?) throws(NoConvergence) -> (values: [Double], coordinates: [Double]) {
        let n = count
        precondition(k >= 1 && k < n, "The dimensions are not in 1..<vertexCount")
        let (values, vectors) = try eigenpairs(.normalizedLaplacian, count: k + 1, largest: false, tolerance: tolerance, maxIterations: maxIterations)
        let d = degrees()
        var coordinates = [Double](repeating: 0, count: n * k)
        for v in 0 ..< n where d[v] > 0 {
            let scale = 1 / d[v].squareRoot()
            for j in 0 ..< k { coordinates[v * k + j] = vectors[(j + 1) * n + v] * scale }
        }
        return (Array(values[1...]), coordinates)
    }

    /// The rows of Ng–Jordan–Weiss: N's eigenvectors for its k smallest eigenvalues as columns,
    /// each row scaled to unit length (a zero row stays zero), vertex v's at v · k.
    @usableFromInline
    func normalizedSpectralRows(clusters k: Int, tolerance: Double, maxIterations: Int?) throws(NoConvergence) -> [Double] {
        let n = count
        let (_, vectors) = try eigenpairs(.normalizedLaplacian, count: k, largest: false, tolerance: tolerance, maxIterations: maxIterations)
        var rows = [Double](repeating: 0, count: n * k)
        for v in 0 ..< n {
            var length = 0.0
            for j in 0 ..< k {
                let x = vectors[j * n + v]
                rows[v * k + j] = x
                length += x * x
            }
            guard length > 0 else { continue }
            let inverse = 1 / length.squareRoot()
            for j in 0 ..< k { rows[v * k + j] *= inverse }
        }
        return rows
    }
}

extension Graph {
    /// The spectral embedding of the graph (Laplacian eigenmaps, Belkin and Niyogi 2003; see
    /// `SpectralEmbedding`): `dimensions` coordinates per vertex from the eigenvectors of the
    /// normalized Laplacian for its smallest eigenvalues after the first, divided by √d(v).
    ///
    /// The eigenvectors are `normalizedLaplacianEigenpairs(smallest: dimensions + 1)`'s, with its
    /// method, accuracy and limits. O((n + m) · products + n · k²) time.
    ///
    /// - Parameters:
    ///   - dimensions: The number of coordinates, in `1..<vertexCount`.
    ///   - tolerance: The residual a Ritz pair must reach, relative to its eigenvalue.
    ///   - maxIterations: The matrix–vector products each Lanczos run may spend; nil for the
    ///     defaults of `normalizedLaplacianEigenpairs(smallest:)`.
    /// - Returns: The coordinates of every vertex.
    /// - Precondition: `dimensions` is in `1..<vertexCount`, `tolerance > 0`, and
    ///   `maxIterations`, when given, is at least 1.
    /// - Throws: `NoConvergence` as `normalizedLaplacianEigenpairs(smallest:)` does.
    @inlinable
    public func spectralEmbedding(dimensions: Int, tolerance: Double = 1e-8, maxIterations: Int? = nil) throws(NoConvergence) -> SpectralEmbedding<Self> {
        precondition(tolerance > 0, "The tolerance is not positive")
        _checkMaxIterations(maxIterations)
        let weights: [Double]? = nil
        let numbering = _vertexNumbering()
        let (values, coordinates) = try _spectralAdjacency(weights, numbering: numbering).spectralEmbedding(dimensions: dimensions, tolerance: tolerance, maxIterations: maxIterations)
        return SpectralEmbedding(self, numbers: numbering?.numbers, eigenvalues: values, coordinates: coordinates)
    }

    /// The spectral embedding of the graph (Laplacian eigenmaps, Belkin and Niyogi 2003; see
    /// `SpectralEmbedding`): `dimensions` coordinates per vertex from the eigenvectors of the
    /// normalized Laplacian for its smallest eigenvalues after the first, divided by √d(v).
    ///
    /// The eigenvectors are `normalizedLaplacianEigenpairs(smallest: dimensions + 1, weight:)`'s,
    /// with its method, accuracy and limits. O((n + m) · products + n · k²) time.
    ///
    /// - Parameters:
    ///   - dimensions: The number of coordinates, in `1..<vertexCount`.
    ///   - weight: The weight of the edge at each position, read once per position; a weight of 0
    ///     is no edge.
    ///   - tolerance: The residual a Ritz pair must reach, relative to its eigenvalue.
    ///   - maxIterations: The matrix–vector products each Lanczos run may spend; nil for the
    ///     defaults of `normalizedLaplacianEigenpairs(smallest:)`.
    /// - Returns: The coordinates of every vertex.
    /// - Precondition: `dimensions` is in `1..<vertexCount`, `tolerance > 0`, every weight is
    ///   finite and nonnegative, and `maxIterations`, when given, is at least 1.
    /// - Throws: `NoConvergence` as `normalizedLaplacianEigenpairs(smallest:)` does.
    @inlinable
    public func spectralEmbedding<W: BinaryInteger>(dimensions: Int, weight: (Edges.Index) -> W, tolerance: Double = 1e-8, maxIterations: Int? = nil) throws(NoConvergence) -> SpectralEmbedding<Self> {
        precondition(tolerance > 0, "The tolerance is not positive")
        _checkMaxIterations(maxIterations)
        let weights = _spectralWeights(weight)
        let numbering = _vertexNumbering()
        let (values, coordinates) = try _spectralAdjacency(weights, numbering: numbering).spectralEmbedding(dimensions: dimensions, tolerance: tolerance, maxIterations: maxIterations)
        return SpectralEmbedding(self, numbers: numbering?.numbers, eigenvalues: values, coordinates: coordinates)
    }

    /// The spectral embedding of the graph (Laplacian eigenmaps, Belkin and Niyogi 2003; see
    /// `SpectralEmbedding`): `dimensions` coordinates per vertex from the eigenvectors of the
    /// normalized Laplacian for its smallest eigenvalues after the first, divided by √d(v).
    ///
    /// The eigenvectors are `normalizedLaplacianEigenpairs(smallest: dimensions + 1, weight:)`'s,
    /// with its method, accuracy and limits. O((n + m) · products + n · k²) time.
    ///
    /// - Parameters:
    ///   - dimensions: The number of coordinates, in `1..<vertexCount`.
    ///   - weight: The weight of the edge at each position, read once per position; a weight of 0
    ///     is no edge.
    ///   - tolerance: The residual a Ritz pair must reach, relative to its eigenvalue.
    ///   - maxIterations: The matrix–vector products each Lanczos run may spend; nil for the
    ///     defaults of `normalizedLaplacianEigenpairs(smallest:)`.
    /// - Returns: The coordinates of every vertex.
    /// - Precondition: `dimensions` is in `1..<vertexCount`, `tolerance > 0`, every weight is
    ///   finite and nonnegative, and `maxIterations`, when given, is at least 1.
    /// - Throws: `NoConvergence` as `normalizedLaplacianEigenpairs(smallest:)` does.
    @inlinable
    public func spectralEmbedding<W: BinaryFloatingPoint>(dimensions: Int, weight: (Edges.Index) -> W, tolerance: Double = 1e-8, maxIterations: Int? = nil) throws(NoConvergence) -> SpectralEmbedding<Self> {
        precondition(tolerance > 0, "The tolerance is not positive")
        _checkMaxIterations(maxIterations)
        let weights = _spectralWeights(weight)
        let numbering = _vertexNumbering()
        let (values, coordinates) = try _spectralAdjacency(weights, numbering: numbering).spectralEmbedding(dimensions: dimensions, tolerance: tolerance, maxIterations: maxIterations)
        return SpectralEmbedding(self, numbers: numbering?.numbers, eigenvalues: values, coordinates: coordinates)
    }

    /// The rows of Ng–Jordan–Weiss for spectral clustering into `clusters` clusters: the
    /// eigenvectors of the normalized Laplacian for its `clusters` smallest eigenvalues as columns,
    /// each row scaled to unit length (a zero row stays zero), vertex number v's at v · clusters.
    /// The eigenvectors are `normalizedLaplacianEigenpairs(smallest: clusters)`'s.
    ///
    /// - Parameters:
    ///   - weights: Each edge's weight by edge number, or nil for weight 1; a weight of 0 is no edge.
    ///   - numbering: The vertex numbering of a graph without vertex indices (`_vertexNumbering()`).
    /// - Precondition: `clusters` is in `1...vertexCount`.
    /// - Throws: `NoConvergence` as `normalizedLaplacianEigenpairs(smallest:)` does.
    @inlinable
    package func _normalizedSpectralRows(clusters: Int, weights: [Double]?, numbering: (listed: [Vertex], numbers: [Vertex: Int])?, tolerance: Double, maxIterations: Int?) throws(NoConvergence) -> [Double] {
        try _spectralAdjacency(weights, numbering: numbering).normalizedSpectralRows(clusters: clusters, tolerance: tolerance, maxIterations: maxIterations)
    }
}
