#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#elseif canImport(Musl)
import Musl
#endif
// A swift.org toolchain reading a newer macOS SDK (the fuzz build) gets a Darwin without libm's
// functions; the SDK's math module has them.
#if canImport(math_h)
import math_h
#endif
import GraphProtocols

/// A quality function that Leiden maximizes.
@frozen
public enum QualityFunction: Hashable, Sendable {
    /// Modularity with resolution γ, as `modularity(of:resolution:)` computes it (Leicht–Newman on
    /// a `DirectedGraph`).
    case modularity
    /// The constant Potts model with resolution γ (Traag, Van Dooren and Nesterov 2011), as
    /// `constantPottsModel(of:resolution:)` computes it: a community is worth keeping together
    /// when its edge density is above γ.
    case constantPottsModel
}

/// Leiden's move phase on one level (`MoveNodesFast`): a queue of every level vertex in shuffled
/// order; each vertex popped moves to the community of greatest gain (a neighbor's, or an empty
/// one), staying unless another gains more by more than rounding, and a move queues the vertex's
/// neighbors outside its new community that are not queued already. `community` holds a label in
/// `0 ..< k` per level vertex and is updated in place. Returns whether any vertex moved.
///
/// The gain of moving v into C is E(v, C) − γ′ (a_v B_C + b_v A_C), E(v, C) the weight between v
/// and C (arcs both ways), a and b each vertex's two weights (out- and in-degree for modularity,
/// sizes for the constant Potts model) and A, B their sums over C. Two gains closer than 4 ulps of
/// their largest term are a tie, for the reason `_louvainLevel` gives.
@inlinable
func _leidenMove<R: RandomNumberGenerator>(_ rows: _LouvainRows, _ community: inout [Int], a: [Double], b: [Double], scale gamma: Double, using generator: inout R) -> Bool {
    let k = community.count
    guard k > 1 else { return false }
    var moved = false
    let order = _shuffledOrder(k, &generator)
    let totalA = UnsafeMutableBufferPointer<Double>.allocate(capacity: k)
    let totalB = UnsafeMutableBufferPointer<Double>.allocate(capacity: k)
    let weightTo = UnsafeMutableBufferPointer<Double>.allocate(capacity: k)
    let size = UnsafeMutableBufferPointer<Int>.allocate(capacity: k)
    let stamp = UnsafeMutableBufferPointer<Int>.allocate(capacity: k)
    let touched = UnsafeMutableBufferPointer<Int>.allocate(capacity: k)
    let queue = UnsafeMutableBufferPointer<Int>.allocate(capacity: k)
    let queued = UnsafeMutableBufferPointer<Bool>.allocate(capacity: k)
    let empty = UnsafeMutableBufferPointer<Int>.allocate(capacity: k)
    defer {
        for buffer in [totalA, totalB, weightTo] { buffer.deallocate() }
        for buffer in [size, stamp, touched, queue, empty] { buffer.deallocate() }
        queued.deallocate()
    }
    for c in 0 ..< k {
        totalA[c] = 0
        totalB[c] = 0
        size[c] = 0
        stamp[c] = -1
        queue[c] = order[c]
        queued[c] = true
    }
    for v in 0 ..< k {
        let c = community[v]
        totalA[c] += a[v]
        totalB[c] += b[v]
        size[c] += 1
    }
    var emptyCount = 0
    for c in stride(from: k - 1, through: 0, by: -1) where size[c] == 0 {
        empty[emptyCount] = c
        emptyCount += 1
    }
    community.withUnsafeMutableBufferPointer { community in
        rows.offsets.withUnsafeBufferPointer { offsets in
            rows.neighbors.withUnsafeBufferPointer { neighbors in
                rows.weights.withUnsafeBufferPointer { weights in
                    a.withUnsafeBufferPointer { a in
                        b.withUnsafeBufferPointer { b in
                            var head = 0, pending = k, step = 0
                            while pending > 0 {
                                let v = queue[head]
                                head = head + 1 == k ? 0 : head + 1
                                pending -= 1
                                queued[v] = false
                                step += 1
                                let current = community[v]
                                var touchedCount = 0
                                for slot in offsets[v] ..< offsets[v + 1] {
                                    let c = community[neighbors[slot]]
                                    if stamp[c] != step {
                                        stamp[c] = step
                                        weightTo[c] = 0
                                        touched[touchedCount] = c
                                        touchedCount += 1
                                    }
                                    weightTo[c] += weights[slot]
                                }
                                let av = a[v], bv = b[v]
                                let ownA = totalA[current] - av, ownB = totalB[current] - bv
                                var bestLink = stamp[current] == step ? weightTo[current] : 0
                                var bestPenalty = gamma * (av * ownB + bv * ownA)
                                var best = bestLink - bestPenalty
                                var chosen = current
                                // An empty community gains 0; it is a choice only when v is not alone.
                                if size[current] > 1 {
                                    let tolerance = 4 * max(abs(bestLink), abs(bestPenalty)).ulp
                                    if -best > tolerance {
                                        best = 0
                                        bestLink = 0
                                        bestPenalty = 0
                                        chosen = -1
                                    }
                                }
                                for i in 0 ..< touchedCount {
                                    let c = touched[i]
                                    if c == current { continue }
                                    let link = weightTo[c], penalty = gamma * (av * totalB[c] + bv * totalA[c])
                                    let gain = link - penalty
                                    let tolerance = 4 * max(abs(link), abs(penalty), abs(bestLink), abs(bestPenalty)).ulp
                                    if gain - best > tolerance {
                                        best = gain
                                        bestLink = link
                                        bestPenalty = penalty
                                        chosen = c
                                    }
                                }
                                guard chosen != current else { continue }
                                if chosen < 0 {
                                    emptyCount -= 1
                                    chosen = empty[emptyCount]
                                }
                                totalA[current] = ownA
                                totalB[current] = ownB
                                size[current] -= 1
                                if size[current] == 0 {
                                    empty[emptyCount] = current
                                    emptyCount += 1
                                }
                                totalA[chosen] += av
                                totalB[chosen] += bv
                                size[chosen] += 1
                                community[v] = chosen
                                moved = true
                                for slot in offsets[v] ..< offsets[v + 1] {
                                    let w = neighbors[slot]
                                    if !queued[w], community[w] != chosen {
                                        queued[w] = true
                                        var tail = head + pending
                                        if tail >= k { tail -= k }
                                        queue[tail] = w
                                        pending += 1
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    return moved
}

/// Leiden's refinement phase (`RefinePartition` and `MergeNodesSubset`): within each community S
/// of `community`, from singletons, each level vertex v (in shuffled order) that is still alone
/// and well connected to S (E(v, S − v) ≥ γ′ (a_v (B_S − b_v) + b_v (A_S − a_v))) joins a
/// neighboring refined community R ⊆ S that is well connected to S in the same sense and whose
/// gain is at least zero, or stays alone (gain 0), drawn with probability proportional to
/// exp(gain / θ). Returns each level vertex's refined community, labeled by a level vertex in it.
/// Every refined community induces a connected subgraph: a vertex joins only a neighbor's.
@inlinable
func _leidenRefine<R: RandomNumberGenerator>(_ rows: _LouvainRows, _ community: [Int], a: [Double], b: [Double], scale gamma: Double, randomness theta: Double, using generator: inout R) -> [Int] {
    let k = community.count
    var refined = Array(0 ..< k)
    guard k > 1 else { return refined }
    let order = _shuffledOrder(k, &generator)
    let sumA = UnsafeMutableBufferPointer<Double>.allocate(capacity: k)
    let sumB = UnsafeMutableBufferPointer<Double>.allocate(capacity: k)
    let external = UnsafeMutableBufferPointer<Double>.allocate(capacity: k)
    let refinedA = UnsafeMutableBufferPointer<Double>.allocate(capacity: k)
    let refinedB = UnsafeMutableBufferPointer<Double>.allocate(capacity: k)
    let refinedExternal = UnsafeMutableBufferPointer<Double>.allocate(capacity: k)
    let refinedSize = UnsafeMutableBufferPointer<Int>.allocate(capacity: k)
    let weightTo = UnsafeMutableBufferPointer<Double>.allocate(capacity: k)
    let stamp = UnsafeMutableBufferPointer<Int>.allocate(capacity: k)
    let touched = UnsafeMutableBufferPointer<Int>.allocate(capacity: k)
    let candidates = UnsafeMutableBufferPointer<Int>.allocate(capacity: k)
    let chances = UnsafeMutableBufferPointer<Double>.allocate(capacity: k)
    defer {
        for buffer in [sumA, sumB, external, refinedA, refinedB, refinedExternal, weightTo, chances] { buffer.deallocate() }
        for buffer in [refinedSize, stamp, touched, candidates] { buffer.deallocate() }
    }
    for c in 0 ..< k {
        sumA[c] = 0
        sumB[c] = 0
        stamp[c] = -1
    }
    refined.withUnsafeMutableBufferPointer { refined in
        community.withUnsafeBufferPointer { community in
            rows.offsets.withUnsafeBufferPointer { offsets in
                rows.neighbors.withUnsafeBufferPointer { neighbors in
                    rows.weights.withUnsafeBufferPointer { weights in
                        a.withUnsafeBufferPointer { a in
                            b.withUnsafeBufferPointer { b in
                                for v in 0 ..< k {
                                    let c = community[v]
                                    sumA[c] += a[v]
                                    sumB[c] += b[v]
                                    var inside = 0.0
                                    for slot in offsets[v] ..< offsets[v + 1] where community[neighbors[slot]] == c {
                                        inside += weights[slot]
                                    }
                                    external[v] = inside
                                    refinedA[v] = a[v]
                                    refinedB[v] = b[v]
                                    refinedExternal[v] = inside
                                    refinedSize[v] = 1
                                }
                                var step = 0
                                for v in order {
                                    guard refined[v] == v, refinedSize[v] == 1 else { continue }
                                    let c = community[v]
                                    let av = a[v], bv = b[v]
                                    let totalA = sumA[c], totalB = sumB[c]
                                    guard external[v] >= gamma * (av * (totalB - bv) + bv * (totalA - av)) else { continue }
                                    step += 1
                                    var touchedCount = 0
                                    for slot in offsets[v] ..< offsets[v + 1] {
                                        let w = neighbors[slot]
                                        guard community[w] == c else { continue }
                                        let r = refined[w]
                                        if stamp[r] != step {
                                            stamp[r] = step
                                            weightTo[r] = 0
                                            touched[touchedCount] = r
                                            touchedCount += 1
                                        }
                                        weightTo[r] += weights[slot]
                                    }
                                    var count = 0
                                    var most = 0.0
                                    for i in 0 ..< touchedCount {
                                        let r = touched[i]
                                        let ra = refinedA[r], rb = refinedB[r]
                                        guard refinedExternal[r] >= gamma * (ra * (totalB - rb) + rb * (totalA - ra)) else { continue }
                                        let gain = weightTo[r] - gamma * (av * rb + bv * ra)
                                        guard gain >= 0 else { continue }
                                        candidates[count] = r
                                        chances[count] = gain
                                        count += 1
                                        if gain > most { most = gain }
                                    }
                                    guard count > 0 else { continue }
                                    // Staying alone gains 0; every chance is relative to the greatest gain.
                                    let stay = exp((0 - most) / theta)
                                    var total = stay
                                    for i in 0 ..< count {
                                        chances[i] = exp((chances[i] - most) / theta)
                                        total += chances[i]
                                    }
                                    var x = Double(generator.next() >> 11) * 0x1p-53 * total
                                    guard x >= stay else { continue }
                                    x -= stay
                                    var pick = count - 1
                                    for i in 0 ..< count - 1 {
                                        if x < chances[i] {
                                            pick = i
                                            break
                                        }
                                        x -= chances[i]
                                    }
                                    let r = candidates[pick]
                                    refined[v] = r
                                    refinedA[r] += av
                                    refinedB[r] += bv
                                    refinedSize[r] += 1
                                    refinedSize[v] = 0
                                    refinedExternal[r] += external[v] - 2 * weightTo[r]
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    return refined
}

/// Leiden (Traag, Waltman and van Eck 2019) in index space: a label per vertex. Each iteration
/// starts from the last partition and repeats the move phase, the refinement and an aggregation
/// in which each refined community becomes a vertex (in the community the move phase gave it),
/// or, when the refinement merges nothing, each community does, until the move phase leaves
/// every level vertex alone.
/// Iterations repeat until one moves no vertex at any level (so the partition is the one it started
/// from), or `iterations` of them have run; then each community is split into its connected parts.
@inlinable
func _leiden<R: RandomNumberGenerator>(_ graph: _CommunityGraph, _ weights: [Double]?, quality: QualityFunction, resolution: Double, randomness: Double, iterations: Int?, using generator: inout R) -> [Int] {
    let n = graph.count
    guard n > 1 else { return Array(0 ..< n) }
    var m = 0.0
    if let weights { for w in weights { m += w } } else { m = Double(graph.edgeCount) }
    let directed = graph.directed
    let modularity = quality == .modularity
    if modularity, m == 0 { return Array(0 ..< n) }
    // H = Σ_c [e_c − γ′ A_c B_c]: m Q for modularity, the constant Potts model itself.
    let gamma = modularity ? (directed ? resolution / m : resolution / (4 * m)) : (directed ? resolution : resolution / 2)
    let base = _LouvainLevel(count: n, directed: directed, from: graph.from, to: graph.to) { weights?[$0] ?? 1 }
    let baseRows = _LouvainRows(base)
    let baseA = modularity ? baseRows.out : [Double](repeating: 1, count: n)
    let baseB = modularity ? baseRows.into : baseA
    var membership = Array(0 ..< n)
    var iteration = 0
    while iterations.map({ iteration < $0 }) ?? true {
        iteration += 1
        var level = base, rows = baseRows, a = baseA, b = baseB
        var node = Array(0 ..< n)
        var community = membership
        var moved = false
        while true {
            if _leidenMove(rows, &community, a: a, b: b, scale: gamma, using: &generator) { moved = true }
            let k = level.count
            var rank = [Int](repeating: -1, count: k)
            var communities = 0
            for c in community where rank[c] < 0 {
                rank[c] = communities
                communities += 1
            }
            if communities == k { break }
            let refined = _leidenRefine(rows, community, a: a, b: b, scale: gamma, randomness: randomness, using: &generator)
            // Each level vertex's vertex on the next level: its refined community's, or, when the
            // refinement merged nothing, its community's (aggregating as Louvain does).
            var group = [Int](repeating: -1, count: k)
            var count = 0
            for v in 0 ..< k where refined[v] == v {
                group[v] = count
                count += 1
            }
            if count == k {
                group = community.map { rank[$0] }
                count = communities
            } else {
                for v in 0 ..< k { group[v] = group[refined[v]] }
            }
            var nextA = [Double](repeating: 0, count: count), nextB = nextA
            var nextCommunity = [Int](repeating: 0, count: count)
            for v in 0 ..< k {
                let r = group[v]
                nextA[r] += a[v]
                nextB[r] += b[v]
                nextCommunity[r] = rank[community[v]]
            }
            let pairs = level
            level = _LouvainLevel(count: count, directed: directed,
                                  from: pairs.pairFrom.map { group[$0] }, to: pairs.pairTo.map { group[$0] }) { pairs.pairWeight[$0] }
            rows = _LouvainRows(level)
            a = nextA
            b = nextB
            community = nextCommunity
            for v in 0 ..< n { node[v] = group[node[v]] }
        }
        // No move at any level leaves the partition as it was; a move raises the quality, so the
        // partition changed.
        guard moved else { break }
        membership = (0 ..< n).map { community[node[$0]] }
    }
    // A tie of gain 0 can keep two parts with no edge between them in one community (on a
    // directed graph a vertex without in-arcs pays no penalty beside one without out-arcs).
    // Splitting such a community never lowers the quality and leaves no vertex a gain.
    return _connectedParts(baseRows, membership)
}

/// Each community of `labels` split into the parts its edges connect (the rows' edges, any
/// weight): a label per vertex, the least vertex of its part.
@inlinable
func _connectedParts(_ rows: _LouvainRows, _ labels: [Int]) -> [Int] {
    let n = labels.count
    var part = [Int](repeating: -1, count: n)
    var stack: [Int] = []
    for s in 0 ..< n where part[s] < 0 {
        part[s] = s
        stack.append(s)
        while let v = stack.popLast() {
            for slot in rows.offsets[v] ..< rows.offsets[v + 1] {
                let w = rows.neighbors[slot]
                if part[w] < 0, labels[w] == labels[s] {
                    part[w] = s
                    stack.append(w)
                }
            }
        }
    }
    return part
}

@inlinable
func _checkLeiden(resolution: Double, randomness: Double, iterations: Int?) {
    _checkResolution(resolution)
    precondition(iterations.map { $0 >= 1 } ?? true, "The number of iterations must be at least one")
    precondition(randomness.isFinite && randomness > 0, "The randomness must be finite and greater than zero")
}

/// The constant Potts model: Σ_c [e_c − γ n_c² / 2] undirected, Σ_c [e_c − γ n_c²] directed, e_c
/// the weight of the edges inside community c (a self-loop inside its vertex's) and n_c its size.
@inlinable
func _constantPottsModel(_ graph: _CommunityGraph, _ weights: [Double]?, labels: [Int], count k: Int, resolution gamma: Double) -> Double {
    var inside = [Double](repeating: 0, count: k)
    var size = [Double](repeating: 0, count: k)
    for c in labels { size[c] += 1 }
    for e in 0 ..< graph.edgeCount {
        let c = labels[graph.from[e]]
        if c == labels[graph.to[e]] { inside[c] += weights?[e] ?? 1 }
    }
    let scale = graph.directed ? gamma : gamma / 2
    var h = 0.0
    for c in 0 ..< k { h += inside[c] - scale * size[c] * size[c] }
    return h
}

extension Graph {
    /// The constant Potts model of a grouping of the vertices (Traag, Van Dooren and Nesterov
    /// 2011): Σ_c [e_c − γ n_c² / 2], e_c the number of edges inside community c (a self-loop is
    /// inside, parallel copies each count) and n_c its number of vertices. O(n + m) after looking
    /// the vertices up.
    ///
    /// - Precondition: `communities` lists every vertex exactly once (empty communities are
    ///   allowed); `resolution` is finite and at least zero.
    @inlinable
    public func constantPottsModel<C: Collection>(of communities: C, resolution: Double = 1) -> Double where C.Element: Collection, C.Element.Element == Vertex {
        let numbers = _communityNumbers()
        let (labels, k) = _membership(communities, count: vertexCount) { _communityNumber(of: $0, numbers) }
        _checkResolution(resolution)
        return _constantPottsModel(_communityGraph(), nil, labels: labels, count: k, resolution: resolution)
    }

    /// The weighted constant Potts model: e_c is a sum of weights. `weight` is called once per
    /// edge, in position order.
    ///
    /// - Precondition: `communities` lists every vertex exactly once; every weight is finite and
    ///   at least zero; `resolution` is finite and at least zero.
    @inlinable
    public func constantPottsModel<C: Collection, W: BinaryFloatingPoint>(of communities: C, weight: (Edges.Index) -> W, resolution: Double = 1) -> Double where C.Element: Collection, C.Element.Element == Vertex {
        let numbers = _communityNumbers()
        let (labels, k) = _membership(communities, count: vertexCount) { _communityNumber(of: $0, numbers) }
        let weights = _communityWeights(weight)
        _checkResolution(resolution)
        return _constantPottsModel(_communityGraph(), weights, labels: labels, count: k, resolution: resolution)
    }

    @inlinable
    func _leidenCommunities<R: RandomNumberGenerator>(_ weights: [Double]?, quality: QualityFunction, resolution: Double, randomness: Double, iterations: Int?, using generator: inout R) -> Partition<DirectedView<Self>> {
        _checkLeiden(resolution: resolution, randomness: randomness, iterations: iterations)
        let listed = _listedVertices()
        let numbers = listed.map(_vertexNumbers)
        let labels = _leiden(_communityGraph(), weights, quality: quality, resolution: resolution, randomness: randomness, iterations: iterations, using: &generator)
        return Partition(directedView, numbers: numbers, listed: listed, labels: labels)
    }

    /// Leiden communities (Traag, Waltman and van Eck 2019), maximizing `quality`. Each level moves
    /// vertices from a queue (shuffled by `generator`) to the community of greatest gain, refines
    /// each community from singletons by merging well-connected vertices at random (a merge of gain
    /// ΔH ≥ 0 drawn with probability proportional to exp(ΔH / `randomness`), ΔH in units of edge
    /// weight: m times the modularity gain, or the constant Potts model's gain), and aggregates the
    /// refined communities into vertices. Iterations start from the last partition and repeat until
    /// one changes nothing (which leaves no vertex that gains by moving alone), or `iterations` of
    /// them have run. Every community is connected: refined communities grow only along edges, and
    /// each community is finally split into its connected parts, which never lowers the quality.
    /// Parallel edges add; a self-loop counts in degrees (modularity) or
    /// inside its community, and never moves a vertex.
    ///
    /// - Parameters:
    ///   - quality: what to maximize; modularity by default.
    ///   - resolution: γ; larger values give smaller communities.
    ///   - randomness: θ, how far the refinement's merges stray from the greatest gain.
    ///   - iterations: at most this many iterations; nil runs them until one changes nothing.
    ///   - generator: the source of the shuffles and the refinement's draws.
    /// - Returns: the communities, in canonical order.
    /// - Complexity: O(m) expected per pass over the queue and per refinement, on each level, per
    ///   iteration.
    /// - Precondition: `resolution` is finite and at least zero; `randomness` is finite and
    ///   greater than zero; `iterations`, when given, is at least 1.
    @inlinable
    public func leidenCommunities(quality: QualityFunction = .modularity, resolution: Double = 1, randomness: Double = 0.01, iterations: Int? = nil, using generator: inout some RandomNumberGenerator) -> Partition<DirectedView<Self>> {
        _leidenCommunities(nil, quality: quality, resolution: resolution, randomness: randomness, iterations: iterations, using: &generator)
    }

    /// Leiden communities drawing from the system's random number generator.
    ///
    /// - Precondition: `resolution` is finite and at least zero; `randomness` is finite and
    ///   greater than zero; `iterations`, when given, is at least 1.
    @inlinable
    public func leidenCommunities(quality: QualityFunction = .modularity, resolution: Double = 1, randomness: Double = 0.01, iterations: Int? = nil) -> Partition<DirectedView<Self>> {
        var generator = SystemRandomNumberGenerator()
        return _leidenCommunities(nil, quality: quality, resolution: resolution, randomness: randomness, iterations: iterations, using: &generator)
    }

    /// Weighted Leiden communities; `weight` is called once per edge, in position order.
    ///
    /// - Precondition: every weight is finite and at least zero; `resolution` is finite and at
    ///   least zero; `randomness` is finite and greater than zero; `iterations`, when given, is at least 1.
    @inlinable
    public func leidenCommunities<W: BinaryFloatingPoint>(weight: (Edges.Index) -> W, quality: QualityFunction = .modularity, resolution: Double = 1, randomness: Double = 0.01, iterations: Int? = nil, using generator: inout some RandomNumberGenerator) -> Partition<DirectedView<Self>> {
        _leidenCommunities(_communityWeights(weight), quality: quality, resolution: resolution, randomness: randomness, iterations: iterations, using: &generator)
    }

    /// Weighted Leiden communities drawing from the system's random number generator.
    ///
    /// - Precondition: every weight is finite and at least zero; `resolution` is finite and at
    ///   least zero; `randomness` is finite and greater than zero; `iterations`, when given, is at least 1.
    @inlinable
    public func leidenCommunities<W: BinaryFloatingPoint>(weight: (Edges.Index) -> W, quality: QualityFunction = .modularity, resolution: Double = 1, randomness: Double = 0.01, iterations: Int? = nil) -> Partition<DirectedView<Self>> {
        var generator = SystemRandomNumberGenerator()
        return _leidenCommunities(_communityWeights(weight), quality: quality, resolution: resolution, randomness: randomness, iterations: iterations, using: &generator)
    }
}

extension DirectedGraph {
    /// The directed constant Potts model: Σ_c [e_c − γ n_c²], e_c the number of arcs inside
    /// community c (a loop is inside). O(n + m) after looking the vertices up.
    ///
    /// - Precondition: `communities` lists every vertex exactly once (empty communities are
    ///   allowed); `resolution` is finite and at least zero.
    @inlinable
    public func constantPottsModel<C: Collection>(of communities: C, resolution: Double = 1) -> Double where C.Element: Collection, C.Element.Element == Vertex {
        let numbers = _communityNumbers()
        let (labels, k) = _membership(communities, count: vertexCount) { _communityNumber(of: $0, numbers) }
        _checkResolution(resolution)
        return _constantPottsModel(_communityGraph(numbers), nil, labels: labels, count: k, resolution: resolution)
    }

    /// The weighted directed constant Potts model. `weight` is called once per edge, in position
    /// order.
    ///
    /// - Precondition: `communities` lists every vertex exactly once; every weight is finite and
    ///   at least zero; `resolution` is finite and at least zero.
    @inlinable
    public func constantPottsModel<C: Collection, W: BinaryFloatingPoint>(of communities: C, weight: (Edges.Index) -> W, resolution: Double = 1) -> Double where C.Element: Collection, C.Element.Element == Vertex {
        let numbers = _communityNumbers()
        let (labels, k) = _membership(communities, count: vertexCount) { _communityNumber(of: $0, numbers) }
        let weights = _communityWeights(weight)
        _checkResolution(resolution)
        return _constantPottsModel(_communityGraph(numbers), weights, labels: labels, count: k, resolution: resolution)
    }

    @inlinable
    func _leidenCommunities<R: RandomNumberGenerator>(_ weights: [Double]?, quality: QualityFunction, resolution: Double, randomness: Double, iterations: Int?, using generator: inout R) -> Partition<Self> {
        _checkLeiden(resolution: resolution, randomness: randomness, iterations: iterations)
        let listed = _listedVertices()
        let numbers = listed.map(_vertexNumbers)
        let labels = _leiden(_communityGraph(numbers), weights, quality: quality, resolution: resolution, randomness: randomness, iterations: iterations, using: &generator)
        return Partition(self, numbers: numbers, listed: listed, labels: labels)
    }

    /// Leiden communities maximizing directed modularity or the directed constant Potts model, as
    /// on `Graph`: E(v, C) counts arcs both ways, and a vertex's out- and in-degree pair with its
    /// community's in- and out-degree sums. Every community is weakly connected.
    ///
    /// - Complexity: O(m) expected per pass over the queue and per refinement, on each level, per
    ///   iteration.
    /// - Precondition: `resolution` is finite and at least zero; `randomness` is finite and
    ///   greater than zero; `iterations`, when given, is at least 1.
    @inlinable
    public func leidenCommunities(quality: QualityFunction = .modularity, resolution: Double = 1, randomness: Double = 0.01, iterations: Int? = nil, using generator: inout some RandomNumberGenerator) -> Partition<Self> {
        _leidenCommunities(nil, quality: quality, resolution: resolution, randomness: randomness, iterations: iterations, using: &generator)
    }

    /// Directed Leiden communities drawing from the system's random number generator.
    ///
    /// - Precondition: `resolution` is finite and at least zero; `randomness` is finite and
    ///   greater than zero; `iterations`, when given, is at least 1.
    @inlinable
    public func leidenCommunities(quality: QualityFunction = .modularity, resolution: Double = 1, randomness: Double = 0.01, iterations: Int? = nil) -> Partition<Self> {
        var generator = SystemRandomNumberGenerator()
        return _leidenCommunities(nil, quality: quality, resolution: resolution, randomness: randomness, iterations: iterations, using: &generator)
    }

    /// Weighted directed Leiden communities; `weight` is called once per edge, in position order.
    ///
    /// - Precondition: every weight is finite and at least zero; `resolution` is finite and at
    ///   least zero; `randomness` is finite and greater than zero; `iterations`, when given, is at least 1.
    @inlinable
    public func leidenCommunities<W: BinaryFloatingPoint>(weight: (Edges.Index) -> W, quality: QualityFunction = .modularity, resolution: Double = 1, randomness: Double = 0.01, iterations: Int? = nil, using generator: inout some RandomNumberGenerator) -> Partition<Self> {
        _leidenCommunities(_communityWeights(weight), quality: quality, resolution: resolution, randomness: randomness, iterations: iterations, using: &generator)
    }

    /// Weighted directed Leiden communities drawing from the system's random number generator.
    ///
    /// - Precondition: every weight is finite and at least zero; `resolution` is finite and at
    ///   least zero; `randomness` is finite and greater than zero; `iterations`, when given, is at least 1.
    @inlinable
    public func leidenCommunities<W: BinaryFloatingPoint>(weight: (Edges.Index) -> W, quality: QualityFunction = .modularity, resolution: Double = 1, randomness: Double = 0.01, iterations: Int? = nil) -> Partition<Self> {
        var generator = SystemRandomNumberGenerator()
        return _leidenCommunities(_communityWeights(weight), quality: quality, resolution: resolution, randomness: randomness, iterations: iterations, using: &generator)
    }
}
