import GraphProtocols
import Walks

/// The part of a graph reachable from one vertex, copied into flat rows in a local numbering:
/// vertex 0 is the source, the others numbered in breadth-first order, and slot `offsets[v] ..<
/// offsets[v + 1]` of `targets` and `positions` is vertex `v`'s row in the graph's order.
@frozen
@usableFromInline
struct _ReachableRows<Vertex, Edge> {
    @usableFromInline var offsets: [Int] = [0]
    @usableFromInline var targets: [Int] = []
    @usableFromInline var positions: [Edge] = []
    @usableFromInline var vertices: [Vertex] = []
    /// The local number of each identifier of the rows, or -1.
    @usableFromInline var local: [Int] = []

    @inlinable
    init() {}

    @inlinable
    var count: Int { vertices.count }

    /// The local number of identifier `id`, or -1 when the source does not reach it.
    @inlinable
    func number(ofIdentifier id: Int) -> Int {
        id < local.count ? local[id] : -1
    }
}

extension _EdgeSearchRows {
    /// The rows reachable from `source`, copied once. O(n′ + m′) for the n′ vertices and m′ edges
    /// reached.
    @inlinable
    mutating func _reachableRows(from source: Int) -> _ReachableRows<Vertex, Edge> {
        var copy = _ReachableRows<Vertex, Edge>()
        if let n = denseCount { copy.local = [Int](repeating: -1, count: n) }
        var identifiers: [Int] = [source]
        _grow(&copy.local, to: source + 1, with: -1)
        copy.local[source] = 0
        var head = 0
        var row = Self.emptyRow
        while head < identifiers.count {
            let u = identifiers[head]
            head += 1
            copy.vertices.append(vertex(u))
            if readsBySlot {
                let (start, end, shift) = bounds(of: u)
                for k in start ..< end {
                    let (edge, w) = edge(atSlot: k, shift: shift)
                    copy._append(edge, w, &identifiers)
                }
            } else {
                load(&row, of: u)
                while let (edge, w) = next(in: &row) { copy._append(edge, w, &identifiers) }
                clear(&row)
            }
            copy.offsets.append(copy.targets.count)
        }
        return copy
    }
}

extension _ReachableRows {
    @inlinable
    @inline(__always)
    mutating func _append(_ edge: Edge, _ w: Int, _ identifiers: inout [Int]) {
        _grow(&local, to: w + 1, with: -1)
        if local[w] < 0 {
            local[w] = identifiers.count
            identifiers.append(w)
        }
        targets.append(local[w])
        positions.append(edge)
    }
}

/// A depth-first enumeration of the simple paths from vertex 0 of flat rows to a set of target
/// vertices, kept on its own stack with an integer cursor per vertex on the path.
@frozen
@usableFromInline
struct _SimplePathSearch: Sendable {
    @usableFromInline let offsets: [Int]
    @usableFromInline let targets: [Int]
    @usableFromInline let isTarget: [Bool]
    /// Whether a target is reachable from the vertex (the vertex itself counts).
    @usableFromInline let reachesTarget: [Bool]
    /// Whether to extend a path past a target it ends at: only when there is another target.
    @usableFromInline let extendsPastTargets: Bool
    @usableFromInline let maxLength: Int
    @usableFromInline var onPath: [Bool]
    /// The path's vertices; `slots[i]` is the slot taken into `path[i + 1]`.
    @usableFromInline var path: [Int] = []
    @usableFromInline var slots: [Int] = []
    /// The next slot to try out of each vertex on the path.
    @usableFromInline var cursors: [Int] = []
    @usableFromInline var started = false

    @inlinable
    init(offsets: [Int], targets: [Int], isTarget: [Bool], maxLength: Int) {
        let n = offsets.count - 1
        self.offsets = offsets
        self.targets = targets
        self.isTarget = isTarget
        self.maxLength = maxLength
        extendsPastTargets = isTarget.lazy.filter { $0 }.count > 1
        onPath = [Bool](repeating: false, count: n)
        // Backward from the targets over the reversed rows.
        var inOffsets = [Int](repeating: 0, count: n + 1)
        for w in targets { inOffsets[w + 1] += 1 }
        for v in 0 ..< n { inOffsets[v + 1] += inOffsets[v] }
        var fill = inOffsets
        var sources = [Int](repeating: 0, count: targets.count)
        for u in 0 ..< n {
            for k in offsets[u] ..< offsets[u + 1] {
                let w = targets[k]
                sources[fill[w]] = u
                fill[w] += 1
            }
        }
        var reaches = isTarget
        var stack: [Int] = []
        for v in 0 ..< n where isTarget[v] { stack.append(v) }
        while let w = stack.popLast() {
            for k in inOffsets[w] ..< inOffsets[w + 1] where !reaches[sources[k]] {
                reaches[sources[k]] = true
                stack.append(sources[k])
            }
        }
        reachesTarget = reaches
    }

