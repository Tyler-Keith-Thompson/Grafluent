import GraphProtocols

/// A successor cursor that also records, in `loops`, whether its row's vertex is among its own
/// successors: the self-loop test a single-vertex component needs, made while Tarjan's search
/// reads the row instead of in a second pass.
@frozen
@usableFromInline
struct _LoopNotingCursor<Base: IteratorProtocol<Int>>: IteratorProtocol {
    @usableFromInline var base: Base
    @usableFromInline let vertex: Int
    @usableFromInline let loops: UnsafeMutablePointer<Bool>

    @inlinable
    @inline(__always)
    init(_ base: Base, vertex: Int, loops: UnsafeMutablePointer<Bool>) {
        self.base = base
        self.vertex = vertex
        self.loops = loops
    }

    @inlinable
    @inline(__always)
    mutating func next() -> Int? {
        guard let w = base.next() else { return nil }
        if w == vertex { loops[w] = true }
        return w
    }
}

extension DirectedGraph {
    /// `_stronglyConnected(_:)`, recording in `loops` each vertex number with a self-loop.
    @inlinable
    @inline(__always)
    func _stronglyConnected(_ vertices: _DenseVertices<Self>, notingLoopsIn loops: UnsafeMutablePointer<Bool>) -> (labels: [Int], count: Int) {
        let n = vertices.count
        if vertices.isIndexed {
            if let result = _withSuccessorIndexRows({ offsets, targets in
                _tarjan(count: n) { _LoopNotingCursor(_RowCursor(row: $0, offsets: offsets, targets: targets), vertex: $0, loops: loops) }
            }) {
                return (result.labels, result.count)
            }
            if let result = _withCheckedOutIndexRows({ targets, targetRows, _, _ in
                _tarjan(count: n) { _LoopNotingCursor(_PooledRowCursor(row: $0, targets: targets, targetRows: targetRows), vertex: $0, loops: loops) }
            }) {
                return (result.labels, result.count)
            }
            let result = _tarjan(count: n) { _LoopNotingCursor(successorIndices(ofIndex: $0).makeIterator(), vertex: $0, loops: loops) }
            return (result.labels, result.count)
        }
        if let rows = vertices.rows {
            let result = rows.offsets.withUnsafeBufferPointer { offsets in
                rows.neighbors.withUnsafeBufferPointer { targets in
                    _tarjan(count: n) { _LoopNotingCursor(_RowCursor(row: $0, offsets: offsets, targets: targets), vertex: $0, loops: loops) }
                }
            }
            return (result.labels, result.count)
        }
        let result = _tarjan(count: n) { u in
            _LoopNotingCursor(successors(of: vertices.vertices[u]).lazy.map { vertices.number(of: $0) }.makeIterator(), vertex: u, loops: loops)
        }
        return (result.labels, result.count)
    }

    /// The nontrivial strongly connected components: the ones that contain a cycle, which are the
    /// components of two or more vertices and the single vertices with a self-loop. A vertex is in
    /// one exactly when it lies on a cycle, and two vertices share one exactly when a cycle passes
    /// through both.
    ///
    /// Tarjan's algorithm, one pass: a self-loop is noticed while the search reads the vertex's
    /// successors.
    ///
    /// The components are those of `stronglyConnectedComponents()` without the trivial ones, in the
    /// same order, a reverse topological order: every path between two of them goes from a later
    /// one to an earlier one. Each lists its vertices in `vertices` order. Empty exactly when the
    /// graph is acyclic. Each is a slice of one shared array, as in `attractingComponents()`, so its
    /// indices do not start at 0.
    ///
    /// Each component's first vertex is its earliest in `vertices`, so one sort by that vertex's
    /// position puts the components in `vertices` order, O(C log C) for C components. On a
    /// `StableDirectedGraph`, where positions are insertion order:
    ///
    /// ```swift
    /// let inInsertionOrder = graph.nontrivialStronglyConnectedComponents()
    ///     .sorted { graph.vertexPosition(of: $0.first!) < graph.vertexPosition(of: $1.first!) }
    /// ```
    ///
    /// - Complexity: O(V + E).
    @inlinable
    public func nontrivialStronglyConnectedComponents() -> [ArraySlice<Vertex>] {
        let vertices = _DenseVertices(self)
        let n = vertices.count
        guard n > 0 else { return [] }
        var loops = [Bool](repeating: false, count: n)
        let (labels, count) = loops.withUnsafeMutableBufferPointer { _stronglyConnected(vertices, notingLoopsIn: $0.baseAddress!) }
        // Each kept component's next free slot in `members`, -1 for a trivial one: kept are the
        // components of two or more vertices, and those whose vertex has a self-loop.
        var size = [Int](repeating: 0, count: count)
        var next = [Int](repeating: -1, count: count)
        for v in 0 ..< n { size[labels[v]] &+= 1 }
        for v in 0 ..< n where loops[v] { next[labels[v]] = 0 }
        var ends: [Int] = []
        var total = 0
        for c in 0 ..< count where size[c] > 1 || next[c] == 0 {
            next[c] = total
            total &+= size[c]
            ends.append(total)
        }
        guard total > 0 else { return [] }
        // The kept vertices, component by component, each component in vertex-number order,
        // which is `vertices` order.
        let members = [Vertex](unsafeUninitializedCapacity: total) { buffer, initialized in
            for v in 0 ..< n {
                let slot = next[labels[v]]
                if slot >= 0 {
                    (buffer.baseAddress! + slot).initialize(to: vertices.vertex(v))
                    next[labels[v]] = slot &+ 1
                }
            }
            initialized = total
        }
        var components: [ArraySlice<Vertex>] = []
        components.reserveCapacity(ends.count)
        var start = 0
        for end in ends {
            components.append(members[start ..< end])
            start = end
        }
        return components
    }
}
