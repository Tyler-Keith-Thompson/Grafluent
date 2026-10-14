import GraphProtocols

/// Every topological order of flat rows by backtracking (Knuth and Szwarcfiter): at each depth
/// the ready vertices (all in-edges from placed vertices) are tried in increasing number, found
/// in a bit set of them.
@frozen
@usableFromInline
struct _TopologicalSortSearch: Sendable {
    @usableFromInline let offsets: [Int]
    @usableFromInline let targets: [Int]
    @usableFromInline var inDegree: [Int]
    /// Bit v: v is not placed and every edge into it comes from a placed vertex.
    @usableFromInline var ready: [UInt64]
    @usableFromInline var order: [Int] = []
    @usableFromInline var started = false

    @inlinable
    init(offsets: [Int], targets: [Int]) {
        let n = offsets.count - 1
        self.offsets = offsets
        self.targets = targets
        var inDegree = [Int](repeating: 0, count: n)
        for w in targets { inDegree[w] += 1 }
        var ready = [UInt64](repeating: 0, count: (n + 63) >> 6)
        for v in 0 ..< n where inDegree[v] == 0 { ready[v >> 6] |= 1 << UInt64(v & 63) }
        self.inDegree = inDegree
        self.ready = ready
        order.reserveCapacity(n)
    }

    @inlinable
    var count: Int { offsets.count - 1 }

    /// The least ready vertex greater than `v`, or -1.
    @inlinable
    @inline(__always)
    func _nextReady(after v: Int) -> Int {
        let from = v + 1
        var word = from >> 6
        guard word < ready.count else { return -1 }
        var bits = ready[word] & (~0 << UInt64(from & 63))
        while bits == 0 {
            word += 1
            guard word < ready.count else { return -1 }
            bits = ready[word]
        }
        return word << 6 | bits.trailingZeroBitCount
    }

    @inlinable
    @inline(__always)
    mutating func _place(_ v: Int) {
        ready[v >> 6] &= ~(1 << UInt64(v & 63))
        order.append(v)
        for k in offsets[v] ..< offsets[v + 1] {
            let w = targets[k]
            inDegree[w] -= 1
            if inDegree[w] == 0 { ready[w >> 6] |= 1 << UInt64(w & 63) }
        }
    }

    @inlinable
    @inline(__always)
    mutating func _unplace(_ v: Int) {
        for k in offsets[v] ..< offsets[v + 1] {
            let w = targets[k]
            if inDegree[w] == 0 { ready[w >> 6] &= ~(1 << UInt64(w & 63)) }
            inDegree[w] += 1
        }
        ready[v >> 6] |= 1 << UInt64(v & 63)
    }

    /// Places the least ready vertex until every vertex is placed; false when none is ready first.
    @inlinable
    mutating func _fill() -> Bool {
        while order.count < count {
            let v = _nextReady(after: -1)
            if v < 0 { return false }
            _place(v)
        }
        return true
    }

    /// Advances to the next order, in `order`; false when there is none.
    @inlinable
    mutating func next() -> Bool {
        if !started {
            started = true
            // Only a cycle leaves no vertex ready, and then before the first order.
            return _fill()
        }
        while let v = order.popLast() {
            _unplace(v)
            let w = _nextReady(after: v)
            if w >= 0 {
                _place(w)
                // Any placement of an acyclic graph's vertices completes.
                _ = _fill()
                return true
            }
        }
        return false
    }
}

/// Every topological order of a directed graph, lazily: the orders of its vertices in which every
/// edge goes from an earlier vertex to a later one, in lexicographic order of the vertices'
/// positions in `vertices`. A graph with a cycle (a self-loop is one) has none, and the empty
/// graph has one, the empty order.
///
/// The sequence holds the graph (a value), so iterating again gives the same orders. The first
/// `next()` copies the graph's rows, O(n + m); each order then takes O(n²/64 + n + m) at most.
@frozen
public struct AllTopologicalSorts<G: DirectedGraph>: Sequence {
    public typealias Element = [G.Vertex]

    @usableFromInline let graph: G

    @inlinable
    init(_ graph: G) {
        self.graph = graph
    }

    @inlinable
    public func makeIterator() -> Iterator {
        Iterator(graph)
    }

    @frozen
    public struct Iterator: IteratorProtocol {
        @usableFromInline let graph: G
        @usableFromInline var search: _TopologicalSortSearch?
        @usableFromInline var vertices: [G.Vertex] = []

        @inlinable
        init(_ graph: G) {
            self.graph = graph
        }

        @inlinable
        public mutating func next() -> Element? {
            if search == nil {
                var ids = _VertexIdentifiers(graph)
                if !ids.isDense { for v in graph.vertices { _ = ids.identifier(of: v) } }
                let n = ids.count
                var offsets = [Int](repeating: 0, count: n + 1)
                var targets: [Int] = []
                targets.reserveCapacity(graph.edgeCount)
                for u in 0 ..< n {
                    ids.forEachSuccessor(of: u) { targets.append($0) }
                    offsets[u + 1] = targets.count
                }
                vertices.reserveCapacity(n)
                for v in 0 ..< n { vertices.append(ids.vertex(v)) }
                search = _TopologicalSortSearch(offsets: offsets, targets: targets)
            }
            guard search!.next() else { return nil }
            var order: [G.Vertex] = []
            order.reserveCapacity(vertices.count)
            for v in search!.order { order.append(vertices[v]) }
            return order
        }
    }
}

extension AllTopologicalSorts: Sendable where G: Sendable {}
extension AllTopologicalSorts.Iterator: Sendable where G: Sendable, G.Vertex: Sendable {}

extension DirectedGraph {
    /// Every topological order of the graph, lazily, in lexicographic order of the vertices'
    /// positions in `vertices`; none when the graph has a cycle. See `AllTopologicalSorts`.
    ///
    /// - Complexity: O(n + m) before the first order; see `AllTopologicalSorts`.
    @inlinable
    public func allTopologicalSorts() -> AllTopologicalSorts<Self> {
        AllTopologicalSorts(self)
    }
}
