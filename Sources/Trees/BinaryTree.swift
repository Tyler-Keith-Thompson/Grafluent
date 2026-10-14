import GraphProtocols

/// A binary tree: a rooted tree in which each vertex has at most a left child and a right child,
/// by position. A vertex with only a left child is a different tree from one with only a right
/// child. Two binary trees are equal when they have the same root and every vertex has the same
/// left and right children.
///
/// It is not itself a graph. `OrderedTree(_:)` (left child first) and `Arborescence(_:)` convert
/// in O(1), forgetting which side a lone child is on.
@frozen
public struct BinaryTree<Vertex: Hashable> {
    @usableFromInline package var _layout: _TreeLayout<Vertex>
    /// Per vertex number: bit 0 when it has a left child, bit 1 when it has a right child. Its
    /// children are its row less its parent edge, the left child first.
    @usableFromInline package var _sides: [UInt8]

    @inlinable
    package init(_layout: _TreeLayout<Vertex>, sides: [UInt8]) {
        self._layout = _layout
        _sides = sides
    }

    /// The binary tree from `root` down, in which the children of a vertex are
    /// `children(vertex)`. `children` is called once for each vertex, level by level; nil when a
    /// vertex is listed twice, as a child of two vertices, as both children of one, or as a child
    /// of its own descendant (the root included). O(n).
    @inlinable
    public init?<E: Error>(root: Vertex, children: (Vertex) throws(E) -> (left: Vertex?, right: Vertex?)) throws(E) {
        var vertices: ContiguousArray<Vertex> = [root]
        var slots: [Vertex: Int] = [root: 0]
        var ends: [Int] = []
        var sides: [UInt8] = []
        var next = 0
        while next < vertices.count {
            let (left, right) = try children(vertices[next])
            var side: UInt8 = 0
            if let left {
                guard slots.updateValue(vertices.count, forKey: left) == nil else { return nil }
                ends.append(next)
                ends.append(vertices.count)
                vertices.append(left)
                side = 1
            }
            if let right {
                guard slots.updateValue(vertices.count, forKey: right) == nil else { return nil }
                ends.append(next)
                ends.append(vertices.count)
                vertices.append(right)
                side |= 2
            }
            sides.append(side)
            next += 1
        }
        let (layout, numbers) = _TreeLayout.levelOrder(vertices, slots, ends)
        if let numbers {
            var renumbered = [UInt8](repeating: 0, count: sides.count)
            for (i, side) in sides.enumerated() { renumbered[numbers[i]] = side }
            sides = renumbered
        }
        self.init(_layout: layout, sides: sides)
    }

    /// The root.
    @inlinable
    public var root: Vertex { _layout.vertices[_layout.roots[0]] }

    /// The number of vertices: at least 1.
    @inlinable
    public var vertexCount: Int { _layout.count }

    /// Whether `vertex` is a vertex of the tree.
    @inlinable
    public func contains(_ vertex: Vertex) -> Bool { _layout.contains(vertex) }

    /// The `j`-th child (0 or 1) of the vertex numbered `v`, by number.
    @inlinable @inline(__always)
    func _child(_ v: Int, _ j: Int) -> Int {
        let hole = _layout.nodes[v].parentOffset
        return _layout.rowNeighbors[_layout.rowOffsets[v] + (hole >= 0 && hole <= j ? j + 1 : j)]
    }

    /// The number of the left child of the vertex numbered `v`, or −1.
    @inlinable @inline(__always)
    func _left(_ v: Int) -> Int { _sides[v] & 1 != 0 ? _child(v, 0) : -1 }

    /// The number of the right child of the vertex numbered `v`, or −1.
    @inlinable @inline(__always)
    func _right(_ v: Int) -> Int { _sides[v] & 2 != 0 ? _child(v, Int(_sides[v] & 1)) : -1 }

    /// The left child of `vertex`, or nil. O(1).
    ///
    /// - Precondition: `vertex` is a vertex of the tree.
    @inlinable
    public func left(of vertex: Vertex) -> Vertex? {
        let c = _left(_layout.number(of: vertex))
        return c < 0 ? nil : _layout.vertices[c]
    }

    /// The right child of `vertex`, or nil. O(1).
    ///
    /// - Precondition: `vertex` is a vertex of the tree.
    @inlinable
    public func right(of vertex: Vertex) -> Vertex? {
        let c = _right(_layout.number(of: vertex))
        return c < 0 ? nil : _layout.vertices[c]
    }

