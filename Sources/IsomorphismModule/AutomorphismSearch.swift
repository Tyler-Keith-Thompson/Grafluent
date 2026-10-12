/// The automorphism group of one graph, and optionally its canonical labeling, by
/// individualization–refinement with automorphism pruning (McKay 1981; McKay & Piperno 2014, nauty
/// and Traces; Junttila & Kaski 2007, bliss).
///
/// The search tree: the root is the equitable refinement of the colour partition; a node
/// individualizes each vertex of its target cell (the first largest cell) in turn and refines
/// again; a leaf is a discrete partition, read as an ordering of the vertices. The refinement is
/// label-invariant, and each node carries the sequence of events its refinement made (running
/// hashes of the splits, `trace`); a node's invariant is its path's event sequences, compared
/// lexicographically.
///
/// - The first leaf found fixes the base (the vertices individualized on its path). A later leaf
///   whose path has the first path's events is compared with the first leaf: the permutation
///   taking one ordering to the other is checked edge by edge, and if it is an automorphism it is
///   kept as a generator and the search jumps back to where the two paths part (the subtree is an
///   image of one already searched).
/// - Orbit pruning: a node skips each candidate that an automorphism found so far, fixing the
///   node's individualized vertices, maps onto a smaller candidate. Candidates go in increasing
///   order, so the smaller one was searched or skipped for the same reason.
/// - Without canonical labeling, a node whose events differ from the first path's is pruned, and
///   its refinement stops at the first differing event (bliss's early abort): no leaf below it is
///   the image of the first leaf.
/// - With canonical labeling, the canonical leaf is the greatest by (the events along its path,
///   its certificate: the graph relabelled by the leaf's ordering), both independent of the vertex
///   numbering. A node whose events are already less than the best leaf's (and differ from the
///   first leaf's) is pruned, and a leaf equal to the best one gives an automorphism.
///
/// The generators found are a strong generating set relative to the base: those fixing the first
/// i base vertices generate their pointwise stabiliser, so the orbit of base vertex i under them is
/// the basic orbit, and the group order is the product of the basic orbit lengths.
final class _AutomorphismSearch {
    struct Node {
        /// The trail length after this node's refinement.
        var mark: Int
        /// This node's candidates (its target cell, increasing) in `candidates`.
        var start: Int
        var end: Int
        var cursor: Int
        var equalsFirst: Bool
        /// The node's path against the best leaf's path: -1, 0 or 1 (0: equal events so far).
        var comparedToBest: Int
        /// How many generators the orbits of this depth have absorbed; -1 before the first.
        var absorbed: Int
    }

    let graph: _IndexGraph
    let n: Int
    let canonical: Bool
    let colors: [Int]
    let span: Int
    let simple: Bool
    let partition: _PartitionRefinement
    let checkCancellation: Bool

    /// The automorphisms found, each by vertex: its image.
    private(set) var generators: [[Int]] = []
    /// The vertices individualized on the first leaf's path.
    private(set) var base: [Int] = []
    /// The first leaf's ordering (position → vertex), then the canonical one when `canonical`.
    private(set) var firstLeaf: [Int] = []
    private(set) var bestLeaf: [Int] = []
    private var bestCertificate: [Int]? = nil
    /// Set when the search stopped for a cancelled task; the results are then incomplete.
    private(set) var cancelled = false

    private var nodes: [Node] = []
    private var candidates: [Int] = []
    /// Per depth: the events (running `trace` values) of the refinement that made the node at
    /// that depth on the current path, and on the first and best leaves' paths; a node's
    /// invariant is the sequence of its ancestors' and its own events, compared lexicographically.
    private var events: [[UInt64]] = []
    private var firstEvents: [[UInt64]] = []
    private var bestEvents: [[UInt64]] = []
    /// Per depth: the vertex individualized below the node at that depth.
    private var path: [Int] = []
    private var bestPath: [Int] = []
    /// Per depth: union–find over the node's target cell, smallest vertex as root.
    private var orbitParent: [[Int]] = []
    private var scratch: [Int] = []
    private var marks: [Int] = []
    private var stamp = 0
    private var expansions = 0

