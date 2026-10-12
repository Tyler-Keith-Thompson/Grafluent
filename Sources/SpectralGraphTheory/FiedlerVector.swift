import GraphProtocols

/// The Fiedler vector of a connected graph: a unit eigenvector of λ₂, the algebraic
/// connectivity, of the Laplacian (or of the normalized Laplacian), with one entry per vertex.
///
/// **Sign.** An eigenvector is defined up to sign; the canonical sign makes the first entry, in
/// index order, whose magnitude is at least 10⁻⁴ of the largest positive. The threshold is
/// relative so that an entry that is 0 in exact arithmetic, but carries rounding noise, never
/// picks the sign.
///
/// **Degenerate λ₂.** When λ₂ is a multiple eigenvalue (complete graphs, cycles, hypercubes), the
/// vector is some unit vector of its eigenspace: deterministic (a fixed start vector), but which
/// one is not part of the contract.
@frozen
public struct FiedlerVector<G: Graph> {
    @usableFromInline let _graph: G
    /// Vertex numbers when the graph has no vertex indices.
    @usableFromInline let _numbers: [G.Vertex: Int]?
    @usableFromInline let _values: [Double]

    /// λ₂, the second smallest eigenvalue of the matrix (Fiedler 1973).
    public let algebraicConnectivity: Double

    @inlinable
    init(_ graph: G, numbers: [G.Vertex: Int]?, algebraicConnectivity: Double, values: [Double]) {
        _graph = graph
        _numbers = numbers
        self.algebraicConnectivity = algebraicConnectivity
        _values = values
    }

    /// Every entry, by vertex index (in `vertices` order): unit length, orthogonal to the null
    /// vector (1, or D^1/2 · 1 for the normalized Laplacian), with the canonical sign. O(1).
    @inlinable
    public var values: [Double] { _values }

    /// The entry of `vertex`. O(1) after looking it up.
    ///
    /// - Precondition: `vertex` is a vertex of the graph.
    @inlinable
    public func value(of vertex: G.Vertex) -> Double {
        if let _numbers {
            guard let v = _numbers[vertex] else { preconditionFailure("The vertex is not in the graph") }
            return _values[v]
        }
        return _values[_graph._requiredVertexIndex(of: vertex, "The vertex is not in the graph")]
    }

    /// The entry of the vertex at `index` (its vertex index, or its position in `vertices` when the
    /// graph has no vertex indices).
    ///
    /// - Precondition: `index` is in `0..<vertexCount`.
    @inlinable
    public func value(ofIndex index: Int) -> Double {
        precondition(index >= 0 && index < _values.count, "Vertex index out of range")
        return _values[index]
    }
}

extension FiedlerVector: Sendable where G: Sendable, G.Vertex: Sendable {}

extension Graph {
    /// The algebraic connectivity λ₂: the second smallest eigenvalue of the Laplacian L (of the
    /// normalized Laplacian N with `normalized`), 0 exactly when the graph is not connected (a
    /// weight-0 edge does not connect). NetworkX `algebraic_connectivity`; Fiedler 1973.
    ///
    /// Thick-restart Lanczos (Wu–Simon) with full reorthogonalization, the null space projected
    /// out, from a fixed start vector: on σI − L (σ twice the largest weighted degree; 2I − N with
    /// `normalized`) while σ/λ₂ is moderate, else on L⁺ by shift-invert, each product a
    /// conjugate-gradient solve with L grounded at the vertex of largest degree. A Ritz pair is
    /// accepted when its residual is at most `tolerance` · λ₂, so λ₂ is relative to itself however
    /// the weights spread; the value is then the vector's Rayleigh quotient, a sum over edges. The
    /// dense solver below 64 vertices. O((n + m) · products) time; 31 n `Double`s (34 n from 5,000
    /// vertices, for the polynomial filter), and on the shift-invert path O(n + m) more for the
    /// solver.
    ///
    /// - Precondition: at least two vertices, `tolerance > 0`, and `maxIterations`, when given, is
    ///   at least 1.
    /// - Throws: `NoConvergence` when the Lanczos run on L⁺ spends `maxIterations` matrix–vector
    ///   products (1,000 when nil) without converging, with the products spent and the Ritz
    ///   residual relative to 1/λ₂. The run on σI − L that may come first hands over to
    ///   shift-invert rather than throwing, after 4,000 + 20√n products or `maxIterations`,
    ///   whichever is smaller. Each shift-invert product is a conjugate-gradient solve that throws,
    ///   with its own iterations and relative residual, after 20,000 + 2n. Below 64 vertices the
    ///   dense solver answers and `maxIterations` is unused. Only a tolerance below rounding has
    ///   reached the default limits in the measurements.
    @inlinable
    public func algebraicConnectivity(normalized: Bool = false, tolerance: Double = 1e-8, maxIterations: Int? = nil) throws(NoConvergence) -> Double {
        precondition(tolerance > 0, "The tolerance is not positive")
        _checkMaxIterations(maxIterations)
        return try _spectralAdjacency(nil, numbering: nil).algebraicConnectivity(normalized: normalized, tolerance: tolerance, maxIterations: maxIterations)
    }

