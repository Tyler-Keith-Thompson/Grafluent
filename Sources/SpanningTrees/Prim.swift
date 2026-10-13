import GraphProtocols
import PriorityQueueModule

extension Graph {
    /// A minimum spanning forest by Prim's algorithm, over every component.
    ///
    /// Grows a tree from the first unspanned vertex in `vertices` order, taking the lightest edge
    /// out of it each step, and repeats until every vertex is spanned. Among equal weights, which
    /// edge it takes is unspecified. Edges are listed in the order their far vertices joined, and
    /// the weight is added up in that order.
    ///
    /// Each edge that is not a self-loop is weighed at most once, from the end spanned first. An
    /// edge whose far end is already spanned is skipped without being weighed.
    ///
    /// - Complexity: O(m log n), with a 4-ary indexed heap.
    /// - Precondition: as for `minimumSpanningTree(weight:)`.
    @inlinable
    public func primMinimumSpanningTree<W: Comparable & AdditiveArithmetic>(
        weight: (Edges.Index) -> W
    ) -> SpanningForest<Self, W> {
        let (edges, total) = _prim(root: nil, weight, ranked: false, key: { w, _ in w })
        return SpanningForest(edges: edges.map(\.position), weight: total)
    }

    /// A minimum spanning tree of `root`'s connected component, by Prim's algorithm from `root`.
    ///
    /// Only that component's edges are weighed.
    ///
    /// - Precondition: `contains(root)`; weights as for `primMinimumSpanningTree(weight:)`.
    @inlinable
    public func primMinimumSpanningTree<W: Comparable & AdditiveArithmetic>(
        from root: Vertex, weight: (Edges.Index) -> W
    ) -> SpanningForest<Self, W> {
        let (edges, total) = _prim(root: root, weight, ranked: false, key: { w, _ in w })
        return SpanningForest(edges: edges.map(\.position), weight: total)
    }

    /// Prim under the strict order (weight, rank), sorted into that order and added up in it: the
    /// forest Kruskal gives, total included. With vertex indices and at least n²/4 edges it scans
    /// an array of keys instead of a heap (`_densePrim`), O(n² + m); the forest is unique under
    /// the order, so it is the same.
    @inlinable
    func _canonicalPrim<W: Comparable & AdditiveArithmetic>(_ weight: (Edges.Index) -> W) -> SpanningForest<Self, W> {
        var edges = _prefersDensePrim ? _densePrim(weight)
            : _prim(root: nil, weight, ranked: true, key: { w, rank in _RankedWeight(w, rank) }).edges
        edges.sort { $0.weight < $1.weight || (!($1.weight < $0.weight) && $0.rank < $1.rank) }
        var total = W.zero
        for e in edges { total += e.weight }
        return SpanningForest(edges: edges.map(\.position), weight: total)
    }

    /// Prim over `root`'s component, or over every component in `vertices` order, with heap
    /// priorities `key(weight, rank)`. Returns the edges in the order taken, with their weights
    /// and, when `ranked`, their ranks (otherwise -1, and no ranks are computed); and, when not
    /// `ranked`, the total added up in that order. When `ranked` the total is zero; the caller
    /// reorders the edges and sums them in its own order, which can avoid an overflow this order
    /// would hit.
    @inlinable
    func _prim<W: Comparable & AdditiveArithmetic, Key: Comparable>(
        root: Vertex?, _ weight: (Edges.Index) -> W, ranked: Bool, key: (W, Int) -> Key
    ) -> (edges: [(position: Edges.Index, weight: W, rank: Int)], total: W) {
        if let n = vertexIndexBound {
            let roots = root.map { _requiredVertexIndex(of: $0, "\($0) is not a vertex of the graph") }
            if edgeIndexBound != nil {
                return _prim(count: n, root: roots, weight, ranked, key, { edgeIndex(of: $0) }) { u in
                    zip(neighborIndices(ofIndex: u), incidentEdges(ofIndex: u)).makeIterator()
                }
            }
            let ranks = ranked ? Dictionary(uniqueKeysWithValues: edges.indices.enumerated().map { ($1, $0) }) : [:]
            return _prim(count: n, root: roots, weight, ranked, key, { ranks[$0]! }) { u in
                zip(neighborIndices(ofIndex: u), incidentEdges(ofIndex: u)).makeIterator()
            }
        }
        let listed = Array(vertices)
        let ids = _numberedVertices()
        let ranks = ranked ? Dictionary(uniqueKeysWithValues: edges.indices.enumerated().map { ($1, $0) }) : [:]
        return _prim(count: listed.count, root: root.map { root in
            guard let id = ids[root] else { preconditionFailure("\(root) is not a vertex of the graph") }
            return id
        }, weight, ranked, key, { ranks[$0]! }) { u in
            let vertex = listed[u]
            return incidentEdges(of: vertex).lazy.map { (ids[oppositeVertex(to: vertex, acrossEdgeAt: $0)]!, $0) }.makeIterator()
        }
    }

