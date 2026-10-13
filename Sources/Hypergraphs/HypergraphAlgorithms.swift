import AdjacencyListModule
import DisjointSetModule
import GraphProtocols
import OrderedCollections

// Algorithms written once on `Hypergraph`. Each runs in index space and maps to vertices only for
// its output, so none hashes a vertex beyond looking up its arguments (the hash law). They need
// both index bounds, which every representation in the library has. n is the vertex count, m the
// hyperedge count, p the number of incidences (Σ|e|), d a degree and k a size.

extension Hypergraph {
    /// Both index bounds, trapping with a message when a conformer lacks one.
    @inlinable
    package func _indexBounds() -> (n: Int, m: Int) {
        guard let n = vertexIndexBound, let m = hyperedgeIndexBound else {
            preconditionFailure("\(Self.self) has no vertex or hyperedge indices, which the hypergraph algorithms need")
        }
        return (n, m)
    }

    /// The positions in index order: `hyperedges` is in index order.
    @inlinable
    package func _positions() -> [Hyperedges.Index] {
        Array(hyperedges.indices)
    }
}

// MARK: - Neighbors, rank, uniformity, histograms

extension Hypergraph {
    /// The vertices that share a hyperedge with `vertex`, each once, in vertex-index order, never
    /// `vertex` itself.
    ///
    /// - Precondition: `vertex` is a vertex.
    /// - Complexity: O(K log K), K = Σ k over the hyperedges at `vertex`: their members are
    ///   gathered, sorted and deduplicated, with no array of n; one hash.
    @inlinable
    public func neighbors(of vertex: Vertex) -> [Vertex] {
        _ = _indexBounds()
        let v = vertexIndex(of: vertex)
        let hyperedges = self.hyperedges
        var found: [Int] = []
        for h in incidentHyperedgeIndices(ofIndex: v) {
            let position = hyperedges.index(hyperedges.startIndex, offsetBy: h)
            for w in memberIndices(ofHyperedgeAt: position) where w != v { found.append(w) }
        }
        found.sort()
        var result: [Vertex] = []
        var previous = -1
        for w in found where w != previous {
            result.append(self.vertex(atIndex: w))
            previous = w
        }
        return result
    }

    /// The greatest hyperedge size (Berge's rank), 0 with no hyperedges. O(m).
    @inlinable
    public var rank: Int {
        var greatest = 0
        for position in hyperedges.indices { greatest = Swift.max(greatest, size(ofHyperedgeAt: position)) }
        return greatest
    }

    /// Whether every hyperedge has exactly `size` members (Berge's k-uniform). Singletons and
    /// empty hyperedges count; vacuously true with no hyperedges. O(m).
    ///
    /// - Precondition: `size >= 0`.
    @inlinable
    public func isUniform(size: Int) -> Bool {
        precondition(size >= 0, "A hyperedge size cannot be negative")
        for position in hyperedges.indices where self.size(ofHyperedgeAt: position) != size { return false }
        return true
    }

    /// Element `d` counts the vertices of degree `d`, up to the greatest degree; `[]` with no
    /// vertices. O(n).
    @inlinable
    public func degreeHistogram() -> [Int] {
        let (n, _) = _indexBounds()
        var histogram: [Int] = []
        for i in 0 ..< n {
            let d = degree(ofIndex: i)
            if d >= histogram.count { histogram.append(contentsOf: repeatElement(0, count: d - histogram.count + 1)) }
            histogram[d] += 1
        }
        return histogram
    }

    /// Element `k` counts the hyperedges of size `k`, up to the rank; `[]` with no hyperedges.
    /// O(m).
    @inlinable
    public func hyperedgeSizeHistogram() -> [Int] {
        var histogram: [Int] = []
        for position in hyperedges.indices {
            let k = size(ofHyperedgeAt: position)
            if k >= histogram.count { histogram.append(contentsOf: repeatElement(0, count: k - histogram.count + 1)) }
            histogram[k] += 1
        }
        return histogram
    }
}

