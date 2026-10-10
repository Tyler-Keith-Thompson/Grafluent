import BipartiteGraphs
import GraphProtocols

/// The connected components of the simple graph, by breadth-first search from each unvisited
/// vertex in index order: component c is `members[starts[c] ..< starts[c + 1]]`, ascending. O(n + m).
@inlinable
func _coloringComponents(_ rows: _ColoringRows) -> (members: [Int], starts: [Int]) {
    let n = rows.count
    var component = [Int](repeating: -1, count: n)
    var queue = [Int](repeating: 0, count: n)
    var count = 0
    for root in 0 ..< n where component[root] < 0 {
        component[root] = count
        var head = 0, tail = 1
        queue[0] = root
        while head < tail {
            let v = queue[head]
            head += 1
            for k in rows.offsets[v] ..< rows.offsets[v + 1] where component[rows.neighbors[k]] < 0 {
                component[rows.neighbors[k]] = count
                queue[tail] = rows.neighbors[k]
                tail += 1
            }
        }
        count += 1
    }
    var starts = [Int](repeating: 0, count: count + 1)
    for c in component { starts[c + 1] += 1 }
    for c in 0 ..< count { starts[c + 1] += starts[c] }
    var fill = starts
    var members = [Int](repeating: 0, count: n)
    for v in 0 ..< n {
        members[fill[component[v]]] = v
        fill[component[v]] += 1
    }
    return (members, starts)
}

/// Renumbers the colours of `colors[from...]` above `high` by first appearance there, so the
/// vector stays proper, keeps `colors[..<from]` (which use colours up to `high` only), and grows
/// by at most one colour at a time.
@inlinable
func _restrictGrowth(_ colors: inout [Int], from: Int, high: Int, scratch: inout [Int]) {
    for c in scratch.indices { scratch[c] = -1 }
    var next = high + 1
    for v in from ..< colors.count {
        let c = colors[v]
        if c <= high { continue }
        if scratch[c] < 0 {
            scratch[c] = next
            next += 1
        }
        colors[v] = scratch[c]
    }
}

/// The exact search for one connected component, in local numbers `0..<count` (ascending global
/// order): its simple rows and the scratch every search reuses, so a search node allocates
/// nothing.
///
/// `extend(_:colors:)` is DSatur branch and bound as a decision procedure (Brélaz 1979; San
/// Segundo 2012): is there a proper colouring with colours `0..<k` agreeing with the given
/// vertices? It branches on the uncoloured vertex with the fewest colours left (the most distinct
/// neighbour colours, kept in linked lists by saturation, then the most uncoloured neighbours, then
/// the least number), tries its allowed colours ascending, and of the colours above every one in
/// use only the first, as they are interchangeable. Neighbour colours are counted per (vertex,
/// colour) and mirrored in a bitset per vertex; the search is a flat stack of (vertex, colour
/// tried, greatest colour before), with no recursion. The lexicographic pass also asks it to
/// backjump (each frame keeps the earlier frames that explain its failures), to try a given
/// colouring's colours first, and to give up after a budget.
@frozen
@usableFromInline
struct _ColoringSearch {
    @usableFromInline var rows = _ColoringRows(offsets: [0], neighbors: [])
    @usableFromInline var k = 0
    @usableFromInline var words = 0
    @usableFromInline var color: [Int] = []
    @usableFromInline var counts: [Int32] = []
    @usableFromInline var masks: [UInt64] = []
    @usableFromInline var saturation: [Int] = []
    @usableFromInline var open: [Int] = []
    /// The uncoloured vertices in doubly linked lists by saturation (`0...k`).
    @usableFromInline var bucketHead: [Int] = []
    @usableFromInline var bucketNext: [Int] = []
    @usableFromInline var bucketPrevious: [Int] = []
    @usableFromInline var uncolored = 0
    @usableFromInline var frameVertex: [Int] = []
    @usableFromInline var frameColor: [Int] = []
    @usableFromInline var frameHigh: [Int] = []
    /// Per frame, the earlier frames that explain its failed colours.
    @usableFromInline var frameConflict: [[Int]] = []
    /// The frame that coloured each vertex (−1 for a preset one), and scratch for failures.
    @usableFromInline var level: [Int] = []
    @usableFromInline var holder: [Int] = []
    @usableFromInline var failure: [Int] = []
    /// The global → local map, −1 outside the component.
    @usableFromInline var local: [Int]

