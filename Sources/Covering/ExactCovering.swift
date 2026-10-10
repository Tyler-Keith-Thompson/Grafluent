import GraphProtocols

// MARK: - Components

/// The connected components of the simple graph, by breadth-first search from each unvisited
/// vertex in index order: `order` lists the vertices component by component (component c is
/// `order[starts[c] ..< starts[c + 1]]`), `color` is a two-colouring per vertex (−1 for skipped
/// vertices), and `bipartite[c]` whether component c's colouring is proper. With `skipLooped`,
/// looped vertices are left out, as if deleted. O(n + m).
@inlinable
func _coveringComponents(
    _ g: _CoveringGraph, skipLooped: Bool
) -> (order: [Int], starts: [Int], color: [Int8], bipartite: [Bool]) {
    let n = g.count
    var color = [Int8](repeating: -1, count: n)
    var order: [Int] = []
    order.reserveCapacity(n)
    var starts = [0]
    var bipartite: [Bool] = []
    for s in 0 ..< n where color[s] < 0 && !(skipLooped && g.hasLoop[s]) {
        color[s] = 0
        var head = order.count
        order.append(s)
        var proper = true
        while head < order.count {
            let v = order[head]
            head += 1
            for k in g.offsets[v] ..< g.offsets[v + 1] {
                let w = g.neighbors[k]
                if skipLooped && g.hasLoop[w] { continue }
                if color[w] < 0 {
                    color[w] = 1 - color[v]
                    order.append(w)
                } else if color[w] == color[v] {
                    proper = false
                }
            }
        }
        starts.append(order.count)
        bipartite.append(proper)
    }
    return (order, starts, color, bipartite)
}

/// The vertices of each connected component of the simple graph (loops ignored), by breadth-first
/// search from each unvisited vertex in index order: component c is `order[starts[c] ..<
/// starts[c + 1]]`. O(n + m).
@inlinable
func _dominationComponents(_ g: _CoveringGraph) -> (order: [Int], starts: [Int]) {
    let n = g.count
    var seen = [Bool](repeating: false, count: n)
    var order: [Int] = []
    order.reserveCapacity(n)
    var starts = [0]
    for s in 0 ..< n where !seen[s] {
        seen[s] = true
        var head = order.count
        order.append(s)
        while head < order.count {
            let v = order[head]
            head += 1
            for k in g.offsets[v] ..< g.offsets[v + 1] where !seen[g.neighbors[k]] {
                seen[g.neighbors[k]] = true
                order.append(g.neighbors[k])
            }
        }
        starts.append(order.count)
    }
    return (order, starts)
}

// MARK: - Independent sets

/// The lexicographically least maximum independent set (flags by vertex number) and its size α.
/// Looped vertices are left out. Bipartite components go through a maximum matching
/// (`_bipartiteIndependentSet`), complete ones take their least vertex, and the others go through
/// `_IndependentSetReduction` (with `lexicographic`) or straight to `_IndependentSetKernel` (for α
/// alone). The rule composes: the least vertex of a symmetric difference lies in one component,
/// whose own least set wins there. Without `lexicographic`, only the size is meaningful.
@inlinable
func _maximumIndependentSet(_ g: _CoveringGraph, lexicographic: Bool) -> (inSet: [Bool], size: Int) {
    let n = g.count
    var inSet = [Bool](repeating: false, count: n)
    guard n > 0 else { return (inSet, 0) }
    let (order, starts, color, bipartite) = _coveringComponents(g, skipLooped: true)
    var side = [Int8](repeating: -1, count: n)
    var size = 0
    var reduction: _IndependentSetReduction?
    var members: [Int] = []
    for c in bipartite.indices {
        let first = starts[c], end = starts[c + 1]
        if bipartite[c] {
            for i in first ..< end { side[order[i]] = color[order[i]] }
            continue
        }
        // A complete component: its least vertex.
        var least = order[first], ends = 0
        for i in first ..< end {
            let u = order[i]
            least = min(least, u)
            for k in g.offsets[u] ..< g.offsets[u + 1] where !g.hasLoop[g.neighbors[k]] { ends += 1 }
        }
        let p = end - first
        if ends == p * (p - 1) {
            inSet[least] = true
            size += 1
            continue
        }
        members.removeAll(keepingCapacity: true)
        members.append(contentsOf: order[first ..< end])
        members.sort()
        if reduction == nil { reduction = _IndependentSetReduction(count: n) }
        if lexicographic {
            reduction!.solve(g, members, side: &side, into: &inSet)
        } else {
            size += reduction!.kernel.solve(g, members, need: Int.max, wantSet: false)
        }
    }
    if side.contains(where: { $0 >= 0 }) {
        size += _bipartiteIndependentSet(g, side: side, lexicographic: lexicographic, into: &inSet)
    }
    if lexicographic {
        size = 0
        for flag in inSet where flag { size += 1 }
    }
    return (inSet, size)
}

/// The lexicographically least maximum independent set of the bipartite components at once
/// (`side[v]` is v's colour there, −1 outside them), written into `inSet`; returns its size, the
/// number of those vertices minus a maximum matching (König).
///
/// Hopcroft–Karp (Hopcroft and Karp 1973) after a greedy start gives a maximum matching. One
/// breadth-first search from every free vertex along alternating paths (unmatched edges leaving
/// vertices on the root's side, matched edges leaving the others) reaches vertices on the root's
/// side, which are in every maximum independent set, and vertices on the other side, which are in
/// every minimum cover. The rest, the core, is perfectly matched, and the maximum independent sets
/// take one end of each core pair X: an unmatched core edge from X's left end to Y's right end
/// requires "X's left end independent implies Y's left end independent" (Dulmage and Mendelsohn
/// 1958). The least set is one pass over the core in index order: each vertex whose pair is
/// undecided is made independent, and the choice propagates forward (left end) or backward (right
/// end) to undecided pairs. O(m √n) for the matching, O(n + m) for the rest.
@inlinable
func _bipartiteIndependentSet(_ g: _CoveringGraph, side: [Int8], lexicographic: Bool, into inSet: inout [Bool]) -> Int {
    let n = g.count
    let infinity = Int.max
    var mate = [Int](repeating: -1, count: n)
    var left: [Int] = []
    var count = 0, matched = 0
    for v in 0 ..< n where side[v] >= 0 {
        count += 1
        guard side[v] == 0 else { continue }
        left.append(v)
        for k in g.offsets[v] ..< g.offsets[v + 1] {
            let w = g.neighbors[k]
            if side[w] >= 0 && mate[w] < 0 {
                mate[v] = w
                mate[w] = v
                matched += 1
                break
            }
        }
    }
    // Hopcroft–Karp phases: layer the left vertices from the free ones, then augment by
    // depth-first search one layer deeper at a time, a row cursor per frame.
    var layer = [Int](repeating: infinity, count: n)
    var queue = [Int](repeating: 0, count: max(left.count, 1))
    var path: [Int] = [], cursor: [Int] = []
    while matched < left.count {
        var head = 0, tail = 0
        for v in left {
            if mate[v] < 0 {
                layer[v] = 0
                queue[tail] = v
                tail += 1
            } else {
                layer[v] = infinity
            }
        }
        var free = infinity
        while head < tail {
            let v = queue[head]
            head += 1
            guard layer[v] < free else { continue }
            for k in g.offsets[v] ..< g.offsets[v + 1] {
                let w = g.neighbors[k]
                guard side[w] >= 0 else { continue }
                let p = mate[w]
                if p < 0 {
                    if free == infinity { free = layer[v] + 1 }
                } else if layer[p] == infinity {
                    layer[p] = layer[v] + 1
                    queue[tail] = p
                    tail += 1
                }
            }
        }
        guard free != infinity else { break }
        for root in left where mate[root] < 0 {
            path.removeAll(keepingCapacity: true)
            cursor.removeAll(keepingCapacity: true)
            path.append(root)
            cursor.append(g.offsets[root])
            var augmented = false
            while let v = path.last {
                let k = cursor[cursor.count - 1]
                if k == g.offsets[v + 1] {
                    layer[v] = infinity
                    path.removeLast()
                    cursor.removeLast()
                    if !cursor.isEmpty { cursor[cursor.count - 1] += 1 }
                    continue
                }
                let w = g.neighbors[k]
                if side[w] >= 0 {
                    let p = mate[w], next = layer[v] + 1
                    if p < 0 {
                        if free == next {
                            augmented = true
                            break
                        }
                    } else if layer[p] == next {
                        path.append(p)
                        cursor.append(g.offsets[p])
                        continue
                    }
                }
                cursor[cursor.count - 1] = k + 1
            }
            if augmented {
                for i in path.indices {
                    let v = path[i], w = g.neighbors[cursor[i]]
                    mate[v] = w
                    mate[w] = v
                }
                matched += 1
            }
        }
    }
    guard lexicographic else { return count - matched }

    // Alternating reach from every free vertex; `root[v]` is the side of v's root, −1 unreached.
    var root = [Int8](repeating: -1, count: n)
    queue.removeAll(keepingCapacity: true)
    for v in 0 ..< n where side[v] >= 0 && mate[v] < 0 {
        root[v] = side[v]
        queue.append(v)
    }
    var head = 0
    while head < queue.count {
        let v = queue[head]
        head += 1
        if side[v] == root[v] {
            inSet[v] = true
            for k in g.offsets[v] ..< g.offsets[v + 1] {
                let w = g.neighbors[k]
                if side[w] >= 0 && root[w] < 0 && w != mate[v] {
                    root[w] = root[v]
                    queue.append(w)
                }
            }
        } else {
            let w = mate[v]
            if w >= 0 && root[w] < 0 {
                root[w] = root[v]
                queue.append(w)
            }
        }
    }

    // The core greedy. `choice` by a pair's left end: 1 the left end is independent (and so is
    // every successor's), 2 the right end is (and so is every predecessor's).
    var choice = [Int8](repeating: 0, count: n)
    var stack: [Int] = []
    for v in 0 ..< n where side[v] >= 0 && root[v] < 0 {
        let x = side[v] == 0 ? v : mate[v]
        guard choice[x] == 0 else { continue }
        stack.append(x)
        if side[v] == 0 {
            // Successors of X: the pairs Y whose right end y is an unmatched core neighbour of X.
            choice[x] = 1
            while let a = stack.popLast() {
                for k in g.offsets[a] ..< g.offsets[a + 1] {
                    let y = g.neighbors[k]
                    guard side[y] >= 0 && root[y] < 0 && y != mate[a] else { continue }
                    let b = mate[y]
                    if choice[b] == 0 {
                        choice[b] = 1
                        stack.append(b)
                    }
                }
            }
        } else {
            // Predecessors of Y: the pairs X whose left end is an unmatched core neighbour of Y's
            // right end.
            choice[x] = 2
            while let b = stack.popLast() {
                let y = mate[b]
                for k in g.offsets[y] ..< g.offsets[y + 1] {
                    let a = g.neighbors[k]
                    guard side[a] >= 0 && root[a] < 0 && a != b else { continue }
                    if choice[a] == 0 {
                        choice[a] = 2
                        stack.append(a)
                    }
                }
            }
        }
    }
    for x in 0 ..< n where side[x] == 0 && root[x] < 0 {
        if choice[x] == 1 { inSet[x] = true } else { inSet[mate[x]] = true }
    }
    return count - matched
}

