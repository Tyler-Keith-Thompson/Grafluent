import GraphProtocols

/// A dense subproblem for maximum-clique search: candidate vertices (global numbers, ascending)
/// and their adjacency among themselves as bitset rows, with scratch buffers reused by every
/// search, so a search node allocates nothing.
@frozen
@usableFromInline
struct _CliqueSubproblem {
    @usableFromInline var vertices: [Int] = []
    @usableFromInline var words = 0
    @usableFromInline var adjacency: [UInt64] = []
    @usableFromInline var local: [Int]
    /// The search stack: one candidate set per depth, flat.
    @usableFromInline var stack: [UInt64] = []
    @usableFromInline var next: [Int] = []
    @usableFromInline var chosen: [Int] = []
    @usableFromInline var uncolored: [UInt64] = []
    @usableFromInline var candidates: [UInt64] = []

    @inlinable
    init(count n: Int) {
        local = [Int](repeating: -1, count: n)
    }

    /// Sets up the candidates `members`, filling adjacency from later-neighbor rows (every edge
    /// among them has an earlier end, whose later row holds it).
    @inlinable
    mutating func load(_ members: [Int], laterOffsets: [Int], later: [Int]) {
        for u in vertices { local[u] = -1 }
        vertices = members.sorted()
        for (i, u) in vertices.enumerated() { local[u] = i }
        let p = vertices.count
        words = (p + 63) >> 6
        adjacency.removeAll(keepingCapacity: true)
        adjacency.append(contentsOf: repeatElement(0, count: p * words))
        for (i, u) in vertices.enumerated() {
            for k in laterOffsets[u] ..< laterOffsets[u + 1] {
                let j = local[later[k]]
                guard j >= 0 else { continue }
                adjacency[i * words + j >> 6] |= 1 << UInt64(j & 63)
                adjacency[j * words + i >> 6] |= 1 << UInt64(i & 63)
            }
        }
    }

    /// The number of colors a greedy coloring of the stack's set at `base` uses (each color class
    /// an independent set, filled in ascending index): an upper bound on a clique inside it.
    @inlinable
    mutating func colorBound(at base: Int) -> Int {
        uncolored.removeAll(keepingCapacity: true)
        uncolored.append(contentsOf: stack[base ..< base + words])
        if candidates.count != words { candidates = [UInt64](repeating: 0, count: words) }
        var colors = 0
        while uncolored.contains(where: { $0 != 0 }) {
            colors += 1
            for k in 0 ..< words { candidates[k] = uncolored[k] }
            for k in 0 ..< words {
                while candidates[k] != 0 {
                    let i = k * 64 + candidates[k].trailingZeroBitCount
                    candidates[k] &= candidates[k] - 1
                    uncolored[k] &= ~(1 << UInt64(i & 63))
                    // Its neighbors cannot share its color.
                    for j in 0 ..< words { candidates[j] &= ~adjacency[i * words + j] }
                }
            }
        }
        return colors
    }

    @inlinable
    func popcount(at base: Int) -> Int {
        var count = 0
        for k in 0 ..< words { count += stack[base + k].nonzeroBitCount }
        return count
    }

    /// Searches the candidates in ascending index, depth first, without recursion. With `exact`
    /// it returns the first (lexicographically least) clique of exactly that many vertices, as
    /// local indices; without, it returns the size of a largest clique bigger than `atLeast`, or
    /// `atLeast` when there is none. Branches are cut by the candidates' count, then by a greedy
    /// coloring computed once per node.
    @inlinable
    mutating func search(exact: Int?, atLeast: Int) -> (size: Int, clique: [Int]?) {
        let p = vertices.count
        var best = atLeast
        let goal = exact ?? Int.max
        if let exact, exact == 0 { return (0, []) }
        if let exact, exact > p { return (best, nil) }
        stack.removeAll(keepingCapacity: true)
        stack.append(contentsOf: repeatElement(0, count: words))
        for i in 0 ..< p { stack[i >> 6] |= 1 << UInt64(i & 63) }
        next.removeAll(keepingCapacity: true)
        chosen.removeAll(keepingCapacity: true)
        // A node is worth searching when it can reach `exact ?? best + 1` vertices.
        if colorBound(at: 0) < (exact ?? best + 1) { return (best, nil) }
        next.append(0)
        while let depth = next.indices.last {
            let base = depth * words
            var i = next[depth]
            while i < p, stack[base + i >> 6] & (1 << UInt64(i & 63)) == 0 { i += 1 }
            guard i < p, chosen.count + popcount(at: base) >= (exact ?? best + 1) else {
                stack.removeLast(words)
                next.removeLast()
                if !chosen.isEmpty { chosen.removeLast() }
                continue
            }
            next[depth] = i + 1
            // Later branches never revisit i: drop it from this node's set.
            stack[base + i >> 6] &= ~(1 << UInt64(i & 63))
            chosen.append(i)
            if exact == nil, chosen.count > best { best = chosen.count }
            if chosen.count == goal { return (goal, chosen) }
            // The child: what is left of this node's set, adjacent to i.
            stack.append(contentsOf: repeatElement(0, count: words))
            let child = base + words
            for k in 0 ..< words { stack[child + k] = stack[base + k] & adjacency[i * words + k] }
            let need = exact ?? best + 1
            if chosen.count + popcount(at: child) < need || chosen.count + colorBound(at: child) < need {
                stack.removeLast(words)
                chosen.removeLast()
                continue
            }
            next.append(0)
        }
        return (best, nil)
    }
}

