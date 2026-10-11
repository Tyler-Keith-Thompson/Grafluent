/// One isomorphism problem in index space, immutable and shared by its searches and their copies:
/// both graphs (rows sorted), their disjoint union for the joint refinement, and the colour ids.
final class _IsomorphismData {
    let g: _IndexGraph
    let h: _IndexGraph
    let union: _RefinementGraph
    let unionColors: [Int]
    /// Exceeds every edge colour id of both graphs.
    let span: Int

    init(_ g: _IndexGraph, _ h: _IndexGraph) {
        self.g = g
        self.h = h
        union = _RefinementGraph(union: g, h)
        unionColors = g.vertexColors.isEmpty ? [] : g.vertexColors + h.vertexColors
        span = max(g.outColors.max() ?? 0, h.outColors.max() ?? 0) + 1
    }
}

/// Every isomorphism from G onto H: a first one, then the rest as that one composed with each
/// automorphism of G.
///
/// The first mapping comes from individualization–refinement on the disjoint union of G and H
/// (`_JointSearch`), which decides most pairs within a few refinements. When that search outgrows
/// its budget (pairs that refinement cannot tell apart, with many symmetric branches: strongly
/// regular graphs, CFI pairs, disjoint unions of equal components), G and H get canonical labelings
/// instead (`_AutomorphismSearch`, whose automorphism pruning keeps those families small) and the
/// pair is isomorphic exactly when the certificates agree. Every isomorphism is the first one
/// composed with an automorphism of G, so the rest of the sequence enumerates the automorphism
/// group (computed at the second element) from its stabiliser chain: O(n) per mapping.
final class _IsomorphismSearch: _MatchingSearch {
    let data: _IsomorphismData
    var first: [Int]? = nil
    /// G's search when the canonical labelings decided; its generators give the group.
    var canonicalG: _AutomorphismSearch? = nil
    var enumeration: _GroupEnumeration? = nil
    var started = false
    var finished = false

    init(_ data: _IsomorphismData) {
        self.data = data
        super.init()
    }

    init(copying other: _IsomorphismSearch) {
        data = other.data
        first = other.first
        canonicalG = other.canonicalG
        enumeration = other.enumeration
        started = other.started
        finished = other.finished
        super.init()
    }

    override func copy() -> _MatchingSearch { _IsomorphismSearch(copying: self) }

    override func next() -> [Int]? {
        if finished { return nil }
        if !started {
            started = true
            guard let images = decide() else {
                finished = true
                return nil
            }
            first = images
            return images
        }
        if enumeration == nil {
            let search = canonicalG ?? _AutomorphismSearch(data.g, colors: data.g.vertexColors, span: data.span, canonical: false, checkCancellation: true)
            canonicalG = nil
            if search.cancelled {
                finished = true
                return nil
            }
            var e = _GroupEnumeration(_PermutationGroup(n: data.g.count, base: search.base, generators: search.stabilizerChain().generators))
            _ = e.next()
            enumeration = e
        }
        guard let element = enumeration!.next(), let first else {
            finished = true
            return nil
        }
        if Task.isCancelled {
            finished = true
            return nil
        }
        return element.map { first[$0] }
    }

    /// The first isomorphism, or nil when there is none (or the task was cancelled).
    private func decide() -> [Int]? {
        let n = data.g.count
        let joint = _JointSearch(data)
        switch joint.first(budget: 64 + 2 * n) {
        case .found(let images): return images
        case .none, .cancelled: return nil
        case .overBudget: break
        }
        let gParts = data.g.components(), hParts = data.h.components()
        if gParts.count > 1 || hParts.count > 1 { return decideByComponents(gParts, hParts) }
        let g = _AutomorphismSearch(data.g, colors: data.g.vertexColors, span: data.span, canonical: true, checkCancellation: true)
        if g.cancelled { return nil }
        let h = _AutomorphismSearch(data.h, colors: data.h.vertexColors, span: data.span, canonical: true, checkCancellation: true)
        if h.cancelled || g.certificate != h.certificate { return nil }
        canonicalG = g
        var images = [Int](repeating: 0, count: n)
        for q in 0 ..< n { images[g.bestLeaf[q]] = h.bestLeaf[q] }
        return images
    }