/// Maximum independent sets of one graph as maximum cliques of its complement, held as bitset
/// rows over local indices (the vertices by ascending degree, ties by index, which colours well).
/// The search is San Segundo, Rodríguez-Losada and Jiménez's BBMC (2011), Tomita and Seki's MCQ
/// (2003) on bitsets, iterative: each node colours its candidates greedily in local order,
/// branches on them from the highest colour down, and stops when the chosen vertices plus the
/// colour cannot beat the best. `_IndependentSetKernel` runs it on what its reductions leave, so
/// the rows cover a kernel component, not the input. Scratch is reused, so a node allocates
/// nothing once the flat stacks have grown.
@frozen
@usableFromInline
struct _IndependentSetSearch {
    /// Vertex number → local index, −1 outside the loaded graph.
    @usableFromInline var local: [Int]
    /// Local index → vertex number.
    @usableFromInline var vertices: [Int] = []
    @usableFromInline var words = 0
    /// The complement's rows: `rows[i * words ..< (i + 1) * words]`.
    @usableFromInline var rows: [UInt64] = []
    /// The candidate set per depth, flat.
    @usableFromInline var sets: [UInt64] = []
    /// The coloured candidates per depth, flat: `order` and `colors` from `starts[d]`; `next[d]` is
    /// one past the next to branch on (they are taken from the end).
    @usableFromInline var order: [Int] = []
    @usableFromInline var colors: [Int] = []
    @usableFromInline var starts: [Int] = []
    @usableFromInline var next: [Int] = []
    @usableFromInline var chosen: [Int] = []
    /// The best clique found by the last `maximum`, by local index.
    @usableFromInline var best: [Int] = []
    /// The set `search` starts from.
    @usableFromInline var start: [UInt64] = []
    @usableFromInline var uncolored: [UInt64] = []
    @usableFromInline var color: [UInt64] = []
    @usableFromInline var degree: [Int] = []
    @usableFromInline var rank: [Int] = []

    @inlinable
    init(count n: Int) {
        local = [Int](repeating: -1, count: n)
    }

    /// Sets up the vertices `members` of `g` (ascending numbers, a union of components, no looped
    /// vertex).
    @inlinable
    mutating func load(_ g: _CoveringGraph, _ members: [Int]) {
        for u in vertices { local[u] = -1 }
        // Degree among the members (every non-looped neighbour is one).
        degree.removeAll(keepingCapacity: true)
        rank.removeAll(keepingCapacity: true)
        for (i, u) in members.enumerated() {
            var d = 0
            for k in g.offsets[u] ..< g.offsets[u + 1] where !g.hasLoop[g.neighbors[k]] { d += 1 }
            degree.append(d)
            rank.append(i)
        }
        rank.sort { degree[$0] != degree[$1] ? degree[$0] < degree[$1] : $0 < $1 }
        vertices.removeAll(keepingCapacity: true)
        for i in rank { vertices.append(members[i]) }
        for (i, u) in vertices.enumerated() { local[u] = i }
        let p = vertices.count
        words = (p + 63) >> 6
        rows.removeAll(keepingCapacity: true)
        rows.append(contentsOf: repeatElement(~0, count: p * words))
        let tail = p & 63
        for i in 0 ..< p {
            if tail != 0 { rows[i * words + words - 1] = (1 << UInt64(tail)) - 1 }
            rows[i * words + i >> 6] &= ~(1 << UInt64(i & 63))
            let u = vertices[i]
            for k in g.offsets[u] ..< g.offsets[u + 1] {
                let j = local[g.neighbors[k]]
                if j >= 0 { rows[i * words + j >> 6] &= ~(1 << UInt64(j & 63)) }
            }
        }
        uncolored.removeAll(keepingCapacity: true)
        uncolored.append(contentsOf: repeatElement(0, count: words))
        color.removeAll(keepingCapacity: true)
        color.append(contentsOf: repeatElement(0, count: words))
        start.removeAll(keepingCapacity: true)
        start.append(contentsOf: repeatElement(0, count: words))
    }

    /// Colours the candidates at `depth` greedily (each colour class independent in the
    /// complement, filled in local order) and lists those of colour at least `least`, by colour.
    @inlinable
    mutating func colorSort(depth: Int, least: Int) {
        starts.append(order.count)
        let base = depth * words
        var remaining = 0
        for k in 0 ..< words {
            uncolored[k] = sets[base + k]
            remaining += uncolored[k].nonzeroBitCount
        }
        var c = 0
        var first = 0
        while remaining > 0 {
            c += 1
            while uncolored[first] == 0 { first += 1 }
            for k in first ..< words { color[k] = uncolored[k] }
            for k in first ..< words {
                while color[k] != 0 {
                    let b = color[k].trailingZeroBitCount
                    let v = k << 6 | b
                    color[k] &= color[k] - 1
                    uncolored[k] &= ~(1 << UInt64(b))
                    remaining -= 1
                    // Its neighbours in the complement cannot share its colour.
                    for j in k ..< words { color[j] &= ~rows[v * words + j] }
                    if c >= least {
                        order.append(v)
                        colors.append(c)
                    }
                }
            }
        }
        next.append(order.count)
    }

    /// The size of a largest clique of the complement inside `start`, if it exceeds `floor`
    /// (recorded in `best`), else `floor`. Stops as soon as `target` is reached.
    @inlinable
    mutating func search(floor: Int, target: Int) -> Int {
        var bestSize = floor
        sets.removeAll(keepingCapacity: true)
        sets.append(contentsOf: start)
        order.removeAll(keepingCapacity: true)
        colors.removeAll(keepingCapacity: true)
        starts.removeAll(keepingCapacity: true)
        next.removeAll(keepingCapacity: true)
        chosen.removeAll(keepingCapacity: true)
        colorSort(depth: 0, least: bestSize + 1)
        while let depth = next.indices.last {
            let i = next[depth] - 1
            if i < starts[depth] || depth + colors[i] <= bestSize {
                order.removeSubrange(starts[depth]...)
                colors.removeSubrange(starts[depth]...)
                starts.removeLast()
                next.removeLast()
                sets.removeLast(words)
                if depth > 0 { chosen.removeLast() }
                continue
            }
            next[depth] = i
            let v = order[i]
            let base = depth * words
            // Later branches never revisit v.
            sets[base + v >> 6] &= ~(1 << UInt64(v & 63))
            chosen.append(v)
            sets.append(contentsOf: repeatElement(0, count: words))
            let child = base + words
            var empty = true
            for k in 0 ..< words {
                let x = sets[base + k] & rows[v * words + k]
                sets[child + k] = x
                if x != 0 { empty = false }
            }
            if empty {
                sets.removeLast(words)
                if depth + 1 > bestSize {
                    bestSize = depth + 1
                    best = chosen
                    if bestSize >= target { return bestSize }
                }
                chosen.removeLast()
                continue
            }
            colorSort(depth: depth + 1, least: bestSize - depth)
        }
        return bestSize
    }

