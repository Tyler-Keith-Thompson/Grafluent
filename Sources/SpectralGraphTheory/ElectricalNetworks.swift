import GraphProtocols

extension Graph {
    /// The number of spanning trees τ(G), weighted: the sum over spanning trees of the product of
    /// their weights, which is any cofactor of the Laplacian (Kirchhoff's matrix-tree theorem).
    /// Loops never lie on a tree; parallel edges each count. 0 for the empty graph and for a
    /// disconnected one, 1 for one vertex. NetworkX `number_of_spanning_trees`.
    ///
    /// A `Double`: counts pass `Int` quickly (K₂₅ has 25²³). A dense Cholesky factorization of the
    /// Laplacian with one vertex removed, its pivots multiplied with the binary exponent kept apart,
    /// so the result overflows only past `Double`'s range, to `.infinity`. When every weight is an
    /// integer (unweighted included) a result below 2⁵³ is rounded to the nearest integer, which is
    /// then exact; nearer to 2⁵³ and above, it is within a relative 10⁻¹² or so, not exact. O(n³) time,
    /// n² `Double`s.
    @inlinable
    public func numberOfSpanningTrees() -> Double {
        _spectralAdjacency(nil, numbering: nil).spanningTreeCount(integral: true)
    }

    /// The number of spanning trees τ(G), weighted: the sum over spanning trees of the product of
    /// their weights, which is any cofactor of the Laplacian (Kirchhoff's matrix-tree theorem).
    /// Loops never lie on a tree; parallel edges each count. 0 for the empty graph and for a
    /// disconnected one, 1 for one vertex. NetworkX `number_of_spanning_trees`.
    ///
    /// A `Double`: counts pass `Int` quickly (K₂₅ has 25²³). A dense Cholesky factorization of the
    /// Laplacian with one vertex removed, its pivots multiplied with the binary exponent kept apart,
    /// so the result overflows only past `Double`'s range, to `.infinity`. When every weight is an
    /// integer (unweighted included) a result below 2⁵³ is rounded to the nearest integer, which is
    /// then exact; nearer to 2⁵³ and above, it is within a relative 10⁻¹² or so, not exact. O(n³) time,
    /// n² `Double`s.
    ///
    /// `weight` gives the weight of the edge at each position, read once per position; a weight of
    /// 0 is no edge.
    ///
    /// - Precondition: every weight is finite and nonnegative.
    @inlinable
    public func numberOfSpanningTrees<W: BinaryInteger>(weight: (Edges.Index) -> W) -> Double {
        _spectralAdjacency(_spectralWeights(weight), numbering: nil).spanningTreeCount(integral: true)
    }

    /// The number of spanning trees τ(G), weighted: the sum over spanning trees of the product of
    /// their weights, which is any cofactor of the Laplacian (Kirchhoff's matrix-tree theorem).
    /// Loops never lie on a tree; parallel edges each count. 0 for the empty graph and for a
    /// disconnected one, 1 for one vertex. NetworkX `number_of_spanning_trees`.
    ///
    /// A `Double`: counts pass `Int` quickly (K₂₅ has 25²³). A dense Cholesky factorization of the
    /// Laplacian with one vertex removed, its pivots multiplied with the binary exponent kept apart,
    /// so the result overflows only past `Double`'s range, to `.infinity`. When every weight is an
    /// integer (unweighted included) a result below 2⁵³ is rounded to the nearest integer, which is
    /// then exact; nearer to 2⁵³ and above, it is within a relative 10⁻¹² or so, not exact. O(n³) time,
    /// n² `Double`s.
    ///
    /// `weight` gives the weight of the edge at each position, read once per position; a weight of
    /// 0 is no edge.
    ///
    /// - Precondition: every weight is finite and nonnegative.
    @inlinable
    public func numberOfSpanningTrees<W: BinaryFloatingPoint>(weight: (Edges.Index) -> W) -> Double {
        let weights = _spectralWeights(weight)
        return _spectralAdjacency(weights, numbering: nil).spanningTreeCount(integral: weights.allSatisfy { $0 == $0.rounded() })
    }

