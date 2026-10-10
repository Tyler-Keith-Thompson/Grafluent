import GraphProtocols

/// One Louvain level: k vertices and each pair's weight once (undirected pairs as (min, max);
/// loops as (v, v)), grouped by the pair's first vertex and in order of first appearance within a
/// group, each summed in arc order. Built by a counting sort and a stamp per row, with no hashing.
@frozen
@usableFromInline
struct _LouvainLevel {
    @usableFromInline let count: Int
    @usableFromInline let directed: Bool
    @usableFromInline var pairFrom: [Int] = []
    @usableFromInline var pairTo: [Int] = []
    @usableFromInline var pairWeight: [Double] = []

    @inlinable
    init(count k: Int, directed: Bool, from: [Int], to: [Int], weight: (Int) -> Double) {
        self.count = k
        self.directed = directed
        let arcs = from.count
        var start = [Int](repeating: 0, count: k + 1)
        for i in 0 ..< arcs { start[(directed ? from[i] : min(from[i], to[i])) + 1] += 1 }
        for v in 0 ..< k { start[v + 1] += start[v] }
        var fill = start
        var order = [Int](repeating: 0, count: arcs)
        for i in 0 ..< arcs {
            let x = directed ? from[i] : min(from[i], to[i])
            order[fill[x]] = i
            fill[x] += 1
        }
        var seen = [Int](repeating: -1, count: k)
        var slot = [Int](repeating: 0, count: k)
        pairFrom.reserveCapacity(arcs)
        pairTo.reserveCapacity(arcs)
        pairWeight.reserveCapacity(arcs)
        for x in 0 ..< k {
            for position in start[x] ..< start[x + 1] {
                let i = order[position]
                let y = directed ? to[i] : max(from[i], to[i])
                if seen[y] == x {
                    pairWeight[slot[y]] += weight(i)
                } else {
                    seen[y] = x
                    slot[y] = pairWeight.count
                    pairFrom.append(x)
                    pairTo.append(y)
                    pairWeight.append(weight(i))
                }
            }
        }
    }
}

/// The level's degrees and merged neighbor rows.
@frozen
@usableFromInline
struct _LouvainRows {
    @usableFromInline var out: [Double]
    @usableFromInline var into: [Double]
    @usableFromInline var offsets: [Int]
    @usableFromInline var neighbors: [Int]
    @usableFromInline var weights: [Double]

    @inlinable
    init(_ level: _LouvainLevel) {
        let k = level.count
        out = [Double](repeating: 0, count: k)
        into = [Double](repeating: 0, count: k)
        var counts = [Int](repeating: 0, count: k + 1)
        for p in 0 ..< level.pairWeight.count {
            let a = level.pairFrom[p], b = level.pairTo[p], x = level.pairWeight[p]
            out[a] += x
            into[b] += x
            if !level.directed {
                out[b] += x
                into[a] += x
            }
            if a != b {
                counts[a + 1] += 1
                counts[b + 1] += 1
            }
        }
        for v in 0 ..< k { counts[v + 1] += counts[v] }
        var fill = counts
        var rawNeighbors = [Int](repeating: 0, count: counts[k])
        var rawWeights = [Double](repeating: 0, count: counts[k])
        for p in 0 ..< level.pairWeight.count {
            let a = level.pairFrom[p], b = level.pairTo[p], x = level.pairWeight[p]
            guard a != b else { continue }
            rawNeighbors[fill[a]] = b
            rawWeights[fill[a]] = x
            fill[a] += 1
            rawNeighbors[fill[b]] = a
            rawWeights[fill[b]] = x
            fill[b] += 1
        }
        // Merge repeats (a directed pair both ways) into the first appearance.
        offsets = [Int](repeating: 0, count: k + 1)
        neighbors = []
        weights = []
        neighbors.reserveCapacity(rawNeighbors.count)
        weights.reserveCapacity(rawNeighbors.count)
        var where_ = [Int](repeating: -1, count: k)
        for v in 0 ..< k {
            let start = neighbors.count
            for slot in counts[v] ..< counts[v + 1] {
                let w = rawNeighbors[slot]
                let at = where_[w]
                if at >= start, at < neighbors.count, neighbors[at] == w {
                    weights[at] += rawWeights[slot]
                } else {
                    where_[w] = neighbors.count
                    neighbors.append(w)
                    weights.append(rawWeights[slot])
                }
            }
            offsets[v + 1] = neighbors.count
        }
    }
}