    /// The algebraic connectivity λ₂: the second smallest eigenvalue of the Laplacian L (of the
    /// normalized Laplacian N with `normalized`), 0 exactly when the graph is not connected (a
    /// weight-0 edge does not connect). NetworkX `algebraic_connectivity`; Fiedler 1973.
    ///
    /// Thick-restart Lanczos (Wu–Simon) with full reorthogonalization, the null space projected
    /// out, from a fixed start vector: on σI − L (σ twice the largest weighted degree; 2I − N with
    /// `normalized`) while σ/λ₂ is moderate, else on L⁺ by shift-invert, each product a
    /// conjugate-gradient solve with L grounded at the vertex of largest degree. A Ritz pair is
    /// accepted when its residual is at most `tolerance` · λ₂, so λ₂ is relative to itself however
    /// the weights spread; the value is then the vector's Rayleigh quotient, a sum over edges. The
    /// dense solver below 64 vertices. O((n + m) · products) time; 31 n `Double`s (34 n from 5,000
    /// vertices, for the polynomial filter), and on the shift-invert path O(n + m) more for the
    /// solver.
    ///
    /// `weight` gives the weight of the edge at each position, read once per position; a weight of
    /// 0 is no edge.
    ///
    /// - Precondition: at least two vertices, and `tolerance > 0`. Every weight is finite and
    ///   nonnegative, and `maxIterations`, when given, is at least 1.
    /// - Throws: `NoConvergence` when the Lanczos run on L⁺ spends `maxIterations` matrix–vector
    ///   products (1,000 when nil) without converging, with the products spent and the Ritz
    ///   residual relative to 1/λ₂. The run on σI − L that may come first hands over to
    ///   shift-invert rather than throwing, after 4,000 + 20√n products or `maxIterations`,
    ///   whichever is smaller. Each shift-invert product is a conjugate-gradient solve that throws,
    ///   with its own iterations and relative residual, after 20,000 + 2n. Below 64 vertices the
    ///   dense solver answers and `maxIterations` is unused. Only a tolerance below rounding has
    ///   reached the default limits in the measurements.
    @inlinable
    public func algebraicConnectivity<W: BinaryInteger>(weight: (Edges.Index) -> W, normalized: Bool = false, tolerance: Double = 1e-8, maxIterations: Int? = nil) throws(NoConvergence) -> Double {
        precondition(tolerance > 0, "The tolerance is not positive")
        _checkMaxIterations(maxIterations)
        return try _spectralAdjacency(_spectralWeights(weight), numbering: nil).algebraicConnectivity(normalized: normalized, tolerance: tolerance, maxIterations: maxIterations)
    }

