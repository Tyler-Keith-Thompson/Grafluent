/// Rows of a `_IndexGraph` in owned buffers, read by the subgraph search without retains or
/// exclusivity checks.
final class _MatchRows {
    let count: Int
    let isDirected: Bool
    let outOffsets: UnsafeMutablePointer<Int>
    let outTargets: UnsafeMutablePointer<Int>
    let outColors: UnsafeMutablePointer<Int>?
    let inOffsets: UnsafeMutablePointer<Int>
    let inTargets: UnsafeMutablePointer<Int>
    let inColors: UnsafeMutablePointer<Int>?
    let vertexColors: UnsafeMutablePointer<Int>?
    let isSimple: Bool

    init(_ graph: _IndexGraph) {
        count = graph.count
        isDirected = graph.isDirected
        isSimple = graph.isSimple
        func copy(_ array: [Int]) -> UnsafeMutablePointer<Int> {
            let pointer = UnsafeMutablePointer<Int>.allocate(capacity: max(array.count, 1))
            array.withUnsafeBufferPointer { if let base = $0.baseAddress { pointer.update(from: base, count: array.count) } }
            return pointer
        }
        outOffsets = copy(graph.outOffsets)
        outTargets = copy(graph.outTargets)
        outColors = graph.outColors.isEmpty ? nil : copy(graph.outColors)
        if graph.isDirected {
            inOffsets = copy(graph.inOffsets)
            inTargets = copy(graph.inTargets)
            inColors = graph.inColors.isEmpty ? nil : copy(graph.inColors)
        } else {
            inOffsets = outOffsets
            inTargets = outTargets
            inColors = outColors
        }
        vertexColors = graph.vertexColors.isEmpty ? nil : copy(graph.vertexColors)
    }

    deinit {
        outOffsets.deallocate()
        outTargets.deallocate()
        outColors?.deallocate()
        if isDirected {
            inOffsets.deallocate()
            inTargets.deallocate()
            inColors?.deallocate()
        }
        vertexColors?.deallocate()
    }
}

/// The pattern's matching order and each vertex's candidate source, computed once per call
/// (VF2++, Jüttner & Madarasi 2018).
struct _MatchingOrder {
    /// Pattern vertices in matching order.
    var order: [Int]
    /// By depth: an earlier pattern vertex adjacent to `order[d]`, or -1.
    var parent: [Int]
    /// By depth: whether the candidates are the in-neighbours of the parent's image (the arc
    /// runs from `order[d]` to the parent), rather than its out-neighbours.
    var parentInward: [Bool]

    /// Breadth-first from the vertex of rarest colour in the target, then of greatest degree;
    /// within a level, most neighbours already ordered first, then greatest degree, then rarest
    /// colour. Each vertex ordered takes one from its colour's count, as VF2++ does. Repeated for
    /// each component of the pattern.
    init(pattern p: _IndexGraph, targetColorCounts: [Int]) {
        let n = p.count
        var frequency = targetColorCounts
        func color(_ v: Int) -> Int { p.vertexColors.isEmpty ? 0 : p.vertexColors[v] }
        var degree = [Int](repeating: 0, count: n)
        for v in 0 ..< n {
            degree[v] = p.outOffsets[v + 1] - p.outOffsets[v]
            if p.isDirected { degree[v] += p.inOffsets[v + 1] - p.inOffsets[v] }
        }
        var depthOf = [Int](repeating: -1, count: n)
        var connections = [Int](repeating: 0, count: n)
        var seen = [Bool](repeating: false, count: n)
        var order: [Int] = []
        order.reserveCapacity(n)
        var level: [Int] = [], nextLevel: [Int] = []
        func neighbors(_ v: Int, _ body: (Int) -> Void) {
            for k in p.outOffsets[v] ..< p.outOffsets[v + 1] where p.outTargets[k] != v { body(p.outTargets[k]) }
            if p.isDirected { for k in p.inOffsets[v] ..< p.inOffsets[v + 1] where p.inTargets[k] != v { body(p.inTargets[k]) } }
        }
        while order.count < n {
            var root = -1
            for v in 0 ..< n where depthOf[v] < 0 && !seen[v] {
                if root < 0 { root = v; continue }
                let fv = frequency[color(v)], fr = frequency[color(root)]
                if fv < fr || (fv == fr && degree[v] > degree[root]) { root = v }
            }
            level = [root]
            seen[root] = true
            while !level.isEmpty {
                // Order this level.
                var remaining = level
                while !remaining.isEmpty {
                    var best = 0
                    for i in 1 ..< remaining.count {
                        let v = remaining[i], b = remaining[best]
                        if connections[v] != connections[b] {
                            if connections[v] > connections[b] { best = i }
                        } else if degree[v] != degree[b] {
                            if degree[v] > degree[b] { best = i }
                        } else if frequency[color(v)] < frequency[color(b)] {
                            best = i
                        }
                    }
                    let v = remaining.remove(at: best)
                    depthOf[v] = order.count
                    order.append(v)
                    frequency[color(v)] -= 1
                    neighbors(v) { w in connections[w] += 1 }
                }
                nextLevel.removeAll()
                for v in level {
                    neighbors(v) { w in
                        if !seen[w] {
                            seen[w] = true
                            nextLevel.append(w)
                        }
                    }
                }
                swap(&level, &nextLevel)
            }
        }
        var parent = [Int](repeating: -1, count: n)
        var parentInward = [Bool](repeating: false, count: n)
        for d in 0 ..< n {
            let u = order[d]
            var best = -1, inward = false
            // w → u (or an undirected edge): candidates are out-neighbours of w's image; u → w:
            // in-neighbours.
            let (offsets, targets) = p.isDirected ? (p.inOffsets, p.inTargets) : (p.outOffsets, p.outTargets)
            for k in offsets[u] ..< offsets[u + 1] {
                let w = targets[k]
                if depthOf[w] < d && (best < 0 || depthOf[w] < depthOf[best]) { best = w; inward = false }
            }
            if p.isDirected {
                for k in p.outOffsets[u] ..< p.outOffsets[u + 1] {
                    let w = p.outTargets[k]
                    if depthOf[w] < d && (best < 0 || depthOf[w] < depthOf[best]) { best = w; inward = true }
                }
            }
            parent[d] = best
            parentInward[d] = inward
        }
        self.order = order
        self.parent = parent
        self.parentInward = parentInward
    }
}