    /// The resistance distance between `source` and `target` (Klein and Randić 1993): the
    /// effective resistance between them when each edge is a conductance (its weight; 1 without
    /// `weight:`), (e_s − e_t)ᵀ L⁺ (e_s − e_t). 0 when they are the same vertex, without reading
    /// any weight; nil when they lie in different components. Symmetric. NetworkX
    /// `resistance_distance`, whose default `invert_weight=True` reads weights as resistances
    /// instead: pass `{ 1 / r($0) }` for that.
    ///
    /// Conjugate gradients, Jacobi preconditioned, on the Laplacian grounded at `target` and
    /// restricted to its component, from 0, until the residual's Euclidean norm is at most
    /// `tolerance` (relative to the right-hand side, which has norm 1): O((n + m) √κ) time, 5 n
    /// `Double`s.
    ///
    /// - Precondition: `source` and `target` are vertices of the graph, and `tolerance > 0`.
    @inlinable
    public func resistanceDistance(from source: Vertex, to target: Vertex, tolerance: Double = 1e-10) -> Double? {
        precondition(tolerance > 0, "The tolerance is not positive")
        let numbering = _vertexNumbering()
        let s = _spectralNumber(of: source, numbering), t = _spectralNumber(of: target, numbering)
        if s == t { return 0 }
        return _spectralAdjacency(nil, numbering: numbering).resistance(from: s, to: t, tolerance: tolerance)
    }

    /// The resistance distance between `source` and `target` (Klein and Randić 1993): the
    /// effective resistance between them when each edge is a conductance (its weight; 1 without
    /// `weight:`), (e_s − e_t)ᵀ L⁺ (e_s − e_t). 0 when they are the same vertex, without reading
    /// any weight; nil when they lie in different components. Symmetric. NetworkX
    /// `resistance_distance`, whose default `invert_weight=True` reads weights as resistances
    /// instead: pass `{ 1 / r($0) }` for that.
    ///
    /// Conjugate gradients, Jacobi preconditioned, on the Laplacian grounded at `target` and
    /// restricted to its component, from 0, until the residual's Euclidean norm is at most
    /// `tolerance` (relative to the right-hand side, which has norm 1): O((n + m) √κ) time, 5 n
    /// `Double`s.
    ///
    /// `weight` gives the conductance of the edge at each position, read once per position (every
    /// position, also outside the component); a weight of 0 is no edge.
    ///
    /// - Precondition: `source` and `target` are vertices of the graph, every weight is finite and
    ///   nonnegative, and `tolerance > 0`.
    @inlinable
    public func resistanceDistance<W: BinaryInteger>(from source: Vertex, to target: Vertex, weight: (Edges.Index) -> W, tolerance: Double = 1e-10) -> Double? {
        precondition(tolerance > 0, "The tolerance is not positive")
        let numbering = _vertexNumbering()
        let s = _spectralNumber(of: source, numbering), t = _spectralNumber(of: target, numbering)
        if s == t { return 0 }
        return _spectralAdjacency(_spectralWeights(weight), numbering: numbering).resistance(from: s, to: t, tolerance: tolerance)
    }

    /// The resistance distance between `source` and `target` (Klein and Randić 1993): the
    /// effective resistance between them when each edge is a conductance (its weight; 1 without
    /// `weight:`), (e_s − e_t)ᵀ L⁺ (e_s − e_t). 0 when they are the same vertex, without reading
    /// any weight; nil when they lie in different components. Symmetric. NetworkX
    /// `resistance_distance`, whose default `invert_weight=True` reads weights as resistances
    /// instead: pass `{ 1 / r($0) }` for that.
    ///
    /// Conjugate gradients, Jacobi preconditioned, on the Laplacian grounded at `target` and
    /// restricted to its component, from 0, until the residual's Euclidean norm is at most
    /// `tolerance` (relative to the right-hand side, which has norm 1): O((n + m) √κ) time, 5 n
    /// `Double`s.
    ///
    /// `weight` gives the conductance of the edge at each position, read once per position (every
    /// position, also outside the component); a weight of 0 is no edge.
    ///
    /// - Precondition: `source` and `target` are vertices of the graph, every weight is finite and
    ///   nonnegative, and `tolerance > 0`.
    @inlinable
    public func resistanceDistance<W: BinaryFloatingPoint>(from source: Vertex, to target: Vertex, weight: (Edges.Index) -> W, tolerance: Double = 1e-10) -> Double? {
        precondition(tolerance > 0, "The tolerance is not positive")
        let numbering = _vertexNumbering()
        let s = _spectralNumber(of: source, numbering), t = _spectralNumber(of: target, numbering)
        if s == t { return 0 }
        return _spectralAdjacency(_spectralWeights(weight), numbering: numbering).resistance(from: s, to: t, tolerance: tolerance)
    }