    /// The algebraic connectivity λ₂: the second smallest eigenvalue of the Laplacian L (of the
    /// normalized Laplacian N with `normalized`), 0 exactly when the graph is not connected (a
    /// weight-0 edge does not connect). NetworkX `algebraic_connectivity`; Fiedler 1973.
    ///
    /// Thick-restart Lanczos (Wu–Simon) with full reorthogonalization, the null space projected
    /// out, from a fixed start vector: on σI − L (σ twice the largest weighted degree; 2I − N with
    /// `normalized`) while σ/λ₂ is moderate, else on L⁺ by shift-invert, each product a
    /// conjugate-gradient solve with L grounded at the vertex of largest degree. A Ritz pair is
    /// accepted when its residual is at most `tolerance` · λ₂, so λ₂ is relative to itself however
    /// the weights spread; the value is then the vector's Rayleigh quotient, a sum over edges. The
    /// dense solver below 64 vertices. O((n + m) · products) time; 31 n `Double`s (34 n from 5,000
    /// vertices, for the polynomial filter), and on the shift-invert path O(n + m) more for the
    /// solver.
    ///
    /// `weight` gives the weight of the edge at each position, read once per position; a weight of
    /// 0 is no edge.
    ///
    /// - Precondition: at least two vertices, and `tolerance > 0`. Every weight is finite and
    ///   nonnegative, and `maxIterations`, when given, is at least 1.
    /// - Throws: `NoConvergence` when the Lanczos run on L⁺ spends `maxIterations` matrix–vector
    ///   products (1,000 when nil) without converging, with the products spent and the Ritz
    ///   residual relative to 1/λ₂. The run on σI − L that may come first hands over to
    ///   shift-invert rather than throwing, after 4,000 + 20√n products or `maxIterations`,
    ///   whichever is smaller. Each shift-invert product is a conjugate-gradient solve that throws,
    ///   with its own iterations and relative residual, after 20,000 + 2n. Below 64 vertices the
    ///   dense solver answers and `maxIterations` is unused. Only a tolerance below rounding has
    ///   reached the default limits in the measurements.
    @inlinable
    public func algebraicConnectivity<W: BinaryFloatingPoint>(weight: (Edges.Index) -> W, normalized: Bool = false, tolerance: Double = 1e-8, maxIterations: Int? = nil) throws(NoConvergence) -> Double {
        precondition(tolerance > 0, "The tolerance is not positive")
        _checkMaxIterations(maxIterations)
        return try _spectralAdjacency(_spectralWeights(weight), numbering: nil).algebraicConnectivity(normalized: normalized, tolerance: tolerance, maxIterations: maxIterations)
    }

    /// The Fiedler vector: λ₂ and a unit eigenvector of it, with the canonical sign (see
    /// `FiedlerVector`); nil when the graph is not connected. NetworkX `fiedler_vector`.
    ///
    /// Thick-restart Lanczos (Wu–Simon) with full reorthogonalization, the null space projected
    /// out, from a fixed start vector: on σI − L (σ twice the largest weighted degree; 2I − N with
    /// `normalized`) while σ/λ₂ is moderate, else on L⁺ by shift-invert, each product a
    /// conjugate-gradient solve with L grounded at the vertex of largest degree. A Ritz pair is
    /// accepted when its residual is at most `tolerance` · λ₂, so λ₂ is relative to itself however
    /// the weights spread; the value is then the vector's Rayleigh quotient, a sum over edges. The
    /// dense solver below 64 vertices. O((n + m) · products) time; 31 n `Double`s (34 n from 5,000
    /// vertices, for the polynomial filter), and on the shift-invert path O(n + m) more for the
    /// solver.
    ///
    /// - Precondition: at least two vertices, `tolerance > 0`, and `maxIterations`, when given, is
    ///   at least 1.
    /// - Throws: `NoConvergence` when the Lanczos run on L⁺ spends `maxIterations` matrix–vector
    ///   products (1,000 when nil) without converging, with the products spent and the Ritz
    ///   residual relative to 1/λ₂. The run on σI − L that may come first hands over to
    ///   shift-invert rather than throwing, after 4,000 + 20√n products or `maxIterations`,
    ///   whichever is smaller. Each shift-invert product is a conjugate-gradient solve that throws,
    ///   with its own iterations and relative residual, after 20,000 + 2n. Below 64 vertices the
    ///   dense solver answers and `maxIterations` is unused. Only a tolerance below rounding has
    ///   reached the default limits in the measurements.
    @inlinable
    public func fiedlerVector(normalized: Bool = false, tolerance: Double = 1e-8, maxIterations: Int? = nil) throws(NoConvergence) -> FiedlerVector<Self>? {
        precondition(tolerance > 0, "The tolerance is not positive")
        _checkMaxIterations(maxIterations)
        let weights: [Double]? = nil
        let numbering = _vertexNumbering()
        guard let (value, vector) = try _spectralAdjacency(weights, numbering: numbering).fiedler(normalized: normalized, tolerance: tolerance, maxIterations: maxIterations) else { return nil }
        return FiedlerVector(self, numbers: numbering?.numbers, algebraicConnectivity: value, values: vector)
    }

