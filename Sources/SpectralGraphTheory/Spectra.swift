import GraphProtocols

extension Graph {
    /// Every eigenvalue of the adjacency matrix A (`adjacencyMatrix()`), ascending, with multiplicity.
    ///
    ///
    /// Dense: Householder tridiagonalization and the root-free QL iteration, O(n³) time and n²
    /// `Double`s, for graphs of up to a few thousand vertices. `[]` for the empty graph.
    ///
    /// - Precondition: `maxIterations`, when given, is at least 1.
    /// - Throws: `NoConvergence` after `maxIterations` QL/QR iterations in all (30 n when nil),
    /// with that count and the off-diagonal entry being reduced, relative to the largest entry of
    /// its block. The iteration converges cubically, about two iterations per eigenvalue, so only a
    /// much smaller limit reaches it.
    @inlinable
    public func adjacencySpectrum(maxIterations: Int? = nil) throws(NoConvergence) -> [Double] {
        _checkMaxIterations(maxIterations)
        return try _spectralAdjacency(nil, numbering: nil).spectrum(.adjacency, maxIterations: maxIterations)
    }

    /// Every eigenvalue of the adjacency matrix A (`adjacencyMatrix()`), ascending, with multiplicity.
    ///
    ///
    /// Dense: Householder tridiagonalization and the root-free QL iteration, O(n³) time and n²
    /// `Double`s, for graphs of up to a few thousand vertices. `[]` for the empty graph.
    ///
    /// `weight` gives the weight of the edge at each position, read once per position.
    ///
    /// - Precondition: every weight is finite, and `maxIterations`, when given, is at least 1.
    /// - Throws: `NoConvergence` after `maxIterations` QL/QR iterations in all (30 n when nil),
    /// with that count and the off-diagonal entry being reduced, relative to the largest entry of
    /// its block. The iteration converges cubically, about two iterations per eigenvalue, so only a
    /// much smaller limit reaches it.
    @inlinable
    public func adjacencySpectrum<W: BinaryInteger>(weight: (Edges.Index) -> W, maxIterations: Int? = nil) throws(NoConvergence) -> [Double] {
        _checkMaxIterations(maxIterations)
        return try _spectralAdjacency(_spectralWeights(weight, allowsNegative: true), numbering: nil).spectrum(.adjacency, maxIterations: maxIterations)
    }

    /// Every eigenvalue of the adjacency matrix A (`adjacencyMatrix()`), ascending, with multiplicity.
    ///
    ///
    /// Dense: Householder tridiagonalization and the root-free QL iteration, O(n³) time and n²
    /// `Double`s, for graphs of up to a few thousand vertices. `[]` for the empty graph.
    ///
    /// `weight` gives the weight of the edge at each position, read once per position.
    ///
    /// - Precondition: every weight is finite, and `maxIterations`, when given, is at least 1.
    /// - Throws: `NoConvergence` after `maxIterations` QL/QR iterations in all (30 n when nil),
    /// with that count and the off-diagonal entry being reduced, relative to the largest entry of
    /// its block. The iteration converges cubically, about two iterations per eigenvalue, so only a
    /// much smaller limit reaches it.
    @inlinable
    public func adjacencySpectrum<W: BinaryFloatingPoint>(weight: (Edges.Index) -> W, maxIterations: Int? = nil) throws(NoConvergence) -> [Double] {
        _checkMaxIterations(maxIterations)
        return try _spectralAdjacency(_spectralWeights(weight, allowsNegative: true), numbering: nil).spectrum(.adjacency, maxIterations: maxIterations)
    }

