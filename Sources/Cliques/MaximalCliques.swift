import GraphProtocols

/// What the maximal-clique search tells its caller about each Bron–Kerbosch call: nothing for
/// `MaximalCliques`, which specializes the calls away, and the calls themselves for
/// `BronKerboschEvents`.
@usableFromInline
protocol _BronKerboschObserver {
    /// A call starts on the frame at `base` of `search`'s frames; its R is `search.clique`.
    mutating func enter(_ search: _MaximalCliqueSearch, at base: Int)
    /// The outer call for `v`, whose P is empty and whose X is `search.xVertices`.
    mutating func enterAlone(_ search: _MaximalCliqueSearch, _ v: Int)
    /// The current call's pivot: member `member` of P ∪ X (P's first).
    mutating func pivot(_ search: _MaximalCliqueSearch, _ member: Int)
    /// A maximal clique, as vertex numbers in ascending order.
    mutating func report(_ clique: [Int])
    /// The current call returns.
    mutating func leave()
}

/// The observer of `MaximalCliques`.
@frozen
@usableFromInline
struct _BronKerboschSilence: _BronKerboschObserver {
    @inlinable init() {}
    @inlinable @inline(__always) func enter(_ search: _MaximalCliqueSearch, at base: Int) {}
    @inlinable @inline(__always) func enterAlone(_ search: _MaximalCliqueSearch, _ v: Int) {}
    @inlinable @inline(__always) func pivot(_ search: _MaximalCliqueSearch, _ member: Int) {}
    @inlinable @inline(__always) func report(_ clique: [Int]) {}
    @inlinable @inline(__always) func leave() {}
}

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
    @usableFromInline let rows: _CompressedRows
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
    init(_ rows: _CompressedRows) {
        self.rows = rows
        let n = rows.count
        order = _cores(rows).order
        var rank = [Int](repeating: 0, count: n)
        for (i, v) in order.enumerated() { rank[v] = i }
        self.rank = rank
        var offsets = [Int](repeating: 0, count: n + 1)
        var later: [Int] = []
        later.reserveCapacity(rows.targets.count / 2)
        for v in 0 ..< n {
            for k in rows.offsets[v] ..< rows.offsets[v + 1] where rank[rows.targets[k]] > rank[v] { later.append(rows.targets[k]) }
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
        var silence = _BronKerboschSilence()
        return next(observer: &silence)
    }

    /// Advances to the next maximal clique, telling `observer` of every call on the way.
    @inlinable
    mutating func next(observer: inout some _BronKerboschObserver) -> Bool {
        while true {
            if !current.isEmpty, step(observer: &observer) { return true }
            guard outer < order.count else { return false }
            let v = order[outer]
            outer += 1
            if start(v, observer: &observer) { return true }
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
    mutating func start(_ v: Int, observer: inout some _BronKerboschObserver) -> Bool {
        for u in pVertices { localP[u] = -1 }
        for u in xVertices { localX[u] = -1 }
        pVertices.removeAll(keepingCapacity: true)
        xVertices.removeAll(keepingCapacity: true)
        for k in laterOffsets[v] ..< laterOffsets[v + 1] { pVertices.append(later[k]) }
        for k in rows.offsets[v] ..< rows.offsets[v + 1] where rank[rows.targets[k]] < rank[v] { xVertices.append(rows.targets[k]) }
        if pVertices.isEmpty {
            observer.enterAlone(self, v)
            guard xVertices.isEmpty else {
                observer.leave()
                return false
            }
            found = [v]
            observer.report(found)
            observer.leave()
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
        observer.enter(self, at: 0)
        observer.pivot(self, choosePivot(at: 0))
        current.append(-1)
        return false
    }

    /// Fills the branch set of the frame at `base`: P minus the neighbors of the pivot, the member
    /// of P ∪ X with most neighbors in P, ties to the least vertex index. Returns the pivot's member
    /// number (P's first, then X's).
    @inlinable
    @discardableResult
    mutating func choosePivot(at base: Int) -> Int {
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
        return best
    }

    /// Runs the search until it reports a clique (left in `found`); false when this subproblem is
    /// done.
    @inlinable
    mutating func step(observer: inout some _BronKerboschObserver) -> Bool {
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
                observer.leave()
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
            observer.enter(self, at: child)
            if pEmpty {
                frames.removeLast(size)
                // A leaf: maximal exactly when nothing excluded extends it.
                if xEmpty {
                    found.removeAll(keepingCapacity: true)
                    found.append(clique[0])
                    for local in clique.dropFirst() { found.append(pVertices[local]) }
                    found.sort()
                    observer.report(found)
                    observer.leave()
                    return true
                }
                observer.leave()
                continue
            }
            observer.pivot(self, choosePivot(at: child))
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
    /// The number of the vertex every clique must contain, or nil for every maximal clique.
    @usableFromInline let containing: Int?

    @inlinable
    init(_ graph: G, containing: Int? = nil) {
        self.graph = graph
        self.containing = containing
    }

    @inlinable
    public func makeIterator() -> Iterator { Iterator(graph, containing: containing) }

    @frozen
    public struct Iterator: IteratorProtocol {
        @usableFromInline let graph: G
        @usableFromInline let containing: Int?
        @usableFromInline var search: _MaximalCliqueSearch?
        @usableFromInline var listed: [G.Vertex]?
        /// With `containing`: the neighborhood's vertices by local number, and whether the lone
        /// clique of a vertex without neighbors is still to be reported.
        @usableFromInline var members: [Int] = []
        @usableFromInline var lonely = false

        @inlinable
        init(_ graph: G, containing: Int?) {
            self.graph = graph
            self.containing = containing
        }

        @inlinable
        public mutating func next() -> [G.Vertex]? {
            if search == nil {
                let rows = graph._simpleRows()
                listed = graph._listedVertices()
                if let containing {
                    let neighborhood = _neighborhood(of: containing, rows)
                    members = neighborhood.members
                    lonely = members.isEmpty
                    search = _MaximalCliqueSearch(neighborhood.rows)
                } else {
                    search = _MaximalCliqueSearch(rows)
                }
            }
            guard let containing else {
                guard search!.next() else { return nil }
                return search!.found.map { graph._vertex(number: $0, listed) }
            }
            if lonely {
                lonely = false
                return [graph._vertex(number: containing, listed)]
            }
            guard search!.next() else { return nil }
            var clique = search!.found.map { members[$0] }
            clique.append(containing)
            clique.sort()
            return clique.map { graph._vertex(number: $0, listed) }
        }
    }
}

extension MaximalCliques: Sendable where G: Sendable {}
extension MaximalCliques.Iterator: Sendable where G: Sendable, G.Vertex: Sendable {}

extension Graph {
    /// Every maximal clique once, lazily, each in `vertices` order; see `MaximalCliques` for the
    /// order. Self-loops and parallel edges are ignored, and an isolated vertex is a clique of one.
    @inlinable
    public func maximalCliques() -> MaximalCliques<Self> { MaximalCliques(self) }

    /// The maximal cliques containing `vertex`, once each, lazily, each in `vertices` order: the
    /// maximal cliques of the subgraph its neighbors induce, in `maximalCliques()` order there,
    /// each with `vertex` added; `[vertex]` alone when it has no neighbor. Self-loops and parallel
    /// edges are ignored. O(n + m) before the first clique; memory O(n + m + degeneracy²), however
    /// many neighbors the vertex has.
    ///
    /// - Precondition: `vertex` is a vertex of the graph.
    @inlinable
    public func maximalCliques(containing vertex: Vertex) -> MaximalCliques<Self> {
        let numbers = _listedVertices().map { _vertexNumbers($0) }
        return MaximalCliques(self, containing: _vertexNumber(of: vertex, numbers, "The vertex is not in the graph"))
    }

    /// The maximal cliques containing `vertex`, throwing instead of trapping when it is not a
    /// vertex of the graph.
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not a vertex of the graph.
    @inlinable
    public func maximalCliques(checkedContaining vertex: Vertex) throws(VertexNotFound) -> MaximalCliques<Self> {
        guard contains(vertex) else { throw VertexNotFound() }
        return maximalCliques(containing: vertex)
    }
}

/// The simple subgraph induced by `v`'s neighbors, renumbered in ascending order: its rows, and
/// each local number's vertex number. O(n + Σ deg u) over the neighbors u.
@inlinable
func _neighborhood(of v: Int, _ rows: _CompressedRows) -> (rows: _CompressedRows, members: [Int]) {
    var members = Array(rows.targets[rows.offsets[v] ..< rows.offsets[v + 1]])
    members.sort()
    var local = [Int](repeating: -1, count: rows.count)
    for (i, u) in members.enumerated() { local[u] = i }
    var offsets = [Int](repeating: 0, count: members.count + 1)
    var targets: [Int] = []
    for (i, u) in members.enumerated() {
        for k in rows.offsets[u] ..< rows.offsets[u + 1] where local[rows.targets[k]] >= 0 { targets.append(local[rows.targets[k]]) }
        offsets[i + 1] = targets.count
    }
    return (_CompressedRows(offsets: offsets, targets: targets, edges: []), members)
}