/// Local moving on one level (NetworkX's `_one_level` arithmetic): sweeps in `order` until one
/// moves nothing. A vertex stays when its own community's gain ties the best; among others a tie
/// goes to the greatest label. Returns each level vertex's community label (a level vertex number)
/// and whether any vertex moved.
///
/// Two departures from NetworkX's code, neither changing a result it reaches:
/// * **Gains within rounding are ties.** Two gains closer than 4 ulps of their largest term are
///   equal: with weights that are not dyadic, sums equal in exact arithmetic can round apart, and a
///   vertex could move A → B → A forever, each move winning by an ulp (NetworkX hangs on such
///   graphs). Integer weights keep every difference far above the bound while 4m² < 2⁵³. A stay
///   writes no total, so totals change only when a vertex moves.
/// * **Only vertices whose inputs changed are evaluated.** A vertex's decision reads the labels of
///   its neighbors and the totals of its own and its neighbors' communities; when u moves from A
///   to B, only the members of A and B and their neighbors can decide differently. Every other
///   vertex would stay, so skipping it leaves the sweeps' moves unchanged. Marking costs the
///   volume of A and B; past n + m in one sweep, every vertex is marked instead, and again when
///   the sweep ends.
@inlinable
func _louvainLevel(_ rows: _LouvainRows, directed: Bool, m: Double, resolution: Double, order: [Int]) -> (community: [Int], moved: Bool) {
    let k = rows.out.count
    let gamma = directed ? resolution : resolution / 2
    let slots = rows.neighbors.count
    // Scratch buffers, allocated once: a level can take many sweeps, and debug builds must not pay
    // a uniqueness check per write. `totalOut` is the undirected total degree.
    let community = UnsafeMutableBufferPointer<Int>.allocate(capacity: k)
    let totalIn = UnsafeMutableBufferPointer<Double>.allocate(capacity: k)
    let totalOut = UnsafeMutableBufferPointer<Double>.allocate(capacity: k)
    let weightTo = UnsafeMutableBufferPointer<Double>.allocate(capacity: k)
    let stamp = UnsafeMutableBufferPointer<Int>.allocate(capacity: k)
    let touched = UnsafeMutableBufferPointer<Int>.allocate(capacity: k)
    let dirty = UnsafeMutableBufferPointer<Bool>.allocate(capacity: k)
    // Members of each community as a doubly linked list.
    let head = UnsafeMutableBufferPointer<Int>.allocate(capacity: k)
    let next = UnsafeMutableBufferPointer<Int>.allocate(capacity: k)
    let previous = UnsafeMutableBufferPointer<Int>.allocate(capacity: k)
    defer {
        for buffer in [community, stamp, touched, head, next, previous] { buffer.deallocate() }
        for buffer in [totalIn, totalOut, weightTo] { buffer.deallocate() }
        dirty.deallocate()
    }
    for v in 0 ..< k {
        community[v] = v
        totalIn[v] = rows.into[v]
        totalOut[v] = rows.out[v]
        weightTo[v] = 0
        stamp[v] = -1
        dirty[v] = true
        head[v] = v
        next[v] = -1
        previous[v] = -1
    }
    var moved = false
    rows.offsets.withUnsafeBufferPointer { offsets in
        rows.neighbors.withUnsafeBufferPointer { neighbors in
            rows.weights.withUnsafeBufferPointer { weights in
                rows.out.withUnsafeBufferPointer { out in
                    rows.into.withUnsafeBufferPointer { into in
                        var step = 0
                        var moves = 1
                        while moves > 0 {
                            moves = 0
                            var marked = 0
                            var markedAll = false
                            for u in order where dirty[u] {
                                dirty[u] = false
                                step += 1
                                let current = community[u]
                                var touchedCount = 0
                                for slot in offsets[u] ..< offsets[u + 1] {
                                    let c = community[neighbors[slot]]
                                    if stamp[c] != step {
                                        stamp[c] = step
                                        weightTo[c] = 0
                                        touched[touchedCount] = c
                                        touchedCount += 1
                                    }
                                    weightTo[c] += weights[slot]
                                }
                                let inDegree = into[u], outDegree = out[u]
                                // The own community's totals without u, kept local unless u moves.
                                let ownIn = directed ? totalIn[current] - inDegree : 0
                                let ownOut = totalOut[current] - outDegree
                                let ownT = directed ? outDegree * ownIn + inDegree * ownOut : ownOut * outDegree
                                var bestLink = (stamp[current] == step ? weightTo[current] : 0) * m
                                var bestPenalty = gamma * ownT
                                var best = bestLink - bestPenalty
                                var chosen = current
                                for i in 0 ..< touchedCount {
                                    let c = touched[i]
                                    if c == current { continue }
                                    let t = directed ? outDegree * totalIn[c] + inDegree * totalOut[c] : totalOut[c] * outDegree
                                    let link = weightTo[c] * m, penalty = gamma * t
                                    let gain = link - penalty
                                    let scale = max(abs(link), abs(penalty), abs(bestLink), abs(bestPenalty))
                                    let tolerance = 4 * scale.ulp
                                    if gain - best > tolerance || (abs(gain - best) <= tolerance && chosen != current && c > chosen) {
                                        best = gain
                                        bestLink = link
                                        bestPenalty = penalty
                                        chosen = c
                                    }
                                }
                                guard chosen != current else { continue }
                                if directed {
                                    totalIn[current] = ownIn
                                    totalIn[chosen] += inDegree
                                }
                                totalOut[current] = ownOut
                                totalOut[chosen] += outDegree
                                // Unlink u from its community, link it at the front of the chosen one.
                                if previous[u] >= 0 { next[previous[u]] = next[u] } else { head[current] = next[u] }
                                if next[u] >= 0 { previous[next[u]] = previous[u] }
                                previous[u] = -1
                                next[u] = head[chosen]
                                if head[chosen] >= 0 { previous[head[chosen]] = u }
                                head[chosen] = u
                                community[u] = chosen
                                moves += 1
                                moved = true
                                guard !markedAll else { continue }
                                for side in 0 ..< 2 {
                                    var w = head[side == 0 ? current : chosen]
                                    while w >= 0, !markedAll {
                                        dirty[w] = true
                                        marked += 1 + offsets[w + 1] - offsets[w]
                                        for slot in offsets[w] ..< offsets[w + 1] { dirty[neighbors[slot]] = true }
                                        w = next[w]
                                        if marked > k + slots {
                                            for v in 0 ..< k { dirty[v] = true }
                                            markedAll = true
                                        }
                                    }
                                }
                                // u's old neighbors are its new community's members' neighbors.
                                for slot in offsets[u] ..< offsets[u + 1] { dirty[neighbors[slot]] = true }
                            }
                            // Moves after the budget ran out marked nothing: evaluate everything again.
                            if markedAll { for v in 0 ..< k { dirty[v] = true } }
                        }
                    }
                }
            }
        }
    }
    return (Array(community), moved)
}