    /// Every eigenvalue of the Laplacian L (`laplacianMatrix()`), ascending, with multiplicity: 0
    /// once per component.
    ///
    /// Dense: Householder tridiagonalization and the root-free QL iteration, O(n³) time and n²
    /// `Double`s, for graphs of up to a few thousand vertices. `[]` for the empty graph.
    ///
    /// - Precondition: `maxIterations`, when given, is at least 1.
    /// - Throws: `NoConvergence` after `maxIterations` QL/QR iterations in all (30 n when nil),
    /// with that count and the off-diagonal entry being reduced, relative to the largest entry of
    /// its block. The iteration converges cubically, about two iterations per eigenvalue, so only a
    /// much smaller limit reaches it.
    @inlinable
    public func laplacianSpectrum(maxIterations: Int? = nil) throws(NoConvergence) -> [Double] {
        _checkMaxIterations(maxIterations)
        return try _spectralAdjacency(nil, numbering: nil).spectrum(.laplacian, maxIterations: maxIterations)
    }

    /// Every eigenvalue of the Laplacian L (`laplacianMatrix()`), ascending, with multiplicity: 0
    /// once per component.
    ///
    /// Dense: Householder tridiagonalization and the root-free QL iteration, O(n³) time and n²
    /// `Double`s, for graphs of up to a few thousand vertices. `[]` for the empty graph.
    ///
    /// `weight` gives the weight of the edge at each position, read once per position; a weight of
    /// 0 is no edge.
    ///
    /// - Precondition: every weight is finite and nonnegative, and `maxIterations`, when given, is
    ///   at least 1.
    /// - Throws: `NoConvergence` after `maxIterations` QL/QR iterations in all (30 n when nil),
    /// with that count and the off-diagonal entry being reduced, relative to the largest entry of
    /// its block. The iteration converges cubically, about two iterations per eigenvalue, so only a
    /// much smaller limit reaches it.
    @inlinable
    public func laplacianSpectrum<W: BinaryInteger>(weight: (Edges.Index) -> W, maxIterations: Int? = nil) throws(NoConvergence) -> [Double] {
        _checkMaxIterations(maxIterations)
        return try _spectralAdjacency(_spectralWeights(weight), numbering: nil).spectrum(.laplacian, maxIterations: maxIterations)
    }

    /// Every eigenvalue of the Laplacian L (`laplacianMatrix()`), ascending, with multiplicity: 0
    /// once per component.
    ///
    /// Dense: Householder tridiagonalization and the root-free QL iteration, O(n³) time and n²
    /// `Double`s, for graphs of up to a few thousand vertices. `[]` for the empty graph.
    ///
    /// `weight` gives the weight of the edge at each position, read once per position; a weight of
    /// 0 is no edge.
    ///
    /// - Precondition: every weight is finite and nonnegative, and `maxIterations`, when given, is
    ///   at least 1.
    /// - Throws: `NoConvergence` after `maxIterations` QL/QR iterations in all (30 n when nil),
    /// with that count and the off-diagonal entry being reduced, relative to the largest entry of
    /// its block. The iteration converges cubically, about two iterations per eigenvalue, so only a
    /// much smaller limit reaches it.
    @inlinable
    public func laplacianSpectrum<W: BinaryFloatingPoint>(weight: (Edges.Index) -> W, maxIterations: Int? = nil) throws(NoConvergence) -> [Double] {
        _checkMaxIterations(maxIterations)
        return try _spectralAdjacency(_spectralWeights(weight), numbering: nil).spectrum(.laplacian, maxIterations: maxIterations)
    }

    /// Every eigenvalue of the normalized Laplacian N (`normalizedLaplacianMatrix()`), ascending,
    /// with multiplicity, in [0, 2]; also the spectrum of the random-walk Laplacian.
    ///
    /// Dense: Householder tridiagonalization and the root-free QL iteration, O(n³) time and n²
    /// `Double`s, for graphs of up to a few thousand vertices. `[]` for the empty graph.
    ///
    /// - Precondition: `maxIterations`, when given, is at least 1.
    /// - Throws: `NoConvergence` after `maxIterations` QL/QR iterations in all (30 n when nil),
    /// with that count and the off-diagonal entry being reduced, relative to the largest entry of
    /// its block. The iteration converges cubically, about two iterations per eigenvalue, so only a
    /// much smaller limit reaches it.
    @inlinable
    public func normalizedLaplacianSpectrum(maxIterations: Int? = nil) throws(NoConvergence) -> [Double] {
        _checkMaxIterations(maxIterations)
        return try _spectralAdjacency(nil, numbering: nil).spectrum(.normalizedLaplacian, maxIterations: maxIterations)
    }

