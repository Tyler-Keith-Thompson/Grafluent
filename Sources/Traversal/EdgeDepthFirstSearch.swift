import GraphProtocols

/// The engine under the edge depth-first searches: pulled one event at a time over `Rows`, with
/// its own stack.
@frozen
@usableFromInline
package struct _EdgeDepthFirstIterator<Rows: _EdgeSearchRows> {
    @usableFromInline var rows: Rows
    /// The roots in order, or `nil` for every vertex in `vertices` order.
    @usableFromInline let roots: [Rows.Vertex]?
    @usableFromInline var nextRoot = 0
    /// Every vertex in `vertices` order, for a whole-graph search without dense identifiers.
    @usableFromInline var rootVertices: [Rows.Vertex] = []
    @usableFromInline let depthLimit: Int?
    /// The order in which each vertex was discovered; -1 for undiscovered.
    @usableFromInline var order: [Int] = []
    /// `_EdgeSearchFlag.finished` and, undirected, `.explored`.
    @usableFromInline var flags: [UInt8] = []
    /// Undirected: each discovered vertex's parent (-1 for a root) and the tree edge from it.
    @usableFromInline var parent: [Int] = []
    @usableFromInline var parentEdge: [Rows.Edge?] = []
    /// Undirected: the self-loops on the path met once.
    @usableFromInline var loopsMet: [Rows.Edge] = []
    @usableFromInline var discoveries = 0
    /// The path from the current root: each vertex, and the rest of its edges (empty when they
    /// are not to be explored), as integer cursors when the rows are read by slot. Otherwise
    /// `rowStack[k]` is the row of `stack[k]`; slots past the top are kept for reuse, so a push
    /// loads a row in place.
    @usableFromInline var stack: [_EdgeSearchFrame] = []
    @usableFromInline var rowStack: [Rows.Row] = []
    @usableFromInline var pendingDiscovery: Int?
    /// The vertex of the last event, when that event was its discovery: the one `prune()` acts on.
    @usableFromInline var justDiscovered: Int?

    @inlinable
    init(rows: Rows, roots: [Rows.Vertex]?, depthLimit: Int?) {
        self.rows = rows
        self.roots = roots
        self.depthLimit = depthLimit
        if let n = rows.denseCount {
            order = [Int](repeating: -1, count: n)
            flags = [UInt8](repeating: 0, count: n)
            if Rows.isUndirected {
                parent = [Int](repeating: -1, count: n)
                parentEdge = [Rows.Edge?](repeating: nil, count: n)
            }
        } else if roots == nil {
            rootVertices = rows.vertexList
        }
    }

    @inlinable
    func _isDiscovered(_ id: Int) -> Bool {
        id < order.count && order[id] >= 0
    }

    /// Marks `id` discovered and pushes it.
    @inlinable
    mutating func _push(_ id: Int, parent p: Int, edge: Rows.Edge?) {
        if rows.denseCount == nil {
            _grow(&order, to: id + 1, with: -1)
            _grow(&flags, to: id + 1, with: 0)
            if Rows.isUndirected {
                _grow(&parent, to: id + 1, with: -1)
                _grow(&parentEdge, to: id + 1, with: nil)
            }
        }
        let explore = depthLimit.map { stack.count < $0 } ?? true
        order[id] = discoveries
        discoveries += 1
        if Rows.isUndirected {
            flags[id] = explore ? _EdgeSearchFlag.explored : 0
            parent[id] = p
            parentEdge[id] = edge
        }
        if rows.readsBySlot {
            let (start, end, shift) = explore ? rows.bounds(of: id) : (0, 0, 0)
            stack.append(_EdgeSearchFrame(vertex: id, cursor: start, end: end, shift: shift))
            return
        }
        stack.append(_EdgeSearchFrame(vertex: id, cursor: 0, end: 0, shift: 0))
        let top = stack.count - 1
        if top == rowStack.count { rowStack.append(Rows.emptyRow) }
        if explore {
            rows.load(&rowStack[top], of: id)
        } else {
            rows.clear(&rowStack[top])
        }
    }

    @inlinable
    mutating func _nextRoot() -> Int? {
        if let roots {
            while nextRoot < roots.count {
                let id = rows.identifier(of: roots[nextRoot])
                nextRoot += 1
                if !_isDiscovered(id) { return id }
            }
            return nil
        }
        if let n = rows.denseCount {
            while nextRoot < n {
                let id = nextRoot
                nextRoot += 1
                if !_isDiscovered(id) { return id }
            }
            return nil
        }
        while nextRoot < rootVertices.count {
            let id = rows.identifier(of: rootVertices[nextRoot])
            nextRoot += 1
            if !_isDiscovered(id) { return id }
        }
        return nil
    }

    /// Whether `edge`, a self-loop of the vertex being explored, was met before: true at its
    /// second end.
    @inlinable
    mutating func _isSecondEnd(ofLoop edge: Rows.Edge) -> Bool {
        if let k = loopsMet.firstIndex(of: edge) {
            loopsMet.remove(at: k)
            return true
        }
        loopsMet.append(edge)
        return false
    }

    @inlinable
    @inline(__always)
    package mutating func next() -> EdgeDepthFirstSearchEvent<Rows.Vertex, Rows.Edge>? {
        justDiscovered = nil
        if let id = pendingDiscovery {
            pendingDiscovery = nil
            justDiscovered = id
            return .discover(rows.vertex(id))
        }
        while true {
            let top = stack.count &- 1
            guard top >= 0 else {
                guard let root = _nextRoot() else { return nil }
                _push(root, parent: -1, edge: nil)
                justDiscovered = root
                return .discover(rows.vertex(root))
            }
            let u = stack[top].vertex
            let next: (edge: Rows.Edge, target: Int)?
            if rows.readsBySlot {
                let k = stack[top].cursor
                if k < stack[top].end {
                    stack[top].cursor = k &+ 1
                    next = rows.edge(atSlot: k, shift: stack[top].shift)
                } else {
                    next = nil
                }
            } else {
                next = rows.next(in: &rowStack[top])
            }
            if let (edge, w) = next {
                if !_isDiscovered(w) {
                    _push(w, parent: u, edge: edge)
                    pendingDiscovery = w
                    return .treeEdge(edge)
                }
                let f = flags[w]
                if Rows.isUndirected {
                    if w == u {
                        if _isSecondEnd(ofLoop: edge) { continue }
                    } else if w == parent[u] && parentEdge[u] == edge {
                        // The tree edge seen from below.
                        continue
                    } else if f == _EdgeSearchFlag.finished | _EdgeSearchFlag.explored {
                        // Reported from `w`, as a back edge to `u`.
                        continue
                    }
                }
                if f & _EdgeSearchFlag.finished == 0 { return .backEdge(edge) }
                return order[w] > order[u] ? .forwardEdge(edge) : .crossEdge(edge)
            }
            stack.removeLast()
            flags[u] |= _EdgeSearchFlag.finished
            return .finish(rows.vertex(u))
        }
    }

    @inlinable
    package mutating func prune() {
        guard let id = justDiscovered else {
            preconditionFailure("prune() applies to the vertex just discovered; call it right after a discover event")
        }
        // The vertex just discovered is the top of the stack.
        let top = stack.count - 1
        if rows.readsBySlot {
            stack[top] = _EdgeSearchFrame(vertex: id, cursor: 0, end: 0, shift: 0)
        } else {
            rows.clear(&rowStack[top])
        }
        flags[id] &= ~_EdgeSearchFlag.explored
    }
}