    /// A maximum independent set of the loaded graph, in `best` (local indices), and its size α;
    /// the greedy set in local order seeds the search. With `floor` above the greedy size, only
    /// sets larger than `floor` are looked for: the result is then α when α > `floor`, else the
    /// greedy size (and `best` the greedy set). The search stops once it reaches `target`.
    @inlinable
    mutating func maximum(floor: Int, target: Int) -> Int {
        let p = vertices.count
        for k in 0 ..< words { start[k] = 0 }
        for i in 0 ..< p { start[i >> 6] |= 1 << UInt64(i & 63) }
        for k in 0 ..< words { uncolored[k] = start[k] }
        best.removeAll(keepingCapacity: true)
        for i in 0 ..< p where uncolored[i >> 6] & (1 << UInt64(i & 63)) != 0 {
            best.append(i)
            for k in 0 ..< words { uncolored[k] &= rows[i * words + k] }
        }
        let greedy = best.count
        guard greedy < target else { return greedy }
        let least = max(floor, greedy)
        let size = search(floor: least, target: target)
        return size > least ? size : greedy
    }
}

/// α of an induced subgraph, with a maximum independent set when asked, by reduction to a kernel.
/// The rules, applied until none does, are the classic degree rules for the size (Xiao and
/// Nagamochi's survey, and KaMIS's first stage): a vertex of degree 0 or 1 is in some maximum set,
/// so it is taken and its neighbour deleted; a vertex of degree 2 whose neighbours are adjacent is
/// taken and both deleted; a vertex v of degree 2 with nonadjacent neighbours a and b is folded:
/// the three become one vertex adjacent to N(a) ∪ N(b) − v, and α drops by exactly one (some
/// maximum set holds v, or holds both a and b). None of these keeps the lexicographic rule, so
/// they serve only α and some maximum set (unfolded at the end: the merged vertex in the set puts
/// a and b in it, else v). What remains, the kernel, splits into components: bipartite ones go
/// through `_bipartiteIndependentSet`, the others through `_IndependentSetSearch`, whose bitset
/// rows are a kernel component's size squared, not the input's.
///
/// The working graph is flat rows in one pool, deleted vertices left in place (a degree counts the
/// live neighbours); a fold merges the shorter row into the longer one, which moves to the pool's
/// end, compacted, when it fills, so merges cost O(m log m) in all. The reductions are O(n + m)
/// apart from that.
@frozen
@usableFromInline
struct _IndependentSetKernel {
    /// Vertex number → working index, −1 outside the current call.
    @usableFromInline var local: [Int]
    /// Working index → vertex number.
    @usableFromInline var vertices: [Int] = []
    /// Row i is `pool[start[i] ..< start[i] + length[i]]`, with room up to `capacity[i]`.
    @usableFromInline var start: [Int] = []
    @usableFromInline var length: [Int] = []
    @usableFromInline var capacity: [Int] = []
    @usableFromInline var pool: [Int] = []
    /// Live neighbours.
    @usableFromInline var degree: [Int] = []
    /// 0 live, 1 taken, 2 deleted or folded away.
    @usableFromInline var state: [Int8] = []
    @usableFromInline var mark: [Int] = []
    @usableFromInline var stamp = 0
    @usableFromInline var queue: [Int] = []
    /// Per fold: v, a, b and the merged vertex (a or b).
    @usableFromInline var folds: [Int] = []
    @usableFromInline var flags: [Bool] = []
    @usableFromInline var kernelIndex: [Int] = []
    @usableFromInline var part: [Int] = []
    @usableFromInline var search: _IndependentSetSearch
    /// The maximum set found by the last `solve` with `wantSet`, by vertex number.
    @usableFromInline var set: [Int] = []

    @inlinable
    init(count n: Int) {
        local = [Int](repeating: -1, count: n)
        search = _IndependentSetSearch(count: n)
    }

    @inlinable
    mutating func delete(_ x: Int) {
        state[x] = 2
        for k in start[x] ..< start[x] + length[x] {
            let y = pool[k]
            guard state[y] == 0 else { continue }
            degree[y] -= 1
            if degree[y] <= 2 { queue.append(y) }
        }
    }

    @inlinable
    func adjacent(_ a: Int, _ b: Int) -> Bool {
        let x = length[a] <= length[b] ? a : b, y = x == a ? b : a
        for k in start[x] ..< start[x] + length[x] where pool[k] == y { return true }
        return false
    }

    /// Appends x to v's row, moving the row (live entries only) to the pool's end when it is full.
    @inlinable
    mutating func append(_ x: Int, to v: Int) {
        if length[v] == capacity[v] {
            let first = pool.count
            for k in start[v] ..< start[v] + length[v] {
                let y = pool[k]
                if state[y] == 0 { pool.append(y) }
            }
            let live = pool.count - first, room = max(4, 2 * live)
            pool.append(contentsOf: repeatElement(-1, count: room - live))
            start[v] = first
            length[v] = live
            capacity[v] = room
        }
        pool[start[v] + length[v]] = x
        length[v] += 1
    }

    /// Folds v (degree 2) with its nonadjacent neighbours a and b into the one of a and b with the
    /// longer row.
    @inlinable
    mutating func fold(_ v: Int, _ a: Int, _ b: Int) {
        let merged = length[a] >= length[b] ? a : b, other = merged == a ? b : a
        state[v] = 2
        state[other] = 2
        stamp += 1
        for k in start[merged] ..< start[merged] + length[merged] where state[pool[k]] == 0 { mark[pool[k]] = stamp }
        degree[merged] -= 1
        for k in start[other] ..< start[other] + length[other] {
            let x = pool[k]
            guard state[x] == 0 else { continue }
            if mark[x] == stamp {
                degree[x] -= 1
                if degree[x] <= 2 { queue.append(x) }
            } else {
                for j in start[x] ..< start[x] + length[x] where pool[j] == other {
                    pool[j] = merged
                    break
                }
                append(x, to: merged)
                degree[merged] += 1
            }
        }
        if degree[merged] <= 2 { queue.append(merged) }
        folds.append(v)
        folds.append(a)
        folds.append(b)
        folds.append(merged)
    }

    /// α of the subgraph induced by `members` (no looped vertex; ascending numbers), and with
    /// `wantSet` a maximum independent set of it in `set`. With `need` finite the caller only asks
    /// whether α ≥ `need` and knows α ≤ `need`: the result is then at least `need` exactly when α
    /// is, and `set` is valid only then.
    @inlinable
    mutating func solve(_ g: _CoveringGraph, _ members: [Int], need: Int, wantSet: Bool) -> Int {
        for u in vertices { local[u] = -1 }
        vertices.removeAll(keepingCapacity: true)
        vertices.append(contentsOf: members)
        let r = members.count
        for i in 0 ..< r { local[members[i]] = i }
        start.removeAll(keepingCapacity: true)
        length.removeAll(keepingCapacity: true)
        capacity.removeAll(keepingCapacity: true)
        degree.removeAll(keepingCapacity: true)
        pool.removeAll(keepingCapacity: true)
        for i in 0 ..< r {
            let u = members[i], first = pool.count
            for k in g.offsets[u] ..< g.offsets[u + 1] {
                let j = local[g.neighbors[k]]
                if j >= 0 { pool.append(j) }
            }
            start.append(first)
            length.append(pool.count - first)
            capacity.append(pool.count - first)
            degree.append(pool.count - first)
        }
        state.removeAll(keepingCapacity: true)
        state.append(contentsOf: repeatElement(0, count: r))
        mark.removeAll(keepingCapacity: true)
        mark.append(contentsOf: repeatElement(0, count: r))
        stamp = 0
        folds.removeAll(keepingCapacity: true)
        queue.removeAll(keepingCapacity: true)
        for i in 0 ..< r where degree[i] <= 2 { queue.append(i) }
        var total = 0, head = 0
        while head < queue.count {
            let v = queue[head]
            head += 1
            guard state[v] == 0, degree[v] <= 2 else { continue }
            var a = -1, b = -1
            for k in start[v] ..< start[v] + length[v] where state[pool[k]] == 0 {
                if a < 0 {
                    a = pool[k]
                } else {
                    b = pool[k]
                    break
                }
            }
            total += 1
            if b < 0 {
                state[v] = 1
                if a >= 0 { delete(a) }
            } else if adjacent(a, b) {
                state[v] = 1
                delete(a)
                delete(b)
            } else {
                fold(v, a, b)
            }
        }

        // The kernel, renumbered, as a simple graph of its own.
        kernelIndex.removeAll(keepingCapacity: true)
        kernelIndex.append(contentsOf: repeatElement(-1, count: r))
        var size = 0
        for i in 0 ..< r where state[i] == 0 {
            kernelIndex[i] = size
            size += 1
        }
        var found = [Bool](repeating: false, count: size)
        if size > 0 {
            var offsets = [0]
            offsets.reserveCapacity(size + 1)
            var neighbors: [Int] = []
            for i in 0 ..< r where state[i] == 0 {
                for k in start[i] ..< start[i] + length[i] where state[pool[k]] == 0 { neighbors.append(kernelIndex[pool[k]]) }
                offsets.append(neighbors.count)
            }
            let kernel = _CoveringGraph(offsets: offsets, neighbors: neighbors, hasLoop: [Bool](repeating: false, count: size))
            let (order, starts, color, bipartite) = _coveringComponents(kernel, skipLooped: false)
            var side = [Int8](repeating: -1, count: size)
            var anyBipartite = false, others = 0
            for c in bipartite.indices {
                if bipartite[c] {
                    anyBipartite = true
                    for i in starts[c] ..< starts[c + 1] { side[order[i]] = color[order[i]] }
                } else {
                    others += 1
                }
            }
            if anyBipartite { total += _bipartiteIndependentSet(kernel, side: side, lexicographic: wantSet, into: &found) }
            for c in bipartite.indices where !bipartite[c] {
                part.removeAll(keepingCapacity: true)
                part.append(contentsOf: order[starts[c] ..< starts[c + 1]])
                part.sort()
                search.load(kernel, part)
                if others == 1 && need != Int.max {
                    let needed = need - total
                    total += search.maximum(floor: needed - 1, target: needed)
                } else {
                    total += search.maximum(floor: 0, target: part.count)
                }
                if wantSet {
                    for i in search.best { found[search.vertices[i]] = true }
                }
            }
        }
        guard wantSet else { return total }
        flags.removeAll(keepingCapacity: true)
        for i in 0 ..< r { flags.append(state[i] == 1 || (state[i] == 0 && found[kernelIndex[i]])) }
        var f = folds.count
        while f > 0 {
            f -= 4
            let v = folds[f], a = folds[f + 1], b = folds[f + 2]
            let both = flags[folds[f + 3]]
            flags[a] = both
            flags[b] = both
            flags[v] = !both
        }
        set.removeAll(keepingCapacity: true)
        for i in 0 ..< r where flags[i] { set.append(vertices[i]) }
        return total
    }
}