extension Graph {
    /// The size of a largest clique of the simple graph, ω: 0 for the empty graph, 1 for an
    /// edgeless one, at most `coreNumbers().degeneracy + 1`. Branch and bound in degeneracy order,
    /// each vertex's later neighbors (at most `degeneracy`, those with a high enough core number)
    /// as the candidates, one search per vertex that raises the best size as it goes, pruned by
    /// counts and a greedy coloring, stopping at the degeneracy bound. Exponential in the worst
    /// case; memory O(n + m + degeneracy²).
    @inlinable
    public func cliqueNumber() -> Int { _cliqueNumber(_simpleRows()).size }

    /// The clique number, the core numbers, the degeneracy order and the later-neighbor rows.
    @inlinable
    func _cliqueNumber(_ rows: _SimpleRows) -> (size: Int, core: [Int], order: [Int], laterOffsets: [Int], later: [Int]) {
        let n = rows.count
        guard n > 0 else { return (0, [], [], [0], []) }
        let (core, order) = _cores(rows)
        var rank = [Int](repeating: 0, count: n)
        for (i, v) in order.enumerated() { rank[v] = i }
        var laterOffsets = [Int](repeating: 0, count: n + 1)
        var later: [Int] = []
        for v in 0 ..< n {
            for k in rows.offsets[v] ..< rows.offsets[v + 1] where rank[rows.neighbors[k]] > rank[v] { later.append(rows.neighbors[k]) }
            laterOffsets[v + 1] = later.count
        }
        let ceiling = core.max()! + 1
        var best = 1
        var sub = _CliqueSubproblem(count: n)
        var members: [Int] = []
        for v in order where best < ceiling && core[v] + 1 > best {
            // A clique through v bigger than best needs best later members of core at least best.
            members.removeAll(keepingCapacity: true)
            for k in laterOffsets[v] ..< laterOffsets[v + 1] where core[later[k]] >= best { members.append(later[k]) }
            guard members.count >= best else { continue }
            sub.load(members, laterOffsets: laterOffsets, later: later)
            best = max(best, sub.search(exact: nil, atLeast: best - 1).size + 1)
        }
        return (min(best, ceiling), core, order, laterOffsets, later)
    }

    /// The lexicographically least largest clique by vertex index, in `vertices` order; [] for the
    /// empty graph. Self-loops and parallel edges are ignored. Each largest clique is searched for
    /// from its first vertex in degeneracy order, among that vertex's later neighbors, so memory
    /// stays O(n + m + degeneracy²) however large a hub's degree; of two cliques of one size, the
    /// lesser is the one holding the least vertex of their symmetric difference. Exponential in the
    /// worst case.
    @inlinable
    public func maximumClique() -> [Vertex] {
        let rows = _simpleRows()
        let n = rows.count
        guard n > 0 else { return [] }
        let (omega, core, order, laterOffsets, later) = _cliqueNumber(rows)
        let listed = _listedVertices()
        var sub = _CliqueSubproblem(count: n)
        var best: [Int]?
        var members: [Int] = []
        for v in order where core[v] + 1 >= omega {
            members.removeAll(keepingCapacity: true)
            for k in laterOffsets[v] ..< laterOffsets[v + 1] where core[later[k]] + 1 >= omega { members.append(later[k]) }
            guard members.count >= omega - 1 else { continue }
            sub.load(members, laterOffsets: laterOffsets, later: later)
            // The least clique through v: v and the least set of the rest (by the same rule).
            guard let rest = sub.search(exact: omega - 1, atLeast: 0).clique else { continue }
            let candidate = ([v] + rest.map { sub.vertices[$0] }).sorted()
            if let current = best {
                let a = Set(candidate), b = Set(current)
                if let least = a.symmetricDifference(b).min(), a.contains(least) { best = candidate }
            } else {
                best = candidate
            }
        }
        guard let clique = best else { preconditionFailure("A clique of the clique number exists") }
        return clique.map { _vertex(number: $0, listed) }
    }
}
