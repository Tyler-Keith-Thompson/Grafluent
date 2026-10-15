import GraphProtocols

/// The engine under the edge breadth-first searches: pulled one event at a time over `Rows`.
@frozen
@usableFromInline
package struct _EdgeBreadthFirstIterator<Rows: _EdgeSearchRows> {
    @usableFromInline var rows: Rows
    @usableFromInline let sources: [Rows.Vertex]
    @usableFromInline var nextSource = 0
    @usableFromInline let depthLimit: Int?
    /// The depth of each discovered vertex; -1 for undiscovered.
    @usableFromInline var depth: [Int] = []
    /// `_EdgeSearchFlag.pruned` and, undirected, `.explored`, set when the vertex's edges are
    /// examined: every edge between it and a vertex explored later, its tree edge and any copy of
    /// it included, was reported from it.
    @usableFromInline var flags: [UInt8] = []
    /// Undirected: the self-loops of the current row met once.
    @usableFromInline var loopsMet: [Rows.Edge] = []
    @usableFromInline var queue: [Int] = []
    @usableFromInline var head = 0
    /// The vertex whose edges are being reported, and the rest of them.
    @usableFromInline var current: Int?
    /// The rest of the current row: `row`, or slots when the rows cannot be read by iterator.
    @usableFromInline var cursor = 0
    @usableFromInline var end = 0
    @usableFromInline var shift = 0
    @usableFromInline var row = Rows.emptyRow
    /// A vertex reached by the tree edge just reported, to be discovered next.
    @usableFromInline var pendingDiscovery: Int?
    /// The vertex of the last event, when that event was its discovery: the one `prune()` acts on.
    @usableFromInline var justDiscovered: Int?

    @inlinable
    init(rows: Rows, sources: [Rows.Vertex], depthLimit: Int?) {
        self.rows = rows
        self.sources = sources
        self.depthLimit = depthLimit
        if let n = rows.denseCount {
            depth = [Int](repeating: -1, count: n)
            flags = [UInt8](repeating: 0, count: n)
        }
    }

    @inlinable
    func _isDiscovered(_ id: Int) -> Bool {
        id < depth.count && depth[id] >= 0
    }

    @inlinable
    mutating func _discover(_ id: Int, depth d: Int) {
        if rows.denseCount == nil {
            _grow(&depth, to: id + 1, with: -1)
            _grow(&flags, to: id + 1, with: 0)
        }
        depth[id] = d
        queue.append(id)
    }

    /// Whether `edge`, a self-loop of the current row, was met before: true at its second end.
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
    package mutating func next() -> EdgeBreadthFirstSearchEvent<Rows.Vertex, Rows.Edge>? {
        justDiscovered = nil
        if let id = pendingDiscovery {
            pendingDiscovery = nil
            justDiscovered = id
            return .discover(rows.vertex(id))
        }
        while nextSource < sources.count {
            let source = sources[nextSource]
            nextSource += 1
            let id = rows.identifier(of: source)
            if _isDiscovered(id) { continue }
            _discover(id, depth: 0)
            justDiscovered = id
            return .discover(source)
        }
        while true {
            if let u = current {
                let next: (edge: Rows.Edge, target: Int)?
                if !rows.readsByIterator {
                    if cursor < end {
                        next = rows.edge(atSlot: cursor, shift: shift)
                        cursor &+= 1
                    } else {
                        next = nil
                    }
                } else {
                    next = rows.next(in: &row)
                }
                guard let (edge, w) = next else {
                    current = nil
                    return .finish(rows.vertex(u))
                }
                if !_isDiscovered(w) {
                    _discover(w, depth: depth[u] + 1)
                    pendingDiscovery = w
                    return .treeEdge(edge)
                }
                if Rows.isUndirected {
                    if w == u {
                        if _isSecondEnd(ofLoop: edge) { continue }
                    } else if flags[w] & _EdgeSearchFlag.explored != 0 {
                        // Reported from `w`.
                        continue
                    }
                }
                return .nonTreeEdge(edge)
            }
            guard head < queue.count else { return nil }
            let u = queue[head]
            head += 1
            if flags[u] & _EdgeSearchFlag.pruned != 0 || depthLimit.map({ depth[u] >= $0 }) ?? false {
                return .finish(rows.vertex(u))
            }
            current = u
            if Rows.isUndirected { flags[u] |= _EdgeSearchFlag.explored }
            if !rows.readsByIterator {
                (cursor, end, shift) = rows.bounds(of: u)
            } else {
                rows.load(&row, of: u)
            }
        }
    }

    @inlinable
    package mutating func prune() {
        guard let id = justDiscovered else {
            preconditionFailure("prune() applies to the vertex just discovered; call it right after a discover event")
        }
        flags[id] |= _EdgeSearchFlag.pruned
    }
}