    /// The parent of `vertex`, or nil at the root. O(1).
    ///
    /// - Precondition: `vertex` is a vertex of the tree.
    @inlinable
    public func parent(of vertex: Vertex) -> Vertex? {
        let p = _layout.nodes[_layout.number(of: vertex)].parent
        return p < 0 ? nil : _layout.vertices[p]
    }

    /// The number of edges between `vertex` and the root. O(1).
    ///
    /// - Precondition: `vertex` is a vertex of the tree.
    @inlinable
    public func depth(of vertex: Vertex) -> Int { _layout.nodes[_layout.number(of: vertex)].depth }

    /// The greatest depth: 0 for a single vertex.
    @inlinable
    public var height: Int { _layout.height }

    /// The vertices in preorder: the root, then its left subtree, then its right subtree. O(1).
    @inlinable
    public var preorder: RootedTree<Vertex>.Preorder { RootedTree.Preorder(_layout, _layout.preorder.indices) }

    /// The vertices in inorder (symmetric order): the left subtree, then the root, then the
    /// right subtree. O(n).
    @inlinable
    public var inorder: [Vertex] {
        let n = _layout.count
        var result: [Vertex] = []
        result.reserveCapacity(n)
        var stack: [Int] = []
        var v = _layout.roots[0]
        while true {
            while v >= 0 {
                stack.append(v)
                v = _left(v)
            }
            guard let top = stack.popLast() else { break }
            result.append(_layout.vertices[top])
            v = _right(top)
        }
        return result
    }

    /// The vertices in postorder: the left subtree, then the right subtree, then the root. O(n).
    @inlinable
    public var postorder: [Vertex] { _layout.postorder() }

    /// `left(of: vertex)`, throwing instead of trapping when `vertex` is not a vertex. O(1).
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not a vertex.
    @inlinable
    public func left(checked vertex: Vertex) throws(VertexNotFound) -> Vertex? {
        let c = _left(try _layout.checkedNumber(of: vertex))
        return c < 0 ? nil : _layout.vertices[c]
    }

    /// `right(of: vertex)`, throwing instead of trapping when `vertex` is not a vertex. O(1).
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not a vertex.
    @inlinable
    public func right(checked vertex: Vertex) throws(VertexNotFound) -> Vertex? {
        let c = _right(try _layout.checkedNumber(of: vertex))
        return c < 0 ? nil : _layout.vertices[c]
    }

    /// `parent(of: vertex)`, throwing instead of trapping when `vertex` is not a vertex: nil still
    /// means `vertex` is the root. O(1).
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not a vertex.
    @inlinable
    public func parent(checked vertex: Vertex) throws(VertexNotFound) -> Vertex? {
        let p = _layout.nodes[try _layout.checkedNumber(of: vertex)].parent
        return p < 0 ? nil : _layout.vertices[p]
    }

    /// `depth(of: vertex)`, throwing instead of trapping when `vertex` is not a vertex. O(1).
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not a vertex.
    @inlinable
    public func depth(checked vertex: Vertex) throws(VertexNotFound) -> Int {
        _layout.nodes[try _layout.checkedNumber(of: vertex)].depth
    }
}

extension OrderedTree {
    /// The ordered tree a binary tree is, each vertex's children left then right. O(1).
    @inlinable
    public init(_ tree: BinaryTree<Vertex>) {
        self.init(_layout: tree._layout)
    }
}

extension Arborescence {
    /// The arborescence a binary tree is, every edge from parent to child, `children(of:)` left
    /// then right. O(1). A new graph, with its own generation and no maps.
    @inlinable
    public init(_ tree: BinaryTree<Vertex>) {
        self.init(_layout: tree._layout)
    }
}

// MARK: - Every binary tree

extension BinaryTree where Vertex == Int {
    /// Every binary tree on `0..<vertexCount`, its vertices numbered in preorder, generated
    /// lazily: the Catalan number C(n) = (2n)! / (n! (n + 1)!) of them, and none for 0. Each
    /// step after the first changes O(1) links on average.
    ///
    /// Knuth's Algorithm B (Skarbek's), The Art of Computer Programming 7.2.1.6.
    ///
    /// - Precondition: `vertexCount` is not negative.
    /// - Complexity: O(n) for each tree, to build it.
    @inlinable
    public static func allBinaryTrees(vertexCount: Int) -> AllBinaryTrees {
        precondition(vertexCount >= 0, "A vertex count is not negative")
        return AllBinaryTrees(vertexCount: vertexCount)
    }
}