    /// `graph` with sorted rows; `colors` its vertex colour ids (empty: one class); `span`
    /// exceeds every edge colour id (the same for two graphs whose certificates are compared).
    init(_ graph: _IndexGraph, colors: [Int], span: Int, canonical: Bool, checkCancellation: Bool = false) {
        self.graph = graph
        n = graph.count
        self.canonical = canonical
        self.colors = colors
        self.span = span
        simple = graph.isSimple
        partition = _PartitionRefinement(_RefinementGraph(single: graph))
        self.checkCancellation = checkCancellation
        run()
    }

    /// The certificate of the canonical leaf: equal for two graphs (with colour ids from one
    /// table) exactly when they are isomorphic.
    var certificate: [Int] {
        if let bestCertificate { return bestCertificate }
        let c = certificate(of: bestLeaf)
        bestCertificate = c
        return c
    }

    // MARK: the search

    private func run() {
        let p = partition
        p.trace = 0
        _ = p.start(colors: colors)
        _ = p.refine()
        if p.isDiscrete {
            firstLeaf = Array(UnsafeBufferPointer(start: p.elements, count: n))
            bestLeaf = firstLeaf
            return
        }
        var haveFirst = false
        var gamma = [Int](repeating: 0, count: n)
        events = [[]]
        pushNode(equalsFirst: true, comparedToBest: 0)
        while !nodes.isEmpty {
            let d = nodes.count - 1
            p.undo(to: nodes[d].mark)
            guard let v = nextCandidate(d) else {
                candidates.removeLast(nodes[d].end - nodes[d].start)
                nodes.removeLast()
                continue
            }
            expansions += 1
            if checkCancellation && expansions & 255 == 0 && Task.isCancelled {
                cancelled = true
                return
            }
            if path.count > d { path[d] = v } else { path.append(v) }
            p.trace = 0
            let record = canonical || !haveFirst
            p.recording = record
            if record { p.recorded.removeAll(keepingCapacity: true) }
            if haveFirst {
                let parent = nodes[d]
                p.startChecking(
                    first: parent.equalsFirst && d + 1 < firstEvents.count ? firstEvents[d + 1] : nil,
                    best: canonical && parent.comparedToBest == 0 && d + 1 < bestEvents.count ? bestEvents[d + 1] : nil,
                    equalsFirst: parent.equalsFirst, comparedToBest: parent.comparedToBest, canonical: canonical)
            }
            p.individualize(v)
            // False only when the events part from the references (pruned).
            if !p.refine() { continue }
            let equalsFirst = haveFirst ? p.equalsFirst : true
            let compared = haveFirst && canonical ? p.comparedToBest : 0
            if record {
                while events.count <= d + 1 { events.append([]) }
                swap(&events[d + 1], &p.recorded)
            }
            if !p.isDiscrete {
                pushNode(equalsFirst: equalsFirst, comparedToBest: compared)
                continue
            }
            // A leaf at depth d + 1.
            let depth = d + 1
            if !haveFirst {
                haveFirst = true
                firstLeaf = Array(UnsafeBufferPointer(start: p.elements, count: n))
                bestLeaf = firstLeaf
                firstEvents = Array(events[0 ... depth])
                bestEvents = firstEvents
                base = Array(path[0 ..< depth])
                bestPath = base
                continue
            }
            if equalsFirst {
                for q in 0 ..< n { gamma[firstLeaf[q]] = p.elements[q] }
                if isAutomorphism(gamma) {
                    generators.append(gamma)
                    jumpBack(depth, to: base)
                    continue
                }
            }
            guard canonical else { continue }
            let leaf = Array(UnsafeBufferPointer(start: p.elements, count: n))
            if compared > 0 {
                setBest(leaf, depth, certificate: nil)
            } else if compared == 0 {
                let c = certificate(of: leaf)
                let order = compare(c, certificate)
                if order > 0 {
                    setBest(leaf, depth, certificate: c)
                } else if order == 0 {
                    for q in 0 ..< n { gamma[bestLeaf[q]] = leaf[q] }
                    generators.append(gamma)
                    jumpBack(depth, to: bestPath)
                }
            }
        }
    }

