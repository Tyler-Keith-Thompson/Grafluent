import GraphProtocols
import Walks

extension DirectedGraph {
    /// `descendants(of: vertex)`, throwing instead of trapping when `vertex` is not a vertex: the
    /// `checked:` spelling (README Principle 6), for a vertex that may not belong to the graph.
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not a vertex.
    @inlinable
    public func descendants(checked vertex: Vertex) throws(VertexNotFound) -> Set<Vertex> {
        guard contains(vertex) else { throw VertexNotFound() }
        return descendants(of: vertex)
    }

    /// Every vertex reachable from `vertex` by at least one edge, `vertex` itself excluded even on a
    /// cycle (NetworkX's `descendants`).
    ///
    /// - Precondition: `vertex` is a vertex.
    @inlinable
    public func descendants(of vertex: Vertex) -> Set<Vertex> {
        var ids = _VertexIdentifiers(self)
        let start = ids.requiredIdentifier(of: vertex, "\(vertex) is not a vertex of the graph")
        var visited = [Bool](repeating: false, count: ids.isDense ? ids.count : start + 1)
        visited[start] = true
        var stack = [start]
        var reached = Set<Vertex>()
        while let u = stack.popLast() {
            ids.forEachSuccessor(of: u) { w in
                _grow(&visited, to: w + 1, with: false)
                if !visited[w] {
                    visited[w] = true
                    stack.append(w)
                }
                if w == start { visited[start] = true }
            }
        }
        for (id, seen) in visited.enumerated() where seen && id != start { reached.insert(ids.vertex(id)) }
        return reached
    }

    /// Whether a path leads from `source` to `target`; true when they are the same vertex.
    ///
    /// - Precondition: both are vertices.
    @inlinable
    public func hasPath(from source: Vertex, to target: Vertex) -> Bool {
        var ids = _VertexIdentifiers(self)
        let start = ids.requiredIdentifier(of: source, "The source \(source) is not a vertex of the graph")
        let goal = ids.requiredIdentifier(of: target, "The target \(target) is not a vertex of the graph")
        if start == goal { return true }
        var visited = [Bool](repeating: false, count: ids.isDense ? ids.count : max(start, goal) + 1)
        visited[start] = true
        var stack = [start]
        while let u = stack.popLast() {
            var found = false
            ids.forEachSuccessor(of: u) { w in
                if w == goal { found = true }
                _grow(&visited, to: w + 1, with: false)
                if !visited[w] {
                    visited[w] = true
                    stack.append(w)
                }
            }
            if found { return true }
        }
        return false
    }
}

extension BidirectionalDirectedGraph {
    /// `ancestors(of: vertex)`, throwing instead of trapping when `vertex` is not a vertex: the
    /// `checked:` spelling (README Principle 6).
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not a vertex.
    @inlinable
    public func ancestors(checked vertex: Vertex) throws(VertexNotFound) -> Set<Vertex> {
        guard contains(vertex) else { throw VertexNotFound() }
        return ancestors(of: vertex)
    }

    /// Every vertex from which a path leads to `vertex`, `vertex` itself excluded (NetworkX's
    /// `ancestors`).
    ///
    /// - Precondition: `vertex` is a vertex.
    @inlinable
    public func ancestors(of vertex: Vertex) -> Set<Vertex> {
        var search = IndexSpaceSearch(self)
        let start = search.ids.requiredIdentifier(of: vertex, "\(vertex) is not a vertex of the graph")
        var reached = Set<Vertex>()
        search.breadthFirstBackward(from: [start]) { v, ids in
            if v != start { reached.insert(ids.vertex(v)) }
            return .proceed
        }
        return reached
    }

