import GraphProtocols

/// Votes for one vertex's label: each slot of its row to another vertex adds the edge's weight to
/// that neighbor's label, labels kept in order of first vote; zero-weight edges cast no vote, so
/// every change strictly raises the weight of edges whose ends agree, and propagation stops (with
/// non-dyadic weights a change decided by rounded sums could in principle be no gain; fuzzing
/// found no such cycle).
/// Reused across vertices.
@frozen
@usableFromInline
struct _Votes {
    @usableFromInline var total: [Double]
    @usableFromInline var stamp: [Int]
    @usableFromInline var labels: [Int] = []
    @usableFromInline var best: [Int] = []
    @usableFromInline var most = 0.0
    @usableFromInline var round = 0

    @inlinable
    init(count: Int) {
        total = [Double](repeating: 0, count: count)
        stamp = [Int](repeating: -1, count: count)
    }

    /// Counts `u`'s votes and lists the most voted labels in `best`, in order of first vote; false
    /// when `u` has no votes.
    @inlinable
    mutating func count(_ u: Int, _ graph: _CommunityGraph, _ weights: [Double]?, _ label: [Int]) -> Bool {
        round += 1
        labels.removeAll(keepingCapacity: true)
        for slot in graph.offsets[u] ..< graph.offsets[u + 1] {
            let t = graph.targets[slot]
            if t == u { continue }
            let x = weights.map { $0[graph.edges[slot]] } ?? 1
            // A zero-weight edge casts no vote: otherwise a vertex could switch between labels of
            // equal (zero) support forever.
            if x == 0 { continue }
            let l = label[t]
            if stamp[l] != round {
                stamp[l] = round
                total[l] = 0
                labels.append(l)
            }
            total[l] += x
        }
        guard !labels.isEmpty else { return false }
        most = total[labels[0]]
        for l in labels where total[l] > most { most = total[l] }
        best.removeAll(keepingCapacity: true)
        for l in labels where total[l] == most { best.append(l) }
        return true
    }

    /// Whether `l` is among the most voted labels of the last count.
    @inlinable
    func isBest(_ l: Int) -> Bool { stamp[l] == round && total[l] == most }
}

/// Semi-synchronous label propagation (Cordasco and Gargano; NetworkX
/// `label_propagation_communities`): a greedy coloring in largest-degree-first order, then rounds
/// over the color classes until every vertex with votes holds a most-voted label.
@inlinable
func _semisynchronousLabelPropagation(_ graph: _CommunityGraph, _ weights: [Double]?) -> [Int] {
    let n = graph.count
    // Largest row first, ties by vertex number; smallest color no colored neighbor has.
    let byDegree = (0 ..< n).sorted {
        let a = graph.offsets[$0 + 1] - graph.offsets[$0], b = graph.offsets[$1 + 1] - graph.offsets[$1]
        return a != b ? a > b : $0 < $1
    }
    var color = [Int](repeating: -1, count: n)
    var used = [Int](repeating: -1, count: n + 1)
    var colors = 0
    for v in byDegree {
        for slot in graph.offsets[v] ..< graph.offsets[v + 1] {
            let t = graph.targets[slot]
            if t != v, color[t] >= 0 { used[color[t]] = v }
        }
        var c = 0
        while used[c] == v { c += 1 }
        color[v] = c
        colors = max(colors, c + 1)
    }
    var classes = [[Int]](repeating: [], count: colors)
    for v in 0 ..< n { classes[color[v]].append(v) }
    var label = Array(0 ..< n)
    var votes = _Votes(count: n)
    // A round that changes nothing is NetworkX's stop test (every vertex with votes holds a
    // most-voted label): if some vertex does not, it or a vertex before it changes in the round.
    var changed = true
    while changed {
        changed = false
        for members in classes {
            for u in members where votes.count(u, graph, weights, label) {
                if votes.best.count == 1 {
                    if label[u] != votes.best[0] {
                        label[u] = votes.best[0]
                        changed = true
                    }
                } else if !votes.isBest(label[u]) {
                    label[u] = votes.best.max()!
                    changed = true
                }
            }
        }
    }
    return label
}

/// Asynchronous label propagation (Raghavan, Albert and Kumara; NetworkX `asyn_lpa_communities`):
/// sweeps in `order()` (index order when it returns nil) until one changes nothing; a vertex not
/// holding a most-voted label takes `choose(best)`.
@inlinable
func _asynchronousLabelPropagation(_ graph: _CommunityGraph, _ weights: [Double]?, order: () -> [Int]?, choose: ([Int]) -> Int) -> [Int] {
    var label = Array(0 ..< graph.count)
    var votes = _Votes(count: graph.count)
    var changed = true
    while changed {
        changed = false
        if let shuffled = order() {
            for u in shuffled where votes.count(u, graph, weights, label) && !votes.isBest(label[u]) {
                label[u] = choose(votes.best)
                changed = true
            }
        } else {
            for u in 0 ..< graph.count where votes.count(u, graph, weights, label) && !votes.isBest(label[u]) {
                label[u] = choose(votes.best)
                changed = true
            }
        }
    }
    return label
}

