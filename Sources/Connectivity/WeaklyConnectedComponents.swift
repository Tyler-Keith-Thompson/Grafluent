import GraphProtocols

extension DirectedGraph {
    /// Union–find over the edges, over one array: a root holds minus its set's size, any other
    /// vertex its parent. Union by size, path halving. Calls `body` with the buffer once the edges
    /// are joined, or once `limit` joins have succeeded.
    @inlinable
    @inline(__always)
    func _joinEndpoints<Result>(
        _ vertices: _DenseVertices<Self>,
        limit: Int = .max,
        _ body: (UnsafeMutableBufferPointer<Int>, _ joins: Int) -> Result
    ) -> Result {
        let n = vertices.count
        var parent = [Int](repeating: -1, count: n)
        return parent.withUnsafeMutableBufferPointer { parent in
            var joins = 0
            @inline(__always)
            func union(_ a: Int, _ b: Int) {
                var a = _find(parent, a)
                var b = _find(parent, b)
                if a == b { return }
                if parent[a] > parent[b] { swap(&a, &b) }
                parent[a] += parent[b]
                parent[b] = a
                joins += 1
            }
            if vertices.isIndexed {
                let joined: Void? = _withSuccessorIndexRows { offsets, targets in
                    var u = 0
                    while u < n, joins < limit {
                        for k in offsets[u] ..< offsets[u + 1] { union(u, targets[k]) }
                        u += 1
                    }
                }
                if joined == nil {
                    var u = 0
                    while u < n, joins < limit {
                        for w in successorIndices(ofIndex: u) { union(u, w) }
                        u += 1
                    }
                }
            } else {
                var u = 0
                while u < n, joins < limit {
                    for w in successors(of: vertices.vertices[u]) { union(u, vertices.numbers[w]!) }
                    u += 1
                }
            }
            return body(parent, joins)
        }
    }

    /// The weakly connected components: the components of the graph with edge directions
    /// ignored. By union–find over the edges, so predecessors are not needed. O(E α(V)).
    ///
    /// Components are in the order of their first vertex in `vertices`, and each lists its
    /// vertices in `vertices` order (the order of NetworkX's `weakly_connected_components`).
    @inlinable
    public func weaklyConnectedComponents() -> Components<Self> {
        let vertices = _DenseVertices(self)
        let n = vertices.count
        var labels = [Int](repeating: -1, count: n)
        let count = _joinEndpoints(vertices) { parent, _ in
            labels.withUnsafeMutableBufferPointer { labels in
                // Number the sets by their first member: a root's label is set when its set is
                // first met, which may be before the root itself.
                var count = 0
                for v in 0 ..< n {
                    let r = _find(parent, v)
                    if labels[r] < 0 {
                        labels[r] = count
                        count += 1
                    }
                    labels[v] = labels[r]
                }
                return count
            }
        }
        return Components(vertices: vertices, labels: labels, count: count)
    }

    /// Whether the graph is connected when edge directions are ignored. False for the empty
    /// graph, so this is `weaklyConnectedComponents().count == 1`. O(V + E), stopping once the
    /// edges seen join every vertex.
    @inlinable
    public var isWeaklyConnected: Bool {
        let vertices = _DenseVertices(self)
        let n = vertices.count
        guard n > 0 else { return false }
        return _joinEndpoints(vertices, limit: n - 1) { _, joins in joins == n - 1 }
    }
}

/// The root of `x`'s set, halving the path on the way.
@inlinable
@inline(__always)
package func _find(_ parent: UnsafeMutableBufferPointer<Int>, _ x: Int) -> Int {
    var x = x
    while parent[x] >= 0 {
        let p = parent[x]
        let g = parent[p]
        if g < 0 { return p }
        parent[x] = g
        x = g
    }
    return x
}
