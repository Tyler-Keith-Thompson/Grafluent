import GraphProtocols

extension Graph {
    /// Closeness centrality (Bavelas; NetworkX `closeness_centrality`): with r the number of vertices
    /// that reach u (u included) and S the sum of their distances, (r − 1)/S · (r − 1)/(n − 1), the
    /// second factor (Wasserman and Faust's) only when `wfImproved`. 0 when nothing else reaches u.
    /// Distances count edges. One breadth-first search per vertex: O(n(n + m)).
    @inlinable
    public func closenessCentrality(wfImproved: Bool = true) -> CentralityScores<DirectedView<Self>> {
        let rows = _centralityRows(readsEdges: false)
        let numbers = _centralityNumbers()
        var search = _UnweightedCentralitySearch(rows)
        return CentralityScores(directed, numbers: numbers, scores: _closenessScores(&search, wfImproved: wfImproved))
    }

    /// The closeness centrality of `vertex` alone: one search, O(n + m).
    ///
    /// - Precondition: `vertex` is a vertex of the graph.
    @inlinable
    public func closenessCentrality(of vertex: Vertex, wfImproved: Bool = true) -> Double {
        let rows = _centralityRows(readsEdges: false)
        let numbers = _centralityNumbers()
        var search = _UnweightedCentralitySearch(rows)
        return Centrality._closeness(&search, at: _centralityNumber(of: vertex, numbers), wfImproved: wfImproved)
    }

    /// Closeness centrality over weighted distances; `weight` is called once per edge, in
    /// position order, before any search. Distances are summed in `W`, and a sum `W`
    /// cannot hold traps. O(n · m log n).
    ///
    /// - Precondition: every weight is at least zero.
    @inlinable
    public func closenessCentrality<W: BinaryInteger>(weight: (Edges.Index) -> W, wfImproved: Bool = true) -> CentralityScores<DirectedView<Self>> {
        let rows = _centralityRows(readsEdges: true)
        let numbers = _centralityNumbers()
        var search = _weightedSearch(_IntegerConversion<W>.self, rows, _centralityWeights(weight, { $0 >= .zero }, _integerWeightMessage))
        return CentralityScores(directed, numbers: numbers, scores: _closenessScores(&search, wfImproved: wfImproved))
    }

    /// The weighted closeness centrality of `vertex` alone: one search, O(m log n).
    ///
    /// - Precondition: `vertex` is a vertex of the graph, and every weight is at least zero.
    @inlinable
    public func closenessCentrality<W: BinaryInteger>(of vertex: Vertex, weight: (Edges.Index) -> W, wfImproved: Bool = true) -> Double {
        let rows = _centralityRows(readsEdges: true)
        let numbers = _centralityNumbers()
        var search = _weightedSearch(_IntegerConversion<W>.self, rows, _centralityWeights(weight, { $0 >= .zero }, _integerWeightMessage))
        return Centrality._closeness(&search, at: _centralityNumber(of: vertex, numbers), wfImproved: wfImproved)
    }

    /// Closeness centrality over weighted distances; `weight` is called once per edge, in
    /// position order, before any search. Distances are summed in `W`, and a sum `W`
    /// cannot hold traps. O(n · m log n).
    ///
    /// - Precondition: every weight is at least zero and not NaN.
    @inlinable
    public func closenessCentrality<W: BinaryFloatingPoint>(weight: (Edges.Index) -> W, wfImproved: Bool = true) -> CentralityScores<DirectedView<Self>> {
        let rows = _centralityRows(readsEdges: true)
        let numbers = _centralityNumbers()
        var search = _weightedSearch(_FloatingConversion<W>.self, rows, _centralityWeights(weight, { $0 >= .zero && !$0.isNaN }, _floatingWeightMessage))
        return CentralityScores(directed, numbers: numbers, scores: _closenessScores(&search, wfImproved: wfImproved))
    }

