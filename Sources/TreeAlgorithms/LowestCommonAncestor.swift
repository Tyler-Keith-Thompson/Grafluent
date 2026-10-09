import Trees

/// The deepest common ancestor of two vertex numbers, a vertex counting as its own ancestor,
/// by climbing. O(depth).
@inlinable
func _climbingLowestCommonAncestor<Vertex>(_ layout: _TreeLayout<Vertex>, _ a: Int, _ b: Int) -> Int {
    var x = a, y = b
    let nodes = layout.nodes
    while nodes[x].depth > nodes[y].depth { x = nodes[x].parent }
    while nodes[y].depth > nodes[x].depth { y = nodes[y].parent }
    while x != y {
        x = nodes[x].parent
        y = nodes[y].parent
    }
    return x
}

extension RootedTree {
    /// The deepest vertex that is an ancestor of both `a` and `b`, a vertex counting as its own
    /// ancestor here (NetworkX `lowest_common_ancestor`): `a` when `a` is above `b`, and `v` for
    /// `(v, v)`. It depends on the root. O(depth(a) + depth(b)), allocating nothing; for many
    /// queries, `LowestCommonAncestors` answers each in O(1).
    ///
    /// - Precondition: Both are vertices of the tree.
    @inlinable
    public func lowestCommonAncestor(of a: Vertex, _ b: Vertex) -> Vertex {
        _layout.vertices[_climbingLowestCommonAncestor(_layout, _layout.number(of: a), _layout.number(of: b))]
    }
}

extension RootedTree {
    /// The deepest common ancestor of the vertices at indices `a` and `b`, as an index.
    /// O(depth(a) + depth(b)).
    ///
    /// - Precondition: Both are in `0..<vertexCount`.
    @inlinable
    public func lowestCommonAncestor(ofIndex a: Int, _ b: Int) -> Int {
        precondition(a >= 0 && a < vertexCount && b >= 0 && b < vertexCount, "Vertex index out of range")
        return _climbingLowestCommonAncestor(_layout, a, b)
    }
}

extension Arborescence {
    /// The deepest common ancestor of the vertices at indices `a` and `b`, as an index.
    /// O(depth(a) + depth(b)).
    ///
    /// - Precondition: Both are in `0..<vertexCount`.
    @inlinable
    public func lowestCommonAncestor(ofIndex a: Int, _ b: Int) -> Int {
        precondition(a >= 0 && a < vertexCount && b >= 0 && b < vertexCount, "Vertex index out of range")
        return _climbingLowestCommonAncestor(_layout, a, b)
    }
}

extension Arborescence {
    /// The deepest vertex that is an ancestor of both `a` and `b`, a vertex counting as its own
    /// ancestor (see `RootedTree.lowestCommonAncestor(of:_:)`). O(depth(a) + depth(b)).
    ///
    /// - Precondition: Both are vertices of the arborescence.
    @inlinable
    public func lowestCommonAncestor(of a: Vertex, _ b: Vertex) -> Vertex {
        _layout.vertices[_climbingLowestCommonAncestor(_layout, _layout.number(of: a), _layout.number(of: b))]
    }
}

/// Lowest common ancestors of a rooted tree or arborescence, each in O(1) after O(n) work
/// (NetworkX `lowest_common_ancestor`, JGraphT's `LowestCommonAncestorAlgorithm`).
///
/// For vertices at preorder positions p < q, the answer is the vertex at the least position among
/// the parents of the vertices at positions p + 1 … q: those parents lie in the answer's subtree
/// and include it, and it has the least position there. So a query is one range minimum over
/// n − 1 parent positions (the Euler tour reduction on half the entries), answered by 64-entry
/// blocks with a bitmask of each prefix's minimum stack and a sparse table over the blocks' minima.
/// About two words per vertex, plus (n/64)·log₂(n/64) for the table.
@frozen
public struct LowestCommonAncestors<Vertex: Hashable> {
    @usableFromInline let _layout: _TreeLayout<Vertex>
    /// Each vertex's preorder position and depth, dense, so a query reads 4-byte entries rather
    /// than two 56-byte node records.
    @usableFromInline let _position: [Int32]
    @usableFromInline let _depth: [Int32]
    /// `_minima[i]`: the preorder position of the parent of the vertex at position i (i ≥ 1).
    @usableFromInline let _minima: [Int32]
    /// For each position, the in-block positions of its prefix's minimum stack.
    @usableFromInline let _masks: [UInt64]
    /// The sparse table over the blocks' minima, level by level.
    @usableFromInline let _table: [Int32]
    @usableFromInline let _blockCount: Int

    /// Precomputes the queries of a rooted tree. O(n).
    @inlinable
    public init(_ tree: RootedTree<Vertex>) {
        self.init(_layout: tree._layout)
    }

    /// Precomputes the queries of an arborescence. O(n).
    @inlinable
    public init(_ arborescence: Arborescence<Vertex>) {
        self.init(_layout: arborescence._layout)
    }

