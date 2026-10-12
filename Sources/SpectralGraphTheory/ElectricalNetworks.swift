import GraphProtocols

extension Graph {
    /// The number of spanning trees τ(G), weighted: the sum over spanning trees of the product of
    /// their weights, which is any cofactor of the Laplacian (Kirchhoff's matrix-tree theorem).
    /// Loops never lie on a tree; parallel edges each count. 0 for the empty graph and for a
    /// disconnected one, 1 for one vertex. NetworkX `number_of_spanning_trees`.
    ///
    /// A `Double`: counts pass `Int` quickly (K₂₅ has 25²³). The Laplacian with one vertex removed
    /// is eliminated densely as Grassmann, Taksar and Heyman eliminate (each pivot a sum of
    /// conductances, never a difference), so the count keeps a relative accuracy of about n · 10⁻¹⁶
    /// whatever the weights; its pivots are multiplied with the binary exponent kept apart, so it
    /// overflows only past `Double`'s range, to `.infinity`. When every weight is an integer
    /// (unweighted included) and the count is below 2¹⁰⁰, it is computed exactly instead (two
    /// determinants modulo 62-bit primes, combined by the Chinese remainder theorem) and rounded
    /// once, so a count below 2⁵³ is exact. O(n³) time (less on sparse graphs), n² `Double`s.
    @inlinable
    public func numberOfSpanningTrees() -> Double {
        _spectralAdjacency(nil, numbering: nil).spanningTreeCount()
    }

    /// The number of spanning trees τ(G), weighted: the sum over spanning trees of the product of
    /// their weights, which is any cofactor of the Laplacian (Kirchhoff's matrix-tree theorem).
    /// Loops never lie on a tree; parallel edges each count. 0 for the empty graph and for a
    /// disconnected one, 1 for one vertex. NetworkX `number_of_spanning_trees`.
    ///
    /// A `Double`: counts pass `Int` quickly (K₂₅ has 25²³). The Laplacian with one vertex removed
    /// is eliminated densely as Grassmann, Taksar and Heyman eliminate (each pivot a sum of
    /// conductances, never a difference), so the count keeps a relative accuracy of about n · 10⁻¹⁶
    /// whatever the weights; its pivots are multiplied with the binary exponent kept apart, so it
    /// overflows only past `Double`'s range, to `.infinity`. When every weight is an integer
    /// (unweighted included) and the count is below 2¹⁰⁰, it is computed exactly instead (two
    /// determinants modulo 62-bit primes, combined by the Chinese remainder theorem) and rounded
    /// once, so a count below 2⁵³ is exact. O(n³) time (less on sparse graphs), n² `Double`s.
    ///
    /// `weight` gives the weight of the edge at each position, read once per position; a weight of
    /// 0 is no edge.
    ///
    /// - Precondition: every weight is finite and nonnegative.
    @inlinable
    public func numberOfSpanningTrees<W: BinaryInteger>(weight: (Edges.Index) -> W) -> Double {
        _spectralAdjacency(_spectralWeights(weight), numbering: nil).spanningTreeCount()
    }

    /// The number of spanning trees τ(G), weighted: the sum over spanning trees of the product of
    /// their weights, which is any cofactor of the Laplacian (Kirchhoff's matrix-tree theorem).
    /// Loops never lie on a tree; parallel edges each count. 0 for the empty graph and for a
    /// disconnected one, 1 for one vertex. NetworkX `number_of_spanning_trees`.
    ///
    /// A `Double`: counts pass `Int` quickly (K₂₅ has 25²³). The Laplacian with one vertex removed
    /// is eliminated densely as Grassmann, Taksar and Heyman eliminate (each pivot a sum of
    /// conductances, never a difference), so the count keeps a relative accuracy of about n · 10⁻¹⁶
    /// whatever the weights; its pivots are multiplied with the binary exponent kept apart, so it
    /// overflows only past `Double`'s range, to `.infinity`. When every weight is an integer
    /// (unweighted included) and the count is below 2¹⁰⁰, it is computed exactly instead (two
    /// determinants modulo 62-bit primes, combined by the Chinese remainder theorem) and rounded
    /// once, so a count below 2⁵³ is exact. O(n³) time (less on sparse graphs), n² `Double`s.
    ///
    /// `weight` gives the weight of the edge at each position, read once per position; a weight of
    /// 0 is no edge.
    ///
    /// - Precondition: every weight is finite and nonnegative.
    @inlinable
    public func numberOfSpanningTrees<W: BinaryFloatingPoint>(weight: (Edges.Index) -> W) -> Double {
        _spectralAdjacency(_spectralWeights(weight), numbering: nil).spanningTreeCount()
    }

