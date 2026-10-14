import DisjointSetModule
import GraphProtocols
import PriorityQueueModule

/// A Steiner tree of an undirected graph: a tree among the graph's edges that connects every
/// terminal, through other vertices where that helps, as edge positions with their total weight.
///
/// The edges are positions in the graph's `edges`, in position order; the vertices are their
/// endpoints, or the single terminal when there is one. Equality compares the edges and the
/// weight, not which graph the tree came from. The tree never contains a self-loop, and holds at
/// most one of a set of parallel edges.
///
/// The tree holds no copy of the graph. Its positions stay valid until the graph is mutated.
@frozen
public struct SteinerTree<G: Graph, Weight: Comparable & AdditiveArithmetic> {
    /// The tree's edges, as positions in the graph's `edges`, in position order.
    public let edges: [G.Edges.Index]

    /// The sum of the edge weights, added up in `edges` order; zero with no edges.
    public let weight: Weight

    @inlinable
    init(edges: [G.Edges.Index], weight: Weight) {
        self.edges = edges
        self.weight = weight
    }
}

extension SteinerTree: Equatable {}
extension SteinerTree: Hashable where Weight: Hashable {}
extension SteinerTree: Sendable where G.Edges.Index: Sendable, Weight: Sendable {}

extension Graph {
    /// An approximate minimum Steiner tree connecting `terminals`, by Mehlhorn's algorithm; nil
    /// when two terminals are in different components.
    ///
    /// One Dijkstra search from all terminals at once assigns every vertex to its nearest
    /// terminal. Each edge between two terminals' regions joins them at the length of the path
    /// through it, a minimum spanning tree of those joins picks which regions to connect, and the
    /// tree is the picked edges with the shortest paths from their ends to their terminals. Its
    /// weight is at most 2(1 − 1/ℓ) times the optimum, where ℓ is the number of leaves of an
    /// optimal tree. Every leaf is a terminal.
    ///
    /// Repeated terminals count once. With fewer than two terminals the tree has no edges. Every
    /// edge that is not a self-loop is weighed once; `weight` is not kept.
    ///
    /// - Parameters:
    ///   - terminals: The vertices to connect.
    ///   - weight: Each edge's weight, from its position.
    /// - Returns: The tree's edges, in position order, and their total weight.
    /// - Complexity: O(m log m).
    /// - Precondition: every terminal is a vertex; every weight is at least zero and not NaN; the
    ///   path lengths do not overflow.
    @inlinable
    public func steinerTree<W: Comparable & AdditiveArithmetic>(
        terminals: some Sequence<Vertex>, weight: (Edges.Index) -> W
    ) -> SteinerTree<Self, W>? {
        let ranked = _rankedEdges { _nonnegativeSteinerWeight(weight($0)) }
        let ids = _steinerTerminals(terminals)
        return _mehlhornSteinerTree(ranked, ids)
    }

    /// `steinerTree(terminals:weight:)`, throwing instead of trapping when a terminal is not a
    /// vertex.
    ///
    /// - Throws: `VertexNotFound` when a terminal is not a vertex of the graph.
    @inlinable
    public func steinerTree<W: Comparable & AdditiveArithmetic>(
        checkedTerminals terminals: some Sequence<Vertex>, weight: (Edges.Index) -> W
    ) throws(VertexNotFound) -> SteinerTree<Self, W>? {
        let listed = Array(terminals)
        for t in listed where !contains(t) { throw VertexNotFound() }
        return steinerTree(terminals: listed, weight: weight)
    }

