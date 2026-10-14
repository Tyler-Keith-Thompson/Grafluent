import GraphProtocols

/// Eigenpairs of a graph matrix at one end of its spectrum: the eigenvalues, from that end
/// (ascending for the smallest, descending for the largest), and an orthonormal eigenvector for
/// each, with one entry per vertex.
///
/// **Sign.** Each eigenvector has the canonical sign of `FiedlerVector`: the first entry, in index
/// order, whose magnitude is at least 10⁻⁴ of the largest is positive.
///
/// **Multiple eigenvalues.** For an eigenvalue of multiplicity greater than one, the vectors are
/// some orthonormal basis of the part of its eigenspace they cover: deterministic, but which basis
/// is not part of the contract. Where the asked-for count ends inside a multiple eigenvalue, which
/// of its vectors are included is not part of the contract either.
@frozen
public struct Eigenpairs<G: Graph> {
    @usableFromInline let _graph: G
    /// Vertex numbers when the graph has no vertex indices.
    @usableFromInline let _numbers: [G.Vertex: Int]?
    /// Eigenvector i at i · vertexCount.
    @usableFromInline let _vectors: [Double]

    /// The eigenvalues, from the end asked for: ascending for the smallest, descending for the
    /// largest.
    public let eigenvalues: [Double]

    @inlinable
    init(_ graph: G, numbers: [G.Vertex: Int]?, eigenvalues: [Double], vectors: [Double]) {
        _graph = graph
        _numbers = numbers
        self.eigenvalues = eigenvalues
        _vectors = vectors
    }

    /// The number of eigenpairs.
    @inlinable
    public var count: Int { eigenvalues.count }

    /// The eigenvector of `eigenvalues[position]`, by vertex index (in `vertices` order): unit
    /// length, orthogonal to the others, with the canonical sign. O(n).
    ///
    /// - Precondition: `position` is in `0..<count`.
    @inlinable
    public func eigenvector(at position: Int) -> [Double] {
        precondition(position >= 0 && position < eigenvalues.count, "Eigenpair position out of range")
        let n = _vectors.count / eigenvalues.count
        return Array(_vectors[position * n ..< (position + 1) * n])
    }

    /// The entry of `vertex` in each eigenvector, in eigenvalue order: the vertex's coordinates in
    /// the eigenvectors. O(count) after looking it up.
    ///
    /// - Precondition: `vertex` is a vertex of the graph.
    @inlinable
    public func eigenvectorEntries(of vertex: G.Vertex) -> [Double] {
        if let _numbers {
            guard let v = _numbers[vertex] else { preconditionFailure("The vertex is not in the graph") }
            return eigenvectorEntries(ofIndex: v)
        }
        return eigenvectorEntries(ofIndex: _graph._requiredVertexIndex(of: vertex, "The vertex is not in the graph"))
    }

    /// The entry of `vertex` in each eigenvector, throwing instead of trapping when it is not a
    /// vertex of the graph.
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not a vertex of the graph.
    @inlinable
    public func eigenvectorEntries(checked vertex: G.Vertex) throws(VertexNotFound) -> [Double] {
        if let _numbers {
            guard let v = _numbers[vertex] else { throw VertexNotFound() }
            return eigenvectorEntries(ofIndex: v)
        }
        guard _graph.contains(vertex) else { throw VertexNotFound() }
        return eigenvectorEntries(of: vertex)
    }

    /// The entry of the vertex at `index` (its vertex index, or its position in `vertices` when
    /// the graph has no vertex indices) in each eigenvector.
    ///
    /// - Precondition: `index` is in `0..<vertexCount`.
    @inlinable
    public func eigenvectorEntries(ofIndex index: Int) -> [Double] {
        let k = eigenvalues.count
        let n = k == 0 ? _graph.vertexCount : _vectors.count / k
        precondition(index >= 0 && index < n, "Vertex index out of range")
        return (0 ..< k).map { _vectors[$0 * n + index] }
    }
}

extension Eigenpairs: Sendable where G: Sendable, G.Vertex: Sendable {}

extension Graph {
    /// The k smallest eigenvalues of the adjacency matrix A (`adjacencyMatrix()`), k = `smallest`,
    /// ascending, each with a unit eigenvector (see `Eigenpairs`).
    ///
    /// Thick-restart Lanczos (Wu–Simon) with full reorthogonalization and locking on −A, from a
    /// fixed start vector; once k pairs are found, a run on the complement of their vectors checks
    /// that no copy of a multiple eigenvalue was missed. A Ritz pair is accepted when its residual
    /// is at most `tolerance` · max(|λ|, s/1000), s Gershgorin's bound on the spectrum; the vectors
    /// are then rotated by Rayleigh–Ritz on M, whose values are returned. The dense solver below 64
    /// vertices, or when k is a third of them or more.
    /// O((n + m) · products + n · k²) time, O(n · k) `Double`s for the vectors and n · max(30, 2k +
    /// 10) for the basis.
    ///
    /// - Parameters:
    ///   - smallest: The number of eigenpairs, in `0...vertexCount`.
    ///   - tolerance: The residual a Ritz pair must reach, relative as described above.
    ///   - maxIterations: The matrix–vector products each Lanczos run may spend; nil for 20,000 +
    ///     20√n.
    /// - Returns: The eigenpairs, in order from that end of the spectrum.
    /// - Precondition: `smallest` is in `0...vertexCount`, `tolerance > 0`, and `maxIterations`,
    ///   when given, is at least 1.
    /// - Throws: `NoConvergence` when a Lanczos run spends `maxIterations` products without
    ///   converging, with the products spent and the largest Ritz residual on the tolerance's
    ///   scale. The dense solver throws as `adjacencySpectrum` does.
    @inlinable
    public func adjacencyEigenpairs(smallest: Int, tolerance: Double = 1e-8, maxIterations: Int? = nil) throws(NoConvergence) -> Eigenpairs<Self> {
        precondition(tolerance > 0, "The tolerance is not positive")
        _checkMaxIterations(maxIterations)
        let weights: [Double]? = nil
        let numbering = _vertexNumbering()
        let (values, vectors) = try _spectralAdjacency(weights, numbering: numbering).eigenpairs(.adjacency, count: smallest, largest: false, tolerance: tolerance, maxIterations: maxIterations)
        return Eigenpairs(self, numbers: numbering?.numbers, eigenvalues: values, vectors: vectors)
    }

    /// The k smallest eigenvalues of the adjacency matrix A (`adjacencyMatrix()`), k = `smallest`,
    /// ascending, each with a unit eigenvector (see `Eigenpairs`).
    ///
    /// Thick-restart Lanczos (Wu–Simon) with full reorthogonalization and locking on −A, from a
    /// fixed start vector; once k pairs are found, a run on the complement of their vectors checks
    /// that no copy of a multiple eigenvalue was missed. A Ritz pair is accepted when its residual
    /// is at most `tolerance` · max(|λ|, s/1000), s Gershgorin's bound on the spectrum; the vectors
    /// are then rotated by Rayleigh–Ritz on M, whose values are returned. The dense solver below 64
    /// vertices, or when k is a third of them or more.
    /// O((n + m) · products + n · k²) time, O(n · k) `Double`s for the vectors and n · max(30, 2k +
    /// 10) for the basis.
    ///
    /// `weight` gives the weight of the edge at each position, read once per position.
    ///
    /// - Parameters:
    ///   - smallest: The number of eigenpairs, in `0...vertexCount`.
    ///   - weight: The weight of the edge at each position.
    ///   - tolerance: The residual a Ritz pair must reach, relative as described above.
    ///   - maxIterations: The matrix–vector products each Lanczos run may spend; nil for 20,000 +
    ///     20√n.
    /// - Returns: The eigenpairs, in order from that end of the spectrum.
    /// - Precondition: `smallest` is in `0...vertexCount`, `tolerance > 0`, every weight is finite,
    ///   and `maxIterations`, when given, is at least 1.
    /// - Throws: `NoConvergence` when a Lanczos run spends `maxIterations` products without
    ///   converging, with the products spent and the largest Ritz residual on the tolerance's
    ///   scale. The dense solver throws as `adjacencySpectrum` does.
    @inlinable
    public func adjacencyEigenpairs<W: BinaryInteger>(smallest: Int, weight: (Edges.Index) -> W, tolerance: Double = 1e-8, maxIterations: Int? = nil) throws(NoConvergence) -> Eigenpairs<Self> {
        precondition(tolerance > 0, "The tolerance is not positive")
        _checkMaxIterations(maxIterations)
        let weights = _spectralWeights(weight, allowsNegative: true)
        let numbering = _vertexNumbering()
        let (values, vectors) = try _spectralAdjacency(weights, numbering: numbering).eigenpairs(.adjacency, count: smallest, largest: false, tolerance: tolerance, maxIterations: maxIterations)
        return Eigenpairs(self, numbers: numbering?.numbers, eigenvalues: values, vectors: vectors)
    }