    /// Advances to the next path; false when there is none. The path is `path` and `slots`.
    @inlinable
    mutating func next() -> Bool {
        if !started {
            started = true
            guard !onPath.isEmpty, reachesTarget[0] else { return false }
            _push(0, slot: -1)
            if isTarget[0] { return true }
        } else if let last = path.last, !extendsPastTargets, isTarget[last] {
            // A path ending at the only target goes no further.
            _pop()
        }
        while let u = path.last {
            let top = path.count - 1
            let k = cursors[top]
            if top < maxLength && k < offsets[u + 1] {
                cursors[top] = k + 1
                let w = targets[k]
                if onPath[w] || !reachesTarget[w] { continue }
                _push(w, slot: k)
                if isTarget[w] { return true }
                continue
            }
            _pop()
        }
        return false
    }

    @inlinable
    @inline(__always)
    mutating func _push(_ w: Int, slot: Int) {
        if slot >= 0 { slots.append(slot) }
        path.append(w)
        cursors.append(offsets[w])
        onPath[w] = true
    }

    @inlinable
    @inline(__always)
    mutating func _pop() {
        let u = path.removeLast()
        cursors.removeLast()
        onPath[u] = false
        if !path.isEmpty { slots.removeLast() }
    }
}

/// The state both simple-path sequences iterate with: the copied rows and the search over them.
@frozen
@usableFromInline
struct _SimplePathIteration<Vertex: Hashable, Edge: Hashable> {
    @usableFromInline var rows: _ReachableRows<Vertex, Edge>
    @usableFromInline var search: _SimplePathSearch

    @inlinable
    init<Rows: _EdgeSearchRows>(_ rows: inout Rows, source: Vertex, targets: [Vertex], maxLength: Int) where Rows.Vertex == Vertex, Rows.Edge == Edge {
        let reached = rows._reachableRows(from: rows.identifier(of: source))
        var isTarget = [Bool](repeating: false, count: reached.count)
        for t in targets {
            let v = reached.number(ofIdentifier: rows.identifier(of: t))
            if v >= 0 { isTarget[v] = true }
        }
        self.rows = reached
        search = _SimplePathSearch(offsets: reached.offsets, targets: reached.targets, isTarget: isTarget, maxLength: maxLength)
    }

    @inlinable
    mutating func next() -> Path<Vertex, Edge>? {
        guard search.next() else { return nil }
        var vertices: [Vertex] = [], edges: [Edge] = []
        vertices.reserveCapacity(search.path.count)
        edges.reserveCapacity(search.slots.count)
        for v in search.path { vertices.append(rows.vertices[v]) }
        for k in search.slots { edges.append(rows.positions[k]) }
        return Path(_uncheckedVertices: vertices, edges: edges)
    }
}

/// Every simple path of a directed graph from a source to any of a set of targets, lazily, in the
/// order a depth-first search from the source, taking out-edges in `outEdges` order, reaches them.
///
/// Each copy of a parallel edge gives a different path. A path reaching one target continues to
/// the others, so a path through a target to another is listed after the shorter one. The source
/// itself, when it is a target, gives the trivial path first.
///
/// The sequence holds the graph (a value), so iterating again gives the same paths. The first
/// `next()` copies the rows the source reaches, O(n + m). A vertex that reaches no target is never
/// entered, but a partial path can still end where every way on is blocked by its own vertices,
/// so the time between two paths is not bounded by a polynomial in n + m.
@frozen
public struct DirectedSimplePaths<G: DirectedGraph>: Sequence {
    public typealias Element = Path<G.Vertex, G.Edges.Index>

    @usableFromInline let graph: G
    @usableFromInline let source: G.Vertex
    @usableFromInline let targets: [G.Vertex]
    /// The longest path, in edges, that the sequence includes.
    public let maxLength: Int

    @inlinable
    init(_ graph: G, source: G.Vertex, targets: [G.Vertex], maxLength: Int) {
        precondition(maxLength >= 0, "maxLength must be nonnegative")
        precondition(graph.contains(source), "The source \(source) is not a vertex of the graph")
        for t in targets { precondition(graph.contains(t), "The target \(t) is not a vertex of the graph") }
        self.graph = graph
        self.source = source
        self.targets = targets
        self.maxLength = maxLength
    }

    @inlinable
    public func makeIterator() -> Iterator {
        Iterator(self)
    }

    @frozen
    public struct Iterator: IteratorProtocol {
        @usableFromInline let paths: DirectedSimplePaths
        @usableFromInline var iteration: _SimplePathIteration<G.Vertex, G.Edges.Index>?

        @inlinable
        init(_ paths: DirectedSimplePaths) {
            self.paths = paths
        }

        @inlinable
        public mutating func next() -> Element? {
            if iteration == nil {
                var rows = _DirectedEdgeRows(paths.graph)
                iteration = _SimplePathIteration(&rows, source: paths.source, targets: paths.targets, maxLength: paths.maxLength)
            }
            return iteration!.next()
        }
    }
}

/// Every simple path of an undirected graph from a source to any of a set of targets, lazily, in
/// the order a depth-first search from the source, taking edges in `incidentEdges` order, reaches
/// them. Each path is listed once, from the source; each copy of a parallel edge gives a different
/// path, and a self-loop is on none. Otherwise as `DirectedSimplePaths`.
@frozen
public struct UndirectedSimplePaths<G: Graph>: Sequence {
    public typealias Element = Path<G.Vertex, G.Edges.Index>