    /// An approximate minimum Steiner tree connecting `terminals`, by the algorithm of Kou,
    /// Markowsky and Berman; nil when two terminals are in different components.
    ///
    /// A Dijkstra search from each terminal gives the distances between terminals; a minimum
    /// spanning tree of that complete distance graph is expanded into its shortest paths; and the
    /// tree is a minimum spanning tree of those paths' edges with every leaf that is not a
    /// terminal pruned, repeatedly. Its weight is at most 2(1 − 1/ℓ) times the optimum, where ℓ is
    /// the number of leaves of an optimal tree.
    ///
    /// Repeated terminals count once. With fewer than two terminals the tree has no edges. Every
    /// edge that is not a self-loop is weighed once; `weight` is not kept.
    ///
    /// - Parameters:
    ///   - terminals: The vertices to connect.
    ///   - weight: Each edge's weight, from its position.
    /// - Returns: The tree's edges, in position order, and their total weight.
    /// - Complexity: O(t (m + n) log n + t²) for t terminals, with O(t n) memory.
    /// - Precondition: every terminal is a vertex; every weight is at least zero and not NaN; the
    ///   path lengths do not overflow.
    @inlinable
    public func kouSteinerTree<W: Comparable & AdditiveArithmetic>(
        terminals: some Sequence<Vertex>, weight: (Edges.Index) -> W
    ) -> SteinerTree<Self, W>? {
        let ranked = _rankedEdges { _nonnegativeSteinerWeight(weight($0)) }
        let ids = _steinerTerminals(terminals)
        return _kouSteinerTree(ranked, ids)
    }

    /// `kouSteinerTree(terminals:weight:)`, throwing instead of trapping when a terminal is not a
    /// vertex.
    ///
    /// - Throws: `VertexNotFound` when a terminal is not a vertex of the graph.
    @inlinable
    public func kouSteinerTree<W: Comparable & AdditiveArithmetic>(
        checkedTerminals terminals: some Sequence<Vertex>, weight: (Edges.Index) -> W
    ) throws(VertexNotFound) -> SteinerTree<Self, W>? {
        let listed = Array(terminals)
        for t in listed where !contains(t) { throw VertexNotFound() }
        return kouSteinerTree(terminals: listed, weight: weight)
    }

    /// The distinct terminals' vertex identifiers (as `_rankedEdges` numbers vertices), in first
    /// appearance order.
    @inlinable
    func _steinerTerminals(_ terminals: some Sequence<Vertex>) -> [Int] {
        let numbers = _vertexNumbering()?.numbers
        var ids: [Int] = []
        var seen = Set<Int>()
        for t in terminals {
            let id = _vertexNumber(of: t, numbers, "The terminal \(t) is not a vertex of the graph")
            if seen.insert(id).inserted { ids.append(id) }
        }
        return ids
    }

    /// Mehlhorn's tree over the ranked edges.
    @inlinable
    func _mehlhornSteinerTree<W: Comparable & AdditiveArithmetic>(_ ranked: _RankedEdges<Edges.Index, W>, _ terminals: [Int]) -> SteinerTree<Self, W>? {
        let t = terminals.count
        guard t >= 2 else { return SteinerTree(edges: [], weight: .zero) }
        let n = ranked.vertexCount
        let rows = _IncidenceRows(ranked)
        // Nearest terminal (by offset in `terminals`), distance and the edge rank towards it.
        var region = [Int](repeating: -1, count: n)
        var distance = [W](repeating: .zero, count: n)
        var toward = [Int](repeating: -1, count: n)
        var settled = [Bool](repeating: false, count: n)
        var queue = IndexedPriorityQueue<W>(indexBound: n)
        for (i, v) in terminals.enumerated() {
            region[v] = i
            queue.insert(v, priority: .zero)
        }
        while let (u, d) = queue.popMin() {
            settled[u] = true
            for slot in rows.offsets[u] ..< rows.offsets[u + 1] {
                let v = rows.neighbor[slot]
                if settled[v] { continue }
                let rank = rows.rank[slot]
                if queue.insertOrDecreasePriority(of: v, to: d + rows.weight[rank]) {
                    distance[v] = d + rows.weight[rank]
                    region[v] = region[u]
                    toward[v] = rank
                }
            }
        }
        // Every edge between two regions, at the length of the terminal-to-terminal path through it.
        var joins: [(W, Int)] = []
        for rank in ranked.u.indices {
            let u = ranked.u[rank], v = ranked.v[rank]
            guard u >= 0, region[u] >= 0, region[v] >= 0, region[u] != region[v] else { continue }
            joins.append((distance[u] + rows.weight[rank] + distance[v], rank))
        }
        joins.sort { $0.0 < $1.0 || (!($1.0 < $0.0) && $0.1 < $1.1) }
        var sets = DisjointSet(count: t)
        var taken = [Bool](repeating: false, count: ranked.u.count)
        var onTree = [Bool](repeating: false, count: n)
        var joined = 0
        for (_, rank) in joins {
            if joined == t - 1 { break }
            guard sets.union(region[ranked.u[rank]], region[ranked.v[rank]]) else { continue }
            joined += 1
            taken[rank] = true
            // The shortest paths from both ends back to their terminals, until they meet the tree.
            for end in [ranked.u[rank], ranked.v[rank]] {
                var x = end
                while !onTree[x] {
                    onTree[x] = true
                    let e = toward[x]
                    if e < 0 { break }
                    taken[e] = true
                    x = ranked.u[e] == x ? ranked.v[e] : ranked.u[e]
                }
            }
        }
        guard joined == t - 1 else { return nil }
        return Self._steinerTree(taken, ranked.position, rows.weight)
    }