    /// The k smallest eigenvalues of the adjacency matrix A (`adjacencyMatrix()`), k = `smallest`,
    /// ascending, each with a unit eigenvector (see `Eigenpairs`).
    ///
    /// Thick-restart Lanczos (Wu–Simon) with full reorthogonalization and locking on −A, from a
    /// fixed start vector; once k pairs are found, a run on the complement of their vectors checks
    /// that no copy of a multiple eigenvalue was missed. A Ritz pair is accepted when its residual
    /// is at most `tolerance` · max(|λ|, s/1000), s Gershgorin's bound on the spectrum; the vectors
    /// are then rotated by Rayleigh–Ritz on M, whose values are returned. The dense solver below 64
    /// vertices, or when k is a third of them or more.
    /// O((n + m) · products + n · k²) time, O(n · k) `Double`s for the vectors and n · max(30, 2k +
    /// 10) for the basis.
    ///
    /// `weight` gives the weight of the edge at each position, read once per position.
    ///
    /// - Parameters:
    ///   - smallest: The number of eigenpairs, in `0...vertexCount`.
    ///   - weight: The weight of the edge at each position.
    ///   - tolerance: The residual a Ritz pair must reach, relative as described above.
    ///   - maxIterations: The matrix–vector products each Lanczos run may spend; nil for 20,000 +
    ///     20√n.
    /// - Returns: The eigenpairs, in order from that end of the spectrum.
    /// - Precondition: `smallest` is in `0...vertexCount`, `tolerance > 0`, every weight is finite,
    ///   and `maxIterations`, when given, is at least 1.
    /// - Throws: `NoConvergence` when a Lanczos run spends `maxIterations` products without
    ///   converging, with the products spent and the largest Ritz residual on the tolerance's
    ///   scale. The dense solver throws as `adjacencySpectrum` does.
    @inlinable
    public func adjacencyEigenpairs<W: BinaryFloatingPoint>(smallest: Int, weight: (Edges.Index) -> W, tolerance: Double = 1e-8, maxIterations: Int? = nil) throws(NoConvergence) -> Eigenpairs<Self> {
        precondition(tolerance > 0, "The tolerance is not positive")
        _checkMaxIterations(maxIterations)
        let weights = _spectralWeights(weight, allowsNegative: true)
        let numbering = _vertexNumbering()
        let (values, vectors) = try _spectralAdjacency(weights, numbering: numbering).eigenpairs(.adjacency, count: smallest, largest: false, tolerance: tolerance, maxIterations: maxIterations)
        return Eigenpairs(self, numbers: numbering?.numbers, eigenvalues: values, vectors: vectors)
    }

    /// The k largest eigenvalues of the adjacency matrix A (`adjacencyMatrix()`), k = `largest`,
    /// descending, each with a unit eigenvector (see `Eigenpairs`).
    ///
    /// Thick-restart Lanczos (Wu–Simon) with full reorthogonalization and locking on M, from a
    /// fixed start vector; once k pairs are found, a run on the complement of their vectors checks
    /// that no copy of a multiple eigenvalue was missed. A Ritz pair is accepted when its residual
    /// is at most `tolerance` · max(|λ|, s/1000), s Gershgorin's bound on the spectrum; the vectors
    /// are then rotated by Rayleigh–Ritz on M, whose values are returned. The dense solver below 64
    /// vertices, or when k is a third of them or more.
    /// O((n + m) · products + n · k²) time, O(n · k) `Double`s for the vectors and n · max(30, 2k +
    /// 10) for the basis.
    ///
    /// - Parameters:
    ///   - largest: The number of eigenpairs, in `0...vertexCount`.
    ///   - tolerance: The residual a Ritz pair must reach, relative as described above.
    ///   - maxIterations: The matrix–vector products each Lanczos run may spend; nil for 20,000 +
    ///     20√n.
    /// - Returns: The eigenpairs, in order from that end of the spectrum.
    /// - Precondition: `largest` is in `0...vertexCount`, `tolerance > 0`, and `maxIterations`,
    ///   when given, is at least 1.
    /// - Throws: `NoConvergence` when a Lanczos run spends `maxIterations` products without
    ///   converging, with the products spent and the largest Ritz residual on the tolerance's
    ///   scale. The dense solver throws as `adjacencySpectrum` does.
    @inlinable
    public func adjacencyEigenpairs(largest: Int, tolerance: Double = 1e-8, maxIterations: Int? = nil) throws(NoConvergence) -> Eigenpairs<Self> {
        precondition(tolerance > 0, "The tolerance is not positive")
        _checkMaxIterations(maxIterations)
        let weights: [Double]? = nil
        let numbering = _vertexNumbering()
        let (values, vectors) = try _spectralAdjacency(weights, numbering: numbering).eigenpairs(.adjacency, count: largest, largest: true, tolerance: tolerance, maxIterations: maxIterations)
        return Eigenpairs(self, numbers: numbering?.numbers, eigenvalues: values, vectors: vectors)
    }

    /// The k largest eigenvalues of the adjacency matrix A (`adjacencyMatrix()`), k = `largest`,
    /// descending, each with a unit eigenvector (see `Eigenpairs`).
    ///
    /// Thick-restart Lanczos (Wu–Simon) with full reorthogonalization and locking on M, from a
    /// fixed start vector; once k pairs are found, a run on the complement of their vectors checks
    /// that no copy of a multiple eigenvalue was missed. A Ritz pair is accepted when its residual
    /// is at most `tolerance` · max(|λ|, s/1000), s Gershgorin's bound on the spectrum; the vectors
    /// are then rotated by Rayleigh–Ritz on M, whose values are returned. The dense solver below 64
    /// vertices, or when k is a third of them or more.
    /// O((n + m) · products + n · k²) time, O(n · k) `Double`s for the vectors and n · max(30, 2k +
    /// 10) for the basis.
    ///
    /// `weight` gives the weight of the edge at each position, read once per position.
    ///
    /// - Parameters:
    ///   - largest: The number of eigenpairs, in `0...vertexCount`.
    ///   - weight: The weight of the edge at each position.
    ///   - tolerance: The residual a Ritz pair must reach, relative as described above.
    ///   - maxIterations: The matrix–vector products each Lanczos run may spend; nil for 20,000 +
    ///     20√n.
    /// - Returns: The eigenpairs, in order from that end of the spectrum.
    /// - Precondition: `largest` is in `0...vertexCount`, `tolerance > 0`, every weight is finite,
    ///   and `maxIterations`, when given, is at least 1.
    /// - Throws: `NoConvergence` when a Lanczos run spends `maxIterations` products without
    ///   converging, with the products spent and the largest Ritz residual on the tolerance's
    ///   scale. The dense solver throws as `adjacencySpectrum` does.
    @inlinable
    public func adjacencyEigenpairs<W: BinaryInteger>(largest: Int, weight: (Edges.Index) -> W, tolerance: Double = 1e-8, maxIterations: Int? = nil) throws(NoConvergence) -> Eigenpairs<Self> {
        precondition(tolerance > 0, "The tolerance is not positive")
        _checkMaxIterations(maxIterations)
        let weights = _spectralWeights(weight, allowsNegative: true)
        let numbering = _vertexNumbering()
        let (values, vectors) = try _spectralAdjacency(weights, numbering: numbering).eigenpairs(.adjacency, count: largest, largest: true, tolerance: tolerance, maxIterations: maxIterations)
        return Eigenpairs(self, numbers: numbering?.numbers, eigenvalues: values, vectors: vectors)
    }

