import GraphProtocols

/// Eppstein–Löffler–Strash's enumeration of maximal cliques, resumable after each clique: for each
/// vertex v in degeneracy order, Bron–Kerbosch with Tomita's pivot from R = {v}, P = v's neighbors
/// after it (at most `degeneracy`), X = those before it, so every maximal clique is found once,
/// from its first vertex in that order. Pivots maximize |P ∩ N(u)|, ties to the least vertex
/// index; branches go in ascending index. No recursion: an explicit stack of frames.
///
/// Each subproblem works on bitsets over P (ascending index, so bit order is index order) and over
/// X, kept apart: rows over P for every vertex of P ∪ X, rows over X only for P's vertices. So a
/// hub with a huge X but few later neighbors costs |P ∪ X|·|P| bits, not |P ∪ X|². The rows are
/// filled from later-neighbor rows only, at most `degeneracy` entries per member.
@frozen
@usableFromInline
struct _MaximalCliqueSearch: Sendable {
    @usableFromInline let rows: _SimpleRows
    @usableFromInline let order: [Int]
    @usableFromInline var rank: [Int]
    /// Each vertex's later neighbors in the degeneracy order: at most `degeneracy` each.
    @usableFromInline let laterOffsets: [Int]
    @usableFromInline let later: [Int]
    @usableFromInline var outer = 0

    // The current subproblem.
    @usableFromInline var pVertices: [Int] = []
    @usableFromInline var xVertices: [Int] = []
    @usableFromInline var pWords = 0
    @usableFromInline var xWords = 0
    /// For each member of P ∪ X (P first), its neighbors in P.
    @usableFromInline var rowsP: [UInt64] = []
    /// For each member of P, its neighbors in X.
    @usableFromInline var rowsX: [UInt64] = []
    @usableFromInline var localP: [Int]
    @usableFromInline var localX: [Int]

    /// Frames: P (pWords), X ∩ P (pWords), X ∩ X₀ (xWords), branches left (pWords), each flat.
    @usableFromInline var frames: [UInt64] = []
    @usableFromInline var current: [Int] = []
    /// The clique being grown: the outer vertex, then local P members.
    @usableFromInline var clique: [Int] = []
    /// The last clique found, as vertex numbers in ascending order.
    @usableFromInline var found: [Int] = []

    @inlinable
    init(_ rows: _SimpleRows) {
        self.rows = rows
        let n = rows.count
        order = _cores(rows).order
        var rank = [Int](repeating: 0, count: n)
        for (i, v) in order.enumerated() { rank[v] = i }
        self.rank = rank
        var offsets = [Int](repeating: 0, count: n + 1)
        var later: [Int] = []
        later.reserveCapacity(rows.neighbors.count / 2)
        for v in 0 ..< n {
            for k in rows.offsets[v] ..< rows.offsets[v + 1] where rank[rows.neighbors[k]] > rank[v] { later.append(rows.neighbors[k]) }
            offsets[v + 1] = later.count
        }
        laterOffsets = offsets
        self.later = later
        localP = [Int](repeating: -1, count: n)
        localX = [Int](repeating: -1, count: n)
    }

    @inlinable
    var frameSize: Int { 3 * pWords + xWords }

    /// Advances to the next maximal clique, left in `found`; false when done.
    @inlinable
    mutating func next() -> Bool {
        while true {
            if !current.isEmpty, step() { return true }
            guard outer < order.count else { return false }
            let v = order[outer]
            outer += 1
            if start(v) { return true }
        }
    }

    /// Records an edge between two members of P ∪ X in the bitset rows.
    @inlinable @inline(__always)
    mutating func link(_ a: Int, _ b: Int) {
        let p = pVertices.count
        let pa = localP[a], pb = localP[b]
        let rowA = pa >= 0 ? pa : p + localX[a]
        if pb >= 0 { rowsP[rowA * pWords + pb >> 6] |= 1 << UInt64(pb & 63) }
        if pa >= 0, pb < 0 {
            let xb = localX[b]
            rowsX[pa * xWords + xb >> 6] |= 1 << UInt64(xb & 63)
        }
    }