    private func setBest(_ leaf: [Int], _ depth: Int, certificate: [Int]?) {
        bestLeaf = leaf
        bestEvents = Array(events[0 ... depth])
        bestPath = Array(path[0 ..< depth])
        bestCertificate = certificate
        // The nodes on the stack are the new best leaf's ancestors.
        for i in nodes.indices { nodes[i].comparedToBest = 0 }
    }

    /// Pops every node below the deepest node shared by the current path (of `depth` vertices)
    /// and `other`; that node goes on with its next candidate.
    private func jumpBack(_ depth: Int, to other: [Int]) {
        var k = 0
        while k < depth && k < other.count && path[k] == other[k] { k += 1 }
        while nodes.count > k + 1 {
            let node = nodes.removeLast()
            candidates.removeLast(node.end - node.start)
        }
    }

    private func pushNode(equalsFirst: Bool, comparedToBest: Int) {
        let p = partition
        let cell = p.firstLargestCell()
        let start = candidates.count
        let length = p.cellLength[cell]
        candidates.append(contentsOf: UnsafeBufferPointer(start: p.elements + cell, count: length))
        candidates.withUnsafeMutableBufferPointer { all in
            var slice = UnsafeMutableBufferPointer(rebasing: all[start...])
            slice.sort()
        }
        nodes.append(Node(mark: p.trailCount, start: start, end: candidates.count, cursor: start, equalsFirst: equalsFirst, comparedToBest: comparedToBest, absorbed: -1))
    }

    /// The next candidate of the node at depth d that no automorphism fixing the node's path maps
    /// onto a smaller candidate, or nil.
    private func nextCandidate(_ d: Int) -> Int? {
        let start = nodes[d].start, end = nodes[d].end
        var cursor = nodes[d].cursor
        defer { nodes[d].cursor = cursor }
        if cursor == start {
            cursor += 1
            return candidates[start]
        }
        if nodes[d].absorbed < generators.count { absorb(d) }
        while cursor < end {
            let v = candidates[cursor]
            cursor += 1
            if find(d, v) == v { return v }
        }
        return nil
    }

    /// Adds to depth d's orbits the generators found since, those fixing the node's path.
    private func absorb(_ d: Int) {
        while orbitParent.count <= d { orbitParent.append([]) }
        if orbitParent[d].isEmpty { orbitParent[d] = [Int](repeating: 0, count: n) }
        let start = nodes[d].start, end = nodes[d].end
        var first = nodes[d].absorbed
        if first < 0 {
            for k in start ..< end { orbitParent[d][candidates[k]] = candidates[k] }
            first = 0
        }
        for g in first ..< generators.count {
            let gamma = generators[g]
            var fixes = true
            for i in 0 ..< d where gamma[path[i]] != path[i] {
                fixes = false
                break
            }
            if !fixes { continue }
            for k in start ..< end {
                let v = candidates[k]
                let a = find(d, v), b = find(d, gamma[v])
                if a < b { orbitParent[d][b] = a } else if b < a { orbitParent[d][a] = b }
            }
        }
        nodes[d].absorbed = generators.count
    }

    @inline(__always)
    private func find(_ d: Int, _ v: Int) -> Int {
        var x = v
        while orbitParent[d][x] != x {
            let up = orbitParent[d][orbitParent[d][x]]
            orbitParent[d][x] = up
            x = up
        }
        return x
    }

    // MARK: leaves

    /// Whether `gamma` keeps vertex colours and maps every out-row onto the row of its image.
    private func isAutomorphism(_ gamma: [Int]) -> Bool {
        if !colors.isEmpty {
            for v in 0 ..< n where colors[gamma[v]] != colors[v] { return false }
        }
        let g = graph
        if simple {
            if marks.count < n { marks = [Int](repeating: 0, count: n) }
            for v in 0 ..< n {
                let x = gamma[v]
                let start = g.outOffsets[v], end = g.outOffsets[v + 1]
                let xs = g.outOffsets[x]
                if g.outOffsets[x + 1] - xs != end - start { return false }
                stamp += 1
                for k in start ..< end { marks[gamma[g.outTargets[k]]] = stamp }
                for k in xs ..< xs + (end - start) where marks[g.outTargets[k]] != stamp { return false }
            }
            return true
        }
        return _preservesRows(gamma, g, g, span, &scratch)
    }

