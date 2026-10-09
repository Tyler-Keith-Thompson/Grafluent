import Trees
import Walks

extension _TreeLayout {
    /// The Euler tour as vertex numbers and edge positions, from `preorder`: before each next
    /// vertex, climb to its parent; then step down to it; at the end, climb to the root.
    @inlinable
    func _eulerTour() -> Walk<Vertex, Int> {
        let n = count
        let root = roots[0]
        var vertices: [Vertex] = []
        var edges: [Int] = []
        vertices.reserveCapacity(2 * n - 1)
        edges.reserveCapacity(2 * n - 2)
        vertices.append(self.vertices[root])
        var current = root
        for i in 1 ..< max(n, 1) {
            let w = preorder[i]
            let p = nodes[w].parent
            while current != p {
                edges.append(nodes[current].parentEdge)
                current = nodes[current].parent
                vertices.append(self.vertices[current])
            }
            edges.append(nodes[w].parentEdge)
            vertices.append(self.vertices[w])
            current = w
        }
        while current != root {
            edges.append(nodes[current].parentEdge)
            current = nodes[current].parent
            vertices.append(self.vertices[current])
        }
        return Walk(_uncheckedVertices: vertices, edges: edges)
    }
}

extension RootedTree {
    /// The closed walk from the root that goes down each child edge, in `children(of:)` order,
    /// and back up it after that subtree: 2n − 1 vertices, each edge position twice (NetworkX
    /// `dfs_labeled_edges`, forward then reverse). The trivial walk for one vertex. O(n).
    @inlinable
    public var eulerTour: Walk<Vertex, Int> { _layout._eulerTour() }
}
