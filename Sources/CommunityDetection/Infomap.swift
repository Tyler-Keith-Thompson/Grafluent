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

// The two-level map equation (Rosvall and Bergstrom) on an undirected graph: a random walker's
// flow is p_α = d_α / 2W at each vertex and w / 2W along each edge each way, W the total weight.
// A module's exit flow q_i is the flow along its edges leaving it, and the code length is
//   L(M) = f(Σ q_i) − 2 Σ f(q_i) − Σ f(p_α) + Σ f(q_i + p_i),  f(x) = x log₂ x,
// p_i the module's vertex flow.

/// x log₂ x, 0 for x ≤ 0 (rounding can leave a vanished exit flow slightly negative).
@inlinable
func _plogp(_ x: Double) -> Double {
    x > 0 ? x * log2(x) : 0
}

/// One level of the Infomap search: nodes (vertices, or the modules of the level below) with
/// their flow, and symmetric rows of the flow between distinct nodes.
@frozen
@usableFromInline
struct _FlowLevel {
    @usableFromInline var flow: [Double]
    /// Each node's flow to other nodes, its exit flow when alone.
    @usableFromInline var exit: [Double]
    @usableFromInline var offsets: [Int]
    @usableFromInline var targets: [Int]
    @usableFromInline var linkFlow: [Double]

    @inlinable
    init(flow: [Double], exit: [Double], offsets: [Int], targets: [Int], linkFlow: [Double]) {
        self.flow = flow
        self.exit = exit
        self.offsets = offsets
        self.targets = targets
        self.linkFlow = linkFlow
    }

    @inlinable
    var count: Int { flow.count }

    /// The vertex level: each edge's flow both ways, self-loops adding only to their vertex.
    /// `nil` when the total weight is zero.
    @inlinable
    init?(_ graph: _CommunityGraph, _ weights: [Double]?) {
        let n = graph.count
        var total = 0.0
        for e in 0 ..< graph.edgeCount { total += weights?[e] ?? 1 }
        guard total > 0 else { return nil }
        let scale = 1 / (2 * total)
        var flow = [Double](repeating: 0, count: n)
        var exit = [Double](repeating: 0, count: n)
        var offsets = [Int](repeating: 0, count: n + 1)
        for e in 0 ..< graph.edgeCount where graph.from[e] != graph.to[e] {
            offsets[graph.from[e] + 1] += 1
            offsets[graph.to[e] + 1] += 1
        }
        for v in 0 ..< n { offsets[v + 1] += offsets[v] }
        var fill = offsets
        var targets = [Int](repeating: 0, count: offsets[n])
        var linkFlow = [Double](repeating: 0, count: offsets[n])
        for e in 0 ..< graph.edgeCount {
            let u = graph.from[e], v = graph.to[e]
            let f = (weights?[e] ?? 1) * scale
            flow[u] += f
            flow[v] += f
            guard u != v else { continue }
            exit[u] += f
            exit[v] += f
            targets[fill[u]] = v
            linkFlow[fill[u]] = f
            fill[u] += 1
            targets[fill[v]] = u
            linkFlow[fill[v]] = f
            fill[v] += 1
        }
        self.init(flow: flow, exit: exit, offsets: offsets, targets: targets, linkFlow: linkFlow)
    }

