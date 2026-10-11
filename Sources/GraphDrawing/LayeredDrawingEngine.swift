import Cycles

/// A layered drawing in index space: vertex numbers `0..<n`, arc `k` from `sources[k]` to
/// `targets[k]`.
@usableFromInline
struct _LayeredResult: Sendable {
    @usableFromInline var layer: [Int]
    @usableFromInline var layerCount: Int
    @usableFromInline var positions: [SIMD2<Double>]
    /// Arc `k`'s bends are `bends[bendStart[k] ..< bendStart[k + 1]]`, from its source to its
    /// target.
    @usableFromInline var bendStart: [Int]
    @usableFromInline var bends: [SIMD2<Double>]
    @usableFromInline var reversed: [Int]
    @usableFromInline var crossings: Int
}

/// The Sugiyama pipeline (api.md, Semantics: Layered): cycle removal by Eades–Lin–Smyth (or the
/// caller's layers), minimum-span layering by network simplex, one dummy vertex per inner layer
/// of a long edge, barycenter crossing reduction keeping the best order seen, Brandes–Köpf
/// coordinates with longest-path compaction.
@usableFromInline
func _layeredDrawing(vertexCount n: Int, sources: [Int], targets: [Int], layers given: [Int]?, maxIterations: Int) -> _LayeredResult {
    let m = sources.count
    // Orient every arc downward: (upper, lower), or (−1, −1) for an arc with no segment.
    var upper = [Int](repeating: -1, count: m), lower = [Int](repeating: -1, count: m)
    var isReversed = [Bool](repeating: false, count: m)
    var reversed: [Int] = []
    // The layers the engine works on are dense: `layer` numbers the non-empty layers 0, 1, …,
    // and `layerValue[l]` is the y (and the reported layer) of layer l. Caller layers with empty
    // layers between them are compressed, so memory does not grow with the layer numbers; a long
    // edge gets a bend only on the non-empty layers it crosses.
    let layer: [Int]
    var layerValue: [Int] = []
    if let given {
        var distinct = given
        distinct.sort()
        for l in distinct where layerValue.last != l { layerValue.append(l) }
        var dense = given
        for v in 0 ..< n {
            // The rank of the vertex's layer among the distinct ones.
            var lo = 0, hi = layerValue.count - 1
            while lo < hi {
                let mid = (lo + hi) / 2
                if layerValue[mid] < given[v] { lo = mid + 1 } else { hi = mid }
            }
            dense[v] = lo
        }
        layer = dense
        for k in 0 ..< m {
            let s = sources[k], t = targets[k]
            guard s != t, layer[s] != layer[t] else { continue }
            if layer[s] < layer[t] {
                (upper[k], lower[k]) = (s, t)
            } else {
                (upper[k], lower[k]) = (t, s)
                isReversed[k] = true
                reversed.append(k)
            }
        }
    } else {
        reversed = _eadesLinSmythReversedArcs(vertexCount: n, sources: sources, targets: targets)
        for k in reversed { isReversed[k] = true }
        var tails: [Int] = [], heads: [Int] = []
        tails.reserveCapacity(m)
        heads.reserveCapacity(m)
        for k in 0 ..< m where sources[k] != targets[k] {
            let (a, b) = isReversed[k] ? (targets[k], sources[k]) : (sources[k], targets[k])
            tails.append(a)
            heads.append(b)
        }
        layer = _minimumSpanLayers(vertexCount: n, tails: tails, heads: heads)
        for k in 0 ..< m where sources[k] != targets[k] {
            (upper[k], lower[k]) = isReversed[k] ? (targets[k], sources[k]) : (sources[k], targets[k])
        }
    }
    var layerCount = 0
    for l in layer { layerCount = Swift.max(layerCount, l + 1) }
    if given == nil { layerValue = Array(0 ..< layerCount) }

    // Dummies: arc k's are numbered dummyStart[k] ..< dummyStart[k + 1], one per inner layer, top
    // down. Nodes are the vertices, then the dummies.
    var dummyStart = [Int](repeating: n, count: m + 1)
    for k in 0 ..< m {
        let inner = upper[k] < 0 ? 0 : layer[lower[k]] - layer[upper[k]] - 1
        dummyStart[k + 1] = dummyStart[k] + inner
    }
    let nodeCount = dummyStart[m]
    var nodeLayer = layer
    nodeLayer.reserveCapacity(nodeCount)
    for k in 0 ..< m {
        for i in 0 ..< dummyStart[k + 1] - dummyStart[k] { nodeLayer.append(layer[upper[k]] + 1 + i) }
    }
    // Segments between adjacent layers, as rows of lower and of upper neighbours, in arc order.
    var downStart = [Int](repeating: 0, count: nodeCount + 1), upStart = [Int](repeating: 0, count: nodeCount + 1)
    func chain(_ k: Int, _ body: (Int, Int) -> Void) {
        var a = upper[k]
        for d in dummyStart[k] ..< dummyStart[k + 1] {
            body(a, d)
            a = d
        }
        body(a, lower[k])
    }
    for k in 0 ..< m where upper[k] >= 0 {
        chain(k) { a, b in
            downStart[a + 1] += 1
            upStart[b + 1] += 1
        }
    }
    for x in 0 ..< nodeCount {
        downStart[x + 1] += downStart[x]
        upStart[x + 1] += upStart[x]
    }
    var down = [Int](repeating: 0, count: downStart[nodeCount]), up = [Int](repeating: 0, count: upStart[nodeCount])
    do {
        var downFill = downStart, upFill = upStart
        for k in 0 ..< m where upper[k] >= 0 {
            chain(k) { a, b in
                down[downFill[a]] = b
                downFill[a] += 1
                up[upFill[b]] = a
                upFill[b] += 1
            }
        }
    }

    // The initial order: each layer's vertices in vertex order, then its dummies by arc.
    var layerStart = [Int](repeating: 0, count: layerCount + 1)
    for x in 0 ..< nodeCount { layerStart[nodeLayer[x] + 1] += 1 }
    for l in 0 ..< layerCount { layerStart[l + 1] += layerStart[l] }
    var order = [Int](repeating: 0, count: nodeCount)
    var position = [Int](repeating: 0, count: nodeCount)
    do {
        var fill = layerStart
        for x in 0 ..< nodeCount {
            let l = nodeLayer[x]
            position[x] = fill[l] - layerStart[l]
            order[fill[l]] = x
            fill[l] += 1
        }
    }
    var graph = _LayerGraph(layerStart: layerStart, downStart: downStart, down: down, upStart: upStart, up: up, vertexCount: n)
    let crossings = graph.reduceCrossings(&order, &position, maxIterations: maxIterations)
    let x = graph.brandesKopf(order, position)

    var positions = [SIMD2<Double>](repeating: .zero, count: n)
    for v in 0 ..< n { positions[v] = SIMD2(x[v], Double(layerValue[layer[v]])) }
    var bendStart = [Int](repeating: 0, count: m + 1)
    var bends: [SIMD2<Double>] = []
    bends.reserveCapacity(nodeCount - n)
    for k in 0 ..< m {
        let range = dummyStart[k] ..< dummyStart[k + 1]
        if isReversed[k] {
            for d in range.reversed() { bends.append(SIMD2(x[d], Double(layerValue[nodeLayer[d]]))) }
        } else {
            for d in range { bends.append(SIMD2(x[d], Double(layerValue[nodeLayer[d]]))) }
        }
        bendStart[k + 1] = bends.count
    }
    if let given {
        return _LayeredResult(
            layer: given, layerCount: (layerValue.last ?? -1) + 1, positions: positions, bendStart: bendStart, bends: bends, reversed: reversed,
            crossings: crossings)
    }
    return _LayeredResult(layer: layer, layerCount: layerCount, positions: positions, bendStart: bendStart, bends: bends, reversed: reversed, crossings: crossings)
}

