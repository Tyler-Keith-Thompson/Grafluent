import GraphProtocols
import Multigraphs

extension PlanarEmbedding {
    /// The dual graph of the embedding: a vertex for each face, and for each edge an edge joining
    /// the two faces it separates.
    ///
    /// Vertex `f` is the face at position `f` in `faces`. The edge at position `k` is the dual of
    /// the `k`th edge of the graph's `edges`: it joins the face to the right of that edge crossed
    /// from its end with the lower vertex number (for a self-loop, its end listed first) and the
    /// face to its right crossed from the other end, in that order. A bridge has one face on both
    /// sides, so its dual is a self-loop; the edges around a vertex of degree d become d edges
    /// around its dual face, parallel when two of them separate the same two faces. Faces are
    /// counted per connected component, so the dual of a disconnected graph is the disjoint union
    /// of its components' duals, and an isolated vertex contributes nothing.
    ///
    /// - Returns: A pseudograph on `0..<faceCount` with one edge per edge of the graph.
    /// - Complexity: O(n + m).
    @inlinable
    public func dualGraph() -> Pseudograph<Int> {
        let m = _layout.edgeCount
        var firstSlot = [Int](repeating: -1, count: m)
        var ends: [UndirectedEdge<Int>] = []
        ends.reserveCapacity(m)
        _layout.rowEdges.withUnsafeBufferPointer { rowEdges in
            firstSlot.withUnsafeMutableBufferPointer { firstSlot in
                for q in 0 ..< rowEdges.count {
                    let e = Int(rowEdges[q])
                    if firstSlot[e] < 0 { firstSlot[e] = q }
                }
            }
        }
        for e in 0 ..< m {
            let q = firstSlot[e]
            ends.append(UndirectedEdge(Int(_layout.faceOfSlot[q]), Int(_layout.faceOfSlot[Int(_layout.twin[q])])))
        }
        return Pseudograph(vertices: 0 ..< faceCount, edges: ends)
    }
}
