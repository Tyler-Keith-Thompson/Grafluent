import GraphProtocols
import NamedGraphs

/// The random k-out arcs, in row-major order: each vertex u in turn samples k distinct targets
/// from the other vertices, ascending (x < u is x, x ≥ u is x + 1). For a pool of N ≤ 21 + (k > 5 ? 4^⌈log₄ 3k⌉ : 0) it takes `pool[below(N − i)]` and moves
/// the pool's last element into its place; for a larger pool it redraws `below(N)` until it has
/// not been drawn. Each row is then sorted.
@inlinable
func _randomKOutArcs<G: RandomNumberGenerator>(_ n: Int, _ k: Int, _ g: inout G) -> [DirectedEdge<Int>] {
    _checkCount(n)
    precondition(k >= 0 && k <= Swift.max(n - 1, 0), "outDegree \(k) is not in 0...\(Swift.max(n - 1, 0))")
    precondition(_productFits(n, k) && n * k <= Int.max / 2, "edge count overflows Int")
    let others = n - 1
    // The pool size up to which the sample shuffles a copy of the pool: 21, plus the smallest power
    // of 4 that is at least 3k when k > 5. (3k is never a power of 4.)
    var poolLimit = 21
    if k > 5 {
        var power = 1
        while power < 3 * k { power *= 4 }
        poolLimit += power
    }
    var arcs: [DirectedEdge<Int>] = []
    arcs.reserveCapacity(n * k)
    guard k > 0 else { return arcs }
    var pool = [Int](repeating: 0, count: others)
    var drawn = [Int](repeating: -1, count: others)
    var row = [Int](repeating: 0, count: k)
    for u in 0 ..< n {
        if others <= poolLimit {
            for x in 0 ..< others { pool[x] = x < u ? x : x + 1 }
            for i in 0 ..< k {
                let j = _below(others - i, &g)
                row[i] = pool[j]
                pool[j] = pool[others - i - 1]
            }
        } else {
            for i in 0 ..< k {
                var j = _below(others, &g)
                while drawn[j] == u { j = _below(others, &g) }
                drawn[j] = u
                row[i] = j < u ? j : j + 1
            }
        }
        if k <= 16 {
            for a in 1 ..< k {
                let value = row[a]
                var b = a
                while b > 0, row[b - 1] > value {
                    row[b] = row[b - 1]
                    b -= 1
                }
                row[b] = value
            }
        } else {
            row.sort()
        }
        for t in row { arcs.append(DirectedEdge(from: u, to: t)) }
    }
    return arcs
}

/// The undirected random k-out graph's pairs: every arc u → v as u – v, sorted, each pair once.
@inlinable
func _randomKOutPairs<G: RandomNumberGenerator>(_ n: Int, _ k: Int, _ g: inout G) -> [DirectedEdge<Int>] {
    let arcs = _randomKOutArcs(n, k, &g)
    // Each arc smaller end first, sorted, then the repeats (u → v and v → u) dropped.
    var low: [DirectedEdge<Int>] = []
    var high: [DirectedEdge<Int>] = []
    low.reserveCapacity(arcs.count)
    high.reserveCapacity(arcs.count)
    for arc in arcs {
        if arc.source < arc.target { low.append(arc) } else { high.append(DirectedEdge(from: arc.target, to: arc.source)) }
    }
    let sorted = _sortedRowMajor(n, low + high)
    var pairs: [DirectedEdge<Int>] = []
    pairs.reserveCapacity(sorted.count)
    for pair in sorted where pairs.last != pair { pairs.append(pair) }
    return pairs
}

extension _DirectedGraphConstruction {
    /// The random k-out digraph: each vertex has out-degree k, its targets a uniform k-subset of
    /// the other vertices, independently for each vertex, so there is no self-loop or repeated arc.
    /// Vertex u draws its targets in turn; the sample shuffles a copy of the other vertices
    /// (taking `below(N − i)` for the i-th, then moving the last remaining into its place) when
    /// there are at most 21 of them (21 + 4^⌈log₄ 3k⌉ for k > 5), and otherwise redraws `below(N)`
    /// until it has not been drawn. k = 0 gives no arcs and no draws. Arcs in row-major order.
    ///
    /// > Trevor I. Fenner and Alan M. Frieze. On the connectivity of random m-orientable graphs and
    /// > digraphs. *Combinatorica* 2(4), 347–359 (1982). doi:10.1007/BF02579431
    ///
    /// - Complexity: O(n·(k log k + 1)) expected: the shuffled pool has at most 21 + 12k vertices.
    /// - Precondition: `vertexCount ≥ 0` and `outDegree` in `0...max(vertexCount − 1, 0)`.
    @inlinable
    public static func randomKOut(vertexCount n: Int, outDegree k: Int, using generator: inout some RandomNumberGenerator) -> Self {
        Self(_vertexCount: n, sortedEdges: _randomKOutArcs(n, k, &generator), _ConstructionToken())
    }

    /// `randomKOut(vertexCount:outDegree:using:)` with the system's random number generator.
    @inlinable
    public static func randomKOut(vertexCount n: Int, outDegree k: Int) -> Self {
        var generator = SystemRandomNumberGenerator()
        return randomKOut(vertexCount: n, outDegree: k, using: &generator)
    }
}

extension _GraphConstruction {
    /// The random k-out graph: the random k-out digraph with its directions dropped, so u – v when
    /// u chose v or v chose u. It makes the directed form's draws; every degree is at least k, and
    /// there are between nk/2 and nk edges. For k ≥ 2 it is connected with probability tending to
    /// 1 (Fenner and Frieze). Sorted.
    ///
    /// - Complexity: as for the directed form.
    /// - Precondition: `vertexCount ≥ 0` and `outDegree` in `0...max(vertexCount − 1, 0)`.
    @inlinable
    public static func randomKOut(vertexCount n: Int, outDegree k: Int, using generator: inout some RandomNumberGenerator) -> Self {
        Self(_vertexCount: n, sortedEdges: _randomKOutPairs(n, k, &generator).lazy.map(_undirected), _ConstructionToken())
    }

    /// `randomKOut(vertexCount:outDegree:using:)` with the system's random number generator.
    @inlinable
    public static func randomKOut(vertexCount n: Int, outDegree k: Int) -> Self {
        var generator = SystemRandomNumberGenerator()
        return randomKOut(vertexCount: n, outDegree: k, using: &generator)
    }
}
