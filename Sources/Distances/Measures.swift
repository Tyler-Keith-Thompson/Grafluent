import GraphProtocols
import Walks

// MARK: - Undirected

extension Graph {
    @inlinable
    func _vertex(number v: Int, _ listed: [Vertex]?) -> Vertex { listed?[v] ?? vertex(atIndex: v) }

    @inlinable
    func _number(of vertex: Vertex, _ listed: [Vertex]?) -> Int {
        precondition(contains(vertex), "The vertex is not in the graph")
        if let listed { return listed.firstIndex(of: vertex)! }
        return vertexIndex(of: vertex)
    }

    /// Every vertex's eccentricity: the greatest distance, in edges, to another vertex; nil for
    /// every vertex when the graph is not connected. Takes and Kosters' bounding: as few searches
    /// as the bounds need (a handful on sparse real-world graphs, n on a cycle). O(k(n + m)).
    @inlinable
    public func eccentricities() -> Eccentricities<DirectedView<Self>, Int> {
        let rows = _distanceRows()
        let values: [Int?] = _bounding(rows, .eccentricities).map { $0.lower.map(Optional.some) } ?? [Int?](repeating: nil, count: rows.count)
        return Eccentricities(directed, listed: _listedVertices(), values: values)
    }

    /// Every vertex's eccentricity by weighted distance, by Dijkstra's algorithm from every
    /// vertex. `weight` is called once per edge, in position order. O(n · m log n).
    ///
    /// - Precondition: Every weight is at least `.zero` and not NaN; the sums fit in `W`.
    @inlinable
    public func eccentricities<W: Comparable & AdditiveArithmetic>(weight: (Edges.Index) -> W) -> Eccentricities<DirectedView<Self>, W> {
        let rows = _distanceRows()
        return Eccentricities(directed, listed: _listedVertices(), values: _allEccentricities(rows, weights: _distanceWeights(weight)))
    }

    /// The eccentricity of one vertex: one search. Nil when the graph is not connected.
    ///
    /// - Precondition: `vertex` is a vertex of the graph.
    @inlinable
    public func eccentricity(of vertex: Vertex) -> Int? {
        let rows = _distanceRows()
        var searches = _BreadthFirstSearches(rows)
        let (e, reachedAll, _) = searches.search(from: _number(of: vertex, _listedVertices()))
        return reachedAll ? e : nil
    }

    /// The weighted eccentricity of one vertex: one search.
    ///
    /// - Precondition: `vertex` is a vertex; every weight is at least `.zero` and not NaN.
    @inlinable
    public func eccentricity<W: Comparable & AdditiveArithmetic>(of vertex: Vertex, weight: (Edges.Index) -> W) -> W? {
        let rows = _distanceRows()
        let weights = _distanceWeights(weight)
        var searches = _DijkstraSearches(rows, weights: weights)
        let (e, reachedAll, _) = searches.search(from: _number(of: vertex, _listedVertices()))
        return reachedAll ? e : nil
    }

    /// The least eccentricity; nil when the graph is not connected or empty. By bounding.
    @inlinable
    public func radius() -> Int? {
        let rows = _distanceRows()
        guard rows.count > 0, let bounds = _bounding(rows, .radius) else { return nil }
        return bounds.minUpper
    }

    /// The greatest eccentricity; nil when the graph is not connected or empty. By bounding.
    @inlinable
    public func diameter() -> Int? {
        let rows = _distanceRows()
        guard rows.count > 0, let bounds = _bounding(rows, .diameter) else { return nil }
        return bounds.maxLower
    }

    /// The vertices of least eccentricity, in `vertices` order; every vertex when the graph is not
    /// connected. By bounding.
    @inlinable
    public func center() -> [Vertex] {
        let rows = _distanceRows()
        let listed = _listedVertices()
        guard let bounds = _bounding(rows, .center) else { return (0 ..< rows.count).map { _vertex(number: $0, listed) } }
        return bounds.upper.indices.filter { bounds.upper[$0] == bounds.minUpper }.map { _vertex(number: $0, listed) }
    }

    /// The vertices of greatest eccentricity, in `vertices` order; every vertex when the graph is
    /// not connected. By bounding.
    @inlinable
    public func periphery() -> [Vertex] {
        let rows = _distanceRows()
        let listed = _listedVertices()
        guard let bounds = _bounding(rows, .periphery) else { return (0 ..< rows.count).map { _vertex(number: $0, listed) } }
        return bounds.lower.indices.filter { bounds.lower[$0] == bounds.maxLower }.map { _vertex(number: $0, listed) }
    }

    @inlinable
    public func radius<W: Comparable & AdditiveArithmetic>(weight: (Edges.Index) -> W) -> W? { eccentricities(weight: weight).radius }

    @inlinable
    public func diameter<W: Comparable & AdditiveArithmetic>(weight: (Edges.Index) -> W) -> W? { eccentricities(weight: weight).diameter }

    @inlinable
    public func center<W: Comparable & AdditiveArithmetic>(weight: (Edges.Index) -> W) -> [Vertex] { eccentricities(weight: weight).center }

    @inlinable
    public func periphery<W: Comparable & AdditiveArithmetic>(weight: (Edges.Index) -> W) -> [Vertex] { eccentricities(weight: weight).periphery }