/// The lexicographically least maximum independent set of one component that is neither
/// bipartite nor complete. The least set is decided vertex by vertex in ascending number: v is
/// taken when some maximum set extends the choices so far with v, else deleted. A witness W, a
/// maximum set of what is left, answers whenever it holds v; otherwise `_IndependentSetKernel`
/// decides whether v's component C of what is left, less N[v], still has |W ∩ C| − 1 independent
/// vertices, and a success becomes the witness there.
///
/// Between decisions, rules that keep the least set itself shrink what is left (each by an
/// exchange: the set holding the lesser vertex of a swap is the lesser set):
/// * a vertex x with no neighbour left is in every maximum set;
/// * a simplicial vertex x (its neighbours left form a clique; checked up to degree 8) less than
///   all of them is in the least set: a maximum set S without x holds exactly one neighbour u, and
///   S − u + x is a lesser maximum set. A leaf less than its neighbour is the common case.
/// Taking x deletes N[x]; a witness holding the neighbour u swaps it for x. After each kernel call
/// the component is split again: pieces that turned bipartite go to the final
/// `_bipartiteIndependentSet` pass, complete ones take their least vertex. A kernel call costs
/// O(|C| + its edges) plus the kernel search, so a component costs O(c (c + m)) at worst and O(c +
/// m) when the rules and the witness settle it.
@frozen
@usableFromInline
struct _IndependentSetReduction {
    @usableFromInline var alive: [Bool]
    /// Neighbours alive.
    @usableFromInline var degree: [Int]
    @usableFromInline var witness: [Bool]
    @usableFromInline var mark: [Int]
    @usableFromInline var stamp = 0
    @usableFromInline var color: [Int8]
    @usableFromInline var queue: [Int] = []
    @usableFromInline var reached: [Int] = []
    @usableFromInline var piece: [Int] = []
    @usableFromInline var kernel: _IndependentSetKernel

    @inlinable
    init(count n: Int) {
        alive = [Bool](repeating: false, count: n)
        degree = [Int](repeating: 0, count: n)
        witness = [Bool](repeating: false, count: n)
        mark = [Int](repeating: 0, count: n)
        color = [Int8](repeating: 0, count: n)
        kernel = _IndependentSetKernel(count: n)
    }

    @inlinable
    mutating func kill(_ g: _CoveringGraph, _ u: Int) {
        alive[u] = false
        for k in g.offsets[u] ..< g.offsets[u + 1] {
            let w = g.neighbors[k]
            guard alive[w] else { continue }
            degree[w] -= 1
            queue.append(w)
        }
    }

    @inlinable
    mutating func take(_ g: _CoveringGraph, _ v: Int, into inSet: inout [Bool]) {
        inSet[v] = true
        alive[v] = false
        for k in g.offsets[v] ..< g.offsets[v + 1] where alive[g.neighbors[k]] { kill(g, g.neighbors[k]) }
    }

    /// Applies the lexicographic rules to the queued vertices until none applies.
    @inlinable
    mutating func reduce(_ g: _CoveringGraph, into inSet: inout [Bool]) {
        while let x = queue.popLast() {
            guard alive[x] else { continue }
            let d = degree[x]
            if d == 0 {
                witness[x] = true
                take(g, x, into: &inSet)
                continue
            }
            guard d <= 8 else { continue }
            var least = true
            for k in g.offsets[x] ..< g.offsets[x + 1] where alive[g.neighbors[k]] && g.neighbors[k] < x {
                least = false
                break
            }
            guard least else { continue }
            if d > 1 {
                stamp += 1
                for k in g.offsets[x] ..< g.offsets[x + 1] where alive[g.neighbors[k]] { mark[g.neighbors[k]] = stamp }
                var clique = true
                for k in g.offsets[x] ..< g.offsets[x + 1] where alive[g.neighbors[k]] {
                    let a = g.neighbors[k]
                    var count = 0
                    for j in g.offsets[a] ..< g.offsets[a + 1] where mark[g.neighbors[j]] == stamp && alive[g.neighbors[j]] { count += 1 }
                    if count != d - 1 {
                        clique = false
                        break
                    }
                }
                guard clique else { continue }
            }
            if !witness[x] {
                for k in g.offsets[x] ..< g.offsets[x + 1] where alive[g.neighbors[k]] { witness[g.neighbors[k]] = false }
                witness[x] = true
            }
            take(g, x, into: &inSet)
        }
    }

    /// The component of v among the vertices alive, into `reached`.
    @inlinable
    mutating func reach(_ g: _CoveringGraph, _ v: Int) {
        stamp += 1
        reached.removeAll(keepingCapacity: true)
        reached.append(v)
        mark[v] = stamp
        var head = 0
        while head < reached.count {
            let u = reached[head]
            head += 1
            for k in g.offsets[u] ..< g.offsets[u + 1] {
                let w = g.neighbors[k]
                if alive[w] && mark[w] != stamp {
                    mark[w] = stamp
                    reached.append(w)
                }
            }
        }
    }

    /// Splits the vertices alive among `list` into components: bipartite ones leave for the
    /// matching pass (`side`), complete ones take their least vertex, and with `computeWitness`
    /// the others get a witness from the kernel.
    @inlinable
    mutating func split(_ g: _CoveringGraph, _ list: [Int], side: inout [Int8], into inSet: inout [Bool], computeWitness: Bool) {
        stamp += 1
        let visit = stamp
        for s in list where alive[s] && mark[s] != visit {
            piece.removeAll(keepingCapacity: true)
            piece.append(s)
            mark[s] = visit
            color[s] = 0
            var proper = true, ends = 0, least = s, head = 0
            while head < piece.count {
                let u = piece[head]
                head += 1
                least = min(least, u)
                for k in g.offsets[u] ..< g.offsets[u + 1] {
                    let w = g.neighbors[k]
                    guard alive[w] else { continue }
                    ends += 1
                    if mark[w] != visit {
                        mark[w] = visit
                        color[w] = 1 - color[u]
                        piece.append(w)
                    } else if color[w] == color[u] {
                        proper = false
                    }
                }
            }
            if proper {
                for x in piece {
                    side[x] = color[x]
                    alive[x] = false
                }
            } else if ends == piece.count * (piece.count - 1) {
                for x in piece { alive[x] = false }
                inSet[least] = true
            } else if computeWitness {
                piece.sort()
                _ = kernel.solve(g, piece, need: Int.max, wantSet: true)
                for x in kernel.set { witness[x] = true }
            }
        }
    }

