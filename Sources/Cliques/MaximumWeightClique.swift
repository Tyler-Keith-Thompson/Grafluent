import GraphProtocols

/// Maximum-weight clique search on a dense graph held as bitset rows over local indices
/// `0..<count`, each with a positive weight: Tavares et al.'s branch and bound, the algorithm of
/// NetworkX's `max_weight_clique`, on bitsets. At each node the candidates are covered greedily by
/// independent sets (each built in local order), each set taking off the least weight left among
/// its members, until the weight taken exceeds what the clique needs to beat the best; only the
/// candidates still carrying weight then need branching, from the last in local order down, each
/// leaving the candidates once branched on. Only cliques heavier than a floor are looked for.
@frozen
@usableFromInline
struct _WeightedCliqueSearch<W: Comparable & AdditiveArithmetic> {
    @usableFromInline var count = 0
    @usableFromInline var words = 0
    @usableFromInline var rows: [UInt64] = []
    @usableFromInline var weights: [W] = []
    /// The candidates per depth, then the branching set per depth, flat, `words` each.
    @usableFromInline var sets: [UInt64] = []
    @usableFromInline var branches: [UInt64] = []
    /// Scratch for the cover: the weight left on each candidate, the candidates still carrying
    /// weight, the vertices an independent set may still take, and the set's members.
    @usableFromInline var residual: [W] = []
    @usableFromInline var work: [UInt64] = []
    @usableFromInline var open: [UInt64] = []
    @usableFromInline var members: [Int] = []
    @usableFromInline var current: [Int] = []
    @usableFromInline var best: W = .zero
    /// The clique of weight `best`, by local index, when `improved`.
    @usableFromInline var bestSet: [Int] = []
    @usableFromInline var improved = false

    @inlinable
    init() {}

    /// Makes room for `p` vertices: `rows` becomes p × `words` zero words, `weights` empty.
    @inlinable
    mutating func reset(count p: Int) {
        count = p
        words = (p + 63) >> 6
        rows.removeAll(keepingCapacity: true)
        rows.append(contentsOf: repeatElement(0, count: p * words))
        weights.removeAll(keepingCapacity: true)
        work.removeAll(keepingCapacity: true)
        work.append(contentsOf: repeatElement(0, count: words))
        open.removeAll(keepingCapacity: true)
        open.append(contentsOf: repeatElement(0, count: words))
    }

    /// Fills the branching set at `depth` from the candidates there: what is left of them once
    /// greedy independent sets have taken off more weight than `target`.
    @inlinable
    mutating func branching(depth: Int, target: W) {
        let base = depth * words
        for k in 0 ..< words {
            let word = sets[base + k]
            work[k] = word
            var bits = word
            while bits != 0 {
                let i = k << 6 | bits.trailingZeroBitCount
                bits &= bits - 1
                residual[i] = weights[i]
            }
        }
        var total = W.zero
        var first = 0
        while true {
            while first < words, work[first] == 0 { first += 1 }
            guard first < words else { break }
            members.removeAll(keepingCapacity: true)
            for k in first ..< words { open[k] = work[k] }
            for k in first ..< words {
                while open[k] != 0 {
                    let i = k << 6 | open[k].trailingZeroBitCount
                    members.append(i)
                    for j in k ..< words { open[j] &= ~rows[i * words + j] }
                    open[k] &= ~(1 << UInt64(i & 63))
                }
            }
            var least = residual[members[0]]
            for i in members where residual[i] < least { least = residual[i] }
            total += least
            if total > target { break }
            for i in members {
                residual[i] -= least
                if residual[i] == .zero { work[i >> 6] &= ~(1 << UInt64(i & 63)) }
            }
        }
        for k in 0 ..< words { branches[base + k] = work[k] }
    }

    /// Extends `current` (of weight `size`) by the candidates at `depth`, raising `best`.
    @inlinable
    mutating func expand(depth: Int, size: W) {
        if size > best {
            best = size
            bestSet = current
            improved = true
        }
        let base = depth * words
        if sets.count < base + 2 * words {
            sets.append(contentsOf: repeatElement(0, count: words))
            branches.append(contentsOf: repeatElement(0, count: words))
        }
        branching(depth: depth, target: best - size)
        var k = words - 1
        while k >= 0 {
            while branches[base + k] != 0 {
                let i = k << 6 | (63 - branches[base + k].leadingZeroBitCount)
                let bit: UInt64 = 1 << UInt64(i & 63)
                branches[base + k] &= ~bit
                sets[base + k] &= ~bit
                for j in 0 ..< words { sets[base + words + j] = sets[base + j] & rows[i * words + j] }
                current.append(i)
                expand(depth: depth + 1, size: size + weights[i])
                current.removeLast()
            }
            k -= 1
        }
    }

    /// The heaviest clique of the loaded graph heavier than `floor`, as `bestSet` with weight
    /// `best` when `improved` (the empty clique, of weight zero, counts).
    @inlinable
    mutating func maximum(floor: W) {
        best = floor
        improved = false
        bestSet.removeAll(keepingCapacity: true)
        current.removeAll(keepingCapacity: true)
        residual.removeAll(keepingCapacity: true)
        residual.append(contentsOf: repeatElement(.zero, count: count))
        sets.removeAll(keepingCapacity: true)
        branches.removeAll(keepingCapacity: true)
        sets.append(contentsOf: repeatElement(0, count: words))
        branches.append(contentsOf: repeatElement(0, count: words))
        for i in 0 ..< count { sets[i >> 6] |= 1 << UInt64(i & 63) }
        expand(depth: 0, size: .zero)
    }
}

