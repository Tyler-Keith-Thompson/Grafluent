import GraphProtocols

// Bulk construction builds the base, then orders it once by Kahn's algorithm, FIFO with the
// sources in `vertices` order, in O(n + m). Inserting the same edges one at a time can give a
// different valid order.

extension DirectedAcyclicGraph {
    /// A graph with the given vertices and no edges, ordered as listed. A repeat is inserted once.
    /// O(n) expected.
    @inlinable
    public init(vertices: some Sequence<Vertex>) {
        self.init()
        for vertex in vertices { insert(vertex) }
    }

    /// A graph with the given edges, whose vertices are their endpoints in order of first
    /// appearance; `nil` when the edges have a cycle, a self-loop included. O(n + m) expected.
    @inlinable
    public init?(edges: some Sequence<DirectedEdge<Vertex>>) {
        self.init(vertices: EmptyCollection(), edges: edges)
    }

    /// A graph with `vertices` first (a repeat once), then the edges in order, as the base inserts
    /// them: copies are kept on a base with parallel edges and collapse on `AdjacencyList`.
    /// Endpoints missing from `vertices` are inserted. `nil` when the edges have a cycle, a
    /// self-loop included; `base.findCycle()` (Traversal) on the same input gives one.
    /// O(n + m) expected.
    @inlinable
    public init?(vertices: some Sequence<Vertex>, edges: some Sequence<DirectedEdge<Vertex>>) {
        var base = Base()
        for vertex in vertices where base._key(of: vertex) == nil { _ = base._insertVertex(vertex) }
        for edge in edges {
            let source = base._key(of: edge.source) ?? base._insertVertex(edge.source)
            let target = base._key(of: edge.target) ?? base._insertVertex(edge.target)
            _ = base._insertEdge(fromKey: source, toKey: target)
        }
        self.init(base)
    }

    /// A graph from a list of edges and vertices; see `DirectedGraphBuilder`. `nil` when the edges
    /// have a cycle.
    @inlinable
    public init?(@DirectedGraphBuilder<Vertex> _ content: () -> DirectedGraphBuilder<Vertex>.Content) {
        let content = content()
        self.init(vertices: content.vertices, edges: content.edges)
    }

    /// `base` with a topological order, or `nil` when it has a cycle. The base is kept as it is,
    /// positions included. O(n + m), with no hashing.
    @inlinable
    public init?(_ base: Base) {
        // Kahn's algorithm in key space: each entry's label holds the in-degree still to be met,
        // and `order` is the FIFO queue.
        var table = _KeyTable()
        var order = ContiguousArray<Int>()
        order.reserveCapacity(base.vertexCount)
        for key in base.vertices.indices {
            let degree = base._inDegree(ofKey: key)
            table.insert(key, label: degree)
            if degree == 0 { order.append(key) }
        }
        var next = 0
        while next < order.count {
            let key = order[next]
            next &+= 1
            for target in base._successorKeys(ofKey: key) {
                let remaining = table.label(target) &- 1
                table.setLabel(target, remaining)
                if remaining == 0 { order.append(target) }
            }
        }
        guard order.count == base.vertexCount else { return nil }
        for (place, key) in order.enumerated() { table.setLabel(key, place) }
        self.init(_base: base, order: order, table: table)
    }

    /// A copy of any directed graph: its vertices in order, then its edges in `edges` order, as
    /// `init(vertices:edges:)` builds them; `nil` when it has a cycle. Converting a
    /// `DirectedAcyclicGraph` returns it unchanged, and a `Base` keeps its storage.
    @inlinable
    public init?(_ graph: some DirectedGraph<Vertex>) {
        if let same = graph as? Self {
            self = same
            return
        }
        if let base = graph as? Base {
            self.init(base)
            return
        }
        self.init(vertices: graph.vertices, edges: graph.edges)
    }
}