    /// The k largest eigenvalues of the adjacency matrix A (`adjacencyMatrix()`), k = `largest`,
    /// descending, each with a unit eigenvector (see `Eigenpairs`).
    ///
    /// Thick-restart Lanczos (Wu–Simon) with full reorthogonalization and locking on M, from a
    /// fixed start vector; once k pairs are found, a run on the complement of their vectors checks
    /// that no copy of a multiple eigenvalue was missed. A Ritz pair is accepted when its residual
    /// is at most `tolerance` · max(|λ|, s/1000), s Gershgorin's bound on the spectrum; the vectors
    /// are then rotated by Rayleigh–Ritz on M, whose values are returned. The dense solver below 64
    /// vertices, or when k is a third of them or more.
    /// O((n + m) · products + n · k²) time, O(n · k) `Double`s for the vectors and n · max(30, 2k +
    /// 10) for the basis.
    ///
    /// `weight` gives the weight of the edge at each position, read once per position.
    ///
    /// - Parameters:
    ///   - largest: The number of eigenpairs, in `0...vertexCount`.
    ///   - weight: The weight of the edge at each position.
    ///   - tolerance: The residual a Ritz pair must reach, relative as described above.
    ///   - maxIterations: The matrix–vector products each Lanczos run may spend; nil for 20,000 +
    ///     20√n.
    /// - Returns: The eigenpairs, in order from that end of the spectrum.
    /// - Precondition: `largest` is in `0...vertexCount`, `tolerance > 0`, every weight is finite,
    ///   and `maxIterations`, when given, is at least 1.
    /// - Throws: `NoConvergence` when a Lanczos run spends `maxIterations` products without
    ///   converging, with the products spent and the largest Ritz residual on the tolerance's
    ///   scale. The dense solver throws as `adjacencySpectrum` does.
    @inlinable
    public func adjacencyEigenpairs<W: BinaryFloatingPoint>(largest: Int, weight: (Edges.Index) -> W, tolerance: Double = 1e-8, maxIterations: Int? = nil) throws(NoConvergence) -> Eigenpairs<Self> {
        precondition(tolerance > 0, "The tolerance is not positive")
        _checkMaxIterations(maxIterations)
        let weights = _spectralWeights(weight, allowsNegative: true)
        let numbering = _vertexNumbering()
        let (values, vectors) = try _spectralAdjacency(weights, numbering: numbering).eigenpairs(.adjacency, count: largest, largest: true, tolerance: tolerance, maxIterations: maxIterations)
        return Eigenpairs(self, numbers: numbering?.numbers, eigenvalues: values, vectors: vectors)
    }

    /// The k smallest eigenvalues of the Laplacian L (`laplacianMatrix()`), k = `smallest`,
    /// ascending, each with a unit eigenvector (see `Eigenpairs`).
    ///
    /// Component by component: each component's null vector first (eigenvalue 0, components in
    /// order of their least vertex), then the smallest positive eigenvalues of the components
    /// merged. On a component of at least 64 vertices, thick-restart Lanczos (Wu–Simon) with full
    /// reorthogonalization and locking, the null vector projected out, from a fixed start vector:
    /// on σI − M (σ Gershgorin's bound) while σ/λ₂ is moderate, else on M⁺ by shift-invert, each
    /// product a conjugate-gradient solve with L grounded at the vertex of largest degree. A Ritz
    /// pair is accepted when its residual is at most `tolerance` · λ, relative to itself as for
    /// `algebraicConnectivity`; the vectors found are then rotated by Rayleigh–Ritz on M, and each
    /// value is its vector's Rayleigh quotient, a sum over edges. The dense solver on a smaller
    /// component, or when k is a third of it or more.
    /// O((n + m) · products + n · k²) time, O(n · k) `Double`s for the vectors and n · max(30, 2k +
    /// 10) for the basis.
    ///
    /// - Parameters:
    ///   - smallest: The number of eigenpairs, in `0...vertexCount`.
    ///   - tolerance: The residual a Ritz pair must reach, relative as described above.
    ///   - maxIterations: The matrix–vector products each Lanczos run may spend; nil for the limits
    ///     under Throws.
    /// - Returns: The eigenpairs, in order from that end of the spectrum.
    /// - Precondition: `smallest` is in `0...vertexCount`, `tolerance > 0`, and `maxIterations`,
    ///   when given, is at least 1.
    /// - Throws: `NoConvergence` when a Lanczos run by shift-invert spends `maxIterations` products
    ///   (1,000 when nil), or a conjugate-gradient solve inside it 20,000 + 2n iterations, without
    ///   converging. A run on σI − M hands over to shift-invert rather than throwing, after 4,000 +
    ///   20√n products or `maxIterations`, whichever is smaller. The dense solver throws as
    ///   `laplacianSpectrum` does.
    @inlinable
    public func laplacianEigenpairs(smallest: Int, tolerance: Double = 1e-8, maxIterations: Int? = nil) throws(NoConvergence) -> Eigenpairs<Self> {
        precondition(tolerance > 0, "The tolerance is not positive")
        _checkMaxIterations(maxIterations)
        let weights: [Double]? = nil
        let numbering = _vertexNumbering()
        let (values, vectors) = try _spectralAdjacency(weights, numbering: numbering).eigenpairs(.laplacian, count: smallest, largest: false, tolerance: tolerance, maxIterations: maxIterations)
        return Eigenpairs(self, numbers: numbering?.numbers, eigenvalues: values, vectors: vectors)
    }

    /// The k smallest eigenvalues of the Laplacian L (`laplacianMatrix()`), k = `smallest`,
    /// ascending, each with a unit eigenvector (see `Eigenpairs`).
    ///
    /// Component by component: each component's null vector first (eigenvalue 0, components in
    /// order of their least vertex), then the smallest positive eigenvalues of the components
    /// merged. On a component of at least 64 vertices, thick-restart Lanczos (Wu–Simon) with full
    /// reorthogonalization and locking, the null vector projected out, from a fixed start vector:
    /// on σI − M (σ Gershgorin's bound) while σ/λ₂ is moderate, else on M⁺ by shift-invert, each
    /// product a conjugate-gradient solve with L grounded at the vertex of largest degree. A Ritz
    /// pair is accepted when its residual is at most `tolerance` · λ, relative to itself as for
    /// `algebraicConnectivity`; the vectors found are then rotated by Rayleigh–Ritz on M, and each
    /// value is its vector's Rayleigh quotient, a sum over edges. The dense solver on a smaller
    /// component, or when k is a third of it or more.
    /// O((n + m) · products + n · k²) time, O(n · k) `Double`s for the vectors and n · max(30, 2k +
    /// 10) for the basis.
    ///
    /// `weight` gives the weight of the edge at each position, read once per position; a weight of
    /// 0 is no edge.
    ///
    /// - Parameters:
    ///   - smallest: The number of eigenpairs, in `0...vertexCount`.
    ///   - weight: The weight of the edge at each position.
    ///   - tolerance: The residual a Ritz pair must reach, relative as described above.
    ///   - maxIterations: The matrix–vector products each Lanczos run may spend; nil for the limits
    ///     under Throws.
    /// - Returns: The eigenpairs, in order from that end of the spectrum.
    /// - Precondition: `smallest` is in `0...vertexCount`, `tolerance > 0`, every weight is finite
    ///   and nonnegative, and `maxIterations`, when given, is at least 1.
    /// - Throws: `NoConvergence` when a Lanczos run by shift-invert spends `maxIterations` products
    ///   (1,000 when nil), or a conjugate-gradient solve inside it 20,000 + 2n iterations, without
    ///   converging. A run on σI − M hands over to shift-invert rather than throwing, after 4,000 +
    ///   20√n products or `maxIterations`, whichever is smaller. The dense solver throws as
    ///   `laplacianSpectrum` does.
    @inlinable
    public func laplacianEigenpairs<W: BinaryInteger>(smallest: Int, weight: (Edges.Index) -> W, tolerance: Double = 1e-8, maxIterations: Int? = nil) throws(NoConvergence) -> Eigenpairs<Self> {
        precondition(tolerance > 0, "The tolerance is not positive")
        _checkMaxIterations(maxIterations)
        let weights = _spectralWeights(weight)
        let numbering = _vertexNumbering()
        let (values, vectors) = try _spectralAdjacency(weights, numbering: numbering).eigenpairs(.laplacian, count: smallest, largest: false, tolerance: tolerance, maxIterations: maxIterations)
        return Eigenpairs(self, numbers: numbering?.numbers, eigenvalues: values, vectors: vectors)
    }

