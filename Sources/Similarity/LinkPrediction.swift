import GraphProtocols

// Vertex-pair similarity for link prediction (Liben-Nowell and Kleinberg 2003): scores of two
// vertices' neighborhoods. Γ(x) is the neighbor set of x in the simple graph underneath: every
// vertex other than x that shares an edge with x, once however many edges join them, so self-loops
// are ignored and parallel edges count once. The two vertices may be the same vertex, and need not
// be adjacent. A directed graph reaches these through `undirectedView`, where a vertex's neighbors
// are its successors and predecessors.
//
// Each measure has four spellings: one pair, which reads only the two neighborhoods (and, for the
// sums, each common neighbor's); one pair, checked; and many pairs, which copy the simple graph's
// rows once and score each pair in O(d(u) + d(v)) without hashing, plain and checked.

extension Graph {
    /// The number of common neighbors of `u` and `v`: |Γ(u) ∩ Γ(v)|.
    ///
    /// Γ(x) is the set of vertices other than x that share an edge with x: self-loops are ignored
    /// and parallel edges count once.
    ///
    /// O(d(u) log d(u) + d(v) log d(v)) with vertex indices; O(d(u) + d(v)) hash operations
    /// without.
    ///
    /// - Parameters:
    ///   - u: A vertex of the graph.
    ///   - v: A vertex of the graph, possibly `u`.
    /// - Precondition: `u` and `v` are vertices of the graph.
    @inlinable
    public func commonNeighborCount(of u: Vertex, and v: Vertex) -> Int { _pairScore(of: u, and: v, _CommonNeighbors()) }

    /// `commonNeighborCount(of:and:)`, throwing instead of trapping when `u` or `v` is not a vertex
    /// of the graph.
    ///
    /// - Throws: `VertexNotFound` when `u` or `v` is not a vertex of the graph.
    @inlinable
    public func commonNeighborCount(checked u: Vertex, and v: Vertex) throws(VertexNotFound) -> Int {
        guard contains(u), contains(v) else { throw VertexNotFound() }
        return _pairScore(of: u, and: v, _CommonNeighbors())
    }

    /// The number of common neighbors of each pair, in order: |Γ(u) ∩ Γ(v)|.
    ///
    /// O(n + m + Σ (d(u) + d(v))) over the pairs, for n vertices and m edges; a run of pairs with
    /// the same first vertex reads its neighbors once, so each later pair of the run costs O(d(v)).
    ///
    /// - Parameter pairs: Pairs of vertices of the graph; a pair may repeat or name one vertex twice.
    /// - Returns: One score per pair, in the order of `pairs`.
    /// - Precondition: every vertex of `pairs` is a vertex of the graph.
    @inlinable
    public func commonNeighborCounts(of pairs: some Sequence<(Vertex, Vertex)>) -> [Int] {
        // The plain spelling traps rather than throwing.
        try! _pairScores(pairs, _CommonNeighbors(), checked: false)
    }

    /// `commonNeighborCounts(of:)`, throwing instead of trapping when a pair names a vertex not in
    /// the graph.
    ///
    /// - Throws: `VertexNotFound` when a vertex of `pairs` is not a vertex of the graph, before any
    ///   pair is scored.
    @inlinable
    public func commonNeighborCounts(checked pairs: some Sequence<(Vertex, Vertex)>) throws(VertexNotFound) -> [Int] {
        try _pairScores(pairs, _CommonNeighbors(), checked: true)
    }

    /// The Jaccard coefficient of `u` and `v`: |Γ(u) ∩ Γ(v)| / |Γ(u) ∪ Γ(v)|, or 0 when both have
    /// no neighbors.
    ///
    /// Γ(x) is the set of vertices other than x that share an edge with x: self-loops are ignored
    /// and parallel edges count once.
    ///
    /// O(d(u) log d(u) + d(v) log d(v)) with vertex indices; O(d(u) + d(v)) hash operations
    /// without.
    ///
    /// - Parameters:
    ///   - u: A vertex of the graph.
    ///   - v: A vertex of the graph, possibly `u`.
    /// - Precondition: `u` and `v` are vertices of the graph.
    @inlinable
    public func jaccardCoefficient(of u: Vertex, and v: Vertex) -> Double { _pairScore(of: u, and: v, _Jaccard()) }