    /// The level whose nodes are the modules `module[α]` in `0..<count`, links between modules
    /// summed and links inside a module dropped.
    @inlinable
    func aggregated(_ module: [Int], count k: Int) -> _FlowLevel {
        var flow = [Double](repeating: 0, count: k)
        var exit = [Double](repeating: 0, count: k)
        var counts = [Int](repeating: 0, count: k + 1)
        for a in 0 ..< count {
            flow[module[a]] += self.flow[a]
            counts[module[a] + 1] += offsets[a + 1] - offsets[a]
        }
        for i in 0 ..< k { counts[i + 1] += counts[i] }
        // The nodes of each module, then their links merged by target module.
        var members = [Int](repeating: 0, count: count)
        var memberOffsets = [Int](repeating: 0, count: k + 1)
        for a in 0 ..< count { memberOffsets[module[a] + 1] += 1 }
        for i in 0 ..< k { memberOffsets[i + 1] += memberOffsets[i] }
        var fill = memberOffsets
        for a in 0 ..< count {
            members[fill[module[a]]] = a
            fill[module[a]] += 1
        }
        var offsets = [Int](repeating: 0, count: k + 1)
        var targets: [Int] = [], linkFlow: [Double] = []
        targets.reserveCapacity(counts[k])
        linkFlow.reserveCapacity(counts[k])
        var slotOf = [Int](repeating: -1, count: k)
        for i in 0 ..< k {
            let start = targets.count
            for m in memberOffsets[i] ..< memberOffsets[i + 1] {
                let a = members[m]
                for slot in self.offsets[a] ..< self.offsets[a + 1] {
                    let j = module[self.targets[slot]]
                    guard j != i else { continue }
                    let f = self.linkFlow[slot]
                    exit[i] += f
                    if slotOf[j] < start {
                        slotOf[j] = targets.count
                        targets.append(j)
                        linkFlow.append(f)
                    } else {
                        linkFlow[slotOf[j]] += f
                    }
                }
            }
            offsets[i + 1] = targets.count
        }
        return _FlowLevel(flow: flow, exit: exit, offsets: offsets, targets: targets, linkFlow: linkFlow)
    }
}

/// The code length of `labels` (in `0..<count`) on the vertex level, the vertex entropy Σ f(p_α)
/// given.
@inlinable
func _codeLength(_ level: _FlowLevel, _ labels: [Int], count k: Int, vertexEntropy: Double) -> Double {
    var exit = [Double](repeating: 0, count: k)
    var flow = [Double](repeating: 0, count: k)
    for a in 0 ..< level.count {
        let i = labels[a]
        flow[i] += level.flow[a]
        for slot in level.offsets[a] ..< level.offsets[a + 1] where labels[level.targets[slot]] != i {
            exit[i] += level.linkFlow[slot]
        }
    }
    var total = 0.0, exitTerm = 0.0, sizeTerm = 0.0
    for i in 0 ..< k {
        total += exit[i]
        exitTerm += _plogp(exit[i])
        sizeTerm += _plogp(exit[i] + flow[i])
    }
    return _plogp(total) - 2 * exitTerm - vertexEntropy + sizeTerm
}

