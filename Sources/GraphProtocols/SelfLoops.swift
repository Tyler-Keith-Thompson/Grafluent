extension DirectedGraph {
    /// Calls `body` with each vertex that has a self-loop, in `vertices` order, and its vertex
    /// index (-1 without vertex indices), until `body` returns false.
    @inlinable
    @inline(__always)
    func _forEachVertexWithSelfLoop(_ body: (_ vertex: Vertex, _ index: Int) -> Bool) {
        guard let n = vertexIndexBound else {
            for vertex in vertices where successors(of: vertex).contains(vertex) {
                if !body(vertex, -1) { return }
            }
            return
        }
        // Stored rows are read in place, without a row value per vertex.
        if _withSuccessorIndexRows({ offsets, targets in
            rows: for v in 0 ..< n {
                for k in offsets[v] ..< offsets[v + 1] where targets[k] == v {
                    if !body(vertex(atIndex: v), v) { return }
                    continue rows
                }
            }
        }) != nil {
            return
        }
        if _withCheckedOutIndexRows({ targets, targetRows, _, _ in
            rows: for v in 0 ..< n {
                let start = targetRows[3 &* v]
                for k in start ..< start &+ targetRows[3 &* v &+ 1] where targets[k] == v {
                    if !body(vertex(atIndex: v), v) { return }
                    continue rows
                }
            }
        }) != nil {
            return
        }
        // `contains` reaches a row's own membership test where it has one (a matrix's bit set).
        for v in 0 ..< n where successorIndices(ofIndex: v).contains(v) {
            if !body(vertex(atIndex: v), v) { return }
        }
    }

    /// Whether some edge goes from a vertex to itself (JGraphT's `GraphTests.hasSelfLoops`,
    /// igraph's `has_loop`). O(V + E), stopping at the first self-loop.
    ///
    /// Whether one vertex has a self-loop is `contains(edge: DirectedEdge(from: v, to: v))`.
    @inlinable
    public var hasSelfLoops: Bool {
        var found = false
        _forEachVertexWithSelfLoop { _, _ in
            found = true
            return false
        }
        return found
    }

    /// The vertices with an edge to themselves, each once however many self-loops it has, in
    /// `vertices` order (NetworkX's `nodes_with_selfloops`). O(V + E).
    @inlinable
    public func verticesWithSelfLoops() -> [Vertex] {
        var result: [Vertex] = []
        _forEachVertexWithSelfLoop { vertex, _ in
            result.append(vertex)
            return true
        }
        return result
    }

    /// The positions of the edges from a vertex to itself, every copy of a repeated one (NetworkX's
    /// `selfloop_edges`; their count is its `number_of_selfloops`): by vertex in `vertices` order,
    /// each vertex's in `outEdges(of:)` order. O(V + E).
    @inlinable
    public func selfLoopEdges() -> [Edges.Index] {
        var result: [Edges.Index] = []
        _forEachVertexWithSelfLoop { vertex, index in
            for position in index >= 0 ? outEdges(ofIndex: index) : outEdges(of: vertex) where target(ofEdgeAt: position) == vertex {
                result.append(position)
            }
            return true
        }
        return result
    }
}

extension Graph {
    /// Calls `body` with each vertex that has a self-loop, in `vertices` order, and its vertex
    /// index (-1 without vertex indices), until `body` returns false.
    @inlinable
    @inline(__always)
    func _forEachVertexWithSelfLoop(_ body: (_ vertex: Vertex, _ index: Int) -> Bool) {
        guard let n = vertexIndexBound else {
            for vertex in vertices where neighbors(of: vertex).contains(vertex) {
                if !body(vertex, -1) { return }
            }
            return
        }
        for v in 0 ..< n where neighborIndices(ofIndex: v).contains(v) {
            if !body(vertex(atIndex: v), v) { return }
        }
    }

    /// Whether some edge joins a vertex to itself (JGraphT's `GraphTests.hasSelfLoops`, igraph's
    /// `has_loop`). O(V + E), stopping at the first self-loop.
    ///
    /// Whether one vertex has a self-loop is `contains(edge: UndirectedEdge(v, v))`.
    @inlinable
    public var hasSelfLoops: Bool {
        var found = false
        _forEachVertexWithSelfLoop { _, _ in
            found = true
            return false
        }
        return found
    }

    /// The vertices with an edge to themselves, each once however many self-loops it has, in
    /// `vertices` order (NetworkX's `nodes_with_selfloops`). O(V + E).
    @inlinable
    public func verticesWithSelfLoops() -> [Vertex] {
        var result: [Vertex] = []
        _forEachVertexWithSelfLoop { vertex, _ in
            result.append(vertex)
            return true
        }
        return result
    }

    /// The positions of the edges from a vertex to itself, every copy of a repeated one, each once
    /// although `incidentEdges(of:)` lists a self-loop twice (NetworkX's `selfloop_edges`; their
    /// count is its `number_of_selfloops`): by vertex in `vertices` order, each vertex's in the
    /// order of their first appearance in `incidentEdges(of:)`. O(V + E).
    @inlinable
    public func selfLoopEdges() -> [Edges.Index] {
        var result: [Edges.Index] = []
        _forEachVertexWithSelfLoop { vertex, index in
            // Each loop appears twice in the row; keep its first appearance.
            var seen: Set<Edges.Index> = []
            for position in index >= 0 ? incidentEdges(ofIndex: index) : incidentEdges(of: vertex)
            where oppositeVertex(to: vertex, acrossEdgeAt: position) == vertex && seen.insert(position).inserted {
                result.append(position)
            }
            return true
        }
        return result
    }
}
