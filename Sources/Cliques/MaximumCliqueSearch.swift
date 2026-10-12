/// Maximum-clique search on a dense graph held as bitset rows over local indices 0 ..< `count`
/// (row i is `rows[i * words ..< (i + 1) * words]`, bit j set when i and j are adjacent, no bit i).
/// The caller fills the rows after `reset(count:)` and chooses the local order, which is the
/// colouring order: descending degree colours well. The search is San Segundo, Rodríguez-Losada
/// and Jiménez's BBMC (2011), Tomita and Seki's MCQ (2003) on bitsets, iterative: each node
/// colours its candidates greedily in local order, branches on them from the highest colour down,
/// and stops when the chosen vertices plus the colour cannot beat the best. Scratch is reused, so a
/// node allocates nothing once the flat stacks have grown.
@frozen
@usableFromInline
package struct _MaximumCliqueSearch {
    /// The number of vertices loaded.
    @usableFromInline package var count = 0
    @usableFromInline package var words = 0
    /// The adjacency rows: `rows[i * words ..< (i + 1) * words]`.
    @usableFromInline package var rows: [UInt64] = []
    /// The set `search` starts from.
    @usableFromInline package var start: [UInt64] = []
    /// The best clique found by the last `maximum` or successful `search`, by local index.
    @usableFromInline package var best: [Int] = []
    /// The candidate set per depth, flat.
    @usableFromInline var sets: [UInt64] = []
    /// The coloured candidates per depth, flat: `order` and `colors` from `starts[d]`; `next[d]` is
    /// one past the next to branch on (they are taken from the end).
    @usableFromInline var order: [Int] = []
    @usableFromInline var colors: [Int] = []
    @usableFromInline var starts: [Int] = []
    @usableFromInline var next: [Int] = []
    @usableFromInline var chosen: [Int] = []
    @usableFromInline var uncolored: [UInt64] = []
    @usableFromInline var color: [UInt64] = []

    @inlinable
    package init() {}

    /// Makes room for `p` vertices: `rows` becomes p × `words` zero words, `start` empty.
    @inlinable
    package mutating func reset(count p: Int) {
        count = p
        words = (p + 63) >> 6
        rows.removeAll(keepingCapacity: true)
        rows.append(contentsOf: repeatElement(0, count: p * words))
        uncolored.removeAll(keepingCapacity: true)
        uncolored.append(contentsOf: repeatElement(0, count: words))
        color.removeAll(keepingCapacity: true)
        color.append(contentsOf: repeatElement(0, count: words))
        start.removeAll(keepingCapacity: true)
        start.append(contentsOf: repeatElement(0, count: words))
    }

    /// Colours the candidates at `depth` greedily (each colour class independent, filled in local
    /// order) and lists those of colour at least `least`, by colour.
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
                    // Its neighbours cannot share its colour.
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

    /// The size of a largest clique inside `start`, if it exceeds `floor` (recorded in `best`), else
    /// `floor`. Stops as soon as `target` is reached.
    @inlinable
    package mutating func search(floor: Int, target: Int) -> Int {
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

    /// A maximum clique of the loaded graph, in `best` (local indices), and its size ω; the greedy
    /// clique in local order seeds the search. With `floor` above the greedy size, only cliques
    /// larger than `floor` are looked for: the result is then ω when ω > `floor`, else the greedy
    /// size (and `best` the greedy clique). The search stops once it reaches `target`.
    @inlinable
    package mutating func maximum(floor: Int, target: Int) -> Int {
        let p = count
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