    /// The k smallest eigenvalues of the Laplacian L (`laplacianMatrix()`), k = `smallest`,
    /// ascending, each with a unit eigenvector (see `Eigenpairs`).
    ///
    /// Component by component: each component's null vector first (eigenvalue 0, components in
    /// order of their least vertex), then the smallest positive eigenvalues of the components
    /// merged. On a component of at least 64 vertices, thick-restart Lanczos (Wu–Simon) with full
    /// reorthogonalization and locking, the null vector projected out, from a fixed start vector:
    /// on σI − M (σ Gershgorin's bound) while σ/λ₂ is moderate, else on M⁺ by shift-invert, each
    /// product a conjugate-gradient solve with L grounded at the vertex of largest degree. A Ritz
    /// pair is accepted when its residual is at most `tolerance` · λ, relative to itself as for
    /// `algebraicConnectivity`; the vectors found are then rotated by Rayleigh–Ritz on M, and each
    /// value is its vector's Rayleigh quotient, a sum over edges. The dense solver on a smaller
    /// component, or when k is a third of it or more.
    /// O((n + m) · products + n · k²) time, O(n · k) `Double`s for the vectors and n · max(30, 2k +
    /// 10) for the basis.
    ///
    /// `weight` gives the weight of the edge at each position, read once per position; a weight of
    /// 0 is no edge.
    ///
    /// - Parameters:
    ///   - smallest: The number of eigenpairs, in `0...vertexCount`.
    ///   - weight: The weight of the edge at each position.
    ///   - tolerance: The residual a Ritz pair must reach, relative as described above.
    ///   - maxIterations: The matrix–vector products each Lanczos run may spend; nil for the limits
    ///     under Throws.
    /// - Returns: The eigenpairs, in order from that end of the spectrum.
    /// - Precondition: `smallest` is in `0...vertexCount`, `tolerance > 0`, every weight is finite
    ///   and nonnegative, and `maxIterations`, when given, is at least 1.
    /// - Throws: `NoConvergence` when a Lanczos run by shift-invert spends `maxIterations` products
    ///   (1,000 when nil), or a conjugate-gradient solve inside it 20,000 + 2n iterations, without
    ///   converging. A run on σI − M hands over to shift-invert rather than throwing, after 4,000 +
    ///   20√n products or `maxIterations`, whichever is smaller. The dense solver throws as
    ///   `laplacianSpectrum` does.
    @inlinable
    public func laplacianEigenpairs<W: BinaryFloatingPoint>(smallest: Int, weight: (Edges.Index) -> W, tolerance: Double = 1e-8, maxIterations: Int? = nil) throws(NoConvergence) -> Eigenpairs<Self> {
        precondition(tolerance > 0, "The tolerance is not positive")
        _checkMaxIterations(maxIterations)
        let weights = _spectralWeights(weight)
        let numbering = _vertexNumbering()
        let (values, vectors) = try _spectralAdjacency(weights, numbering: numbering).eigenpairs(.laplacian, count: smallest, largest: false, tolerance: tolerance, maxIterations: maxIterations)
        return Eigenpairs(self, numbers: numbering?.numbers, eigenvalues: values, vectors: vectors)
    }

    /// The k largest eigenvalues of the Laplacian L (`laplacianMatrix()`), k = `largest`,
    /// descending, each with a unit eigenvector (see `Eigenpairs`).
    ///
    /// Thick-restart Lanczos (Wu–Simon) with full reorthogonalization and locking on M, from a
    /// fixed start vector; once k pairs are found, a run on the complement of their vectors checks
    /// that no copy of a multiple eigenvalue was missed. A Ritz pair is accepted when its residual
    /// is at most `tolerance` · max(|λ|, s/1000), s Gershgorin's bound on the spectrum; the vectors
    /// are then rotated by Rayleigh–Ritz on M, whose values are returned. The dense solver below 64
    /// vertices, or when k is a third of them or more.
    /// O((n + m) · products + n · k²) time, O(n · k) `Double`s for the vectors and n · max(30, 2k +
    /// 10) for the basis.
    ///
    /// - Parameters:
    ///   - largest: The number of eigenpairs, in `0...vertexCount`.
    ///   - tolerance: The residual a Ritz pair must reach, relative as described above.
    ///   - maxIterations: The matrix–vector products each Lanczos run may spend; nil for 20,000 +
    ///     20√n.
    /// - Returns: The eigenpairs, in order from that end of the spectrum.
    /// - Precondition: `largest` is in `0...vertexCount`, `tolerance > 0`, and `maxIterations`,
    ///   when given, is at least 1.
    /// - Throws: `NoConvergence` when a Lanczos run spends `maxIterations` products without
    ///   converging, with the products spent and the largest Ritz residual on the tolerance's
    ///   scale. The dense solver throws as `adjacencySpectrum` does.
    @inlinable
    public func laplacianEigenpairs(largest: Int, tolerance: Double = 1e-8, maxIterations: Int? = nil) throws(NoConvergence) -> Eigenpairs<Self> {
        precondition(tolerance > 0, "The tolerance is not positive")
        _checkMaxIterations(maxIterations)
        let weights: [Double]? = nil
        let numbering = _vertexNumbering()
        let (values, vectors) = try _spectralAdjacency(weights, numbering: numbering).eigenpairs(.laplacian, count: largest, largest: true, tolerance: tolerance, maxIterations: maxIterations)
        return Eigenpairs(self, numbers: numbering?.numbers, eigenvalues: values, vectors: vectors)
    }

    /// The k largest eigenvalues of the Laplacian L (`laplacianMatrix()`), k = `largest`,
    /// descending, each with a unit eigenvector (see `Eigenpairs`).
    ///
    /// Thick-restart Lanczos (Wu–Simon) with full reorthogonalization and locking on M, from a
    /// fixed start vector; once k pairs are found, a run on the complement of their vectors checks
    /// that no copy of a multiple eigenvalue was missed. A Ritz pair is accepted when its residual
    /// is at most `tolerance` · max(|λ|, s/1000), s Gershgorin's bound on the spectrum; the vectors
    /// are then rotated by Rayleigh–Ritz on M, whose values are returned. The dense solver below 64
    /// vertices, or when k is a third of them or more.
    /// O((n + m) · products + n · k²) time, O(n · k) `Double`s for the vectors and n · max(30, 2k +
    /// 10) for the basis.
    ///
    /// `weight` gives the weight of the edge at each position, read once per position; a weight of
    /// 0 is no edge.
    ///
    /// - Parameters:
    ///   - largest: The number of eigenpairs, in `0...vertexCount`.
    ///   - weight: The weight of the edge at each position.
    ///   - tolerance: The residual a Ritz pair must reach, relative as described above.
    ///   - maxIterations: The matrix–vector products each Lanczos run may spend; nil for 20,000 +
    ///     20√n.
    /// - Returns: The eigenpairs, in order from that end of the spectrum.
    /// - Precondition: `largest` is in `0...vertexCount`, `tolerance > 0`, every weight is finite
    ///   and nonnegative, and `maxIterations`, when given, is at least 1.
    /// - Throws: `NoConvergence` when a Lanczos run spends `maxIterations` products without
    ///   converging, with the products spent and the largest Ritz residual on the tolerance's
    ///   scale. The dense solver throws as `adjacencySpectrum` does.
    @inlinable
    public func laplacianEigenpairs<W: BinaryInteger>(largest: Int, weight: (Edges.Index) -> W, tolerance: Double = 1e-8, maxIterations: Int? = nil) throws(NoConvergence) -> Eigenpairs<Self> {
        precondition(tolerance > 0, "The tolerance is not positive")
        _checkMaxIterations(maxIterations)
        let weights = _spectralWeights(weight)
        let numbering = _vertexNumbering()
        let (values, vectors) = try _spectralAdjacency(weights, numbering: numbering).eigenpairs(.laplacian, count: largest, largest: true, tolerance: tolerance, maxIterations: maxIterations)
        return Eigenpairs(self, numbers: numbering?.numbers, eigenvalues: values, vectors: vectors)
    }

