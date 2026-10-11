import GraphProtocols

extension Graph {
    /// Every eigenvalue of the adjacency matrix A (`adjacencyMatrix()`), ascending, with multiplicity.
    /// NetworkX `adjacency_spectrum`.
    ///
    /// Dense: Householder tridiagonalization and the implicit QL iteration, O(n³) time and n²
    /// `Double`s, for graphs of up to a few thousand vertices. `[]` for the empty graph.
    @inlinable
    public func adjacencySpectrum() -> [Double] {
        _spectralAdjacency(nil, numbering: nil).spectrum(.adjacency)
    }

    /// Every eigenvalue of the adjacency matrix A (`adjacencyMatrix()`), ascending, with multiplicity.
    /// NetworkX `adjacency_spectrum`.
    ///
    /// Dense: Householder tridiagonalization and the implicit QL iteration, O(n³) time and n²
    /// `Double`s, for graphs of up to a few thousand vertices. `[]` for the empty graph.
    ///
    /// `weight` gives the weight of the edge at each position, read once per position.
    ///
    /// - Precondition: every weight is finite.
    @inlinable
    public func adjacencySpectrum<W: BinaryInteger>(weight: (Edges.Index) -> W) -> [Double] {
        _spectralAdjacency(_spectralWeights(weight, allowsNegative: true), numbering: nil).spectrum(.adjacency)
    }

    /// Every eigenvalue of the adjacency matrix A (`adjacencyMatrix()`), ascending, with multiplicity.
    /// NetworkX `adjacency_spectrum`.
    ///
    /// Dense: Householder tridiagonalization and the implicit QL iteration, O(n³) time and n²
    /// `Double`s, for graphs of up to a few thousand vertices. `[]` for the empty graph.
    ///
    /// `weight` gives the weight of the edge at each position, read once per position.
    ///
    /// - Precondition: every weight is finite.
    @inlinable
    public func adjacencySpectrum<W: BinaryFloatingPoint>(weight: (Edges.Index) -> W) -> [Double] {
        _spectralAdjacency(_spectralWeights(weight, allowsNegative: true), numbering: nil).spectrum(.adjacency)
    }

    /// Every eigenvalue of the Laplacian L (`laplacianMatrix()`), ascending, with multiplicity: 0
    /// once per component. NetworkX `laplacian_spectrum`.
    ///
    /// Dense: Householder tridiagonalization and the implicit QL iteration, O(n³) time and n²
    /// `Double`s, for graphs of up to a few thousand vertices. `[]` for the empty graph.
    @inlinable
    public func laplacianSpectrum() -> [Double] {
        _spectralAdjacency(nil, numbering: nil).spectrum(.laplacian)
    }

    /// Every eigenvalue of the Laplacian L (`laplacianMatrix()`), ascending, with multiplicity: 0
    /// once per component. NetworkX `laplacian_spectrum`.
    ///
    /// Dense: Householder tridiagonalization and the implicit QL iteration, O(n³) time and n²
    /// `Double`s, for graphs of up to a few thousand vertices. `[]` for the empty graph.
    ///
    /// `weight` gives the weight of the edge at each position, read once per position; a weight of
    /// 0 is no edge.
    ///
    /// - Precondition: every weight is finite and nonnegative.
    @inlinable
    public func laplacianSpectrum<W: BinaryInteger>(weight: (Edges.Index) -> W) -> [Double] {
        _spectralAdjacency(_spectralWeights(weight), numbering: nil).spectrum(.laplacian)
    }

    /// Every eigenvalue of the Laplacian L (`laplacianMatrix()`), ascending, with multiplicity: 0
    /// once per component. NetworkX `laplacian_spectrum`.
    ///
    /// Dense: Householder tridiagonalization and the implicit QL iteration, O(n³) time and n²
    /// `Double`s, for graphs of up to a few thousand vertices. `[]` for the empty graph.
    ///
    /// `weight` gives the weight of the edge at each position, read once per position; a weight of
    /// 0 is no edge.
    ///
    /// - Precondition: every weight is finite and nonnegative.
    @inlinable
    public func laplacianSpectrum<W: BinaryFloatingPoint>(weight: (Edges.Index) -> W) -> [Double] {
        _spectralAdjacency(_spectralWeights(weight), numbering: nil).spectrum(.laplacian)
    }

    /// Every eigenvalue of the normalized Laplacian N (`normalizedLaplacianMatrix()`), ascending,
    /// with multiplicity, in [0, 2]; also the spectrum of the random-walk Laplacian. NetworkX
    /// `normalized_laplacian_spectrum`.
    ///
    /// Dense: Householder tridiagonalization and the implicit QL iteration, O(n³) time and n²
    /// `Double`s, for graphs of up to a few thousand vertices. `[]` for the empty graph.
    @inlinable
    public func normalizedLaplacianSpectrum() -> [Double] {
        _spectralAdjacency(nil, numbering: nil).spectrum(.normalizedLaplacian)
    }