    @inlinable
    init(count n: Int) {
        local = [Int](repeating: -1, count: n)
    }

    @inlinable
    var count: Int { rows.count }

    /// Sets up the subgraph that `members` (ascending numbers in `global`) induce.
    @inlinable
    mutating func load(_ members: ArraySlice<Int>, of global: _ColoringRows) {
        for (i, u) in members.enumerated() { local[u] = i }
        var offsets = [0]
        offsets.reserveCapacity(members.count + 1)
        var neighbors: [Int] = []
        for u in members {
            for k in global.offsets[u] ..< global.offsets[u + 1] where local[global.neighbors[k]] >= 0 {
                neighbors.append(local[global.neighbors[k]])
            }
            offsets.append(neighbors.count)
        }
        for u in members { local[u] = -1 }
        rows = _ColoringRows(offsets: offsets, neighbors: neighbors)
    }

    /// A clique found greedily: from each seed (every vertex, or the 64 of greatest degree in a
    /// component above 1024 vertices), its neighbours by degree descending, each taken when
    /// adjacent to all taken so far (`hits[w]` counts the taken vertices adjacent to w).
    @inlinable
    func greedyClique() -> [Int] {
        let p = count
        let order = _largestFirstOrder(rows)
        var hits = [Int](repeating: 0, count: p)
        var rank = [Int](repeating: 0, count: p)
        for (i, v) in order.enumerated() { rank[v] = i }
        var best: [Int] = []
        var clique: [Int] = []
        var candidates: [Int] = []
        let ceiling = rows.maximumDegree + 1
        for s in order.prefix(p > 1024 ? 64 : p) {
            if rows.degree(s) + 1 <= best.count { break }
            candidates.removeAll(keepingCapacity: true)
            candidates.append(contentsOf: rows.neighbors[rows.offsets[s] ..< rows.offsets[s + 1]])
            candidates.sort { rank[$0] < rank[$1] }
            clique.removeAll(keepingCapacity: true)
            clique.append(s)
            for k in rows.offsets[s] ..< rows.offsets[s + 1] { hits[rows.neighbors[k]] += 1 }
            for x in candidates where hits[x] == clique.count {
                clique.append(x)
                for k in rows.offsets[x] ..< rows.offsets[x + 1] { hits[rows.neighbors[k]] += 1 }
            }
            for y in clique {
                for k in rows.offsets[y] ..< rows.offsets[y + 1] { hits[rows.neighbors[k]] -= 1 }
            }
            if clique.count > best.count { best = clique }
            if best.count == ceiling { break }
        }
        return best.sorted()
    }

    /// Puts the uncoloured `v` at the head of its saturation's list.
    @inlinable @inline(__always)
    mutating func link(_ v: Int) {
        let s = saturation[v], head = bucketHead[s]
        bucketNext[v] = head
        bucketPrevious[v] = -1
        if head >= 0 { bucketPrevious[head] = v }
        bucketHead[s] = v
    }

    @inlinable @inline(__always)
    mutating func unlink(_ v: Int) {
        let before = bucketPrevious[v], after = bucketNext[v]
        if before >= 0 { bucketNext[before] = after } else { bucketHead[saturation[v]] = after }
        if after >= 0 { bucketPrevious[after] = before }
    }

    @inlinable @inline(__always)
    mutating func assign(_ v: Int, _ c: Int) {
        unlink(v)
        color[v] = c
        uncolored -= 1
        let word = c >> 6, bit = UInt64(1) << UInt64(c & 63)
        for i in rows.offsets[v] ..< rows.offsets[v + 1] {
            let w = rows.neighbors[i]
            let slot = w &* k &+ c
            if counts[slot] == 0 {
                masks[w &* words &+ word] |= bit
                if color[w] < 0 {
                    unlink(w)
                    saturation[w] += 1
                    link(w)
                } else {
                    saturation[w] += 1
                }
            }
            counts[slot] += 1
            open[w] -= 1
        }
    }

