extension Tree where Vertex == Int {
    /// The tree on `0..<vertexCount` whose edge `k` joins `ends[2k]` and `ends[2k + 1]`, for a
    /// generator that knows the edges form a tree: the dense layout, with no vertex dictionary.
    /// O(n).
    ///
    /// - Precondition: `vertexCount ≥ 1`, and the ends are a tree on `0..<vertexCount`.
    @inlinable
    package init(_vertexCount n: Int, treeEnds ends: [Int]) {
        precondition(n >= 1, "A Tree has at least one vertex")
        if n == 1 {
            self.init(_layout: .single(0))
            return
        }
        guard let layout = _TreeLayout(vertices: ContiguousArray(0 ..< n), slots: [:], dense: true, ends: ends, root: 0) else {
            preconditionFailure("The edges are not a tree")
        }
        self.init(_layout: layout)
    }
}