extension Graph {
    @inlinable
    func _labelPropagation(_ weights: [Double]?, _ run: (_CommunityGraph) -> [Int]) -> Partition<DirectedView<Self>> {
        let listed = _listedVertices()
        let numbers = listed.map(CommunityDetection._communityNumbers)
        let labels = run(_labelPropagationRows(readsEdges: weights != nil))
        return Partition(directed, numbers: numbers, listed: listed, labels: labels)
    }

    /// Label propagation communities, semi-synchronous (Cordasco and Gargano; NetworkX
    /// `label_propagation_communities`): every vertex starts with its own label and repeatedly
    /// takes the label most of its edges lead to (each parallel edge votes; self-loops vote for
    /// nothing), keeping its own on a tie, otherwise taking the greatest; vertices of one color of a
    /// greedy coloring update together. Deterministic.
    @inlinable
    public func labelPropagationCommunities() -> Partition<DirectedView<Self>> {
        _labelPropagation(nil) { _semisynchronousLabelPropagation($0, nil) }
    }

    /// Weighted semi-synchronous label propagation: each edge votes with its weight (a zero-weight
    /// edge does not vote). `weight` is called once per edge, in position order.
    ///
    /// - Precondition: every weight is finite and at least zero.
    @inlinable
    public func labelPropagationCommunities<W: BinaryFloatingPoint>(weight: (Edges.Index) -> W) -> Partition<DirectedView<Self>> {
        let weights = _communityWeights(weight)
        return _labelPropagation(weights) { _semisynchronousLabelPropagation($0, weights) }
    }

    /// Asynchronous label propagation communities (Raghavan, Albert and Kumara; NetworkX
    /// `asyn_lpa_communities`): sweeps in vertex index order, each vertex not holding a most-voted
    /// label taking the greatest of them, until a sweep changes nothing. Deterministic; on
    /// symmetric graphs (a ring of cliques) one label can flood the graph, which the `using:` form
    /// usually avoids.
    @inlinable
    public func asynchronousLabelPropagationCommunities() -> Partition<DirectedView<Self>> {
        _labelPropagation(nil) { graph in
            _asynchronousLabelPropagation(graph, nil, order: { nil }, choose: { $0.max()! })
        }
    }

    /// Weighted asynchronous label propagation. `weight` is called once per edge, in position order.
    ///
    /// - Precondition: every weight is finite and at least zero.
    @inlinable
    public func asynchronousLabelPropagationCommunities<W: BinaryFloatingPoint>(weight: (Edges.Index) -> W) -> Partition<DirectedView<Self>> {
        let weights = _communityWeights(weight)
        return _labelPropagation(weights) { graph in
            _asynchronousLabelPropagation(graph, weights, order: { nil }, choose: { $0.max()! })
        }
    }

    /// Asynchronous label propagation with each sweep's order shuffled by `generator` (NetworkX's
    /// `seed`): each sweep shuffles a fresh `0 ..< n` by Fisher–Yates (as
    /// `louvainCommunities(using:)`), and every vertex not holding a most-voted label draws once,
    /// even when one label is most voted, taking the `generator.next(upperBound: t)`-th of the t
    /// most-voted labels in order of first vote.
    @inlinable
    public func asynchronousLabelPropagationCommunities(using generator: inout some RandomNumberGenerator) -> Partition<DirectedView<Self>> {
        _labelPropagation(nil) { graph in
            _asynchronousLabelPropagation(graph, nil, order: { _shuffledOrder(graph.count, &generator) }, choose: { $0[Int(generator.next(upperBound: UInt($0.count)))] })
        }
    }

    /// Weighted asynchronous label propagation with shuffled sweeps and random ties.
    ///
    /// - Precondition: every weight is finite and at least zero.
    @inlinable
    public func asynchronousLabelPropagationCommunities<W: BinaryFloatingPoint>(weight: (Edges.Index) -> W, using generator: inout some RandomNumberGenerator) -> Partition<DirectedView<Self>> {
        let weights = _communityWeights(weight)
        return _labelPropagation(weights) { graph in
            _asynchronousLabelPropagation(graph, weights, order: { _shuffledOrder(graph.count, &generator) }, choose: { $0[Int(generator.next(upperBound: UInt($0.count)))] })
        }
    }
}