/// The edge breadth-first search pushed to `visit` over flat rows, read with integer cursors:
/// the `forEach` of the edge breadth-first searches. `sources` are identifiers. Returns false if
/// `visit` stopped it.
@inlinable
@inline(__always)
@discardableResult
package func _edgeBreadthFirst(
    _ rows: _EdgeFlatRows, count n: Int, sources: [Int], depthLimit: Int?, undirected: Bool,
    _ visit: (_EdgeSearchStep) -> Bool
) -> Bool {
    var depth = [Int](repeating: -1, count: n)
    var explored = [Bool](repeating: false, count: undirected ? n : 0)
    var loopsMet: [Int] = []
    var queue: [Int] = []
    queue.reserveCapacity(n)
    for s in sources where depth[s] < 0 {
        depth[s] = 0
        queue.append(s)
        guard visit(.discover(s)) else { return false }
    }
    var head = 0
    while head < queue.count {
        let u = queue[head]
        head &+= 1
        if depthLimit.map({ depth[u] < $0 }) ?? true {
            if undirected { explored[u] = true }
            let (start, end, shift) = rows.bounds(of: u)
            for k in start ..< end {
                let w = rows.targets[k]
                let edge = rows.position(at: k, shift: shift)
                if depth[w] < 0 {
                    depth[w] = depth[u] &+ 1
                    queue.append(w)
                    guard visit(.treeEdge(edge)), visit(.discover(w)) else { return false }
                    continue
                }
                if undirected {
                    if w == u {
                        if let m = loopsMet.firstIndex(of: edge) {
                            loopsMet.remove(at: m)
                            continue
                        }
                        loopsMet.append(edge)
                    } else if explored[w] {
                        continue
                    }
                }
                guard visit(.nonTreeEdge(edge)) else { return false }
            }
        }
        guard visit(.finish(u)) else { return false }
    }
    return true
}

extension _EdgeBreadthFirstIterator: Sendable where Rows: Sendable, Rows.Vertex: Sendable, Rows.Edge: Sendable, Rows.Row: Sendable {}

/// A breadth-first search whose edge events carry edge positions: a sequence of
/// `EdgeBreadthFirstSearchEvent`s, in the order `BreadthFirstSearch` reports them. Parallel edges
/// are told apart, and a weight or other per-edge value is read at the position given. It holds a
/// copy of the graph, so later changes to the original do not affect it, and it can be iterated
/// more than once.
///
/// `for event in search` pulls events one at a time, and stopping the loop stops the search. To
/// skip a vertex's out-edges, iterate by hand and call `prune()` right after its `discover` event.
/// `search.forEach { … }` pushes every event to a closure in one loop, which is faster when every
/// event is wanted.
@frozen
public struct EdgeBreadthFirstSearch<G: DirectedGraph>: Sequence {
    public typealias Element = EdgeBreadthFirstSearchEvent<G.Vertex, G.Edges.Index>

    @usableFromInline let graph: G
    @usableFromInline let sources: [G.Vertex]
    @usableFromInline let depthLimit: Int?

    @inlinable
    init(graph: G, sources: [G.Vertex], depthLimit: Int?) {
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
        Iterator(_EdgeBreadthFirstIterator(rows: _DirectedEdgeRows(graph), sources: sources, depthLimit: depthLimit))
    }