    /// Kou, Markowsky and Berman's tree over the ranked edges.
    @inlinable
    func _kouSteinerTree<W: Comparable & AdditiveArithmetic>(_ ranked: _RankedEdges<Edges.Index, W>, _ terminals: [Int]) -> SteinerTree<Self, W>? {
        let t = terminals.count
        guard t >= 2 else { return SteinerTree(edges: [], weight: .zero) }
        let n = ranked.vertexCount
        let rows = _IncidenceRows(ranked)
        // Per terminal, its shortest-path tree: the edge rank towards it from every vertex, and
        // the distances to the other terminals (nil: unreachable).
        var toward = [[Int]](repeating: [], count: t)
        var between = [[W?]](repeating: [], count: t)
        var distance = [W](repeating: .zero, count: n)
        var settled = [Bool](repeating: false, count: n)
        var queue = IndexedPriorityQueue<W>(indexBound: n)
        for i in 0 ..< t {
            var parent = [Int](repeating: -1, count: n)
            for v in 0 ..< n { settled[v] = false }
            var reached = [Bool](repeating: false, count: n)
            queue.insert(terminals[i], priority: .zero)
            distance[terminals[i]] = .zero
            reached[terminals[i]] = true
            while let (u, d) = queue.popMin() {
                settled[u] = true
                for slot in rows.offsets[u] ..< rows.offsets[u + 1] {
                    let v = rows.neighbor[slot]
                    if settled[v] { continue }
                    let rank = rows.rank[slot]
                    if queue.insertOrDecreasePriority(of: v, to: d + rows.weight[rank]) {
                        distance[v] = d + rows.weight[rank]
                        reached[v] = true
                        parent[v] = rank
                    }
                }
            }
            toward[i] = parent
            between[i] = terminals.map { reached[$0] ? distance[$0] : nil }
        }
        // Prim over the complete distance graph, ties to the lower terminal offset.
        var inTree = [Bool](repeating: false, count: t)
        var best = [W?](repeating: nil, count: t)
        var from = [Int](repeating: -1, count: t)
        best[0] = .zero
        var hull = [Bool](repeating: false, count: ranked.u.count)
        for _ in 0 ..< t {
            var next = -1
            for j in 0 ..< t where !inTree[j] {
                guard let b = best[j] else { continue }
                if next < 0 || b < best[next]! { next = j }
            }
            guard next >= 0 else { return nil }
            inTree[next] = true
            if from[next] >= 0 {
                // The shortest path from terminal `from[next]` to `next`, into the hull.
                let parent = toward[from[next]]
                var x = terminals[next]
                while parent[x] >= 0 {
                    let e = parent[x]
                    hull[e] = true
                    x = ranked.u[e] == x ? ranked.v[e] : ranked.u[e]
                }
            }
            for j in 0 ..< t where !inTree[j] {
                guard let d = between[next][j] else { continue }
                if best[j] == nil || d < best[j]! {
                    best[j] = d
                    from[j] = next
                }
            }
        }
        // A minimum spanning forest of the hull, then the leaves that are not terminals pruned.
        var order: [(W, Int)] = []
        for rank in hull.indices where hull[rank] { order.append((rows.weight[rank], rank)) }
        order.sort { $0.0 < $1.0 || (!($1.0 < $0.0) && $0.1 < $1.1) }
        var sets = DisjointSet(count: n)
        var taken = [Bool](repeating: false, count: ranked.u.count)
        var degree = [Int](repeating: 0, count: n)
        for (_, rank) in order where sets.union(ranked.u[rank], ranked.v[rank]) {
            taken[rank] = true
            degree[ranked.u[rank]] += 1
            degree[ranked.v[rank]] += 1
        }
        var isTerminal = [Bool](repeating: false, count: n)
        for v in terminals { isTerminal[v] = true }
        // The tree's edges at each vertex, to find a pruned leaf's one remaining edge.
        var incident = [[Int]](repeating: [], count: n)
        for rank in taken.indices where taken[rank] {
            incident[ranked.u[rank]].append(rank)
            incident[ranked.v[rank]].append(rank)
        }
        var leaves = (0 ..< n).filter { degree[$0] == 1 && !isTerminal[$0] }
        while let leaf = leaves.popLast() {
            guard let e = incident[leaf].first(where: { taken[$0] }) else { continue }
            taken[e] = false
            degree[leaf] -= 1
            let other = ranked.u[e] == leaf ? ranked.v[e] : ranked.u[e]
            degree[other] -= 1
            if degree[other] == 1 && !isTerminal[other] { leaves.append(other) }
        }
        return Self._steinerTree(taken, ranked.position, rows.weight)
    }

