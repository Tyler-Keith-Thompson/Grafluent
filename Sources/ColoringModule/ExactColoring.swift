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
/// neighbour colours, then the most uncoloured neighbours, then the least number), tries its
/// allowed colours ascending, and of the colours above every one in use only the first, as they
/// are interchangeable. Neighbour colours are counted per (vertex, colour) and mirrored in a bitset
/// per vertex; the search is a flat stack of (vertex, colour tried, greatest colour before), with
/// no recursion.
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
    @usableFromInline var uncolored = 0
    @usableFromInline var frameVertex: [Int] = []
    @usableFromInline var frameColor: [Int] = []
    @usableFromInline var frameHigh: [Int] = []
    /// The global → local map, −1 outside the component.
    @usableFromInline var local: [Int]

    @inlinable
    init(count n: Int) {
        local = [Int](repeating: -1, count: n)
    }

    @inlinable
    var count: Int { rows.count }

    /// Sets up the component `members` (ascending global numbers) of `global`.
    @inlinable
    mutating func load(_ members: ArraySlice<Int>, of global: _ColoringRows) {
        for (i, u) in members.enumerated() { local[u] = i }
        var offsets = [0]
        offsets.reserveCapacity(members.count + 1)
        var neighbors: [Int] = []
        for u in members {
            for k in global.offsets[u] ..< global.offsets[u + 1] { neighbors.append(local[global.neighbors[k]]) }
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

    @inlinable @inline(__always)
    mutating func assign(_ v: Int, _ c: Int) {
        color[v] = c
        uncolored -= 1
        let word = c >> 6, bit = UInt64(1) << UInt64(c & 63)
        for i in rows.offsets[v] ..< rows.offsets[v + 1] {
            let w = rows.neighbors[i]
            let slot = w &* k &+ c
            if counts[slot] == 0 {
                masks[w &* words &+ word] |= bit
                saturation[w] += 1
            }
            counts[slot] += 1
            open[w] -= 1
        }
    }

    @inlinable @inline(__always)
    mutating func unassign(_ v: Int, _ c: Int) {
        color[v] = -1
        uncolored += 1
        let word = c >> 6, bit = UInt64(1) << UInt64(c & 63)
        for i in rows.offsets[v] ..< rows.offsets[v + 1] {
            let w = rows.neighbors[i]
            let slot = w &* k &+ c
            counts[slot] -= 1
            if counts[slot] == 0 {
                masks[w &* words &+ word] &= ~bit
                saturation[w] -= 1
            }
            open[w] += 1
        }
    }

    @inlinable @inline(__always)
    func allows(_ v: Int, _ c: Int) -> Bool {
        masks[v &* words &+ c >> 6] & (UInt64(1) << UInt64(c & 63)) == 0
    }

    /// The next colour for `v` after `after`, at most `limit`, that no neighbour holds; −1 if none.
    @inlinable
    func nextColor(_ v: Int, after: Int, limit: Int) -> Int {
        var c = after + 1
        while c <= limit {
            if allows(v, c) { return c }
            c += 1
        }
        return -1
    }

    /// Whether a proper colouring with colours `0..<colors` agrees with `preset` (a colour per
    /// local vertex, −1 for free ones); when it does, `color` holds one.
    @inlinable
    mutating func extend(_ preset: [Int], colors: Int) -> Bool {
        let p = count
        k = colors
        words = (colors + 63) >> 6
        color = [Int](repeating: -1, count: p)
        counts.removeAll(keepingCapacity: true)
        counts.append(contentsOf: repeatElement(0, count: p * colors))
        masks.removeAll(keepingCapacity: true)
        masks.append(contentsOf: repeatElement(0, count: p * words))
        saturation.removeAll(keepingCapacity: true)
        saturation.append(contentsOf: repeatElement(0, count: p))
        open.removeAll(keepingCapacity: true)
        for v in 0 ..< p { open.append(rows.degree(v)) }
        uncolored = p
        var high = -1
        for v in 0 ..< p where preset[v] >= 0 {
            let c = preset[v]
            guard c < colors, allows(v, c) else { return false }
            assign(v, c)
            high = max(high, c)
        }
        frameVertex.removeAll(keepingCapacity: true)
        frameColor.removeAll(keepingCapacity: true)
        frameHigh.removeAll(keepingCapacity: true)
        // true: choose a vertex and open a frame; false: advance the top frame.
        var descend = true
        while true {
            if descend {
                if uncolored == 0 { return true }
                var best = -1, bestSaturation = -1, bestOpen = -1
                for v in 0 ..< p where color[v] < 0 {
                    let s = saturation[v]
                    if s > bestSaturation || (s == bestSaturation && open[v] > bestOpen) {
                        best = v
                        bestSaturation = s
                        bestOpen = open[v]
                    }
                }
                if bestSaturation < colors {
                    frameVertex.append(best)
                    frameColor.append(-1)
                    frameHigh.append(high)
                }
                descend = false
                if bestSaturation >= colors {
                    // A vertex with no colour left: undo the top frame's colour, then advance it.
                    guard let top = frameVertex.last else { return false }
                    unassign(top, frameColor[frameColor.count - 1])
                    high = frameHigh[frameHigh.count - 1]
                }
                continue
            }
            guard let v = frameVertex.last else { return false }
            let t = frameVertex.count - 1
            let base = frameHigh[t]
            let c = nextColor(v, after: frameColor[t], limit: min(colors - 1, base + 1))
            if c >= 0 {
                frameColor[t] = c
                assign(v, c)
                high = max(base, c)
                descend = true
                continue
            }
            frameVertex.removeLast()
            frameColor.removeLast()
            frameHigh.removeLast()
            guard let top = frameVertex.last else { return false }
            unassign(top, frameColor[frameColor.count - 1])
            high = frameHigh[frameHigh.count - 1]
        }
    }

    /// The chromatic number of the loaded component, known not bipartite (so at least 3), with a
    /// colouring that uses that many colours. DSatur gives the upper bound, a greedy clique the
    /// lower one; each k between is decided with the clique fixed to colours `0..<q`, ascending.
    @inlinable
    mutating func chromaticNumber() -> (chi: Int, witness: [Int]) {
        let greedy = _saturationColoring(rows)
        var upper = 0
        for c in greedy where c >= upper { upper = c + 1 }
        let clique = greedyClique()
        let lower = max(3, clique.count)
        guard lower < upper else { return (upper, greedy) }
        var preset = [Int](repeating: -1, count: count)
        for (i, v) in clique.enumerated() { preset[v] = i }
        for colors in lower ..< upper where extend(preset, colors: colors) { return (colors, color) }
        return (upper, greedy)
    }

    /// The lexicographically least colouring of the loaded component with colours `0..<chi`,
    /// given a colouring `witness` with that many. First fit in index order is the least proper
    /// colouring of all, so it is the answer when it fits. Otherwise each vertex in index order
    /// takes the least colour whose prefix still extends: the witness, renumbered to agree with
    /// the prefix and grow by one colour at a time, shows that its own colour does, so only lesser
    /// colours are decided, and each success becomes the next witness.
    @inlinable
    mutating func leastColoring(chi: Int, witness: [Int]) -> [Int] {
        let p = count
        let order = Array(0 ..< p)
        let fit = _firstFit(rows, order: order)
        if !fit.contains(where: { $0 >= chi }) { return fit }
        var witness = witness
        var scratch = [Int](repeating: -1, count: chi)
        _restrictGrowth(&witness, from: 0, high: -1, scratch: &scratch)
        var preset = [Int](repeating: -1, count: p)
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
                preset[v] = c
                if extend(preset, colors: chi) {
                    witness = color
                    chosen = c
                    break
                }
            }
            preset[v] = chosen
            high = max(high, chosen)
            _restrictGrowth(&witness, from: v + 1, high: high, scratch: &scratch)
        }
        return preset
    }
}