// MARK: - Dual

extension Hypergraph {
    /// The dual hypergraph (Berge's H*), the transpose of the incidence: its vertices are this
    /// hypergraph's positions, in order, and its hyperedge `i` is vertex `i`'s set of hyperedges.
    /// An isolated vertex becomes an empty hyperedge, and an empty hyperedge an isolated vertex, so
    /// the dual is always defined; `dual().dual()` is this hypergraph with its vertices relabeled
    /// to their indices and its positions kept.
    ///
    /// - Complexity: O(n + m + p) expected: m position hashes, no vertex hashed.
    @inlinable
    public func dual() -> UndirectedIncidenceList<Hyperedges.Index> {
        let (n, m) = _indexBounds()
        var offsets = ContiguousArray<Int>()
        offsets.reserveCapacity(n + 1)
        offsets.append(0)
        var flat = ContiguousArray<Int>()
        for i in 0 ..< n {
            for h in incidentHyperedgeIndices(ofIndex: i) { flat.append(h) }
            offsets.append(flat.count)
        }
        return UndirectedIncidenceList(_uncheckedVertices: OrderedSet(uncheckedUniqueElements: _positions()),
                                       plane: _IncidencePlane(vertexCount: m, offsets: offsets, members: flat))
    }
}

// MARK: - Expansions

extension Hypergraph {
    /// The clique expansion (Berge's 2-section): every vertex, isolated ones included, in
    /// vertex-index order, and an edge between every two vertices that share a hyperedge, once,
    /// with no self-loops. Edges ascend by (index of u, index of v), u the lower. Singletons and
    /// empty hyperedges add no edge. Lossy and quadratic: one hyperedge of k members is k(k − 1)/2
    /// edges.
    ///
    /// - Complexity: O(n + Σ k² + e log d) for e edges: each vertex's neighbors are gathered with
    ///   a marker array and sorted. Building the result hashes each vertex once (n hashes,
    ///   whatever the output size, and none for the vertices `0..<n` in order) and no vertex per
    ///   edge.
    @inlinable
    public func cliqueExpansion() -> UndirectedAdjacencyList<Vertex> {
        let (n, _) = _indexBounds()
        let positions = _positions()
        var stamp = [Int](repeating: -1, count: n)
        var edges: [UndirectedEdge<Int>] = []
        var found: [Int] = []
        for u in 0 ..< n {
            found.removeAll(keepingCapacity: true)
            stamp[u] = u
            for h in incidentHyperedgeIndices(ofIndex: u) {
                for w in memberIndices(ofHyperedgeAt: positions[h]) where w > u && stamp[w] != u {
                    stamp[w] = u
                    found.append(w)
                }
            }
            found.sort()
            for w in found { edges.append(UndirectedEdge(u, w)) }
        }
        var vertices = ContiguousArray<Vertex>()
        vertices.reserveCapacity(n)
        for i in 0 ..< n { vertices.append(vertex(atIndex: i)) }
        return UndirectedAdjacencyList(_uncheckedVertices: vertices, sortedSlotEdges: edges)
    }

    /// The s-line graph (Aksoy et al. 2020): every position `0..<m` as a vertex, in order, and an
    /// edge `p`–`q` (`p < q`) when the two hyperedges share at least `s` members. An empty
    /// hyperedge, or one sharing fewer than `s` members with every other, is isolated. Edges ascend
    /// by `(p, q)`.
    ///
    /// - Precondition: `s >= 1`.
    /// - Complexity: O(m + Σ_v d(v)² + e log e) with one counter array, no hashing beyond the
    ///   positions of the result.
    @inlinable
    public func lineGraph(s: Int) -> UndirectedAdjacencyList<Hyperedges.Index> {
        precondition(s >= 1, "s must be at least 1")
        let (_, m) = _indexBounds()
        var edges: [UndirectedEdge<Int>] = []
        _forEachOverlap(s: s, hyperedgeCount: m, ordered: true) { p, q in edges.append(UndirectedEdge(p, q)) }
        return UndirectedAdjacencyList(_uncheckedVertices: ContiguousArray(_positions()), sortedSlotEdges: edges)
    }