    @inlinable @inline(__always)
    mutating func unassign(_ v: Int, _ c: Int) {
        let word = c >> 6, bit = UInt64(1) << UInt64(c & 63)
        for i in rows.offsets[v] ..< rows.offsets[v + 1] {
            let w = rows.neighbors[i]
            let slot = w &* k &+ c
            counts[slot] -= 1
            if counts[slot] == 0 {
                masks[w &* words &+ word] &= ~bit
                if color[w] < 0 {
                    unlink(w)
                    saturation[w] -= 1
                    link(w)
                } else {
                    saturation[w] -= 1
                }
            }
            open[w] += 1
        }
        color[v] = -1
        uncolored += 1
        link(v)
    }

    @inlinable @inline(__always)
    func allows(_ v: Int, _ c: Int) -> Bool {
        masks[v &* words &+ c >> 6] & (UInt64(1) << UInt64(c & 63)) == 0
    }

    /// The next colour for `v` after `after` (−1 before the first), at most `limit`, that no
    /// neighbour holds; −1 if none. `prefer[v]`, when given, comes first, then the rest ascending.
    @inlinable
    func nextColor(_ v: Int, after: Int, limit: Int, prefer: [Int]) -> Int {
        let first = prefer.isEmpty ? -1 : prefer[v]
        if after < 0, first >= 0, first <= limit, allows(v, first) { return first }
        var c = after == first ? 0 : after + 1
        while c <= limit {
            if c != first && allows(v, c) { return c }
            c += 1
        }
        return -1
    }

    /// Whether a proper colouring with colours `0..<colors` agrees with `preset` (a colour per
    /// local vertex, −1 for free ones, the preset ones in `0..<colors` and proper among
    /// themselves); when it does, `color` holds one. Each vertex tries `prefer`'s colour first
    /// when given (a colouring to stay close to), then the others ascending.
    @inlinable
    mutating func extend(_ preset: [Int], colors: Int) -> Bool {
        extend(preset, colors: colors, prefer: [], seed: 0, budget: .max, backjumping: false)!
    }