    /// The k largest eigenvalues of the Laplacian L (`laplacianMatrix()`), k = `largest`,
    /// descending, each with a unit eigenvector (see `Eigenpairs`).
    ///
    /// Thick-restart Lanczos (Wu–Simon) with full reorthogonalization and locking on M, from a
    /// fixed start vector; once k pairs are found, a run on the complement of their vectors checks
    /// that no copy of a multiple eigenvalue was missed. A Ritz pair is accepted when its residual
    /// is at most `tolerance` · max(|λ|, s/1000), s Gershgorin's bound on the spectrum; the vectors
    /// are then rotated by Rayleigh–Ritz on M, whose values are returned. The dense solver below 64
    /// vertices, or when k is a third of them or more.
    /// O((n + m) · products + n · k²) time, O(n · k) `Double`s for the vectors and n · max(30, 2k +
    /// 10) for the basis.
    ///
    /// `weight` gives the weight of the edge at each position, read once per position; a weight of
    /// 0 is no edge.
    ///
    /// - Parameters:
    ///   - largest: The number of eigenpairs, in `0...vertexCount`.
    ///   - weight: The weight of the edge at each position.
    ///   - tolerance: The residual a Ritz pair must reach, relative as described above.
    ///   - maxIterations: The matrix–vector products each Lanczos run may spend; nil for 20,000 +
    ///     20√n.
    /// - Returns: The eigenpairs, in order from that end of the spectrum.
    /// - Precondition: `largest` is in `0...vertexCount`, `tolerance > 0`, every weight is finite
    ///   and nonnegative, and `maxIterations`, when given, is at least 1.
    /// - Throws: `NoConvergence` when a Lanczos run spends `maxIterations` products without
    ///   converging, with the products spent and the largest Ritz residual on the tolerance's
    ///   scale. The dense solver throws as `adjacencySpectrum` does.
    @inlinable
    public func laplacianEigenpairs<W: BinaryFloatingPoint>(largest: Int, weight: (Edges.Index) -> W, tolerance: Double = 1e-8, maxIterations: Int? = nil) throws(NoConvergence) -> Eigenpairs<Self> {
        precondition(tolerance > 0, "The tolerance is not positive")
        _checkMaxIterations(maxIterations)
        let weights = _spectralWeights(weight)
        let numbering = _vertexNumbering()
        let (values, vectors) = try _spectralAdjacency(weights, numbering: numbering).eigenpairs(.laplacian, count: largest, largest: true, tolerance: tolerance, maxIterations: maxIterations)
        return Eigenpairs(self, numbers: numbering?.numbers, eigenvalues: values, vectors: vectors)
    }

    /// The k smallest eigenvalues of the normalized Laplacian N (`normalizedLaplacianMatrix()`), k
    /// = `smallest`, ascending, each with a unit eigenvector (see `Eigenpairs`).
    ///
    /// Component by component: each component's null vector first (eigenvalue 0, components in
    /// order of their least vertex), then the smallest positive eigenvalues of the components
    /// merged. On a component of at least 64 vertices, thick-restart Lanczos (Wu–Simon) with full
    /// reorthogonalization and locking, the null vector projected out, from a fixed start vector:
    /// on σI − M (σ Gershgorin's bound) while σ/λ₂ is moderate, else on M⁺ by shift-invert, each
    /// product a conjugate-gradient solve with L grounded at the vertex of largest degree. A Ritz
    /// pair is accepted when its residual is at most `tolerance` · λ, relative to itself as for
    /// `algebraicConnectivity`; the vectors found are then rotated by Rayleigh–Ritz on M, and each
    /// value is its vector's Rayleigh quotient, a sum over edges. The dense solver on a smaller
    /// component, or when k is a third of it or more.
    /// O((n + m) · products + n · k²) time, O(n · k) `Double`s for the vectors and n · max(30, 2k +
    /// 10) for the basis.
    ///
    /// - Parameters:
    ///   - smallest: The number of eigenpairs, in `0...vertexCount`.
    ///   - tolerance: The residual a Ritz pair must reach, relative as described above.
    ///   - maxIterations: The matrix–vector products each Lanczos run may spend; nil for the limits
    ///     under Throws.
    /// - Returns: The eigenpairs, in order from that end of the spectrum.
    /// - Precondition: `smallest` is in `0...vertexCount`, `tolerance > 0`, and `maxIterations`,
    ///   when given, is at least 1.
    /// - Throws: `NoConvergence` when a Lanczos run by shift-invert spends `maxIterations` products
    ///   (1,000 when nil), or a conjugate-gradient solve inside it 20,000 + 2n iterations, without
    ///   converging. A run on σI − M hands over to shift-invert rather than throwing, after 4,000 +
    ///   20√n products or `maxIterations`, whichever is smaller. The dense solver throws as
    ///   `laplacianSpectrum` does.
    @inlinable
    public func normalizedLaplacianEigenpairs(smallest: Int, tolerance: Double = 1e-8, maxIterations: Int? = nil) throws(NoConvergence) -> Eigenpairs<Self> {
        precondition(tolerance > 0, "The tolerance is not positive")
        _checkMaxIterations(maxIterations)
        let weights: [Double]? = nil
        let numbering = _vertexNumbering()
        let (values, vectors) = try _spectralAdjacency(weights, numbering: numbering).eigenpairs(.normalizedLaplacian, count: smallest, largest: false, tolerance: tolerance, maxIterations: maxIterations)
        return Eigenpairs(self, numbers: numbering?.numbers, eigenvalues: values, vectors: vectors)
    }

    /// The k smallest eigenvalues of the normalized Laplacian N (`normalizedLaplacianMatrix()`), k
    /// = `smallest`, ascending, each with a unit eigenvector (see `Eigenpairs`).
    ///
    /// Component by component: each component's null vector first (eigenvalue 0, components in
    /// order of their least vertex), then the smallest positive eigenvalues of the components
    /// merged. On a component of at least 64 vertices, thick-restart Lanczos (Wu–Simon) with full
    /// reorthogonalization and locking, the null vector projected out, from a fixed start vector:
    /// on σI − M (σ Gershgorin's bound) while σ/λ₂ is moderate, else on M⁺ by shift-invert, each
    /// product a conjugate-gradient solve with L grounded at the vertex of largest degree. A Ritz
    /// pair is accepted when its residual is at most `tolerance` · λ, relative to itself as for
    /// `algebraicConnectivity`; the vectors found are then rotated by Rayleigh–Ritz on M, and each
    /// value is its vector's Rayleigh quotient, a sum over edges. The dense solver on a smaller
    /// component, or when k is a third of it or more.
    /// O((n + m) · products + n · k²) time, O(n · k) `Double`s for the vectors and n · max(30, 2k +
    /// 10) for the basis.
    ///
    /// `weight` gives the weight of the edge at each position, read once per position; a weight of
    /// 0 is no edge.
    ///
    /// - Parameters:
    ///   - smallest: The number of eigenpairs, in `0...vertexCount`.
    ///   - weight: The weight of the edge at each position.
    ///   - tolerance: The residual a Ritz pair must reach, relative as described above.
    ///   - maxIterations: The matrix–vector products each Lanczos run may spend; nil for the limits
    ///     under Throws.
    /// - Returns: The eigenpairs, in order from that end of the spectrum.
    /// - Precondition: `smallest` is in `0...vertexCount`, `tolerance > 0`, every weight is finite
    ///   and nonnegative, and `maxIterations`, when given, is at least 1.
    /// - Throws: `NoConvergence` when a Lanczos run by shift-invert spends `maxIterations` products
    ///   (1,000 when nil), or a conjugate-gradient solve inside it 20,000 + 2n iterations, without
    ///   converging. A run on σI − M hands over to shift-invert rather than throwing, after 4,000 +
    ///   20√n products or `maxIterations`, whichever is smaller. The dense solver throws as
    ///   `laplacianSpectrum` does.
    @inlinable
    public func normalizedLaplacianEigenpairs<W: BinaryInteger>(smallest: Int, weight: (Edges.Index) -> W, tolerance: Double = 1e-8, maxIterations: Int? = nil) throws(NoConvergence) -> Eigenpairs<Self> {
        precondition(tolerance > 0, "The tolerance is not positive")
        _checkMaxIterations(maxIterations)
        let weights = _spectralWeights(weight)
        let numbering = _vertexNumbering()
        let (values, vectors) = try _spectralAdjacency(weights, numbering: numbering).eigenpairs(.normalizedLaplacian, count: smallest, largest: false, tolerance: tolerance, maxIterations: maxIterations)
        return Eigenpairs(self, numbers: numbering?.numbers, eigenvalues: values, vectors: vectors)
    }