/// One subgraph problem, immutable and shared by its searches and their copies: both graphs'
/// rows, the matching order, and the target's adjacency as a bit matrix (simple graphs with at
/// most 4,096 target vertices).
final class _SubgraphData {
    let p: _MatchRows
    let t: _MatchRows
    let induced: Bool
    let order: [Int]
    let parent: [Int]
    let parentInward: [Bool]
    let simple: Bool
    let bits: UnsafeMutablePointer<UInt64>?
    let words: Int
    let colorClasses: Int

    init(pattern: _IndexGraph, target: _IndexGraph, induced: Bool) {
        p = _MatchRows(pattern)
        t = _MatchRows(target)
        self.induced = induced
        let classes = max(pattern.vertexColors.max() ?? 0, target.vertexColors.max() ?? 0) + 1
        colorClasses = classes
        var counts = [Int](repeating: 0, count: classes)
        if target.vertexColors.isEmpty {
            counts[0] = target.count
        } else {
            for c in target.vertexColors { counts[c] += 1 }
        }
        let matchingOrder = _MatchingOrder(pattern: pattern, targetColorCounts: counts)
        order = matchingOrder.order
        parent = matchingOrder.parent
        parentInward = matchingOrder.parentInward
        simple = p.isSimple && t.isSimple
        let nt = target.count
        if simple && nt > 0 && nt <= 4096 {
            words = (nt + 63) / 64
            let b = UnsafeMutablePointer<UInt64>.allocate(capacity: nt * words)
            b.initialize(repeating: 0, count: nt * words)
            for x in 0 ..< nt {
                for k in target.outOffsets[x] ..< target.outOffsets[x + 1] {
                    let y = target.outTargets[k]
                    b[x * words + y >> 6] |= 1 << UInt64(y & 63)
                }
            }
            bits = b
        } else {
            words = 0
            bits = nil
        }
    }

    deinit {
        bits?.deallocate()
    }
}

/// Induced subgraph isomorphism or monomorphism by VF2++ (Jüttner & Madarasi 2018), a
/// depth-first search on an explicit stack over VF2's state (Cordella et al. 2004).
///
/// Depth d maps `order[d]`. Its candidates are the neighbours of its parent's image (or every
/// target vertex, for the first vertex of a component). A candidate x for u must be free, of u's
/// colour and at least u's degree in each direction; for every mapped neighbour w of u the edges
/// between x and w's image must equal (induced) or contain (monomorphism) the edges between u and
/// w, as multisets of colours, and the same for self-loops; induced, x must have no other mapped
/// neighbours. The cutting rule: for each colour, x has at least as many free neighbours as u, in
/// each direction. A cancelled task ends the sequence (checked every 4,096 steps).
final class _SubgraphSearch: _MatchingSearch {
    let data: _SubgraphData
    let p: _MatchRows
    let t: _MatchRows
    let induced: Bool
    let order: [Int]
    let parent: [Int]
    let parentInward: [Bool]
    let simple: Bool
    let bits: UnsafeMutablePointer<UInt64>?
    let words: Int
    let colorClasses: Int
    // Search state.
    let core1: UnsafeMutablePointer<Int>
    let core2: UnsafeMutablePointer<Int>
    let cursor: UnsafeMutablePointer<Int>
    let end: UnsafeMutablePointer<Int>
    let balance: UnsafeMutablePointer<Int>
    var depth = 0
    var started = false
    var finished = false
    var steps = 0