    /// A shortest path from `source` to `target` by edge count, searching forward from the source
    /// and backward from the target at once, one whole level at a time from whichever frontier is
    /// smaller (NetworkX's `bidirectional_shortest_path`). `nil` when there is none. Its edges are
    /// the ones the searches crossed: an out-edge for each step found forward, an in-edge for each
    /// step found backward.
    ///
    /// - Precondition: both are vertices.
    @inlinable
    public func bidirectionalShortestPath(from source: Vertex, to target: Vertex) -> Path<Vertex, Edges.Index>? {
        var ids = _VertexIdentifiers(self)
        let start = ids.requiredIdentifier(of: source, "The source \(source) is not a vertex of the graph")
        let goal = ids.requiredIdentifier(of: target, "The target \(target) is not a vertex of the graph")
        if start == goal { return Path(vertex: source) }
        // -2: not reached from that side; -1: the side's root.
        let unseen = -2
        var forwardParent = [Int](repeating: unseen, count: ids.count)
        var backwardParent = [Int](repeating: unseen, count: ids.count)
        // The edge each parent pointer crossed: from the parent forward, into it backward.
        var forwardEdge = [Edges.Index?](repeating: nil, count: ids.count)
        var backwardEdge = [Edges.Index?](repeating: nil, count: ids.count)
        func reached(_ parents: [Int], _ id: Int) -> Bool { id < parents.count && parents[id] != unseen }
        _grow(&forwardParent, to: max(start, goal) + 1, with: unseen)
        _grow(&backwardParent, to: max(start, goal) + 1, with: unseen)
        _grow(&forwardEdge, to: max(start, goal) + 1, with: nil)
        _grow(&backwardEdge, to: max(start, goal) + 1, with: nil)
        forwardParent[start] = -1
        backwardParent[goal] = -1
        var forwardFringe = [start]
        var backwardFringe = [goal]
        var neighbors: [(Int, Edges.Index)] = []
        var meeting: Int?
        search: while !forwardFringe.isEmpty, !backwardFringe.isEmpty {
            let forward = forwardFringe.count <= backwardFringe.count
            let level = forward ? forwardFringe : backwardFringe
            var next: [Int] = []
            for v in level {
                neighbors.removeAll(keepingCapacity: true)
                if ids.isIndexed {
                    if forward {
                        for (w, e) in zip(successorIndices(ofIndex: v), outEdges(ofIndex: v)) { neighbors.append((w, e)) }
                    } else {
                        for (w, e) in zip(predecessorIndices(ofIndex: v), inEdges(ofIndex: v)) { neighbors.append((w, e)) }
                    }
                } else if let rows = ids.rows {
                    // Numbered: `Edges.Index` is `Int` for a sparsely indexed graph.
                    let numbered = forward ? rows : ids.numberedPredecessorRows()
                    for k in numbered.offsets[v] ..< numbered.offsets[v + 1] {
                        neighbors.append((numbered.neighbors[k], unsafeBitCast(numbered.edges[k], to: Edges.Index.self)))
                    }
                } else if forward {
                    for e in outEdges(of: ids.vertex(v)) { neighbors.append((ids.identifier(of: self.target(ofEdgeAt: e)), e)) }
                } else {
                    for e in inEdges(of: ids.vertex(v)) { neighbors.append((ids.identifier(of: self.source(ofEdgeAt: e)), e)) }
                }
                for (w, e) in neighbors {
                    _grow(&forwardParent, to: w + 1, with: unseen)
                    _grow(&backwardParent, to: w + 1, with: unseen)
                    _grow(&forwardEdge, to: w + 1, with: nil)
                    _grow(&backwardEdge, to: w + 1, with: nil)
                    if forward {
                        if !reached(forwardParent, w) {
                            forwardParent[w] = v
                            forwardEdge[w] = e
                            next.append(w)
                        }
                        if reached(backwardParent, w) {
                            meeting = w
                            break search
                        }
                    } else {
                        if !reached(backwardParent, w) {
                            backwardParent[w] = v
                            backwardEdge[w] = e
                            next.append(w)
                        }
                        if reached(forwardParent, w) {
                            meeting = w
                            break search
                        }
                    }
                }
            }
            if forward { forwardFringe = next } else { backwardFringe = next }
        }
        guard let meeting else { return nil }
        // Back from the meeting vertex to the source along forward parents, then on to the target
        // along backward ones; each pointer's edge is the step between its two vertices.
        var path: [Int] = []
        var edges: [Edges.Index] = []
        var v = meeting
        while v != -1 {
            path.append(v)
            if let e = forwardEdge[v] { edges.append(e) }
            v = forwardParent[v]
        }
        path.reverse()
        edges.reverse()
        v = meeting
        while backwardParent[v] != -1 {
            edges.append(backwardEdge[v]!)
            v = backwardParent[v]
            path.append(v)
        }
        // A shortest path repeats no vertex, and each step is an edge of the graph.
        return Path(_uncheckedVertices: path.map { ids.vertex($0) }, edges: edges)
    }
}
