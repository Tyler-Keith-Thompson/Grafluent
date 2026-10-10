import GraphProtocols

/// A candidate merge for Clauset–Newman–Moore: ΔQ for joining community u into v.
@frozen
@usableFromInline
struct _Merge {
    @usableFromInline let gain: Double
    @usableFromInline let u: Int
    @usableFromInline let v: Int

    @inlinable
    init(gain: Double, u: Int, v: Int) {
        self.gain = gain
        self.u = u
        self.v = v
    }

    /// Whether `self` is taken before `other`: greater gain, then the least pair (u, v).
    @inlinable
    func precedes(_ other: _Merge) -> Bool {
        if gain != other.gain { return gain > other.gain }
        return u != other.u ? u < other.u : v < other.v
    }
}

/// A binary heap of merges, best first. Entries go stale when their pair's ΔQ changes; the caller
/// checks each popped entry against the current table.
@frozen
@usableFromInline
struct _MergeHeap {
    @usableFromInline var items: [_Merge] = []

    @inlinable
    init() {}

    @inlinable
    mutating func push(_ item: _Merge) {
        items.append(item)
        var i = items.count - 1
        while i > 0 {
            let parent = (i - 1) / 2
            guard items[i].precedes(items[parent]) else { break }
            items.swapAt(i, parent)
            i = parent
        }
    }

    @inlinable
    mutating func pop() -> _Merge? {
        guard let top = items.first else { return nil }
        let last = items.removeLast()
        if !items.isEmpty {
            items[0] = last
            var i = 0
            let n = items.count
            while true {
                let l = 2 * i + 1, r = l + 1
                var best = i
                if l < n, items[l].precedes(items[best]) { best = l }
                if r < n, items[r].precedes(items[best]) { best = r }
                if best == i { break }
                items.swapAt(i, best)
                i = best
            }
        }
        return top
    }
}

/// A community's ΔQ row: its adjacent communities in increasing number, each with ΔQ for merging.
@frozen
@usableFromInline
struct _GainRow {
    @usableFromInline var neighbors: [Int] = []
    @usableFromInline var gains: [Double] = []

    @inlinable
    init() {}

    /// The position of `x`, or where it would be inserted.
    @inlinable
    func position(of x: Int) -> (index: Int, found: Bool) {
        var low = 0, high = neighbors.count
        while low < high {
            let mid = (low + high) / 2
            if neighbors[mid] < x { low = mid + 1 } else { high = mid }
        }
        return (low, low < neighbors.count && neighbors[low] == x)
    }

    @inlinable
    func gain(to x: Int) -> Double? {
        let (i, found) = position(of: x)
        return found ? gains[i] : nil
    }

    @inlinable
    mutating func set(_ x: Int, _ gain: Double) {
        let (i, found) = position(of: x)
        if found {
            gains[i] = gain
        } else {
            neighbors.insert(x, at: i)
            gains.insert(gain, at: i)
        }
    }

    @inlinable
    mutating func remove(_ x: Int) {
        let (i, found) = position(of: x)
        if found {
            neighbors.remove(at: i)
            gains.remove(at: i)
        }
    }
}

