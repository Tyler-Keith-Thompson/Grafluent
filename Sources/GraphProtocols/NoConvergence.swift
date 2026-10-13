/// The error an iterative method throws when it uses up its iteration limit without meeting its
/// stopping rule.
///
/// Power iterations (eigenvector and Katz centrality, PageRank, HITS), Lanczos and
/// conjugate-gradient runs, and QL eigenvalue iterations throw it. Each throwing method documents
/// what it counts as an iteration and what its residual measures. The residual is on the scale of
/// the tolerance the method compares it with, which is the caller's `tolerance` where the method
/// takes one, so `residual / tolerance` says how far from convergence the method stopped. It may
/// be infinite or NaN when the iteration diverged.
///
/// ```swift
/// do throws(NoConvergence) {
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