    /// `jaccardCoefficient(of:and:)`, throwing instead of trapping when `u` or `v` is not a vertex
    /// of the graph.
    ///
    /// - Throws: `VertexNotFound` when `u` or `v` is not a vertex of the graph.
    @inlinable
    public func jaccardCoefficient(checked u: Vertex, and v: Vertex) throws(VertexNotFound) -> Double {
        guard contains(u), contains(v) else { throw VertexNotFound() }
        return _pairScore(of: u, and: v, _Jaccard())
    }

    /// The Jaccard coefficient of each pair, in order: |Γ(u) ∩ Γ(v)| / |Γ(u) ∪ Γ(v)|, or 0 when
    /// both have no neighbors.
    ///
    /// O(n + m + Σ (d(u) + d(v))) over the pairs, for n vertices and m edges; a run of pairs with
    /// the same first vertex reads its neighbors once, so each later pair of the run costs O(d(v)).
    ///
    /// - Parameter pairs: Pairs of vertices of the graph; a pair may repeat or name one vertex twice.
    /// - Returns: One score per pair, in the order of `pairs`.
    /// - Precondition: every vertex of `pairs` is a vertex of the graph.
    @inlinable
    public func jaccardCoefficients(of pairs: some Sequence<(Vertex, Vertex)>) -> [Double] {
        // The plain spelling traps rather than throwing.
        try! _pairScores(pairs, _Jaccard(), checked: false)
    }

    /// `jaccardCoefficients(of:)`, throwing instead of trapping when a pair names a vertex not in
    /// the graph.
    ///
    /// - Throws: `VertexNotFound` when a vertex of `pairs` is not a vertex of the graph, before any
    ///   pair is scored.
    @inlinable
    public func jaccardCoefficients(checked pairs: some Sequence<(Vertex, Vertex)>) throws(VertexNotFound) -> [Double] {
        try _pairScores(pairs, _Jaccard(), checked: true)
    }

    /// The Sørensen–Dice coefficient of `u` and `v`: 2 |Γ(u) ∩ Γ(v)| / (|Γ(u)| + |Γ(v)|), or 0 when
    /// both have no neighbors.
    ///
    /// Γ(x) is the set of vertices other than x that share an edge with x: self-loops are ignored
    /// and parallel edges count once.
    ///
    /// O(d(u) log d(u) + d(v) log d(v)) with vertex indices; O(d(u) + d(v)) hash operations
    /// without.
    ///
    /// - Parameters:
    ///   - u: A vertex of the graph.
    ///   - v: A vertex of the graph, possibly `u`.
    /// - Precondition: `u` and `v` are vertices of the graph.
    @inlinable
    public func diceCoefficient(of u: Vertex, and v: Vertex) -> Double { _pairScore(of: u, and: v, _Dice()) }

    /// `diceCoefficient(of:and:)`, throwing instead of trapping when `u` or `v` is not a vertex of
    /// the graph.
    ///
    /// - Throws: `VertexNotFound` when `u` or `v` is not a vertex of the graph.
    @inlinable
    public func diceCoefficient(checked u: Vertex, and v: Vertex) throws(VertexNotFound) -> Double {
        guard contains(u), contains(v) else { throw VertexNotFound() }
        return _pairScore(of: u, and: v, _Dice())
    }

    /// The Sørensen–Dice coefficient of each pair, in order: 2 |Γ(u) ∩ Γ(v)| / (|Γ(u)| + |Γ(v)|),
    /// or 0 when both have no neighbors.
    ///
    /// O(n + m + Σ (d(u) + d(v))) over the pairs, for n vertices and m edges; a run of pairs with
    /// the same first vertex reads its neighbors once, so each later pair of the run costs O(d(v)).
    ///
    /// - Parameter pairs: Pairs of vertices of the graph; a pair may repeat or name one vertex twice.
    /// - Returns: One score per pair, in the order of `pairs`.
    /// - Precondition: every vertex of `pairs` is a vertex of the graph.
    @inlinable
    public func diceCoefficients(of pairs: some Sequence<(Vertex, Vertex)>) -> [Double] {
        // The plain spelling traps rather than throwing.
        try! _pairScores(pairs, _Dice(), checked: false)
    }