    /// The graph relabelled by `leaf` (position → vertex): per position, the vertex colour, the
    /// row length and the sorted row of (position of the neighbour, edge colour).
    private func certificate(of leaf: [Int]) -> [Int] {
        let g = graph
        var inverse = [Int](repeating: 0, count: n)
        for q in 0 ..< n { inverse[leaf[q]] = q }
        var out: [Int] = []
        out.reserveCapacity(2 * n + g.outTargets.count)
        var row: [Int] = []
        for q in 0 ..< n {
            let v = leaf[q]
            out.append(colors.isEmpty ? 0 : colors[v])
            let start = g.outOffsets[v], end = g.outOffsets[v + 1]
            out.append(end - start)
            row.removeAll(keepingCapacity: true)
            if g.hasEdgeColors {
                for k in start ..< end { row.append(inverse[g.outTargets[k]] &* span &+ g.outColors[k]) }
            } else {
                for k in start ..< end { row.append(inverse[g.outTargets[k]]) }
            }
            row.sort()
            out.append(contentsOf: row)
        }
        return out
    }

    private func compare(_ a: [Int], _ b: [Int]) -> Int {
        if a.count != b.count { return a.count < b.count ? -1 : 1 }
        for i in 0 ..< a.count where a[i] != b[i] { return a[i] < b[i] ? -1 : 1 }
        return 0
    }

    // MARK: results

    /// A strong generating set relative to the base, and the basic orbit lengths: for base vertex
    /// i, the size of its orbit under the generators that fix base vertices 0..<i. A generator is
    /// kept only when it joins two orbits of the generators kept before it at its level or
    /// deeper (the generators fixing the base up to the first base vertex it moves), which leaves
    /// every basic orbit, and so the group, unchanged; at most n − 1 are kept.
    func stabilizerChain() -> (generators: [[Int]], lengths: [Int]) {
        let k = base.count
        guard k > 0 else { return ([], []) }
        var byLevel = [[Int]](repeating: [], count: k)
        for (index, gamma) in generators.enumerated() {
            var i = 0
            while i < k && gamma[base[i]] == base[i] { i += 1 }
            if i < k { byLevel[i].append(index) }
        }
        var parent = Array(0 ..< n)
        func find(_ v: Int) -> Int {
            var x = v
            while parent[x] != x {
                parent[x] = parent[parent[x]]
                x = parent[x]
            }
            return x
        }
        var kept: [Int] = []
        var lengths = [Int](repeating: 1, count: k)
        for i in stride(from: k - 1, through: 0, by: -1) {
            for index in byLevel[i] {
                let gamma = generators[index]
                var joined = false
                for v in 0 ..< n {
                    let a = find(v), b = find(gamma[v])
                    if a != b {
                        parent[a] = b
                        joined = true
                    }
                }
                if joined { kept.append(index) }
            }
            let root = find(base[i])
            var size = 0
            for v in 0 ..< n where find(v) == root { size += 1 }
            lengths[i] = size
        }
        kept.sort()
        return (kept.map { generators[$0] }, lengths)
    }
}

/// Whether `images` maps every out-row of `g` onto the out-row of its image in `h`, colours
/// included (rows sorted by (neighbour, colour); `span` exceeds every edge colour id).
func _preservesRows(_ images: [Int], _ g: _IndexGraph, _ h: _IndexGraph, _ span: Int, _ keys: inout [Int]) -> Bool {
    let colored = g.hasEdgeColors
    for v in 0 ..< g.count {
        let x = images[v]
        let start = g.outOffsets[v], end = g.outOffsets[v + 1]
        let hs = h.outOffsets[x]
        guard h.outOffsets[x + 1] - hs == end - start else { return false }
        keys.removeAll(keepingCapacity: true)
        if colored {
            for k in start ..< end { keys.append(images[g.outTargets[k]] &* span &+ g.outColors[k]) }
            keys.sort()
            for j in 0 ..< keys.count where keys[j] != h.outTargets[hs + j] &* span &+ h.outColors[hs + j] { return false }
        } else {
            for k in start ..< end { keys.append(images[g.outTargets[k]]) }
            keys.sort()
            for j in 0 ..< keys.count where keys[j] != h.outTargets[hs + j] { return false }
        }
    }
    return true
}

