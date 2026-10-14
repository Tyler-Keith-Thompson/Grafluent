import Centrality
import GraphProtocols
import PriorityQueueModule

/// A component's most central live edge: the greatest betweenness, then the least edge number.
/// Ordered so that the minimum is the edge to remove next.
@frozen
@usableFromInline
struct _CentralEdge: Comparable {
    @usableFromInline let score: Double
    @usableFromInline let edge: Int

    @inlinable
    init(score: Double, edge: Int) {
        self.score = score
        self.edge = edge
    }

    @inlinable
    static func < (lhs: _CentralEdge, rhs: _CentralEdge) -> Bool {
        lhs.score > rhs.score || (lhs.score == rhs.score && lhs.edge < rhs.edge)
    }
}

/// The partitions of the Girvan–Newman method (Girvan and Newman 2002), coarsest first: repeatedly
/// remove an edge of greatest betweenness, and list the components each time their number grows.
///
/// Returned by `girvanNewmanCommunities()`. Iterating it does the work, one split at a time: the
/// first partition has one more community than the graph has components, each later one splits
/// one community in two, and the last is every vertex alone. A graph with no edges other than
/// self-loops lists its components once. Each partition keeps a copy-on-write copy of the graph,
/// as `Partition` does.
@frozen
public struct GirvanNewmanSequence<G: Graph>: Sequence {
    public typealias Element = Partition<DirectedView<G>>

    @usableFromInline let _graph: G
    @usableFromInline let _numbers: [G.Vertex: Int]?
    @usableFromInline let _listed: [G.Vertex]?
    /// The rows without self-loops, with edge numbers.
    @usableFromInline let _rows: _CompressedRows
    @usableFromInline let _edgeCount: Int

    @inlinable
    init(_ graph: G) {
        _graph = graph
        _listed = graph._listedVertices()
        _numbers = _listed.map(_vertexNumbers)
        _rows = graph._runOnUndirectedRows(_CopyRows(readsEdges: true, dropsLoops: true))
        _edgeCount = graph.edgeCount
    }

    @inlinable
    public func makeIterator() -> Iterator { Iterator(self) }

    /// The state of the method: the graph left after the removals so far, its components, and the
    /// betweenness of every edge left. Removing an edge recomputes the betweenness of its component
    /// only (of both parts when it splits), since no other edge's shortest paths change.
    @frozen
    public struct Iterator: IteratorProtocol {
        @usableFromInline let _sequence: GirvanNewmanSequence
        /// Row v is slots `starts[v] ..< ends[v]`; a removed edge's slots are swapped past the end.
        @usableFromInline var _starts: [Int]
        @usableFromInline var _ends: [Int]
        @usableFromInline var _targets: [Int]
        @usableFromInline var _edges: [Int]
        /// The edge end in each slot (2e and 2e + 1 for edge e), and the slot of each edge end.
        @usableFromInline var _endInSlot: [Int]
        @usableFromInline var _slotOfEnd: [Int]
        /// The vertex whose row holds each edge end.
        @usableFromInline var _vertexOfEnd: [Int]
        /// Ordered-pair betweenness of every edge left, by edge number.
        @usableFromInline var _scores: [Double]
        /// The component of each vertex, numbered 0 ..< `_componentCount`.
        @usableFromInline var _component: [Int]
        @usableFromInline var _componentCount = 0
        /// The round in which each vertex was last reached by `_collect`.
        @usableFromInline var _seen: [Int]
        @usableFromInline var _round = 0
        /// Each component with an edge left, keyed by its most central edge.
        @usableFromInline var _central: IndexedPriorityQueue<_CentralEdge>
        // Search scratch, one value per vertex; `_distance` is −1 between searches.
        @usableFromInline var _distance: [Int]
        @usableFromInline var _sigma: [Double]
        @usableFromInline var _delta: [Double]
        @usableFromInline var _order: [Int]
        @usableFromInline var _started = false

        @inlinable
        init(_ sequence: GirvanNewmanSequence) {
            _sequence = sequence
            let rows = sequence._rows
            let n = rows.count, m = sequence._edgeCount
            _starts = Array(rows.offsets.dropLast())
            _ends = Array(rows.offsets.dropFirst())
            _targets = rows.targets
            _edges = rows.edges
            var endInSlot = [Int](repeating: 0, count: rows.targets.count)
            var slotOfEnd = [Int](repeating: -1, count: 2 * m)
            var vertexOfEnd = [Int](repeating: 0, count: 2 * m)
            for v in 0 ..< n {
                for slot in rows.offsets[v] ..< rows.offsets[v + 1] {
                    let e = rows.edges[slot]
                    let end = slotOfEnd[2 * e] < 0 ? 2 * e : 2 * e + 1
                    endInSlot[slot] = end
                    slotOfEnd[end] = slot
                    vertexOfEnd[end] = v
                }
            }
            _endInSlot = endInSlot
            _slotOfEnd = slotOfEnd
            _vertexOfEnd = vertexOfEnd
            _scores = [Double](repeating: 0, count: m)
            _component = [Int](repeating: -1, count: n)
            _seen = [Int](repeating: 0, count: n)
            _central = IndexedPriorityQueue(indexBound: n)
            _distance = [Int](repeating: -1, count: n)
            _sigma = [Double](repeating: 0, count: n)
            _delta = [Double](repeating: 0, count: n)
            _order = [Int](repeating: 0, count: n)
        }

