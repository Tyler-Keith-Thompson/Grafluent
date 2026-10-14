import GraphProtocols
import SpectralGraphTheory

extension Graph {
    /// A drawing whose axes are eigenvectors of the Laplacian: x is the eigenvector of the second
    /// smallest eigenvalue of L = D − A (the Fiedler vector of a connected graph) and y that of
    /// the third, both of unit length, in `vertices` order.
    ///
    /// A is the weighted adjacency matrix: parallel edges add their weights, self-loops are
    /// ignored, and a weight of 0 is no edge. The eigenvalues are sorted ascending with their
    /// multiplicity, so a graph with c components has c zero eigenvalues and its axes come from
    /// eigenvectors of 0 when c > 1 (which ones is fixed by the solver, not specified). Each axis's
    /// sign makes its first entry, in `vertices` order, whose magnitude is at least 10⁻⁴ of its
    /// largest positive. Two vertices have y = 0, and one vertex is at the origin. The drawing is
    /// not rescaled (`rescaled(scale:center:)` maps it to a common frame). A directed graph is
    /// drawn through `undirectedView`.
    ///
    /// Dense: Householder tridiagonalization and the implicit QL iteration, O(n³) time and n²
    /// `Double`s, for graphs of up to a few thousand vertices.
    ///
    /// - Koren, "Drawing graphs by eigenvectors: theory and practice", Computers & Mathematics with
    ///   Applications 49(11–12), 2005.
    ///
    /// - Precondition: every weight is finite and not negative; `maxIterations`, when given, is at
    ///   least 1.
    /// - Throws: `NoConvergence` after `maxIterations` QL iterations in all (30 n when nil), with
    ///   that count and the off-diagonal entry being reduced, relative to the largest entry of its
    ///   block. The iteration converges cubically, about two iterations per eigenvalue.
    @inlinable
    public func spectralLayout(weight: (Edges.Index) -> Double = { _ in 1 }, maxIterations: Int? = nil) throws(NoConvergence) -> Drawing<Vertex> {
        let limit = _eigenIterationLimit(maxIterations, vertexCount)
        let edges = _drawingEdges(weight)
        return edges.drawing(try _spectralPositions(count: edges.vertexCount, us: edges.us, vs: edges.vs, weights: edges.values, maxIterations: limit))
    }

    /// A drawing by classical multidimensional scaling of the shortest-path distances: the
    /// coordinates of the best rank-2 approximation of the doubly centred squared distances.
    ///
    /// The distance d_ij of two vertices is their shortest-path distance with `edgeLength` (hops by
    /// default); between components it is 1 + L̄·√n, L̄ the mean edge length, as in
    /// `stressMajorizationLayout()`. With B = −½ J D⁽²⁾ J (D⁽²⁾ the squared distances, J the centring
    /// matrix), x is √λ₁ · v₁ and y is √λ₂ · v₂ for the two largest eigenvalues λ₁ ≥ λ₂ of B and
    /// their unit eigenvectors (a negative eigenvalue gives 0). When the distances are Euclidean
    /// in the plane, the drawing reproduces them exactly, up to a rigid motion. Each axis's sign
    /// makes its first entry, in `vertices` order, whose magnitude is at least 10⁻⁴ of its
    /// largest positive. The drawing is centred on the origin. A directed graph is drawn through
    /// `undirectedView`.
    ///
    /// - Torgerson, "Multidimensional scaling: I. Theory and method", Psychometrika 17(4), 1952.
    ///
    /// O(n·(n + m)) for the distances by breadth-first search (O(n·m log n) by Dijkstra when the
    /// lengths differ), then O(n³) for the dense eigensystem; n² `Double`s.
    ///
    /// - Precondition: every edge length is positive and finite; `maxIterations`, when given, is at
    ///   least 1.
    /// - Throws: `NoConvergence` after `maxIterations` QL iterations in all (30 n when nil), as
    ///   `spectralLayout(weight:maxIterations:)`.
    @inlinable
    public func multidimensionalScalingLayout(edgeLength: (Edges.Index) -> Double = { _ in 1 }, maxIterations: Int? = nil) throws(NoConvergence) -> Drawing<Vertex> {
        let limit = _eigenIterationLimit(maxIterations, vertexCount)
        let edges = _drawingEdges(edgeLength)
        return edges.drawing(try _scalingPositions(count: edges.vertexCount, us: edges.us, vs: edges.vs, lengths: edges.values, maxIterations: limit))
    }
}

/// Columns 1 and 2 of the Laplacian's eigenvectors, ascending, as points.
@usableFromInline
func _spectralPositions(count n: Int, us: [Int], vs: [Int], weights: [Double], maxIterations: Int) throws(NoConvergence) -> [SIMD2<Double>] {
    var largest = 0.0
    for w in weights {
        precondition(w.isFinite && w >= 0, "Every weight must be finite and not negative")
        largest = Swift.max(largest, w)
    }
    if n <= 1 { return [SIMD2<Double>](repeating: .zero, count: n) }
    // Scaled by a power of two so the degrees cannot overflow; eigenvectors do not change.
    let scale = _powerOfTwoScale(largest)
    var laplacian = [Double](repeating: 0, count: n * n)
    for e in 0 ..< us.count {
        let u = us[e], v = vs[e], w = weights[e] * scale
        laplacian[u * n + u] += w
        laplacian[v * n + v] += w
        laplacian[u * n + v] -= w
        laplacian[v * n + u] -= w
    }
    var (_, vectors) = try _symmetricEigensystem(laplacian, n, maxIterations: maxIterations)
    let columns = n >= 3 ? 2 : 1
    vectors.withUnsafeMutableBufferPointer { vectors in
        for c in 1 ... columns { _fixEigenvectorSign(UnsafeMutableBufferPointer(rebasing: vectors[c * n ..< c * n + n])) }
    }
    var positions = [SIMD2<Double>](repeating: .zero, count: n)
    for i in 0 ..< n { positions[i] = SIMD2(vectors[n + i], columns == 2 ? vectors[2 * n + i] : 0) }
    return positions
}

