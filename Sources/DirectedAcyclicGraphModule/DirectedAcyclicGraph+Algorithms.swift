import GraphProtocols
import Walks

extension DirectedAcyclicGraph {
    /// Whether a path leads from `source` to `target`. True when they are the same vertex.
    ///
    /// Returns false in O(1) when `source` is placed after `target`, since every path goes forward
    /// in the order. Otherwise a depth-first search visits only the vertices placed between the
    /// two. Gives the same answer as Traversal's `hasPath(from:to:)`.
    ///
    /// - Precondition: both are vertices.
    @inlinable
    public func hasPath(from source: Vertex, to target: Vertex) -> Bool {
        guard let start = _base._key(of: source) else { preconditionFailure("The source \(source) is not a vertex of the graph") }
        guard let goal = _base._key(of: target) else { preconditionFailure("The target \(target) is not a vertex of the graph") }
        if start == goal { return true }
        let lower = _table.label(start), upper = _table.label(goal)
        if lower > upper { return false }
        // One bit per label between the two: labels are slots, which compaction keeps O(n).
        var seen = [UInt64](repeating: 0, count: (upper &- lower) &>> 6 &+ 1)
        var stack = [start]
        while let key = stack.popLast() {
            for next in _base._successorKeys(ofKey: key) {
                if next == goal { return true }
                let label = _table.label(next)
                if label < upper {
                    let bit = label &- lower
                    let word = bit &>> 6, mask = UInt64(1) &<< UInt64(bit & 63)
                    if seen[word] & mask == 0 {
                        seen[word] |= mask
                        stack.append(next)
                    }
                }
            }
        }
        return false
    }

    /// The reachability of every vertex, as bit rows over places: row `p`, `words` words long,
    /// holds the places of the vertices reachable by at least one edge from the vertex at place
    /// `p`. Computed in reverse order, each row the union of its successors' rows and bits.
    /// O(n · m / 64) time and n² / 8 bytes.
    @inlinable
    internal func _reachability(_ places: _Places) -> (rows: [UInt64], words: Int) {
        let n = _order.count
        let words = (n &+ 63) &>> 6
        var rows = [UInt64](repeating: 0, count: n &* words)
        rows.withUnsafeMutableBufferPointer { rows in
            var p = n &- 1
            while p >= 0 {
                let row = p &* words
                for next in _base._successorKeys(ofKey: places.key(atPlace: p)) {
                    let q = places.place(ofKey: next)
                    rows[row &+ q &>> 6] |= UInt64(1) &<< UInt64(q & 63)
                    // Successors are placed later, so a row only ever reads rows after it.
                    let other = q &* words
                    var w = q &>> 6
                    while w < words {
                        rows[row &+ w] |= rows[other &+ w]
                        w &+= 1
                    }
                }
                p &-= 1
            }
        }
        return (rows, words)
    }

    /// The transitive closure, not reflexive.
    ///
    /// A copy of the graph in which, for each vertex u in topological order, an edge u→w is
    /// appended for each vertex w reachable from u that is not already a successor, in topological
    /// order of w. Existing edges, parallel copies included, keep their positions, and the
    /// topological order is unchanged.
    ///
    /// - Complexity: O(n · m / 64 + n + output) time and n² / 8 bytes of scratch.
    @inlinable
    public func transitiveClosure() -> Self {
        let places = _places()
        let (rows, words) = _reachability(places)
        var closure = self
        let n = _order.count
        var have = [UInt64](repeating: 0, count: words)
        for p in 0 ..< n {
            let key = places.key(atPlace: p)
            for next in _base._successorKeys(ofKey: key) {
                let q = places.place(ofKey: next)
                have[q &>> 6] |= UInt64(1) &<< UInt64(q & 63)
            }
            let row = p &* words
            for w in 0 ..< words {
                var missing = rows[row &+ w] & ~have[w]
                while missing != 0 {
                    let q = w &<< 6 | missing.trailingZeroBitCount
                    _ = closure._base._insertEdge(fromKey: key, toKey: places.key(atPlace: q))
                    missing &= missing &- 1
                }
                have[w] = 0
            }
        }
        return closure
    }