/// Clauset–Newman–Moore with NetworkX's arithmetic and order: ΔQ_ij = w_ij/m − γ(a_i b_j + b_i a_j)
/// for adjacent communities, the greatest taken first (ties to the least pair (i, j), i < j, i
/// merged into j), neighbors updated by CNM's three rules, until the greatest ΔQ is negative.
/// Rows are sorted arrays merged linearly; the heap holds one entry per pair (i < j) and is rebuilt
/// from the rows when stale entries outnumber live ones, so memory stays O(m). Returns a label per
/// vertex (the surviving community's number).
@inlinable
func _greedyModularity(_ graph: _CommunityGraph, _ weights: [Double]?, resolution gamma: Double) -> [Int] {
    let n = graph.count
    var m = 0.0
    if let weights { for w in weights { m += w } } else { m = Double(graph.edgeCount) }
    guard graph.edgeCount > 0, m != 0 else { return Array(0 ..< n) }
    let q0 = 1 / m
    var out = [Double](repeating: 0, count: n), into = [Double](repeating: 0, count: n)
    for e in 0 ..< graph.edgeCount {
        let w = weights?[e] ?? 1
        out[graph.from[e]] += w
        into[graph.to[e]] += w
        if !graph.directed {
            out[graph.to[e]] += w
            into[graph.from[e]] += w
        }
    }
    // Undirected, a and b are one array (NetworkX's `a = b = …`), so merging updates both.
    var a = graph.directed ? out.map { $0 * q0 } : out.map { $0 * q0 * 0.5 }
    var b = graph.directed ? into.map { $0 * q0 } : a
    // Rows: the weight between each pair (loops left out), summed in edge order, sorted by
    // neighbor: a counting sort of both orientations by source, stable in edge order, then each
    // row sorted by neighbor (stable) and merged.
    var start = [Int](repeating: 0, count: n + 1)
    for e in 0 ..< graph.edgeCount where graph.from[e] != graph.to[e] {
        start[graph.from[e] + 1] += 1
        start[graph.to[e] + 1] += 1
    }
    for v in 0 ..< n { start[v + 1] += start[v] }
    var fill = start
    var arcTarget = [Int](repeating: 0, count: start[n]), arcWeight = [Double](repeating: 0, count: start[n])
    for e in 0 ..< graph.edgeCount where graph.from[e] != graph.to[e] {
        let u = graph.from[e], v = graph.to[e], w = weights?[e] ?? 1
        arcTarget[fill[u]] = v
        arcWeight[fill[u]] = w
        fill[u] += 1
        arcTarget[fill[v]] = u
        arcWeight[fill[v]] = w
        fill[v] += 1
    }
    var rows = [_GainRow](repeating: _GainRow(), count: n)
    var heap = _MergeHeap()
    var live = 0
    for u in 0 ..< n {
        let slots = (start[u] ..< start[u + 1]).sorted { arcTarget[$0] != arcTarget[$1] ? arcTarget[$0] < arcTarget[$1] : $0 < $1 }
        var row = _GainRow()
        for slot in slots {
            if row.neighbors.last == arcTarget[slot] {
                row.gains[row.gains.count - 1] += arcWeight[slot]
            } else {
                row.neighbors.append(arcTarget[slot])
                row.gains.append(arcWeight[slot])
            }
        }
        for i in row.neighbors.indices {
            let v = row.neighbors[i]
            row.gains[i] = q0 * row.gains[i] - gamma * (a[u] * b[v] + b[u] * a[v])
            if u < v {
                heap.push(_Merge(gain: row.gains[i], u: u, v: v))
                live += 1
            }
        }
        rows[u] = row
    }
    var parent = Array(0 ..< n)
    var merged = _GainRow()
    while let top = heap.pop() {
        let u = top.u, v = top.v
        guard let current = rows[u].gain(to: v), current == top.gain else { continue }
        if current < 0 { break }
        let au = a[u], bu = graph.directed ? b[u] : a[u], av = a[v], bv = graph.directed ? b[v] : a[v]
        // The merged row of v: both rows walked in neighbor order, u and v left out.
        let rowU = rows[u], rowV = rows[v]
        merged.neighbors.removeAll(keepingCapacity: true)
        merged.gains.removeAll(keepingCapacity: true)
        var i = 0, j = 0
        while i < rowU.neighbors.count || j < rowV.neighbors.count {
            let x = i < rowU.neighbors.count ? rowU.neighbors[i] : Int.max
            let y = j < rowV.neighbors.count ? rowV.neighbors[j] : Int.max
            let z = min(x, y)
            let d: Double
            if x == y {
                d = rowV.gains[j] + rowU.gains[i]
                i += 1
                j += 1
            } else if y < x {
                let az = a[z], bz = graph.directed ? b[z] : a[z]
                d = rowV.gains[j] - gamma * (au * bz + az * bu)
                j += 1
            } else {
                let az = a[z], bz = graph.directed ? b[z] : a[z]
                d = rowU.gains[i] - gamma * (av * bz + az * bv)
                i += 1
            }
            if z == u || z == v { continue }
            merged.neighbors.append(z)
            merged.gains.append(d)
        }
        // Pairs that disappear: u with each of its neighbors (v among them).
        live -= rowU.neighbors.count
        live -= rowV.neighbors.count - 1
        for (k, x) in merged.neighbors.enumerated() {
            let d = merged.gains[k]
            rows[x].remove(u)
            rows[x].set(v, d)
            heap.push(_Merge(gain: d, u: min(v, x), v: max(v, x)))
            live += 1
        }
        rows[u] = _GainRow()
        swap(&rows[v], &merged)
        parent[u] = v
        a[v] += a[u]
        a[u] = 0
        if graph.directed {
            b[v] += b[u]
            b[u] = 0
        }
        // Stale entries outnumber live ones: rebuild the heap from the rows.
        if heap.items.count > 2 * live + 1024 {
            heap.items.removeAll(keepingCapacity: true)
            for x in 0 ..< n {
                for (k, y) in rows[x].neighbors.enumerated() where x < y {
                    heap.push(_Merge(gain: rows[x].gains[k], u: x, v: y))
                }
            }
        }
    }
    // Each vertex's community: follow the merges to the surviving community.
    var label = [Int](repeating: 0, count: n)
    for y in 0 ..< n {
        var r = y
        while parent[r] != r { r = parent[r] }
        var x = y
        while parent[x] != r {
            let up = parent[x]
            parent[x] = r
            x = up
        }
        label[y] = r
    }
    return label
}

