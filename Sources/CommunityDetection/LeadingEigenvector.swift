import GraphProtocols
import SpectralGraphTheory

/// B⁽ᵍ⁾ x for one community: its subgraph's rows in local numbers, the members' degrees and the
/// row sums of B⁽ᵍ⁾.
@frozen
@usableFromInline
struct _ModularityOperator {
    @usableFromInline let offsets: [Int]
    @usableFromInline let neighbors: [Int]
    @usableFromInline let weights: [Double]
    @usableFromInline let degrees: [Double]
    @usableFromInline let diagonal: [Double]
    @usableFromInline let m2: Double

    @inlinable
    init(offsets: [Int], neighbors: [Int], weights: [Double], degrees: [Double], diagonal: [Double], m2: Double) {
        self.offsets = offsets
        self.neighbors = neighbors
        self.weights = weights
        self.degrees = degrees
        self.diagonal = diagonal
        self.m2 = m2
    }

    /// y = A_g x − k (kᵀx) / 2m − diag(row sums) x.
    @inlinable
    func apply(_ x: UnsafePointer<Double>, _ y: UnsafeMutablePointer<Double>) {
        let s = degrees.count
        var kx = 0.0
        for i in 0 ..< s { kx += degrees[i] * x[i] }
        let factor = kx / m2
        for i in 0 ..< s {
            var sum = 0.0
            for slot in offsets[i] ..< offsets[i + 1] { sum += weights[slot] * x[neighbors[slot]] }
            y[i] = sum - degrees[i] * factor - diagonal[i] * x[i]
        }
    }
}

/// Newman's leading-eigenvector method (2006) in index space: from one community holding every
/// vertex, each community g is split by the signs of the leading eigenvector of its generalized
/// modularity matrix B⁽ᵍ⁾_ij = A_ij − k_i k_j / 2m − δ_ij Σ_{l ∈ g} (A_il − k_i k_l / 2m) (entries
/// positive on one side, negative on the other, entries 0 up to rounding together on the side of
/// greater gain) while its eigenvalue and the split's modularity
/// gain sᵀB⁽ᵍ⁾s / 4m are positive (beyond rounding); otherwise g is indivisible. Returns a label per
/// vertex.
@inlinable
func _leadingEigenvector(_ rows: _MergedRows, degrees k: [Double], tolerance: Double, maxIterations: Int?) throws(NoConvergence) -> [Int] {
    let n = rows.count
    var label = [Int](repeating: 0, count: n)
    var m2 = 0.0
    for x in k { m2 += x }
    guard m2 > 0 else { return Array(0 ..< n) }
    guard n > 1 else { return label }
    var count = 1
    var pending = [Array(0 ..< n)]
    var local = [Int](repeating: -1, count: n)
    while let members = pending.popLast() {
        let s = members.count
        guard s > 1 else { continue }
        for (i, v) in members.enumerated() { local[v] = i }
        // The community's subgraph in local numbers, and the row sums of B⁽ᵍ⁾: Σ_{l ∈ g} A_il −
        // k_i K_g / 2m.
        var kg = 0.0
        for v in members { kg += k[v] }
        var offsets = [Int](repeating: 0, count: s + 1)
        var neighbors: [Int] = [], weights: [Double] = []
        var degrees = [Double](repeating: 0, count: s)
        var diagonal = [Double](repeating: 0, count: s)
        var bound = 0.0
        for (i, v) in members.enumerated() {
            var inside = 0.0
            for slot in rows.offsets[v] ..< rows.offsets[v + 1] {
                let j = local[rows.neighbors[slot]]
                guard j >= 0 else { continue }
                neighbors.append(j)
                weights.append(rows.weights[slot])
                inside += rows.weights[slot]
            }
            offsets[i + 1] = neighbors.count
            degrees[i] = k[v]
            diagonal[i] = inside - k[v] * kg / m2
            bound = max(bound, 2 * (inside + k[v] * kg / m2))
        }
        for v in members { local[v] = -1 }
        let modularityOperator = _ModularityOperator(offsets: offsets, neighbors: neighbors, weights: weights, degrees: degrees, diagonal: diagonal, m2: m2)
        var value = 0.0, vector: [Double]
        if s < 64 {
            // Dense: B⁽ᵍ⁾ column by column, then the symmetric eigensolver.
            var matrix = [Double](repeating: 0, count: s * s)
            var unit = [Double](repeating: 0, count: s)
            var d = [Double](repeating: 0, count: s), e = d
            for j in 0 ..< s {
                unit[j] = 1
                unit.withUnsafeBufferPointer { x in matrix.withUnsafeMutableBufferPointer { modularityOperator.apply(x.baseAddress!, $0.baseAddress! + j * s) } }
                unit[j] = 0
            }
            try matrix.withUnsafeMutableBufferPointer { (a) throws(NoConvergence) in
                try d.withUnsafeMutableBufferPointer { (d) throws(NoConvergence) in
                    try e.withUnsafeMutableBufferPointer { (e) throws(NoConvergence) in
                        try _symmetricEigen(s, a.baseAddress!, d.baseAddress!, e.baseAddress!, vectors: true)
                    }
                }
            }
            value = d[s - 1]
            vector = Array(matrix[(s - 1) * s ..< s * s])
        } else {
            var products = 0
            let budget = maxIterations ?? max(10_000, 50 * s)
            let rule = _LanczosRule(tolerance: tolerance, shift: 0, floor: max(1e-6 * bound, 1e-300), abandonRatio: .infinity, budget: budget)
            guard let pair = try _largestEigenpair(count: s, null: nil, lowerBound: -bound, filters: false, rule: rule, products: &products, apply: { (x, y) throws(NoConvergence) in modularityOperator.apply(x, y) }) else {
                preconditionFailure("Lanczos without a shift abandoned")
            }
            (value, vector) = pair
        }
        let scale = max(bound, 1)
        // Entries > 0 on one side, < 0 on the other; entries that are 0 up to rounding go together
        // to whichever side gains more.
        var largest = 0.0
        for x in vector { largest = max(largest, abs(x)) }
        let zero = 1e-10 * largest
        var gain = -Double.infinity
        var split: [Double] = []
        if value > 1e-8 * scale {
            var y = [Double](repeating: 0, count: s)
            for zeroSide in [-1.0, 1.0] {
                var candidate = [Double](repeating: -1, count: s)
                var ones = 0
                for i in 0 ..< s {
                    if vector[i] > zero || (abs(vector[i]) <= zero && zeroSide > 0) { candidate[i] = 1 }
                    if candidate[i] > 0 { ones += 1 }
                }
                guard ones > 0, ones < s else { continue }
                candidate.withUnsafeBufferPointer { x in y.withUnsafeMutableBufferPointer { modularityOperator.apply(x.baseAddress!, $0.baseAddress!) } }
                var q = 0.0
                for i in 0 ..< s { q += candidate[i] * y[i] }
                if q > gain {
                    gain = q
                    split = candidate
                }
            }
        }
        guard gain > 1e-10 * scale * Double(s) else { continue }
        let other = count
        count += 1
        var first: [Int] = [], second: [Int] = []
        for (i, v) in members.enumerated() {
            if split[i] > 0 {
                label[v] = other
                second.append(v)
            } else {
                first.append(v)
            }
        }
        pending.append(first)
        pending.append(second)
    }
    return label
}