    /// `extend(_:colors:)` with `prefer`, ties among the most constrained vertices broken by a
    /// hash of `seed` and the number instead of the number alone when `seed` is not 0, and at most
    /// `budget` colours tried: nil when they run out first.
    @inlinable
    mutating func extend(_ preset: [Int], colors: Int, prefer: [Int], seed: UInt64, budget: Int, backjumping: Bool) -> Bool? {
        let p = count
        var tries = 0
        k = colors
        words = (colors + 63) >> 6
        color.removeAll(keepingCapacity: true)
        color.append(contentsOf: repeatElement(-1, count: p))
        counts.removeAll(keepingCapacity: true)
        counts.append(contentsOf: repeatElement(0, count: p * colors))
        masks.removeAll(keepingCapacity: true)
        masks.append(contentsOf: repeatElement(0, count: p * words))
        saturation.removeAll(keepingCapacity: true)
        saturation.append(contentsOf: repeatElement(0, count: p))
        open.removeAll(keepingCapacity: true)
        for v in 0 ..< p { open.append(rows.degree(v)) }
        uncolored = p
        bucketHead.removeAll(keepingCapacity: true)
        bucketHead.append(contentsOf: repeatElement(-1, count: colors + 1))
        bucketNext.removeAll(keepingCapacity: true)
        bucketNext.append(contentsOf: repeatElement(-1, count: p))
        bucketPrevious.removeAll(keepingCapacity: true)
        bucketPrevious.append(contentsOf: repeatElement(-1, count: p))
        for v in stride(from: p - 1, through: 0, by: -1) { link(v) }
        var high = -1
        for v in 0 ..< p where preset[v] >= 0 {
            let c = preset[v]
            assign(v, c)
            high = max(high, c)
        }
        frameVertex.removeAll(keepingCapacity: true)
        frameColor.removeAll(keepingCapacity: true)
        frameHigh.removeAll(keepingCapacity: true)
        level.removeAll(keepingCapacity: true)
        level.append(contentsOf: repeatElement(-1, count: p))
        holder.removeAll(keepingCapacity: true)
        holder.append(contentsOf: repeatElement(0, count: colors))
        // true: choose a vertex and open a frame; false: advance the top frame.
        var descend = true
        while true {
            if descend {
                if uncolored == 0 { return true }
                // The highest non-empty saturation list, then the most uncoloured neighbours there.
                var bestSaturation = colors
                while bucketHead[bestSaturation] < 0 { bestSaturation -= 1 }
                descend = false
                if bestSaturation >= colors {
                    // A vertex with no colour left: back to the latest frame that took one of them.
                    failure.removeAll(keepingCapacity: true)
                    if backjumping { addBlockers(of: bucketHead[colors], limit: colors - 1) }
                    guard backjump(below: frameVertex.count, all: !backjumping) else { return false }
                    high = frameHigh[frameHigh.count - 1]
                    continue
                }
                var best = -1, bestOpen = -1, bestKey = UInt64.max
                var v = bucketHead[bestSaturation]
                while v >= 0 {
                    let key = seed == 0 ? UInt64(v) : (UInt64(v) &+ seed) &* 0x9E37_79B9_7F4A_7C15
                    if open[v] > bestOpen || (open[v] == bestOpen && key < bestKey) {
                        best = v
                        bestOpen = open[v]
                        bestKey = key
                    }
                    v = bucketNext[v]
                }
                let t = frameVertex.count
                frameVertex.append(best)
                frameColor.append(-1)
                frameHigh.append(high)
                if t == frameConflict.count {
                    frameConflict.append([])
                } else {
                    frameConflict[t].removeAll(keepingCapacity: true)
                }
                continue
            }
            let t = frameVertex.count - 1
            let v = frameVertex[t]
            let base = frameHigh[t]
            let limit = min(colors - 1, base + 1)
            let c = nextColor(v, after: frameColor[t], limit: limit, prefer: prefer)
            if c >= 0 {
                tries += 1
                if tries > budget { return nil }
                frameColor[t] = c
                level[v] = t
                assign(v, c)
                high = max(base, c)
                descend = true
                continue
            }
            // Every colour failed: the frames that explain each. The colours above `limit`, left
            // out as interchangeable with it, fail for the same frames: those frames use colours up
            // to `base` only, so swapping two colours above it maps one failed search onto the other.
            failure.removeAll(keepingCapacity: true)
            if backjumping {
                failure.append(contentsOf: frameConflict[t])
                addBlockers(of: v, limit: limit)
            }
            guard backjump(below: t, all: !backjumping) else { return false }
            high = frameHigh[frameHigh.count - 1]
        }
    }

    /// Adds to `failure`, for each colour in `0...limit` that a neighbour of `x` holds, the
    /// earliest frame holding it there; none when a preset vertex holds it.
    @inlinable
    mutating func addBlockers(of x: Int, limit: Int) {
        for c in 0 ... limit { holder[c] = Int.max }
        for i in rows.offsets[x] ..< rows.offsets[x + 1] {
            let w = rows.neighbors[i], c = color[w]
            if c >= 0 && c <= limit { holder[c] = min(holder[c], level[w]) }
        }
        for c in 0 ... limit where holder[c] >= 0 && holder[c] != Int.max { failure.append(holder[c]) }
    }

    /// Conflict-directed backjumping (Prosser 1993) after a failure that the frames in `failure`
    /// explain (all frames below `below` with `all`): pops every frame above the latest of them,
    /// undoes that one's colour and hands it the rest. False when nothing explains the failure
    /// but the presets.
    @inlinable
    mutating func backjump(below: Int, all: Bool) -> Bool {
        var j = -1
        if all {
            j = below - 1
        } else {
            for f in failure where f > j { j = f }
        }
        guard j >= 0 else { return false }
        while frameVertex.count - 1 > j {
            let v = frameVertex.removeLast(), c = frameColor.removeLast()
            frameHigh.removeLast()
            if color[v] >= 0 { unassign(v, c) }
        }
        if !all {
            failure.sort()
            var last = -1
            for f in failure where f != j && f != last {
                frameConflict[j].append(f)
                last = f
            }
        }
        unassign(frameVertex[j], frameColor[j])
        return true
    }