    init(_ data: _SubgraphData) {
        self.data = data
        p = data.p
        t = data.t
        induced = data.induced
        order = data.order
        parent = data.parent
        parentInward = data.parentInward
        simple = data.simple
        bits = data.bits
        words = data.words
        colorClasses = data.colorClasses
        let np = max(p.count, 1), nt = max(t.count, 1)
        core1 = .allocate(capacity: np)
        core1.initialize(repeating: -1, count: np)
        core2 = .allocate(capacity: nt)
        core2.initialize(repeating: -1, count: nt)
        cursor = .allocate(capacity: np)
        cursor.initialize(repeating: 0, count: np)
        end = .allocate(capacity: np)
        end.initialize(repeating: 0, count: np)
        balance = .allocate(capacity: colorClasses)
        balance.initialize(repeating: 0, count: colorClasses)
        super.init()
    }

    convenience init(copying other: _SubgraphSearch) {
        self.init(other.data)
        let np = max(p.count, 1), nt = max(t.count, 1)
        core1.update(from: other.core1, count: np)
        core2.update(from: other.core2, count: nt)
        cursor.update(from: other.cursor, count: np)
        end.update(from: other.end, count: np)
        depth = other.depth
        started = other.started
        finished = other.finished
        steps = other.steps
    }

    override func copy() -> _MatchingSearch { _SubgraphSearch(copying: self) }

    deinit {
        core1.deallocate()
        core2.deallocate()
        cursor.deallocate()
        end.deallocate()
        balance.deallocate()
    }

    override func next() -> [Int]? {
        if finished { return nil }
        let np = p.count
        if !started {
            started = true
            if np == 0 {
                finished = true
                return []
            }
            depth = 0
            setCandidates(0)
        } else {
            // Resume after a leaf: unmap the last vertex and continue its candidates.
            depth = np - 1
            unmap(order[depth])
        }
        while true {
            steps &+= 1
            if steps & 4095 == 0 && Task.isCancelled {
                finished = true
                return nil
            }
            let d = depth
            let u = order[d]
            var found = -1
            while cursor[d] < end[d] {
                let x = candidate(d)
                if x >= 0 && feasible(u, x) {
                    found = x
                    break
                }
            }
            if found >= 0 {
                core1[u] = found
                core2[found] = u
                if d == np - 1 {
                    return (0 ..< np).map { core1[$0] }
                }
                depth = d + 1
                setCandidates(depth)
            } else {
                if d == 0 {
                    finished = true
                    return nil
                }
                depth = d - 1
                unmap(order[depth])
            }
        }
    }

    @inline(__always)
    private func unmap(_ u: Int) {
        core2[core1[u]] = -1
        core1[u] = -1
    }

    /// Candidates of depth d: slots of a target row, or target vertices (`parent[d] < 0`).
    private func setCandidates(_ d: Int) {
        let w = parent[d]
        if w < 0 {
            cursor[d] = 0
            end[d] = t.count
        } else {
            let y = core1[w]
            let offsets = parentInward[d] ? t.inOffsets : t.outOffsets
            cursor[d] = offsets[y]
            end[d] = offsets[y + 1]
        }
    }

    /// The candidate at depth d's cursor, advancing it; -1 for a repeat (a parallel edge) or a
    /// mapped vertex.
    @inline(__always)
    private func candidate(_ d: Int) -> Int {
        let k = cursor[d]
        cursor[d] = k + 1
        let x: Int
        if parent[d] < 0 {
            x = k
        } else {
            let targets = parentInward[d] ? t.inTargets : t.outTargets
            x = targets[k]
            let y = core1[parent[d]]
            let offsets = parentInward[d] ? t.inOffsets : t.outOffsets
            if k > offsets[y] && targets[k - 1] == x { return -1 }
        }
        return core2[x] < 0 ? x : -1
    }

    private func feasible(_ u: Int, _ x: Int) -> Bool {
        if let pc = p.vertexColors, pc[u] != t.vertexColors![x] { return false }
        if t.outOffsets[x + 1] - t.outOffsets[x] < p.outOffsets[u + 1] - p.outOffsets[u] { return false }
        if p.isDirected && t.inOffsets[x + 1] - t.inOffsets[x] < p.inOffsets[u + 1] - p.inOffsets[u] { return false }
        if !relationHolds(u, x, p.outOffsets, p.outTargets, p.outColors, t.outOffsets, t.outTargets, t.outColors, outward: true) { return false }
        if p.isDirected && !relationHolds(u, x, p.inOffsets, p.inTargets, p.inColors, t.inOffsets, t.inTargets, t.inColors, outward: false) { return false }
        return true
    }

