import GraphProtocols
import SpectralGraphTheory

/// k-means on the n points of `points` (point i at i · dimensions): the run of least inertia (sum
/// of squared distances to the assigned center; the first on ties) of `runs` runs, each seeded by
/// k-means++ (Arthur and Vassilvitskii 2007) and refined by Lloyd's iteration until no assignment
/// changes, or 300 iterations. A point goes to the nearest center, the least on ties. A cluster
/// left empty takes the point farthest from its center among clusters of two or more, so every
/// cluster is nonempty. Returns each point's cluster in `0..<clusters`.
@inlinable
func _kMeans<R: RandomNumberGenerator>(_ points: [Double], count n: Int, dimensions k: Int, clusters c: Int, runs: Int, using generator: inout R) -> [Int] {
    precondition(c >= 1 && c <= n, "The cluster count is not in 1...vertexCount")
    var best: [Int] = []
    var bestInertia = Double.infinity
    // Flat scratch, so the loops below index without bounds checks or copy-on-write tests.
    let doubles = UnsafeMutablePointer<Double>.allocate(capacity: c * k + n)
    let ints = UnsafeMutablePointer<Int>.allocate(capacity: n + c)
    defer {
        doubles.deallocate()
        ints.deallocate()
    }
    let centers = doubles, distance = doubles + c * k
    let labels = ints, sizes = ints + n
    labels.update(repeating: 0, count: n)
    return points.withUnsafeBufferPointer { buffer in
        let points = buffer.baseAddress!
        for _ in 0 ..< runs {
            // k-means++ seeding: each next center drawn with probability ∝ the squared distance to
            // the nearest center so far.
            let first = Int.random(in: 0 ..< n, using: &generator)
            for j in 0 ..< k { centers[j] = points[first * k + j] }
            for i in 0 ..< n {
                var s = 0.0
                for j in 0 ..< k {
                    let t = points[i * k + j] - centers[j]
                    s += t * t
                }
                distance[i] = s
            }
            for center in 1 ..< c {
                var total = 0.0
                for i in 0 ..< n { total += distance[i] }
                var chosen = n - 1
                if total > 0 {
                    let r = Double.random(in: 0 ..< total, using: &generator)
                    var sum = 0.0
                    for i in 0 ..< n {
                        sum += distance[i]
                        if sum > r {
                            chosen = i
                            break
                        }
                    }
                } else {
                    chosen = Int.random(in: 0 ..< n, using: &generator)
                }
                for j in 0 ..< k { centers[center * k + j] = points[chosen * k + j] }
                for i in 0 ..< n {
                    var s = 0.0
                    for j in 0 ..< k {
                        let t = points[i * k + j] - centers[center * k + j]
                        s += t * t
                    }
                    if s < distance[i] { distance[i] = s }
                }
            }
            // Lloyd's iteration.
            for iteration in 0 ..< 300 {
                var changed = false
                for i in 0 ..< n {
                    var nearest = 0
                    var least = Double.infinity
                    for center in 0 ..< c {
                        var s = 0.0
                        for j in 0 ..< k {
                            let t = points[i * k + j] - centers[center * k + j]
                            s += t * t
                        }
                        if s < least {
                            least = s
                            nearest = center
                        }
                    }
                    if iteration == 0 || labels[i] != nearest { changed = true }
                    labels[i] = nearest
                    distance[i] = least
                }
                for center in 0 ..< c { sizes[center] = 0 }
                for i in 0 ..< n { sizes[labels[i]] += 1 }
                for center in 0 ..< c where sizes[center] == 0 {
                    var farthest = -1
                    for i in 0 ..< n where sizes[labels[i]] > 1 && (farthest < 0 || distance[i] > distance[farthest]) { farthest = i }
                    sizes[labels[farthest]] -= 1
                    labels[farthest] = center
                    sizes[center] = 1
                    distance[farthest] = 0
                    for j in 0 ..< k { centers[center * k + j] = points[farthest * k + j] }
                    changed = true
                }
                guard changed else { break }
                // The means.
                for t in 0 ..< c * k { centers[t] = 0 }
                for i in 0 ..< n {
                    for j in 0 ..< k { centers[labels[i] * k + j] += points[i * k + j] }
                }
                for center in 0 ..< c {
                    let inverse = 1 / Double(sizes[center])
                    for j in 0 ..< k { centers[center * k + j] *= inverse }
                }
            }
            var inertia = 0.0
            for i in 0 ..< n {
                var s = 0.0
                for j in 0 ..< k {
                    let t = points[i * k + j] - centers[labels[i] * k + j]
                    s += t * t
                }
                inertia += s
            }
            if inertia < bestInertia || best.isEmpty {
                bestInertia = inertia
                best = Array(UnsafeBufferPointer(start: labels, count: n))
            }
        }
        return best
    }
}

/// The k-means runs of `spectralClustering`.
@usableFromInline let _kMeansRuns = 10

extension Graph {
    @inlinable
    func _spectralClustering<R: RandomNumberGenerator>(clusterCount: Int, weights: [Double]?, tolerance: Double, maxIterations: Int?, using generator: inout R) throws(NoConvergence) -> Partition<DirectedView<Self>> {
        precondition(tolerance > 0, "The tolerance is not positive")
        if let maxIterations { precondition(maxIterations >= 1, "maxIterations must be at least 1") }
        precondition(clusterCount >= 1 && clusterCount <= vertexCount, "The cluster count is not in 1...vertexCount")
        let numbering = _vertexNumbering()
        let rows = try _normalizedSpectralRows(clusters: clusterCount, weights: weights, numbering: numbering, tolerance: tolerance, maxIterations: maxIterations)
        let labels = _kMeans(rows, count: vertexCount, dimensions: clusterCount, clusters: clusterCount, runs: _kMeansRuns, using: &generator)
        return Partition(directedView, numbers: numbering?.numbers, listed: numbering?.listed, labels: labels)
    }