/// The proper layered graph (vertices and dummies, segments only between adjacent layers) that
/// crossing reduction and coordinate assignment work on.
struct _LayerGraph {
    let layerStart: [Int]
    let downStart: [Int]
    let down: [Int]
    let upStart: [Int]
    let up: [Int]
    /// Nodes below this number are vertices; the rest are dummies.
    let vertexCount: Int
    var keys: [(Double, Int)] = []
    var buffer: [Int] = []
    var tree: [Int] = []

    init(layerStart: [Int], downStart: [Int], down: [Int], upStart: [Int], up: [Int], vertexCount: Int) {
        self.layerStart = layerStart
        self.downStart = downStart
        self.down = down
        self.upStart = upStart
        self.up = up
        self.vertexCount = vertexCount
    }

    var layerCount: Int { layerStart.count - 1 }

    // MARK: Crossing reduction

    /// Barycenter sweeps (down, then up) until there are no crossings, a sweep changes nothing, or
    /// `maxIterations` sweeps; leaves the order with the fewest crossings seen (the first such)
    /// in `order` and `position`, and returns its crossing count.
    mutating func reduceCrossings(_ order: inout [Int], _ position: inout [Int], maxIterations: Int) -> Int {
        var best = crossings(order, position)
        var bestOrder = order
        var iteration = 0
        while iteration < maxIterations, best > 0 {
            iteration += 1
            var changed = false
            for l in stride(from: 1, to: layerCount, by: 1) {
                if sortLayer(l, &order, &position, start: upStart, neighbors: up) { changed = true }
            }
            for l in stride(from: layerCount - 2, through: 0, by: -1) {
                if sortLayer(l, &order, &position, start: downStart, neighbors: down) { changed = true }
            }
            let c = crossings(order, position)
            if c < best {
                best = c
                bestOrder = order
            }
            if !changed { break }
        }
        order = bestOrder
        for l in 0 ..< layerCount {
            for i in layerStart[l] ..< layerStart[l + 1] { position[order[i]] = i - layerStart[l] }
        }
        return best
    }