    /// `diceCoefficients(of:)`, throwing instead of trapping when a pair names a vertex not in the
    /// graph.
    ///
    /// - Throws: `VertexNotFound` when a vertex of `pairs` is not a vertex of the graph, before any
    ///   pair is scored.
    @inlinable
    public func diceCoefficients(checked pairs: some Sequence<(Vertex, Vertex)>) throws(VertexNotFound) -> [Double] {
        try _pairScores(pairs, _Dice(), checked: true)
    }

    /// The cosine similarity (Salton index) of `u` and `v`: |Γ(u) ∩ Γ(v)| / √(|Γ(u)| · |Γ(v)|), or
    /// 0 when either has no neighbors.
    ///
    /// Γ(x) is the set of vertices other than x that share an edge with x: self-loops are ignored
    /// and parallel edges count once.
    ///
    /// O(d(u) log d(u) + d(v) log d(v)) with vertex indices; O(d(u) + d(v)) hash operations
    /// without.
    ///
    /// - Parameters:
    ///   - u: A vertex of the graph.
    ///   - v: A vertex of the graph, possibly `u`.
    /// - Precondition: `u` and `v` are vertices of the graph.
    @inlinable
    public func cosineSimilarity(of u: Vertex, and v: Vertex) -> Double { _pairScore(of: u, and: v, _Cosine()) }

    /// `cosineSimilarity(of:and:)`, throwing instead of trapping when `u` or `v` is not a vertex of
    /// the graph.
    ///
    /// - Throws: `VertexNotFound` when `u` or `v` is not a vertex of the graph.
    @inlinable
    public func cosineSimilarity(checked u: Vertex, and v: Vertex) throws(VertexNotFound) -> Double {
        guard contains(u), contains(v) else { throw VertexNotFound() }
        return _pairScore(of: u, and: v, _Cosine())
    }

    /// The cosine similarity (Salton index) of each pair, in order: |Γ(u) ∩ Γ(v)| / √(|Γ(u)| ·
    /// |Γ(v)|), or 0 when either has no neighbors.
    ///
    /// O(n + m + Σ (d(u) + d(v))) over the pairs, for n vertices and m edges; a run of pairs with
    /// the same first vertex reads its neighbors once, so each later pair of the run costs O(d(v)).
    ///
    /// - Parameter pairs: Pairs of vertices of the graph; a pair may repeat or name one vertex twice.
    /// - Returns: One score per pair, in the order of `pairs`.
    /// - Precondition: every vertex of `pairs` is a vertex of the graph.
    @inlinable
    public func cosineSimilarities(of pairs: some Sequence<(Vertex, Vertex)>) -> [Double] {
        // The plain spelling traps rather than throwing.
        try! _pairScores(pairs, _Cosine(), checked: false)
    }

    /// `cosineSimilarities(of:)`, throwing instead of trapping when a pair names a vertex not in
    /// the graph.
    ///
    /// - Throws: `VertexNotFound` when a vertex of `pairs` is not a vertex of the graph, before any
    ///   pair is scored.
    @inlinable
    public func cosineSimilarities(checked pairs: some Sequence<(Vertex, Vertex)>) throws(VertexNotFound) -> [Double] {
        try _pairScores(pairs, _Cosine(), checked: true)
    }