    /// The tree of the edge ranks `taken`, in rank order, its weight added up in that order.
    @inlinable
    static func _steinerTree<W: Comparable & AdditiveArithmetic>(_ taken: [Bool], _ positions: [Edges.Index], _ weight: [W]) -> SteinerTree<Self, W> {
        var edges: [Edges.Index] = []
        var total = W.zero
        for rank in taken.indices where taken[rank] {
            edges.append(positions[rank])
            total += weight[rank]
        }
        return SteinerTree(edges: edges, weight: total)
    }
}

/// `w`, trapping when it is negative or NaN.
@inlinable
func _nonnegativeSteinerWeight<W: Comparable & AdditiveArithmetic>(_ w: W) -> W {
    precondition(w >= .zero, "Steiner trees need nonnegative weights (and no NaN)")
    return w
}

/// The ranked edges as rows in index space: each vertex's (neighbor, rank) pairs, and each rank's
/// weight.
@frozen
@usableFromInline
struct _IncidenceRows<W> {
    @usableFromInline var offsets: [Int]
    @usableFromInline var neighbor: [Int]
    @usableFromInline var rank: [Int]
    /// By rank; zero for a self-loop, which is in no row.
    @usableFromInline var weight: [W]

    @inlinable
    init<Position>(_ ranked: _RankedEdges<Position, W>) where W: Comparable & AdditiveArithmetic {
        let n = ranked.vertexCount, m = ranked.u.count
        var offsets = [Int](repeating: 0, count: n + 1)
        for r in 0 ..< m where ranked.u[r] >= 0 {
            offsets[ranked.u[r] + 1] += 1
            offsets[ranked.v[r] + 1] += 1
        }
        for v in 0 ..< n { offsets[v + 1] += offsets[v] }
        var next = offsets
        var neighbor = [Int](repeating: 0, count: offsets[n])
        var rank = [Int](repeating: 0, count: offsets[n])
        for r in 0 ..< m where ranked.u[r] >= 0 {
            let u = ranked.u[r], v = ranked.v[r]
            neighbor[next[u]] = v
            rank[next[u]] = r
            next[u] += 1
            neighbor[next[v]] = u
            rank[next[v]] = r
            next[v] += 1
        }
        var weight = [W](repeating: .zero, count: m)
        for (w, r) in ranked.keyed { weight[r] = w }
        self.offsets = offsets
        self.neighbor = neighbor
        self.rank = rank
        self.weight = weight
    }
}
