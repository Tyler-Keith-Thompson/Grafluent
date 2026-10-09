import GraphProtocols
import Walks

/// The vertex and edge numbers of the path a search with parents found from `u` to `v`.
@inlinable
func _pathNumbers(_ u: Int, _ v: Int, _ parentSlot: [Int], _ rows: _DistanceRows) -> (vertices: [Int], edges: [Int]) {
    var vertices: [Int] = [v], edges: [Int] = []
    var x = v
    while x != u {
        let slot = parentSlot[x]
        // The slot's source: the row holding it.
        var lo = 0, hi = rows.count
        while hi - lo > 1 {
            let mid = (lo + hi) / 2
            if rows.offsets[mid] <= slot { lo = mid } else { hi = mid }
        }
        edges.append(rows.edges[slot])
        x = lo
        vertices.append(x)
    }
    return (vertices.reversed(), edges.reversed())
}

extension DirectedGraph {
    @inlinable
    func _vertex(number v: Int, _ listed: [Vertex]?) -> Vertex { listed?[v] ?? vertex(atIndex: v) }

    @inlinable
    func _number(of vertex: Vertex, _ listed: [Vertex]?) -> Int {
        precondition(contains(vertex), "The vertex is not in the graph")
        if let listed { return listed.firstIndex(of: vertex)! }
        return vertexIndex(of: vertex)
    }

    @inlinable
    func _path(_ numbers: (vertices: [Int], edges: [Int]), _ listed: [Vertex]?) -> Path<Vertex, Edges.Index> {
        let positions = Array(edges.indices)
        return Path(_uncheckedVertices: numbers.vertices.map { _vertex(number: $0, listed) }, edges: numbers.edges.map { positions[$0] })
    }

    /// Every vertex's eccentricity over out-distances: the greatest distance from it to another
    /// vertex; nil when some vertex is not reachable from it. Breadth-first search from every
    /// vertex, skipping those reached by a search that missed a vertex (they miss it too).
    /// O(n(n + m)).
    @inlinable
    public func eccentricities() -> Eccentricities<Self, Int> {
        let (rows, listed) = _distanceRows()
        return Eccentricities(self, listed: listed, values: _allEccentricities(rows))
    }

    /// Every vertex's eccentricity by weighted out-distance, by Dijkstra's algorithm. `weight` is
    /// called once per edge, in position order. O(n · m log n).
    ///
    /// - Precondition: Every weight is at least `.zero` and not NaN; the sums fit in `W`.
    @inlinable
    public func eccentricities<W: Comparable & AdditiveArithmetic>(weight: (Edges.Index) -> W) -> Eccentricities<Self, W> {
        let (rows, listed) = _distanceRows()
        return Eccentricities(self, listed: listed, values: _allEccentricities(rows, weights: _distanceWeights(weight)))
    }

    /// The eccentricity of one vertex over out-distances: one search.
    ///
    /// - Precondition: `vertex` is a vertex of the graph.
    @inlinable
    public func eccentricity(of vertex: Vertex) -> Int? {
        let (rows, listed) = _distanceRows()
        var searches = _BreadthFirstSearches(rows)
        let (e, reachedAll, _) = searches.search(from: _number(of: vertex, listed))
        return reachedAll ? e : nil
    }

    /// The weighted eccentricity of one vertex: one search.
    ///
    /// - Precondition: `vertex` is a vertex; every weight is at least `.zero` and not NaN.
    @inlinable
    public func eccentricity<W: Comparable & AdditiveArithmetic>(of vertex: Vertex, weight: (Edges.Index) -> W) -> W? {
        let (rows, listed) = _distanceRows()
        var searches = _DijkstraSearches(rows, weights: _distanceWeights(weight))
        let (e, reachedAll, _) = searches.search(from: _number(of: vertex, listed))
        return reachedAll ? e : nil
    }

    /// The least eccentricity: finite when some vertex reaches every vertex; nil otherwise, or
    /// when empty.
    @inlinable
    public func radius() -> Int? { eccentricities().radius }

    /// The greatest eccentricity; nil when the graph is not strongly connected, or empty. Stops at
    /// the first search that misses a vertex.
    @inlinable
    public func diameter() -> Int? {
        let (rows, _) = _distanceRows()
        return _radiusAndDiameter(_allEccentricities(rows, stopAtMiss: true)).diameter
    }

    /// The vertices of least eccentricity, in `vertices` order.
    @inlinable
    public func center() -> [Vertex] { eccentricities().center }

    /// The vertices of greatest eccentricity, in `vertices` order: those that do not reach every
    /// vertex when the graph is not strongly connected.
    @inlinable
    public func periphery() -> [Vertex] { eccentricities().periphery }

    @inlinable
    public func radius<W: Comparable & AdditiveArithmetic>(weight: (Edges.Index) -> W) -> W? { eccentricities(weight: weight).radius }

