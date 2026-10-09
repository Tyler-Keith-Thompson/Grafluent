import GraphProtocols

extension DirectedGraph {
    /// For identifiers `steps`, the first out-edge (in `outEdges` order) from each to the next: in
    /// index space with vertex indices, so nothing is hashed; through `outEdges(of:)` otherwise.
    ///
    /// - Precondition: each step is an edge of the graph.
    @inlinable
    func _stepEdges(_ steps: [Int], _ ids: _VertexIdentifiers<Self>) -> [Edges.Index] {
        var edges: [Edges.Index] = []
        edges.reserveCapacity(Swift.max(0, steps.count - 1))
        for i in steps.indices.dropLast() {
            let (u, w) = (steps[i], steps[i + 1])
            let found: Edges.Index?
            if ids.isIndexed {
                found = zip(successorIndices(ofIndex: u), outEdges(ofIndex: u)).first { $0.0 == w }?.1
            } else {
                let target = ids.vertex(w)
                found = outEdges(of: ids.vertex(u)).first { self.target(ofEdgeAt: $0) == target }
            }
            guard let found else { preconditionFailure("No edge joins two consecutive vertices of a search result") }
            edges.append(found)
        }
        return edges
    }
}