    /// Prim in index space. `arcs(u)` gives `(v, position)` for every edge end at `u`. With no
    /// root, every index in order is a root.
    @inlinable
    func _prim<W: Comparable & AdditiveArithmetic, Key: Comparable, Arcs: IteratorProtocol>(
        count n: Int, root: Int?, _ weight: (Edges.Index) -> W, _ ranked: Bool, _ key: (W, Int) -> Key,
        _ rank: (Edges.Index) -> Int, _ arcs: (Int) -> Arcs
    ) -> (edges: [(position: Edges.Index, weight: W, rank: Int)], total: W) where Arcs.Element == (Int, Edges.Index) {
        var spanned = [Bool](repeating: false, count: n)
        // Each queued vertex's best edge so far: its position (meaningful once `hasParent`), its
        // weight and, when ranked, its rank.
        var hasParent = [Bool](repeating: false, count: n)
        var parentEdge = [Edges.Index](repeating: edges.startIndex, count: n > 0 && !edges.isEmpty ? n : 0)
        var best = [W](repeating: .zero, count: n)
        var bestRank = [Int](repeating: -1, count: ranked ? n : 0)
        var queue = IndexedPriorityQueue<Key>(indexBound: n)
        var taken: [(position: Edges.Index, weight: W, rank: Int)] = []
        taken.reserveCapacity(Swift.max(0, n - 1))
        var total = W.zero
        for start in root.map({ $0 ..< $0 + 1 }) ?? 0 ..< n where !spanned[start] {
            queue.insert(start, priority: key(.zero, -1))
            while let (u, _) = queue.popMin() {
                spanned[u] = true
                if hasParent[u] {
                    taken.append((parentEdge[u], best[u], ranked ? bestRank[u] : -1))
                    if !ranked { total += best[u] }
                }
                var out = arcs(u)
                while let (v, position) = out.next() {
                    guard !spanned[v] else { continue }
                    let w = weight(position)
                    precondition(w == w, "An edge weight is NaN")
                    let r = ranked ? rank(position) : -1
                    if queue.insertOrDecreasePriority(of: v, to: key(w, r)) {
                        hasParent[v] = true
                        parentEdge[v] = position
                        best[v] = w
                        if ranked { bestRank[v] = r }
                    }
                }
            }
        }
        return (taken, total)
    }
}

/// A weight with the rank of its edge, ordered by weight and then rank: the strict order under
/// which the minimum spanning forest is unique.
@frozen
@usableFromInline
struct _RankedWeight<W: Comparable>: Comparable {
    @usableFromInline let weight: W
    @usableFromInline let rank: Int

    @inlinable
    init(_ weight: W, _ rank: Int) {
        self.weight = weight
        self.rank = rank
    }

    @inlinable
    static func < (a: Self, b: Self) -> Bool {
        a.weight < b.weight || (!(b.weight < a.weight) && a.rank < b.rank)
    }

    @inlinable
    static func == (a: Self, b: Self) -> Bool {
        !(a.weight < b.weight) && !(b.weight < a.weight) && a.rank == b.rank
    }
}