/// One frame of a depth-first search over flat rows: the vertex, and the rest of its row as
/// integer cursors.
@frozen
@usableFromInline
package struct _EdgeSearchFrame {
    @usableFromInline let vertex: Int
    @usableFromInline var cursor: Int
    @usableFromInline let end: Int
    @usableFromInline let shift: Int

    @inlinable
    init(vertex: Int, cursor: Int, end: Int, shift: Int) {
        self.vertex = vertex
        self.cursor = cursor
        self.end = end
        self.shift = shift
    }
}

/// A step of an edge search over flat rows, in identifiers and `Int` positions.
@frozen
@usableFromInline
package enum _EdgeSearchStep {
    case discover(Int)
    case treeEdge(Int)
    case backEdge(Int)
    case forwardEdge(Int)
    case crossEdge(Int)
    case nonTreeEdge(Int)
    case finish(Int)
}

/// The edge depth-first search pushed to `visit` over flat rows, with integer cursors on its
/// stack: the `forEach` of the edge depth-first searches. `roots` are identifiers; `nil` is every
/// vertex in index order. Returns false if `visit` stopped it.
@inlinable
@inline(__always)
@discardableResult
package func _edgeDepthFirst(
    _ rows: _EdgeFlatRows, count n: Int, roots: [Int]?, depthLimit: Int?, undirected: Bool,
    _ visit: (_EdgeSearchStep) -> Bool
) -> Bool {
    var order = [Int](repeating: -1, count: n)
    var flags = [UInt8](repeating: 0, count: n)
    var parent = [Int](repeating: -1, count: undirected ? n : 0)
    var parentEdge = [Int](repeating: -1, count: undirected ? n : 0)
    var loopsMet: [Int] = []
    var stack: [_EdgeSearchFrame] = []
    var discoveries = 0
    let rootCount = roots?.count ?? n
    for r in 0 ..< rootCount {
        let root = roots?[r] ?? r
        if order[root] >= 0 { continue }
        // Pushes `w`, discovered from `u` across `edge`.
        var w = root, u = -1, edge = -1
        var pushing = true
        while true {
            if pushing {
                pushing = false
                let explore = depthLimit.map { stack.count < $0 } ?? true
                order[w] = discoveries
                discoveries &+= 1
                if undirected {
                    flags[w] = explore ? _EdgeSearchFlag.explored : 0
                    parent[w] = u
                    parentEdge[w] = edge
                }
                let (start, end, shift) = explore ? rows.bounds(of: w) : (0, 0, 0)
                stack.append(_EdgeSearchFrame(vertex: w, cursor: start, end: end, shift: shift))
                guard visit(.discover(w)) else { return false }
            }
            let top = stack.count &- 1
            if top < 0 { break }
            u = stack[top].vertex
            let k = stack[top].cursor
            if k < stack[top].end {
                stack[top].cursor = k &+ 1
                w = rows.targets[k]
                edge = rows.position(at: k, shift: stack[top].shift)
                if order[w] < 0 {
                    guard visit(.treeEdge(edge)) else { return false }
                    pushing = true
                    continue
                }
                let f = flags[w]
                if undirected {
                    if w == u {
                        if let m = loopsMet.firstIndex(of: edge) {
                            loopsMet.remove(at: m)
                            continue
                        }
                        loopsMet.append(edge)
                    } else if w == parent[u] && parentEdge[u] == edge {
                        continue
                    } else if f == _EdgeSearchFlag.finished | _EdgeSearchFlag.explored {
                        continue
                    }
                }
                let step: _EdgeSearchStep = f & _EdgeSearchFlag.finished == 0 ? .backEdge(edge)
                    : order[w] > order[u] ? .forwardEdge(edge) : .crossEdge(edge)
                guard visit(step) else { return false }
                continue
            }
            stack.removeLast()
            flags[u] |= _EdgeSearchFlag.finished
            guard visit(.finish(u)) else { return false }
        }
    }
    return true
}