    /// The Fiedler vector: λ₂ and a unit eigenvector of it, with the canonical sign (see
    /// `FiedlerVector`); nil when the graph is not connected. NetworkX `fiedler_vector`.
    ///
    /// Thick-restart Lanczos (Wu–Simon) with full reorthogonalization, the null space projected
    /// out, from a fixed start vector: on σI − L (σ twice the largest weighted degree; 2I − N with
    /// `normalized`) while σ/λ₂ is moderate, else on L⁺ by shift-invert, each product a
    /// conjugate-gradient solve with L grounded at the vertex of largest degree. A Ritz pair is
    /// accepted when its residual is at most `tolerance` · λ₂, so λ₂ is relative to itself however
    /// the weights spread; the value is then the vector's Rayleigh quotient, a sum over edges. The
    /// dense solver below 64 vertices. O((n + m) · products) time; 31 n `Double`s (34 n from 5,000
    /// vertices, for the polynomial filter), and on the shift-invert path O(n + m) more for the
    /// solver.
    ///
    /// `weight` gives the weight of the edge at each position, read once per position; a weight of
    /// 0 is no edge.
    ///
    /// - Precondition: at least two vertices, and `tolerance > 0`. Every weight is finite and
    ///   nonnegative, and `maxIterations`, when given, is at least 1.
    /// - Throws: `NoConvergence` when the Lanczos run on L⁺ spends `maxIterations` matrix–vector
    ///   products (1,000 when nil) without converging, with the products spent and the Ritz
    ///   residual relative to 1/λ₂. The run on σI − L that may come first hands over to
    ///   shift-invert rather than throwing, after 4,000 + 20√n products or `maxIterations`,
    ///   whichever is smaller. Each shift-invert product is a conjugate-gradient solve that throws,
    ///   with its own iterations and relative residual, after 20,000 + 2n. Below 64 vertices the
    ///   dense solver answers and `maxIterations` is unused. Only a tolerance below rounding has
    ///   reached the default limits in the measurements.
    @inlinable
    public func fiedlerVector<W: BinaryInteger>(weight: (Edges.Index) -> W, normalized: Bool = false, tolerance: Double = 1e-8, maxIterations: Int? = nil) throws(NoConvergence) -> FiedlerVector<Self>? {
        precondition(tolerance > 0, "The tolerance is not positive")
        _checkMaxIterations(maxIterations)
        let weights = _spectralWeights(weight)
        let numbering = _vertexNumbering()
        guard let (value, vector) = try _spectralAdjacency(weights, numbering: numbering).fiedler(normalized: normalized, tolerance: tolerance, maxIterations: maxIterations) else { return nil }
        return FiedlerVector(self, numbers: numbering?.numbers, algebraicConnectivity: value, values: vector)
    }

    /// The Fiedler vector: λ₂ and a unit eigenvector of it, with the canonical sign (see
    /// `FiedlerVector`); nil when the graph is not connected. NetworkX `fiedler_vector`.
    ///
    /// Thick-restart Lanczos (Wu–Simon) with full reorthogonalization, the null space projected
    /// out, from a fixed start vector: on σI − L (σ twice the largest weighted degree; 2I − N with
    /// `normalized`) while σ/λ₂ is moderate, else on L⁺ by shift-invert, each product a
    /// conjugate-gradient solve with L grounded at the vertex of largest degree. A Ritz pair is
    /// accepted when its residual is at most `tolerance` · λ₂, so λ₂ is relative to itself however
    /// the weights spread; the value is then the vector's Rayleigh quotient, a sum over edges. The
    /// dense solver below 64 vertices. O((n + m) · products) time; 31 n `Double`s (34 n from 5,000
    /// vertices, for the polynomial filter), and on the shift-invert path O(n + m) more for the
    /// solver.
    ///
    /// `weight` gives the weight of the edge at each position, read once per position; a weight of
    /// 0 is no edge.
    ///
    /// - Precondition: at least two vertices, and `tolerance > 0`. Every weight is finite and
    ///   nonnegative, and `maxIterations`, when given, is at least 1.
    /// - Throws: `NoConvergence` when the Lanczos run on L⁺ spends `maxIterations` matrix–vector
    ///   products (1,000 when nil) without converging, with the products spent and the Ritz
    ///   residual relative to 1/λ₂. The run on σI − L that may come first hands over to
    ///   shift-invert rather than throwing, after 4,000 + 20√n products or `maxIterations`,
    ///   whichever is smaller. Each shift-invert product is a conjugate-gradient solve that throws,
    ///   with its own iterations and relative residual, after 20,000 + 2n. Below 64 vertices the
    ///   dense solver answers and `maxIterations` is unused. Only a tolerance below rounding has
    ///   reached the default limits in the measurements.
    @inlinable
    public func fiedlerVector<W: BinaryFloatingPoint>(weight: (Edges.Index) -> W, normalized: Bool = false, tolerance: Double = 1e-8, maxIterations: Int? = nil) throws(NoConvergence) -> FiedlerVector<Self>? {
        precondition(tolerance > 0, "The tolerance is not positive")
        _checkMaxIterations(maxIterations)
        let weights = _spectralWeights(weight)
        let numbering = _vertexNumbering()
        guard let (value, vector) = try _spectralAdjacency(weights, numbering: numbering).fiedler(normalized: normalized, tolerance: tolerance, maxIterations: maxIterations) else { return nil }
        return FiedlerVector(self, numbers: numbering?.numbers, algebraicConnectivity: value, values: vector)
    }