    /// The Adamic–Adar index of `u` and `v`: the sum of 1 / ln |Γ(w)| over their common neighbors
    /// w.
    ///
    /// A common neighbor of two distinct vertices has at least two neighbors; when `u == v`, a
    /// neighbor with no other neighbor adds +∞.
    ///
    /// Γ(x) is the set of vertices other than x that share an edge with x: self-loops are ignored
    /// and parallel edges count once.
    ///
    /// With vertex indices the terms add in ascending vertex index, as in `adamicAdarIndices(of:)`, in
    /// O(d(u) log d(u) + d(v) log d(v) + Σ d(w) log d(w)) over the common neighbors w; without, they
    /// add in an unspecified order, in that many hash operations.
    ///
    /// - Parameters:
    ///   - u: A vertex of the graph.
    ///   - v: A vertex of the graph, possibly `u`.
    /// - Precondition: `u` and `v` are vertices of the graph.
    @inlinable
    public func adamicAdarIndex(of u: Vertex, and v: Vertex) -> Double { _pairScore(of: u, and: v, _AdamicAdar()) }

    /// `adamicAdarIndex(of:and:)`, throwing instead of trapping when `u` or `v` is not a vertex of
    /// the graph.
    ///
    /// - Throws: `VertexNotFound` when `u` or `v` is not a vertex of the graph.
    @inlinable
    public func adamicAdarIndex(checked u: Vertex, and v: Vertex) throws(VertexNotFound) -> Double {
        guard contains(u), contains(v) else { throw VertexNotFound() }
        return _pairScore(of: u, and: v, _AdamicAdar())
    }

    /// The Adamic–Adar index of each pair, in order: the sum of 1 / ln |Γ(w)| over the common
    /// neighbors w, added in ascending vertex index (position in `vertices` without vertex
    /// indices).
    ///
    /// When `u == v`, a neighbor with no other neighbor adds +∞.
    ///
    /// O(n + m log m + Σ (d(u) + d(v))) over the pairs, for n vertices and m edges; a run of pairs
    /// with the same first vertex reads its neighbors once, so each later pair of the run costs
    /// O(d(v)).
    ///
    /// - Parameter pairs: Pairs of vertices of the graph; a pair may repeat or name one vertex twice.
    /// - Returns: One score per pair, in the order of `pairs`.
    /// - Precondition: every vertex of `pairs` is a vertex of the graph.
    @inlinable
    public func adamicAdarIndices(of pairs: some Sequence<(Vertex, Vertex)>) -> [Double] {
        // The plain spelling traps rather than throwing.
        try! _pairScores(pairs, _AdamicAdar(), checked: false)
    }

    /// `adamicAdarIndices(of:)`, throwing instead of trapping when a pair names a vertex not in the
    /// graph.
    ///
    /// - Throws: `VertexNotFound` when a vertex of `pairs` is not a vertex of the graph, before any
    ///   pair is scored.
    @inlinable
    public func adamicAdarIndices(checked pairs: some Sequence<(Vertex, Vertex)>) throws(VertexNotFound) -> [Double] {
        try _pairScores(pairs, _AdamicAdar(), checked: true)
    }

    /// The resource allocation index of `u` and `v`: the sum of 1 / |Γ(w)| over their common
    /// neighbors w.
    ///
    /// Γ(x) is the set of vertices other than x that share an edge with x: self-loops are ignored
    /// and parallel edges count once.
    ///
    /// With vertex indices the terms add in ascending vertex index, as in
    /// `resourceAllocationIndices(of:)`, in O(d(u) log d(u) + d(v) log d(v) + Σ d(w) log d(w)) over
    /// the common neighbors w; without, they add in an unspecified order, in that many hash
    /// operations.
    ///
    /// - Parameters:
    ///   - u: A vertex of the graph.
    ///   - v: A vertex of the graph, possibly `u`.
    /// - Precondition: `u` and `v` are vertices of the graph.
    @inlinable
    public func resourceAllocationIndex(of u: Vertex, and v: Vertex) -> Double { _pairScore(of: u, and: v, _ResourceAllocation()) }

    /// `resourceAllocationIndex(of:and:)`, throwing instead of trapping when `u` or `v` is not a
    /// vertex of the graph.
    ///
    /// - Throws: `VertexNotFound` when `u` or `v` is not a vertex of the graph.
    @inlinable
    public func resourceAllocationIndex(checked u: Vertex, and v: Vertex) throws(VertexNotFound) -> Double {
        guard contains(u), contains(v) else { throw VertexNotFound() }
        return _pairScore(of: u, and: v, _ResourceAllocation())
    }