/// χ (with `lexicographic` false) or the per-component least optimal colouring (with it), by
/// vertex number. The whole graph is tried as bipartite first (BipartiteGraphs' two-colouring,
/// whose sides are the least colouring: each component's least vertex left); otherwise each
/// component on its own: a single vertex takes 0, a bipartite one its two-colouring, and the rest
/// the search. For χ alone, a component whose DSatur bound is no more than the best so far is
/// skipped.
@inlinable
func _exactColoring(_ rows: _ColoringRows, lexicographic: Bool) -> (chi: Int, colors: [Int]) {
    let n = rows.count
    var colors = [Int](repeating: 0, count: n)
    guard n > 0 else { return (0, colors) }
    guard !rows.neighbors.isEmpty else { return (1, colors) }
    var whole = _ColoringRowSource(rows)
    if let sides = _TwoColoring(witness: false).run(count: n, edgeCount: rows.neighbors.count / 2, &whole).sides {
        for v in 0 ..< n { colors[v] = Int(sides[v]) }
        return (2, colors)
    }
    let (members, starts) = _coloringComponents(rows)
    var search = _ColoringSearch(count: n)
    var chi = 1
    for c in 0 ..< starts.count - 1 {
        let part = members[starts[c] ..< starts[c + 1]]
        guard part.count > 1 else { continue }
        search.load(part, of: rows)
        var source = _ColoringRowSource(search.rows)
        if let sides = _TwoColoring(witness: false).run(count: part.count, edgeCount: search.rows.neighbors.count / 2, &source).sides {
            for (i, v) in part.enumerated() { colors[v] = Int(sides[i]) }
            chi = max(chi, 2)
            continue
        }
        if !lexicographic {
            let greedy = _saturationColoring(search.rows)
            if greedy.max()! + 1 <= chi { continue }
        }
        let (k, witness) = search.chromaticNumber()
        chi = max(chi, k)
        guard lexicographic else { continue }
        let least = search.leastColoring(chi: k, witness: witness)
        for (i, v) in part.enumerated() { colors[v] = least[i] }
    }
    return (chi, colors)
}