    /// The spectral ordering (NetworkX `spectral_ordering`; Barnard, Pothen and Simon): the
    /// components in order of their least vertex index; a component of at most two vertices in
    /// index order; a larger one ascending by the Fiedler vector of that component (for a connected
    /// graph, `fiedlerVector()`'s), entries within 10⁻⁸ · max|x| of their predecessor kept in
    /// index order. `[]` for the empty graph.
    ///
    /// Thick-restart Lanczos (Wu–Simon) with full reorthogonalization, the null space projected
    /// out, from a fixed start vector: on σI − L (σ twice the largest weighted degree; 2I − N with
    /// `normalized`) while σ/λ₂ is moderate, else on L⁺ by shift-invert, each product a
    /// conjugate-gradient solve with L grounded at the vertex of largest degree. A Ritz pair is
    /// accepted when its residual is at most `tolerance` · λ₂, so λ₂ is relative to itself however
    /// the weights spread; the value is then the vector's Rayleigh quotient, a sum over edges. The
    /// dense solver below 64 vertices. O((n + m) · products) time; 31 n `Double`s (34 n from 5,000
    /// vertices, for the polynomial filter), and on the shift-invert path O(n + m) more for the
    /// solver.
    ///
    /// - Precondition: `tolerance > 0`, and `maxIterations`, when given, is at least 1.
    /// - Throws: `NoConvergence` when the Lanczos run on L⁺ spends `maxIterations` matrix–vector
    ///   products (1,000 when nil) without converging, with the products spent and the Ritz
    ///   residual relative to 1/λ₂. The run on σI − L that may come first hands over to
    ///   shift-invert rather than throwing, after 4,000 + 20√n products or `maxIterations`,
    ///   whichever is smaller. Each shift-invert product is a conjugate-gradient solve that throws,
    ///   with its own iterations and relative residual, after 20,000 + 2n. Below 64 vertices the
    ///   dense solver answers and `maxIterations` is unused. Only a tolerance below rounding has
    ///   reached the default limits in the measurements.
    @inlinable
    public func spectralOrdering(normalized: Bool = false, tolerance: Double = 1e-8, maxIterations: Int? = nil) throws(NoConvergence) -> [Vertex] {
        precondition(tolerance > 0, "The tolerance is not positive")
        _checkMaxIterations(maxIterations)
        let weights: [Double]? = nil
        let numbering = _vertexNumbering()
        let order = try _spectralAdjacency(weights, numbering: numbering).spectralOrdering(normalized: normalized, tolerance: tolerance, maxIterations: maxIterations)
        return order.map { _vertex(number: $0, numbering?.listed) }
    }