    /// Calls `body(p, q)` for every pair of hyperedge indices `p < q` sharing at least `s` members:
    /// for each `p`, the members' other hyperedges after `p` are counted in one array. With
    /// `ordered`, the counted ones are sorted, so the pairs come in ascending `(p, q)` order.
    @inlinable
    package func _forEachOverlap(s: Int, hyperedgeCount m: Int, ordered: Bool, _ body: (Int, Int) -> Void) {
        var counts = [Int](repeating: 0, count: m)
        var touched: [Int] = []
        var p = 0
        for position in hyperedges.indices {
            touched.removeAll(keepingCapacity: true)
            for v in memberIndices(ofHyperedgeAt: position) {
                for q in incidentHyperedgeIndices(ofIndex: v) where q > p {
                    if counts[q] == 0 { touched.append(q) }
                    counts[q] &+= 1
                }
            }
            if ordered { touched.sort() }
            for q in touched {
                if counts[q] >= s { body(p, q) }
                counts[q] = 0
            }
            p &+= 1
        }
    }
}

// MARK: - Components

extension Hypergraph {
    /// The connected components: two vertices are together when a chain of hyperedges joins them.
    /// Components are ordered by their least vertex index and list their vertices in index order;
    /// an isolated vertex is alone, and an empty hyperedge joins nothing. No vertices, no
    /// components.
    ///
    /// - Complexity: O(n + p α(n)), union–find over the members.
    @inlinable
    public func connectedComponents() -> [[Vertex]] {
        let (n, _) = _indexBounds()
        var sets = DisjointSet(count: n)
        _unionMembers(&sets)
        return sets.sets().map { $0.map { self.vertex(atIndex: $0) } }
    }

    /// Whether there is exactly one connected component: false with no vertices. O(n + p α(n)).
    @inlinable
    public var isConnected: Bool {
        let (n, _) = _indexBounds()
        var sets = DisjointSet(count: n)
        _unionMembers(&sets)
        return sets.setCount == 1
    }

    @inlinable
    package func _unionMembers(_ sets: inout DisjointSet) {
        for position in hyperedges.indices {
            var first = -1
            _forEachMemberIndex(ofHyperedgeAt: position) { v in
                if first < 0 { first = v } else { sets.union(first, v) }
            }
        }
    }

    /// The hyperedge s-components (Aksoy et al. 2020): the connected components of `lineGraph(s:)`,
    /// as positions, without building it. Singletons are kept, an empty hyperedge is its own
    /// component, and components are ordered by their least position, each ascending. The vertex
    /// s-components are `dual().sConnectedComponents(s:)`.
    ///
    /// - Precondition: `s >= 1`.
    /// - Complexity: O(n + m + p α(m)) for `s == 1`, a union over each vertex's hyperedges (two
    ///   hyperedges share a member exactly when some vertex is in both); O(m + Σ_v d(v)²)
    ///   otherwise. No hashing beyond the output positions.
    @inlinable
    public func sConnectedComponents(s: Int) -> [[Hyperedges.Index]] {
        precondition(s >= 1, "s must be at least 1")
        let (n, m) = _indexBounds()
        var sets = DisjointSet(count: m)
        if s == 1 {
            for i in 0 ..< n {
                var first = -1
                for h in incidentHyperedgeIndices(ofIndex: i) {
                    if first < 0 { first = h } else { sets.union(first, h) }
                }
            }
        } else {
            _forEachOverlap(s: s, hyperedgeCount: m, ordered: false) { p, q in sets.union(p, q) }
        }
        let positions = _positions()
        return sets.sets().map { $0.map { positions[$0] } }
    }
}
