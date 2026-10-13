import GraphProtocols
import Trees

extension DirectedGraph {
    /// The breadth-first search tree from `source`, as an arborescence rooted there: every vertex
    /// the search reaches, each with the vertex it was discovered from as parent. Each parent is a
    /// vertex one edge closer to `source`, so a tree path is a shortest path by edge count.
    ///
    /// Vertices are listed in discovery order, `source` first, and edge positions follow them:
    /// edge k leads to the vertex at offset k + 1, so `edges` lists the tree edges in the
    /// order `breadthFirstSearch(from:)` reports them. O(n + m) over the reached part; the
    /// vertices are hashed once, into the arborescence's lookup table, unless they come out as
    /// the `Int`s `0..<k` in order.
    ///
    /// - Parameter depthLimit: When given, only vertices at most this many edges from `source`
    ///   are in the tree.
    /// - Precondition: `source` is a vertex; `depthLimit` is not negative.
    @inlinable
    public func breadthFirstTree(from source: Vertex, depthLimit: Int? = nil) -> Arborescence<Vertex> {
        precondition(depthLimit.map { $0 >= 0 } ?? true, "A depth limit cannot be negative")
        var search = IndexSpaceSearch(self)
        let root = search.ids.requiredIdentifier(of: source, "The source \(source) is not a vertex of the graph")
        var order: [Int] = []
        search.breadthFirst(from: CollectionOfOne(root), depthLimit: depthLimit) { step, _ in
            if case .discover(let v) = step { order.append(v) }
            return .proceed
        }
        return _searchTree(order, search)
    }

    /// The depth-first search tree from `source`, as an arborescence rooted there: every vertex
    /// the search reaches, each with the vertex it was discovered from as parent. Successors are
    /// explored in `successors(of:)` order.
    ///
    /// Vertices are listed in discovery order (preorder), `source` first, and edge positions
    /// follow them: edge k leads to the vertex at offset k + 1, so `edges` lists the tree
    /// edges in the order `depthFirstSearch(from:)` reports them. O(n + m) over the reached part;
    /// the vertices are hashed once, into the arborescence's lookup table, unless they come out
    /// as the `Int`s `0..<k` in order.
    ///
    /// - Parameter depthLimit: When given, only vertices at most this many tree edges from
    ///   `source` are in the tree.
    /// - Precondition: `source` is a vertex; `depthLimit` is not negative.
    @inlinable
    public func depthFirstTree(from source: Vertex, depthLimit: Int? = nil) -> Arborescence<Vertex> {
        precondition(depthLimit.map { $0 >= 0 } ?? true, "A depth limit cannot be negative")
        var search = IndexSpaceSearch(self)
        let root = search.ids.requiredIdentifier(of: source, "The source \(source) is not a vertex of the graph")
        var order: [Int] = []
        search.depthFirst(from: [root], depthLimit: depthLimit) { step, _ in
            if case .discover(let v) = step { order.append(v) }
            return .proceed
        }
        return _searchTree(order, search)
    }

    /// The search forest of `search`, one tree, over the identifiers in `order`, the discovery
    /// order: its root first, each vertex's parent discovered before it.
    @inlinable
    func _searchTree(_ order: [Int], _ search: IndexSpaceSearch<Self>) -> Arborescence<Vertex> {
        var vertices = ContiguousArray<Vertex>()
        vertices.reserveCapacity(order.count)
        var parents = [Int](repeating: -1, count: order.count)
        for (k, id) in order.enumerated() {
            vertices.append(search.ids.vertex(id))
            // `discovery` numbers the vertices in discovery order, as `order` lists them.
            let p = search.parent[id]
            if p >= 0 { parents[k] = search.discovery[p] }
        }
        return Arborescence(vertices: vertices, parents: parents)
    }
}