/// Every binary tree on `0..<n` in Knuth's Algorithm B order, its vertices numbered in preorder:
/// `BinaryTree.allBinaryTrees(vertexCount:)`.
@frozen
public struct AllBinaryTrees: Sequence, Sendable {
    @usableFromInline let _vertexCount: Int

    @inlinable
    init(vertexCount: Int) { _vertexCount = vertexCount }

    @inlinable
    public func makeIterator() -> Iterator { Iterator(vertexCount: _vertexCount) }

    @inlinable
    public var underestimatedCount: Int { _vertexCount > 0 ? 1 : 0 }

    /// The iterator: Algorithm B's links, l and r over 1…n (0 for none), with l[n + 1] = 1.
    @frozen
    public struct Iterator: IteratorProtocol, Sendable {
        @usableFromInline var _left: [Int]
        @usableFromInline var _right: [Int]
        @usableFromInline let _n: Int
        @usableFromInline var _started: Bool
        @usableFromInline var _done: Bool

        @inlinable
        init(vertexCount n: Int) {
            _n = n
            // B1: the tree whose every vertex is its predecessor's left child.
            _left = [Int](repeating: 0, count: n + 2)
            _right = [Int](repeating: 0, count: n + 2)
            for k in 1 ..< Swift.max(n, 1) { _left[k] = k + 1 }
            _left[n + 1] = 1
            _started = false
            _done = n == 0
        }

        @inlinable
        public mutating func next() -> BinaryTree<Int>? {
            guard !_done else { return nil }
            if _started {
                // B3: find j, the first vertex with a left link, resetting those before it.
                var j = 1
                while _left[j] == 0 {
                    _right[j] = 0
                    _left[j] = j + 1
                    j += 1
                }
                if j > _n {
                    _done = true
                    return nil
                }
                // B4: y, the last vertex of the right spine of j's left subtree, and k its parent
                // on it (0 when y is j's left child).
                var y = _left[j], k = 0
                while _right[y] > 0 {
                    k = y
                    y = _right[y]
                }
                // B5: promote y.
                if k > 0 { _right[k] = 0 } else { _left[j] = 0 }
                _right[y] = _right[j]
                _right[j] = y
            }
            _started = true
            return _tree()
        }

        /// The current links as a tree on 0..<n: vertex k − 1 for Knuth's k, and the edge to
        /// each vertex c > 0 at position c − 1, so every row lists the parent edge, then the left
        /// child, then the right (preorder puts the left child first).
        @inlinable
        func _tree() -> BinaryTree<Int> {
            let n = _n
            var ends = [Int](repeating: 0, count: 2 * (n - 1))
            var sides = [UInt8](repeating: 0, count: n)
            for k in 1 ... n {
                if _left[k] > 0 {
                    ends[2 * (_left[k] - 2)] = k - 1
                    ends[2 * (_left[k] - 2) + 1] = _left[k] - 1
                    sides[k - 1] |= 1
                }
                if _right[k] > 0 {
                    ends[2 * (_right[k] - 2)] = k - 1
                    ends[2 * (_right[k] - 2) + 1] = _right[k] - 1
                    sides[k - 1] |= 2
                }
            }
            guard let layout = _TreeLayout<Int>(vertices: ContiguousArray(0 ..< n), slots: [:], dense: true, ends: ends, root: 0, oriented: true) else {
                preconditionFailure("Algorithm B's links form a binary tree")
            }
            return BinaryTree(_layout: layout, sides: sides)
        }
    }
}

// MARK: - Huffman trees

