import GraphProtocols

/// Eppstein–Löffler–Strash's enumeration of maximal cliques, resumable after each clique: for each
/// vertex v in degeneracy order, Bron–Kerbosch with Tomita's pivot from R = {v}, P = v's neighbors
/// after it (at most `degeneracy`), X = those before it, so every maximal clique is found once,
/// from its first vertex in that order. Pivots maximize |P ∩ N(u)|, ties to the least vertex
/// index; branches go in ascending index. No recursion: an explicit stack of frames.
///
/// Each subproblem works on bitsets over P (ascending index, so bit order is index order) and over
/// X, kept apart: rows over P for every vertex of P ∪ X, rows over X only for P's vertices. So a
/// hub with a huge X but few later neighbors costs |P ∪ X|·|P| bits, not |P ∪ X|².
@frozen
@usableFromInline
struct _MaximalCliqueSearch: Sendable {
    @usableFromInline let rows: _SimpleRows
    @usableFromInline let order: [Int]
    @usableFromInline var rank: [Int]
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

    @inlinable
    init(_ rows: _SimpleRows) {
        self.rows = rows
        let n = rows.count
        order = _cores(rows).order
        rank = [Int](repeating: 0, count: n)
        for (i, v) in order.enumerated() { rank[v] = i }
        localP = [Int](repeating: -1, count: n)
        localX = [Int](repeating: -1, count: n)
    }

    @inlinable
    var frameSize: Int { 3 * pWords + xWords }

    @inlinable @inline(__always)
    static func test(_ words: [UInt64], _ base: Int, _ bit: Int) -> Bool {
        words[base + bit >> 6] & (1 << UInt64(bit & 63)) != 0
    }

    /// The next maximal clique, as vertex numbers in ascending order; nil when done.
    @inlinable
    mutating func next() -> [Int]? {
        while true {
            if !current.isEmpty, let clique = step() { return clique }
            guard outer < order.count else { return nil }
            let v = order[outer]
            outer += 1
            if let clique = start(v) { return clique }
        }
    }

    /// Sets up the subproblem of `v`, returning `[v]` when it is a maximal clique on its own.
    @inlinable
    mutating func start(_ v: Int) -> [Int]? {
        for u in pVertices { localP[u] = -1 }
        for u in xVertices { localX[u] = -1 }
        pVertices.removeAll(keepingCapacity: true)
        xVertices.removeAll(keepingCapacity: true)
        for k in rows.offsets[v] ..< rows.offsets[v + 1] {
            let u = rows.neighbors[k]
            if rank[u] > rank[v] { pVertices.append(u) } else { xVertices.append(u) }
        }
        if pVertices.isEmpty { return xVertices.isEmpty ? [v] : nil }
        pVertices.sort()
        xVertices.sort()
        for (i, u) in pVertices.enumerated() { localP[u] = i }
        for (i, u) in xVertices.enumerated() { localX[u] = i }
        let p = pVertices.count, x = xVertices.count
        pWords = (p + 63) >> 6
        xWords = (x + 63) >> 6
        rowsP = [UInt64](repeating: 0, count: (p + x) * pWords)
        rowsX = [UInt64](repeating: 0, count: p * xWords)
        for (i, u) in (pVertices + xVertices).enumerated() {
            for k in rows.offsets[u] ..< rows.offsets[u + 1] {
                let w = rows.neighbors[k]
                let lp = localP[w]
                if lp >= 0 { rowsP[i * pWords + lp >> 6] |= 1 << UInt64(lp & 63) }
                if i < p {
                    let lx = localX[w]
                    if lx >= 0 { rowsX[i * xWords + lx >> 6] |= 1 << UInt64(lx & 63) }
                }
            }
        }
        frames.removeAll(keepingCapacity: true)
        current.removeAll(keepingCapacity: true)
        clique = [v]
        // The root frame: P all set, X ∩ P empty, X ∩ X₀ all set.
        var root = [UInt64](repeating: 0, count: frameSize)
        for i in 0 ..< p { root[i >> 6] |= 1 << UInt64(i & 63) }
        for i in 0 ..< x { root[2 * pWords + i >> 6] |= 1 << UInt64(i & 63) }
        push(root)
        return nil
    }

    /// Pushes a frame with P, X ∩ P and X ∩ X₀ set, choosing its pivot and so its branches.
    @inlinable
    mutating func push(_ frame: [UInt64]) {
        var frame = frame
        // Pivot: the member of P ∪ X with most neighbors in P; ties to the least vertex index.
        var best = -1, bestScore = -1, bestVertex = Int.max
        func consider(_ member: Int, _ vertex: Int) {
            var score = 0
            for k in 0 ..< pWords { score += (frame[k] & rowsP[member * pWords + k]).nonzeroBitCount }
            if score > bestScore || (score == bestScore && vertex < bestVertex) {
                best = member
                bestScore = score
                bestVertex = vertex
            }
        }
        for i in 0 ..< pVertices.count where Self.test(frame, 0, i) || Self.test(frame, pWords, i) { consider(i, pVertices[i]) }
        for i in 0 ..< xVertices.count where Self.test(frame, 2 * pWords, i) { consider(pVertices.count + i, xVertices[i]) }
        // Branches: P minus the pivot's neighbors.
        for k in 0 ..< pWords { frame[2 * pWords + xWords + k] = frame[k] & ~rowsP[best * pWords + k] }
        frames.append(contentsOf: frame)
        current.append(-1)
    }

    /// Runs the search until it reports a clique; nil when this subproblem is done.
    @inlinable
    mutating func step() -> [Int]? {
        while let top = current.last {
            let base = frames.count - frameSize
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
                frames.removeLast(frameSize)
                current.removeLast()
                continue
            }
            current[current.count - 1] = w
            clique.append(w)
            // The child: P ∩ N(w), X ∩ N(w) on both halves.
            var child = [UInt64](repeating: 0, count: frameSize)
            var pEmpty = true, xEmpty = true
            for k in 0 ..< pWords {
                let row = rowsP[w * pWords + k]
                child[k] = frames[base + k] & row
                child[pWords + k] = frames[base + pWords + k] & row
                if child[k] != 0 { pEmpty = false }
                if child[pWords + k] != 0 { xEmpty = false }
            }
            for k in 0 ..< xWords {
                child[2 * pWords + k] = frames[base + 2 * pWords + k] & rowsX[w * xWords + k]
                if child[2 * pWords + k] != 0 { xEmpty = false }
            }
            if pEmpty {
                // A leaf: maximal exactly when nothing excluded extends it.
                if xEmpty {
                    var result = [clique[0]]
                    for local in clique.dropFirst() { result.append(pVertices[local]) }
                    result.sort()
                    return result
                }
                continue
            }
            push(child)
        }
        return nil
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
            guard let numbers = search!.next() else { return nil }
            return numbers.map { graph._vertex(number: $0, listed) }
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