    /// The chromatic number of the loaded component, known not bipartite (so at least 3), with a
    /// colouring that uses that many colours; when greedy DSatur already uses no more than `floor`,
    /// its count and colouring instead (χ alone needs no better, nor does a colouring with `floor`
    /// colours). DSatur gives the upper bound, a greedy clique the lower one; each k between is
    /// decided with the clique fixed to colours `0..<q`, ascending.
    @inlinable
    mutating func chromaticNumber(above floor: Int) -> (chi: Int, witness: [Int]) {
        let greedy = _saturationColoring(rows)
        var upper = 0
        for c in greedy where c >= upper { upper = c + 1 }
        guard upper > floor else { return (upper, greedy) }
        let clique = greedyClique()
        let lower = max(3, clique.count)
        guard lower < upper else { return (upper, greedy) }
        var preset = [Int](repeating: -1, count: count)
        for (i, v) in clique.enumerated() { preset[v] = i }
        for colors in lower ..< upper {
            if extend(preset, colors: colors) { return (colors, color) }
        }
        return (upper, greedy)
    }

    /// The lexicographically least colouring of the loaded component with colours `0..<chi`,
    /// given a colouring `witness` with that many. First fit in index order is the least proper
    /// colouring of all, so it is the answer when it fits. Otherwise each vertex v in index order
    /// takes the least colour whose prefix still extends. The witness, renumbered to agree with
    /// the prefix and grow by one colour at a time, shows that its own colour does, so only lesser
    /// colours c are decided, each in up to two steps. First a Kempe swap: when the chain of v in
    /// colours c and witness[v] has no vertex before v, swapping it gives the next witness.
    /// Otherwise a search, only over the regions after v that v touches.
    @inlinable
    mutating func leastColoring(chi: Int, witness: [Int]) -> [Int] {
        let p = count
        let fit = _firstFit(rows, order: Array(0 ..< p))
        if !fit.contains(where: { $0 >= chi }) { return fit }
        var witness = witness
        var scratch = [Int](repeating: -1, count: chi)
        _restrictGrowth(&witness, from: 0, high: -1, scratch: &scratch)
        var preset = [Int](repeating: -1, count: p)
        var mark = [Int](repeating: -1, count: p)
        var stamp = 0
        var queue: [Int] = [], members: [Int] = [], boundary: [Int] = [], part: [Int] = [], hint: [Int] = []
        var reached = -1
        // Average degree at most 8.
        let sparse = rows.neighbors.count <= 8 * p
        var region = _ColoringSearch(count: p)
        var high = -1
        for v in 0 ..< p {
            var chosen = witness[v]
            for c in 0 ..< witness[v] {
                var clash = false
                for i in rows.offsets[v] ..< rows.offsets[v + 1] where preset[rows.neighbors[i]] == c {
                    clash = true
                    break
                }
                if clash { continue }
                // The Kempe chain of v in colours c and d.
                let d = witness[v]
                stamp += 1
                queue.removeAll(keepingCapacity: true)
                queue.append(v)
                mark[v] = stamp
                var head = 0, fixed = false
                while head < queue.count {
                    let x = queue[head]
                    head += 1
                    for i in rows.offsets[x] ..< rows.offsets[x + 1] {
                        let y = rows.neighbors[i]
                        if mark[y] == stamp || (witness[y] != c && witness[y] != d) { continue }
                        mark[y] = stamp
                        queue.append(y)
                    }
                    if x < v { fixed = true }
                }
                if !fixed {
                    for x in queue { witness[x] = witness[x] == c ? d : c }
                    chosen = c
                    break
                }
                // Otherwise a search over the vertices after v that v reaches through vertices
                // after v (the regions it touches), with their neighbours before v and v fixed:
                // the prefix separates the regions, so the others keep the witness's colours.
                if reached != v {
                    reached = v
                    stamp += 1
                    members.removeAll(keepingCapacity: true)
                    boundary.removeAll(keepingCapacity: true)
                    mark[v] = stamp
                    members.append(v)
                    head = 0
                    while head < members.count {
                        let x = members[head]
                        head += 1
                        for j in rows.offsets[x] ..< rows.offsets[x + 1] {
                            let y = rows.neighbors[j]
                            if mark[y] == stamp { continue }
                            mark[y] = stamp
                            if y > v { members.append(y) } else { boundary.append(y) }
                        }
                    }
                    members.append(contentsOf: boundary)
                    members.sort()
                    region.load(members[...], of: rows)
                }
                preset[v] = c
                part.removeAll(keepingCapacity: true)
                hint.removeAll(keepingCapacity: true)
                for y in members {
                    part.append(y <= v ? preset[y] : -1)
                    hint.append(witness[y])
                }
                // On a sparse component these searches have heavy tails, so there they backjump
                // and restart with growing budgets, each trying the witness's colours first, with
                // a new tie order each time. On a dense one that only repeats work.
                var round = 0, extends = false
                while true {
                    let budget = !sparse || round >= 40 ? Int.max : 256 << round
                    if let answer = region.extend(part, colors: chi, prefer: sparse ? hint : [], seed: UInt64(round), budget: budget, backjumping: sparse) {
                        extends = answer
                        break
                    }
                    round += 1
                }
                if extends {
                    for (j, y) in members.enumerated() where y > v { witness[y] = region.color[j] }
                    witness[v] = c
                    chosen = c
                    break
                }
                preset[v] = -1
            }
            preset[v] = chosen
            high = max(high, chosen)
            _restrictGrowth(&witness, from: v + 1, high: high, scratch: &scratch)
        }
        return preset
    }
}