    /// Every eigenvalue of the normalized Laplacian N (`normalizedLaplacianMatrix()`), ascending,
    /// with multiplicity, in [0, 2]; also the spectrum of the random-walk Laplacian. NetworkX
    /// `normalized_laplacian_spectrum`.
    ///
    /// Dense: Householder tridiagonalization and the implicit QL iteration, O(n³) time and n²
    /// `Double`s, for graphs of up to a few thousand vertices. `[]` for the empty graph.
    ///
    /// `weight` gives the weight of the edge at each position, read once per position; a weight of
    /// 0 is no edge.
    ///
    /// - Precondition: every weight is finite and nonnegative.
    @inlinable
    public func normalizedLaplacianSpectrum<W: BinaryInteger>(weight: (Edges.Index) -> W) -> [Double] {
        _spectralAdjacency(_spectralWeights(weight), numbering: nil).spectrum(.normalizedLaplacian)
    }

    /// Every eigenvalue of the normalized Laplacian N (`normalizedLaplacianMatrix()`), ascending,
    /// with multiplicity, in [0, 2]; also the spectrum of the random-walk Laplacian. NetworkX
    /// `normalized_laplacian_spectrum`.
    ///
    /// Dense: Householder tridiagonalization and the implicit QL iteration, O(n³) time and n²
    /// `Double`s, for graphs of up to a few thousand vertices. `[]` for the empty graph.
    ///
    /// `weight` gives the weight of the edge at each position, read once per position; a weight of
    /// 0 is no edge.
    ///
    /// - Precondition: every weight is finite and nonnegative.
    @inlinable
    public func normalizedLaplacianSpectrum<W: BinaryFloatingPoint>(weight: (Edges.Index) -> W) -> [Double] {
        _spectralAdjacency(_spectralWeights(weight), numbering: nil).spectrum(.normalizedLaplacian)
    }

    /// The spectral radius ρ(A), the largest magnitude of an eigenvalue of the adjacency matrix:
    /// for nonnegative weights, the largest eigenvalue (Perron–Frobenius); 0 without edges.
    /// Thick-restart Lanczos on A from a fixed start vector (with −A as well when a weight is
    /// negative), accepting a Ritz pair whose residual is at most `tolerance` times Gershgorin's
    /// bound on |λ|; the dense solver below 64 vertices.
    ///
    /// - Precondition: `tolerance > 0`.
    @inlinable
    public func spectralRadius(tolerance: Double = 1e-8) -> Double {
        precondition(tolerance > 0, "The tolerance is not positive")
        return _spectralAdjacency(nil, numbering: nil).spectralRadius(tolerance: tolerance)
    }

    /// The spectral radius ρ(A), the largest magnitude of an eigenvalue of the adjacency matrix:
    /// for nonnegative weights, the largest eigenvalue (Perron–Frobenius); 0 without edges.
    /// Thick-restart Lanczos on A from a fixed start vector (with −A as well when a weight is
    /// negative), accepting a Ritz pair whose residual is at most `tolerance` times Gershgorin's
    /// bound on |λ|; the dense solver below 64 vertices.
    ///
    /// - Precondition: `tolerance > 0`.
    ///
    /// `weight` gives the weight of the edge at each position, read once per position.
    ///
    /// - Precondition: every weight is finite.
    @inlinable
    public func spectralRadius<W: BinaryInteger>(weight: (Edges.Index) -> W, tolerance: Double = 1e-8) -> Double {
        precondition(tolerance > 0, "The tolerance is not positive")
        return _spectralAdjacency(_spectralWeights(weight, allowsNegative: true), numbering: nil).spectralRadius(tolerance: tolerance)
    }

    /// The spectral radius ρ(A), the largest magnitude of an eigenvalue of the adjacency matrix:
    /// for nonnegative weights, the largest eigenvalue (Perron–Frobenius); 0 without edges.
    /// Thick-restart Lanczos on A from a fixed start vector (with −A as well when a weight is
    /// negative), accepting a Ritz pair whose residual is at most `tolerance` times Gershgorin's
    /// bound on |λ|; the dense solver below 64 vertices.
    ///
    /// - Precondition: `tolerance > 0`.
    ///
    /// `weight` gives the weight of the edge at each position, read once per position.
    ///
    /// - Precondition: every weight is finite.
    @inlinable
    public func spectralRadius<W: BinaryFloatingPoint>(weight: (Edges.Index) -> W, tolerance: Double = 1e-8) -> Double {
        precondition(tolerance > 0, "The tolerance is not positive")
        return _spectralAdjacency(_spectralWeights(weight, allowsNegative: true), numbering: nil).spectralRadius(tolerance: tolerance)
    }
}
