import GraphProtocols

/// A depth-first search: a lazy sequence of `DepthFirstSearchEvent`s, with every edge classified as
/// a tree, back, forward or cross edge. It holds a copy of the graph and can be iterated more than
/// once. The search keeps its own stack, so a deep graph cannot overflow the call stack.
///
/// Two ways to consume it. `for event in search` pulls events one at a time, lazily, so stopping
/// the loop stops the search; to skip a vertex's out-edges, iterate by hand and call `prune()`
/// right after its `discover` event. `search.forEach { … }` pushes every event to a closure in a
/// single loop, faster than pulling, for when every event is wanted.
///
/// With a depth limit, a vertex first reached by a path longer than the limit is not explored from
/// a later, shorter path either: the search goes depth-first, not by distance (as in NetworkX).
@frozen
public struct DepthFirstSearch<G: DirectedGraph>: Sequence {
    public typealias Element = DepthFirstSearchEvent<G.Vertex>

    @usableFromInline let graph: G
    /// The roots in order, or `nil` for every vertex in `vertices` order.
    @usableFromInline let roots: [G.Vertex]?
    @usableFromInline let depthLimit: Int?

    @inlinable
    init(graph: G, roots: [G.Vertex]?, depthLimit: Int?) {
        precondition(depthLimit.map { $0 >= 0 } ?? true, "A depth limit cannot be negative")
        for root in roots ?? [] {
            precondition(graph.contains(root), "The source \(root) is not a vertex of the graph")
        }
        self.graph = graph
        self.roots = roots
        self.depthLimit = depthLimit
    }

    @inlinable
    public func makeIterator() -> Iterator {
        Iterator(graph: graph, roots: roots, depthLimit: depthLimit)
    }