    /// Writes the least maximum independent set of the component `members` (ascending numbers)
    /// into `inSet`, except for the pieces it leaves to the matching pass through `side`.
    @inlinable
    mutating func solve(_ g: _CoveringGraph, _ members: [Int], side: inout [Int8], into inSet: inout [Bool]) {
        for u in members {
            alive[u] = true
            witness[u] = false
        }
        for u in members {
            var d = 0
            for k in g.offsets[u] ..< g.offsets[u + 1] where alive[g.neighbors[k]] { d += 1 }
            degree[u] = d
        }
        queue.append(contentsOf: members.reversed())
        reduce(g, into: &inSet)
        split(g, members, side: &side, into: &inSet, computeWitness: true)
        for v in members {
            guard alive[v] else { continue }
            if witness[v] {
                take(g, v, into: &inSet)
                reduce(g, into: &inSet)
                continue
            }
            reach(g, v)
            var need = 0
            for u in reached where witness[u] { need += 1 }
            var take = need <= 1
            if !take {
                stamp += 1
                mark[v] = stamp
                for k in g.offsets[v] ..< g.offsets[v + 1] { mark[g.neighbors[k]] = stamp }
                piece.removeAll(keepingCapacity: true)
                for u in reached where mark[u] != stamp { piece.append(u) }
                piece.sort()
                take = kernel.solve(g, piece, need: need - 1, wantSet: true) >= need - 1
                if take {
                    for u in reached { witness[u] = false }
                    for u in kernel.set { witness[u] = true }
                }
            } else {
                for u in reached { witness[u] = false }
            }
            if take {
                witness[v] = true
                self.take(g, v, into: &inSet)
            } else {
                kill(g, v)
            }
            reduce(g, into: &inSet)
            split(g, reached, side: &side, into: &inSet, computeWitness: false)
        }
    }
}

// MARK: - Dominating sets

/// Minimum dominating sets of one component by branch and reduce on the sparse rows, with every
/// change on a trail so a branch is undone exactly. Per vertex it keeps its state (allowed,
/// forbidden or chosen), how many chosen vertices dominate it, how many allowed ones could, and
/// its coverage (the undominated vertices of its closed neighbourhood); the undominated vertices
/// are a dense list, so a node visits only them and their neighbours.
///
/// Rules, applied after every change until none does (each keeps, for the state it is applied to,
/// a minimum set consistent with the state; the lexicographic ones keep the least such set):
/// * forced: an undominated vertex with one allowed dominator left needs it, so it is chosen;
/// * useless: an allowed vertex that dominates nothing new is forbidden (a set holding it is not
///   minimum);
/// * dominated: an allowed vertex v whose undominated closed neighbourhood X lies in N[u] for an
///   allowed u is forbidden: a set holding v and u is not minimum, and one holding v alone becomes
///   S − v + u. For the lexicographic rule u < v is required, so S − v + u is the lesser set; for
///   the size u < v or a strictly larger coverage (ties keep one of the two). A leaf v whose
///   neighbour u is less is the case that settles paths and many trees outright. Checked for
///   every vertex at the start, then again after a change only for vertices of degree at most 16
///   (or with nothing new to dominate), and only when the least degree in X is at most 16, which
///   bounds a check by 17 rows.
///
/// A node of `decide` fails when an undominated vertex has no allowed dominator, when the budget
/// is spent, when the largest `budget − chosen` coverages sum to less than the undominated count,
/// or when a 2-packing of the undominated vertices (greedy, fewest allowed dominators first, each
/// with no allowed dominator in common with those before) is larger than the budget left: each
/// packed vertex needs a dominator of its own (on trees the largest 2-packing is γ; Meir and Moon
/// 1975). Otherwise it branches on the most-coverage allowed dominator w of an undominated vertex
/// with the fewest left: w chosen, then w forbidden.
@frozen
@usableFromInline
struct _DominatingSetSearch {
    @usableFromInline let offsets: [Int]
    @usableFromInline let neighbors: [Int]
    /// The component, ascending.
    @usableFromInline var members: [Int] = []
    /// 0 allowed, 1 forbidden, 2 chosen.
    @usableFromInline var state: [UInt8]
    @usableFromInline var dominators: [Int]
    @usableFromInline var allowed: [Int]
    @usableFromInline var coverage: [Int]
    /// The undominated vertices are `undominated[..<open]`; `position` inverts it.
    @usableFromInline var undominated: [Int]
    @usableFromInline var position: [Int]
    @usableFromInline var open = 0
    @usableFromInline var chosen = 0
    @usableFromInline var budget = 0
    /// The dominator `status` chose to branch on.
    @usableFromInline var branch = -1
    /// Changes, newest last: 2v for v chosen, 2v + 1 for v forbidden.
    @usableFromInline var trail: [Int] = []
    @usableFromInline var forced: [Int] = []
    @usableFromInline var checks: [Int] = []
    @usableFromInline var infeasible = false
    @usableFromInline var mark: [Int]
    @usableFromInline var stamp = 0
    @usableFromInline var histogram: [Int]
    @usableFromInline var sorted: [Int]
    /// Per open branch: the trail length before it and its dominator, and whether it is in its
    /// second half (dominator forbidden).
    @usableFromInline var frames: [Int] = []
    /// A minimum completion of the lexicographic choices so far.
    @usableFromInline var witness: [Bool]
    /// The vertices the last successful `decide` chose.
    @usableFromInline var picks: [Int] = []
    /// The allowed vertices of the part `gather` found.
    @usableFromInline var scope: [Int] = []
    @usableFromInline var reached: [Int]
    /// Whether `decide` runs on `scope` (else on `members`).
    @usableFromInline var scoped = false
    /// The component's greatest degree.
    @usableFromInline var topDegree = 0

    @inlinable
    init(_ g: _CoveringGraph) {
        let n = g.count
        offsets = g.offsets
        neighbors = g.neighbors
        state = [UInt8](repeating: 0, count: n)
        dominators = [Int](repeating: 0, count: n)
        allowed = [Int](repeating: 0, count: n)
        coverage = [Int](repeating: 0, count: n)
        undominated = [Int](repeating: 0, count: n)
        position = [Int](repeating: 0, count: n)
        mark = [Int](repeating: 0, count: n)
        sorted = [Int](repeating: 0, count: n)
        witness = [Bool](repeating: false, count: n)
        reached = [Int](repeating: 0, count: n)
        var top = 0
        for v in 0 ..< n { top = max(top, g.offsets[v + 1] - g.offsets[v]) }
        histogram = [Int](repeating: 0, count: top + 2)
    }

    @inlinable
    mutating func take(_ w: Int) {
        state[w] = 2
        chosen += 1
        trail.append(w << 1)
        var k = offsets[w] - 1
        while k < offsets[w + 1] {
            let x = k < offsets[w] ? w : neighbors[k]
            k += 1
            allowed[x] -= 1
            dominators[x] += 1
            guard dominators[x] == 1 else { continue }
            let i = position[x], last = undominated[open - 1]
            undominated[i] = last
            position[last] = i
            undominated[open - 1] = x
            position[x] = open - 1
            open -= 1
            coverage[x] -= 1
            if state[x] == 0 && (coverage[x] == 0 || offsets[x + 1] - offsets[x] <= 16) { checks.append(x) }
            for j in offsets[x] ..< offsets[x + 1] {
                let y = neighbors[j]
                coverage[y] -= 1
                if state[y] == 0 && (coverage[y] == 0 || offsets[y + 1] - offsets[y] <= 16) { checks.append(y) }
            }
        }
    }

    @inlinable
    mutating func forbid(_ y: Int) {
        state[y] = 1
        trail.append(y << 1 | 1)
        var k = offsets[y] - 1
        while k < offsets[y + 1] {
            let x = k < offsets[y] ? y : neighbors[k]
            k += 1
            allowed[x] -= 1
            if dominators[x] == 0 {
                if allowed[x] == 0 {
                    infeasible = true
                } else if allowed[x] == 1 {
                    forced.append(x)
                }
            }
        }
    }

    /// Undoes the trail down to `length` entries.
    @inlinable
    mutating func undo(to length: Int) {
        infeasible = false
        while trail.count > length {
            let entry = trail.removeLast(), v = entry >> 1
            if entry & 1 == 1 {
                state[v] = 0
                allowed[v] += 1
                for k in offsets[v] ..< offsets[v + 1] { allowed[neighbors[k]] += 1 }
                continue
            }
            // Reverse order of `take`, so each vertex returns to the slot it left.
            var k = offsets[v + 1] - 1
            while k >= offsets[v] - 1 {
                let x = k < offsets[v] ? v : neighbors[k]
                k -= 1
                allowed[x] += 1
                dominators[x] -= 1
                guard dominators[x] == 0 else { continue }
                open += 1
                coverage[x] += 1
                for j in offsets[x] ..< offsets[x + 1] { coverage[neighbors[j]] += 1 }
            }
            state[v] = 0
            chosen -= 1
        }
    }

