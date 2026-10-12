/// The error an iterative method throws when it spends its iteration limit without meeting its
/// stopping rule: a power iteration (eigenvector and Katz centrality, PageRank, HITS), a Lanczos
/// or conjugate-gradient run, or a QL eigenvalue iteration. Named after Eigen's
/// `ComputationInfo::NoConvergence`; NetworkX raises `PowerIterationFailedConvergence` and SciPy
/// `ArpackNoConvergence` in the same place.
///
/// Each throwing method documents what it counts as an iteration and what its residual measures.
/// The residual is on the scale of the tolerance the method compares it with (the caller's
/// `tolerance`, where it has one), so `residual / tolerance` says how far from converged the method
/// stopped. It may be infinite or NaN when the iteration diverged.
///
/// ```swift
/// do {
///     let scores = try graph.pageRank(maxIterations: 20)
///     use(scores)
/// } catch {
///     print("PageRank stopped after \(error.iterations) iterations at \(error.residual)")
/// }
/// ```
@frozen
public struct NoConvergence: Error, Sendable, Hashable {
    /// The iterations spent before the method gave up.
    public var iterations: Int

    /// The method's convergence measure after its last iteration, which was still above the
    /// tolerance.
    public var residual: Double

    /// An error recording `iterations` and `residual`.
    @inlinable
    public init(iterations: Int, residual: Double) {
        self.iterations = iterations
        self.residual = residual
    }
}

extension NoConvergence: CustomStringConvertible {
    public var description: String {
        "NoConvergence(iterations: \(iterations), residual: \(residual))"
    }
}