/// Classical scaling of the shortest-path distances, as points.
@usableFromInline
func _scalingPositions(count n: Int, us: [Int], vs: [Int], lengths: [Double], maxIterations: Int) throws(NoConvergence) -> [SIMD2<Double>] {
    for x in lengths { precondition(x.isFinite && x > 0, "Every edge length must be positive and finite") }
    if n <= 1 { return [SIMD2<Double>](repeating: .zero, count: n) }
    let mean = lengths.isEmpty ? 1 : lengths.reduce(0, +) / Double(lengths.count)
    let apart = 1 + mean * Double(n).squareRoot()
    var b = [Double](repeating: 0, count: n * n)
    var largest = 0.0
    _eachDistanceRow(count: n, us: us, vs: vs, lengths: lengths) { s, distance in
        for v in 0 ..< n {
            let d = distance[v] < 0 ? apart : distance[v]
            b[s * n + v] = d
            largest = Swift.max(largest, d)
        }
    }
    // Squared after scaling by a power of two, so they cannot overflow; undone on the axes.
    let scale = _powerOfTwoScale(largest)
    var rowMeans = [Double](repeating: 0, count: n)
    for s in 0 ..< n {
        var sum = 0.0
        for v in 0 ..< n {
            let d = b[s * n + v] * scale
            b[s * n + v] = d * d
            sum += d * d
        }
        rowMeans[s] = sum / Double(n)
    }
    let grandMean = rowMeans.reduce(0, +) / Double(n)
    for s in 0 ..< n {
        for v in 0 ..< n { b[s * n + v] = -0.5 * (b[s * n + v] - rowMeans[s] - rowMeans[v] + grandMean) }
    }
    var (values, vectors) = try _symmetricEigensystem(b, n, maxIterations: maxIterations)
    vectors.withUnsafeMutableBufferPointer { vectors in
        for c in n - 2 ..< n { _fixEigenvectorSign(UnsafeMutableBufferPointer(rebasing: vectors[c * n ..< c * n + n])) }
    }
    let sx = Swift.max(values[n - 1], 0).squareRoot() / scale, sy = Swift.max(values[n - 2], 0).squareRoot() / scale
    var positions = [SIMD2<Double>](repeating: .zero, count: n)
    for i in 0 ..< n { positions[i] = SIMD2(sx * vectors[(n - 1) * n + i], sy * vectors[(n - 2) * n + i]) }
    return positions
}

/// The eigenvalues of the symmetric `n` × `n` matrix `a` (column-major; for a symmetric matrix
/// also row-major), ascending, and orthonormal eigenvectors, column `j` of `vectors` (entries
/// `j * n ..< j * n + n`) belonging to `values[j]`: `SpectralGraphTheory`'s dense solver
/// (Householder tridiagonalization and the implicit QL iteration). Throws `NoConvergence` once the
/// QL iteration has spent `maxIterations` iterations in all, with that count and the off-diagonal
/// entry being reduced relative to the largest |d| + |e| seen. O(n³) time, n² doubles.
@usableFromInline
func _symmetricEigensystem(_ a: [Double], _ n: Int, maxIterations: Int) throws(NoConvergence) -> (values: [Double], vectors: [Double]) {
    var v = a
    var d = [Double](repeating: 0, count: n)
    var e = [Double](repeating: 0, count: n)
    guard n > 0 else { return ([], []) }
    try v.withUnsafeMutableBufferPointer { (v) throws(NoConvergence) in
        try d.withUnsafeMutableBufferPointer { (d) throws(NoConvergence) in
            try e.withUnsafeMutableBufferPointer { (e) throws(NoConvergence) in
                try _symmetricEigen(n, v.baseAddress!, d.baseAddress!, e.baseAddress!, vectors: true, maxIterations: maxIterations)
            }
        }
    }
    return (d, v)
}

/// Flips `column` so that its first entry, in index order, whose magnitude is at least 10⁻⁴ of the
/// largest is positive: an eigenvector's sign, fixed.
@inline(__always)
func _fixEigenvectorSign(_ column: UnsafeMutableBufferPointer<Double>) {
    var largest = 0.0
    for x in column { largest = Swift.max(largest, Swift.abs(x)) }
    for x in column where Swift.abs(x) >= 1e-4 * largest {
        if x < 0 { for k in column.indices { column[k] = -column[k] } }
        return
    }
}

/// The power of two that brings `largest` to [1, 2) (as near as a normal power of two reaches), as
/// a multiplier: scaling by it is exact unless a value underflows. 1 for 0.
@inline(__always)
func _powerOfTwoScale(_ largest: Double) -> Double {
    guard largest > 0 && largest.isFinite else { return 1 }
    let exponent = Swift.min(Swift.max(-Int(largest.exponent), -1022), 1023)
    return Double(sign: .plus, exponent: exponent, significand: 1)
}

/// The default iteration limit of the QL iteration: 30 per eigenvalue.
@usableFromInline
func _eigenIterationLimit(_ maxIterations: Int?, _ n: Int) -> Int {
    if let maxIterations {
        precondition(maxIterations >= 1, "maxIterations must be at least 1")
        return maxIterations
    }
    return Swift.max(30 * n, 1)
}
