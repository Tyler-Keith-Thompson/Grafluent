import GraphProtocols

/// A breadth-first search: a sequence of `BreadthFirstSearchEvent`s. It holds a copy of the graph,
/// so later changes to the original do not affect it, and it can be iterated more than once.
/// Per-vertex state is kept in arrays indexed by the graph's vertex indices when it has them.
///
/// Two ways to consume it. `for event in search` pulls events one at a time, lazily, so stopping
/// the loop stops the search; to skip a vertex's out-edges, iterate by hand and call `prune()`
/// right after its `discover` event. `search.forEach { … }` pushes every event to a closure in a
/// single loop, about twice as fast as pulling, for when every event is wanted.
@frozen
public struct BreadthFirstSearch<Graph: DirectedGraph>: Sequence {
    public typealias Element = BreadthFirstSearchEvent<Graph.Vertex>

    @usableFromInline let graph: Graph
    @usableFromInline let sources: [Graph.Vertex]
    @usableFromInline let depthLimit: Int?

    @inlinable
    init(graph: Graph, sources: [Graph.Vertex], depthLimit: Int?) {
        precondition(depthLimit.map { $0 >= 0 } ?? true, "A depth limit cannot be negative")
        for source in sources {
            precondition(graph.contains(source), "The source \(source) is not a vertex of the graph")
        }
        self.graph = graph
        self.sources = sources
        self.depthLimit = depthLimit
    }

    @inlinable
    public func makeIterator() -> Iterator {
        Iterator(graph: graph, sources: sources, depthLimit: depthLimit)
    }

    /// Calls `body` with every event, in order, in one loop.
    @inlinable
    public func forEach<Failure: Error>(_ body: (BreadthFirstSearchEvent<Graph.Vertex>) throws(Failure) -> Void) throws(Failure) {
        var search = IndexSpaceSearch(graph)
        var sourceIDs: [Int] = []
        for source in sources { sourceIDs.append(search.ids.identifier(of: source)) }
        var failure: Failure?
        search.breadthFirst(from: sourceIDs, depthLimit: depthLimit) { step, ids in
            let event: BreadthFirstSearchEvent<Graph.Vertex> = switch step {
            case .discover(let v): .discover(ids.vertex(v))
            case .treeEdge(let u, let w): .treeEdge(DirectedEdge(from: ids.vertex(u), to: ids.vertex(w)))
            case .nonTreeEdge(let u, let w): .nonTreeEdge(DirectedEdge(from: ids.vertex(u), to: ids.vertex(w)))
            case .finish(let v): .finish(ids.vertex(v))
            }
            do throws(Failure) {
                try body(event)
                return .proceed
            } catch {
                failure = error
                return .stop
            }
        }
        if let failure { throw failure }
    }

    public struct Iterator: IteratorProtocol {
        @usableFromInline var ids: _VertexIdentifiers<Graph>
        @usableFromInline let sources: [Graph.Vertex]
        @usableFromInline var nextSource = 0
        @usableFromInline let depthLimit: Int?
        /// The depth of each discovered vertex; -1 for undiscovered.
        @usableFromInline var depth: [Int] = []
        @usableFromInline var pruned: [Bool] = []
        @usableFromInline var queue: [Int] = []
        @usableFromInline var head = 0
        /// The vertex whose out-edges are being reported, and the rest of them.
        @usableFromInline var current: Int?
        @usableFromInline var currentVertex: Graph.Vertex?
        @usableFromInline var indexedNeighbors: Graph.SuccessorIndices.Iterator?
        @usableFromInline var unindexedNeighbors: Graph.Successors.Iterator?
        /// A vertex reached by the tree edge just reported, to be discovered next.
        @usableFromInline var pendingDiscovery: Int?
        /// The vertex of the last event, when that event was its discovery: the one `prune()` acts on.
        @usableFromInline var justDiscovered: Int?

        @inlinable
        init(graph: Graph, sources: [Graph.Vertex], depthLimit: Int?) {
            self.ids = _VertexIdentifiers(graph)
            self.sources = sources
            self.depthLimit = depthLimit
            if ids.isIndexed {
                depth = [Int](repeating: -1, count: ids.count)
                pruned = [Bool](repeating: false, count: ids.count)
            }
        }

        @inlinable
        mutating func _discover(_ id: Int, depth d: Int) {
            if !ids.isIndexed {
                _grow(&depth, to: id + 1, with: -1)
                _grow(&pruned, to: id + 1, with: false)
            }
            depth[id] = d
            queue.append(id)
        }

        @inlinable
        func _isDiscovered(_ id: Int) -> Bool {
            id < depth.count && depth[id] >= 0
        }