    /// The resource allocation index of each pair, in order: the sum of 1 / |Γ(w)| over the common
    /// neighbors w, added in ascending vertex index (position in `vertices` without vertex
    /// indices).
    ///
    /// O(n + m log m + Σ (d(u) + d(v))) over the pairs, for n vertices and m edges; a run of pairs
    /// with the same first vertex reads its neighbors once, so each later pair of the run costs
    /// O(d(v)).
    ///
    /// - Parameter pairs: Pairs of vertices of the graph; a pair may repeat or name one vertex twice.
    /// - Returns: One score per pair, in the order of `pairs`.
    /// - Precondition: every vertex of `pairs` is a vertex of the graph.
    @inlinable
    public func resourceAllocationIndices(of pairs: some Sequence<(Vertex, Vertex)>) -> [Double] {
        // The plain spelling traps rather than throwing.
        try! _pairScores(pairs, _ResourceAllocation(), checked: false)
    }

    /// `resourceAllocationIndices(of:)`, throwing instead of trapping when a pair names a vertex
    /// not in the graph.
    ///
    /// - Throws: `VertexNotFound` when a vertex of `pairs` is not a vertex of the graph, before any
    ///   pair is scored.
    @inlinable
    public func resourceAllocationIndices(checked pairs: some Sequence<(Vertex, Vertex)>) throws(VertexNotFound) -> [Double] {
        try _pairScores(pairs, _ResourceAllocation(), checked: true)
    }

    /// The preferential attachment score of `u` and `v`: |Γ(u)| · |Γ(v)|.
    ///
    /// Γ(x) is the set of vertices other than x that share an edge with x: self-loops are ignored
    /// and parallel edges count once.
    ///
    /// O(d(u) log d(u) + d(v) log d(v)) with vertex indices; O(d(u) + d(v)) hash operations
    /// without.
    ///
    /// - Parameters:
    ///   - u: A vertex of the graph.
    ///   - v: A vertex of the graph, possibly `u`.
    /// - Precondition: `u` and `v` are vertices of the graph.
    @inlinable
    public func preferentialAttachmentScore(of u: Vertex, and v: Vertex) -> Int { _pairScore(of: u, and: v, _PreferentialAttachment()) }

    /// `preferentialAttachmentScore(of:and:)`, throwing instead of trapping when `u` or `v` is not
    /// a vertex of the graph.
    ///
    /// - Throws: `VertexNotFound` when `u` or `v` is not a vertex of the graph.
    @inlinable
    public func preferentialAttachmentScore(checked u: Vertex, and v: Vertex) throws(VertexNotFound) -> Int {
        guard contains(u), contains(v) else { throw VertexNotFound() }
        return _pairScore(of: u, and: v, _PreferentialAttachment())
    }

    /// The preferential attachment score of each pair, in order: |Γ(u)| · |Γ(v)|.
    ///
    /// O(n + m + p) for p pairs, n vertices and m edges.
    ///
    /// - Parameter pairs: Pairs of vertices of the graph; a pair may repeat or name one vertex twice.
    /// - Returns: One score per pair, in the order of `pairs`.
    /// - Precondition: every vertex of `pairs` is a vertex of the graph.
    @inlinable
    public func preferentialAttachmentScores(of pairs: some Sequence<(Vertex, Vertex)>) -> [Int] {
        // The plain spelling traps rather than throwing.
        try! _pairScores(pairs, _PreferentialAttachment(), checked: false)
    }

    /// `preferentialAttachmentScores(of:)`, throwing instead of trapping when a pair names a vertex
    /// not in the graph.
    ///
    /// - Throws: `VertexNotFound` when a vertex of `pairs` is not a vertex of the graph, before any
    ///   pair is scored.
    @inlinable
    public func preferentialAttachmentScores(checked pairs: some Sequence<(Vertex, Vertex)>) throws(VertexNotFound) -> [Int] {
        try _pairScores(pairs, _PreferentialAttachment(), checked: true)
    }
}
