import GraphProtocols

/// Breadth-first and depth-first search in index space, pushed to a visitor, which also receives
/// the identifiers (borrowed) to turn an identifier back into a vertex: the engine under the
/// public searches and the queries, and the search other Grafluent modules (connectivity, flows,
/// shortest paths) build on. Vertices are identifiers from `_VertexIdentifiers` (the graph's
/// vertex indices when it has them), so a visitor keeps its own state in arrays.
///
/// The search state stays readable after a run: discovery order, parents in the search forest, and
/// depths.
@frozen
@usableFromInline
package struct IndexSpaceSearch<G: DirectedGraph> {
    /// What a visitor tells the search after each step.
    @frozen
    @usableFromInline
    package enum Control {
        /// Carry on.
        case proceed
        /// After a discovery: do not explore the vertex's out-edges. Elsewhere, like `proceed`.
        case prune
        /// End the search now.
        case stop
    }

    /// A step of a breadth-first search, in Boost's event order.
    @frozen
    @usableFromInline
    package enum BreadthFirstStep {
        case discover(Int)
        case treeEdge(source: Int, target: Int)
        case nonTreeEdge(source: Int, target: Int)
        case finish(Int)
    }

    /// A step of a depth-first search, with CLRS's edge classes.
    @frozen
    @usableFromInline
    package enum DepthFirstStep {
        case discover(Int)
        case treeEdge(source: Int, target: Int)
        case backEdge(source: Int, target: Int)
        case forwardEdge(source: Int, target: Int)
        case crossEdge(source: Int, target: Int)
        case finish(Int)
    }

    @usableFromInline
    package var ids: _VertexIdentifiers<G>
    /// The order in which each vertex was discovered, or -1.
    @usableFromInline
    package var discovery: [Int]
    @usableFromInline
    package var finished: [Bool]
    /// Each discovered vertex's parent in the search forest, or -1 for a root.
    @usableFromInline
    package var parent: [Int]
    @usableFromInline
    package var depth: [Int]
    @usableFromInline var discoveries = 0

    @inlinable
    package init(_ graph: G) {
        ids = _VertexIdentifiers(graph)
        let n = ids.isIndexed ? ids.count : 0
        discovery = [Int](repeating: -1, count: n)
        finished = [Bool](repeating: false, count: n)
        parent = [Int](repeating: -1, count: n)
        depth = [Int](repeating: 0, count: n)
    }

    @inlinable
    package func isDiscovered(_ id: Int) -> Bool {
        id < discovery.count && discovery[id] >= 0
    }

    @inlinable
    @inline(__always)
    mutating func _ensure(_ id: Int) {
        if id >= discovery.count {
            _grow(&discovery, to: id + 1, with: -1)
            _grow(&finished, to: id + 1, with: false)
            _grow(&parent, to: id + 1, with: -1)
            _grow(&depth, to: id + 1, with: 0)
        }
    }

    @inlinable
    @inline(__always)
    mutating func _discover(_ id: Int, parent p: Int, depth d: Int) {
        _ensure(id)
        discovery[id] = discoveries
        discoveries += 1
        parent[id] = p
        depth[id] = d
    }

    /// A breadth-first search from `sources`, reported to `visit`. Returns false if stopped.
    @inlinable
    @inline(__always)
    @discardableResult
    package mutating func breadthFirst(from sources: some Sequence<Int>, depthLimit: Int? = nil, _ visit: (BreadthFirstStep, borrowing _VertexIdentifiers<G>) -> Control) -> Bool {
        if ids.isIndexed {
            // Rows the graph lends out, read directly.
            let graph = ids.graph
            if let completed = graph._withSuccessorIndexRows({ offsets, targets in
                _breadthFirst(sources, depthLimit, visit, offsets, targets)
            }) {
                return completed
            }
        }
        return _breadthFirst(sources, depthLimit, visit, nil, nil)
    }

    @inlinable
    @inline(__always)
    mutating func _breadthFirst(
        _ sources: some Sequence<Int>,
        _ depthLimit: Int?,
        _ visit: (BreadthFirstStep, borrowing _VertexIdentifiers<G>) -> Control,
        _ offsets: UnsafeBufferPointer<Int>?,
        _ targets: UnsafeBufferPointer<Int>?
    ) -> Bool {
        var queue: [Int] = []
        var pruned: Set<Int> = []
        for s in sources where !isDiscovered(s) {
            _discover(s, parent: -1, depth: 0)
            queue.append(s)
            switch visit(.discover(s), ids) {
            case .stop: return false
            case .prune: pruned.insert(s)
            case .proceed: break
            }
        }
        var head = 0
        while head < queue.count {
            let u = queue[head]
            head += 1
            if pruned.isEmpty || !pruned.contains(u), depthLimit.map({ depth[u] < $0 }) ?? true {
                if let offsets, let targets {
                    for k in offsets[u] ..< offsets[u + 1] {
                        guard _breadthFirstEdge(u, targets[k], &queue, &pruned, visit) else { return false }
                    }
                } else if ids.isIndexed {
                    for w in ids.graph.successorIndices(ofIndex: u) {
                        guard _breadthFirstEdge(u, w, &queue, &pruned, visit) else { return false }
                    }
                } else {
                    for v in ids.graph.successors(of: ids.vertices[u]) {
                        let w = ids.identifier(of: v)
                        guard _breadthFirstEdge(u, w, &queue, &pruned, visit) else { return false }
                    }
                }
            }
            finished[u] = true
            if case .stop = visit(.finish(u), ids) { return false }
        }
        return true
    }

    @inlinable
    @inline(__always)
    mutating func _breadthFirstEdge(_ u: Int, _ w: Int, _ queue: inout [Int], _ pruned: inout Set<Int>, _ visit: (BreadthFirstStep, borrowing _VertexIdentifiers<G>) -> Control) -> Bool {
        if isDiscovered(w) {
            if case .stop = visit(.nonTreeEdge(source: u, target: w), ids) { return false }
            return true
        }
        _discover(w, parent: u, depth: depth[u] + 1)
        queue.append(w)
        if case .stop = visit(.treeEdge(source: u, target: w), ids) { return false }
        switch visit(.discover(w), ids) {
        case .stop: return false
        case .prune: pruned.insert(w)
        case .proceed: break
        }
        return true
    }

    /// A depth-first search from each of `roots` in turn (every vertex, in `vertices` order, when
    /// `roots` is nil), reported to `visit`. Returns false if stopped.
    @inlinable
    @inline(__always)
    @discardableResult
    package mutating func depthFirst(from roots: [Int]?, depthLimit: Int? = nil, _ visit: (DepthFirstStep, borrowing _VertexIdentifiers<G>) -> Control) -> Bool {
        if ids.isIndexed {
            // Rows the graph lends out: cursors over them hold no reference to retain per vertex.
            let graph = ids.graph
            if let completed = graph._withSuccessorIndexRows({ offsets, targets in
                _depthFirst(roots, depthLimit, visit, { _RowCursor(row: $1, offsets: offsets, targets: targets) }, { _, w in w })
            }) {
                return completed
            }
            return _depthFirst(roots, depthLimit, visit, { $0.graph.successorIndices(ofIndex: $1).makeIterator() }, { _, w in w })
        }
        return _depthFirst(roots, depthLimit, visit, { $0.graph.successors(of: $0.vertices[$1]).makeIterator() }, { $0.identifier(of: $1) })
    }

    @inlinable
    @inline(__always)
    mutating func _depthFirst<Neighbors: IteratorProtocol>(
        _ roots: [Int]?,
        _ depthLimit: Int?,
        _ visit: (DepthFirstStep, borrowing _VertexIdentifiers<G>) -> Control,
        _ neighbors: (borrowing _VertexIdentifiers<G>, Int) -> Neighbors,
        _ identify: (inout _VertexIdentifiers<G>, Neighbors.Element) -> Int
    ) -> Bool {
        var stack: [Int] = []
        var iterators: [Neighbors?] = []
        // Every vertex in `vertices` order: with indices that is index order, so no lookups.
        var rootVertices = roots == nil && !ids.isIndexed ? ids.graph.vertices.makeIterator() : nil
        let rootCount = roots?.count ?? (ids.isIndexed ? ids.count : 0)
        var nextRoot = 0
        while true {
            // The next root not yet reached.
            let root: Int
            if rootVertices != nil {
                guard let v = rootVertices!.next() else { return true }
                root = ids.identifier(of: v)
            } else {
                guard nextRoot < rootCount else { return true }
                root = roots?[nextRoot] ?? nextRoot
                nextRoot += 1
            }
            if isDiscovered(root) { continue }
            _discover(root, parent: -1, depth: 0)
            switch visit(.discover(root), ids) {
            case .stop: return false
            case .prune: iterators.append(nil)
            case .proceed: iterators.append(depthLimit == 0 ? nil : neighbors(ids, root))
            }
            stack.append(root)
            while let u = stack.last {
                let top = stack.count - 1
                if let next = iterators[top]?.next() {
                    let w = identify(&ids, next)
                    if !isDiscovered(w) {
                        _discover(w, parent: u, depth: stack.count)
                        if case .stop = visit(.treeEdge(source: u, target: w), ids) { return false }
                        let control = visit(.discover(w), ids)
                        if case .stop = control { return false }
                        let explore = control != .prune && (depthLimit.map { stack.count < $0 } ?? true)
                        stack.append(w)
                        iterators.append(explore ? neighbors(ids, w) : nil)
                        continue
                    }
                    let step: DepthFirstStep = !finished[w] ? .backEdge(source: u, target: w)
                        : discovery[w] > discovery[u] ? .forwardEdge(source: u, target: w) : .crossEdge(source: u, target: w)
                    if case .stop = visit(step, ids) { return false }
                    continue
                }
                stack.removeLast()
                iterators.removeLast()
                finished[u] = true
                if case .stop = visit(.finish(u), ids) { return false }
            }
        }
    }
}

extension IndexSpaceSearch.Control: Equatable {}

extension IndexSpaceSearch where G: BidirectionalDirectedGraph {
    /// A breadth-first search backward along in-edges from `sources`: `visit` sees each vertex
    /// discovered, with its parent being the vertex it leads to. Returns false if stopped.
    @inlinable
    @inline(__always)
    @discardableResult
    package mutating func breadthFirstBackward(from sources: some Sequence<Int>, _ visit: (Int, borrowing _VertexIdentifiers<G>) -> Control) -> Bool {
        var queue: [Int] = []
        for s in sources where !isDiscovered(s) {
            _discover(s, parent: -1, depth: 0)
            queue.append(s)
            if case .stop = visit(s, ids) { return false }
        }
        var head = 0
        var predecessors: [Int] = []
        while head < queue.count {
            let v = queue[head]
            head += 1
            predecessors.removeAll(keepingCapacity: true)
            ids.forEachPredecessor(of: v) { predecessors.append($0) }
            for u in predecessors where !isDiscovered(u) {
                _discover(u, parent: v, depth: depth[v] + 1)
                queue.append(u)
                if case .stop = visit(u, ids) { return false }
            }
        }
        return true
    }
}
