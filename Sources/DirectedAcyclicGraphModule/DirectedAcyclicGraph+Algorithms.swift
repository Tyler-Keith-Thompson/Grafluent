import GraphProtocols
import Walks

extension DirectedAcyclicGraph {
    /// Whether a path leads from `source` to `target`; true when they are the same vertex
    /// (NetworkX's `has_path`). False in O(1) when `source` is placed after `target`, since every
    /// path goes forward in the order; otherwise a depth-first search visits only the vertices
    /// placed between the two, the pruning Pearce–Kelly's forward search uses. This shadows
    /// Traversal's `hasPath(from:to:)`, with the same answer.
    ///
    /// - Precondition: both are vertices.
    @inlinable
    public func hasPath(from source: Vertex, to target: Vertex) -> Bool {
        guard let start = _base._key(of: source) else { preconditionFailure("The source \(source) is not a vertex of the graph") }
        guard let goal = _base._key(of: target) else { preconditionFailure("The target \(target) is not a vertex of the graph") }
        if start == goal { return true }
        let lower = _table.label(start), upper = _table.label(goal)
        if lower > upper { return false }
        // One bit per label between the two; labels span at most 2n + 1024.
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
    internal func _reachability(_ places: _KeyTable) -> (rows: [UInt64], words: Int) {
        let n = _order.count
        let words = (n &+ 63) &>> 6
        var rows = [UInt64](repeating: 0, count: n &* words)
        rows.withUnsafeMutableBufferPointer { rows in
            var p = n &- 1
            while p >= 0 {
                let row = p &* words
                for next in _base._successorKeys(ofKey: _order[p]) {
                    let q = places.label(next)
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

    /// The transitive closure (NetworkX's `transitive_closure_dag`, not reflexive): a copy of the
    /// graph in which, for each vertex u in topological order, an edge u→w is appended for each
    /// vertex w reachable from u that is not already a successor, in topological order of w.
    /// Existing edges, copies included, keep their positions, and the order is the same.
    /// O(n · m / 64 + n + output) time and n² / 8 bytes of scratch.
    @inlinable
    public func transitiveClosure() -> Self {
        let places = _placeTable()
        let (rows, words) = _reachability(places)
        var closure = self
        let n = _order.count
        var have = [UInt64](repeating: 0, count: words)
        for p in 0 ..< n {
            let key = _order[p]
            for next in _base._successorKeys(ofKey: key) {
                let q = places.label(next)
                have[q &>> 6] |= UInt64(1) &<< UInt64(q & 63)
            }
            let row = p &* words
            for w in 0 ..< words {
                var missing = rows[row &+ w] & ~have[w]
                while missing != 0 {
                    let q = w &<< 6 | missing.trailingZeroBitCount
                    _ = closure._base._insertEdge(fromKey: key, toKey: _order[q])
                    missing &= missing &- 1
                }
                have[w] = 0
            }
        }
        return closure
    }

    /// The transitive reduction (NetworkX's `transitive_reduction`): the edge u→w is kept exactly
    /// when no path of two or more edges leads from u to w, and of parallel copies only the first
    /// in `edges` order. A new graph: the vertices in `vertices` order, the kept edges in `edges`
    /// order at fresh positions (a `StableDirectedGraph` is compacted), and the same topological
    /// order. O(n · m / 64 + n + m) time and n² / 8 bytes of scratch.
    @inlinable
    public func transitiveReduction() -> Self {
        let places = _placeTable()
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
                for next in _base._successorKeys(ofKey: _order[p]) {
                    let other = places.label(next) &* words
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
            let s = places.label(_base._sourceKey(ofEdgeAt: position))
            let target = _base._targetKey(ofEdgeAt: position)
            let t = places.label(target)
            let at = s &* words &+ t &>> 6, mask = UInt64(1) &<< UInt64(t & 63)
            // Marking the kept edge's bit drops its later copies.
            if rows[at] & mask != 0 { continue }
            rows[at] |= mask
            _ = reduced._insertEdge(fromKey: keys.label(_order[s]), toKey: keys.label(target))
        }
        var order = ContiguousArray<Int>()
        order.reserveCapacity(n)
        var table = _KeyTable()
        for (place, key) in _order.enumerated() {
            let new = keys.label(key)
            order.append(new)
            table.insert(new, label: place)
        }
        return Self(_base: reduced, order: order, table: table)
    }

    /// A longest path, by edge count (NetworkX's `dag_longest_path` with unit weights, given this
    /// order as `topo_order`). Walking the order, each vertex's best predecessor edge is the first
    /// in `inEdges` order that achieves its maximum; the path ends at the first vertex in the
    /// order with the greatest distance. `nil` only for the empty graph; an edgeless graph gives
    /// its first vertex in the order. O(n + m).
    @inlinable
    public func longestPath() -> Path<Vertex, Edges.Index>? {
        let n = _order.count
        guard n > 0 else { return nil }
        var distance = [Int](repeating: 0, count: n)
        var parent = [Int](repeating: -1, count: n)
        var parentEdge = [Edges.Index?](repeating: nil, count: n)
        let places = _placeTable()
        var best = 0
        for p in 0 ..< n {
            let key = _order[p]
            var d = 0
            for (previous, edge) in zip(_base._predecessorKeys(ofKey: key), _base._inEdges(ofKey: key)) {
                let q = places.label(previous)
                if distance[q] &+ 1 > d {
                    d = distance[q] &+ 1
                    parent[p] = q
                    parentEdge[p] = edge
                }
            }
            distance[p] = d
            if d > distance[best] { best = p }
        }
        var vertices: [Vertex] = []
        var edges: [Edges.Index] = []
        vertices.reserveCapacity(distance[best] &+ 1)
        edges.reserveCapacity(distance[best])
        var p = best
        while true {
            vertices.append(_base._vertex(atKey: _order[p]))
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