extension _EdgeDepthFirstIterator: Sendable where Rows: Sendable, Rows.Vertex: Sendable, Rows.Edge: Sendable, Rows.Row: Sendable {}

/// A depth-first search whose edge events carry edge positions: a sequence of
/// `EdgeDepthFirstSearchEvent`s, in the order `DepthFirstSearch` reports them, with every edge
/// classified as a tree, back, forward or cross edge. Parallel edges are told apart: a repeated
/// tree edge is a forward edge at its own position. It holds a copy of the graph and can be
/// iterated more than once. The search keeps its own stack, so a deep graph cannot overflow the
/// call stack.
///
/// `for event in search` pulls events one at a time, and stopping the loop stops the search. To
/// skip a vertex's out-edges, iterate by hand and call `prune()` right after its `discover` event.
/// `search.forEach { … }` pushes every event to a closure in one loop, which is faster when every
/// event is wanted.
@frozen
public struct EdgeDepthFirstSearch<G: DirectedGraph>: Sequence {
    public typealias Element = EdgeDepthFirstSearchEvent<G.Vertex, G.Edges.Index>

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
        Iterator(_EdgeDepthFirstIterator(rows: _DirectedEdgeRows(graph), roots: roots, depthLimit: depthLimit))
    }

    /// Calls `body` with every event, in order, in one loop. Over rows the graph lends in index
    /// space, the search keeps integer cursors on its stack; otherwise it is the iterator's loop.
    @inlinable
    public func forEach<Failure: Error>(_ body: (Element) throws(Failure) -> Void) throws(Failure) {
        var reader = _DirectedEdgeRows(graph)
        var rootIDs: [Int]?
        if let roots {
            var ids: [Int] = []
            for root in roots { ids.append(reader.identifier(of: root)) }
            rootIDs = ids
        }
        let rows = reader
        let n = rows.denseCount ?? 0
        var failure: Failure?
        let ran = rows.withFlatRows { flat in
            _edgeDepthFirst(flat, count: n, roots: rootIDs, depthLimit: depthLimit, undirected: false) { step in
                let event: Element
                switch step {
                case .discover(let v): event = .discover(rows.vertex(v))
                case .treeEdge(let e): event = .treeEdge(unsafeBitCast(e, to: G.Edges.Index.self))
                case .backEdge(let e): event = .backEdge(unsafeBitCast(e, to: G.Edges.Index.self))
                case .forwardEdge(let e): event = .forwardEdge(unsafeBitCast(e, to: G.Edges.Index.self))
                case .crossEdge(let e): event = .crossEdge(unsafeBitCast(e, to: G.Edges.Index.self))
                case .finish(let v): event = .finish(rows.vertex(v))
                case .nonTreeEdge: preconditionFailure("A depth-first search has no non-tree edge step")
                }
                do throws(Failure) {
                    try body(event)
                    return true
                } catch {
                    failure = error
                    return false
                }
            }
        }
        if let failure { throw failure }
        if ran == nil {
            var iterator = makeIterator()
            while let event = iterator.next() { try body(event) }
        }
    }

    public struct Iterator: IteratorProtocol {
        @usableFromInline var search: _EdgeDepthFirstIterator<_DirectedEdgeRows<G>>

        @inlinable
        init(_ search: _EdgeDepthFirstIterator<_DirectedEdgeRows<G>>) { self.search = search }

        @inlinable
        public mutating func next() -> Element? { search.next() }

        /// Skips the out-edges of the vertex just discovered; it is still finished.
        ///
        /// - Precondition: the last event was a `discover`.
        @inlinable
        public mutating func prune() { search.prune() }
    }
}