    /// Decides a pair with more than one component (bliss's component recursion): the
    /// components must pair off by vertex and edge counts, then by canonical certificates; the
    /// first isomorphism maps each component of G onto its partner by their canonical labelings.
    private func decideByComponents(_ gParts: [_IndexGraph.Component], _ hParts: [_IndexGraph.Component]) -> [Int]? {
        guard gParts.count == hParts.count else { return nil }
        func sizes(_ parts: [_IndexGraph.Component]) -> [Int] {
            parts.map { $0.graph.count &* (data.g.edgeCount + 1) &+ $0.graph.edgeCount }.sorted()
        }
        guard sizes(gParts) == sizes(hParts) else { return nil }
        func labelings(_ parts: [_IndexGraph.Component]) -> [(certificate: [Int], leaf: [Int], vertices: [Int])]? {
            var out: [(certificate: [Int], leaf: [Int], vertices: [Int])] = []
            for part in parts {
                let search = _AutomorphismSearch(part.graph, colors: part.graph.vertexColors, span: data.span, canonical: true, checkCancellation: true)
                if search.cancelled { return nil }
                out.append(([part.graph.count] + search.certificate, search.bestLeaf, part.vertices))
            }
            out.sort { $0.certificate.lexicographicallyPrecedes($1.certificate) }
            return out
        }
        guard let a = labelings(gParts), let b = labelings(hParts) else { return nil }
        var images = [Int](repeating: 0, count: data.g.count)
        for (x, y) in zip(a, b) {
            guard x.certificate == y.certificate else { return nil }
            for q in 0 ..< x.leaf.count { images[x.vertices[x.leaf[q]]] = y.vertices[y.leaf[q]] }
        }
        return images
    }
}

/// Isomorphism by individualization–refinement on the disjoint union of G and H, up to a budget
/// of nodes.
///
/// The partition starts from the vertex colours and is refined jointly over both graphs, so a cell
/// holds the vertices of G and of H that no refinement has told apart; every cell must hold as many
/// of each (the root check that decides most non-isomorphic pairs). A search node picks a target
/// cell (the first smallest cell with more than one vertex of each graph: VF2++'s rarest-class rule
/// on the refined classes), its G vertex u of least index, and branches on each H vertex x of the
/// cell in index order: u and x get a cell of their own, the partition is refined again, and an
/// unbalanced cell prunes the branch. An isomorphism extending the branch's mapping preserves the
/// refined partition, so no isomorphism is lost. A leaf is a partition into pairs {g, h},
/// equitable, so g ↦ h preserves every edge multiplicity in both directions; with edge colours,
/// which refinement compares through 64-bit weights, each leaf is also checked edge by edge (a
/// defensive check: it fails only when two different multisets of colours have equal weight sums
/// modulo 2⁶⁴).
final class _JointSearch {
    enum Outcome {
        case found([Int])
        case none
        case overBudget
        case cancelled
    }

    struct Level {
        /// The trail length before this level's choices.
        var mark: Int
        var u: Int
        /// This level's candidates in `candidates`.
        var start: Int
        var end: Int
        var cursor: Int
    }

    let data: _IsomorphismData
    let partition: _PartitionRefinement
    let n: Int
    var levels: [Level] = []
    var candidates: [Int] = []
    var images: [Int]
    var scratch: [Int] = []

    init(_ data: _IsomorphismData) {
        self.data = data
        n = data.g.count
        partition = _PartitionRefinement(data.union)
        images = [Int](repeating: 0, count: data.g.count)
    }

    /// The first leaf that is an isomorphism, searching at most `budget` nodes.
    func first(budget: Int) -> Outcome {
        guard partition.start(colors: data.unionColors), partition.refine() else { return .none }
        if partition.isDiscrete { return leaf() ? .found(images) : .none }
        pushLevel()
        var nodes = 0, failures = 0
        while !levels.isEmpty {
            let d = levels.count - 1
            partition.undo(to: levels[d].mark)
            if levels[d].cursor == levels[d].end {
                candidates.removeLast(levels[d].end - levels[d].start)
                levels.removeLast()
                // A subtree below the first level without a leaf: refinement is not telling the
                // branches apart, the case canonical labeling handles. The second one ends the search.
                if d > 0 {
                    failures += 1
                    if failures > 1 { return .overBudget }
                }
                continue
            }
            nodes += 1
            if nodes > budget { return .overBudget }
            if nodes & 255 == 0 && Task.isCancelled { return .cancelled }
            let x = candidates[levels[d].cursor]
            levels[d].cursor += 1
            partition.individualize(levels[d].u, x)
            if !partition.refine() { continue }
            if partition.isDiscrete {
                if leaf() { return .found(images) }
                continue
            }
            pushLevel()
        }
        return .none
    }

    /// Branches on the first smallest cell with more than two vertices.
    private func pushLevel() {
        let p = partition
        let best = p.firstSmallestCell()
        let length = p.cellLength[best]
        var u = Int.max
        let start = candidates.count
        for q in best ..< best + length {
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

    /// Reads the mapping at a discrete partition (every cell one vertex of G and one of H) into
    /// `images`; false when edge colours tell it apart from an isomorphism.
    private func leaf() -> Bool {
        let p = partition
        for g in 0 ..< n {
            let c = p.cellOf[g]
            let a = p.elements[c], b = p.elements[c + 1]
            images[g] = (a == g ? b : a) - n
        }
        if data.g.hasEdgeColors { return _preservesRows(images, data.g, data.h, data.span, &scratch) }
        return true
    }
}