    /// The path, with its edges, between the lexicographically least pair of vertices (by vertex
    /// index) at distance `diameter()`: from the first vertex of greatest eccentricity to the first
    /// vertex farthest from it, as breadth-first search finds it (each vertex reached first through
    /// its first edge in row order). Nil when the graph is not connected or empty.
    @inlinable
    public func diameterPath() -> Path<Vertex, Edges.Index>? {
        let rows = _distanceRows()
        guard rows.count > 0, let bounds = _bounding(rows, .periphery) else { return nil }
        let u = bounds.lower.firstIndex(of: bounds.maxLower)!
        var searches = _BreadthFirstSearches(rows)
        _ = searches.search(from: u, parents: true)
        let v = searches.distance.firstIndex(of: bounds.maxLower)!
        return _path(u, v, searches.parentSlot, rows)
    }

    /// The same by weighted distance, and its length summed along the path (with floating point
    /// it can differ from `diameter(weight:)` in the last digit). Nil when not connected or empty.
    ///
    /// - Precondition: Every weight is at least `.zero` and not NaN; the sums fit in `W`.
    @inlinable
    public func diameterPath<W: Comparable & AdditiveArithmetic>(weight: (Edges.Index) -> W) -> (path: Path<Vertex, Edges.Index>, distance: W)? {
        let rows = _distanceRows()
        let weights = _distanceWeights(weight)
        let values = _allEccentricities(rows, weights: weights)
        guard rows.count > 0, let diameter = _radiusAndDiameter(values).diameter else { return nil }
        let u = values.firstIndex { $0 == diameter }!
        var searches = _DijkstraSearches(rows, weights: weights)
        _ = searches.search(from: u, parents: true)
        var v = u
        for x in 0 ..< rows.count where searches.distance[x] > searches.distance[v] { v = x }
        return (_path(u, v, searches.parentSlot, rows), searches.distance[v])
    }

    @inlinable
    func _path(_ u: Int, _ v: Int, _ parentSlot: [Int], _ rows: _DistanceRows) -> Path<Vertex, Edges.Index> {
        let (vertexNumbers, edgeNumbers) = _pathNumbers(u, v, parentSlot, rows)
        let listed = _listedVertices()
        let positions = Array(edges.indices)
        return Path(_uncheckedVertices: vertexNumbers.map { _vertex(number: $0, listed) }, edges: edgeNumbers.map { positions[$0] })
    }

    /// The vertices of least total distance to all others (NetworkX 3.7 `centroid`, also called
    /// the median or barycenter), in `vertices` order; every vertex when the graph is not
    /// connected. On a tree it is Jordan's centroid. O(n(n + m)).
    @inlinable
    public func centroid() -> [Vertex] {
        let listed = _listedVertices()
        return _leastTotals(_totals(_distanceRows())).map { _vertex(number: $0, listed) }
    }

    /// The vertices of least total weighted distance to all others. O(n · m log n).
    ///
    /// - Precondition: Every weight is at least `.zero` and not NaN; the sums fit in `W`.
    @inlinable
    public func centroid<W: Comparable & AdditiveArithmetic>(weight: (Edges.Index) -> W) -> [Vertex] {
        let listed = _listedVertices()
        return _leastTotals(_totals(_distanceRows(), weights: _distanceWeights(weight))).map { _vertex(number: $0, listed) }
    }

    /// The sum of the distances over all unordered pairs of vertices (NetworkX `wiener_index`);
    /// nil when the graph is not connected, 0 when it has fewer than two vertices. O(n(n + m)).
    @inlinable
    public func wienerIndex() -> Int? { _wienerIndex(_distanceRows()) }

    /// The sum of the weighted distances over all unordered pairs, sources in index order and each
    /// one's later targets in index order.
    ///
    /// - Precondition: Every weight is at least `.zero` and not NaN; the sums fit in `W`.
    @inlinable
    public func wienerIndex<W: Comparable & AdditiveArithmetic>(weight: (Edges.Index) -> W) -> W? {
        _wienerIndex(_distanceRows(), weights: _distanceWeights(weight))
    }

    /// The Wiener index over the number of pairs (NetworkX `average_shortest_path_length`); 0 for
    /// one vertex; nil when the graph is empty or not connected.
    @inlinable
    public func averageShortestPathLength() -> Double? {
        let n = vertexCount
        guard n > 0, let total = wienerIndex() else { return nil }
        return n == 1 ? 0 : Double(total) / Double(_pairCount(n, undirected: true))
    }

    /// The weighted Wiener index over the number of pairs.
    ///
    /// - Precondition: Every weight is at least `.zero` and not NaN.
    @inlinable
    public func averageShortestPathLength<W: BinaryFloatingPoint>(weight: (Edges.Index) -> W) -> W? {
        let n = vertexCount
        guard n > 0, let total = wienerIndex(weight: weight) else { return nil }
        return n == 1 ? 0 : total / W(_pairCount(n, undirected: true))
    }

    /// 2m / (n(n − 1)), every edge counted (self-loops and parallel copies included, so it can
    /// exceed 1); 0 when there are fewer than two vertices (NetworkX `density`). O(1).
    @inlinable
    public var density: Double {
        let n = vertexCount
        return n <= 1 ? 0 : 2 * Double(edgeCount) / (Double(n) * Double(n - 1))
    }
}
