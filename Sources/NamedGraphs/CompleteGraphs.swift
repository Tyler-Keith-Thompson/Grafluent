import AdjacencyListModule
import BipartiteGraphs
import GraphProtocols

extension _GraphConstruction {
    /// The complete graph Kₙ on `0..<vertexCount`: an edge between every pair of vertices
    /// (NetworkX `complete_graph`, igraph `Full`). n(n − 1)/2 edges, `UndirectedEdge(u, v)` with
    /// u < v in lexicographic order. O(n²), with the edges computed as the graph reads them, so no
    /// edge list is allocated. `complete(vertexCount: 0)` is the null graph.
    ///
    /// - Precondition: `vertexCount ≥ 0`, and n(n − 1)/2 fits in `Int`.
    @inlinable
    public static func complete(vertexCount n: Int) -> Self {
        _checkCount(n)
        precondition(_unorderedPairCount(n) != nil, "edge count overflows Int")
        return Self(_vertexCount: n, sortedEdges: _AscendingPairs(n).lazy.map(_undirected))
    }

    /// The complete bipartite graph K_{a,b}: left side `0..<leftCount`, right side
    /// `leftCount..<leftCount + rightCount` (NetworkX's numbering), an edge from every left vertex to
    /// every right one, left end first, in lexicographic order. a·b edges, O(a + b + ab), with no
    /// edge list allocated. The sides as a structure are `BipartiteGraph.completeBipartite`.
    ///
    /// - Precondition: both counts are non-negative, and a + b and a·b fit in `Int`.
    @inlinable
    public static func completeBipartite(leftCount a: Int, rightCount b: Int) -> Self {
        _checkCompleteBipartite(a, b)
        return Self(_vertexCount: a + b, sortedEdges: _CrossPairs(a, b).lazy.map(_undirected))
    }
}

extension _DirectedGraphConstruction {
    /// The complete directed graph on `0..<vertexCount`: both arcs between every pair, n(n − 1)
    /// arcs in row-major order (NetworkX `complete_graph(n, create_using=nx.DiGraph)`). O(n²), with
    /// no edge list allocated.
    ///
    /// - Precondition: `vertexCount ≥ 0`, and n(n − 1) fits in `Int`.
    @inlinable
    public static func complete(vertexCount n: Int) -> Self {
        _checkCount(n)
        precondition(_orderedPairCount(n) != nil, "edge count overflows Int")
        return Self(_vertexCount: n, sortedEdges: _DistinctPairs(n))
    }

    /// K_{a,b} oriented from the left side `0..<leftCount` to the right side
    /// `leftCount..<leftCount + rightCount` (igraph `Full_Bipartite(mode="out")`): a·b arcs in
    /// row-major order. O(a + b + ab), with no edge list allocated.
    ///
    /// - Precondition: both counts are non-negative, and a + b and a·b fit in `Int`.
    @inlinable
    public static func completeBipartite(leftCount a: Int, rightCount b: Int) -> Self {
        _checkCompleteBipartite(a, b)
        return Self(_vertexCount: a + b, sortedEdges: _CrossPairs(a, b))
    }
}

extension BipartiteGraph where Vertex == Int {
    /// K_{a,b} with its sides: `left` is `0..<leftCount` and `right` is
    /// `leftCount..<leftCount + rightCount`, each edge stored left end first, in lexicographic
    /// order. The sides are known, so there is no 2-colouring pass. O(a + b + ab).
    ///
    /// - Precondition: both counts are non-negative, and a + b and a·b fit in `Int`.
    @inlinable
    public static func completeBipartite(leftCount a: Int, rightCount b: Int) -> BipartiteGraph {
        BipartiteGraph(_leftCount: a, graph: UndirectedAdjacencyList<Int>.completeBipartite(leftCount: a, rightCount: b))
    }
}

@inlinable
func _checkCompleteBipartite(_ a: Int, _ b: Int) {
    _checkCount(a, "leftCount")
    _checkCount(b, "rightCount")
    precondition(a <= Int.max - b && _productFits(a, b), "count overflows Int")
}