/// A permutation group from a base and a strong generating set, with its elements enumerated
/// lazily: every element is t₀ ∘ t₁ ∘ … ∘ t_{k−1}, where t_i maps base vertex i to a point of its
/// basic orbit (Sims 1970). Immutable once built; shared by copies of an enumeration.
final class _PermutationGroup {
    let n: Int
    let base: [Int]
    let generators: [[Int]]
    /// Per level: the basic orbit's points (the base vertex first), and for each point but the
    /// first the index of its parent point and of the generator that maps the parent to it.
    let points: [[Int]]
    let parents: [[Int]]
    let labels: [[Int]]

    init(n: Int, base: [Int], generators: [[Int]]) {
        self.n = n
        self.base = base
        self.generators = generators
        var points: [[Int]] = [], parents: [[Int]] = [], labels: [[Int]] = []
        var index = [Int](repeating: -1, count: n)
        for i in 0 ..< base.count {
            let fixing = generators.indices.filter { g in (0 ..< i).allSatisfy { generators[g][base[$0]] == base[$0] } }
            var orbit = [base[i]], parent = [-1], label = [-1]
            index[base[i]] = 0
            var head = 0
            while head < orbit.count {
                let p = orbit[head]
                for g in fixing {
                    let q = generators[g][p]
                    if index[q] < 0 {
                        index[q] = orbit.count
                        orbit.append(q)
                        parent.append(head)
                        label.append(g)
                    }
                }
                head += 1
            }
            for q in orbit { index[q] = -1 }
            points.append(orbit)
            parents.append(parent)
            labels.append(label)
        }
        self.points = points
        self.parents = parents
        self.labels = labels
    }

    /// `outer ∘ t`, where t is the transversal element of level `level` for the point at `slot`.
    func compose(_ outer: [Int], level: Int, slot: Int) -> [Int] {
        var chain: [Int] = []
        var s = slot
        while s > 0 {
            chain.append(labels[level][s])
            s = parents[level][s]
        }
        if chain.isEmpty { return outer }
        var result = [Int](repeating: 0, count: n)
        for v in 0 ..< n {
            var x = v
            // t = g_chain[0] ∘ g_chain[1] ∘ …: the generator nearest the base vertex acts first.
            for g in chain.reversed() { x = generators[g][x] }
            result[v] = outer[x]
        }
        return result
    }
}

/// An odometer over the elements of a `_PermutationGroup`, the identity first.
struct _GroupEnumeration {
    let group: _PermutationGroup
    /// Per level, the slot of the chosen point.
    var digits: [Int]
    /// Per level, t₀ ∘ … ∘ t_i for the chosen digits.
    var products: [[Int]]
    var started = false
    var finished = false

    init(_ group: _PermutationGroup) {
        self.group = group
        digits = [Int](repeating: 0, count: group.base.count)
        let identity = Array(0 ..< group.n)
        products = [[Int]](repeating: identity, count: group.base.count)
    }

    /// The next element, or nil after the last.
    mutating func next() -> [Int]? {
        if finished { return nil }
        let k = digits.count
        if !started {
            started = true
            if k == 0 { finished = true }
            return Array(0 ..< group.n)
        }
        var i = k - 1
        while i >= 0 && digits[i] + 1 == group.points[i].count {
            digits[i] = 0
            i -= 1
        }
        if i < 0 {
            finished = true
            return nil
        }
        digits[i] += 1
        for j in i ..< k {
            let outer = j == 0 ? Array(0 ..< group.n) : products[j - 1]
            products[j] = group.compose(outer, level: j, slot: digits[j])
        }
        return products[k - 1]
    }
}