    /// The weighted closeness centrality of `vertex` alone: one search, O(m log n).
    ///
    /// - Precondition: `vertex` is a vertex of the graph, and every weight is at least zero and not NaN.
    @inlinable
    public func closenessCentrality<W: BinaryFloatingPoint>(of vertex: Vertex, weight: (Edges.Index) -> W, wfImproved: Bool = true) -> Double {
        let rows = _centralityRows(readsEdges: true)
        let numbers = _centralityNumbers()
        var search = _weightedSearch(_FloatingConversion<W>.self, rows, _centralityWeights(weight, { $0 >= .zero && !$0.isNaN }, _floatingWeightMessage))
        return Centrality._closeness(&search, at: _centralityNumber(of: vertex, numbers), wfImproved: wfImproved)
    }

    /// Harmonic centrality (Marchiori and Latora; NetworkX `harmonic_centrality`): Σ 1/d(v, u) over
    /// the vertices v at a positive finite distance, not normalized. O(n(n + m)).
    @inlinable
    public func harmonicCentrality() -> CentralityScores<DirectedView<Self>> {
        let rows = _centralityRows(readsEdges: false)
        let numbers = _centralityNumbers()
        var search = _UnweightedCentralitySearch(rows)
        return CentralityScores(directed, numbers: numbers, scores: _harmonicScores(&search))
    }

    /// The harmonic centrality of `vertex` alone: one search, O(n + m).
    ///
    /// - Precondition: `vertex` is a vertex of the graph.
    @inlinable
    public func harmonicCentrality(of vertex: Vertex) -> Double {
        let rows = _centralityRows(readsEdges: false)
        let numbers = _centralityNumbers()
        var search = _UnweightedCentralitySearch(rows)
        return search.sums(from: _centralityNumber(of: vertex, numbers)).harmonic
    }

    /// Harmonic centrality over weighted distances; a vertex at distance 0 adds nothing.
    ///
    /// - Precondition: every weight is at least zero.
    @inlinable
    public func harmonicCentrality<W: BinaryInteger>(weight: (Edges.Index) -> W) -> CentralityScores<DirectedView<Self>> {
        let rows = _centralityRows(readsEdges: true)
        let numbers = _centralityNumbers()
        var search = _weightedSearch(_IntegerConversion<W>.self, rows, _centralityWeights(weight, { $0 >= .zero }, _integerWeightMessage))
        return CentralityScores(directed, numbers: numbers, scores: _harmonicScores(&search))
    }

    /// The weighted harmonic centrality of `vertex` alone.
    ///
    /// - Precondition: `vertex` is a vertex of the graph, and every weight is at least zero.
    @inlinable
    public func harmonicCentrality<W: BinaryInteger>(of vertex: Vertex, weight: (Edges.Index) -> W) -> Double {
        let rows = _centralityRows(readsEdges: true)
        let numbers = _centralityNumbers()
        var search = _weightedSearch(_IntegerConversion<W>.self, rows, _centralityWeights(weight, { $0 >= .zero }, _integerWeightMessage))
        return search.sums(from: _centralityNumber(of: vertex, numbers)).harmonic
    }

    /// Harmonic centrality over weighted distances; a vertex at distance 0 adds nothing.
    ///
    /// - Precondition: every weight is at least zero and not NaN.
    @inlinable
    public func harmonicCentrality<W: BinaryFloatingPoint>(weight: (Edges.Index) -> W) -> CentralityScores<DirectedView<Self>> {
        let rows = _centralityRows(readsEdges: true)
        let numbers = _centralityNumbers()
        var search = _weightedSearch(_FloatingConversion<W>.self, rows, _centralityWeights(weight, { $0 >= .zero && !$0.isNaN }, _floatingWeightMessage))
        return CentralityScores(directed, numbers: numbers, scores: _harmonicScores(&search))
    }

    /// The weighted harmonic centrality of `vertex` alone.
    ///
    /// - Precondition: `vertex` is a vertex of the graph, and every weight is at least zero and not NaN.
    @inlinable
    public func harmonicCentrality<W: BinaryFloatingPoint>(of vertex: Vertex, weight: (Edges.Index) -> W) -> Double {
        let rows = _centralityRows(readsEdges: true)
        let numbers = _centralityNumbers()
        var search = _weightedSearch(_FloatingConversion<W>.self, rows, _centralityWeights(weight, { $0 >= .zero && !$0.isNaN }, _floatingWeightMessage))
        return search.sums(from: _centralityNumber(of: vertex, numbers)).harmonic
    }
}