    /// The k smallest eigenvalues of the normalized Laplacian N (`normalizedLaplacianMatrix()`), k
    /// = `smallest`, ascending, each with a unit eigenvector (see `Eigenpairs`).
    ///
    /// Component by component: each component's null vector first (eigenvalue 0, components in
    /// order of their least vertex), then the smallest positive eigenvalues of the components
    /// merged. On a component of at least 64 vertices, thick-restart Lanczos (Wu–Simon) with full
    /// reorthogonalization and locking, the null vector projected out, from a fixed start vector:
    /// on σI − M (σ Gershgorin's bound) while σ/λ₂ is moderate, else on M⁺ by shift-invert, each
    /// product a conjugate-gradient solve with L grounded at the vertex of largest degree. A Ritz
    /// pair is accepted when its residual is at most `tolerance` · λ, relative to itself as for
    /// `algebraicConnectivity`; the vectors found are then rotated by Rayleigh–Ritz on M, and each
    /// value is its vector's Rayleigh quotient, a sum over edges. The dense solver on a smaller
    /// component, or when k is a third of it or more.
    /// O((n + m) · products + n · k²) time, O(n · k) `Double`s for the vectors and n · max(30, 2k +
    /// 10) for the basis.
    ///
    /// `weight` gives the weight of the edge at each position, read once per position; a weight of
    /// 0 is no edge.
    ///
    /// - Parameters:
    ///   - smallest: The number of eigenpairs, in `0...vertexCount`.
    ///   - weight: The weight of the edge at each position.
    ///   - tolerance: The residual a Ritz pair must reach, relative as described above.
    ///   - maxIterations: The matrix–vector products each Lanczos run may spend; nil for the limits
    ///     under Throws.
    /// - Returns: The eigenpairs, in order from that end of the spectrum.
    /// - Precondition: `smallest` is in `0...vertexCount`, `tolerance > 0`, every weight is finite
    ///   and nonnegative, and `maxIterations`, when given, is at least 1.
    /// - Throws: `NoConvergence` when a Lanczos run by shift-invert spends `maxIterations` products
    ///   (1,000 when nil), or a conjugate-gradient solve inside it 20,000 + 2n iterations, without
    ///   converging. A run on σI − M hands over to shift-invert rather than throwing, after 4,000 +
    ///   20√n products or `maxIterations`, whichever is smaller. The dense solver throws as
    ///   `laplacianSpectrum` does.
    @inlinable
    public func normalizedLaplacianEigenpairs<W: BinaryFloatingPoint>(smallest: Int, weight: (Edges.Index) -> W, tolerance: Double = 1e-8, maxIterations: Int? = nil) throws(NoConvergence) -> Eigenpairs<Self> {
        precondition(tolerance > 0, "The tolerance is not positive")
        _checkMaxIterations(maxIterations)
        let weights = _spectralWeights(weight)
        let numbering = _vertexNumbering()
        let (values, vectors) = try _spectralAdjacency(weights, numbering: numbering).eigenpairs(.normalizedLaplacian, count: smallest, largest: false, tolerance: tolerance, maxIterations: maxIterations)
        return Eigenpairs(self, numbers: numbering?.numbers, eigenvalues: values, vectors: vectors)
    }

    /// The k largest eigenvalues of the normalized Laplacian N (`normalizedLaplacianMatrix()`), k =
    /// `largest`, descending, each with a unit eigenvector (see `Eigenpairs`).
    ///
    /// Thick-restart Lanczos (Wu–Simon) with full reorthogonalization and locking on M, from a
    /// fixed start vector; once k pairs are found, a run on the complement of their vectors checks
    /// that no copy of a multiple eigenvalue was missed. A Ritz pair is accepted when its residual
    /// is at most `tolerance` · max(|λ|, s/1000), s Gershgorin's bound on the spectrum; the vectors
    /// are then rotated by Rayleigh–Ritz on M, whose values are returned. The dense solver below 64
    /// vertices, or when k is a third of them or more.
    /// O((n + m) · products + n · k²) time, O(n · k) `Double`s for the vectors and n · max(30, 2k +
    /// 10) for the basis.
    ///
    /// - Parameters:
    ///   - largest: The number of eigenpairs, in `0...vertexCount`.
    ///   - tolerance: The residual a Ritz pair must reach, relative as described above.
    ///   - maxIterations: The matrix–vector products each Lanczos run may spend; nil for 20,000 +
    ///     20√n.
    /// - Returns: The eigenpairs, in order from that end of the spectrum.
    /// - Precondition: `largest` is in `0...vertexCount`, `tolerance > 0`, and `maxIterations`,
    ///   when given, is at least 1.
    /// - Throws: `NoConvergence` when a Lanczos run spends `maxIterations` products without
    ///   converging, with the products spent and the largest Ritz residual on the tolerance's
    ///   scale. The dense solver throws as `adjacencySpectrum` does.
    @inlinable
    public func normalizedLaplacianEigenpairs(largest: Int, tolerance: Double = 1e-8, maxIterations: Int? = nil) throws(NoConvergence) -> Eigenpairs<Self> {
        precondition(tolerance > 0, "The tolerance is not positive")
        _checkMaxIterations(maxIterations)
        let weights: [Double]? = nil
        let numbering = _vertexNumbering()
        let (values, vectors) = try _spectralAdjacency(weights, numbering: numbering).eigenpairs(.normalizedLaplacian, count: largest, largest: true, tolerance: tolerance, maxIterations: maxIterations)
        return Eigenpairs(self, numbers: numbering?.numbers, eigenvalues: values, vectors: vectors)
    }

    /// The k largest eigenvalues of the normalized Laplacian N (`normalizedLaplacianMatrix()`), k =
    /// `largest`, descending, each with a unit eigenvector (see `Eigenpairs`).
    ///
    /// Thick-restart Lanczos (Wu–Simon) with full reorthogonalization and locking on M, from a
    /// fixed start vector; once k pairs are found, a run on the complement of their vectors checks
    /// that no copy of a multiple eigenvalue was missed. A Ritz pair is accepted when its residual
    /// is at most `tolerance` · max(|λ|, s/1000), s Gershgorin's bound on the spectrum; the vectors
    /// are then rotated by Rayleigh–Ritz on M, whose values are returned. The dense solver below 64
    /// vertices, or when k is a third of them or more.
    /// O((n + m) · products + n · k²) time, O(n · k) `Double`s for the vectors and n · max(30, 2k +
    /// 10) for the basis.
    ///
    /// `weight` gives the weight of the edge at each position, read once per position; a weight of
    /// 0 is no edge.
    ///
    /// - Parameters:
    ///   - largest: The number of eigenpairs, in `0...vertexCount`.
    ///   - weight: The weight of the edge at each position.
    ///   - tolerance: The residual a Ritz pair must reach, relative as described above.
    ///   - maxIterations: The matrix–vector products each Lanczos run may spend; nil for 20,000 +
    ///     20√n.
    /// - Returns: The eigenpairs, in order from that end of the spectrum.
    /// - Precondition: `largest` is in `0...vertexCount`, `tolerance > 0`, every weight is finite
    ///   and nonnegative, and `maxIterations`, when given, is at least 1.
    /// - Throws: `NoConvergence` when a Lanczos run spends `maxIterations` products without
    ///   converging, with the products spent and the largest Ritz residual on the tolerance's
    ///   scale. The dense solver throws as `adjacencySpectrum` does.
    @inlinable
    public func normalizedLaplacianEigenpairs<W: BinaryInteger>(largest: Int, weight: (Edges.Index) -> W, tolerance: Double = 1e-8, maxIterations: Int? = nil) throws(NoConvergence) -> Eigenpairs<Self> {
        precondition(tolerance > 0, "The tolerance is not positive")
        _checkMaxIterations(maxIterations)
        let weights = _spectralWeights(weight)
        let numbering = _vertexNumbering()
        let (values, vectors) = try _spectralAdjacency(weights, numbering: numbering).eigenpairs(.normalizedLaplacian, count: largest, largest: true, tolerance: tolerance, maxIterations: maxIterations)
        return Eigenpairs(self, numbers: numbering?.numbers, eigenvalues: values, vectors: vectors)
    }

