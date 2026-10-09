import GraphProtocols

/// A dense subproblem for maximum-clique search: candidate vertices (global numbers, ascending)
/// and their adjacency among themselves as bitset rows.
@frozen
@usableFromInline
struct _CliqueSubproblem {
    @usableFromInline var vertices: [Int] = []
    @usableFromInline var words = 0
    @usableFromInline var adjacency: [UInt64] = []
    @usableFromInline var local: [Int]

    @inlinable
    init(count n: Int) {
        local = [Int](repeating: -1, count: n)
    }

    /// Sets up the candidates `members` (any order; sorted here).
    @inlinable
    mutating func load(_ members: [Int], _ rows: _SimpleRows) {
        for u in vertices { local[u] = -1 }
        vertices = members.sorted()
        for (i, u) in vertices.enumerated() { local[u] = i }
        let p = vertices.count
        words = (p + 63) >> 6
        adjacency = [UInt64](repeating: 0, count: p * words)
        for (i, u) in vertices.enumerated() {
            for k in rows.offsets[u] ..< rows.offsets[u + 1] {
                let j = local[rows.neighbors[k]]
                if j >= 0 { adjacency[i * words + j >> 6] |= 1 << UInt64(j & 63) }
            }
        }
    }

    /// The number of colors a greedy coloring of `set` uses (each color class an independent set,
    /// filled in ascending index): an upper bound on the largest clique inside it.
    @inlinable
    func colorBound(_ set: [UInt64]) -> Int {
        var uncolored = set
        var colors = 0
        while uncolored.contains(where: { $0 != 0 }) {
            colors += 1
            var candidates = uncolored
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

    /// The lexicographically least clique of exactly `size` vertices inside the candidates (local
    /// indices, ascending), searching branches in ascending index and pruning by the coloring bound;
    /// nil when there is none. No recursion.
    @inlinable
    func firstClique(of size: Int) -> [Int]? {
        let p = vertices.count
        guard size > 0 else { return [] }
        guard size <= p else { return nil }
        var all = [UInt64](repeating: 0, count: words)
        for i in 0 ..< p { all[i >> 6] |= 1 << UInt64(i & 63) }
        // Frames: the candidate set, and the next index to try in it.
        var sets: [[UInt64]] = [all]
        var next: [Int] = [0]
        var chosen: [Int] = []
        while let depth = next.indices.last {
            let set = sets[depth]
            var i = next[depth]
            while i < p, set[i >> 6] & (1 << UInt64(i & 63)) == 0 { i += 1 }
            guard i < p, chosen.count + colorBound(set) >= size else {
                sets.removeLast()
                next.removeLast()
                if !chosen.isEmpty { chosen.removeLast() }
                continue
            }
            next[depth] = i + 1
            // Later branches never revisit i: drop it from this frame's set.
            sets[depth][i >> 6] &= ~(1 << UInt64(i & 63))
            chosen.append(i)
            if chosen.count == size { return chosen }
            var child = [UInt64](repeating: 0, count: words)
            for k in 0 ..< words { child[k] = set[k] & adjacency[i * words + k] }
            child[i >> 6] &= ~(1 << UInt64(i & 63))
            sets.append(child)
            next.append(i + 1)
        }
        return nil
    }
}

extension Graph {
    /// The size of a largest clique of the simple graph, ω: 0 for the empty graph, 1 for an
    /// edgeless one, at most `coreNumbers().degeneracy + 1`. Branch and bound in degeneracy order,
    /// each vertex's later neighbors as the candidates, pruned by core numbers and a greedy
    /// coloring, stopping at the degeneracy bound. Exponential in the worst case.
    @inlinable
    public func cliqueNumber() -> Int { _cliqueNumber(_simpleRows()).size }

    @inlinable
    func _cliqueNumber(_ rows: _SimpleRows) -> (size: Int, core: [Int]) {
        let n = rows.count
        guard n > 0 else { return (0, []) }
        let (core, order) = _cores(rows)
        let ceiling = core.max()! + 1
        var rank = [Int](repeating: 0, count: n)
        for (i, v) in order.enumerated() { rank[v] = i }
        var best = 1
        var sub = _CliqueSubproblem(count: n)
        for v in order where best < ceiling && core[v] + 1 > best {
            var later: [Int] = []
            for k in rows.offsets[v] ..< rows.offsets[v + 1] where rank[rows.neighbors[k]] > rank[v] { later.append(rows.neighbors[k]) }
            guard later.count >= best else { continue }
            sub.load(later, rows)
            // Grow while a larger clique through v exists.
            while best < ceiling, sub.firstClique(of: best) != nil { best += 1 }
        }
        return (best, core)
    }

    /// The lexicographically least largest clique by vertex index, in `vertices` order; [] for the
    /// empty graph. Self-loops and parallel edges are ignored. Exponential in the worst case.
    @inlinable
    public func maximumClique() -> [Vertex] {
        let rows = _simpleRows()
        let n = rows.count
        guard n > 0 else { return [] }
        let (omega, core) = _cliqueNumber(rows)
        let listed = _listedVertices()
        var sub = _CliqueSubproblem(count: n)
        // The least vertex v that starts a clique of ω, and within it the least such clique among
        // its greater neighbors.
        for v in 0 ..< n where core[v] + 1 >= omega {
            var greater: [Int] = []
            for k in rows.offsets[v] ..< rows.offsets[v + 1] where rows.neighbors[k] > v { greater.append(rows.neighbors[k]) }
            guard greater.count >= omega - 1 else { continue }
            sub.load(greater, rows)
            if let rest = sub.firstClique(of: omega - 1) {
                return ([v] + rest.map { sub.vertices[$0] }).map { _vertex(number: $0, listed) }
            }
        }
        preconditionFailure("A clique of the clique number exists")
    }
}