extension Graph {
    /// The chromatic number χ of the simple graph (self-loops ignored, parallel edges once): the
    /// fewest colours of a proper colouring. 0 for the empty graph, 1 without edges, 2 when
    /// bipartite with an edge (BipartiteGraphs' two-colouring, O(n + m)). Otherwise the greatest
    /// over the connected components, each non-bipartite one decided by DSatur branch and bound
    /// (Brélaz 1979) between a greedy clique and greedy DSatur (Sage `chromatic_number`, JGraphT
    /// `BrownBacktrackColoring.getChromaticNumber`, Mathematica `ChromaticNumber`). Exponential in
    /// the worst case: Mycielski graphs, whose χ exceeds ω by a lot, are the hard ones.
    @inlinable
    public func chromaticNumber() -> Int {
        _exactColoring(_runOnUndirectedRows(_CopyColoringRows()), lexicographic: false).chi
    }

    /// An optimal colouring of the simple graph: on each connected component, of all its
    /// colourings with its own chromatic number of colours, the one whose colour vector (in
    /// `vertices` order) is lexicographically least. So within a component colours appear in
    /// order of first use, colour classes are numbered by their least vertex, a bipartite
    /// component is coloured by its `bipartition()` sides (left 0), and `colorCount ==
    /// chromaticNumber()`. Components are not coupled: a bipartite one keeps two colours beside a
    /// triangle. Combinatorica `MinimumVertexColoring`, Sage `vertex_coloring()`, JGraphT
    /// `BrownBacktrackColoring.getColoring`, with this tie rule. First fit in index order when it
    /// is already optimal; otherwise DSatur branch and bound per vertex prefix. Exponential in the
    /// worst case.
    @inlinable
    public func minimumColoring() -> Coloring<Self> {
        let rows = _runOnUndirectedRows(_CopyColoringRows())
        return Coloring(self, listed: _listedVertices(), colors: _exactColoring(rows, lexicographic: true).colors)
    }
}
