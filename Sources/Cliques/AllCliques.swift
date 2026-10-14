import GraphProtocols

/// Chiba–Nishizeki's listing of every clique within a size range, resumable after each clique:
/// for each vertex v in degeneracy order, the cliques whose first vertex in that order is v, grown
/// depth first from {v} by v's later neighbors (at most `degeneracy`) in ascending index, each
/// branch keeping only the candidates adjacent to everything chosen. A branch is cut when its
/// candidates cannot bring it to the least size, and not extended past the greatest. No
/// recursion: one candidate bitset per depth, over v's later neighbors.
@frozen
@usableFromInline
struct _CliqueListing: Sendable {
    @usableFromInline let order: [Int]
    @usableFromInline let laterOffsets: [Int]
    @usableFromInline let later: [Int]
    @usableFromInline let minimum: Int
    @usableFromInline let maximum: Int
    @usableFromInline var outer = 0

    // The current subproblem: v's later neighbors, ascending, and their adjacency as bitsets.
    @usableFromInline var vertex = 0
    @usableFromInline var members: [Int] = []
    @usableFromInline var local: [Int]
    @usableFromInline var words = 0
    @usableFromInline var rows: [UInt64] = []
    /// The candidates left at each depth, flat, `words` each.
    @usableFromInline var frames: [UInt64] = []
    /// The local members chosen after v.
    @usableFromInline var chosen: [Int] = []
    /// Whether the last clique reported was a leaf, whose vertex is still in `chosen`.
    @usableFromInline var leaf = false
    /// The last clique found, as vertex numbers in ascending order.
    @usableFromInline var found: [Int] = []

    @inlinable
    init(_ rows: _CompressedRows, minimum: Int, maximum: Int) {
        let n = rows.count
        order = _cores(rows).order
        var rank = [Int](repeating: 0, count: n)
        for (i, v) in order.enumerated() { rank[v] = i }
        var offsets = [Int](repeating: 0, count: n + 1)
        var later: [Int] = []
        later.reserveCapacity(rows.targets.count / 2)
        for v in 0 ..< n {
            for k in rows.offsets[v] ..< rows.offsets[v + 1] where rank[rows.targets[k]] > rank[v] { later.append(rows.targets[k]) }
            offsets[v + 1] = later.count
        }
        laterOffsets = offsets
        self.later = later
        self.minimum = minimum
        self.maximum = maximum
        local = [Int](repeating: -1, count: n)
    }

    /// Advances to the next clique, left in `found`; false when done.
    @inlinable
    mutating func next() -> Bool {
        guard minimum <= maximum else { return false }
        while true {
            if !frames.isEmpty, step() { return true }
            guard outer < order.count else { return false }
            let v = order[outer]
            outer += 1
            if start(v) { return true }
        }
    }

    /// Sets up the subproblem of `v`; true when `[v]` itself is reported (left in `found`).
    @inlinable
    mutating func start(_ v: Int) -> Bool {
        for u in members { local[u] = -1 }
        members.removeAll(keepingCapacity: true)
        let p = laterOffsets[v + 1] - laterOffsets[v]
        guard 1 + p >= minimum else { return false }
        vertex = v
        frames.removeAll(keepingCapacity: true)
        chosen.removeAll(keepingCapacity: true)
        leaf = false
        if maximum > 1, p > 0 {
            for k in laterOffsets[v] ..< laterOffsets[v + 1] { members.append(later[k]) }
            members.sort()
            for (i, u) in members.enumerated() { local[u] = i }
            words = (p + 63) >> 6
            rows.removeAll(keepingCapacity: true)
            rows.append(contentsOf: repeatElement(0, count: p * words))
            // Each edge among the members has an earlier end, whose later row holds it.
            for i in 0 ..< p {
                let u = members[i]
                for k in laterOffsets[u] ..< laterOffsets[u + 1] {
                    let j = local[later[k]]
                    guard j >= 0 else { continue }
                    rows[i * words + j >> 6] |= 1 << UInt64(j & 63)
                    rows[j * words + i >> 6] |= 1 << UInt64(i & 63)
                }
            }
            frames.append(contentsOf: repeatElement(0, count: words))
            for i in 0 ..< p { frames[i >> 6] |= 1 << UInt64(i & 63) }
        }
        guard minimum <= 1 else { return false }
        found.removeAll(keepingCapacity: true)
        found.append(v)
        return true
    }