    @inlinable
    init(_layout layout: _TreeLayout<Vertex>) {
        _layout = layout
        let n = layout.count
        precondition(n < Int(Int32.max), "Too many vertices for 32-bit positions")
        var position = [Int32](repeating: 0, count: n), depth = [Int32](repeating: 0, count: n)
        for v in 0 ..< n {
            position[v] = Int32(truncatingIfNeeded: layout.nodes[v].preorderPosition)
            depth[v] = Int32(truncatingIfNeeded: layout.nodes[v].depth)
        }
        var minima = [Int32](repeating: Int32.max, count: n)
        for i in 1 ..< max(n, 1) { minima[i] = position[layout.nodes[layout.preorder[i]].parent] }
        var masks = [UInt64](repeating: 0, count: n)
        let blocks = (n + 63) / 64
        var blockMinima = [Int32](repeating: Int32.max, count: blocks)
        for b in 0 ..< blocks {
            let start = b * 64
            var stack: UInt64 = 0
            var least = Int32.max
            for i in start ..< min(start + 64, n) {
                let value = minima[i]
                // Pop the stack's top while it is not less than this entry.
                while stack != 0 {
                    let top = 63 - stack.leadingZeroBitCount
                    guard minima[start + top] >= value else { break }
                    stack &= ~(UInt64(1) << UInt64(top))
                }
                stack |= UInt64(1) << UInt64(i - start)
                masks[i] = stack
                if value < least { least = value }
            }
            blockMinima[b] = least
        }
        // Sparse table: level k holds the minimum of blocks i ..< i + 2^k.
        var table = blockMinima
        var width = 1
        while 2 * width <= blocks {
            let previous = table.count - blocks
            for i in 0 ..< blocks {
                let j = i + width
                table.append(j < blocks ? min(table[previous + i], table[previous + j]) : table[previous + i])
            }
            width *= 2
        }
        _position = position
        _depth = depth
        _minima = minima
        _masks = masks
        _table = table
        _blockCount = blocks
    }

    /// The least entry of `_minima[l ... r]` inside one block.
    @inlinable @inline(__always)
    func _inBlock(_ l: Int, _ r: Int) -> Int32 {
        let start = l & ~63
        let mask = _masks[r] >> UInt64(l - start)
        return _minima[l + mask.trailingZeroBitCount]
    }

    /// The least entry of `_minima[l ... r]`.
    @inlinable
    func _rangeMinimum(_ l: Int, _ r: Int) -> Int32 {
        let bl = l >> 6, br = r >> 6
        if bl == br { return _inBlock(l, r) }
        var least = min(_inBlock(l, (bl << 6) + 63), _inBlock(br << 6, r))
        if bl + 1 <= br - 1 {
            let lo = bl + 1, hi = br - 1
            let k = Int.bitWidth - 1 - (hi - lo + 1).leadingZeroBitCount
            let level = k * _blockCount
            least = min(least, min(_table[level + lo], _table[level + hi - (1 << k) + 1]))
        }
        return least
    }

    /// The deepest common ancestor of the vertices at indices `a` and `b`, as an index. O(1).
    ///
    /// - Precondition: Both are in `0..<vertexCount`.
    @inlinable
    public func lowestCommonAncestor(ofIndex a: Int, _ b: Int) -> Int {
        precondition(a >= 0 && a < _layout.count && b >= 0 && b < _layout.count, "Vertex index out of range")
        if a == b { return a }
        var p = Int(_position[a]), q = Int(_position[b])
        if p > q { swap(&p, &q) }
        return _layout.preorder[Int(_rangeMinimum(p + 1, q))]
    }

    /// The deepest vertex that is an ancestor of both, a vertex counting as its own ancestor.
    /// O(1).
    ///
    /// - Precondition: Both are vertices of the tree.
    @inlinable
    public func lowestCommonAncestor(of a: Vertex, _ b: Vertex) -> Vertex {
        _layout.vertices[lowestCommonAncestor(ofIndex: _layout.number(of: a), _layout.number(of: b))]
    }

    /// The number of edges between the vertices at indices `a` and `b`. O(1).
    ///
    /// - Precondition: Both are in `0..<vertexCount`.
    @inlinable
    public func distance(fromIndex a: Int, toIndex b: Int) -> Int {
        let c = lowestCommonAncestor(ofIndex: a, b)
        return Int(_depth[a]) + Int(_depth[b]) - 2 * Int(_depth[c])
    }

    /// The number of edges between `a` and `b`; it does not depend on the root. O(1).
    ///
    /// - Precondition: Both are vertices of the tree.
    @inlinable
    public func distance(from a: Vertex, to b: Vertex) -> Int {
        distance(fromIndex: _layout.number(of: a), toIndex: _layout.number(of: b))
    }
}

extension LowestCommonAncestors: Sendable where Vertex: Sendable {}
