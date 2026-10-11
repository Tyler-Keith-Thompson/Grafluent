import GraphProtocols

extension _GraphConstruction {
    /// The empty graph on `0..<vertexCount`: no edges (NetworkX `empty_graph`). The one spelling
    /// every conformer shares (`UndirectedAdjacencyList<Int>` has no `init(vertexCount:)`). O(n).
    ///
    /// - Precondition: `vertexCount ≥ 0`.
    @inlinable
    public static func empty(vertexCount n: Int) -> Self {
        _checkCount(n)
        return Self(_vertexCount: n, sortedEdges: EmptyCollection(), _ConstructionToken())
    }
}

extension _DirectedGraphConstruction {
    /// The empty directed graph on `0..<vertexCount`. O(n).
    ///
    /// - Precondition: `vertexCount ≥ 0`.
    @inlinable
    public static func empty(vertexCount n: Int) -> Self {
        _checkCount(n)
        return Self(_vertexCount: n, sortedEdges: EmptyCollection(), _ConstructionToken())
    }
}