extension DirectedGraph {
    /// Closeness centrality over incoming distances d(v, u) (NetworkX `closeness_centrality`): with
    /// r the number of vertices that reach u (u included) and S the sum of their distances,
    /// (r − 1)/S · (r − 1)/(n − 1), the second factor only when `wfImproved`. 0 when nothing else
    /// reaches u. For outgoing distances, use the reversed graph. O(n(n + m)).
    @inlinable
    public func closenessCentrality(wfImproved: Bool = true) -> CentralityScores<Self> {
        let (copied, numbers) = _centralityRows(readsEdges: false)
        let rows = copied.transposed()
        var search = _UnweightedCentralitySearch(rows)
        return CentralityScores(self, numbers: numbers, scores: _closenessScores(&search, wfImproved: wfImproved))
    }

    /// The closeness centrality of `vertex` alone: one search, O(n + m).
    ///
    /// - Precondition: `vertex` is a vertex of the graph.
    @inlinable
    public func closenessCentrality(of vertex: Vertex, wfImproved: Bool = true) -> Double {
        let (copied, numbers) = _centralityRows(readsEdges: false)
        let rows = copied.transposed()
        var search = _UnweightedCentralitySearch(rows)
        return Centrality._closeness(&search, at: _centralityNumber(of: vertex, numbers), wfImproved: wfImproved)
    }

    /// Closeness centrality over weighted incoming distances; `weight` is called once per edge, in
    /// position order, before any search. Distances are summed in `W`, and a sum `W`
    /// cannot hold traps. O(n · m log n).
    ///
    /// - Precondition: every weight is at least zero.
    @inlinable
    public func closenessCentrality<W: BinaryInteger>(weight: (Edges.Index) -> W, wfImproved: Bool = true) -> CentralityScores<Self> {
        let (copied, numbers) = _centralityRows(readsEdges: true)
        let rows = copied.transposed()
        var search = _weightedSearch(_IntegerConversion<W>.self, rows, _centralityWeights(weight, { $0 >= .zero }, _integerWeightMessage))
        return CentralityScores(self, numbers: numbers, scores: _closenessScores(&search, wfImproved: wfImproved))
    }

    /// The weighted closeness centrality of `vertex` alone: one search, O(m log n).
    ///
    /// - Precondition: `vertex` is a vertex of the graph, and every weight is at least zero.
    @inlinable
    public func closenessCentrality<W: BinaryInteger>(of vertex: Vertex, weight: (Edges.Index) -> W, wfImproved: Bool = true) -> Double {
        let (copied, numbers) = _centralityRows(readsEdges: true)
        let rows = copied.transposed()
        var search = _weightedSearch(_IntegerConversion<W>.self, rows, _centralityWeights(weight, { $0 >= .zero }, _integerWeightMessage))
        return Centrality._closeness(&search, at: _centralityNumber(of: vertex, numbers), wfImproved: wfImproved)
    }

    /// Closeness centrality over weighted incoming distances; `weight` is called once per edge, in
    /// position order, before any search. Distances are summed in `W`, and a sum `W`
    /// cannot hold traps. O(n · m log n).
    ///
    /// - Precondition: every weight is at least zero and not NaN.
    @inlinable
    public func closenessCentrality<W: BinaryFloatingPoint>(weight: (Edges.Index) -> W, wfImproved: Bool = true) -> CentralityScores<Self> {
        let (copied, numbers) = _centralityRows(readsEdges: true)
        let rows = copied.transposed()
        var search = _weightedSearch(_FloatingConversion<W>.self, rows, _centralityWeights(weight, { $0 >= .zero && !$0.isNaN }, _floatingWeightMessage))
        return CentralityScores(self, numbers: numbers, scores: _closenessScores(&search, wfImproved: wfImproved))
    }