    /// Every eigenvalue of the normalized Laplacian N (`normalizedLaplacianMatrix()`), ascending,
    /// with multiplicity, in [0, 2]; also the spectrum of the random-walk Laplacian.
    ///
    /// Dense: Householder tridiagonalization and the root-free QL iteration, O(n³) time and n²
    /// `Double`s, for graphs of up to a few thousand vertices. `[]` for the empty graph.
    ///
    /// `weight` gives the weight of the edge at each position, read once per position; a weight of
    /// 0 is no edge.
    ///
    /// - Precondition: every weight is finite and nonnegative, and `maxIterations`, when given, is
    ///   at least 1.
    /// - Throws: `NoConvergence` after `maxIterations` QL/QR iterations in all (30 n when nil),
    /// with that count and the off-diagonal entry being reduced, relative to the largest entry of
    /// its block. The iteration converges cubically, about two iterations per eigenvalue, so only a
    /// much smaller limit reaches it.
    @inlinable
    public func normalizedLaplacianSpectrum<W: BinaryInteger>(weight: (Edges.Index) -> W, maxIterations: Int? = nil) throws(NoConvergence) -> [Double] {
        _checkMaxIterations(maxIterations)
        return try _spectralAdjacency(_spectralWeights(weight), numbering: nil).spectrum(.normalizedLaplacian, maxIterations: maxIterations)
    }

    /// Every eigenvalue of the normalized Laplacian N (`normalizedLaplacianMatrix()`), ascending,
    /// with multiplicity, in [0, 2]; also the spectrum of the random-walk Laplacian.
    ///
    /// Dense: Householder tridiagonalization and the root-free QL iteration, O(n³) time and n²
    /// `Double`s, for graphs of up to a few thousand vertices. `[]` for the empty graph.
    ///
    /// `weight` gives the weight of the edge at each position, read once per position; a weight of
    /// 0 is no edge.
    ///
    /// - Precondition: every weight is finite and nonnegative, and `maxIterations`, when given, is
    ///   at least 1.
    /// - Throws: `NoConvergence` after `maxIterations` QL/QR iterations in all (30 n when nil),
    /// with that count and the off-diagonal entry being reduced, relative to the largest entry of
    /// its block. The iteration converges cubically, about two iterations per eigenvalue, so only a
    /// much smaller limit reaches it.
    @inlinable
    public func normalizedLaplacianSpectrum<W: BinaryFloatingPoint>(weight: (Edges.Index) -> W, maxIterations: Int? = nil) throws(NoConvergence) -> [Double] {
        _checkMaxIterations(maxIterations)
        return try _spectralAdjacency(_spectralWeights(weight), numbering: nil).spectrum(.normalizedLaplacian, maxIterations: maxIterations)
    }

    /// The spectral radius ρ(A), the largest magnitude of an eigenvalue of the adjacency matrix:
    /// for nonnegative weights, the largest eigenvalue (Perron–Frobenius); 0 without edges.
    /// Thick-restart Lanczos on A from a fixed start vector (with −A as well when a weight is
    /// negative), the top Ritz pair tested every 5 steps, accepting it when its residual is at
    /// most `tolerance` · ρ (relative); the dense solver below 64 vertices. O((n + m) · products)
    /// time, 31 n `Double`s; the operator shares the graph's rows.
    ///
    /// - Precondition: `tolerance > 0`, and `maxIterations`, when given, is at least 1.
    /// - Throws: `NoConvergence` when a Lanczos run (on A, then on −A when a weight is negative)
    ///   spends `maxIterations` matrix–vector products (20,000 + 20√n when nil) without converging,
    ///   with the products spent and the Ritz residual relative to ρ. From 5,000 vertices a
    ///   polynomial-filtered step counts 10 products, so the count may pass the limit by up to 10.
    ///   Below 64 vertices the dense solver answers and `maxIterations` is unused. Only a tolerance
    ///   below rounding has reached the default limit in the measurements.
    @inlinable
    public func spectralRadius(tolerance: Double = 1e-8, maxIterations: Int? = nil) throws(NoConvergence) -> Double {
        precondition(tolerance > 0, "The tolerance is not positive")
        _checkMaxIterations(maxIterations)
        return try _spectralAdjacency(nil, numbering: nil).spectralRadius(tolerance: tolerance, maxIterations: maxIterations)
    }