    /// The effective graph resistance (the Kirchhoff index of Klein and Randić): the sum of
    /// `resistanceDistance` over unordered pairs of vertices, n · Σ_{i≥2} 1/λᵢ over the Laplacian
    /// spectrum; nil when the graph is not connected, 0 for zero or one vertex. NetworkX
    /// `effective_graph_resistance` (which returns ∞ when disconnected). Dense: O(n³) time.
    @inlinable
    public func effectiveGraphResistance() -> Double? {
        _spectralAdjacency(nil, numbering: nil).effectiveGraphResistance()
    }

    /// The effective graph resistance (the Kirchhoff index of Klein and Randić): the sum of
    /// `resistanceDistance` over unordered pairs of vertices, n · Σ_{i≥2} 1/λᵢ over the Laplacian
    /// spectrum; nil when the graph is not connected, 0 for zero or one vertex. NetworkX
    /// `effective_graph_resistance` (which returns ∞ when disconnected). Dense: O(n³) time.
    ///
    /// `weight` gives the weight of the edge at each position, read once per position; a weight of
    /// 0 is no edge.
    ///
    /// - Precondition: every weight is finite and nonnegative.
    @inlinable
    public func effectiveGraphResistance<W: BinaryInteger>(weight: (Edges.Index) -> W) -> Double? {
        _spectralAdjacency(_spectralWeights(weight), numbering: nil).effectiveGraphResistance()
    }

    /// The effective graph resistance (the Kirchhoff index of Klein and Randić): the sum of
    /// `resistanceDistance` over unordered pairs of vertices, n · Σ_{i≥2} 1/λᵢ over the Laplacian
    /// spectrum; nil when the graph is not connected, 0 for zero or one vertex. NetworkX
    /// `effective_graph_resistance` (which returns ∞ when disconnected). Dense: O(n³) time.
    ///
    /// `weight` gives the weight of the edge at each position, read once per position; a weight of
    /// 0 is no edge.
    ///
    /// - Precondition: every weight is finite and nonnegative.
    @inlinable
    public func effectiveGraphResistance<W: BinaryFloatingPoint>(weight: (Edges.Index) -> W) -> Double? {
        _spectralAdjacency(_spectralWeights(weight), numbering: nil).effectiveGraphResistance()
    }

    /// The Kemeny constant: the expected number of steps of the random walk (edge weights as
    /// transition rates, a loop taken with probability 2w/d(v)) from a vertex to a target drawn
    /// from the stationary distribution, which does not depend on the start; Σ_{i≥2} 1/μᵢ over the
    /// normalized Laplacian spectrum. nil when the graph is not connected, 0 for zero or one vertex.
    /// NetworkX `kemeny_constant`. Dense: O(n³) time.
    @inlinable
    public func kemenyConstant() -> Double? {
        _spectralAdjacency(nil, numbering: nil).kemenyConstant()
    }

    /// The Kemeny constant: the expected number of steps of the random walk (edge weights as
    /// transition rates, a loop taken with probability 2w/d(v)) from a vertex to a target drawn
    /// from the stationary distribution, which does not depend on the start; Σ_{i≥2} 1/μᵢ over the
    /// normalized Laplacian spectrum. nil when the graph is not connected, 0 for zero or one vertex.
    /// NetworkX `kemeny_constant`. Dense: O(n³) time.
    ///
    /// `weight` gives the weight of the edge at each position, read once per position; a weight of
    /// 0 is no edge.
    ///
    /// - Precondition: every weight is finite and nonnegative.
    @inlinable
    public func kemenyConstant<W: BinaryInteger>(weight: (Edges.Index) -> W) -> Double? {
        _spectralAdjacency(_spectralWeights(weight), numbering: nil).kemenyConstant()
    }

    /// The Kemeny constant: the expected number of steps of the random walk (edge weights as
    /// transition rates, a loop taken with probability 2w/d(v)) from a vertex to a target drawn
    /// from the stationary distribution, which does not depend on the start; Σ_{i≥2} 1/μᵢ over the
    /// normalized Laplacian spectrum. nil when the graph is not connected, 0 for zero or one vertex.
    /// NetworkX `kemeny_constant`. Dense: O(n³) time.
    ///
    /// `weight` gives the weight of the edge at each position, read once per position; a weight of
    /// 0 is no edge.
    ///
    /// - Precondition: every weight is finite and nonnegative.
    @inlinable
    public func kemenyConstant<W: BinaryFloatingPoint>(weight: (Edges.Index) -> W) -> Double? {
        _spectralAdjacency(_spectralWeights(weight), numbering: nil).kemenyConstant()
    }
}