/// Louvain (Blondel et al.) with NetworkX's stop rule: levels while the modularity of the original
/// graph rises by more than `threshold`; each level's order from `order(k)`. The modularity is
/// computed on the original graph (NetworkX: on the level graph), equal in exact arithmetic and
/// possibly rounding apart within an ulp of `threshold`.
@inlinable
func _louvain(_ graph: _CommunityGraph, _ weights: [Double]?, resolution: Double, threshold: Double, order: (Int) -> [Int]) -> [Int] {
    let n = graph.count
    guard graph.edgeCount > 0 else { return Array(0 ..< n) }
    var m = 0.0
    if let weights { for w in weights { m += w } } else { m = Double(graph.edgeCount) }
    var level = _LouvainLevel(count: n, directed: graph.directed, from: graph.from, to: graph.to) { weights?[$0] ?? 1 }
    var node = Array(0 ..< n)
    var modularity = _modularity(graph, weights, labels: Array(0 ..< n), count: n, resolution: resolution)
    var (community, moved) = _louvainLevel(_LouvainRows(level), directed: graph.directed, m: m, resolution: resolution, order: order(level.count))
    var final: [Int] = []
    var first = true
    while first || moved {
        first = false
        // Nonempty communities in label order.
        var rank = [Int](repeating: -1, count: level.count)
        for c in community { rank[c] = 0 }
        var count = 0
        for c in 0 ..< level.count where rank[c] == 0 {
            rank[c] = count
            count += 1
        }
        let labels = (0 ..< n).map { rank[community[node[$0]]] }
        final = labels
        let next = _modularity(graph, weights, labels: labels, count: count, resolution: resolution)
        if next - modularity <= threshold { break }
        modularity = next
        let pairs = level
        let aggregate = _LouvainLevel(count: count, directed: graph.directed,
                                      from: pairs.pairFrom.map { rank[community[$0]] }, to: pairs.pairTo.map { rank[community[$0]] }) { pairs.pairWeight[$0] }
        node = labels
        level = aggregate
        (community, moved) = _louvainLevel(_LouvainRows(level), directed: graph.directed, m: m, resolution: resolution, order: order(level.count))
    }
    return final
}