extension EdgeDepthFirstSearch: Sendable where G: Sendable, G.Vertex: Sendable {}
extension EdgeDepthFirstSearch.Iterator: Sendable where G: Sendable, G.Vertex: Sendable, G.Edges.Index: Sendable, G.OutEdges.Iterator: Sendable, G.SuccessorIndices.Iterator: Sendable {}

/// The edge depth-first search of an undirected graph: a sequence of `EdgeDepthFirstSearchEvent`s
/// that reports each edge once, by its position, from the end that reaches it first. The tree
/// edge into a vertex is not reported again from it, so a parallel edge to the parent is a back
/// edge. It holds a copy of the graph and can be iterated more than once, and keeps its own stack.
///
/// `for event in search` pulls events one at a time, and stopping the loop stops the search. To
/// skip a vertex's edges, iterate by hand and call `prune()` right after its `discover` event.
/// `search.forEach { … }` pushes every event to a closure in one loop, which is faster when every
/// event is wanted.
@frozen
public struct UndirectedEdgeDepthFirstSearch<G: Graph>: Sequence {
    public typealias Element = EdgeDepthFirstSearchEvent<G.Vertex, G.Edges.Index>

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
        Iterator(_EdgeDepthFirstIterator(rows: _UndirectedEdgeRows(graph), roots: roots, depthLimit: depthLimit))
    }

    /// Calls `body` with every event, in order, in one loop. Over rows the graph lends in index
    /// space, the search keeps integer cursors on its stack; otherwise it is the iterator's loop.
    @inlinable
    public func forEach<Failure: Error>(_ body: (Element) throws(Failure) -> Void) throws(Failure) {
        var reader = _UndirectedEdgeRows(graph)
        var rootIDs: [Int]?
        if let roots {
            var ids: [Int] = []
            for root in roots { ids.append(reader.identifier(of: root)) }
            rootIDs = ids
        }
        let rows = reader
        let n = rows.denseCount ?? 0
        var failure: Failure?
        let ran = rows.withFlatRows { flat in
            _edgeDepthFirst(flat, count: n, roots: rootIDs, depthLimit: depthLimit, undirected: true) { step in
                let event: Element
                switch step {
                case .discover(let v): event = .discover(rows.vertex(v))
                case .treeEdge(let e): event = .treeEdge(unsafeBitCast(e, to: G.Edges.Index.self))
                case .backEdge(let e): event = .backEdge(unsafeBitCast(e, to: G.Edges.Index.self))
                case .forwardEdge(let e): event = .forwardEdge(unsafeBitCast(e, to: G.Edges.Index.self))
                case .crossEdge(let e): event = .crossEdge(unsafeBitCast(e, to: G.Edges.Index.self))
                case .finish(let v): event = .finish(rows.vertex(v))
                case .nonTreeEdge: preconditionFailure("A depth-first search has no non-tree edge step")
                }
                do throws(Failure) {
                    try body(event)
                    return true
                } catch {
                    failure = error
                    return false
                }
            }
        }
        if let failure { throw failure }
        if ran == nil {
            var iterator = makeIterator()
            while let event = iterator.next() { try body(event) }
        }
    }

    public struct Iterator: IteratorProtocol {
        @usableFromInline var search: _EdgeDepthFirstIterator<_UndirectedEdgeRows<G>>

        @inlinable
        init(_ search: _EdgeDepthFirstIterator<_UndirectedEdgeRows<G>>) { self.search = search }

        @inlinable
        public mutating func next() -> Element? { search.next() }

        /// Skips the edges of the vertex just discovered; it is still finished, and its edges to
        /// vertices explored later are reported from their other ends.
        ///
        /// - Precondition: the last event was a `discover`.
        @inlinable
        public mutating func prune() { search.prune() }
    }
}