    @inlinable
    public func diameter<W: Comparable & AdditiveArithmetic>(weight: (Edges.Index) -> W) -> W? {
        let (rows, _) = _distanceRows()
        return _radiusAndDiameter(_allEccentricities(rows, weights: _distanceWeights(weight), stopAtMiss: true)).diameter
    }

    @inlinable
    public func center<W: Comparable & AdditiveArithmetic>(weight: (Edges.Index) -> W) -> [Vertex] { eccentricities(weight: weight).center }

    @inlinable
    public func periphery<W: Comparable & AdditiveArithmetic>(weight: (Edges.Index) -> W) -> [Vertex] { eccentricities(weight: weight).periphery }

    /// A shortest path between the lexicographically least ordered pair of vertices at distance
    /// `diameter()`: from the first vertex of greatest eccentricity to the first vertex farthest
    /// from it, as breadth-first search finds it. Nil when not strongly connected, or empty.
    @inlinable
    public func diameterPath() -> Path<Vertex, Edges.Index>? {
        let (rows, listed) = _distanceRows()
        let values = _allEccentricities(rows, stopAtMiss: true)
        guard rows.count > 0, let diameter = _radiusAndDiameter(values).diameter else { return nil }
        let u = values.firstIndex { $0 == diameter }!
        var searches = _BreadthFirstSearches(rows)
        _ = searches.search(from: u, parents: true)
        let v = searches.distance.firstIndex(of: diameter)!
        return _path(_pathNumbers(u, v, searches.parentSlot, rows), listed)
    }

    /// The same by weighted distance, and its length: `diameter(weight:)`.
    ///
    /// - Precondition: Every weight is at least `.zero` and not NaN; the sums fit in `W`.
    @inlinable
    public func diameterPath<W: Comparable & AdditiveArithmetic>(weight: (Edges.Index) -> W) -> (path: Path<Vertex, Edges.Index>, distance: W)? {
        let (rows, listed) = _distanceRows()
        let weights = _distanceWeights(weight)
        let values = _allEccentricities(rows, weights: weights, stopAtMiss: true)
        guard rows.count > 0, let diameter = _radiusAndDiameter(values).diameter else { return nil }
        let u = values.firstIndex { $0 == diameter }!
        var searches = _DijkstraSearches(rows, weights: weights)
        _ = searches.search(from: u, parents: true)
        var v = u
        for x in 0 ..< rows.count where searches.distance[x] > searches.distance[v] { v = x }
        return (_path(_pathNumbers(u, v, searches.parentSlot, rows), listed), searches.distance[v])
    }

    /// The vertices of least total out-distance to all others (NetworkX 3.7 `centroid`), in
    /// `vertices` order. A vertex that does not reach every vertex has an infinite total, so when
    /// some do, the least among those that reach all is returned (where NetworkX raises), and when
    /// none does, every vertex.
    @inlinable
    public func centroid() -> [Vertex] {
        let (rows, listed) = _distanceRows()
        return _leastTotals(_totals(rows)).map { _vertex(number: $0, listed) }
    }

    @inlinable
    public func centroid<W: Comparable & AdditiveArithmetic>(weight: (Edges.Index) -> W) -> [Vertex] {
        let (rows, listed) = _distanceRows()
        return _leastTotals(_totals(rows, weights: _distanceWeights(weight))).map { _vertex(number: $0, listed) }
    }

    /// The sum of the distances over all ordered pairs; nil when not strongly connected.
    @inlinable
    public func wienerIndex() -> Int? { _wienerIndex(_distanceRows().rows) }

    @inlinable
    public func wienerIndex<W: Comparable & AdditiveArithmetic>(weight: (Edges.Index) -> W) -> W? {
        _wienerIndex(_distanceRows().rows, weights: _distanceWeights(weight))
    }

    /// The Wiener index over the number of ordered pairs; 0 for one vertex; nil when empty or not
    /// strongly connected.
    @inlinable
    public func averageShortestPathLength() -> Double? {
        let n = vertexCount
        guard n > 0, let total = wienerIndex() else { return nil }
        return n == 1 ? 0 : Double(total) / Double(_pairCount(n, undirected: false))
    }

    @inlinable
    public func averageShortestPathLength<W: BinaryFloatingPoint>(weight: (Edges.Index) -> W) -> W? {
        let n = vertexCount
        guard n > 0, let total = wienerIndex(weight: weight) else { return nil }
        return n == 1 ? 0 : total / W(_pairCount(n, undirected: false))
    }

    /// m / (n(n − 1)), every edge counted; 0 when there are fewer than two vertices. O(1).
    @inlinable
    public var density: Double {
        let n = vertexCount
        return n <= 1 ? 0 : Double(edgeCount) / (Double(n) * Double(n - 1))
    }
}