/// The greedy moves of one level: each node, in an order shuffled per sweep, moves to the
/// neighboring module (or an empty one) that shortens the code length most, the candidates
/// scanned in a shuffled order so that ties go to any of them, until a sweep moves none. `module` holds the starting modules, in `0..<level.count`, and ends with the found ones.
@inlinable
func _infomapMoves<R: RandomNumberGenerator>(_ level: _FlowLevel, _ module: inout [Int], _ generator: inout R) {
    let n = level.count
    var flow = [Double](repeating: 0, count: n)
    var exit = [Double](repeating: 0, count: n)
    var size = [Int](repeating: 0, count: n)
    for a in 0 ..< n {
        let i = module[a]
        flow[i] += level.flow[a]
        size[i] += 1
        for slot in level.offsets[a] ..< level.offsets[a + 1] where module[level.targets[slot]] != i {
            exit[i] += level.linkFlow[slot]
        }
    }
    var empty: [Int] = []
    for i in (0 ..< n).reversed() where size[i] == 0 { empty.append(i) }
    var totalExit = 0.0
    for i in 0 ..< n { totalExit += exit[i] }
    var stamp = [Int](repeating: -1, count: n)
    var toModule = [Double](repeating: 0, count: n)
    var touched: [Int] = []
    var tick = 0
    while true {
        var moved = false
        let order = _shuffledOrder(n, &generator)
        for a in order {
            let source = module[a]
            tick += 1
            touched.removeAll(keepingCapacity: true)
            for slot in level.offsets[a] ..< level.offsets[a + 1] {
                let j = module[level.targets[slot]]
                if stamp[j] != tick {
                    stamp[j] = tick
                    toModule[j] = 0
                    touched.append(j)
                }
                toModule[j] += level.linkFlow[slot]
            }
            let pa = level.flow[a], ea = level.exit[a]
            let toSource = stamp[source] == tick ? toModule[source] : 0
            let qA = exit[source], pA = flow[source]
            let qA2 = qA - ea + 2 * toSource, pA2 = pA - pa
            let fixedA = -2 * (_plogp(qA2) - _plogp(qA)) + _plogp(qA2 + pA2) - _plogp(qA + pA)
            if size[source] > 1, let e = empty.last {
                stamp[e] = tick
                toModule[e] = 0
                touched.append(e)
            }
            // The candidates in random order, so that the first of several equal gains is taken
            // at random rather than always the one nearest the front of the row.
            var c = touched.count - 1
            while c > 0 {
                touched.swapAt(c, Int(generator.next(upperBound: UInt(c + 1))))
                c -= 1
            }
            var best = 0.0, target = source
            for b in touched {
                guard b != source else { continue }
                let toB = toModule[b]
                let qB = exit[b], pB = flow[b]
                let qB2 = qB + ea - 2 * toB, pB2 = pB + pa
                let total = totalExit - qA - qB + qA2 + qB2
                let delta = _plogp(total) - _plogp(totalExit) + fixedA
                    - 2 * (_plogp(qB2) - _plogp(qB)) + _plogp(qB2 + pB2) - _plogp(qB + pB)
                if delta < best {
                    best = delta
                    target = b
                }
            }
            guard best < -1e-10 else { continue }
            let toTarget = stamp[target] == tick ? toModule[target] : 0
            if size[target] == 0 { empty.removeLast() }
            let qB = exit[target]
            exit[source] = qA2
            flow[source] = pA2
            exit[target] = qB + ea - 2 * toTarget
            flow[target] += pa
            totalExit += exit[source] + exit[target] - qA - qB
            size[source] -= 1
            size[target] += 1
            if size[source] == 0 { empty.append(source) }
            module[a] = target
            moved = true
        }
        if !moved { break }
    }
}

/// Renumbers `module` densely by first appearance; returns the number of modules.
@inlinable
func _renumber(_ module: inout [Int]) -> Int {
    var map = [Int](repeating: -1, count: module.count)
    var k = 0
    for a in module.indices {
        if map[module[a]] < 0 {
            map[module[a]] = k
            k += 1
        }
        module[a] = map[module[a]]
    }
    return k
}

/// One run of the core algorithm on `level`, whose node `vertexNode[v]` holds vertex v, from the
/// modules `start` (in `0..<level.count`): greedy moves, then each module merged into a node, level
/// by level until no two modules merge. Returns each vertex's module.
@inlinable
func _infomapCore<R: RandomNumberGenerator>(_ level: _FlowLevel, _ start: [Int], _ vertexNode: [Int], _ generator: inout R) -> [Int] {
    var labels = vertexNode
    var level = level
    var module = start
    while true {
        _infomapMoves(level, &module, &generator)
        let k = _renumber(&module)
        for v in labels.indices { labels[v] = module[labels[v]] }
        guard k < level.count else { break }
        level = level.aggregated(module, count: k)
        module = Array(0 ..< k)
    }
    return labels
}