    /// The weighted closeness centrality of `vertex` alone: one search, O(m log n).
    ///
    /// - Precondition: `vertex` is a vertex of the graph, and every weight is at least zero and not NaN.
    @inlinable
    public func closenessCentrality<W: BinaryFloatingPoint>(of vertex: Vertex, weight: (Edges.Index) -> W, wfImproved: Bool = true) -> Double {
        let (copied, numbers) = _centralityRows(readsEdges: true)
        let rows = copied.transposed()
        var search = _weightedSearch(_FloatingConversion<W>.self, rows, _centralityWeights(weight, { $0 >= .zero && !$0.isNaN }, _floatingWeightMessage))
        return Centrality._closeness(&search, at: _centralityNumber(of: vertex, numbers), wfImproved: wfImproved)
    }

    /// Harmonic centrality (Marchiori and Latora; NetworkX `harmonic_centrality`): Σ 1/d(v, u) over
    /// the vertices v at a positive finite incoming distance, not normalized. O(n(n + m)).
    @inlinable
    public func harmonicCentrality() -> CentralityScores<Self> {
        let (copied, numbers) = _centralityRows(readsEdges: false)
        let rows = copied.transposed()
        var search = _UnweightedCentralitySearch(rows)
        return CentralityScores(self, numbers: numbers, scores: _harmonicScores(&search))
    }

    /// The harmonic centrality of `vertex` alone: one search, O(n + m).
    ///
    /// - Precondition: `vertex` is a vertex of the graph.
    @inlinable
    public func harmonicCentrality(of vertex: Vertex) -> Double {
        let (copied, numbers) = _centralityRows(readsEdges: false)
        let rows = copied.transposed()
        var search = _UnweightedCentralitySearch(rows)
        return search.sums(from: _centralityNumber(of: vertex, numbers)).harmonic
    }

    /// Harmonic centrality over weighted incoming distances; a vertex at distance 0 adds nothing.
    ///
    /// - Precondition: every weight is at least zero.
    @inlinable
    public func harmonicCentrality<W: BinaryInteger>(weight: (Edges.Index) -> W) -> CentralityScores<Self> {
        let (copied, numbers) = _centralityRows(readsEdges: true)
        let rows = copied.transposed()
        var search = _weightedSearch(_IntegerConversion<W>.self, rows, _centralityWeights(weight, { $0 >= .zero }, _integerWeightMessage))
        return CentralityScores(self, numbers: numbers, scores: _harmonicScores(&search))
    }

    /// The weighted harmonic centrality of `vertex` alone.
    ///
    /// - Precondition: `vertex` is a vertex of the graph, and every weight is at least zero.
    @inlinable
    public func harmonicCentrality<W: BinaryInteger>(of vertex: Vertex, weight: (Edges.Index) -> W) -> Double {
        let (copied, numbers) = _centralityRows(readsEdges: true)
        let rows = copied.transposed()
        var search = _weightedSearch(_IntegerConversion<W>.self, rows, _centralityWeights(weight, { $0 >= .zero }, _integerWeightMessage))
        return search.sums(from: _centralityNumber(of: vertex, numbers)).harmonic
    }

    /// Harmonic centrality over weighted incoming distances; a vertex at distance 0 adds nothing.
    ///
    /// - Precondition: every weight is at least zero and not NaN.
    @inlinable
    public func harmonicCentrality<W: BinaryFloatingPoint>(weight: (Edges.Index) -> W) -> CentralityScores<Self> {
        let (copied, numbers) = _centralityRows(readsEdges: true)
        let rows = copied.transposed()
        var search = _weightedSearch(_FloatingConversion<W>.self, rows, _centralityWeights(weight, { $0 >= .zero && !$0.isNaN }, _floatingWeightMessage))
        return CentralityScores(self, numbers: numbers, scores: _harmonicScores(&search))
    }

    /// The weighted harmonic centrality of `vertex` alone.
    ///
    /// - Precondition: `vertex` is a vertex of the graph, and every weight is at least zero and not NaN.
    @inlinable
    public func harmonicCentrality<W: BinaryFloatingPoint>(of vertex: Vertex, weight: (Edges.Index) -> W) -> Double {
        let (copied, numbers) = _centralityRows(readsEdges: true)
        let rows = copied.transposed()
        var search = _weightedSearch(_FloatingConversion<W>.self, rows, _centralityWeights(weight, { $0 >= .zero && !$0.isNaN }, _floatingWeightMessage))
        return search.sums(from: _centralityNumber(of: vertex, numbers)).harmonic
    }
}