    /// The dominated rule for v (allowed): −1 when v dominates nothing new, u when X ⊆ N[u]
    /// qualifies, −2 when neither.
    @inlinable
    mutating func dominance(_ v: Int, lexicographic: Bool) -> Int {
        let need = coverage[v]
        if need == 0 { return -1 }
        var y = -1, least = Int.max
        var k = offsets[v] - 1
        while k < offsets[v + 1] {
            let x = k < offsets[v] ? v : neighbors[k]
            k += 1
            guard dominators[x] == 0 else { continue }
            let d = offsets[x + 1] - offsets[x]
            if d < least {
                least = d
                y = x
            }
        }
        guard least <= 16 else { return -2 }
        stamp += 1
        k = offsets[v] - 1
        while k < offsets[v + 1] {
            let x = k < offsets[v] ? v : neighbors[k]
            k += 1
            if dominators[x] == 0 { mark[x] = stamp }
        }
        k = offsets[y] - 1
        while k < offsets[y + 1] {
            let u = k < offsets[y] ? y : neighbors[k]
            k += 1
            guard u != v, state[u] == 0, coverage[u] >= need else { continue }
            if u > v && (lexicographic || coverage[u] == need) { continue }
            var count = mark[u] == stamp ? 1 : 0
            for j in offsets[u] ..< offsets[u + 1] where mark[neighbors[j]] == stamp { count += 1 }
            if count == need { return u }
        }
        return -2
    }

    /// Applies the rules to the queued vertices until none applies or the state is infeasible.
    /// With `lexicographic`, only the rules that keep the least set, and the witness follows them.
    @inlinable
    mutating func reduce(lexicographic: Bool) {
        while !infeasible {
            if let x = forced.popLast() {
                guard dominators[x] == 0 else { continue }
                var y = state[x] == 0 ? x : -1
                if y < 0 {
                    for k in offsets[x] ..< offsets[x + 1] where state[neighbors[k]] == 0 {
                        y = neighbors[k]
                        break
                    }
                }
                guard y >= 0 else {
                    infeasible = true
                    break
                }
                if lexicographic { witness[y] = true }
                take(y)
                continue
            }
            if let v = checks.popLast() {
                guard state[v] == 0 else { continue }
                let u = dominance(v, lexicographic: lexicographic)
                guard u != -2 else { continue }
                if lexicographic && witness[v] {
                    witness[v] = false
                    if u >= 0 { witness[u] = true }
                }
                forbid(v)
                continue
            }
            break
        }
        forced.removeAll(keepingCapacity: true)
        checks.removeAll(keepingCapacity: true)
    }

    /// A 2-packing of the undominated vertices, greedy with the fewest allowed dominators first;
    /// stops past `limit`.
    @inlinable
    mutating func packing(limit: Int) -> Int {
        var top = 0
        for i in 0 ..< open {
            let a = allowed[undominated[i]]
            histogram[a] += 1
            top = max(top, a)
        }
        var sum = 0
        for a in 0 ... top {
            let h = histogram[a]
            histogram[a] = sum
            sum += h
        }
        for i in 0 ..< open {
            let x = undominated[i]
            sorted[histogram[allowed[x]]] = x
            histogram[allowed[x]] += 1
        }
        for a in 0 ... top { histogram[a] = 0 }
        stamp += 1
        var count = 0
        for i in 0 ..< open {
            let x = sorted[i]
            var free = state[x] != 0 || mark[x] != stamp
            if free {
                for k in offsets[x] ..< offsets[x + 1] where state[neighbors[k]] == 0 && mark[neighbors[k]] == stamp {
                    free = false
                    break
                }
            }
            guard free else { continue }
            count += 1
            if count > limit { return count }
            if state[x] == 0 { mark[x] = stamp }
            for k in offsets[x] ..< offsets[x + 1] where state[neighbors[k]] == 0 { mark[neighbors[k]] = stamp }
        }
        return count
    }

    /// The node's verdict: 1 when everything is dominated, −1 when it fails, 0 when it branches
    /// (on `branch`).
    @inlinable
    mutating func status() -> Int {
        if infeasible || chosen > budget { return -1 }
        if open == 0 { return 1 }
        let left = budget - chosen
        if left == 0 { return -1 }
        if left < open {
            if left * (topDegree + 1) < open { return -1 }
            // The coverages of the allowed vertices next to the undominated ones (all of them lie
            // in `scope`), whichever way is shorter to list.
            var top = 0
            let candidates = scoped ? scope.count : members.count
            if candidates <= 4 * open {
                for i in 0 ..< candidates {
                    let y = scoped ? scope[i] : members[i]
                    guard state[y] == 0 && coverage[y] > 0 else { continue }
                    histogram[coverage[y]] += 1
                    top = max(top, coverage[y])
                }
            } else {
                stamp += 1
                for i in 0 ..< open {
                    let x = undominated[i]
                    var k = offsets[x] - 1
                    while k < offsets[x + 1] {
                        let y = k < offsets[x] ? x : neighbors[k]
                        k += 1
                        guard state[y] == 0 && mark[y] != stamp else { continue }
                        mark[y] = stamp
                        histogram[coverage[y]] += 1
                        top = max(top, coverage[y])
                    }
                }
            }
            var sum = 0, rest = left, c = top
            while c > 0 && rest > 0 {
                let t = min(rest, histogram[c])
                sum += t * c
                rest -= t
                c -= 1
            }
            for c in 0 ... top { histogram[c] = 0 }
            if sum < open { return -1 }
            if packing(limit: left) > left { return -1 }
        }
        var x = -1, fewest = Int.max
        for i in 0 ..< open {
            let u = undominated[i]
            if allowed[u] < fewest || (allowed[u] == fewest && u < x) {
                fewest = allowed[u]
                x = u
            }
        }
        var w = -1, most = -1
        var k = offsets[x] - 1
        while k < offsets[x + 1] {
            let y = k < offsets[x] ? x : neighbors[k]
            k += 1
            guard state[y] == 0 else { continue }
            if coverage[y] > most || (coverage[y] == most && y < w) {
                most = coverage[y]
                w = y
            }
        }
        branch = w
        return 0
    }

    /// Whether at most `budget` chosen vertices in all, none forbidden, complete the current state.
    /// With `scoped`, the undominated vertices are those of one part (`gather`) and `scope` lists
    /// its allowed vertices, else `members` stands for them. The state is left as it was; on success `picks` holds the
    /// vertices the search chose on top of it.
    @inlinable
    mutating func decide(budget: Int, scoped: Bool) -> Bool {
        self.budget = budget
        self.scoped = scoped
        let base = trail.count
        for i in 0 ..< (scoped ? scope.count : members.count) {
            let v = scoped ? scope[i] : members[i]
            if state[v] == 0 { checks.append(v) }
        }
        reduce(lexicographic: false)
        var verdict = status()
        frames.removeAll(keepingCapacity: true)
        while true {
            if verdict == 1 {
                picks.removeAll(keepingCapacity: true)
                for i in base ..< trail.count where trail[i] & 1 == 0 { picks.append(trail[i] >> 1) }
                undo(to: base)
                return true
            }
            if verdict == -1 {
                // Back to the newest branch still in its first half.
                while let last = frames.last, last == 1 { frames.removeLast(3) }
                guard !frames.isEmpty else {
                    undo(to: base)
                    return false
                }
                let f = frames.count - 3
                frames[f + 2] = 1
                undo(to: frames[f])
                forbid(frames[f + 1])
                reduce(lexicographic: false)
                verdict = status()
                continue
            }
            frames.append(trail.count)
            frames.append(branch)
            frames.append(0)
            take(branch)
            reduce(lexicographic: false)
            verdict = status()
        }
    }

    /// The part of the problem v (allowed) belongs to: the undominated vertices and allowed
    /// dominators reachable from v, alternating, through closed neighbourhoods. Its undominated
    /// vertices move to the front of `undominated` (their count is returned), its allowed ones go
    /// to `scope`. Nothing outside it interacts with a choice inside it.
    @inlinable
    mutating func gather(_ v: Int) -> Int {
        stamp += 1
        scope.removeAll(keepingCapacity: true)
        scope.append(v)
        reached[v] = stamp
        var front = 0, head = 0
        while head < scope.count {
            let w = scope[head]
            head += 1
            var k = offsets[w] - 1
            while k < offsets[w + 1] {
                let x = k < offsets[w] ? w : neighbors[k]
                k += 1
                guard dominators[x] == 0 && mark[x] != stamp else { continue }
                mark[x] = stamp
                let i = position[x], y = undominated[front]
                undominated[front] = x
                position[x] = front
                undominated[i] = y
                position[y] = i
                front += 1
                var j = offsets[x] - 1
                while j < offsets[x + 1] {
                    let u = j < offsets[x] ? x : neighbors[j]
                    j += 1
                    guard state[u] == 0 && reached[u] != stamp else { continue }
                    reached[u] = stamp
                    scope.append(u)
                }
            }
        }
        return front
    }