    /// Sets up the subproblem of `v`; true when `[v]` alone is a maximal clique (left in `found`).
    @inlinable
    mutating func start(_ v: Int) -> Bool {
        for u in pVertices { localP[u] = -1 }
        for u in xVertices { localX[u] = -1 }
        pVertices.removeAll(keepingCapacity: true)
        xVertices.removeAll(keepingCapacity: true)
        for k in laterOffsets[v] ..< laterOffsets[v + 1] { pVertices.append(later[k]) }
        for k in rows.offsets[v] ..< rows.offsets[v + 1] where rank[rows.neighbors[k]] < rank[v] { xVertices.append(rows.neighbors[k]) }
        if pVertices.isEmpty {
            guard xVertices.isEmpty else { return false }
            found = [v]
            return true
        }
        pVertices.sort()
        xVertices.sort()
        for (i, u) in pVertices.enumerated() { localP[u] = i }
        for (i, u) in xVertices.enumerated() { localX[u] = i }
        let p = pVertices.count, x = xVertices.count
        pWords = (p + 63) >> 6
        xWords = (x + 63) >> 6
        rowsP.removeAll(keepingCapacity: true)
        rowsP.append(contentsOf: repeatElement(0, count: (p + x) * pWords))
        rowsX.removeAll(keepingCapacity: true)
        rowsX.append(contentsOf: repeatElement(0, count: p * xWords))
        // Each edge among the members has an earlier end, whose later row holds it: so only later
        // rows are read, at most `degeneracy` per member, not the members' whole rows.
        for i in 0 ..< p + x {
            let u = i < p ? pVertices[i] : xVertices[i - p]
            for k in laterOffsets[u] ..< laterOffsets[u + 1] {
                let w = later[k]
                guard localP[w] >= 0 || localX[w] >= 0 else { continue }
                link(u, w)
                link(w, u)
            }
        }
        frames.removeAll(keepingCapacity: true)
        current.removeAll(keepingCapacity: true)
        clique.removeAll(keepingCapacity: true)
        clique.append(v)
        // The root frame: P all set, X ∩ P empty, X ∩ X₀ all set.
        frames.append(contentsOf: repeatElement(0, count: frameSize))
        for i in 0 ..< p { frames[i >> 6] |= 1 << UInt64(i & 63) }
        for i in 0 ..< x { frames[2 * pWords + i >> 6] |= 1 << UInt64(i & 63) }
        choosePivot(at: 0)
        current.append(-1)
        return false
    }

    /// Fills the branch set of the frame at `base`: P minus the neighbors of the pivot, the member
    /// of P ∪ X with most neighbors in P, ties to the least vertex index.
    @inlinable
    mutating func choosePivot(at base: Int) {
        let p = pVertices.count
        var best = -1, bestScore = -1, bestVertex = Int.max
        // Members of P and of X ∩ P (both over P's bits), then of X ∩ X₀.
        for half in 0 ..< 2 {
            for k in 0 ..< pWords {
                var word = frames[base + half * pWords + k]
                while word != 0 {
                    let i = k * 64 + word.trailingZeroBitCount
                    word &= word - 1
                    var score = 0
                    for j in 0 ..< pWords { score += (frames[base + j] & rowsP[i * pWords + j]).nonzeroBitCount }
                    let vertex = pVertices[i]
                    if score > bestScore || (score == bestScore && vertex < bestVertex) {
                        best = i
                        bestScore = score
                        bestVertex = vertex
                    }
                }
            }
        }
        for k in 0 ..< xWords {
            var word = frames[base + 2 * pWords + k]
            while word != 0 {
                let i = k * 64 + word.trailingZeroBitCount
                word &= word - 1
                var score = 0
                for j in 0 ..< pWords { score += (frames[base + j] & rowsP[(p + i) * pWords + j]).nonzeroBitCount }
                let vertex = xVertices[i]
                if score > bestScore || (score == bestScore && vertex < bestVertex) {
                    best = p + i
                    bestScore = score
                    bestVertex = vertex
                }
            }
        }
        for k in 0 ..< pWords { frames[base + 2 * pWords + xWords + k] = frames[base + k] & ~rowsP[best * pWords + k] }
    }