/// The vertices of each module split by the core algorithm run on the module alone (its inner
/// links, flows scaled to sum to 1), as submodule numbers per vertex, and their count.
@inlinable
func _submodules<R: RandomNumberGenerator>(_ base: _FlowLevel, _ labels: [Int], count k: Int, _ generator: inout R) -> (labels: [Int], count: Int) {
    let n = base.count
    var memberOffsets = [Int](repeating: 0, count: k + 1)
    for v in 0 ..< n { memberOffsets[labels[v] + 1] += 1 }
    for i in 0 ..< k { memberOffsets[i + 1] += memberOffsets[i] }
    var fill = memberOffsets
    var members = [Int](repeating: 0, count: n)
    for v in 0 ..< n {
        members[fill[labels[v]]] = v
        fill[labels[v]] += 1
    }
    var local = [Int](repeating: 0, count: n)
    var sub = [Int](repeating: 0, count: n)
    var count = 0
    for i in 0 ..< k {
        let inside = members[memberOffsets[i] ..< memberOffsets[i + 1]]
        let c = inside.count
        for (l, v) in inside.enumerated() { local[v] = l }
        var flow = [Double](repeating: 0, count: c), exit = [Double](repeating: 0, count: c)
        var offsets = [Int](repeating: 0, count: c + 1)
        var targets: [Int] = [], linkFlow: [Double] = []
        var total = 0.0
        for (l, v) in inside.enumerated() {
            // A self-loop's flow stays with its vertex.
            flow[l] = base.flow[v] - base.exit[v]
            for slot in base.offsets[v] ..< base.offsets[v + 1] where labels[base.targets[slot]] == i {
                targets.append(local[base.targets[slot]])
                linkFlow.append(base.linkFlow[slot])
                exit[l] += base.linkFlow[slot]
            }
            flow[l] += exit[l]
            total += flow[l]
            offsets[l + 1] = targets.count
        }
        guard c > 1, total > 0 else {
            for v in inside { sub[v] = count }
            count += 1
            continue
        }
        let scale = 1 / total
        for l in 0 ..< c {
            flow[l] *= scale
            exit[l] *= scale
        }
        for slot in linkFlow.indices { linkFlow[slot] *= scale }
        let level = _FlowLevel(flow: flow, exit: exit, offsets: offsets, targets: targets, linkFlow: linkFlow)
        var parts = _infomapCore(level, Array(0 ..< c), Array(0 ..< c), &generator)
        let found = _renumber(&parts)
        for (l, v) in inside.enumerated() { sub[v] = count + parts[l] }
        count += found
    }
    return (sub, count)
}

/// The best of `trials` runs: each the core algorithm from singletons, then tuned while that
/// shortens the code length, alternately from its modules on the vertices (fine tuning) and from
/// its modules on their submodules (coarse tuning); the single module when it is shorter still.
@inlinable
func _infomap<R: RandomNumberGenerator>(_ graph: _CommunityGraph, _ weights: [Double]?, trials: Int, _ generator: inout R) -> [Int] {
    precondition(trials >= 1, "Infomap needs at least one trial")
    let n = graph.count
    guard let base = _FlowLevel(graph, weights) else { return Array(0 ..< n) }
    var entropy = 0.0
    for a in 0 ..< n { entropy += _plogp(base.flow[a]) }
    let identity = Array(0 ..< n)
    var best = [Int](repeating: 0, count: n)
    var bestLength = _codeLength(base, best, count: 1, vertexEntropy: entropy)
    for _ in 0 ..< trials {
        var labels = _infomapCore(base, identity, identity, &generator)
        var k = _renumber(&labels)
        var length = _codeLength(base, labels, count: k, vertexEntropy: entropy)
        var fine = true
        var stale = 0
        while stale < 2 {
            var tuned: [Int]
            if fine {
                tuned = _infomapCore(base, labels, identity, &generator)
            } else {
                let (sub, s) = _submodules(base, labels, count: k, &generator)
                var parent = [Int](repeating: 0, count: s)
                for v in 0 ..< n { parent[sub[v]] = labels[v] }
                tuned = _infomapCore(base.aggregated(sub, count: s), parent, sub, &generator)
            }
            fine.toggle()
            let tunedCount = _renumber(&tuned)
            let tunedLength = _codeLength(base, tuned, count: tunedCount, vertexEntropy: entropy)
            if tunedLength < length - 1e-10 {
                labels = tuned
                k = tunedCount
                length = tunedLength
                stale = 0
            } else {
                stale += 1
            }
        }
        if length < bestLength - 1e-10 {
            best = labels
            bestLength = length
        }
    }
    return best
}

extension Graph {
    @inlinable
    func _infomapCommunities<R: RandomNumberGenerator>(_ weights: [Double]?, trials: Int, _ generator: inout R) -> Partition<DirectedView<Self>> {
        let listed = _listedVertices()
        let numbers = listed.map(_vertexNumbers)
        let labels = _infomap(_communityGraph(), weights, trials: trials, &generator)
        return Partition(directedView, numbers: numbers, listed: listed, labels: labels)
    }

