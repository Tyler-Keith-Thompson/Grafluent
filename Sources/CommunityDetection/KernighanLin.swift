import GraphProtocols

/// An undirected graph's neighbor rows with repeats merged: row v lists each other vertex adjacent
/// to v once, where it first appears in v's `incidentEdges` row, with the summed weight of the
/// edges between them. Self-loops are left out.
@frozen
@usableFromInline
struct _MergedRows {
    @usableFromInline var offsets: [Int]
    @usableFromInline var neighbors: [Int]
    @usableFromInline var weights: [Double]

    @inlinable
    init(_ rows: _CompressedRows, _ edgeWeights: [Double]?) {
        let n = rows.count
        offsets = [Int](repeating: 0, count: n + 1)
        neighbors = []
        weights = []
        neighbors.reserveCapacity(rows.targets.count)
        weights.reserveCapacity(rows.targets.count)
        var slotOf = [Int](repeating: -1, count: n)
        var owner = [Int](repeating: -1, count: n)
        for v in 0 ..< n {
            for slot in rows.offsets[v] ..< rows.offsets[v + 1] {
                let w = rows.targets[slot]
                if w == v { continue }
                let x = edgeWeights.map { $0[rows.edges[slot]] } ?? 1
                if owner[w] == v {
                    weights[slotOf[w]] += x
                } else {
                    owner[w] = v
                    slotOf[w] = neighbors.count
                    neighbors.append(w)
                    weights.append(x)
                }
            }
            offsets[v + 1] = neighbors.count
        }
    }

    @inlinable
    var count: Int { offsets.count - 1 }
}

extension Graph {
    /// The merged rows, weights read once per edge in position order.
    @inlinable
    func _mergedRows(_ weights: [Double]?) -> _MergedRows {
        _MergedRows(_runOnUndirectedRows(_CopyRows(readsEdges: weights != nil, dropsLoops: true)), weights)
    }
}

/// A binary min-heap of (value, stamp, vertex) entries with lazy deletion: an entry is current
/// while its vertex is in the heap and its value is the vertex's value; ties go to the lesser stamp
/// (the order of insertion).
@frozen
@usableFromInline
struct _StampedHeap {
    @usableFromInline var values: [Double] = []
    @usableFromInline var stamps: [Int] = []
    @usableFromInline var vertices: [Int] = []
    @usableFromInline var current: [Double]
    @usableFromInline var present: [Bool]
    @usableFromInline var stamp = 0
    @usableFromInline var count = 0

    @inlinable
    init(count n: Int) {
        current = [Double](repeating: 0, count: n)
        present = [Bool](repeating: false, count: n)
    }

    @inlinable
    func less(_ i: Int, _ j: Int) -> Bool {
        values[i] < values[j] || (values[i] == values[j] && stamps[i] < stamps[j])
    }

    @inlinable
    mutating func push(_ v: Int, _ value: Double) {
        if !present[v] {
            present[v] = true
            count += 1
        }
        current[v] = value
        values.append(value)
        stamps.append(stamp)
        vertices.append(v)
        stamp += 1
        var i = values.count - 1
        while i > 0 {
            let parent = (i - 1) / 2
            guard less(i, parent) else { break }
            swapEntries(i, parent)
            i = parent
        }
    }

    @inlinable
    mutating func swapEntries(_ i: Int, _ j: Int) {
        values.swapAt(i, j)
        stamps.swapAt(i, j)
        vertices.swapAt(i, j)
    }

    @inlinable
    mutating func removeTop() {
        let last = values.count - 1
        swapEntries(0, last)
        values.removeLast()
        stamps.removeLast()
        vertices.removeLast()
        var i = 0
        let size = values.count
        while true {
            let l = 2 * i + 1, r = l + 1
            var smallest = i
            if l < size, less(l, smallest) { smallest = l }
            if r < size, less(r, smallest) { smallest = r }
            if smallest == i { break }
            swapEntries(i, smallest)
            i = smallest
        }
    }

