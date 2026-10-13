extension Tree {
    /// The tree's Prüfer sequence: remove the least-ranked leaf and record its neighbor, until two
    /// vertices remain.
    ///
    /// When `Vertex` is `Int` and the vertices are exactly `0..<n`, in any order, a vertex's rank
    /// is its value: this is the standard Prüfer code, and `Tree(pruferSequence:)` decodes it back
    /// to an equal tree. Otherwise a vertex's rank is its index (its place in `vertices`), and the
    /// sequence is the code of the tree relabeled by index, written with the vertices themselves.
    ///
    /// - Returns: `n − 2` vertices, or `nil` for a single vertex.
    /// - Complexity: O(n).
    @inlinable
    public var pruferSequence: [Vertex]? {
        let layout = _layout
        let n = layout.count
        guard n >= 2 else { return nil }
        // Each vertex's degree and the XOR of its neighbors, by rank: when all but one neighbor
        // are gone, the XOR is the one left, so a removed leaf's neighbor needs no rooting.
        var degree = [Int](repeating: 0, count: n)
        var xor = [Int](repeating: 0, count: n)
        let names: ContiguousArray<Vertex>
        if !layout.dense, let values = Self._rangeValues(layout.vertices) {
            for v in 0 ..< n {
                let x = values[v]
                degree[x] = layout.rowOffsets[v + 1] - layout.rowOffsets[v]
                for k in layout.rowOffsets[v] ..< layout.rowOffsets[v + 1] { xor[x] ^= values[layout.rowNeighbors[k]] }
            }
            // Rank x is the vertex x.
            names = unsafeBitCast(ContiguousArray(0 ..< n), to: ContiguousArray<Vertex>.self)
        } else {
            for v in 0 ..< n {
                degree[v] = layout.rowOffsets[v + 1] - layout.rowOffsets[v]
                for k in layout.rowOffsets[v] ..< layout.rowOffsets[v + 1] { xor[v] ^= layout.rowNeighbors[k] }
            }
            names = layout.vertices
        }
        var code: [Vertex] = []
        code.reserveCapacity(n - 2)
        var pointer = 0
        while degree[pointer] != 1 { pointer += 1 }
        var leaf = pointer
        for _ in 0 ..< n - 2 {
            let next = xor[leaf]
            code.append(names[next])
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

    /// The vertices as `Int`s when `Vertex` is `Int` and every vertex is in `0..<count`: since the
    /// vertices are distinct, they are then exactly `0..<count`. Nil otherwise. O(n).
    @inlinable
    static func _rangeValues(_ vertices: ContiguousArray<Vertex>) -> ContiguousArray<Int>? {
        guard Vertex.self == Int.self else { return nil }
        let values = unsafeBitCast(vertices, to: ContiguousArray<Int>.self)
        let count = UInt(bitPattern: values.count)
        for x in values where UInt(bitPattern: x) >= count { return nil }
        return values
    }
}

extension Tree where Vertex == Int {
    /// The tree on `0..<code.count + 2` with this Prüfer sequence: edge k joins the k-th leaf
    /// removed to the k-th element, and the last joins the two vertices left. It inverts
    /// `pruferSequence` for any tree whose vertices are the `Int`s `0..<n`: decoding that tree's
    /// sequence gives an equal tree, with its vertices in order.
    ///
    /// - Returns: `nil` when an element is outside `0..<code.count + 2`.
    /// - Complexity: O(n).
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
        self.init(_layout: layout)
    }
}