    /// The least minimum dominating set of the component `members` (ascending numbers, at least
    /// two, none adjacent to all the others), flagged in `inSet`. The lexicographic rules run first; γ comes from a first `decide` with no budget
    /// (a greedy descent), then decisions with one fewer until one fails or the 2-packing bound is
    /// met. The least set is then decided vertex by vertex in ascending number, with a witness W (a
    /// minimum completion of the choices so far): v is chosen when it is in W, forbidden when it
    /// dominates nothing new, and otherwise decided on v's part of the problem alone (`gather`),
    /// whose share of W is its least completion: v is chosen when choosing it still leaves a
    /// completion of that size there (which becomes W's share), else forbidden. The lexicographic
    /// rules run after each.
    @inlinable
    mutating func solve(_ component: [Int], into inSet: inout [Bool]) {
        members = component
        topDegree = 0
        for (i, v) in component.enumerated() {
            topDegree = max(topDegree, offsets[v + 1] - offsets[v])
            let d = offsets[v + 1] - offsets[v] + 1
            state[v] = 0
            dominators[v] = 0
            allowed[v] = d
            coverage[v] = d
            undominated[i] = v
            position[v] = i
            witness[v] = false
        }
        open = component.count
        chosen = 0
        trail.removeAll(keepingCapacity: true)
        infeasible = false
        checks.append(contentsOf: component.reversed())
        reduce(lexicographic: true)
        if open > 0 {
            _ = decide(budget: Int.max, scoped: false)
            var gamma = chosen + picks.count
            for v in picks { witness[v] = true }
            let lower = chosen + packing(limit: Int.max)
            while gamma > lower && decide(budget: gamma - 1, scoped: false) {
                gamma = chosen + picks.count
                for v in members { witness[v] = false }
                for v in picks { witness[v] = true }
            }
            for v in component {
                guard open > 0 else { break }
                guard state[v] == 0 else { continue }
                if witness[v] {
                    take(v)
                    reduce(lexicographic: true)
                    continue
                }
                if coverage[v] == 0 {
                    forbid(v)
                    reduce(lexicographic: true)
                    continue
                }
                // Decide on v's part alone, the rest of the undominated list hidden past `open`.
                let size = gather(v), hidden = open - size
                var need = 0
                for w in scope where witness[w] { need += 1 }
                open = size
                let before = trail.count, earlier = chosen
                take(v)
                let success = decide(budget: earlier + need, scoped: true)
                if success {
                    for w in scope { witness[w] = false }
                    for w in picks { witness[w] = true }
                    witness[v] = true
                } else {
                    undo(to: before)
                }
                // Bring the hidden block back next to the open prefix: v's newly dominated
                // vertices sit between them, and their order no longer matters.
                let moved = size - open, swaps = min(moved, hidden)
                for i in 0 ..< swaps {
                    let a = open + i, b = size + hidden - 1 - i
                    let x = undominated[a], y = undominated[b]
                    undominated[a] = y
                    position[y] = a
                    undominated[b] = x
                    position[x] = b
                }
                open += hidden
                if success {
                    // The lexicographic rules see the vertices v's choice changed.
                    for k in offsets[v] ..< offsets[v + 1] {
                        let x = neighbors[k]
                        if state[x] == 0 { checks.append(x) }
                        for j in offsets[x] ..< offsets[x + 1] where state[neighbors[j]] == 0 { checks.append(neighbors[j]) }
                    }
                } else {
                    forbid(v)
                }
                reduce(lexicographic: true)
            }
        }
        for v in component where state[v] == 2 { inSet[v] = true }
    }
}

/// Minimum dominating sets of one dense component (see `_minimumDominatingSet`), on bitset closed
/// neighbourhoods over local indices (the component's vertices in ascending number), where a
/// node's bookkeeping is word operations rather than the Δ² neighbour visits of a choice in
/// `_DominatingSetSearch`. The decision search is iterative: a node branches over the allowed
/// dominators of an undominated vertex with the fewest of them (most new coverage first), and
/// each tried dominator is forbidden to its later siblings. It prunes when some undominated
/// vertex has no allowed dominator left, and when the budget times the greatest new coverage is
/// less than the number undominated. Flat stacks: a node allocates nothing once they have grown.
@frozen
@usableFromInline
struct _DenseDominatingSetSearch {
    @usableFromInline var local: [Int]
    @usableFromInline var vertices: [Int] = []
    @usableFromInline var words = 0
    /// N[i] per local index, flat.
    @usableFromInline var closed: [UInt64] = []
    @usableFromInline var full: [UInt64] = []
    /// Per depth, flat: the dominated vertices, the forbidden dominators, the dominators left to try.
    @usableFromInline var dominated: [UInt64] = []
    @usableFromInline var forbidden: [UInt64] = []
    @usableFromInline var candidates: [UInt64] = []
    @usableFromInline var picks: [Int] = []

    @inlinable
    init(count n: Int) {
        local = [Int](repeating: -1, count: n)
    }

    /// Sets up the component `members` (ascending numbers).
    @inlinable
    mutating func load(_ g: _CoveringGraph, _ members: [Int]) {
        for u in vertices { local[u] = -1 }
        vertices = members
        for (i, u) in members.enumerated() { local[u] = i }
        let p = members.count
        words = (p + 63) >> 6
        closed.removeAll(keepingCapacity: true)
        closed.append(contentsOf: repeatElement(0, count: p * words))
        for (i, u) in members.enumerated() {
            closed[i * words + i >> 6] |= 1 << UInt64(i & 63)
            for k in g.offsets[u] ..< g.offsets[u + 1] {
                let j = local[g.neighbors[k]]
                closed[i * words + j >> 6] |= 1 << UInt64(j & 63)
            }
        }
        full = [UInt64](repeating: 0, count: words)
        for i in 0 ..< p { full[i >> 6] |= 1 << UInt64(i & 63) }
    }

    /// How many vertices of N[w] are not in the dominated set at `base`.
    @inlinable
    func coverage(_ w: Int, at base: Int) -> Int {
        var count = 0
        for k in 0 ..< words { count += (closed[w * words + k] & ~dominated[base + k]).nonzeroBitCount }
        return count
    }

    /// Examines the node at `depth`: 1 when everything is dominated, −1 when it is pruned, 0 when
    /// it branches (its dominators to try are pushed on `candidates`).
    @inlinable
    mutating func open(depth: Int, budget: Int) -> Int {
        let base = depth * words
        var undominated = 0
        for k in 0 ..< words { undominated += (full[k] & ~dominated[base + k]).nonzeroBitCount }
        if undominated == 0 { return 1 }
        let remaining = budget - depth
        if remaining <= 0 { return -1 }
        var target = -1, fewest = Int.max
        for k in 0 ..< words {
            var bits = full[k] & ~dominated[base + k]
            while bits != 0 {
                let u = k << 6 | bits.trailingZeroBitCount
                bits &= bits - 1
                var count = 0
                for j in 0 ..< words { count += (closed[u * words + j] & ~forbidden[base + j]).nonzeroBitCount }
                if count == 0 { return -1 }
                if count < fewest {
                    fewest = count
                    target = u
                }
            }
        }
        var most = 0
        for k in 0 ..< words {
            var bits = full[k] & ~forbidden[base + k]
            while bits != 0 {
                let w = k << 6 | bits.trailingZeroBitCount
                bits &= bits - 1
                most = max(most, coverage(w, at: base))
            }
        }
        if most * remaining < undominated { return -1 }
        for k in 0 ..< words { candidates.append(closed[target * words + k] & ~forbidden[base + k]) }
        return 0
    }

    /// Whether at most `budget` dominators, none forbidden, complete the dominated set; the first
    /// `words` of `dominated` and `forbidden` hold the start. On success `picks` holds them.
    @inlinable
    mutating func decide(budget: Int) -> Bool {
        dominated.removeLast(dominated.count - words)
        forbidden.removeLast(forbidden.count - words)
        candidates.removeAll(keepingCapacity: true)
        picks.removeAll(keepingCapacity: true)
        let status = open(depth: 0, budget: budget)
        if status != 0 { return status == 1 }
        while candidates.count > 0 {
            let depth = candidates.count / words - 1
            let base = depth * words
            // The candidate with the most new coverage, the least index on ties.
            var w = -1, most = -1
            for k in 0 ..< words {
                var bits = candidates[base + k]
                while bits != 0 {
                    let x = k << 6 | bits.trailingZeroBitCount
                    bits &= bits - 1
                    let c = coverage(x, at: base)
                    if c > most {
                        most = c
                        w = x
                    }
                }
            }
            if w < 0 {
                if depth == 0 { return false }
                candidates.removeLast(words)
                dominated.removeLast(words)
                forbidden.removeLast(words)
                picks.removeLast()
                continue
            }
            candidates[base + w >> 6] &= ~(1 << UInt64(w & 63))
            forbidden[base + w >> 6] |= 1 << UInt64(w & 63)
            for k in 0 ..< words {
                dominated.append(dominated[base + k] | closed[w * words + k])
                forbidden.append(forbidden[base + k])
            }
            picks.append(w)
            let child = open(depth: depth + 1, budget: budget)
            if child == 1 { return true }
            if child == -1 {
                dominated.removeLast(words)
                forbidden.removeLast(words)
                picks.removeLast()
            }
        }
        return false
    }

