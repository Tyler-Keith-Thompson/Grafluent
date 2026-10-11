/// Isomorphism by individualization–refinement on the disjoint union of G and H.
///
/// The partition starts from the vertex colours and is refined jointly over both graphs, so a cell
/// holds the vertices of G and of H that no refinement has told apart; every cell must hold as many
/// of each (the root check that decides most non-isomorphic pairs). A search node picks a target
/// cell (the first smallest cell with more than one vertex of each graph: VF2++'s rarest-class rule
/// on the refined classes), its G vertex u of least index, and branches on each H vertex x of the
/// cell in index order: u and x get a cell of their own, the partition is refined again, and an
/// unbalanced cell prunes the branch. An isomorphism extending the branch's mapping preserves the
/// refined partition, so no isomorphism is lost; distinct branches map u differently, so none is
/// found twice. A leaf is a partition into pairs {g, h}, equitable, so g ↦ h preserves every edge
/// multiplicity in both directions; with edge colours, which refinement compares through 64-bit
/// weights, each leaf is also checked edge by edge.
///
/// Phase 2 shape: automorphism pruning (McKay & Piperno 2014) would run this loop on one graph
/// (`_RefinementGraph` with `half == count`), keep the first leaf, turn each later leaf with the
/// same invariant into an automorphism, and skip in `levels[d]`'s candidate list every vertex in
/// the same orbit (of the pointwise stabiliser of the levels above) as a candidate already tried.
/// The candidate lists, the trail marks and the leaf extraction are the hooks.
final class _RefinementSearch: _MatchingSearch {
    struct Level {
        /// The trail length before this level's choices.
        var mark: Int
        var u: Int
        /// This level's candidates in `candidates`.
        var start: Int
        var end: Int
        var cursor: Int
    }

    let partition: _PartitionRefinement
    let n: Int
    let colors: [Int]
    /// With edge colours: both graphs, to check each leaf.
    let check: (g: _IndexGraph, h: _IndexGraph)?
    var levels: [Level] = []
    var candidates: [Int] = []
    var started = false
    var finished = false
    var scratch: [Int] = []

    init(_ g: _IndexGraph, _ h: _IndexGraph) {
        n = g.count
        let graph = _RefinementGraph(union: g, h)
        partition = _PartitionRefinement(graph)
        colors = g.vertexColors.isEmpty ? [] : g.vertexColors + h.vertexColors
        check = g.hasEdgeColors ? (g, h) : nil
        super.init()
    }

    init(copying other: _RefinementSearch) {
        n = other.n
        partition = _PartitionRefinement(copying: other.partition)
        colors = other.colors
        check = other.check
        levels = other.levels
        candidates = other.candidates
        started = other.started
        finished = other.finished
        super.init()
    }

    override func copy() -> _MatchingSearch { _RefinementSearch(copying: self) }

    override func next() -> [Int]? {
        if finished { return nil }
        if !started {
            started = true
            guard partition.start(colors: colors), partition.refine() else {
                finished = true
                return nil
            }
            if partition.cellCount == n {
                finished = true
                return leaf()
            }
            pushLevel()
        }
        while !levels.isEmpty {
            let d = levels.count - 1
            partition.undo(to: levels[d].mark)
            if levels[d].cursor == levels[d].end {
                candidates.removeLast(levels[d].end - levels[d].start)
                levels.removeLast()
                continue
            }
            let x = candidates[levels[d].cursor]
            levels[d].cursor += 1
            partition.individualize(levels[d].u, x)
            if !partition.refine() { continue }
            if partition.cellCount == n {
                if let mapping = leaf() { return mapping }
                continue
            }
            pushLevel()
        }
        finished = true
        return nil
    }

    /// Branches on the first smallest cell with more than two vertices.
    private func pushLevel() {
        let p = partition
        var best = -1, bestLength = Int.max
        var s = 0
        while s < p.count {
            let length = p.cellLength[s]
            if length > 2 && length < bestLength {
                best = s
                bestLength = length
            }
            s += length
        }
        precondition(best >= 0, "A non-discrete partition has a cell with more than two vertices")
        var u = Int.max
        let start = candidates.count
        for q in best ..< best + bestLength {
            let v = p.elements[q]
            if v < n {
                if v < u { u = v }
            } else {
                candidates.append(v)
            }
        }
        candidates.withUnsafeMutableBufferPointer { all in
            var slice = UnsafeMutableBufferPointer(rebasing: all[start...])
            slice.sort()
        }
        levels.append(Level(mark: p.trailCount, u: u, start: start, end: candidates.count, cursor: start))
    }

    /// The mapping at a discrete partition (every cell one vertex of G and one of H), or nil when
    /// edge colours tell it apart from an isomorphism.
    private func leaf() -> [Int]? {
        let p = partition
        var images = [Int](repeating: 0, count: n)
        for g in 0 ..< n {
            let c = p.cellOf[g]
            let a = p.elements[c], b = p.elements[c + 1]
            images[g] = (a == g ? b : a) - n
        }
        if let check, !_preservesColoredEdges(images, check.g, check.h, &scratch) { return nil }
        return images
    }
}

/// Whether `images` maps every out-row of `g` onto the out-row of its image in `h`, colours
/// included (rows sorted by (neighbour, colour)).
func _preservesColoredEdges(_ images: [Int], _ g: _IndexGraph, _ h: _IndexGraph, _ keys: inout [Int]) -> Bool {
    let span = max(g.outColors.max() ?? 0, h.outColors.max() ?? 0) + 1
    for v in 0 ..< g.count {
        let x = images[v]
        let start = g.outOffsets[v], end = g.outOffsets[v + 1]
        let hs = h.outOffsets[x]
        guard h.outOffsets[x + 1] - hs == end - start else { return false }
        keys.removeAll(keepingCapacity: true)
        for k in start ..< end { keys.append(images[g.outTargets[k]] &* span &+ g.outColors[k]) }
        keys.sort()
        for j in 0 ..< keys.count where keys[j] != h.outTargets[hs + j] &* span &+ h.outColors[hs + j] { return false }
    }
    return true
}