    /// The spectral ordering (NetworkX `spectral_ordering`; Barnard, Pothen and Simon): the
    /// components in order of their least vertex index; a component of at most two vertices in
    /// index order; a larger one ascending by the Fiedler vector of that component (for a connected
    /// graph, `fiedlerVector()`'s), entries within 10⁻⁸ · max|x| of their predecessor kept in
    /// index order. `[]` for the empty graph.
    ///
    /// Thick-restart Lanczos (Wu–Simon) with full reorthogonalization, the null space projected
    /// out, from a fixed start vector: on σI − L (σ twice the largest weighted degree; 2I − N with
    /// `normalized`) while σ/λ₂ is moderate, else on L⁺ by shift-invert, each product a
    /// conjugate-gradient solve with L grounded at the vertex of largest degree. A Ritz pair is
    /// accepted when its residual is at most `tolerance` · λ₂, so λ₂ is relative to itself however
    /// the weights spread; the value is then the vector's Rayleigh quotient, a sum over edges. The
    /// dense solver below 64 vertices. O((n + m) · products) time; 31 n `Double`s (34 n from 5,000
    /// vertices, for the polynomial filter), and on the shift-invert path O(n + m) more for the
    /// solver.
    ///
    /// `weight` gives the weight of the edge at each position, read once per position; a weight of
    /// 0 is no edge.
    ///
    /// - Precondition: `tolerance > 0`. Every weight is finite and nonnegative, and
    ///   `maxIterations`, when given, is at least 1.
    /// - Throws: `NoConvergence` when the Lanczos run on L⁺ spends `maxIterations` matrix–vector
    ///   products (1,000 when nil) without converging, with the products spent and the Ritz
    ///   residual relative to 1/λ₂. The run on σI − L that may come first hands over to
    ///   shift-invert rather than throwing, after 4,000 + 20√n products or `maxIterations`,
    ///   whichever is smaller. Each shift-invert product is a conjugate-gradient solve that throws,
    ///   with its own iterations and relative residual, after 20,000 + 2n. Below 64 vertices the
    ///   dense solver answers and `maxIterations` is unused. Only a tolerance below rounding has
    ///   reached the default limits in the measurements.
    @inlinable
    public func spectralOrdering<W: BinaryInteger>(weight: (Edges.Index) -> W, normalized: Bool = false, tolerance: Double = 1e-8, maxIterations: Int? = nil) throws(NoConvergence) -> [Vertex] {
        precondition(tolerance > 0, "The tolerance is not positive")
        _checkMaxIterations(maxIterations)
        let weights = _spectralWeights(weight)
        let numbering = _vertexNumbering()
        let order = try _spectralAdjacency(weights, numbering: numbering).spectralOrdering(normalized: normalized, tolerance: tolerance, maxIterations: maxIterations)
        return order.map { _vertex(number: $0, numbering?.listed) }
    }

    /// The spectral ordering (NetworkX `spectral_ordering`; Barnard, Pothen and Simon): the
    /// components in order of their least vertex index; a component of at most two vertices in
    /// index order; a larger one ascending by the Fiedler vector of that component (for a connected
    /// graph, `fiedlerVector()`'s), entries within 10⁻⁸ · max|x| of their predecessor kept in
    /// index order. `[]` for the empty graph.
    ///
    /// Thick-restart Lanczos (Wu–Simon) with full reorthogonalization, the null space projected
    /// out, from a fixed start vector: on σI − L (σ twice the largest weighted degree; 2I − N with
    /// `normalized`) while σ/λ₂ is moderate, else on L⁺ by shift-invert, each product a
    /// conjugate-gradient solve with L grounded at the vertex of largest degree. A Ritz pair is
    /// accepted when its residual is at most `tolerance` · λ₂, so λ₂ is relative to itself however
    /// the weights spread; the value is then the vector's Rayleigh quotient, a sum over edges. The
    /// dense solver below 64 vertices. O((n + m) · products) time; 31 n `Double`s (34 n from 5,000
    /// vertices, for the polynomial filter), and on the shift-invert path O(n + m) more for the
    /// solver.
    ///
    /// `weight` gives the weight of the edge at each position, read once per position; a weight of
    /// 0 is no edge.
    ///
    /// - Precondition: `tolerance > 0`. Every weight is finite and nonnegative, and
    ///   `maxIterations`, when given, is at least 1.
    /// - Throws: `NoConvergence` when the Lanczos run on L⁺ spends `maxIterations` matrix–vector
    ///   products (1,000 when nil) without converging, with the products spent and the Ritz
    ///   residual relative to 1/λ₂. The run on σI − L that may come first hands over to
    ///   shift-invert rather than throwing, after 4,000 + 20√n products or `maxIterations`,
    ///   whichever is smaller. Each shift-invert product is a conjugate-gradient solve that throws,
    ///   with its own iterations and relative residual, after 20,000 + 2n. Below 64 vertices the
    ///   dense solver answers and `maxIterations` is unused. Only a tolerance below rounding has
    ///   reached the default limits in the measurements.
    @inlinable
    public func spectralOrdering<W: BinaryFloatingPoint>(weight: (Edges.Index) -> W, normalized: Bool = false, tolerance: Double = 1e-8, maxIterations: Int? = nil) throws(NoConvergence) -> [Vertex] {
        precondition(tolerance > 0, "The tolerance is not positive")
        _checkMaxIterations(maxIterations)
        let weights = _spectralWeights(weight)
        let numbering = _vertexNumbering()
        let order = try _spectralAdjacency(weights, numbering: numbering).spectralOrdering(normalized: normalized, tolerance: tolerance, maxIterations: maxIterations)
        return order.map { _vertex(number: $0, numbering?.listed) }
    }
}