    /// The current entry of least value (then stamp), removed with its vertex.
    @inlinable
    mutating func pop() -> (vertex: Int, value: Double) {
        while true {
            let v = vertices[0], value = values[0]
            removeTop()
            if present[v], current[v] == value {
                present[v] = false
                count -= 1
                return (v, value)
            }
        }
    }

    /// Changes a present vertex's value by pushing a new entry, unless it is unchanged.
    @inlinable
    mutating func update(_ v: Int, _ value: Double) {
        if value != current[v] { push(v, value) }
    }
}

/// Kernighan–Lin bisection in the form of NetworkX's `kernighan_lin_bisection`: each pass moves
/// vertices one at a time, alternating between the sides (side 0 first) to keep the sizes, each
/// time the vertex whose move (with the moves before it) gains the most cut weight, then applies the
/// shortest prefix of pairs of least total cost if that cost is below zero, and otherwise stops.
/// `side` holds 0 or 1 per vertex and is updated in place.
@inlinable
func _kernighanLin(_ rows: _MergedRows, side: inout [Int], iterations: Int) {
    let n = rows.count
    var costs: [Double] = []
    var swaps: [(Int, Int)] = []
    for _ in 0 ..< iterations {
        // Each vertex's cost: weight to its own side minus weight to the other side.
        var heaps = [_StampedHeap(count: n), _StampedHeap(count: n)]
        for u in 0 ..< n {
            var cost = 0.0
            for slot in rows.offsets[u] ..< rows.offsets[u + 1] {
                cost += side[rows.neighbors[slot]] == side[u] ? rows.weights[slot] : -rows.weights[slot]
            }
            heaps[side[u]].push(u, cost)
        }
        costs.removeAll(keepingCapacity: true)
        swaps.removeAll(keepingCapacity: true)
        var total = 0.0
        while heaps[0].count > 0, heaps[1].count > 0 {
            var pair = (0, 0)
            for s in 0 ..< 2 {
                let (u, cost) = heaps[s].pop()
                total += cost
                if s == 0 { pair.0 = u } else { pair.1 = u }
                // u leaves its side: its own side's vertices lose an inside neighbor, the other
                // side's gain one.
                for slot in rows.offsets[u] ..< rows.offsets[u + 1] {
                    let w = rows.neighbors[slot]
                    let t = side[w]
                    guard heaps[t].present[w] else { continue }
                    let x = t == side[u] ? -rows.weights[slot] : rows.weights[slot]
                    heaps[t].update(w, heaps[t].current[w] + 2 * x)
                }
            }
            costs.append(total)
            swaps.append(pair)
        }
        guard var best = costs.first else { break }
        var length = 1
        for (i, cost) in costs.enumerated() where cost < best {
            best = cost
            length = i + 1
        }
        if best >= 0 { break }
        for (u, v) in swaps.prefix(length) {
            side[u] = 1
            side[v] = 0
        }
    }
}

@inlinable
func _checkKernighanLin(iterations: Int) {
    precondition(iterations >= 0, "The number of iterations must be at least zero")
}

extension Graph {
    @inlinable
    func _kernighanLinBisection(_ weights: [Double]?, side: [Int], iterations: Int) -> Partition<DirectedView<Self>> {
        let listed = _listedVertices()
        let numbers = listed.map(_vertexNumbers)
        var side = side
        _kernighanLin(_mergedRows(weights), side: &side, iterations: iterations)
        // Labels must be vertex numbers: one vertex is label 0 whatever its side.
        return Partition(directedView, numbers: numbers, listed: listed, labels: side.count < 2 ? [Int](repeating: 0, count: side.count) : side)
    }

    /// The sides of `communities`, which must be two: 1 for the first's vertices, 0 for the second's.
    @inlinable
    func _bisectionSides<C: Collection>(_ communities: C) -> [Int] where C.Element: Collection, C.Element.Element == Vertex {
        precondition(communities.count == 2, "A bisection starts from exactly two communities")
        let numbers = _communityNumbers()
        let (labels, _) = _membership(communities, count: vertexCount) { _communityNumber(of: $0, numbers) }
        return labels.map { 1 - $0 }
    }