    @usableFromInline let graph: G
    @usableFromInline let source: G.Vertex
    @usableFromInline let targets: [G.Vertex]
    /// The longest path, in edges, that the sequence includes.
    public let maxLength: Int

    @inlinable
    init(_ graph: G, source: G.Vertex, targets: [G.Vertex], maxLength: Int) {
        precondition(maxLength >= 0, "maxLength must be nonnegative")
        precondition(graph.contains(source), "The source \(source) is not a vertex of the graph")
        for t in targets { precondition(graph.contains(t), "The target \(t) is not a vertex of the graph") }
        self.graph = graph
        self.source = source
        self.targets = targets
        self.maxLength = maxLength
    }

    @inlinable
    public func makeIterator() -> Iterator {
        Iterator(self)
    }

    @frozen
    public struct Iterator: IteratorProtocol {
        @usableFromInline let paths: UndirectedSimplePaths
        @usableFromInline var iteration: _SimplePathIteration<G.Vertex, G.Edges.Index>?

        @inlinable
        init(_ paths: UndirectedSimplePaths) {
            self.paths = paths
        }

        @inlinable
        public mutating func next() -> Element? {
            if iteration == nil {
                var rows = _UndirectedEdgeRows(paths.graph)
                iteration = _SimplePathIteration(&rows, source: paths.source, targets: paths.targets, maxLength: paths.maxLength)
            }
            return iteration!.next()
        }
    }
}

extension _ReachableRows: Sendable where Vertex: Sendable, Edge: Sendable {}
extension _SimplePathIteration: Sendable where Vertex: Sendable, Edge: Sendable {}
extension DirectedSimplePaths: Sendable where G: Sendable, G.Vertex: Sendable {}
extension DirectedSimplePaths.Iterator: Sendable where G: Sendable, G.Vertex: Sendable, G.Edges.Index: Sendable {}
extension UndirectedSimplePaths: Sendable where G: Sendable, G.Vertex: Sendable {}
extension UndirectedSimplePaths.Iterator: Sendable where G: Sendable, G.Vertex: Sendable, G.Edges.Index: Sendable {}

extension DirectedGraph {
    /// Every simple path from `source` to `target`, lazily: no vertex twice, each copy of a
    /// parallel edge a different path, in the order of `DirectedSimplePaths`. When `source` is
    /// `target`, the trivial path alone.
    ///
    /// - Parameter maxLength: The longest path to include, in edges.
    /// - Complexity: O(n + m) before the first path; see `DirectedSimplePaths`.
    /// - Precondition: both are vertices, and `maxLength >= 0`.
    @inlinable
    public func allSimplePaths(from source: Vertex, to target: Vertex, maxLength: Int = .max) -> DirectedSimplePaths<Self> {
        DirectedSimplePaths(self, source: source, targets: [target], maxLength: maxLength)
    }

    /// Every simple path from `source` to any of `targets`, lazily, in the order of
    /// `DirectedSimplePaths`: a path through one target to another is listed too.
    ///
    /// - Parameter maxLength: The longest path to include, in edges.
    /// - Complexity: O(n + m) before the first path; see `DirectedSimplePaths`.
    /// - Precondition: `source` and every target are vertices, and `maxLength >= 0`.
    @inlinable
    public func allSimplePaths(from source: Vertex, to targets: some Sequence<Vertex>, maxLength: Int = .max) -> DirectedSimplePaths<Self> {
        DirectedSimplePaths(self, source: source, targets: Array(targets), maxLength: maxLength)
    }
}

extension Graph {
    /// Every simple path from `source` to `target`, lazily: no vertex twice, each copy of a
    /// parallel edge a different path, in the order of `UndirectedSimplePaths`. When `source` is
    /// `target`, the trivial path alone.
    ///
    /// - Parameter maxLength: The longest path to include, in edges.
    /// - Complexity: O(n + m) before the first path; see `DirectedSimplePaths`.
    /// - Precondition: both are vertices, and `maxLength >= 0`.
    @inlinable
    public func allSimplePaths(from source: Vertex, to target: Vertex, maxLength: Int = .max) -> UndirectedSimplePaths<Self> {
        UndirectedSimplePaths(self, source: source, targets: [target], maxLength: maxLength)
    }

    /// Every simple path from `source` to any of `targets`, lazily, in the order of
    /// `UndirectedSimplePaths`: a path through one target to another is listed too.
    ///
    /// - Parameter maxLength: The longest path to include, in edges.
    /// - Complexity: O(n + m) before the first path; see `DirectedSimplePaths`.
    /// - Precondition: `source` and every target are vertices, and `maxLength >= 0`.
    @inlinable
    public func allSimplePaths(from source: Vertex, to targets: some Sequence<Vertex>, maxLength: Int = .max) -> UndirectedSimplePaths<Self> {
        UndirectedSimplePaths(self, source: source, targets: Array(targets), maxLength: maxLength)
    }
}
