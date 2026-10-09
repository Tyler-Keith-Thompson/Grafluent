extension Tree {
    /// The tree's Prüfer sequence (NetworkX `to_prufer_sequence`, igraph `to_prufer`): remove the
    /// leaf with the least vertex index and record its neighbor, until two vertices remain. Nil
    /// for a single vertex. For `Int` vertices `0..<n` in order, this is NetworkX's and igraph's
    /// code; otherwise it is the code of the tree relabeled by vertex index. O(n).
    @inlinable
    public var pruferSequence: [Vertex]? {
        let layout = _layout
        let n = layout.count
        guard n >= 2 else { return nil }
        // Each vertex's degree and the XOR of its neighbors: when all but one neighbor are gone,
        // the XOR is the one left, so a removed leaf's neighbor needs no rooting.
        var degree = [Int](repeating: 0, count: n)
        var xor = [Int](repeating: 0, count: n)
        for v in 0 ..< n {
            degree[v] = layout.rowOffsets[v + 1] - layout.rowOffsets[v]
            for k in layout.rowOffsets[v] ..< layout.rowOffsets[v + 1] { xor[v] ^= layout.rowNeighbors[k] }
        }
        var code: [Vertex] = []
        code.reserveCapacity(n - 2)
        var pointer = 0
        while degree[pointer] != 1 { pointer += 1 }
        var leaf = pointer
        for _ in 0 ..< n - 2 {
            let next = xor[leaf]
            code.append(layout.vertices[next])
            degree[leaf] = 0
            xor[next] ^= leaf
            degree[next] -= 1
            if degree[next] == 1, next < pointer {
                leaf = next
            } else {
                pointer += 1
                while degree[pointer] != 1 { pointer += 1 }
                leaf = pointer
            }
        }
        return code
    }
}

extension Tree where Vertex == Int {
    /// The tree on `0..<code.count + 2` with this Prüfer sequence (NetworkX
    /// `from_prufer_sequence`, igraph `from_prufer`): edge k joins the k-th leaf removed to the
    /// k-th element, and the last joins the two vertices left. Nil when an element is outside
    /// `0..<code.count + 2`. O(n).
    @inlinable
    public init?(pruferSequence: some Sequence<Int>) {
        let code = Array(pruferSequence)
        let n = code.count + 2
        var degree = [Int](repeating: 1, count: n)
        for x in code {
            guard x >= 0, x < n else { return nil }
            degree[x] += 1
        }
        var ends: [Int] = []
        ends.reserveCapacity(2 * (n - 1))
        var pointer = 0
        while degree[pointer] != 1 { pointer += 1 }
        var leaf = pointer
        for v in code {
            ends.append(leaf)
            ends.append(v)
            degree[leaf] -= 1
            degree[v] -= 1
            if degree[v] == 1, v < pointer {
                leaf = v
            } else {
                pointer += 1
                while degree[pointer] != 1 { pointer += 1 }
                leaf = pointer
            }
        }
        // The two left: the current leaf and the last vertex.
        ends.append(leaf)
        ends.append(n - 1)
        guard let layout = _TreeLayout(vertices: ContiguousArray(0 ..< n), slots: [:], dense: true, ends: ends, root: 0) else { return nil }
        _layout = layout
    }
}