    /// The transitive reduction.
    ///
    /// The edge u→w is kept exactly when no path of two or more edges leads from u to w, and of
    /// parallel copies only the first in `edges` order is kept. The result is a new graph with the
    /// vertices in `vertices` order, the kept edges in `edges` order at fresh positions (a
    /// `StableDirectedGraph` is compacted), and the same topological order.
    ///
    /// - Complexity: O(n · m / 64 + n + m) time and n² / 8 bytes of scratch.
    @inlinable
    public func transitiveReduction() -> Self {
        let places = _places()
        let reachability = _reachability(places)
        var rows = reachability.rows
        let words = reachability.words
        let n = _order.count
        // Row p becomes the vertices reachable through a successor in two or more edges: the union
        // of its successors' rows. Rows are rewritten in increasing order, and a successor's row
        // comes later, so it is still the reachability row when read.
        var far = [UInt64](repeating: 0, count: words)
        rows.withUnsafeMutableBufferPointer { rows in
            for p in 0 ..< n {
                for next in _base._successorKeys(ofKey: places.key(atPlace: p)) {
                    let other = places.place(ofKey: next) &* words
                    for w in 0 ..< words { far[w] |= rows[other &+ w] }
                }
                let row = p &* words
                for w in 0 ..< words {
                    rows[row &+ w] = far[w]
                    far[w] = 0
                }
            }
        }
        var reduced = Base()
        reduced.reserveCapacity(vertexCount: n, edgeCount: 0)
        var keys = _KeyTable()
        for key in _base.vertices.indices {
            // A map from old keys to new ones.
            keys.insert(key, label: reduced._insertVertex(_base._vertex(atKey: key)))
        }
        for position in _base.edges.indices {
            let s = places.place(ofKey: _base._sourceKey(ofEdgeAt: position))
            let target = _base._targetKey(ofEdgeAt: position)
            let t = places.place(ofKey: target)
            let at = s &* words &+ t &>> 6, mask = UInt64(1) &<< UInt64(t & 63)
            // Marking the kept edge's bit drops its later copies.
            if rows[at] & mask != 0 { continue }
            rows[at] |= mask
            _ = reduced._insertEdge(fromKey: keys.label(places.key(atPlace: s)), toKey: keys.label(target))
        }
        var order = ContiguousArray<Int>()
        order.reserveCapacity(n)
        var table = _KeyTable()
        for key in reduced.vertices.indices { table.insert(key, label: 0) }
        for place in 0 ..< n {
            let new = keys.label(places.key(atPlace: place))
            order.append(new)
            table.setLabel(new, place)
        }
        return Self(_base: reduced, order: order, table: table)
    }

    /// A longest path by edge count.
    ///
    /// Walking the topological order, each vertex's best predecessor edge is the first in
    /// `inEdges` order that achieves its maximum. The path ends at the first vertex in the order
    /// with the greatest distance. An edgeless graph gives its first vertex in the order.
    ///
    /// - Returns: The path, or `nil` for the empty graph.
    /// - Complexity: O(n + m).
    @inlinable
    public func longestPath() -> Path<Vertex, Edges.Index>? {
        _longestPath { _ in 1 }
    }

    /// A path of greatest total weight, with weights read by edge position.
    ///
    /// Walking the topological order, each vertex takes the predecessor edge, first in `inEdges`
    /// order among equals, that maximizes its distance plus the edge's weight. A vertex starts
    /// afresh at distance zero when that maximum is negative or it has no in-edge. The path ends at
    /// the first vertex in the order with the greatest distance, and its weight is that distance.
    /// With negative weights the path may be a single vertex. A zero-weight edge extends a path.
    ///
    /// - Returns: The path, or `nil` for the empty graph.
    /// - Precondition: No distance is NaN, and every sum fits in `W`.
    /// - Complexity: O(n + m).
    @inlinable
    public func longestPath<W: Comparable & AdditiveArithmetic>(weight: (Edges.Index) -> W) -> Path<Vertex, Edges.Index>? {
        _longestPath(weight)
    }

    @inlinable
    internal func _longestPath<W: Comparable & AdditiveArithmetic>(_ weight: (Edges.Index) -> W) -> Path<Vertex, Edges.Index>? {
        let n = _order.count
        guard n > 0 else { return nil }
        var distance = [W](repeating: .zero, count: n)
        var parent = [Int](repeating: -1, count: n)
        var parentEdge = [Edges.Index?](repeating: nil, count: n)
        let places = _places()
        var best = 0
        for p in 0 ..< n {
            let key = places.key(atPlace: p)
            var d = W.zero
            var from = -1
            var through: Edges.Index?
            for (previous, edge) in zip(_base._predecessorKeys(ofKey: key), _base._inEdges(ofKey: key)) {
                let q = places.place(ofKey: previous)
                let candidate = distance[q] + weight(edge)
                precondition(candidate == candidate, "A path's weight is NaN")
                if from < 0 || candidate > d {
                    d = candidate
                    from = q
                    through = edge
                }
            }
            if from >= 0, d >= .zero {
                distance[p] = d
                parent[p] = from
                parentEdge[p] = through
            }
            if distance[p] > distance[best] { best = p }
        }
        var vertices: [Vertex] = []
        var edges: [Edges.Index] = []
        var p = best
        while true {
            vertices.append(_base._vertex(atKey: places.key(atPlace: p)))
            guard let edge = parentEdge[p] else { break }
            edges.append(edge)
            p = parent[p]
        }
        vertices.reverse()
        edges.reverse()
        // Every step is an edge, and the order is strict along it, so no vertex repeats.
        return Path(_uncheckedVertices: vertices, edges: edges)
    }
}
