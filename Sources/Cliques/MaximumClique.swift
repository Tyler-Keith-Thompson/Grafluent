import GraphProtocols

/// A dense subproblem for maximum-clique search: candidate vertices (global numbers) and their
/// adjacency among themselves as `_MaximumCliqueSearch` rows, local indices by descending degree
/// within the subproblem (ties by the order given), the MCQ order. Its buffers are reused by every
/// subproblem.
@frozen
@usableFromInline
struct _CliqueSubproblem {
    /// Local index → vertex number.
    @usableFromInline var vertices: [Int] = []
    /// Vertex number → local index, −1 outside the subproblem.
    @usableFromInline var local: [Int]
    @usableFromInline var degree: [Int] = []
    @usableFromInline var rank: [Int] = []
    @usableFromInline var engine = _MaximumCliqueSearch()

    @inlinable
    init(count n: Int) {
        local = [Int](repeating: -1, count: n)
    }

    /// Sets up the candidates `members`, reading adjacency from later-neighbor rows (every edge
    /// among them has an earlier end, whose later row holds it).
    @inlinable
    mutating func load(_ members: [Int], laterOffsets: [Int], later: [Int]) {
        for u in vertices { local[u] = -1 }
        let p = members.count
        vertices.removeAll(keepingCapacity: true)
        for i in 0 ..< p { local[members[i]] = i }
        if p < 32 {
            // Small enough that ordering would cost more than it saves.
            vertices.append(contentsOf: members)
        } else {
            degree.removeAll(keepingCapacity: true)
            degree.append(contentsOf: repeatElement(0, count: p))
            for i in 0 ..< p {
                let u = members[i]
                for k in laterOffsets[u] ..< laterOffsets[u + 1] {
                    let j = local[later[k]]
                    guard j >= 0 else { continue }
                    degree[i] += 1
                    degree[j] += 1
                }
            }
            rank.removeAll(keepingCapacity: true)
            rank.append(contentsOf: 0 ..< p)
            rank.sort { degree[$0] != degree[$1] ? degree[$0] > degree[$1] : $0 < $1 }
            for i in rank { vertices.append(members[i]) }
            for i in 0 ..< p { local[vertices[i]] = i }
        }
        engine.reset(count: p)
        let words = engine.words
        for i in 0 ..< p {
            let u = vertices[i]
            for k in laterOffsets[u] ..< laterOffsets[u + 1] {
                let j = local[later[k]]
                guard j >= 0 else { continue }
                engine.rows[i * words + j >> 6] |= 1 << UInt64(j & 63)
                engine.rows[j * words + i >> 6] |= 1 << UInt64(i & 63)
            }
        }
    }
}

extension Graph {
    /// The size of a largest clique of the simple graph, ω: 0 for the empty graph, 1 for an
    /// edgeless one, at most `coreNumbers().degeneracy + 1`. Branch and bound in degeneracy order,
    /// each vertex's later neighbors (at most `degeneracy`, those with a high enough core number)
    /// as the candidates, one search per vertex that raises the best size as it goes, stopping at
    /// the degeneracy bound. Each search is San Segundo et al.'s BBMC on bitsets, candidates in
    /// descending degree, branching from the highest greedy colour down. Exponential in the worst
    /// case; memory O(n + m + degeneracy²).
    @inlinable
    public func cliqueNumber() -> Int { _cliqueNumber(_simpleRows()).clique.count }

    /// A largest clique of the simple graph, in `vertices` order; [] for the empty graph.
    /// Self-loops and parallel edges are ignored. Deterministic, but which largest clique it is
    /// depends on the search; for one fixed by a rule, see `lexicographicallyFirstMaximumClique()`.
    /// It is the clique `cliqueNumber()`'s search finds, so it costs the same: exponential in the
    /// worst case, memory O(n + m + degeneracy²). The search does not check for task cancellation.
    @inlinable
    public func maximumClique() -> [Vertex] {
        let listed = _listedVertices()
        return _cliqueNumber(_simpleRows()).clique.sorted().map { _vertex(number: $0, listed) }
    }