    /// Infomap communities (Rosvall and Bergstrom): the partition of shortest two-level map
    /// equation code length found in `trials` runs, see `codeLength(of:)`. Each run starts from
    /// every vertex alone; a level moves each node, in an order shuffled by `generator` each
    /// sweep, to the neighboring module (or an empty one) that shortens the code length most,
    /// until a sweep moves none, then merges each module into a node, until no modules merge.
    /// The run is then tuned while that shortens the code length, alternately from its modules on
    /// the vertices and from its modules on their submodules (each module split by a run on it
    /// alone), and the single module wins when it is shorter than every run. Parallel edges add; a
    /// self-loop adds to its vertex's flow and never leaves a module. A graph without edges
    /// gives every vertex alone. O(m) per sweep.
    ///
    /// - Precondition: `trials >= 1`.
    @inlinable
    public func infomapCommunities(trials: Int = 10, using generator: inout some RandomNumberGenerator) -> Partition<DirectedView<Self>> {
        _infomapCommunities(nil, trials: trials, &generator)
    }

    /// Weighted Infomap communities: flow along each edge in proportion to its weight. `weight`
    /// is called once per edge, in position order. A graph whose weights are all zero gives
    /// every vertex alone.
    ///
    /// - Precondition: every weight is finite and at least zero; `trials >= 1`.
    @inlinable
    public func infomapCommunities<W: BinaryFloatingPoint>(weight: (Edges.Index) -> W, trials: Int = 10, using generator: inout some RandomNumberGenerator) -> Partition<DirectedView<Self>> {
        _infomapCommunities(_communityWeights(weight), trials: trials, &generator)
    }

    /// The two-level map equation's code length L(M) of a grouping of the vertices, in bits
    /// (Rosvall and Bergstrom): the flow is d_α / 2W at each vertex and 1 / 2W along each edge
    /// each way, W the number of edges (a self-loop counts twice in a degree and never leaves a
    /// module); with q_i a community's exit flow and p_i its vertices' flow,
    /// L(M) = f(Σ q_i) − 2 Σ f(q_i) − Σ f(p_α) + Σ f(q_i + p_i), f(x) = x log₂ x. 0 without
    /// edges. Takes any grouping, such as a `Partition`. O(n + m) after looking the vertices up.
    ///
    /// - Precondition: `communities` lists every vertex exactly once (empty communities are
    ///   allowed).
    @inlinable
    public func codeLength<C: Collection>(of communities: C) -> Double where C.Element: Collection, C.Element.Element == Vertex {
        let numbers = _communityNumbers()
        let (labels, k) = _membership(communities, count: vertexCount) { _communityNumber(of: $0, numbers) }
        return _graphCodeLength(nil, labels, count: k)
    }

    /// Weighted code length: W and the degrees are sums of weights. `weight` is called once per
    /// edge, in position order. 0 when the weights are all zero.
    ///
    /// - Precondition: `communities` lists every vertex exactly once; every weight is finite and
    ///   at least zero.
    @inlinable
    public func codeLength<C: Collection, W: BinaryFloatingPoint>(of communities: C, weight: (Edges.Index) -> W) -> Double where C.Element: Collection, C.Element.Element == Vertex {
        let numbers = _communityNumbers()
        let (labels, k) = _membership(communities, count: vertexCount) { _communityNumber(of: $0, numbers) }
        return _graphCodeLength(_communityWeights(weight), labels, count: k)
    }

    @inlinable
    func _graphCodeLength(_ weights: [Double]?, _ labels: [Int], count k: Int) -> Double {
        guard let base = _FlowLevel(_communityGraph(), weights) else { return 0 }
        var entropy = 0.0
        for a in 0 ..< base.count { entropy += _plogp(base.flow[a]) }
        return _codeLength(base, labels, count: k, vertexEntropy: entropy)
    }
}