    /// Sorts layer `l` by the mean position of each node's neighbours in the adjacent layer (its
    /// own position when it has none), stably; returns whether the order changed.
    mutating func sortLayer(_ l: Int, _ order: inout [Int], _ position: inout [Int], start: [Int], neighbors: [Int]) -> Bool {
        let s = layerStart[l], e = layerStart[l + 1]
        keys.removeAll(keepingCapacity: true)
        for i in s ..< e {
            let x = order[i]
            let a = start[x], b = start[x + 1]
            if a == b {
                keys.append((Double(i - s), i - s))
            } else {
                var sum = 0
                for slot in a ..< b { sum += position[neighbors[slot]] }
                keys.append((Double(sum) / Double(b - a), i - s))
            }
        }
        keys.sort { $0.0 < $1.0 || ($0.0 == $1.0 && $0.1 < $1.1) }
        var changed = false
        buffer.removeAll(keepingCapacity: true)
        for i in s ..< e { buffer.append(order[i]) }
        for (i, key) in keys.enumerated() {
            if key.1 != i { changed = true }
            let x = buffer[key.1]
            order[s + i] = x
            position[x] = i
        }
        return changed
    }

    /// The number of pairs of segments between adjacent layers whose ends are in opposite
    /// orders, by Barth, Jünger and Mutzel's accumulator tree (a Fenwick tree here) per layer
    /// pair: O(M log N).
    mutating func crossings(_ order: [Int], _ position: [Int]) -> Int {
        var total = 0
        for l in stride(from: 0, to: layerCount - 1, by: 1) {
            let width = layerStart[l + 2] - layerStart[l + 1]
            if tree.count < width + 1 { tree = [Int](repeating: 0, count: width + 1) }
            for i in 0 ... width { tree[i] = 0 }
            var seen = 0
            for i in layerStart[l] ..< layerStart[l + 1] {
                let x = order[i]
                // This node's segments cross the earlier nodes' segments that end strictly to the
                // right; they do not cross each other, so all are counted before any is added and
                // no sort is needed.
                for slot in downStart[x] ..< downStart[x + 1] {
                    // Earlier segments ending at most p.
                    var atMost = 0, k = position[down[slot]] + 1
                    while k > 0 {
                        atMost += tree[k]
                        k -= k & -k
                    }
                    total += seen - atMost
                }
                for slot in downStart[x] ..< downStart[x + 1] {
                    var k = position[down[slot]] + 1
                    while k <= width {
                        tree[k] += 1
                        k += k & -k
                    }
                }
                seen += downStart[x + 1] - downStart[x]
            }
        }
        return total
    }