    /// Calls `body` with every event, in order, in one loop.
    @inlinable
    public func forEach<Failure: Error>(_ body: (DepthFirstSearchEvent<G.Vertex>) throws(Failure) -> Void) throws(Failure) {
        var search = IndexSpaceSearch(graph)
        var rootIDs: [Int]?
        if let roots {
            var ids: [Int] = []
            for root in roots { ids.append(search.ids.identifier(of: root)) }
            rootIDs = ids
        }
        var failure: Failure?
        search.depthFirst(from: rootIDs, depthLimit: depthLimit) { step, ids in
            let event: DepthFirstSearchEvent<G.Vertex> = switch step {
            case .discover(let v): .discover(ids.vertex(v))
            case .treeEdge(let u, let w): .treeEdge(DirectedEdge(from: ids.vertex(u), to: ids.vertex(w)))
            case .backEdge(let u, let w): .backEdge(DirectedEdge(from: ids.vertex(u), to: ids.vertex(w)))
            case .forwardEdge(let u, let w): .forwardEdge(DirectedEdge(from: ids.vertex(u), to: ids.vertex(w)))
            case .crossEdge(let u, let w): .crossEdge(DirectedEdge(from: ids.vertex(u), to: ids.vertex(w)))
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

    /// The vertices in the order discovered (NetworkX's `dfs_preorder_nodes`).
    @inlinable
    public var preorder: some Sequence<G.Vertex> {
        lazy.compactMap { if case .discover(let v) = $0 { v } else { nil } }
    }

    /// The vertices in the order finished (NetworkX's `dfs_postorder_nodes`). With a depth limit,
    /// the vertices at the limit are finished too.
    @inlinable
    public var postorder: some Sequence<G.Vertex> {
        lazy.compactMap { if case .finish(let v) = $0 { v } else { nil } }
    }

    public struct Iterator: IteratorProtocol {
        @usableFromInline var ids: _VertexIdentifiers<G>
        @usableFromInline let roots: [G.Vertex]?
        @usableFromInline var nextRoot = 0
        @usableFromInline var vertexIterator: G.Vertices.Iterator
        @usableFromInline let depthLimit: Int?
        /// The order in which each vertex was discovered; -1 for undiscovered.
        @usableFromInline var discovered: [Int] = []
        @usableFromInline var finished: [Bool] = []
        @usableFromInline var pruned: [Bool] = []
        @usableFromInline var discoveries = 0
        /// The path from the current root: each vertex, and the rest of its out-edges (`nil` when
        /// they are not to be explored).
        @usableFromInline var stack: [Int] = []
        @usableFromInline var indexedNeighbors: [G.SuccessorIndices.Iterator?] = []
        @usableFromInline var unindexedNeighbors: [G.Successors.Iterator?] = []
        @usableFromInline var pendingDiscovery: Int?
        /// The vertex of the last event, when that event was its discovery: the one `prune()` acts on.
        @usableFromInline var justDiscovered: Int?

        @inlinable
        init(graph: G, roots: [G.Vertex]?, depthLimit: Int?) {
            self.ids = _VertexIdentifiers(graph)
            self.roots = roots
            self.vertexIterator = graph.vertices.makeIterator()
            self.depthLimit = depthLimit
            if ids.isIndexed {
                discovered = [Int](repeating: -1, count: ids.count)
                finished = [Bool](repeating: false, count: ids.count)
                pruned = [Bool](repeating: false, count: ids.count)
            }
        }

        @inlinable
        func _isDiscovered(_ id: Int) -> Bool {
            id < discovered.count && discovered[id] >= 0
        }

        /// Marks `id` discovered and pushes it.
        @inlinable
        mutating func _push(_ id: Int) {
            if !ids.isIndexed {
                _grow(&discovered, to: id + 1, with: -1)
                _grow(&finished, to: id + 1, with: false)
                _grow(&pruned, to: id + 1, with: false)
            }
            discovered[id] = discoveries
            discoveries += 1
            let explore = depthLimit.map { stack.count < $0 } ?? true
            stack.append(id)
            if ids.isIndexed {
                indexedNeighbors.append(explore ? ids.graph.successorIndices(ofIndex: id).makeIterator() : nil)
            } else {
                unindexedNeighbors.append(explore ? ids.graph.successors(of: ids.vertices[id]).makeIterator() : nil)
            }
        }

        @inlinable
        mutating func _nextRoot() -> Int? {
            if let roots {
                while nextRoot < roots.count {
                    let id = ids.identifier(of: roots[nextRoot])
                    nextRoot += 1
                    if !_isDiscovered(id) { return id }
                }
                return nil
            }
            while let v = vertexIterator.next() {
                let id = ids.identifier(of: v)
                if !_isDiscovered(id) { return id }
            }
            return nil
        }

        @inlinable
        @inline(__always)
        public mutating func next() -> DepthFirstSearchEvent<G.Vertex>? {
            justDiscovered = nil
            if let id = pendingDiscovery {
                pendingDiscovery = nil
                justDiscovered = id
                return .discover(ids.vertex(id))
            }
            guard let u = stack.last else {
                guard let root = _nextRoot() else { return nil }
                _push(root)
                justDiscovered = root
                return .discover(ids.vertex(root))
            }
            let top = stack.count - 1
            let next: Int?
            if pruned[u] {
                next = nil
            } else if ids.isIndexed {
                next = indexedNeighbors[top]?.next()
            } else {
                next = unindexedNeighbors[top]?.next().map { ids.identifier(of: $0) }
            }
            if let w = next {
                let edge = DirectedEdge(from: ids.vertex(u), to: ids.vertex(w))
                if !_isDiscovered(w) {
                    _push(w)
                    pendingDiscovery = w
                    return .treeEdge(edge)
                }
                if !finished[w] { return .backEdge(edge) }
                return discovered[w] > discovered[u] ? .forwardEdge(edge) : .crossEdge(edge)
            }
            stack.removeLast()
            if ids.isIndexed { indexedNeighbors.removeLast() } else { unindexedNeighbors.removeLast() }
            finished[u] = true
            return .finish(ids.vertex(u))
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

        /// The vertices on the search path, from the root to the vertex being explored.
        @inlinable
        var _path: [G.Vertex] { stack.map { ids.vertex($0) } }
    }
}

extension DepthFirstSearch: Sendable where G: Sendable, G.Vertex: Sendable {}
extension DepthFirstSearch.Iterator: Sendable where G: Sendable, G.Vertex: Sendable, G.Vertices.Iterator: Sendable, G.SuccessorIndices.Iterator: Sendable, G.Successors.Iterator: Sendable {}

extension DirectedGraph {
    /// A depth-first search from `source`.
    ///
    /// - Parameter depthLimit: When given, vertices at this depth are discovered and finished but
    ///   their out-edges are not reported.
    /// - Precondition: `source` is a vertex; `depthLimit` is not negative.
    @inlinable
    public func depthFirstSearch(from source: Vertex, depthLimit: Int? = nil) -> DepthFirstSearch<Self> {
        DepthFirstSearch(graph: self, roots: [source], depthLimit: depthLimit)
    }

    /// A depth-first search from each of `roots` in turn, skipping a root already reached.
    ///
    /// - Precondition: every root is a vertex; `depthLimit` is not negative.
    @inlinable
    public func depthFirstSearch(from roots: some Sequence<Vertex>, depthLimit: Int? = nil) -> DepthFirstSearch<Self> {
        DepthFirstSearch(graph: self, roots: Array(roots), depthLimit: depthLimit)
    }

    /// A depth-first search of the whole graph: each vertex not yet reached, in `vertices` order,
    /// starts a new tree.
    @inlinable
    public func depthFirstSearch(depthLimit: Int? = nil) -> DepthFirstSearch<Self> {
        DepthFirstSearch(graph: self, roots: nil, depthLimit: depthLimit)
    }
}
