import GraphProtocols
import NamedGraphs

/// The stochastic block model's pairs, sorted, and its vertex count: NetworkX's
/// `stochastic_block_model` (its `sparse=True` procedure) with consecutive blocks iterated in
/// ascending order. Block pairs go undirected in `combinations_with_replacement` order, directed
/// row-major; within one, the vertex pairs are listed in ascending order (combinations within a
/// block, or permutations when directed, the product between blocks) and the skips index into that
/// list arithmetically, rather than stepping over each skipped pair as NetworkX's `islice` does.
@inlinable
func _blockModelPairs<G: RandomNumberGenerator>(
    _ sizes: [Int], _ probabilities: [[Double]], directed: Bool, _ g: inout G
) -> (vertexCount: Int, pairs: [DirectedEdge<Int>]) {
    let blocks = sizes.count
    for size in sizes { precondition(size >= 0, "block size \(size) is negative") }
    precondition(
        probabilities.count == blocks && probabilities.allSatisfy { $0.count == blocks },
        "edgeProbabilities is not blockSizes.count square"
    )
    for row in probabilities {
        for p in row { _checkProbability(p, "edge probability") }
    }
    if !directed {
        for i in 0 ..< blocks {
            for j in 0 ..< i { precondition(probabilities[i][j] == probabilities[j][i], "edgeProbabilities is not symmetric") }
        }
    }
    var starts = [0]
    for size in sizes {
        precondition(starts[starts.count - 1] <= Int.max - size, "vertex count overflows Int")
        starts.append(starts[starts.count - 1] + size)
    }
    let n = starts[blocks]
    var pairs: [DirectedEdge<Int>] = []
    for i in 0 ..< blocks {
        for j in (directed ? 0 : i) ..< blocks {
            let p = probabilities[i][j]
            guard p > 0 else { continue }
            let a = sizes[i], b = sizes[j], startI = starts[i], startJ = starts[j]
            let within = i == j
            // The number of vertex pairs in this block pair, and the length of each row of the list
            // (a row is one first vertex) when the rows are all equal.
            let total: Int
            if within {
                guard let count = directed ? _orderedPairCount(a) : _unorderedPairCount(a) else {
                    preconditionFailure("edge count overflows Int")
                }
                total = count
            } else {
                precondition(_productFits(a, b), "edge count overflows Int")
                total = a * b
            }
            if p >= 1 {
                // Every pair, no draws.
                for x in 0 ..< a {
                    for y in (within && !directed ? x + 1 : 0) ..< b where !(within && x == y) {
                        pairs.append(DirectedEdge(from: startI + x, to: startJ + y))
                    }
                }
                continue
            }
            let lp = _log(1 - p)
            guard lp != 0 else { continue }
            // Even an empty block pair makes its first draw, as NetworkX's loop does.
            // `t` is the index of the next pair in the list; for combinations, (row, column) is
            // that pair, walked forward row by row.
            var t = 0
            var row = 0
            var column = 1
            while true {
                let u = _uniform01(&g)
                // log(0): NetworkX raises; the block pair ends.
                if u == 0 { break }
                let skip = (_log(u) / lp).rounded(.down)
                guard skip < Double(total - t) else { break }
                let s = Int(skip)
                t += s
                let x: Int, y: Int
                if within && !directed {
                    // Row r holds (r, r + 1 ..< a): a − 1 − r pairs.
                    var rest = s
                    while rest >= a - column {
                        rest -= a - column
                        row += 1
                        column = row + 1
                    }
                    column += rest
                    (x, y) = (row, column)
                    column += 1
                    if column >= a {
                        row += 1
                        column = row + 1
                    }
                } else if within {
                    // Row r holds every other vertex of the block: a − 1 pairs.
                    x = t / (a - 1)
                    let r = t % (a - 1)
                    y = r < x ? r : r + 1
                } else {
                    x = t / b
                    y = t % b
                }
                pairs.append(DirectedEdge(from: startI + x, to: startJ + y))
                t += 1
            }
        }
    }
    // A vertex's pairs as the first element come block pair by block pair, each ascending, with
    // the second block increasing: one stable pass by the first element sorts them.
    return (n, _sortedBySource(n, pairs, []))
}

extension _GraphConstruction {
    /// The stochastic block model: consecutive blocks of the given sizes (block 0 is
    /// `0..<blockSizes[0]`, and so on), and each pair of vertices in blocks i and j joined
    /// independently with probability `edgeProbabilities[i][j]`.
    ///
    /// > Paul W. Holland, Kathryn Blackmond Laskey and Samuel Leinhardt. Stochastic blockmodels:
    /// > First steps. *Social Networks* 5(2), 109–137 (1983). doi:10.1016/0378-8733(83)90021-7
    ///
    /// Each block pair is sampled by geometric skipping over its pairs, indexed arithmetically, so
    /// the cost is O(n + m + B²) expected for B blocks; a probability of 0 or 1 makes no draws.
    /// The draws are NetworkX's `stochastic_block_model(sizes, p)` on the same stream (NetworkX
    /// steps over every skipped pair, O(n²)). Edges sorted.
    ///
    /// - Precondition: no negative size; `edgeProbabilities` is square of side `blockSizes.count`,
    ///   symmetric (exactly), with every entry in 0...1.
    @inlinable
    public static func stochasticBlockModel(
        blockSizes: [Int], edgeProbabilities: [[Double]], using generator: inout some RandomNumberGenerator
    ) -> Self {
        let (n, pairs) = _blockModelPairs(blockSizes, edgeProbabilities, directed: false, &generator)
        return Self(_vertexCount: n, sortedEdges: pairs.lazy.map(_undirected))
    }

    /// `stochasticBlockModel(blockSizes:edgeProbabilities:using:)` with the system's random number
    /// generator.
    @inlinable
    public static func stochasticBlockModel(blockSizes: [Int], edgeProbabilities: [[Double]]) -> Self {
        var generator = SystemRandomNumberGenerator()
        return stochasticBlockModel(blockSizes: blockSizes, edgeProbabilities: edgeProbabilities, using: &generator)
    }
}

extension _DirectedGraphConstruction {
    /// The directed stochastic block model: each ordered pair u ≠ v, u in block i and v in block j,
    /// is an arc independently with probability `edgeProbabilities[i][j]`, which need not be
    /// symmetric (NetworkX `directed=True`, igraph `SBM(directed=True)`). O(n + m + B²) expected;
    /// arcs in row-major order.
    ///
    /// - Precondition: no negative size; `edgeProbabilities` is square of side `blockSizes.count`
    ///   with every entry in 0...1.
    @inlinable
    public static func stochasticBlockModel(
        blockSizes: [Int], edgeProbabilities: [[Double]], using generator: inout some RandomNumberGenerator
    ) -> Self {
        let (n, pairs) = _blockModelPairs(blockSizes, edgeProbabilities, directed: true, &generator)
        return Self(_vertexCount: n, sortedEdges: pairs)
    }

    /// `stochasticBlockModel(blockSizes:edgeProbabilities:using:)` with the system's random number
    /// generator.
    @inlinable
    public static func stochasticBlockModel(blockSizes: [Int], edgeProbabilities: [[Double]]) -> Self {
        var generator = SystemRandomNumberGenerator()
        return stochasticBlockModel(blockSizes: blockSizes, edgeProbabilities: edgeProbabilities, using: &generator)
    }
}