    // MARK: Coordinates

    /// Brandes and Köpf's horizontal coordinates for every node, least x 0.
    mutating func brandesKopf(_ order: [Int], _ position: [Int]) -> [Double] {
        let nodeCount = position.count
        guard nodeCount > 0 else { return [] }
        let marked = typeOneConflicts(order, position)
        // Every node's upper and lower neighbours by position, by one pass over the layers in
        // order (a sort per node would be O(d log d), an insertion sort O(d²) on a hub).
        var sortedUp = [Int](repeating: 0, count: up.count), sortedDown = [Int](repeating: 0, count: down.count)
        do {
            var upFill = upStart, downFill = downStart
            for u in order {
                for slot in downStart[u] ..< downStart[u + 1] {
                    let v = down[slot]
                    sortedUp[upFill[v]] = u
                    upFill[v] += 1
                }
                for slot in upStart[u] ..< upStart[u + 1] {
                    let v = up[slot]
                    sortedDown[downFill[v]] = u
                    downFill[v] += 1
                }
            }
        }
        var results: [[Int]] = []
        results.reserveCapacity(4)
        var root = [Int](repeating: 0, count: nodeCount), align = [Int](repeating: 0, count: nodeCount)
        var place = [Int](repeating: 0, count: nodeCount)
        for upward in [true, false] {
            for leftward in [true, false] {
                results.append(
                    alignAndCompact(
                        order, position, sorted: upward ? sortedUp : sortedDown, marked: marked, upward: upward, leftward: leftward, &root, &align,
                        &place))
            }
        }
        var widths: [Int] = []
        var lows: [Int] = [], highs: [Int] = []
        for r in results {
            var lo = Int.max, hi = Int.min
            for v in r {
                lo = Swift.min(lo, v)
                hi = Swift.max(hi, v)
            }
            lows.append(lo)
            highs.append(hi)
            widths.append(hi - lo)
        }
        var narrowest = 0
        for i in 1 ..< 4 where widths[i] < widths[narrowest] { narrowest = i }
        // Align to the narrowest: left alignments by their minimum, right ones by their maximum.
        var shift = [Int](repeating: 0, count: 4)
        for i in 0 ..< 4 { shift[i] = i % 2 == 0 ? lows[narrowest] - lows[i] : highs[narrowest] - highs[i] }
        var x = [Double](repeating: 0, count: nodeCount)
        var least = Double.infinity
        for v in 0 ..< nodeCount {
            var a = results[0][v] + shift[0], b = results[1][v] + shift[1], c = results[2][v] + shift[2], d = results[3][v] + shift[3]
            // The two middle values of four.
            if a > b { swap(&a, &b) }
            if c > d { swap(&c, &d) }
            let second = Swift.max(a, c), third = Swift.min(b, d)
            x[v] = Double(second + third) / 2
            least = Swift.min(least, x[v])
        }
        for v in 0 ..< nodeCount { x[v] -= least }
        return x
    }

    /// The segments (upper, lower) marked as type-1 conflicts: a segment that is not inner (both
    /// ends dummies) crossing an inner one. Keys are upper · N + lower.
    func typeOneConflicts(_ order: [Int], _ position: [Int]) -> Set<Int> {
        let nodeCount = position.count
        var marked = Set<Int>()
        for l in stride(from: 1, to: layerCount, by: 1) {
            let upperWidth = layerStart[l] - layerStart[l - 1]
            let s = layerStart[l], e = layerStart[l + 1]
            var k0 = 0, start = s
            for i in s ..< e {
                let v = order[i]
                // The upper end of v's inner segment, if v is a dummy below a dummy.
                var innerUpper = -1
                if v >= vertexCount {
                    for slot in upStart[v] ..< upStart[v + 1] where up[slot] >= vertexCount {
                        innerUpper = up[slot]
                        break
                    }
                }
                guard i == e - 1 || innerUpper >= 0 else { continue }
                let k1 = innerUpper >= 0 ? position[innerUpper] : upperWidth - 1
                for j in start ... i {
                    let w = order[j]
                    for slot in upStart[w] ..< upStart[w + 1] {
                        let u = up[slot]
                        let k = position[u]
                        if (k < k0 || k > k1) && !(u >= vertexCount && w >= vertexCount) { marked.insert(u * nodeCount + w) }
                    }
                }
                start = i + 1
                k0 = k1
            }
        }
        return marked
    }