    /// The checks along one direction of rows (out-rows, or in-rows of a directed graph).
    @inline(__always)
    private func relationHolds(
        _ u: Int, _ x: Int,
        _ po: UnsafeMutablePointer<Int>, _ pt: UnsafeMutablePointer<Int>, _ pc: UnsafeMutablePointer<Int>?,
        _ to: UnsafeMutablePointer<Int>, _ tt: UnsafeMutablePointer<Int>, _ tc: UnsafeMutablePointer<Int>?,
        outward: Bool
    ) -> Bool {
        var patternMapped = 0, patternFree = 0, patternLoop = false
        let ps = po[u], pe = po[u + 1]
        var k = ps
        while k < pe {
            let w = pt[k]
            var ke = k + 1
            while ke < pe && pt[ke] == w { ke += 1 }
            if w == u {
                patternLoop = true
                if !segmentHolds(k, ke, pc, x, x, to, tt, tc, outward) { return false }
            } else {
                let y = core1[w]
                if y >= 0 {
                    if !segmentHolds(k, ke, pc, x, y, to, tt, tc, outward) { return false }
                    patternMapped += ke - k
                } else {
                    patternFree += 1
                }
            }
            k = ke
        }
        var targetMapped = 0, targetFree = 0, targetLoop = false
        let ts = to[x], te = to[x + 1]
        k = ts
        while k < te {
            let y = tt[k]
            var ke = k + 1
            while ke < te && tt[ke] == y { ke += 1 }
            if y == x {
                targetLoop = true
            } else if core2[y] >= 0 {
                targetMapped += ke - k
            } else {
                targetFree += 1
            }
            k = ke
        }
        if induced && (targetMapped != patternMapped || (targetLoop && !patternLoop)) { return false }
        if patternFree > targetFree { return false }
        guard let pv = p.vertexColors, let tv = t.vertexColors, patternFree > 0 else { return true }
        // Per colour: the free distinct neighbours of u, less those of x, must not be positive.
        var ok = true
        k = ps
        while k < pe {
            let w = pt[k]
            if w != u && core1[w] < 0 && (k == ps || pt[k - 1] != w) { balance[pv[w]] += 1 }
            k += 1
        }
        k = ts
        while k < te {
            let y = tt[k]
            if y != x && core2[y] < 0 && (k == ts || tt[k - 1] != y) { balance[tv[y]] -= 1 }
            k += 1
        }
        k = ps
        while k < pe {
            let w = pt[k]
            if w != u && core1[w] < 0 && balance[pv[w]] > 0 { ok = false }
            k += 1
        }
        k = ps
        while k < pe {
            let w = pt[k]
            if w != u && core1[w] < 0 { balance[pv[w]] = 0 }
            k += 1
        }
        k = ts
        while k < te {
            let y = tt[k]
            if y != x && core2[y] < 0 { balance[tv[y]] = 0 }
            k += 1
        }
        return ok
    }

    /// Whether the pattern slots `k..<ke` (one neighbour) are matched by the target's slots from
    /// x to y: equal as multisets of colours (induced) or contained (monomorphism).
    @inline(__always)
    private func segmentHolds(
        _ k: Int, _ ke: Int, _ pc: UnsafeMutablePointer<Int>?,
        _ x: Int, _ y: Int,
        _ to: UnsafeMutablePointer<Int>, _ tt: UnsafeMutablePointer<Int>, _ tc: UnsafeMutablePointer<Int>?,
        _ outward: Bool
    ) -> Bool {
        if simple {
            if let bits {
                // Out-rows: x → y; in-rows: y → x.
                let (a, b) = outward ? (x, y) : (y, x)
                return bits[a * words + b >> 6] & (1 << UInt64(b & 63)) != 0
            }
        }
        // Binary search for y in x's row.
        var low = to[x], high = to[x + 1]
        while low < high {
            let mid = (low + high) >> 1
            if tt[mid] < y { low = mid + 1 } else { high = mid }
        }
        var segmentEnd = low
        while segmentEnd < to[x + 1] && tt[segmentEnd] == y { segmentEnd += 1 }
        let needed = ke - k, available = segmentEnd - low
        guard let pc, let tc else {
            return induced ? needed == available : needed <= available
        }
        if induced {
            if needed != available { return false }
            for j in 0 ..< needed where pc[k + j] != tc[low + j] { return false }
            return true
        }
        if needed > available { return false }
        // Sub-multiset of sorted colour runs.
        var i = k, j = low
        while i < ke {
            while j < segmentEnd && tc[j] < pc[i] { j += 1 }
            if j == segmentEnd || tc[j] != pc[i] { return false }
            i += 1
            j += 1
        }
        return true
    }
}
