import GraphProtocols

extension _GraphConstruction {
    /// The empty graph on `0..<vertexCount`, with no edges. Every conformer has this factory,
    /// including those with no `init(vertexCount:)`. O(n).
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