    /// The sides of a random balanced split: `vertices` shuffled by `generator` as Louvain's orders
    /// are, the first ⌊n/2⌋ on one side.
    @inlinable
    func _randomBisection<R: RandomNumberGenerator>(using generator: inout R) -> [Int] {
        let n = vertexCount
        var side = [Int](repeating: 0, count: n)
        for v in _shuffledOrder(n, &generator).prefix(n / 2) { side[v] = 1 }
        return side
    }

    /// Kernighan–Lin bisection (Kernighan and Lin 1970) from a random balanced split, lowering the
    /// number of edges between the two halves: each pass moves the vertex of greatest gain from
    /// alternate sides (a tie to the vertex whose cost changed least recently, then the lesser
    /// vertex number), each vertex once, and keeps the best prefix of moved pairs while it cuts
    /// fewer edges. Parallel edges add; self-loops never matter. The sizes of the two halves differ
    /// by at most one.
    ///
    /// - Parameters:
    ///   - iterations: at most this many passes; a pass that lowers nothing stops early.
    ///   - generator: shuffles the vertices for the starting split: the first ⌊n/2⌋ of the shuffled
    ///     vertex numbers form one half.
    /// - Returns: the halves, in canonical order (one community when n ≤ 1, none when n = 0).
    /// - Complexity: O(m log m) per pass.
    /// - Precondition: `iterations` is at least zero.
    @inlinable
    public func kernighanLinBisection(iterations: Int = 10, using generator: inout some RandomNumberGenerator) -> Partition<DirectedView<Self>> {
        _checkKernighanLin(iterations: iterations)
        return _kernighanLinBisection(nil, side: _randomBisection(using: &generator), iterations: iterations)
    }

    /// Kernighan–Lin bisection from a random balanced split drawn from the system's generator.
    ///
    /// - Precondition: `iterations` is at least zero.
    @inlinable
    public func kernighanLinBisection(iterations: Int = 10) -> Partition<DirectedView<Self>> {
        var generator = SystemRandomNumberGenerator()
        return kernighanLinBisection(iterations: iterations, using: &generator)
    }

    /// Kernighan–Lin bisection from the two communities given, whose sizes it keeps. Deterministic.
    ///
    /// - Precondition: `communities` is two collections that list every vertex exactly once;
    ///   `iterations` is at least zero.
    @inlinable
    public func kernighanLinBisection<C: Collection>(startingFrom communities: C, iterations: Int = 10) -> Partition<DirectedView<Self>> where C.Element: Collection, C.Element.Element == Vertex {
        let side = _bisectionSides(communities)
        _checkKernighanLin(iterations: iterations)
        return _kernighanLinBisection(nil, side: side, iterations: iterations)
    }

    /// Weighted Kernighan–Lin bisection from a random balanced split, lowering the weight of the
    /// edges between the halves; `weight` is called once per edge, in position order.
    ///
    /// - Precondition: every weight is finite and at least zero; `iterations` is at least zero.
    @inlinable
    public func kernighanLinBisection<W: BinaryFloatingPoint>(weight: (Edges.Index) -> W, iterations: Int = 10, using generator: inout some RandomNumberGenerator) -> Partition<DirectedView<Self>> {
        let weights = _communityWeights(weight)
        _checkKernighanLin(iterations: iterations)
        return _kernighanLinBisection(weights, side: _randomBisection(using: &generator), iterations: iterations)
    }

    /// Weighted Kernighan–Lin bisection from the two communities given.
    ///
    /// - Precondition: `communities` is two collections that list every vertex exactly once;
    ///   every weight is finite and at least zero; `iterations` is at least zero.
    @inlinable
    public func kernighanLinBisection<C: Collection, W: BinaryFloatingPoint>(startingFrom communities: C, weight: (Edges.Index) -> W, iterations: Int = 10) -> Partition<DirectedView<Self>> where C.Element: Collection, C.Element.Element == Vertex {
        let side = _bisectionSides(communities)
        let weights = _communityWeights(weight)
        _checkKernighanLin(iterations: iterations)
        return _kernighanLinBisection(weights, side: side, iterations: iterations)
    }
}