        /// The next partition, or nil after every vertex is alone. Each call removes edges until a
        /// community splits: O(n_C · m_C) per removal from a component C with n_C vertices and m_C
        /// edges, plus O(n) to build the partition.
        @inlinable
        public mutating func next() -> Partition<DirectedView<G>>? {
            if !_started {
                _started = true
                let n = _component.count
                var listed: [Int] = []
                for v in 0 ..< n where _component[v] < 0 {
                    _collect(from: v, into: &listed)
                    for w in listed { _component[w] = _componentCount }
                    _recompute(listed, component: _componentCount)
                    _componentCount += 1
                }
                if _central.isEmpty { return _partition() }
            }
            var listed: [Int] = []
            while let (c, central) = _central.popMin() {
                let e = central.edge
                let u = _vertexOfEnd[2 * e], v = _vertexOfEnd[2 * e + 1]
                _removeEnd(2 * e)
                _removeEnd(2 * e + 1)
                _collect(from: u, into: &listed)
                if _seen[v] == _round {
                    _recompute(listed, component: c)
                    continue
                }
                // u's side becomes a new community; v's side keeps the number c.
                let split = _componentCount
                _componentCount += 1
                for w in listed { _component[w] = split }
                _recompute(listed, component: split)
                _collect(from: v, into: &listed)
                _recompute(listed, component: c)
                return _partition()
            }
            return nil
        }

        /// Swap-removes the slot of edge end `end` from its row.
        @inlinable
        mutating func _removeEnd(_ end: Int) {
            let slot = _slotOfEnd[end], v = _vertexOfEnd[end]
            let last = _ends[v] - 1
            let moved = _endInSlot[last]
            _targets[slot] = _targets[last]
            _edges[slot] = _edges[last]
            _endInSlot[slot] = moved
            _slotOfEnd[moved] = slot
            _endInSlot[last] = end
            _slotOfEnd[end] = last
            _ends[v] = last
        }

        /// Lists every vertex reachable from `s` over the edges left in `listed`, in breadth-first
        /// order, and stamps them with a new `_round` in `_seen`.
        @inlinable
        mutating func _collect(from s: Int, into listed: inout [Int]) {
            _round += 1
            let round = _round
            listed.removeAll(keepingCapacity: true)
            _seen[s] = round
            listed.append(s)
            var head = 0
            while head < listed.count {
                let v = listed[head]
                head += 1
                for slot in _starts[v] ..< _ends[v] {
                    let w = _targets[slot]
                    if _seen[w] != round {
                        _seen[w] = round
                        listed.append(w)
                    }
                }
            }
        }

        /// Recomputes the betweenness of the edges among `listed` (one component) and queues the
        /// component under its most central edge, if it has one.
        @inlinable
        mutating func _recompute(_ listed: [Int], component: Int) {
            var best: _CentralEdge?
            for v in listed {
                for slot in _starts[v] ..< _ends[v] { _scores[_edges[slot]] = 0 }
            }
            _starts.withUnsafeBufferPointer { starts in
                _ends.withUnsafeBufferPointer { ends in
                    _targets.withUnsafeBufferPointer { targets in
                        _edges.withUnsafeBufferPointer { edges in
                            listed.withUnsafeBufferPointer { pivots in
                                _distance.withUnsafeMutableBufferPointer { distance in
                                    _sigma.withUnsafeMutableBufferPointer { sigma in
                                        _delta.withUnsafeMutableBufferPointer { delta in
                                            _order.withUnsafeMutableBufferPointer { order in
                                                _scores.withUnsafeMutableBufferPointer { scores in
                                                    _accumulateEdgeBetweenness(
                                                        starts: starts, ends: ends, targets: targets, edges: edges, pivots: pivots,
                                                        distance: distance, sigma: sigma, delta: delta, order: order, scores: scores)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            for v in listed {
                for slot in _starts[v] ..< _ends[v] {
                    let candidate = _CentralEdge(score: _scores[_edges[slot]], edge: _edges[slot])
                    if best.map({ candidate < $0 }) ?? true { best = candidate }
                }
            }
            if let best { _central.insert(component, priority: best) }
        }

        @inlinable
        func _partition() -> Partition<DirectedView<G>> {
            Partition(_sequence._graph.directedView, numbers: _sequence._numbers, listed: _sequence._listed, labels: _component)
        }
    }
}

extension GirvanNewmanSequence: Sendable where G: Sendable, G.Vertex: Sendable {}
extension GirvanNewmanSequence.Iterator: Sendable where G: Sendable, G.Vertex: Sendable {}

extension Graph {
    /// Girvan–Newman communities: the successively finer partitions found by removing, again and
    /// again, the edge of greatest betweenness (`edgeBetweennessCentrality()`), recomputed after
    /// each removal. A tie goes to the least edge position; parallel copies share their pairs'
    /// paths, and self-loops are never removed and never matter. The sequence is lazy: each
    /// partition is computed when iteration reaches it.
    ///
    /// - Returns: the partitions, coarsest first: each time the number of components grows, the
    ///   components; ending with every vertex alone.
    /// - Complexity: O(m) to start. Each removal recomputes the betweenness of the removed edge's
    ///   component C alone, O(n_C · m_C); every split builds a partition in O(n). The whole
    ///   sequence is O(m² n) in the worst case.
    @inlinable
    public func girvanNewmanCommunities() -> GirvanNewmanSequence<Self> {
        GirvanNewmanSequence(self)
    }
}