    /// The k largest eigenvalues of the normalized Laplacian N (`normalizedLaplacianMatrix()`), k =
    /// `largest`, descending, each with a unit eigenvector (see `Eigenpairs`).
    ///
    /// Thick-restart Lanczos (Wu–Simon) with full reorthogonalization and locking on M, from a
    /// fixed start vector; once k pairs are found, a run on the complement of their vectors checks
    /// that no copy of a multiple eigenvalue was missed. A Ritz pair is accepted when its residual
    /// is at most `tolerance` · max(|λ|, s/1000), s Gershgorin's bound on the spectrum; the vectors
    /// are then rotated by Rayleigh–Ritz on M, whose values are returned. The dense solver below 64
    /// vertices, or when k is a third of them or more.
    /// O((n + m) · products + n · k²) time, O(n · k) `Double`s for the vectors and n · max(30, 2k +
    /// 10) for the basis.
    ///
    /// `weight` gives the weight of the edge at each position, read once per position; a weight of
    /// 0 is no edge.
    ///
    /// - Parameters:
    ///   - largest: The number of eigenpairs, in `0...vertexCount`.
    ///   - weight: The weight of the edge at each position.
    ///   - tolerance: The residual a Ritz pair must reach, relative as described above.
    ///   - maxIterations: The matrix–vector products each Lanczos run may spend; nil for 20,000 +
    ///     20√n.
    /// - Returns: The eigenpairs, in order from that end of the spectrum.
    /// - Precondition: `largest` is in `0...vertexCount`, `tolerance > 0`, every weight is finite
    ///   and nonnegative, and `maxIterations`, when given, is at least 1.
    /// - Throws: `NoConvergence` when a Lanczos run spends `maxIterations` products without
    ///   converging, with the products spent and the largest Ritz residual on the tolerance's
    ///   scale. The dense solver throws as `adjacencySpectrum` does.
    @inlinable
    public func normalizedLaplacianEigenpairs<W: BinaryFloatingPoint>(largest: Int, weight: (Edges.Index) -> W, tolerance: Double = 1e-8, maxIterations: Int? = nil) throws(NoConvergence) -> Eigenpairs<Self> {
        precondition(tolerance > 0, "The tolerance is not positive")
        _checkMaxIterations(maxIterations)
        let weights = _spectralWeights(weight)
        let numbering = _vertexNumbering()
        let (values, vectors) = try _spectralAdjacency(weights, numbering: numbering).eigenpairs(.normalizedLaplacian, count: largest, largest: true, tolerance: tolerance, maxIterations: maxIterations)
        return Eigenpairs(self, numbers: numbering?.numbers, eigenvalues: values, vectors: vectors)
    }

    /// The k smallest eigenvalues of the signless Laplacian Q (`signlessLaplacianMatrix()`), k =
    /// `smallest`, ascending, each with a unit eigenvector (see `Eigenpairs`).
    ///
    /// Thick-restart Lanczos (Wu–Simon) with full reorthogonalization and locking on σI − M (σ
    /// Gershgorin's bound), from a fixed start vector; once k pairs are found, a run on the
    /// complement of their vectors checks that no copy of a multiple eigenvalue was missed. A Ritz
    /// pair is accepted when its residual is at most `tolerance` · max(|λ|, s/1000), s Gershgorin's
    /// bound on the spectrum; the vectors are then rotated by Rayleigh–Ritz on M, whose values are
    /// returned. The dense solver below 64 vertices, or when k is a third of them or more.
    /// O((n + m) · products + n · k²) time, O(n · k) `Double`s for the vectors and n · max(30, 2k +
    /// 10) for the basis.
    ///
    /// - Parameters:
    ///   - smallest: The number of eigenpairs, in `0...vertexCount`.
    ///   - tolerance: The residual a Ritz pair must reach, relative as described above.
    ///   - maxIterations: The matrix–vector products each Lanczos run may spend; nil for 20,000 +
    ///     20√n.
    /// - Returns: The eigenpairs, in order from that end of the spectrum.
    /// - Precondition: `smallest` is in `0...vertexCount`, `tolerance > 0`, and `maxIterations`,
    ///   when given, is at least 1.
    /// - Throws: `NoConvergence` when a Lanczos run spends `maxIterations` products without
    ///   converging, with the products spent and the largest Ritz residual on the tolerance's
    ///   scale. The dense solver throws as `adjacencySpectrum` does.
    @inlinable
    public func signlessLaplacianEigenpairs(smallest: Int, tolerance: Double = 1e-8, maxIterations: Int? = nil) throws(NoConvergence) -> Eigenpairs<Self> {
        precondition(tolerance > 0, "The tolerance is not positive")
        _checkMaxIterations(maxIterations)
        let weights: [Double]? = nil
        let numbering = _vertexNumbering()
        let (values, vectors) = try _spectralAdjacency(weights, numbering: numbering).eigenpairs(.signlessLaplacian, count: smallest, largest: false, tolerance: tolerance, maxIterations: maxIterations)
        return Eigenpairs(self, numbers: numbering?.numbers, eigenvalues: values, vectors: vectors)
    }

    /// The k smallest eigenvalues of the signless Laplacian Q (`signlessLaplacianMatrix()`), k =
    /// `smallest`, ascending, each with a unit eigenvector (see `Eigenpairs`).
    ///
    /// Thick-restart Lanczos (Wu–Simon) with full reorthogonalization and locking on σI − M (σ
    /// Gershgorin's bound), from a fixed start vector; once k pairs are found, a run on the
    /// complement of their vectors checks that no copy of a multiple eigenvalue was missed. A Ritz
    /// pair is accepted when its residual is at most `tolerance` · max(|λ|, s/1000), s Gershgorin's
    /// bound on the spectrum; the vectors are then rotated by Rayleigh–Ritz on M, whose values are
    /// returned. The dense solver below 64 vertices, or when k is a third of them or more.
    /// O((n + m) · products + n · k²) time, O(n · k) `Double`s for the vectors and n · max(30, 2k +
    /// 10) for the basis.
    ///
    /// `weight` gives the weight of the edge at each position, read once per position; a weight of
    /// 0 is no edge.
    ///
    /// - Parameters:
    ///   - smallest: The number of eigenpairs, in `0...vertexCount`.
    ///   - weight: The weight of the edge at each position.
    ///   - tolerance: The residual a Ritz pair must reach, relative as described above.
    ///   - maxIterations: The matrix–vector products each Lanczos run may spend; nil for 20,000 +
    ///     20√n.
    /// - Returns: The eigenpairs, in order from that end of the spectrum.
    /// - Precondition: `smallest` is in `0...vertexCount`, `tolerance > 0`, every weight is finite
    ///   and nonnegative, and `maxIterations`, when given, is at least 1.
    /// - Throws: `NoConvergence` when a Lanczos run spends `maxIterations` products without
    ///   converging, with the products spent and the largest Ritz residual on the tolerance's
    ///   scale. The dense solver throws as `adjacencySpectrum` does.
    @inlinable
    public func signlessLaplacianEigenpairs<W: BinaryInteger>(smallest: Int, weight: (Edges.Index) -> W, tolerance: Double = 1e-8, maxIterations: Int? = nil) throws(NoConvergence) -> Eigenpairs<Self> {
        precondition(tolerance > 0, "The tolerance is not positive")
        _checkMaxIterations(maxIterations)
        let weights = _spectralWeights(weight)
        let numbering = _vertexNumbering()
        let (values, vectors) = try _spectralAdjacency(weights, numbering: numbering).eigenpairs(.signlessLaplacian, count: smallest, largest: false, tolerance: tolerance, maxIterations: maxIterations)
        return Eigenpairs(self, numbers: numbering?.numbers, eigenvalues: values, vectors: vectors)
    }

    /// The k smallest eigenvalues of the signless Laplacian Q (`signlessLaplacianMatrix()`), k =
    /// `smallest`, ascending, each with a unit eigenvector (see `Eigenpairs`).
    ///
    /// Thick-restart Lanczos (Wu–Simon) with full reorthogonalization and locking on σI − M (σ
    /// Gershgorin's bound), from a fixed start vector; once k pairs are found, a run on the
    /// complement of their vectors checks that no copy of a multiple eigenvalue was missed. A Ritz
    /// pair is accepted when its residual is at most `tolerance` · max(|λ|, s/1000), s Gershgorin's
    /// bound on the spectrum; the vectors are then rotated by Rayleigh–Ritz on M, whose values are
    /// returned. The dense solver below 64 vertices, or when k is a third of them or more.
    /// O((n + m) · products + n · k²) time, O(n · k) `Double`s for the vectors and n · max(30, 2k +
    /// 10) for the basis.
    ///
    /// `weight` gives the weight of the edge at each position, read once per position; a weight of
    /// 0 is no edge.
    ///
    /// - Parameters:
    ///   - smallest: The number of eigenpairs, in `0...vertexCount`.
    ///   - weight: The weight of the edge at each position.
    ///   - tolerance: The residual a Ritz pair must reach, relative as described above.
    ///   - maxIterations: The matrix–vector products each Lanczos run may spend; nil for 20,000 +
    ///     20√n.
    /// - Returns: The eigenpairs, in order from that end of the spectrum.
    /// - Precondition: `smallest` is in `0...vertexCount`, `tolerance > 0`, every weight is finite
    ///   and nonnegative, and `maxIterations`, when given, is at least 1.
    /// - Throws: `NoConvergence` when a Lanczos run spends `maxIterations` products without
    ///   converging, with the products spent and the largest Ritz residual on the tolerance's
    ///   scale. The dense solver throws as `adjacencySpectrum` does.
    @inlinable
    public func signlessLaplacianEigenpairs<W: BinaryFloatingPoint>(smallest: Int, weight: (Edges.Index) -> W, tolerance: Double = 1e-8, maxIterations: Int? = nil) throws(NoConvergence) -> Eigenpairs<Self> {
        precondition(tolerance > 0, "The tolerance is not positive")
        _checkMaxIterations(maxIterations)
        let weights = _spectralWeights(weight)
        let numbering = _vertexNumbering()
        let (values, vectors) = try _spectralAdjacency(weights, numbering: numbering).eigenpairs(.signlessLaplacian, count: smallest, largest: false, tolerance: tolerance, maxIterations: maxIterations)
        return Eigenpairs(self, numbers: numbering?.numbers, eigenvalues: values, vectors: vectors)
    }