    /// The spectral radius ρ(A), the largest magnitude of an eigenvalue of the adjacency matrix:
    /// for nonnegative weights, the largest eigenvalue (Perron–Frobenius); 0 without edges.
    /// Thick-restart Lanczos on A from a fixed start vector (with −A as well when a weight is
    /// negative), the top Ritz pair tested every 5 steps, accepting it when its residual is at
    /// most `tolerance` · ρ (relative); the dense solver below 64 vertices. O((n + m) · products)
    /// time, 31 n `Double`s; the operator shares the graph's rows.
    ///
    /// `weight` gives the weight of the edge at each position, read once per position.
    ///
    /// - Precondition: `tolerance > 0`, every weight is finite, and `maxIterations`, when given, is
    ///   at least 1.
    /// - Throws: `NoConvergence` when a Lanczos run (on A, then on −A when a weight is negative)
    ///   spends `maxIterations` matrix–vector products (20,000 + 20√n when nil) without converging,
    ///   with the products spent and the Ritz residual relative to ρ. From 5,000 vertices a
    ///   polynomial-filtered step counts 10 products, so the count may pass the limit by up to 10.
    ///   Below 64 vertices the dense solver answers and `maxIterations` is unused. Only a tolerance
    ///   below rounding has reached the default limit in the measurements.
    @inlinable
    public func spectralRadius<W: BinaryInteger>(weight: (Edges.Index) -> W, tolerance: Double = 1e-8, maxIterations: Int? = nil) throws(NoConvergence) -> Double {
        precondition(tolerance > 0, "The tolerance is not positive")
        _checkMaxIterations(maxIterations)
        return try _spectralAdjacency(_spectralWeights(weight, allowsNegative: true), numbering: nil).spectralRadius(tolerance: tolerance, maxIterations: maxIterations)
    }

    /// The spectral radius ρ(A), the largest magnitude of an eigenvalue of the adjacency matrix:
    /// for nonnegative weights, the largest eigenvalue (Perron–Frobenius); 0 without edges.
    /// Thick-restart Lanczos on A from a fixed start vector (with −A as well when a weight is
    /// negative), the top Ritz pair tested every 5 steps, accepting it when its residual is at
    /// most `tolerance` · ρ (relative); the dense solver below 64 vertices. O((n + m) · products)
    /// time, 31 n `Double`s; the operator shares the graph's rows.
    ///
    /// `weight` gives the weight of the edge at each position, read once per position.
    ///
    /// - Precondition: `tolerance > 0`, every weight is finite, and `maxIterations`, when given, is
    ///   at least 1.
    /// - Throws: `NoConvergence` when a Lanczos run (on A, then on −A when a weight is negative)
    ///   spends `maxIterations` matrix–vector products (20,000 + 20√n when nil) without converging,
    ///   with the products spent and the Ritz residual relative to ρ. From 5,000 vertices a
    ///   polynomial-filtered step counts 10 products, so the count may pass the limit by up to 10.
    ///   Below 64 vertices the dense solver answers and `maxIterations` is unused. Only a tolerance
    ///   below rounding has reached the default limit in the measurements.
    @inlinable
    public func spectralRadius<W: BinaryFloatingPoint>(weight: (Edges.Index) -> W, tolerance: Double = 1e-8, maxIterations: Int? = nil) throws(NoConvergence) -> Double {
        precondition(tolerance > 0, "The tolerance is not positive")
        _checkMaxIterations(maxIterations)
        return try _spectralAdjacency(_spectralWeights(weight, allowsNegative: true), numbering: nil).spectralRadius(tolerance: tolerance, maxIterations: maxIterations)
    }
}