        @inlinable
        @inline(__always)
        public mutating func next() -> BreadthFirstSearchEvent<Graph.Vertex>? {
            justDiscovered = nil
            if let id = pendingDiscovery {
                pendingDiscovery = nil
                justDiscovered = id
                return .discover(ids.vertex(id))
            }
            while nextSource < sources.count {
                let source = sources[nextSource]
                nextSource += 1
                let id = ids.identifier(of: source)
                if _isDiscovered(id) { continue }
                _discover(id, depth: 0)
                justDiscovered = id
                return .discover(source)
            }
            while true {
                if let u = current {
                    let next: Int? = ids.isIndexed
                        ? indexedNeighbors!.next()
                        : unindexedNeighbors!.next().map { ids.identifier(of: $0) }
                    guard let w = next else {
                        current = nil
                        indexedNeighbors = nil
                        unindexedNeighbors = nil
                        return .finish(currentVertex!)
                    }
                    let edge = DirectedEdge(from: currentVertex!, to: ids.vertex(w))
                    if _isDiscovered(w) { return .nonTreeEdge(edge) }
                    _discover(w, depth: depth[u] + 1)
                    pendingDiscovery = w
                    return .treeEdge(edge)
                }
                guard head < queue.count else { return nil }
                let u = queue[head]
                head += 1
                if pruned[u] || depthLimit.map({ depth[u] >= $0 }) ?? false {
                    return .finish(ids.vertex(u))
                }
                current = u
                currentVertex = ids.vertex(u)
                if ids.isIndexed {
                    indexedNeighbors = ids.graph.successorIndices(ofIndex: u).makeIterator()
                } else {
                    unindexedNeighbors = ids.graph.successors(of: ids.vertices[u]).makeIterator()
                }
            }
        }

        /// Skips the out-edges of the vertex just discovered; it is still finished.
        ///
        /// - Precondition: the last event was a `discover`.
        @inlinable
        public mutating func prune() {
            guard let id = justDiscovered else {
                preconditionFailure("prune() applies to the vertex just discovered; call it right after a discover event")
            }
            pruned[id] = true
        }
    }
}

extension BreadthFirstSearch: Sendable where Graph: Sendable, Graph.Vertex: Sendable {}
extension BreadthFirstSearch.Iterator: Sendable where Graph: Sendable, Graph.Vertex: Sendable, Graph.SuccessorIndices.Iterator: Sendable, Graph.Successors.Iterator: Sendable {}

extension DirectedGraph {
    /// A breadth-first search from `source`.
    ///
    /// - Parameter depthLimit: When given, vertices at this depth are discovered and finished but
    ///   their out-edges are not reported.
    /// - Precondition: `source` is a vertex; `depthLimit` is not negative.
    @inlinable
    public func breadthFirstSearch(from source: Vertex, depthLimit: Int? = nil) -> BreadthFirstSearch<Self> {
        BreadthFirstSearch(graph: self, sources: [source], depthLimit: depthLimit)
    }

    /// A breadth-first search from several sources at once: all are discovered first, at depth 0,
    /// in the order given. A repeated source is ignored. The sources are read when the search is
    /// made, so the sequence must be finite.
    ///
    /// - Precondition: every source is a vertex; `depthLimit` is not negative.
    @inlinable
    public func breadthFirstSearch(from sources: some Sequence<Vertex>, depthLimit: Int? = nil) -> BreadthFirstSearch<Self> {
        BreadthFirstSearch(graph: self, sources: Array(sources), depthLimit: depthLimit)
    }

    /// The vertices reachable from `source`, by distance: layer k holds the vertices k edges away,
    /// in the order a breadth-first search discovers them (NetworkX's `bfs_layers`).
    ///
    /// - Precondition: `source` is a vertex.
    @inlinable
    public func breadthFirstLayers(from source: Vertex) -> [[Vertex]] {
        breadthFirstLayers(from: [source])
    }

    /// The vertices reachable from any of `sources`, by distance from the nearest.
    ///
    /// - Precondition: every source is a vertex.
    @inlinable
    public func breadthFirstLayers(from sources: some Sequence<Vertex>) -> [[Vertex]] {
        // A dedicated loop, a level at a time: no events, one visited flag per vertex.
        var ids = _VertexIdentifiers(self)
        var visited = [Bool](repeating: false, count: ids.isIndexed ? ids.count : 0)
        var current: [Int] = []
        for source in sources {
            precondition(contains(source), "The source \(source) is not a vertex of the graph")
            let id = ids.identifier(of: source)
            _grow(&visited, to: id + 1, with: false)
            if !visited[id] {
                visited[id] = true
                current.append(id)
            }
        }
        var layers: [[Vertex]] = []
        var next: [Int] = []
        while !current.isEmpty {
            layers.append(current.map { ids.vertex($0) })
            next.removeAll(keepingCapacity: true)
            for u in current {
                ids.forEachSuccessor(of: u) { w in
                    _grow(&visited, to: w + 1, with: false)
                    if !visited[w] {
                        visited[w] = true
                        next.append(w)
                    }
                }
            }
            swap(&current, &next)
        }
        return layers
    }
}