/// 0 ..< k, shuffled by Fisher–Yates from the last position down, each swap drawn with
/// `next(upperBound:)`.
@inlinable
func _shuffledOrder<R: RandomNumberGenerator>(_ k: Int, _ generator: inout R) -> [Int] {
    var order = Array(0 ..< k)
    var i = k - 1
    while i > 0 {
        let j = Int(generator.next(upperBound: UInt(i + 1)))
        order.swapAt(i, j)
        i -= 1
    }
    return order
}

@inlinable
func _checkLouvain(resolution: Double, threshold: Double) {
    _checkResolution(resolution)
    precondition(threshold.isFinite && threshold >= 0, "The threshold must be finite and at least zero")
}

extension Graph {
    @inlinable
    func _louvainCommunities(_ weights: [Double]?, resolution: Double, threshold: Double, order: (Int) -> [Int]) -> Partition<DirectedView<Self>> {
        _checkLouvain(resolution: resolution, threshold: threshold)
        let listed = _listedVertices()
        let numbers = listed.map(CommunityDetection._communityNumbers)
        let labels = _louvain(_communityGraph(), weights, resolution: resolution, threshold: threshold, order: order)
        return Partition(directed, numbers: numbers, listed: listed, labels: labels)
    }

    /// Louvain communities (Blondel et al.; NetworkX `louvain_communities`): each level moves
    /// vertices, in index order, to the neighboring community of greatest modularity gain (staying
    /// on a tie, otherwise the greatest community label), then merges each community into a vertex,
    /// while the modularity rises by more than `threshold`. Deterministic: a function of the graph's
    /// vertex numbering and weights. Parallel edges add; a self-loop counts in degrees and never
    /// moves a vertex. O(m) per sweep.
    ///
    /// - Precondition: `resolution` and `threshold` are finite and at least zero.
    @inlinable
    public func louvainCommunities(resolution: Double = 1, threshold: Double = 1e-7) -> Partition<DirectedView<Self>> {
        _louvainCommunities(nil, resolution: resolution, threshold: threshold) { Array(0 ..< $0) }
    }

    /// Weighted Louvain communities; `weight` is called once per edge, in position order. With
    /// integer-valued weights every gain is exact; with others, near-ties depend on summation order.
    ///
    /// - Precondition: every weight is finite and at least zero; `resolution` and `threshold` are
    ///   finite and at least zero.
    @inlinable
    public func louvainCommunities<W: BinaryFloatingPoint>(weight: (Edges.Index) -> W, resolution: Double = 1, threshold: Double = 1e-7) -> Partition<DirectedView<Self>> {
        _louvainCommunities(_communityWeights(weight), resolution: resolution, threshold: threshold) { Array(0 ..< $0) }
    }