extension UndirectedEdgeDepthFirstSearch: Sendable where G: Sendable, G.Vertex: Sendable {}
extension UndirectedEdgeDepthFirstSearch.Iterator: Sendable where G: Sendable, G.Vertex: Sendable, G.Edges.Index: Sendable, G.IncidentEdges.Iterator: Sendable, G.NeighborIndices.Iterator: Sendable {}

extension DirectedGraph {
    /// A depth-first search from `source` whose edge events carry edge positions.
    ///
    /// - Parameter depthLimit: When given, vertices at this depth are discovered and finished but
    ///   their out-edges are not reported.
    /// - Complexity: O(n + m) over the reached part.
    /// - Precondition: `source` is a vertex; `depthLimit` is not negative.
    @inlinable
    public func edgeDepthFirstSearch(from source: Vertex, depthLimit: Int? = nil) -> EdgeDepthFirstSearch<Self> {
        EdgeDepthFirstSearch(graph: self, roots: [source], depthLimit: depthLimit)
    }

    /// A depth-first search from each of `roots` in turn, skipping a root already reached, whose
    /// edge events carry edge positions.
    ///
    /// - Complexity: O(n + m) over the reached part.
    /// - Precondition: every root is a vertex; `depthLimit` is not negative.
    @inlinable
    public func edgeDepthFirstSearch(from roots: some Sequence<Vertex>, depthLimit: Int? = nil) -> EdgeDepthFirstSearch<Self> {
        EdgeDepthFirstSearch(graph: self, roots: Array(roots), depthLimit: depthLimit)
    }

    /// A depth-first search of the whole graph whose edge events carry edge positions: each
    /// vertex not yet reached, in `vertices` order, starts a new tree.
    ///
    /// - Complexity: O(n + m).
    @inlinable
    public func edgeDepthFirstSearch(depthLimit: Int? = nil) -> EdgeDepthFirstSearch<Self> {
        EdgeDepthFirstSearch(graph: self, roots: nil, depthLimit: depthLimit)
    }
}

extension Graph {
    /// A depth-first search from `source` that reports each edge once, by its position.
    ///
    /// - Parameter depthLimit: When given, vertices at this depth are discovered and finished but
    ///   their edges are not examined.
    /// - Complexity: O(n + m) over the reached part.
    /// - Precondition: `source` is a vertex; `depthLimit` is not negative.
    @inlinable
    public func edgeDepthFirstSearch(from source: Vertex, depthLimit: Int? = nil) -> UndirectedEdgeDepthFirstSearch<Self> {
        UndirectedEdgeDepthFirstSearch(graph: self, roots: [source], depthLimit: depthLimit)
    }

    /// A depth-first search from each of `roots` in turn, skipping a root already reached, that
    /// reports each edge once, by its position.
    ///
    /// - Complexity: O(n + m) over the reached part.
    /// - Precondition: every root is a vertex; `depthLimit` is not negative.
    @inlinable
    public func edgeDepthFirstSearch(from roots: some Sequence<Vertex>, depthLimit: Int? = nil) -> UndirectedEdgeDepthFirstSearch<Self> {
        UndirectedEdgeDepthFirstSearch(graph: self, roots: Array(roots), depthLimit: depthLimit)
    }

    /// A depth-first search of the whole graph that reports each edge once, by its position: each
    /// vertex not yet reached, in `vertices` order, starts a new tree.
    ///
    /// - Complexity: O(n + m).
    @inlinable
    public func edgeDepthFirstSearch(depthLimit: Int? = nil) -> UndirectedEdgeDepthFirstSearch<Self> {
        UndirectedEdgeDepthFirstSearch(graph: self, roots: nil, depthLimit: depthLimit)
    }
}
