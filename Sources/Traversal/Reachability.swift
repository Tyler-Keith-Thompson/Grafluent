import GraphProtocols

extension DirectedGraph {
    /// Every vertex reachable from `vertex` by at least one edge, `vertex` itself excluded even on a
    /// cycle (NetworkX's `descendants`).
    ///
    /// - Precondition: `vertex` is a vertex.
    @inlinable
    public func descendants(of vertex: Vertex) -> Set<Vertex> {
        precondition(contains(vertex), "\(vertex) is not a vertex of the graph")
        var ids = _VertexIdentifiers(self)
        let start = ids.identifier(of: vertex)
        var visited = [Bool](repeating: false, count: ids.isIndexed ? ids.count : start + 1)
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
        precondition(contains(source), "The source \(source) is not a vertex of the graph")
        precondition(contains(target), "The target \(target) is not a vertex of the graph")
        if source == target { return true }
        var ids = _VertexIdentifiers(self)
        let start = ids.identifier(of: source)
        let goal = ids.identifier(of: target)
        var visited = [Bool](repeating: false, count: ids.isIndexed ? ids.count : max(start, goal) + 1)
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
    /// Every vertex from which a path leads to `vertex`, `vertex` itself excluded (NetworkX's
    /// `ancestors`).
    ///
    /// - Precondition: `vertex` is a vertex.
    @inlinable
    public func ancestors(of vertex: Vertex) -> Set<Vertex> {
        precondition(contains(vertex), "\(vertex) is not a vertex of the graph")
        var search = IndexSpaceSearch(self)
        let start = search.ids.identifier(of: vertex)
        var reached = Set<Vertex>()
        search.breadthFirstBackward(from: [start]) { v, ids in
            if v != start { reached.insert(ids.vertex(v)) }
            return .proceed
        }
        return reached
    }

    /// A shortest path from `source` to `target` by edge count, searching forward from the source
    /// and backward from the target at once, one whole level at a time from whichever frontier is
    /// smaller (NetworkX's `bidirectional_shortest_path`). `nil` when there is none.
    ///
    /// - Precondition: both are vertices.
    @inlinable
    public func bidirectionalShortestPath(from source: Vertex, to target: Vertex) -> [Vertex]? {
        precondition(contains(source), "The source \(source) is not a vertex of the graph")
        precondition(contains(target), "The target \(target) is not a vertex of the graph")
        if source == target { return [source] }
        var ids = _VertexIdentifiers(self)
        let start = ids.identifier(of: source)
        let goal = ids.identifier(of: target)
        // -2: not reached from that side; -1: the side's root.
        let unseen = -2
        var forwardParent = [Int](repeating: unseen, count: ids.count)
        var backwardParent = [Int](repeating: unseen, count: ids.count)
        func reached(_ parents: [Int], _ id: Int) -> Bool { id < parents.count && parents[id] != unseen }
        _grow(&forwardParent, to: max(start, goal) + 1, with: unseen)
        _grow(&backwardParent, to: max(start, goal) + 1, with: unseen)
        forwardParent[start] = -1
        backwardParent[goal] = -1
        var forwardFringe = [start]
        var backwardFringe = [goal]
        var neighbors: [Int] = []
        var meeting: Int?
        search: while !forwardFringe.isEmpty, !backwardFringe.isEmpty {
            let forward = forwardFringe.count <= backwardFringe.count
            let level = forward ? forwardFringe : backwardFringe
            var next: [Int] = []
            for v in level {
                neighbors.removeAll(keepingCapacity: true)
                if forward {
                    ids.forEachSuccessor(of: v) { neighbors.append($0) }
                } else {
                    ids.forEachPredecessor(of: v) { neighbors.append($0) }
                }
                for w in neighbors {
                    _grow(&forwardParent, to: w + 1, with: unseen)
                    _grow(&backwardParent, to: w + 1, with: unseen)
                    if forward {
                        if !reached(forwardParent, w) {
                            forwardParent[w] = v
                            next.append(w)
                        }
                        if reached(backwardParent, w) {
                            meeting = w
                            break search
                        }
                    } else {
                        if !reached(backwardParent, w) {
                            backwardParent[w] = v
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
        var path: [Vertex] = []
        var v = meeting
        while v != -1 {
            path.append(ids.vertex(v))
            v = forwardParent[v]
        }
        path.reverse()
        v = backwardParent[meeting]
        while v != -1 {
            path.append(ids.vertex(v))
            v = backwardParent[v]
        }
        return path
    }
}