extension Graph {
    @inlinable
    func _greedyModularityCommunities(_ weights: [Double]?, resolution: Double) -> Partition<DirectedView<Self>> {
        _checkResolution(resolution)
        let listed = _listedVertices()
        let numbers = listed.map(CommunityDetection._communityNumbers)
        let labels = _greedyModularity(_communityGraph(), weights, resolution: resolution)
        return Partition(directed, numbers: numbers, listed: listed, labels: labels)
    }

    /// Greedy modularity communities (Clauset, Newman and Moore; NetworkX
    /// `greedy_modularity_communities`): from singletons, repeatedly merge the two adjacent
    /// communities whose merge raises modularity most (ties to the least pair of vertex numbers),
    /// while it does not lower it. Deterministic. O(m d log n), d the depth of the merge tree.
    ///
    /// - Precondition: `resolution` is finite and at least zero.
    @inlinable
    public func greedyModularityCommunities(resolution: Double = 1) -> Partition<DirectedView<Self>> {
        _greedyModularityCommunities(nil, resolution: resolution)
    }

    /// Weighted greedy modularity communities; `weight` is called once per edge, in position order.
    ///
    /// - Precondition: every weight is finite and at least zero; `resolution` is finite and at
    ///   least zero.
    @inlinable
    public func greedyModularityCommunities<W: BinaryFloatingPoint>(weight: (Edges.Index) -> W, resolution: Double = 1) -> Partition<DirectedView<Self>> {
        _greedyModularityCommunities(_communityWeights(weight), resolution: resolution)
    }
}

extension DirectedGraph {
    @inlinable
    func _greedyModularityCommunities(_ weights: [Double]?, resolution: Double) -> Partition<Self> {
        _checkResolution(resolution)
        let listed = _listedVertices()
        let numbers = listed.map(CommunityDetection._communityNumbers)
        let labels = _greedyModularity(_communityGraph(numbers), weights, resolution: resolution)
        return Partition(self, numbers: numbers, listed: listed, labels: labels)
    }

    /// Greedy modularity communities maximizing directed modularity (NetworkX
    /// `greedy_modularity_communities`). Deterministic.
    ///
    /// - Precondition: `resolution` is finite and at least zero.
    @inlinable
    public func greedyModularityCommunities(resolution: Double = 1) -> Partition<Self> {
        _greedyModularityCommunities(nil, resolution: resolution)
    }

    /// Weighted greedy modularity communities over arcs; `weight` is called once per edge, in
    /// position order.
    ///
    /// - Precondition: every weight is finite and at least zero; `resolution` is finite and at
    ///   least zero.
    @inlinable
    public func greedyModularityCommunities<W: BinaryFloatingPoint>(weight: (Edges.Index) -> W, resolution: Double = 1) -> Partition<Self> {
        _greedyModularityCommunities(_communityWeights(weight), resolution: resolution)
    }
}