    /// Spectral clustering into `clusterCount` communities (Ng, Jordan and Weiss 2001): the
    /// eigenvectors of the normalized Laplacian for its `clusterCount` smallest eigenvalues as
    /// columns, each row scaled to unit length (a zero row stays zero), and the rows clustered by
    /// k-means: the least-inertia run of 10, each seeded by k-means++ (Arthur and Vassilvitskii
    /// 2007) and refined by Lloyd's iteration until no assignment changes, or 300 iterations. A
    /// cluster left empty takes the row farthest from its center, so there are exactly
    /// `clusterCount` communities.
    ///
    /// The eigenvectors are `normalizedLaplacianEigenpairs(smallest: clusterCount)`'s, with its
    /// method, accuracy and limits; `generator` draws only the k-means++ seeds, so the same
    /// generator state gives the same partition.
    ///
    /// - Parameters:
    ///   - clusterCount: The number of communities, in `1...vertexCount`.
    ///   - tolerance: The residual a Ritz pair must reach, relative to its eigenvalue.
    ///   - maxIterations: The matrix–vector products each Lanczos run may spend; nil for the
    ///     defaults of `normalizedLaplacianEigenpairs(smallest:)`.
    ///   - generator: The source of the k-means++ draws.
    /// - Returns: The communities, in canonical order.
    /// - Complexity: O((n + m) · products + 3,000 n k²), k the cluster count.
    /// - Precondition: `clusterCount` is in `1...vertexCount`, `tolerance > 0`, and
    ///   `maxIterations`, when given, is at least 1.
    /// - Throws: `NoConvergence` as `normalizedLaplacianEigenpairs(smallest:)` does.
    @inlinable
    public func spectralClustering(clusterCount: Int, tolerance: Double = 1e-8, maxIterations: Int? = nil, using generator: inout some RandomNumberGenerator) throws(NoConvergence) -> Partition<DirectedView<Self>> {
        try _spectralClustering(clusterCount: clusterCount, weights: nil, tolerance: tolerance, maxIterations: maxIterations, using: &generator)
    }

    /// Spectral clustering into `clusterCount` communities (Ng, Jordan and Weiss 2001), as
    /// `spectralClustering(clusterCount:using:)`, drawing from the system's random number
    /// generator.
    ///
    /// - Precondition: `clusterCount` is in `1...vertexCount`, `tolerance > 0`, and
    ///   `maxIterations`, when given, is at least 1.
    /// - Throws: `NoConvergence` as `normalizedLaplacianEigenpairs(smallest:)` does.
    @inlinable
    public func spectralClustering(clusterCount: Int, tolerance: Double = 1e-8, maxIterations: Int? = nil) throws(NoConvergence) -> Partition<DirectedView<Self>> {
        var generator = SystemRandomNumberGenerator()
        return try _spectralClustering(clusterCount: clusterCount, weights: nil, tolerance: tolerance, maxIterations: maxIterations, using: &generator)
    }

    /// Weighted spectral clustering into `clusterCount` communities (Ng, Jordan and Weiss 2001),
    /// as `spectralClustering(clusterCount:using:)` on the weighted normalized Laplacian. `weight`
    /// is called once per edge, in position order; a weight of 0 is no edge.
    ///
    /// - Precondition: `clusterCount` is in `1...vertexCount`, `tolerance > 0`, every weight is
    ///   finite and at least zero, and `maxIterations`, when given, is at least 1.
    /// - Throws: `NoConvergence` as `normalizedLaplacianEigenpairs(smallest:weight:)` does.
    @inlinable
    public func spectralClustering<W: BinaryFloatingPoint>(clusterCount: Int, weight: (Edges.Index) -> W, tolerance: Double = 1e-8, maxIterations: Int? = nil, using generator: inout some RandomNumberGenerator) throws(NoConvergence) -> Partition<DirectedView<Self>> {
        try _spectralClustering(clusterCount: clusterCount, weights: _communityWeights(weight), tolerance: tolerance, maxIterations: maxIterations, using: &generator)
    }

    /// Weighted spectral clustering into `clusterCount` communities (Ng, Jordan and Weiss 2001),
    /// as `spectralClustering(clusterCount:weight:using:)`, drawing from the system's random
    /// number generator.
    ///
    /// - Precondition: `clusterCount` is in `1...vertexCount`, `tolerance > 0`, every weight is
    ///   finite and at least zero, and `maxIterations`, when given, is at least 1.
    /// - Throws: `NoConvergence` as `normalizedLaplacianEigenpairs(smallest:weight:)` does.
    @inlinable
    public func spectralClustering<W: BinaryFloatingPoint>(clusterCount: Int, weight: (Edges.Index) -> W, tolerance: Double = 1e-8, maxIterations: Int? = nil) throws(NoConvergence) -> Partition<DirectedView<Self>> {
        var generator = SystemRandomNumberGenerator()
        return try _spectralClustering(clusterCount: clusterCount, weights: _communityWeights(weight), tolerance: tolerance, maxIterations: maxIterations, using: &generator)
    }
}
