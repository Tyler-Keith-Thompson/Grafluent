import AdjacencyListModule
import GraphProtocols

extension BipartiteGraph where Vertex == Int {
    /// The bipartite graph with left side `0..<leftCount` and right side
    /// `leftCount..<graph.vertexCount`, for a generator whose `graph` has the vertices `0..<n` in
    /// order and stores every edge left end first: the sides are known, so there is no 2-colouring
    /// pass. O(n).
    @inlinable
    package init(_leftCount a: Int, graph: UndirectedAdjacencyList<Int>) {
        let n = graph.vertexCount
        self.init()
        _base = graph
        _side = [BipartiteSide](repeating: .left, count: a) + [BipartiteSide](repeating: .right, count: n - a)
        _left = Array(0 ..< a)
        _right = Array(a ..< n)
        _sideOffset = Array(0 ..< a) + Array(0 ..< n - a)
    }
}
