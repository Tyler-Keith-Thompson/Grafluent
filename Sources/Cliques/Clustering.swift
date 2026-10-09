import GraphProtocols

/// Each vertex's triangles in the simple graph, by Latapy's compact-forward listing: vertices
/// ranked by (degree, index), each one's forward neighbors (higher rank) marked, and each forward
/// neighbor's forward neighbors checked against the marks. O(m^(3/2)).
@inlinable
func _triangles(_ rows: _SimpleRows) -> [Int] {
    let n = rows.count
    guard n > 0 else { return [] }
    // Rank by degree, ties by index: a stable counting sort.
    let maxDegree = (0 ..< n).map { rows.degree($0) }.max()!
    var start = [Int](repeating: 0, count: maxDegree + 2)
    for v in 0 ..< n { start[rows.degree(v) + 1] += 1 }
    for d in 0 ... maxDegree { start[d + 1] += start[d] }
    var rank = [Int](repeating: 0, count: n)
    for v in 0 ..< n {
        rank[v] = start[rows.degree(v)]
        start[rows.degree(v)] += 1
    }
    // Forward rows.
    var offsets = [Int](repeating: 0, count: n + 1)
    var forward: [Int] = []
    forward.reserveCapacity(rows.neighbors.count / 2)
    for v in 0 ..< n {
        for k in rows.offsets[v] ..< rows.offsets[v + 1] where rank[rows.neighbors[k]] > rank[v] { forward.append(rows.neighbors[k]) }
        offsets[v + 1] = forward.count
    }
    var triangles = [Int](repeating: 0, count: n)
    var mark = [Int](repeating: -1, count: n)
    for v in 0 ..< n {
        for k in offsets[v] ..< offsets[v + 1] { mark[forward[k]] = v }
        for k in offsets[v] ..< offsets[v + 1] {
            let w = forward[k]
            for j in offsets[w] ..< offsets[w + 1] where mark[forward[j]] == v {
                triangles[v] += 1
                triangles[w] += 1
                triangles[forward[j]] += 1
            }
        }
    }
    return triangles
}

/// Triangles and clustering for every vertex of an undirected graph's simple graph, from one
/// pass (JGraphT's `ClusteringCoefficient`; NetworkX `triangles`, `clustering`, `transitivity`,
/// `average_clustering`).
@frozen
public struct ClusteringCoefficients<G: Graph> {
    @usableFromInline let _graph: G
    @usableFromInline let _numbers: [G.Vertex: Int]?
    @usableFromInline let _triangles: [Int]
    @usableFromInline let _degrees: [Int]
    @usableFromInline let _triangleCount: Int
    @usableFromInline let _transitivity: Double
    @usableFromInline let _averageClustering: Double

    @inlinable
    init(_ graph: G, listed: [G.Vertex]?, rows: _SimpleRows) {
        _graph = graph
        if let listed {
            var numbers: [G.Vertex: Int] = [:]
            numbers.reserveCapacity(listed.count)
            for (i, v) in listed.enumerated() { numbers[v] = i }
            _numbers = numbers
        } else {
            _numbers = nil
        }
        let triangles = Cliques._triangles(rows)
        let degrees = (0 ..< rows.count).map { rows.degree($0) }
        _triangles = triangles
        _degrees = degrees
        var corners = 0, triples = 0
        var sum = 0.0
        for v in triangles.indices {
            corners += triangles[v]
            let d = degrees[v]
            triples += d * (d - 1) / 2
            sum += _clustering(triangles[v], d)
        }
        _triangleCount = corners / 3
        _transitivity = corners == 0 ? 0 : Double(corners) / Double(triples)
        _averageClustering = triangles.isEmpty ? 0 : sum / Double(triangles.count)
    }

    @inlinable
    func _index(of vertex: G.Vertex) -> Int {
        if let _numbers {
            guard let v = _numbers[vertex] else { preconditionFailure("The vertex is not in the graph") }
            return v
        }
        precondition(_graph.contains(vertex), "The vertex is not in the graph")
        return _graph.vertexIndex(of: vertex)
    }

    /// The local clustering coefficient of `vertex`: 2T / (d(d − 1)) for its T triangles and d
    /// distinct neighbors; 0 when d < 2.
    ///
    /// - Precondition: `vertex` is a vertex of the graph.
    @inlinable
    public func clusteringCoefficient(of vertex: G.Vertex) -> Double {
        let v = _index(of: vertex)
        return _clustering(_triangles[v], _degrees[v])
    }