extension Graph {
    /// A clique of greatest total weight in the simple graph, in `vertices` order, with weights
    /// read once per vertex. Vertices of weight zero or less are never taken, so the result is []
    /// when no weight is positive (and for the empty graph). Each vertex v in degeneracy order with
    /// a positive weight is searched with its later positive neighbors (at most `degeneracy`),
    /// ordered by descending degree among them, by Tavares et al.'s branch and bound (NetworkX's
    /// `max_weight_clique`) for a clique beating the best so far. Exponential in the worst case;
    /// memory O(n + m + degeneracy²).
    ///
    /// - Precondition: every sum of weights fits in `W`, and no weight is NaN.
    @inlinable
    public func maximumWeightClique<W: Comparable & AdditiveArithmetic>(weight: (Vertex) -> W) -> [Vertex] {
        let rows = _simpleRows()
        let n = rows.count
        guard n > 0 else { return [] }
        let listed = _listedVertices()
        let weights = (0 ..< n).map { weight(_vertex(number: $0, listed)) }
        let order = _cores(rows).order
        var rank = [Int](repeating: 0, count: n)
        for (i, v) in order.enumerated() { rank[v] = i }
        var laterOffsets = [Int](repeating: 0, count: n + 1)
        var later: [Int] = []
        later.reserveCapacity(rows.targets.count / 2)
        for v in 0 ..< n {
            for k in rows.offsets[v] ..< rows.offsets[v + 1] where rank[rows.targets[k]] > rank[v] && weights[rows.targets[k]] > .zero { later.append(rows.targets[k]) }
            laterOffsets[v + 1] = later.count
        }
        var local = [Int](repeating: -1, count: n)
        var members: [Int] = [], degree: [Int] = []
        var search = _WeightedCliqueSearch<W>()
        var best = W.zero
        var clique: [Int] = []
        for v in order where weights[v] > .zero {
            for u in members { local[u] = -1 }
            members.removeAll(keepingCapacity: true)
            var total = weights[v]
            for k in laterOffsets[v] ..< laterOffsets[v + 1] {
                members.append(later[k])
                total += weights[later[k]]
            }
            guard total > best else { continue }
            let p = members.count
            for (i, u) in members.enumerated() { local[u] = i }
            // Degrees among the members, from later rows: each edge among them has an earlier end.
            degree.removeAll(keepingCapacity: true)
            degree.append(contentsOf: repeatElement(0, count: p))
            for i in 0 ..< p {
                for k in laterOffsets[members[i]] ..< laterOffsets[members[i] + 1] where local[later[k]] >= 0 {
                    degree[i] += 1
                    degree[local[later[k]]] += 1
                }
            }
            let ranked = (0 ..< p).sorted { degree[$0] != degree[$1] ? degree[$0] > degree[$1] : members[$0] < members[$1] }
            members = ranked.map { members[$0] }
            for (i, u) in members.enumerated() { local[u] = i }
            search.reset(count: p)
            let words = search.words
            for i in 0 ..< p {
                let u = members[i]
                search.weights.append(weights[u])
                for k in laterOffsets[u] ..< laterOffsets[u + 1] {
                    let j = local[later[k]]
                    guard j >= 0 else { continue }
                    search.rows[i * words + j >> 6] |= 1 << UInt64(j & 63)
                    search.rows[j * words + i >> 6] |= 1 << UInt64(i & 63)
                }
            }
            search.maximum(floor: best - weights[v])
            if search.improved {
                best = weights[v] + search.best
                clique = [v] + search.bestSet.map { members[$0] }
            }
        }
        return clique.sorted().map { _vertex(number: $0, listed) }
    }
}

extension Graph {
    /// The size of a largest clique containing `vertex` (its node clique number): 1 for a vertex
    /// with no neighbor. One more than the clique number of the subgraph its neighbors induce,
    /// found as `cliqueNumber()` finds it; exponential in the worst case, memory O(n + m +
    /// degeneracy²). Self-loops and parallel edges are ignored.
    ///
    /// - Precondition: `vertex` is a vertex of the graph.
    @inlinable
    public func cliqueNumber(of vertex: Vertex) -> Int {
        let numbers = _listedVertices().map { _vertexNumbers($0) }
        let v = _vertexNumber(of: vertex, numbers, "The vertex is not in the graph")
        let neighborhood = _neighborhood(of: v, _simpleRows())
        return _cliqueNumber(neighborhood.rows).clique.count + 1
    }

    /// The size of a largest clique containing `vertex`, throwing instead of trapping when it is
    /// not a vertex of the graph.
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not a vertex of the graph.
    @inlinable
    public func cliqueNumber(checked vertex: Vertex) throws(VertexNotFound) -> Int {
        guard contains(vertex) else { throw VertexNotFound() }
        return cliqueNumber(of: vertex)
    }
}