    /// Calls `body` with every event, in order, in one loop. Over rows the graph lends in index
    /// space, the search reads them with integer cursors; otherwise it is the iterator's loop.
    @inlinable
    public func forEach<Failure: Error>(_ body: (Element) throws(Failure) -> Void) throws(Failure) {
        var reader = _DirectedEdgeRows(graph)
        var sourceIDs: [Int] = []
        for source in sources { sourceIDs.append(reader.identifier(of: source)) }
        let rows = reader
        let n = rows.denseCount ?? 0
        var failure: Failure?
        let ran = rows.withFlatRows { flat in
            _edgeBreadthFirst(flat, count: n, sources: sourceIDs, depthLimit: depthLimit, undirected: false) { step in
                let event: Element
                switch step {
                case .discover(let v): event = .discover(rows.vertex(v))
                case .treeEdge(let e): event = .treeEdge(unsafeBitCast(e, to: G.Edges.Index.self))
                case .nonTreeEdge(let e): event = .nonTreeEdge(unsafeBitCast(e, to: G.Edges.Index.self))
                case .finish(let v): event = .finish(rows.vertex(v))
                case .backEdge, .forwardEdge, .crossEdge: preconditionFailure("A breadth-first search classifies edges as tree or non-tree only")
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
        @usableFromInline var search: _EdgeBreadthFirstIterator<_DirectedEdgeRows<G>>

        @inlinable
        init(_ search: _EdgeBreadthFirstIterator<_DirectedEdgeRows<G>>) { self.search = search }

        @inlinable
        public mutating func next() -> Element? { search.next() }

        /// Skips the out-edges of the vertex just discovered; it is still finished.
        ///
        /// - Precondition: the last event was a `discover`.
        @inlinable
        public mutating func prune() { search.prune() }
    }
}

extension EdgeBreadthFirstSearch: Sendable where G: Sendable, G.Vertex: Sendable {}
extension EdgeBreadthFirstSearch.Iterator: Sendable where G: Sendable, G.Vertex: Sendable, G.Edges.Index: Sendable, G.OutEdges.Iterator: Sendable, G.SuccessorIndices.Iterator: Sendable {}

/// The edge breadth-first search of an undirected graph: a sequence of
/// `EdgeBreadthFirstSearchEvent`s that reports each edge once, by its position, from the end
/// whose edges are examined first. It holds a copy of the graph and can be iterated more than
/// once.
///
/// `for event in search` pulls events one at a time, and stopping the loop stops the search. To
/// skip a vertex's edges, iterate by hand and call `prune()` right after its `discover` event.
/// `search.forEach { … }` pushes every event to a closure in one loop, which is faster when every
/// event is wanted.
@frozen
public struct UndirectedEdgeBreadthFirstSearch<G: Graph>: Sequence {
    public typealias Element = EdgeBreadthFirstSearchEvent<G.Vertex, G.Edges.Index>

    @usableFromInline let graph: G
    @usableFromInline let sources: [G.Vertex]
    @usableFromInline let depthLimit: Int?

    @inlinable
    init(graph: G, sources: [G.Vertex], depthLimit: Int?) {
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
        Iterator(_EdgeBreadthFirstIterator(rows: _UndirectedEdgeRows(graph), sources: sources, depthLimit: depthLimit))
    }

    /// Calls `body` with every event, in order, in one loop. Over rows the graph lends in index
    /// space, the search reads them with integer cursors; otherwise it is the iterator's loop.
    @inlinable
    public func forEach<Failure: Error>(_ body: (Element) throws(Failure) -> Void) throws(Failure) {
        var reader = _UndirectedEdgeRows(graph)
        var sourceIDs: [Int] = []
        for source in sources { sourceIDs.append(reader.identifier(of: source)) }
        let rows = reader
        let n = rows.denseCount ?? 0
        var failure: Failure?
        let ran = rows.withFlatRows { flat in
            _edgeBreadthFirst(flat, count: n, sources: sourceIDs, depthLimit: depthLimit, undirected: true) { step in
                let event: Element
                switch step {
                case .discover(let v): event = .discover(rows.vertex(v))
                case .treeEdge(let e): event = .treeEdge(unsafeBitCast(e, to: G.Edges.Index.self))
                case .nonTreeEdge(let e): event = .nonTreeEdge(unsafeBitCast(e, to: G.Edges.Index.self))
                case .finish(let v): event = .finish(rows.vertex(v))
                case .backEdge, .forwardEdge, .crossEdge: preconditionFailure("A breadth-first search classifies edges as tree or non-tree only")
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
        @usableFromInline var search: _EdgeBreadthFirstIterator<_UndirectedEdgeRows<G>>

        @inlinable
        init(_ search: _EdgeBreadthFirstIterator<_UndirectedEdgeRows<G>>) { self.search = search }

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

extension UndirectedEdgeBreadthFirstSearch: Sendable where G: Sendable, G.Vertex: Sendable {}
extension UndirectedEdgeBreadthFirstSearch.Iterator: Sendable where G: Sendable, G.Vertex: Sendable, G.Edges.Index: Sendable, G.IncidentEdges.Iterator: Sendable, G.NeighborIndices.Iterator: Sendable {}

extension LazyDirectedGraphView {
    /// A breadth-first search from `source` whose edge events carry edge positions.
    ///
    /// - Parameter depthLimit: When given, vertices at this depth are discovered and finished but
    ///   their out-edges are not reported.
    /// - Complexity: O(n + m) over the reached part.
    /// - Precondition: `source` is a vertex; `depthLimit` is not negative.
    @inlinable
    public func edgeBreadthFirstSearch(from source: Base.Vertex, depthLimit: Int? = nil) -> EdgeBreadthFirstSearch<Base> {
        EdgeBreadthFirstSearch(graph: base, sources: [source], depthLimit: depthLimit)
    }

    /// A breadth-first search from several sources at once whose edge events carry edge
    /// positions: all are discovered first, at depth 0, in the order given. A repeated source is
    /// ignored. The sources are read when the search is made, so the sequence must be finite.
    ///
    /// - Complexity: O(n + m) over the reached part.
    /// - Precondition: every source is a vertex; `depthLimit` is not negative.
    @inlinable
    public func edgeBreadthFirstSearch(from sources: some Sequence<Base.Vertex>, depthLimit: Int? = nil) -> EdgeBreadthFirstSearch<Base> {
        EdgeBreadthFirstSearch(graph: base, sources: Array(sources), depthLimit: depthLimit)
    }
}

extension LazyGraphView {
    /// A breadth-first search from `source` that reports each edge once, by its position.
    ///
    /// - Parameter depthLimit: When given, vertices at this depth are discovered and finished but
    ///   their edges are not examined.
    /// - Complexity: O(n + m) over the reached part.
    /// - Precondition: `source` is a vertex; `depthLimit` is not negative.
    @inlinable
    public func edgeBreadthFirstSearch(from source: Base.Vertex, depthLimit: Int? = nil) -> UndirectedEdgeBreadthFirstSearch<Base> {
        UndirectedEdgeBreadthFirstSearch(graph: base, sources: [source], depthLimit: depthLimit)
    }

    /// A breadth-first search from several sources at once that reports each edge once, by its
    /// position: all are discovered first, at depth 0, in the order given. A repeated source is
    /// ignored. The sources are read when the search is made, so the sequence must be finite.
    ///
    /// - Complexity: O(n + m) over the reached part.
    /// - Precondition: every source is a vertex; `depthLimit` is not negative.
    @inlinable
    public func edgeBreadthFirstSearch(from sources: some Sequence<Base.Vertex>, depthLimit: Int? = nil) -> UndirectedEdgeBreadthFirstSearch<Base> {
        UndirectedEdgeBreadthFirstSearch(graph: base, sources: Array(sources), depthLimit: depthLimit)
    }
}