    /// Runs the search until it reports a clique (left in `found`); false when this subproblem is
    /// done.
    @inlinable
    mutating func step() -> Bool {
        if leaf {
            chosen.removeLast()
            leaf = false
        }
        while !frames.isEmpty {
            let base = frames.count - words
            // The next branch: the lowest candidate left.
            var w = -1
            for k in 0 ..< words {
                let word = frames[base + k]
                if word != 0 {
                    w = k * 64 + word.trailingZeroBitCount
                    frames[base + k] = word & (word - 1)
                    break
                }
            }
            guard w >= 0 else {
                frames.removeLast(words)
                if !chosen.isEmpty { chosen.removeLast() }
                continue
            }
            let size = chosen.count + 2
            // The child's candidates: those left after w, adjacent to w.
            var reach = 0
            for k in 0 ..< words { reach += (frames[base + k] & rows[w * words + k]).nonzeroBitCount }
            guard size + reach >= minimum else { continue }
            chosen.append(w)
            if size < maximum, reach > 0 {
                for k in 0 ..< words { frames.append(frames[base + k] & rows[w * words + k]) }
            } else {
                leaf = true
            }
            if size >= minimum {
                found.removeAll(keepingCapacity: true)
                found.append(vertex)
                for i in chosen { found.append(members[i]) }
                found.sort()
                return true
            }
            if leaf {
                chosen.removeLast()
                leaf = false
            }
        }
        return false
    }
}

/// Every clique of an undirected graph's simple graph whose size is in a range, once each, lazily,
/// each in `vertices` order (by vertex index). The order is by the cliques' first vertex in
/// `coreNumbers().degeneracyOrdering`, then depth first, each clique followed by its extensions by
/// later vertices in ascending index. The sequence holds the graph, so iterating again gives the
/// same cliques. O(n + m) before the first clique, O(d) bitset words per clique for degeneracy d.
@frozen
public struct AllCliques<G: Graph>: Sequence {
    public typealias Element = [G.Vertex]

    @usableFromInline let graph: G
    @usableFromInline let minimum: Int
    @usableFromInline let maximum: Int

    @inlinable
    init(_ graph: G, minimum: Int, maximum: Int) {
        self.graph = graph
        self.minimum = minimum
        self.maximum = maximum
    }

    @inlinable
    public func makeIterator() -> Iterator { Iterator(graph, minimum: minimum, maximum: maximum) }

    @frozen
    public struct Iterator: IteratorProtocol {
        @usableFromInline let graph: G
        @usableFromInline let minimum: Int
        @usableFromInline let maximum: Int
        @usableFromInline var search: _CliqueListing?
        @usableFromInline var listed: [G.Vertex]?

        @inlinable
        init(_ graph: G, minimum: Int, maximum: Int) {
            self.graph = graph
            self.minimum = minimum
            self.maximum = maximum
        }

        @inlinable
        public mutating func next() -> [G.Vertex]? {
            if search == nil {
                search = _CliqueListing(graph._simpleRows(), minimum: minimum, maximum: maximum)
                listed = graph._listedVertices()
            }
            guard search!.next() else { return nil }
            return search!.found.map { graph._vertex(number: $0, listed) }
        }
    }
}

extension AllCliques: Sendable where G: Sendable {}
extension AllCliques.Iterator: Sendable where G: Sendable, G.Vertex: Sendable {}

extension Graph {
    /// Every clique whose size is in `sizes`, maximal or not, once each, lazily, each in
    /// `vertices` order; see `AllCliques` for the order. Self-loops and parallel edges are ignored,
    /// and the empty set is never listed. `allCliques(sizes: 3 ... 3)` lists the triangles,
    /// `allCliques(sizes: 1...)` every clique.
    ///
    /// - Precondition: `sizes` has no negative bound.
    @inlinable
    public func allCliques(sizes: some RangeExpression<Int>) -> AllCliques<Self> {
        let range = sizes.relative(to: 0 ..< Int.max)
        precondition(range.lowerBound >= 0, "Clique sizes must be nonnegative")
        return AllCliques(self, minimum: max(range.lowerBound, 1), maximum: range.upperBound - 1)
    }
}