    /// The lexicographically first largest clique: of all the largest cliques, the least by vertex
    /// index, in `vertices` order; [] for the empty graph. Self-loops and parallel edges are
    /// ignored. Of two cliques of one size, the lesser is the one holding the least vertex of their
    /// symmetric difference. After `cliqueNumber()`'s search, each largest clique is searched for
    /// from its first vertex v in degeneracy order, among v's later neighbors, so memory stays O(n +
    /// m + degeneracy²) however large a hub's degree. For each v, a witness clique W (any one of
    /// the right size) guides a pass over the candidates in ascending number: a candidate in W is
    /// taken, any other is taken exactly when a search finds the rest of a clique among the common
    /// neighbors left (which then becomes W). A v whose candidates all exceed the least vertex of
    /// the best clique so far is skipped. Up to one search per vertex and candidate, each
    /// exponential in the worst case, so it can be far slower than `maximumClique()`; the search
    /// does not check for task cancellation.
    public func lexicographicallyFirstMaximumClique() -> [Vertex] {
        let rows = _simpleRows()
        let n = rows.count
        guard n > 0 else { return [] }
        let (largest, core, order, laterOffsets, later) = _cliqueNumber(rows)
        let omega = largest.count
        let listed = _listedVertices()
        let need = omega - 1
        var sub = _CliqueSubproblem(count: n)
        var best: [Int]?
        var members: [Int] = [], chosen: [Int] = []
        var witness: [UInt64] = [], open: [UInt64] = []
        for v in order where core[v] + 1 >= omega {
            members.removeAll(keepingCapacity: true)
            for k in laterOffsets[v] ..< laterOffsets[v + 1] where core[later[k]] + 1 >= omega { members.append(later[k]) }
            guard members.count >= need else { continue }
            members.sort()
            // Every clique through v then lies above the best clique's least vertex.
            if let current = best, min(v, members.first ?? v) > current[0] { continue }
            sub.load(members, laterOffsets: laterOffsets, later: later)
            guard sub.engine.maximum(floor: need - 1, target: need) >= need else { continue }
            let words = sub.engine.words
            witness.removeAll(keepingCapacity: true)
            witness.append(contentsOf: repeatElement(0, count: words))
            for i in sub.engine.best { witness[i >> 6] |= 1 << UInt64(i & 63) }
            // `open`: the candidates adjacent to every chosen one, not yet decided.
            open.removeAll(keepingCapacity: true)
            open.append(contentsOf: repeatElement(0, count: words))
            for i in 0 ..< members.count { open[i >> 6] |= 1 << UInt64(i & 63) }
            chosen.removeAll(keepingCapacity: true)
            for u in members where chosen.count < need {
                let i = sub.local[u], bit: UInt64 = 1 << UInt64(i & 63)
                guard open[i >> 6] & bit != 0 else { continue }
                open[i >> 6] &= ~bit
                var take = witness[i >> 6] & bit != 0
                if !take {
                    let rest = need - chosen.count - 1
                    var reach = 0
                    for k in 0 ..< words {
                        let x = open[k] & sub.engine.rows[i * words + k]
                        sub.engine.start[k] = x
                        reach += x.nonzeroBitCount
                    }
                    if reach >= rest && (rest == 0 || sub.engine.search(floor: rest - 1, target: rest) >= rest) {
                        take = true
                        for k in 0 ..< words { witness[k] = 0 }
                        if rest > 0 {
                            for j in sub.engine.best { witness[j >> 6] |= 1 << UInt64(j & 63) }
                        }
                    }
                }
                guard take else { continue }
                chosen.append(u)
                for k in 0 ..< words { open[k] &= sub.engine.rows[i * words + k] }
            }
            // The least clique through v: v and the least set of the rest (by the same rule).
            let candidate = ([v] + chosen).sorted()
            if let current = best {
                if candidate.lexicographicallyPrecedes(current) { best = candidate }
            } else {
                best = candidate
            }
        }
        guard let clique = best else { preconditionFailure("A clique of the clique number exists") }
        return clique.map { _vertex(number: $0, listed) }
    }
}

/// A largest clique of the simple graph `rows` (vertex numbers, in no particular order), or the
/// first clique of `target` vertices found; with the core numbers, the degeneracy order and the
/// later-neighbor rows. Branch and bound in degeneracy order: each vertex's later neighbors with a
/// high enough core number are a `_CliqueSubproblem`, searched by BBMC for a clique bigger than
/// the best so far, stopping at the degeneracy bound.
@inlinable
package func _cliqueNumber(_ rows: _CompressedRows, target: Int = .max) -> (clique: [Int], core: [Int], order: [Int], laterOffsets: [Int], later: [Int]) {
    let n = rows.count
    guard n > 0 else { return ([], [], [], [0], []) }
    let (core, order) = _cores(rows)
    var rank = [Int](repeating: 0, count: n)
    for (i, v) in order.enumerated() { rank[v] = i }
    var laterOffsets = [Int](repeating: 0, count: n + 1)
    var later: [Int] = []
    for v in 0 ..< n {
        for k in rows.offsets[v] ..< rows.offsets[v + 1] where rank[rows.targets[k]] > rank[v] { later.append(rows.targets[k]) }
        laterOffsets[v + 1] = later.count
    }
    let ceiling = min(core.max()! + 1, target)
    var clique = [order[0]]
    var sub = _CliqueSubproblem(count: n)
    var members: [Int] = []
    for v in order where clique.count < ceiling && core[v] + 1 > clique.count {
        // A clique through v bigger than the best needs that many later members of core at least
        // that.
        let best = clique.count
        members.removeAll(keepingCapacity: true)
        for k in laterOffsets[v] ..< laterOffsets[v + 1] where core[later[k]] >= best { members.append(later[k]) }
        guard members.count >= best else { continue }
        sub.load(members, laterOffsets: laterOffsets, later: later)
        if sub.engine.maximum(floor: best - 1, target: ceiling - 1) + 1 > best {
            clique.removeAll(keepingCapacity: true)
            clique.append(v)
            for i in sub.engine.best { clique.append(sub.vertices[i]) }
        }
    }
    return (clique, core, order, laterOffsets, later)
}