    /// Runs the search until it reports a clique (left in `found`); false when this subproblem is
    /// done.
    @inlinable
    mutating func step() -> Bool {
        let size = frameSize
        while let top = current.last {
            let base = frames.count - size
            if top >= 0 {
                // Back from branching on `top`: move it from P to X.
                frames[base + top >> 6] &= ~(1 << UInt64(top & 63))
                frames[base + pWords + top >> 6] |= 1 << UInt64(top & 63)
                clique.removeLast()
                current[current.count - 1] = -1
            }
            // The next branch: the lowest bit left.
            var w = -1
            for k in 0 ..< pWords {
                let word = frames[base + 2 * pWords + xWords + k]
                if word != 0 {
                    w = k * 64 + word.trailingZeroBitCount
                    frames[base + 2 * pWords + xWords + k] = word & (word - 1)
                    break
                }
            }
            guard w >= 0 else {
                frames.removeLast(size)
                current.removeLast()
                continue
            }
            current[current.count - 1] = w
            clique.append(w)
            // The child, written straight after the parent: P ∩ N(w), X ∩ N(w) on both halves.
            frames.append(contentsOf: repeatElement(0, count: size))
            let child = base + size
            var pEmpty = true, xEmpty = true
            for k in 0 ..< pWords {
                let row = rowsP[w * pWords + k]
                let pk = frames[base + k] & row, xk = frames[base + pWords + k] & row
                frames[child + k] = pk
                frames[child + pWords + k] = xk
                if pk != 0 { pEmpty = false }
                if xk != 0 { xEmpty = false }
            }
            for k in 0 ..< xWords {
                let xk = frames[base + 2 * pWords + k] & rowsX[w * xWords + k]
                frames[child + 2 * pWords + k] = xk
                if xk != 0 { xEmpty = false }
            }
            if pEmpty {
                frames.removeLast(size)
                // A leaf: maximal exactly when nothing excluded extends it.
                if xEmpty {
                    found.removeAll(keepingCapacity: true)
                    found.append(clique[0])
                    for local in clique.dropFirst() { found.append(pVertices[local]) }
                    found.sort()
                    return true
                }
                continue
            }
            choosePivot(at: child)
            current.append(-1)
        }
        return false
    }
}

/// Every maximal clique of an undirected graph's simple graph once, lazily, each in `vertices`
/// order (by vertex index): an isolated vertex, or one whose only edges are loops, is a clique of
/// one. The order is Eppstein–Löffler–Strash's: by the cliques' first vertex in
/// `coreNumbers().degeneracyOrdering`, then as Bron–Kerbosch with Tomita's pivot (ties to the least
/// index) and branches in ascending index meets them. The sequence holds the graph, so iterating
/// again gives the same cliques. O(n + m) before the first clique, O(d·n·3^(d/3)) in all for
/// degeneracy d.
@frozen
public struct MaximalCliques<G: Graph>: Sequence {
    public typealias Element = [G.Vertex]

    @usableFromInline let graph: G

    @inlinable
    init(_ graph: G) {
        self.graph = graph
    }

    @inlinable
    public func makeIterator() -> Iterator { Iterator(graph) }

    @frozen
    public struct Iterator: IteratorProtocol {
        @usableFromInline let graph: G
        @usableFromInline var search: _MaximalCliqueSearch?
        @usableFromInline var listed: [G.Vertex]?

        @inlinable
        init(_ graph: G) {
            self.graph = graph
        }

        @inlinable
        public mutating func next() -> [G.Vertex]? {
            if search == nil {
                search = _MaximalCliqueSearch(graph._simpleRows())
                listed = graph._listedVertices()
            }
            guard search!.next() else { return nil }
            return search!.found.map { graph._vertex(number: $0, listed) }
        }
    }
}

extension MaximalCliques: Sendable where G: Sendable {}
extension MaximalCliques.Iterator: Sendable where G: Sendable, G.Vertex: Sendable {}

extension Graph {
    /// Every maximal clique once, lazily, each in `vertices` order; see `MaximalCliques` for the
    /// order. Self-loops and parallel edges are ignored, and an isolated vertex is a clique of one
    /// (NetworkX `find_cliques`, igraph `maximal_cliques`, JGraphT's Bron–Kerbosch finders).
    @inlinable
    public func maximalCliques() -> MaximalCliques<Self> { MaximalCliques(self) }
}