    /// The resistance distance between `source` and `target` (Klein and Randić 1993): the
    /// effective resistance between them when each edge is a conductance (its weight; 1 without
    /// `weight:`), (e_s − e_t)ᵀ L⁺ (e_s − e_t). 0 when they are the same vertex, without reading
    /// any weight; nil when they lie in different components. Symmetric. NetworkX
    /// `resistance_distance`, whose default `invert_weight=True` reads weights as resistances
    /// instead: pass `{ 1 / r($0) }` for that.
    ///
    /// Conjugate gradients on the Laplacian grounded at `target`, from 0, until the residual's
    /// Euclidean norm is at most `tolerance` (relative to the right-hand side, which has norm 1),
    /// or, on a weight spread that puts that below rounding, until the true residual stops
    /// improving. Jacobi preconditioned for 300 iterations, then by a modified incomplete Cholesky
    /// factor in maximum-spanning-tree order. O((n + m) √κ) time; about 9 n words, and O(n + m) for
    /// the factor when it is built. Traps after 20,000 + 2n products, which no input has reached
    /// in the measurements.
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
    /// Conjugate gradients on the Laplacian grounded at `target`, from 0, until the residual's
    /// Euclidean norm is at most `tolerance` (relative to the right-hand side, which has norm 1),
    /// or, on a weight spread that puts that below rounding, until the true residual stops
    /// improving. Jacobi preconditioned for 300 iterations, then by a modified incomplete Cholesky
    /// factor in maximum-spanning-tree order. O((n + m) √κ) time; about 9 n words, and O(n + m) for
    /// the factor when it is built. Traps after 20,000 + 2n products, which no input has reached
    /// in the measurements.
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
    /// Conjugate gradients on the Laplacian grounded at `target`, from 0, until the residual's
    /// Euclidean norm is at most `tolerance` (relative to the right-hand side, which has norm 1),
    /// or, on a weight spread that puts that below rounding, until the true residual stops
    /// improving. Jacobi preconditioned for 300 iterations, then by a modified incomplete Cholesky
    /// factor in maximum-spanning-tree order. O((n + m) √κ) time; about 9 n words, and O(n + m) for
    /// the factor when it is built. Traps after 20,000 + 2n products, which no input has reached
    /// in the measurements.
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
    /// `effective_graph_resistance` (which returns ∞ when disconnected).
    ///
    /// n · tr(L_g⁻¹) − 1ᵀ L_g⁻¹ 1 with L_g the Laplacian grounded at the vertex of largest degree,
    /// from its GTH elimination (as `numberOfSpanningTrees`): every term is a sum of positive ones,
    /// so the result keeps a relative accuracy of about n² · 10⁻¹⁶ under any weight spread, where
    /// n · Σ 1/λᵢ over a dense spectrum loses it. O(n³) time, n² `Double`s.
    @inlinable
    public func effectiveGraphResistance() -> Double? {
        _spectralAdjacency(nil, numbering: nil).effectiveGraphResistance()
    }

    /// The effective graph resistance (the Kirchhoff index of Klein and Randić): the sum of
    /// `resistanceDistance` over unordered pairs of vertices, n · Σ_{i≥2} 1/λᵢ over the Laplacian
    /// spectrum; nil when the graph is not connected, 0 for zero or one vertex. NetworkX
    /// `effective_graph_resistance` (which returns ∞ when disconnected).
    ///
    /// n · tr(L_g⁻¹) − 1ᵀ L_g⁻¹ 1 with L_g the Laplacian grounded at the vertex of largest degree,
    /// from its GTH elimination (as `numberOfSpanningTrees`): every term is a sum of positive ones,
    /// so the result keeps a relative accuracy of about n² · 10⁻¹⁶ under any weight spread, where
    /// n · Σ 1/λᵢ over a dense spectrum loses it. O(n³) time, n² `Double`s.
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
    /// `effective_graph_resistance` (which returns ∞ when disconnected).
    ///
    /// n · tr(L_g⁻¹) − 1ᵀ L_g⁻¹ 1 with L_g the Laplacian grounded at the vertex of largest degree,
    /// from its GTH elimination (as `numberOfSpanningTrees`): every term is a sum of positive ones,
    /// so the result keeps a relative accuracy of about n² · 10⁻¹⁶ under any weight spread, where
    /// n · Σ 1/λᵢ over a dense spectrum loses it. O(n³) time, n² `Double`s.
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
    /// NetworkX `kemeny_constant`.
    ///
    /// vol · (Σᵢ πᵢ (L_g⁻¹)ᵢᵢ − πᵀ L_g⁻¹ π), π the stationary distribution, which is
    /// (1/2vol) Σᵢⱼ dᵢ dⱼ R(i, j) (commute times are vol · R), with L_g the Laplacian grounded at
    /// the vertex of largest degree and eliminated as for `numberOfSpanningTrees`. Every term is a
    /// sum of positive ones and the difference loses at most a factor n, so the result keeps its
    /// relative accuracy under any weight spread. O(n³) time, n² `Double`s.
    @inlinable
    public func kemenyConstant() -> Double? {
        _spectralAdjacency(nil, numbering: nil).kemenyConstant()
    }

    /// The Kemeny constant: the expected number of steps of the random walk (edge weights as
    /// transition rates, a loop taken with probability 2w/d(v)) from a vertex to a target drawn
    /// from the stationary distribution, which does not depend on the start; Σ_{i≥2} 1/μᵢ over the
    /// normalized Laplacian spectrum. nil when the graph is not connected, 0 for zero or one vertex.
    /// NetworkX `kemeny_constant`.
    ///
    /// vol · (Σᵢ πᵢ (L_g⁻¹)ᵢᵢ − πᵀ L_g⁻¹ π), π the stationary distribution, which is
    /// (1/2vol) Σᵢⱼ dᵢ dⱼ R(i, j) (commute times are vol · R), with L_g the Laplacian grounded at
    /// the vertex of largest degree and eliminated as for `numberOfSpanningTrees`. Every term is a
    /// sum of positive ones and the difference loses at most a factor n, so the result keeps its
    /// relative accuracy under any weight spread. O(n³) time, n² `Double`s.
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
    /// NetworkX `kemeny_constant`.
    ///
    /// vol · (Σᵢ πᵢ (L_g⁻¹)ᵢᵢ − πᵀ L_g⁻¹ π), π the stationary distribution, which is
    /// (1/2vol) Σᵢⱼ dᵢ dⱼ R(i, j) (commute times are vol · R), with L_g the Laplacian grounded at
    /// the vertex of largest degree and eliminated as for `numberOfSpanningTrees`. Every term is a
    /// sum of positive ones and the difference loses at most a factor n, so the result keeps its
    /// relative accuracy under any weight spread. O(n³) time, n² `Double`s.
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