/// What `_exactColoring` computes.
@usableFromInline
enum _ExactColoringGoal {
    /// χ alone.
    case chromaticNumber
    /// χ and a colouring with χ colours, numbered by first appearance.
    case minimumColoring
    /// χ and the per-component lexicographically first colouring with each component's χ colours.
    case lexicographicallyFirst
}

/// χ, with a colouring by vertex number for `goal`. The whole graph is tried as bipartite first
/// (BipartiteGraphs' two-colouring, whose sides are the lexicographically first colouring: each
/// component's least vertex left); otherwise each component on its own: a single vertex takes 0,
/// a bipartite one its two-colouring, and the rest the search. Except for the lexicographic goal,
/// a component whose DSatur bound is no more than the best so far keeps its DSatur colouring.
@inlinable
func _exactColoring(_ rows: _ColoringRows, goal: _ExactColoringGoal) -> (chi: Int, colors: [Int]) {
    let n = rows.count
    var colors = [Int](repeating: 0, count: n)
    guard n > 0 else { return (0, colors) }
    guard !rows.neighbors.isEmpty else { return (1, colors) }
    var whole = _ColoringRowSource(rows)
    if let sides = _TwoColoring(witness: false).run(count: n, edgeCount: rows.neighbors.count, &whole).sides {
        for v in 0 ..< n { colors[v] = Int(sides[v]) }
        return (2, colors)
    }
    let (members, starts) = _coloringComponents(rows)
    var search = _ColoringSearch(count: n)
    let lexicographic = goal == .lexicographicallyFirst
    var chi = 1
    for c in 0 ..< starts.count - 1 {
        let part = members[starts[c] ..< starts[c + 1]]
        guard part.count > 1 else { continue }
        search.load(part, of: rows)
        var source = _ColoringRowSource(search.rows)
        if let sides = _TwoColoring(witness: false).run(count: part.count, edgeCount: search.rows.neighbors.count, &source).sides {
            for (i, v) in part.enumerated() { colors[v] = Int(sides[i]) }
            continue
        }
        let (k, witness) = search.chromaticNumber(above: lexicographic ? 0 : chi)
        chi = max(chi, k)
        switch goal {
        case .chromaticNumber:
            continue
        case .minimumColoring:
            for (i, v) in part.enumerated() { colors[v] = witness[i] }
        case .lexicographicallyFirst:
            let least = search.leastColoring(chi: k, witness: witness)
            for (i, v) in part.enumerated() { colors[v] = least[i] }
        }
    }
    if goal == .minimumColoring {
        var renumbered = [Int](repeating: -1, count: chi)
        var next = 0
        for v in 0 ..< n {
            let c = colors[v]
            if renumbered[c] < 0 {
                renumbered[c] = next
                next += 1
            }
            colors[v] = renumbered[c]
        }
    }
    return (chi, colors)
}