    /// Louvain communities with each level's visit order shuffled by `generator` (NetworkX's
    /// `seed`): one Fisher–Yates shuffle per level, position i (from the last down to 1) swapped
    /// with `generator.next(upperBound: i + 1)`.
    ///
    /// - Precondition: `resolution` and `threshold` are finite and at least zero.
    @inlinable
    public func louvainCommunities(resolution: Double = 1, threshold: Double = 1e-7, using generator: inout some RandomNumberGenerator) -> Partition<DirectedView<Self>> {
        _louvainCommunities(nil, resolution: resolution, threshold: threshold) { _shuffledOrder($0, &generator) }
    }

    /// Weighted Louvain communities with shuffled visit orders.
    ///
    /// - Precondition: every weight is finite and at least zero; `resolution` and `threshold` are
    ///   finite and at least zero.
    @inlinable
    public func louvainCommunities<W: BinaryFloatingPoint>(weight: (Edges.Index) -> W, resolution: Double = 1, threshold: Double = 1e-7, using generator: inout some RandomNumberGenerator) -> Partition<DirectedView<Self>> {
        _louvainCommunities(_communityWeights(weight), resolution: resolution, threshold: threshold) { _shuffledOrder($0, &generator) }
    }
}

extension DirectedGraph {
    @inlinable
    func _louvainCommunities(_ weights: [Double]?, resolution: Double, threshold: Double, order: (Int) -> [Int]) -> Partition<Self> {
        _checkLouvain(resolution: resolution, threshold: threshold)
        let listed = _listedVertices()
        let numbers = listed.map(CommunityDetection._communityNumbers)
        let labels = _louvain(_communityGraph(numbers), weights, resolution: resolution, threshold: threshold, order: order)
        return Partition(self, numbers: numbers, listed: listed, labels: labels)
    }

    /// Louvain communities with the directed gain (Dugué and Perez; NetworkX
    /// `louvain_communities`): as on `Graph`, maximizing directed modularity.
    ///
    /// - Precondition: `resolution` and `threshold` are finite and at least zero.
    @inlinable
    public func louvainCommunities(resolution: Double = 1, threshold: Double = 1e-7) -> Partition<Self> {
        _louvainCommunities(nil, resolution: resolution, threshold: threshold) { Array(0 ..< $0) }
    }

    /// Weighted directed Louvain communities; `weight` is called once per edge, in position order.
    ///
    /// - Precondition: every weight is finite and at least zero; `resolution` and `threshold` are
    ///   finite and at least zero.
    @inlinable
    public func louvainCommunities<W: BinaryFloatingPoint>(weight: (Edges.Index) -> W, resolution: Double = 1, threshold: Double = 1e-7) -> Partition<Self> {
        _louvainCommunities(_communityWeights(weight), resolution: resolution, threshold: threshold) { Array(0 ..< $0) }
    }

    /// Directed Louvain communities with each level's visit order shuffled by `generator`.
    ///
    /// - Precondition: `resolution` and `threshold` are finite and at least zero.
    @inlinable
    public func louvainCommunities(resolution: Double = 1, threshold: Double = 1e-7, using generator: inout some RandomNumberGenerator) -> Partition<Self> {
        _louvainCommunities(nil, resolution: resolution, threshold: threshold) { _shuffledOrder($0, &generator) }
    }

    /// Weighted directed Louvain communities with shuffled visit orders.
    ///
    /// - Precondition: every weight is finite and at least zero; `resolution` and `threshold` are
    ///   finite and at least zero.
    @inlinable
    public func louvainCommunities<W: BinaryFloatingPoint>(weight: (Edges.Index) -> W, resolution: Double = 1, threshold: Double = 1e-7, using generator: inout some RandomNumberGenerator) -> Partition<Self> {
        _louvainCommunities(_communityWeights(weight), resolution: resolution, threshold: threshold) { _shuffledOrder($0, &generator) }
    }
}