    /// The least minimum dominating set of the loaded component, flagged in `inSet`. γ: the greedy
    /// set (most new coverage, least index) as a start, then decisions with one fewer until one
    /// fails. The least set is decided vertex by vertex in ascending number, with a witness as in
    /// `_DominatingSetSearch.solve`.
    @inlinable
    mutating func solve(into inSet: inout [Bool]) {
        let p = vertices.count
        dominated = [UInt64](repeating: 0, count: words)
        forbidden = [UInt64](repeating: 0, count: words)
        var witness: [Int] = []
        while dominated != full {
            var w = -1, most = 0
            for x in 0 ..< p {
                let c = coverage(x, at: 0)
                if c > most {
                    most = c
                    w = x
                }
            }
            witness.append(w)
            for k in 0 ..< words { dominated[k] |= closed[w * words + k] }
        }
        while true {
            for k in 0 ..< words {
                dominated[k] = 0
                forbidden[k] = 0
            }
            guard witness.count > 1, decide(budget: witness.count - 1) else { break }
            witness = picks
        }
        var inWitness = [UInt64](repeating: 0, count: words)
        for i in witness { inWitness[i >> 6] |= 1 << UInt64(i & 63) }
        var start = [UInt64](repeating: 0, count: words)
        var excluded = [UInt64](repeating: 0, count: words)
        var need = witness.count
        for v in 0 ..< p {
            guard need > 0 else { break }
            let word = v >> 6, bit: UInt64 = 1 << UInt64(v & 63)
            var take = inWitness[word] & bit != 0
            if !take {
                for k in 0 ..< words {
                    dominated[k] = start[k] | closed[v * words + k]
                    forbidden[k] = excluded[k]
                }
                if decide(budget: need - 1) {
                    take = true
                    for k in 0 ..< words { inWitness[k] = 0 }
                    inWitness[word] |= bit
                    for i in picks { inWitness[i >> 6] |= 1 << UInt64(i & 63) }
                }
            }
            if take {
                inSet[vertices[v]] = true
                need -= 1
                for k in 0 ..< words { start[k] |= closed[v * words + k] }
            } else {
                excluded[word] |= bit
            }
        }
    }
}

/// The lexicographically least minimum dominating set, flags by vertex number: per connected
/// component (loops ignored), isolated vertices and components with a vertex adjacent to all the
/// others directly, the rest by `_DominatingSetSearch` or, when dense, `_DenseDominatingSetSearch`.
@inlinable
func _minimumDominatingSet(_ g: _CoveringGraph) -> [Bool] {
    let n = g.count
    var inSet = [Bool](repeating: false, count: n)
    let (order, starts) = _dominationComponents(g)
    var search: _DominatingSetSearch?
    var dense: _DenseDominatingSetSearch?
    var members: [Int] = []
    for c in 0 ..< starts.count - 1 {
        let p = starts[c + 1] - starts[c]
        if p == 1 {
            inSet[order[starts[c]]] = true
            continue
        }
        members.removeAll(keepingCapacity: true)
        members.append(contentsOf: order[starts[c] ..< starts[c + 1]])
        members.sort()
        // A vertex adjacent to all the others answers alone (the least such).
        var ends = 0, universal = -1
        for u in members {
            let d = g.offsets[u + 1] - g.offsets[u]
            ends += d
            if universal < 0 && d == p - 1 { universal = u }
        }
        if universal >= 0 {
            inSet[universal] = true
            continue
        }
        // Bitset rows when the mean degree d satisfies d² > p ⌈p / 64⌉: a choice then costs more in
        // neighbour visits than a node costs in words, and the rows (p ⌈p / 64⌉ < 2m words) stay
        // within the edges' size.
        let words = (p + 63) >> 6
        if ends * ends > p * p * p * words {
            if dense == nil { dense = _DenseDominatingSetSearch(count: n) }
            dense!.load(g, members)
            dense!.solve(into: &inSet)
        } else {
            if search == nil { search = _DominatingSetSearch(g) }
            search!.solve(members, into: &inSet)
        }
    }
    return inSet
}

// MARK: - Entry points

extension Graph {
    /// A maximum independent set (exact): of all the largest ones, the lexicographically least by
    /// vertex index, in `vertices` order; [] for the empty graph. Of two sets of one size, the
    /// lesser holds the least vertex of their symmetric difference (`maximumClique()`'s rule, so
    /// on a loop-free graph this is `maximumClique()` of the complement). A vertex with a
    /// self-loop is never in it; parallel edges count once.
    ///
    /// Looped vertices are removed and each connected component solved alone, since the rule
    /// composes across components. A bipartite component costs O(m √n): a maximum matching
    /// (Hopcroft–Karp), the alternating reach from its free vertices (König), and one greedy pass
    /// over the perfectly matched core in index order along the Dulmage–Mendelsohn implications.
    /// A complete component takes its least vertex. Any other component of c vertices is decided
    /// vertex by vertex in index order against a witness maximum set, shrunk between decisions by
    /// rules that keep the least set (an isolated vertex is taken; so is a simplicial vertex, such
    /// as a leaf, less than all its neighbours), with pieces that turn bipartite or complete
    /// handed to the cases above. Each decision the witness cannot answer computes α of what is
    /// left of the vertex's component by the degree-0, -1 and -2 reductions (taking a leaf,
    /// folding a degree-2 vertex) and then, on the kernel's non-bipartite components, branch and
    /// bound on bitset rows of the complement with a greedy-colouring bound (BBMC; San Segundo et
    /// al. 2011). So trees with few extra edges, long paths and cycles cost O(c (c + m)) at worst
    /// and O(c + m) when the rules settle them; the search is exponential in the kernel's size in
    /// the worst case. Memory O(n + m + k² / 64) words for a kernel component of k vertices.
    @inlinable
    public func maximumIndependentSet() -> [Vertex] {
        _coveringVertices(flagged: _maximumIndependentSet(_coveringGraph(), lexicographic: true).inSet, _listedVertices())
    }

    /// The size of a maximum independent set, α: 0 for the empty graph. A bipartite component
    /// contributes its vertex count minus a maximum matching (König), a complete one 1, any other
    /// the reductions and kernel search of `maximumIndependentSet()` once, without its
    /// lexicographic pass: O(n + m) plus the search on what the reductions leave.
    @inlinable
    public func independenceNumber() -> Int {
        _maximumIndependentSet(_coveringGraph(), lexicographic: false).size
    }

    /// A minimum vertex cover (exact): `vertices` minus `maximumIndependentSet()`, in `vertices`
    /// order (τ = n − α, Gallai), so the minimum cover avoiding the least vertex of a symmetric
    /// difference. Every vertex with a self-loop is in it; parallel edges count once. The cost is
    /// `maximumIndependentSet()`'s: O(m √n) on bipartite components.
    @inlinable
    public func minimumVertexCover() -> [Vertex] {
        var flags = _maximumIndependentSet(_coveringGraph(), lexicographic: true).inSet
        for v in flags.indices { flags[v].toggle() }
        return _coveringVertices(flagged: flags, _listedVertices())
    }

    /// A minimum dominating set (exact): every vertex is in it or adjacent to one in it, and of
    /// the smallest such sets it is the lexicographically least by vertex index (the rule of
    /// `maximumIndependentSet()`), in `vertices` order; [] for the empty graph. Self-loops and
    /// parallel edges do not matter; isolated vertices are in it.
    ///
    /// Each connected component is solved alone; a vertex adjacent to all the others of its
    /// component answers alone. Otherwise branch and reduce: after every choice, an undominated
    /// vertex with one possible dominator gets it, and a vertex whose undominated closed
    /// neighbourhood lies in another's is ruled out (for the lexicographic pass only in favour of
    /// a lesser vertex, which keeps the least set; this leaf rule settles paths and many trees
    /// outright). The search branches on the most-coverage dominator of an undominated vertex
    /// with the fewest left and prunes on the budget, on the largest coverages, and on a greedy
    /// 2-packing (vertices with no dominator in common, each needing its own; on trees the largest
    /// 2-packing is γ, Meir and Moon 1975). γ comes from a greedy descent and decisions one
    /// smaller; the least set of γ vertices is then decided vertex by vertex in index order
    /// against a witness, each decision searching only the part of the problem the vertex
    /// touches. Sparse components keep O(n + m) words of state; dense ones (mean degree d with d²
    /// above c ⌈c / 64⌉) use bitset closed neighbourhoods, under 2m words. Exponential in the
    /// component size in the worst case.
    @inlinable
    public func minimumDominatingSet() -> [Vertex] {
        _coveringVertices(flagged: _minimumDominatingSet(_coveringGraph()), _listedVertices())
    }
}