    /// One of the four vertical alignments and its compaction: x per node (negated for the
    /// rightward ones, so every result reads left to right).
    mutating func alignAndCompact(
        _ order: [Int], _ position: [Int], sorted neighbors: [Int], marked: Set<Int>, upward: Bool, leftward: Bool,
        _ root: inout [Int], _ align: inout [Int], _ place: inout [Int]
    ) -> [Int] {
        let nodeCount = position.count
        let layers = layerCount
        // The position of a node in this direction's horizontal order.
        @inline(__always) func p(_ x: Int, _ width: Int) -> Int { leftward ? x : width - 1 - x }
        for x in 0 ..< nodeCount {
            root[x] = x
            align[x] = x
        }
        let start = upward ? upStart : downStart
        for step in 1 ..< Swift.max(layers, 1) {
            let l = upward ? step : layers - 1 - step
            let adjacent = upward ? l - 1 : l + 1
            let adjacentWidth = layerStart[adjacent + 1] - layerStart[adjacent]
            let s = layerStart[l], e = layerStart[l + 1]
            var r = -1
            for t in 0 ..< e - s {
                let v = order[leftward ? s + t : e - 1 - t]
                let a = start[v], b = start[v + 1]
                guard a < b else { continue }
                let d = b - a
                // The median, or the two medians (left first in this direction) of an even count;
                // `neighbors` rows ascend by position, so the rightward directions read them back
                // to front.
                for mi in (d - 1) / 2 ... d / 2 {
                    guard align[v] == v else { break }
                    let u = neighbors[leftward ? a + mi : b - 1 - mi]
                    let key = upward ? u * nodeCount + v : v * nodeCount + u
                    let pu = p(position[u], adjacentWidth)
                    if !marked.contains(key) && r < pu {
                        align[u] = v
                        root[v] = root[u]
                        align[v] = root[v]
                        r = pu
                    }
                }
            }
        }
        // Compaction: blocks (sets with one root) as a graph, an edge from the block of each node
        // to the block of the node right after it in its layer; x of a block is its longest
        // path from a block with no predecessor, at separation 1.
        var indegree = [Int](repeating: 0, count: nodeCount)
        var succStart = [Int](repeating: 0, count: nodeCount + 1)
        for l in 0 ..< layers {
            let s = layerStart[l], e = layerStart[l + 1]
            guard e - s > 1 else { continue }
            for t in 0 ..< e - s - 1 {
                let a = order[leftward ? s + t : e - 1 - t], b = order[leftward ? s + t + 1 : e - 2 - t]
                succStart[root[a] + 1] += 1
                indegree[root[b]] += 1
            }
        }
        for x in 0 ..< nodeCount { succStart[x + 1] += succStart[x] }
        var succ = [Int](repeating: 0, count: succStart[nodeCount])
        var fill = succStart
        for l in 0 ..< layers {
            let s = layerStart[l], e = layerStart[l + 1]
            guard e - s > 1 else { continue }
            for t in 0 ..< e - s - 1 {
                let a = order[leftward ? s + t : e - 1 - t], b = order[leftward ? s + t + 1 : e - 2 - t]
                succ[fill[root[a]]] = root[b]
                fill[root[a]] += 1
            }
        }
        for x in 0 ..< nodeCount { place[x] = 0 }
        var queue: [Int] = []
        queue.reserveCapacity(nodeCount)
        for x in 0 ..< nodeCount where root[x] == x && indegree[x] == 0 { queue.append(x) }
        var head = 0
        while head < queue.count {
            let block = queue[head]
            head += 1
            for slot in succStart[block] ..< succStart[block + 1] {
                let c = succ[slot]
                place[c] = Swift.max(place[c], place[block] + 1)
                indegree[c] -= 1
                if indegree[c] == 0 { queue.append(c) }
            }
        }
        var xs = [Int](repeating: 0, count: nodeCount)
        for x in 0 ..< nodeCount { xs[x] = leftward ? place[root[x]] : -place[root[x]] }
        return xs
    }
}