extension BinaryTree where Vertex == Int {
    /// The Huffman tree of the weights: a binary tree whose leaves are `0..<n`, the weights'
    /// offsets, in which the sum over the leaves of weight times depth is least. Each step
    /// joins the two lightest trees under a new vertex, `n`, `n + 1`, … in turn, the lighter as
    /// the left child; on a tie a leaf goes before a joined tree, and earlier ones before later.
    /// The root is `2n − 2`, or the lone leaf 0. Reading left as 0 and right as 1 down to a
    /// leaf gives its code word.
    ///
    /// Huffman, "A method for the construction of minimum-redundancy codes", Proceedings of the
    /// IRE 40(9), 1952, by van Leeuwen's two queues after one sort.
    ///
    /// - Parameter weights: The weights, at least one.
    /// - Returns: The tree on `0..<2n − 1`.
    /// - Precondition: There is at least one weight, and every sum of weights fits in `W`.
    /// - Complexity: O(n log n) for the sort, then O(n).
    @inlinable
    public static func huffman<W: Comparable & AdditiveArithmetic>(weights: some Sequence<W>) -> BinaryTree<Int> {
        let weight = ContiguousArray(weights)
        let n = weight.count
        precondition(n >= 1, "A Huffman tree has at least one leaf")
        // Leaves by weight, ties by offset; joined trees come out of the second queue lightest
        // first, since each join weighs at least the one before.
        let leaves = (0 ..< n).sorted { weight[$0] < weight[$1] || (weight[$0] == weight[$1] && $0 < $1) }
        var joined = ContiguousArray<W>()
        joined.reserveCapacity(n - 1)
        var children = [Int](repeating: -1, count: 2 * (n - 1))
        var head = 0, joinedHead = 0
        for t in 0 ..< n - 1 {
            var pair = (0, 0), total = W.zero
            for s in 0 ..< 2 {
                let takeLeaf = head < n && (joinedHead >= joined.count || weight[leaves[head]] <= joined[joinedHead])
                let picked: Int
                if takeLeaf {
                    picked = leaves[head]
                    total += weight[picked]
                    head += 1
                } else {
                    picked = n + joinedHead
                    total += joined[joinedHead]
                    joinedHead += 1
                }
                if s == 0 { pair.0 = picked } else { pair.1 = picked }
            }
            children[2 * t] = pair.0
            children[2 * t + 1] = pair.1
            joined.append(total)
        }
        // The joined vertex n + t has children[2t] and children[2t + 1], on the edges at
        // positions 2t and 2t + 1, so its row lists the left child before the right.
        let count = 2 * n - 1
        var ends = [Int](repeating: 0, count: 2 * (count - 1))
        for t in 0 ..< n - 1 {
            let e = 2 * t
            ends[2 * e] = n + t
            ends[2 * e + 1] = children[2 * t]
            ends[2 * e + 2] = n + t
            ends[2 * e + 3] = children[2 * t + 1]
        }
        var sides = [UInt8](repeating: 0, count: count)
        for v in n ..< count { sides[v] = 3 }
        guard let layout = _TreeLayout<Int>(vertices: ContiguousArray(0 ..< count), slots: [:], dense: true, ends: ends, root: count - 1, oriented: true) else {
            preconditionFailure("Huffman joins form a binary tree")
        }
        return BinaryTree(_layout: layout, sides: sides)
    }
}

// MARK: - Equality, hashing, descriptions

extension BinaryTree: Equatable {
    /// The same root, and the same left and right children at every vertex. O(n).
    @inlinable
    public static func == (lhs: BinaryTree, rhs: BinaryTree) -> Bool {
        guard lhs._layout.sameOrderedTree(as: rhs._layout) else { return false }
        for i in 0 ..< lhs._layout.count where lhs._sides[lhs._layout.preorder[i]] != rhs._sides[rhs._layout.preorder[i]] { return false }
        return true
    }
}

extension BinaryTree: Hashable {
    @inlinable
    public func hash(into hasher: inout Hasher) {
        _layout.hashOrdered(into: &hasher)
        for v in _layout.preorder { hasher.combine(_sides[v]) }
    }
}

extension BinaryTree: Sendable where Vertex: Sendable {}

extension BinaryTree: CustomStringConvertible, CustomDebugStringConvertible {
    /// Each vertex followed by its left and right children in parentheses, `_` for a missing
    /// one, at most 16 vertices in preorder: `0(1(_, 3), 2)`.
    public var description: String {
        // Vertex numbers, and the punctuation as negative codes.
        let tokens = [")", "_", ", ", "("]
        var text = ""
        var stack: [Int] = [_layout.roots[0]]
        var written = 0
        while let item = stack.popLast() {
            guard item >= 0 else {
                text += tokens[-1 - item]
                continue
            }
            guard written < GraphDescription.limit else {
                text += "…"
                for t in stack.reversed() where t == -1 { text += ")" }
                return text
            }
            text += GraphDescription.vertex(_layout.vertices[item])
            written += 1
            guard _sides[item] != 0 else { continue }
            let l = _left(item), r = _right(item)
            stack += [-1, r < 0 ? -2 : r, -3, l < 0 ? -2 : l, -4]
        }
        return text
    }

    /// The type, the vertex count, and the nested form.
    public var debugDescription: String {
        "BinaryTree<\(Vertex.self)>(vertexCount: \(vertexCount), " + description + ")"
    }
}