extension Graph {
    /// The chromatic number χ of the simple graph (self-loops ignored, parallel edges once): the
    /// fewest colours of a proper colouring. 0 for the empty graph, 1 without edges, 2 when
    /// bipartite with an edge (BipartiteGraphs' two-colouring, O(n + m)). Otherwise the greatest
    /// over the connected components, each non-bipartite one decided by DSatur branch and bound
    /// (Brélaz 1979) between a greedy clique and greedy DSatur (Sage `chromatic_number`, JGraphT
    /// `BrownBacktrackColoring.getChromaticNumber`, Mathematica `VertexChromaticNumber`).
    /// Exponential in the worst case: Mycielski graphs, whose χ exceeds ω by a lot, are the hard
    /// ones. The search does not check for task cancellation.
    @inlinable
    public func chromaticNumber() -> Int {
        _exactColoring(_runOnUndirectedRows(_CopyColoringRows()), goal: .chromaticNumber).chi
    }

    /// An optimal colouring of the simple graph: `colorCount == chromaticNumber()`, with colours
    /// numbered by first appearance in `vertices` order (the first vertex has colour 0, and each
    /// colour first appears after the one below it). It is the colouring `chromaticNumber()`'s
    /// search finds, so it costs the same: a bipartite graph gets its `bipartition()` sides (left
    /// 0), and each other component the colouring that DSatur branch and bound found for it, or
    /// greedy DSatur's when that already uses no more colours than another component needs.
    /// Sage `vertex_coloring()` and JGraphT `BrownBacktrackColoring.getColoring`, which also return
    /// the optimal colouring their search finds; Mathematica `FindVertexColoring`. Deterministic, but which optimal colouring it is depends on the search; for one fixed
    /// by a rule, see `lexicographicallyFirstMinimumColoring()`. Exponential in the worst case, as
    /// `chromaticNumber()` is; the search does not check for task cancellation.
    @inlinable
    public func minimumColoring() -> Coloring<Self> {
        let numbering = _vertexNumbering()
        let rows = _runOnUndirectedRows(_CopyColoringRows(), vertexNumbering: numbering)
        return Coloring(self, numbering: numbering, colors: _exactColoring(rows, goal: .minimumColoring).colors)
    }

    /// The lexicographically first minimum colouring of the simple graph: on each connected
    /// component, of all its colourings with its own chromatic number of colours, the one whose
    /// colour vector (in `vertices` order) is lexicographically least, Khuller and Vazirani's
    /// lexicographically first k-colouring (1991) with k = the component's χ. So within a
    /// component colours appear in order of first use, colour classes are numbered by their least
    /// vertex, a bipartite component is coloured by its `bipartition()` sides (left 0), and
    /// `colorCount == chromaticNumber()`. Components are not coupled: a bipartite one keeps two
    /// colours beside a triangle.
    ///
    /// First fit in index order (the lexicographically first proper colouring of all) when it is
    /// already optimal. Otherwise each vertex in turn takes the least colour its prefix still
    /// extends with (k-colouring's self-reduction to its decision problem): a Kempe swap of the last
    /// colouring found when one avoids the prefix, else DSatur branch and bound over the parts
    /// after the prefix that the vertex touches (on sparse components with conflict-directed
    /// backjumping and restarts). Khuller and Vazirani show the lexicographically first
    /// four-colouring of a planar graph is NP-hard to find, though some four-colouring is found in
    /// polynomial time. It can be far slower than `minimumColoring()`: on random sparse
    /// 3-colourable graphs with 2n edges it took about 0.2 s at 1,000 vertices, 2.7 s at 2,000 and
    /// over 100 s at 5,000, where `minimumColoring()` takes about a millisecond. The search does not
    /// check for task cancellation.
    @inlinable
    public func lexicographicallyFirstMinimumColoring() -> Coloring<Self> {
        let numbering = _vertexNumbering()
        let rows = _runOnUndirectedRows(_CopyColoringRows(), vertexNumbering: numbering)
        return Coloring(self, numbering: numbering, colors: _exactColoring(rows, goal: .lexicographicallyFirst).colors)
    }
}