    /// The local clustering coefficient of the vertex at `index`.
    ///
    /// - Precondition: `index` is in `0..<vertexCount`.
    @inlinable
    public func clusteringCoefficient(ofIndex index: Int) -> Double {
        precondition(index >= 0 && index < _triangles.count, "Vertex index out of range")
        return _clustering(_triangles[index], _degrees[index])
    }

    /// The number of triangles through `vertex`.
    ///
    /// - Precondition: `vertex` is a vertex of the graph.
    @inlinable
    public func triangleCount(of vertex: G.Vertex) -> Int { _triangles[_index(of: vertex)] }

    /// The number of triangles through the vertex at `index`.
    ///
    /// - Precondition: `index` is in `0..<vertexCount`.
    @inlinable
    public func triangleCount(ofIndex index: Int) -> Int {
        precondition(index >= 0 && index < _triangles.count, "Vertex index out of range")
        return _triangles[index]
    }

    /// The number of triangles in the graph. O(1).
    @inlinable
    public var triangleCount: Int { _triangleCount }

    /// Three times the triangles over the connected triples; 0 when there are no triangles. O(1).
    @inlinable
    public var transitivity: Double { _transitivity }

    /// The mean local clustering coefficient over every vertex, zeros included, summed in
    /// `vertices` order; 0 for the empty graph. O(1).
    @inlinable
    public var averageClustering: Double { _averageClustering }
}

/// 2T / (d(d − 1)), or 0 when d < 2.
@inlinable
func _clustering(_ triangles: Int, _ degree: Int) -> Double {
    degree < 2 ? 0 : Double(2 * triangles) / Double(degree * (degree - 1))
}

extension ClusteringCoefficients: Sendable where G: Sendable, G.Vertex: Sendable {}

extension Graph {
    /// Triangles and clustering for every vertex of the simple graph (self-loops ignored,
    /// parallel edges counted once), in one compact-forward pass. O(m^(3/2)).
    @inlinable
    public func clusteringCoefficients() -> ClusteringCoefficients<Self> {
        ClusteringCoefficients(self, listed: _listedVertices(), rows: _simpleRows())
    }

    /// The number of triangles in the simple graph. O(m^(3/2)).
    @inlinable
    public func triangleCount() -> Int { _triangles(_simpleRows()).reduce(0, +) / 3 }

    /// Three times the triangles over the connected triples; 0 when there are no triangles.
    @inlinable
    public func transitivity() -> Double { clusteringCoefficients().transitivity }

    /// The mean local clustering coefficient over every vertex, zeros included; 0 when empty.
    @inlinable
    public func averageClustering() -> Double { clusteringCoefficients().averageClustering }

    /// The distinct neighbors of `vertex` other than itself, as vertex numbers or vertices.
    @inlinable
    func _localTriangles(of vertex: Vertex) -> (triangles: Int, degree: Int) {
        precondition(contains(vertex), "The vertex is not in the graph")
        if vertexIndexBound != nil {
            let v = vertexIndex(of: vertex)
            var around = Set<Int>()
            for w in neighborIndices(ofIndex: v) where w != v { around.insert(w) }
            var corners = 0
            for w in around {
                var seen = Set<Int>()
                for x in neighborIndices(ofIndex: w) where x != w && x != v && around.contains(x) && seen.insert(x).inserted { corners += 1 }
            }
            return (corners / 2, around.count)
        }
        var around = Set<Vertex>()
        for w in neighbors(of: vertex) where w != vertex { around.insert(w) }
        var corners = 0
        for w in around {
            var seen = Set<Vertex>()
            for x in neighbors(of: w) where x != w && x != vertex && around.contains(x) && seen.insert(x).inserted { corners += 1 }
        }
        return (corners / 2, around.count)
    }

    /// The number of triangles through `vertex`, from its neighborhood alone.
    ///
    /// - Precondition: `vertex` is a vertex of the graph.
    @inlinable
    public func triangleCount(of vertex: Vertex) -> Int { _localTriangles(of: vertex).triangles }

    /// The local clustering coefficient of `vertex`, from its neighborhood alone: 2T / (d(d − 1)),
    /// 0 when it has fewer than two distinct neighbors.
    ///
    /// - Precondition: `vertex` is a vertex of the graph.
    @inlinable
    public func clusteringCoefficient(of vertex: Vertex) -> Double {
        let (t, d) = _localTriangles(of: vertex)
        return _clustering(t, d)
    }
}