extension Graph {
    @inlinable
    func _leadingEigenvectorCommunities(_ weights: [Double]?, tolerance: Double, maxIterations: Int?) throws(NoConvergence) -> Partition<DirectedView<Self>> {
        precondition(tolerance > 0 && tolerance.isFinite, "The tolerance must be finite and greater than zero")
        precondition(maxIterations.map { $0 >= 1 } ?? true, "maxIterations must be at least 1")
        let listed = _listedVertices()
        let numbers = listed.map(_vertexNumbers)
        let rows = _mergedRows(weights)
        // Degrees as modularity counts them: a self-loop twice.
        var degree = [Double](repeating: 0, count: rows.count)
        for v in 0 ..< rows.count {
            for slot in rows.offsets[v] ..< rows.offsets[v + 1] { degree[v] += rows.weights[slot] }
        }
        let loops = _loopWeights(weights)
        for v in 0 ..< rows.count { degree[v] += 2 * loops[v] }
        let labels = try _leadingEigenvector(rows, degrees: degree, tolerance: tolerance, maxIterations: maxIterations)
        return Partition(directedView, numbers: numbers, listed: listed, labels: labels)
    }

    /// Leading-eigenvector communities (Newman 2006): repeated bisection by the signs of the leading
    /// eigenvector of each community's generalized modularity matrix B⁽ᵍ⁾, starting from one
    /// community, while the eigenvalue and the bisection's modularity gain are positive. The final
    /// partition does not depend on the order of the splits. Parallel edges add; self-loops count
    /// in the degrees only, as in `modularity(of:)`.
    ///
    /// - Parameters:
    ///   - tolerance: the relative residual at which an eigenpair is accepted (communities of 64
    ///     vertices or more, by Lanczos iteration; smaller ones are solved densely).
    ///   - maxIterations: the operator applications each Lanczos run may take; nil scales with the
    ///     community's size.
    /// - Returns: the communities, in canonical order; every vertex alone when the total weight is 0.
    /// - Complexity: O(m_g + s) per product with B⁽ᵍ⁾ on a community of s vertices and m_g
    ///   edges, times the Lanczos iterations of its split; O(s³) below 64 vertices.
    /// - Throws: `NoConvergence` when an eigenpair is not found within `maxIterations` products.
    /// - Precondition: `tolerance` is finite and greater than zero; `maxIterations`, when given, is
    ///   at least 1.
    @inlinable
    public func leadingEigenvectorCommunities(tolerance: Double = 1e-10, maxIterations: Int? = nil) throws(NoConvergence) -> Partition<DirectedView<Self>> {
        try _leadingEigenvectorCommunities(nil, tolerance: tolerance, maxIterations: maxIterations)
    }

    /// Weighted leading-eigenvector communities: A, k and m are weights. `weight` is called once
    /// per edge, in position order.
    ///
    /// - Throws: `NoConvergence` when an eigenpair is not found within `maxIterations` products.
    /// - Precondition: every weight is finite and at least zero; `tolerance` is finite and greater
    ///   than zero; `maxIterations`, when given, is at least 1.
    @inlinable
    public func leadingEigenvectorCommunities<W: BinaryFloatingPoint>(weight: (Edges.Index) -> W, tolerance: Double = 1e-10, maxIterations: Int? = nil) throws(NoConvergence) -> Partition<DirectedView<Self>> {
        try _leadingEigenvectorCommunities(_communityWeights(weight), tolerance: tolerance, maxIterations: maxIterations)
    }
}