    /// The k largest eigenvalues of the signless Laplacian Q (`signlessLaplacianMatrix()`), k =
    /// `largest`, descending, each with a unit eigenvector (see `Eigenpairs`).
    ///
    /// Thick-restart Lanczos (Wu–Simon) with full reorthogonalization and locking on M, from a
    /// fixed start vector; once k pairs are found, a run on the complement of their vectors checks
    /// that no copy of a multiple eigenvalue was missed. A Ritz pair is accepted when its residual
    /// is at most `tolerance` · max(|λ|, s/1000), s Gershgorin's bound on the spectrum; the vectors
    /// are then rotated by Rayleigh–Ritz on M, whose values are returned. The dense solver below 64
    /// vertices, or when k is a third of them or more.
    /// O((n + m) · products + n · k²) time, O(n · k) `Double`s for the vectors and n · max(30, 2k +
    /// 10) for the basis.
    ///
    /// - Parameters:
    ///   - largest: The number of eigenpairs, in `0...vertexCount`.
    ///   - tolerance: The residual a Ritz pair must reach, relative as described above.
    ///   - maxIterations: The matrix–vector products each Lanczos run may spend; nil for 20,000 +
    ///     20√n.
    /// - Returns: The eigenpairs, in order from that end of the spectrum.
    /// - Precondition: `largest` is in `0...vertexCount`, `tolerance > 0`, and `maxIterations`,
    ///   when given, is at least 1.
    /// - Throws: `NoConvergence` when a Lanczos run spends `maxIterations` products without
    ///   converging, with the products spent and the largest Ritz residual on the tolerance's
    ///   scale. The dense solver throws as `adjacencySpectrum` does.
    @inlinable
    public func signlessLaplacianEigenpairs(largest: Int, tolerance: Double = 1e-8, maxIterations: Int? = nil) throws(NoConvergence) -> Eigenpairs<Self> {
        precondition(tolerance > 0, "The tolerance is not positive")
        _checkMaxIterations(maxIterations)
        let weights: [Double]? = nil
        let numbering = _vertexNumbering()
        let (values, vectors) = try _spectralAdjacency(weights, numbering: numbering).eigenpairs(.signlessLaplacian, count: largest, largest: true, tolerance: tolerance, maxIterations: maxIterations)
        return Eigenpairs(self, numbers: numbering?.numbers, eigenvalues: values, vectors: vectors)
    }

    /// The k largest eigenvalues of the signless Laplacian Q (`signlessLaplacianMatrix()`), k =
    /// `largest`, descending, each with a unit eigenvector (see `Eigenpairs`).
    ///
    /// Thick-restart Lanczos (Wu–Simon) with full reorthogonalization and locking on M, from a
    /// fixed start vector; once k pairs are found, a run on the complement of their vectors checks
    /// that no copy of a multiple eigenvalue was missed. A Ritz pair is accepted when its residual
    /// is at most `tolerance` · max(|λ|, s/1000), s Gershgorin's bound on the spectrum; the vectors
    /// are then rotated by Rayleigh–Ritz on M, whose values are returned. The dense solver below 64
    /// vertices, or when k is a third of them or more.
    /// O((n + m) · products + n · k²) time, O(n · k) `Double`s for the vectors and n · max(30, 2k +
    /// 10) for the basis.
    ///
    /// `weight` gives the weight of the edge at each position, read once per position; a weight of
    /// 0 is no edge.
    ///
    /// - Parameters:
    ///   - largest: The number of eigenpairs, in `0...vertexCount`.
    ///   - weight: The weight of the edge at each position.
    ///   - tolerance: The residual a Ritz pair must reach, relative as described above.
    ///   - maxIterations: The matrix–vector products each Lanczos run may spend; nil for 20,000 +
    ///     20√n.
    /// - Returns: The eigenpairs, in order from that end of the spectrum.
    /// - Precondition: `largest` is in `0...vertexCount`, `tolerance > 0`, every weight is finite
    ///   and nonnegative, and `maxIterations`, when given, is at least 1.
    /// - Throws: `NoConvergence` when a Lanczos run spends `maxIterations` products without
    ///   converging, with the products spent and the largest Ritz residual on the tolerance's
    ///   scale. The dense solver throws as `adjacencySpectrum` does.
    @inlinable
    public func signlessLaplacianEigenpairs<W: BinaryInteger>(largest: Int, weight: (Edges.Index) -> W, tolerance: Double = 1e-8, maxIterations: Int? = nil) throws(NoConvergence) -> Eigenpairs<Self> {
        precondition(tolerance > 0, "The tolerance is not positive")
        _checkMaxIterations(maxIterations)
        let weights = _spectralWeights(weight)
        let numbering = _vertexNumbering()
        let (values, vectors) = try _spectralAdjacency(weights, numbering: numbering).eigenpairs(.signlessLaplacian, count: largest, largest: true, tolerance: tolerance, maxIterations: maxIterations)
        return Eigenpairs(self, numbers: numbering?.numbers, eigenvalues: values, vectors: vectors)
    }

    /// The k largest eigenvalues of the signless Laplacian Q (`signlessLaplacianMatrix()`), k =
    /// `largest`, descending, each with a unit eigenvector (see `Eigenpairs`).
    ///
    /// Thick-restart Lanczos (Wu–Simon) with full reorthogonalization and locking on M, from a
    /// fixed start vector; once k pairs are found, a run on the complement of their vectors checks
    /// that no copy of a multiple eigenvalue was missed. A Ritz pair is accepted when its residual
    /// is at most `tolerance` · max(|λ|, s/1000), s Gershgorin's bound on the spectrum; the vectors
    /// are then rotated by Rayleigh–Ritz on M, whose values are returned. The dense solver below 64
    /// vertices, or when k is a third of them or more.
    /// O((n + m) · products + n · k²) time, O(n · k) `Double`s for the vectors and n · max(30, 2k +
    /// 10) for the basis.
    ///
    /// `weight` gives the weight of the edge at each position, read once per position; a weight of
    /// 0 is no edge.
    ///
    /// - Parameters:
    ///   - largest: The number of eigenpairs, in `0...vertexCount`.
    ///   - weight: The weight of the edge at each position.
    ///   - tolerance: The residual a Ritz pair must reach, relative as described above.
    ///   - maxIterations: The matrix–vector products each Lanczos run may spend; nil for 20,000 +
    ///     20√n.
    /// - Returns: The eigenpairs, in order from that end of the spectrum.
    /// - Precondition: `largest` is in `0...vertexCount`, `tolerance > 0`, every weight is finite
    ///   and nonnegative, and `maxIterations`, when given, is at least 1.
    /// - Throws: `NoConvergence` when a Lanczos run spends `maxIterations` products without
    ///   converging, with the products spent and the largest Ritz residual on the tolerance's
    ///   scale. The dense solver throws as `adjacencySpectrum` does.
    @inlinable
    public func signlessLaplacianEigenpairs<W: BinaryFloatingPoint>(largest: Int, weight: (Edges.Index) -> W, tolerance: Double = 1e-8, maxIterations: Int? = nil) throws(NoConvergence) -> Eigenpairs<Self> {
        precondition(tolerance > 0, "The tolerance is not positive")
        _checkMaxIterations(maxIterations)
        let weights = _spectralWeights(weight)
        let numbering = _vertexNumbering()
        let (values, vectors) = try _spectralAdjacency(weights, numbering: numbering).eigenpairs(.signlessLaplacian, count: largest, largest: true, tolerance: tolerance, maxIterations: maxIterations)
        return Eigenpairs(self, numbers: numbering?.numbers, eigenvalues: values, vectors: vectors)
    }
}
