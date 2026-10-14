import GraphProtocols

/// An ordered tree (plane tree): a rooted tree in which the children of each vertex form a
/// sequence, first to last. The order is part of the value: two ordered trees are equal when they
/// have the same root and every vertex has the same children in the same order, which is the
/// identity being an ordered-tree isomorphism between them.
///
/// It is not itself a graph. `RootedTree(_:)` and `Arborescence(_:)` convert in O(1), with
/// `children(of:)` in this tree's order, for the graph queries and algorithms.
@frozen
public struct OrderedTree<Vertex: Hashable> {
    @usableFromInline package var _layout: _TreeLayout<Vertex>

    @inlinable
    package init(_layout: _TreeLayout<Vertex>) {
        self._layout = _layout
    }

    /// The ordered tree from `root` down, in which the children of a vertex are
    /// `children(vertex)`, in order. `children` is called once for each vertex, level by level;
    /// nil when a vertex is listed twice, as a child of two vertices, twice among one vertex's
    /// children, or as a child of its own descendant (the root included). O(n).
    @inlinable
    public init?<Children: Sequence<Vertex>, E: Error>(root: Vertex, children: (Vertex) throws(E) -> Children) throws(E) {
        var vertices: ContiguousArray<Vertex> = [root]
        var slots: [Vertex: Int] = [root: 0]
        var ends: [Int] = []
        var next = 0
        while next < vertices.count {
            for child in try children(vertices[next]) {
                guard slots.updateValue(vertices.count, forKey: child) == nil else { return nil }
                ends.append(next)
                ends.append(vertices.count)
                vertices.append(child)
            }
            next += 1
        }
        self.init(_layout: _TreeLayout.levelOrder(vertices, slots, ends))
    }

    /// The rooted tree with each vertex's children in `children(of:)` order. O(1).
    @inlinable
    public init(_ tree: RootedTree<Vertex>) {
        self.init(_layout: tree._layout)
    }

    /// The arborescence with each vertex's children in `children(of:)` order. O(1).
    @inlinable
    public init(_ arborescence: Arborescence<Vertex>) {
        self.init(_layout: arborescence._layout)
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

    /// The parent of `vertex`, or nil at the root. O(1).
    ///
    /// - Precondition: `vertex` is a vertex of the tree.
    @inlinable
    public func parent(of vertex: Vertex) -> Vertex? {
        let p = _layout.nodes[_layout.number(of: vertex)].parent
        return p < 0 ? nil : _layout.vertices[p]
    }

    /// The children of `vertex`, first to last. O(1).
    ///
    /// - Precondition: `vertex` is a vertex of the tree.
    @inlinable
    public func children(of vertex: Vertex) -> RootedTree<Vertex>.Children { RootedTree.Children(_layout, _layout.number(of: vertex)) }

    /// The number of edges between `vertex` and the root. O(1).
    ///
    /// - Precondition: `vertex` is a vertex of the tree.
    @inlinable
    public func depth(of vertex: Vertex) -> Int { _layout.nodes[_layout.number(of: vertex)].depth }

    /// The greatest depth: 0 for a single vertex.
    @inlinable
    public var height: Int { _layout.height }

    /// The vertices in preorder: the root, then each child's subtree, first child first. O(1).
    @inlinable
    public var preorder: RootedTree<Vertex>.Preorder { RootedTree.Preorder(_layout, _layout.preorder.indices) }

    /// The vertices in postorder: each child's subtree, first child first, then the vertex. O(n).
    @inlinable
    public var postorder: [Vertex] { _layout.postorder() }

    /// `parent(of: vertex)`, throwing instead of trapping when `vertex` is not a vertex: nil still
    /// means `vertex` is the root. O(1).
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not a vertex.
    @inlinable
    public func parent(checked vertex: Vertex) throws(VertexNotFound) -> Vertex? {
        let p = _layout.nodes[try _layout.checkedNumber(of: vertex)].parent
        return p < 0 ? nil : _layout.vertices[p]
    }

    /// `children(of: vertex)`, throwing instead of trapping when `vertex` is not a vertex. O(1).
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not a vertex.
    @inlinable
    public func children(checked vertex: Vertex) throws(VertexNotFound) -> RootedTree<Vertex>.Children {
        RootedTree.Children(_layout, try _layout.checkedNumber(of: vertex))
    }

    /// `depth(of: vertex)`, throwing instead of trapping when `vertex` is not a vertex. O(1).
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not a vertex.
    @inlinable
    public func depth(checked vertex: Vertex) throws(VertexNotFound) -> Int {
        _layout.nodes[try _layout.checkedNumber(of: vertex)].depth
    }
}

extension RootedTree {
    /// The rooted tree an ordered tree is, with `children(of:)` in its order. O(1). A new graph,
    /// with its own generation and no maps.
    @inlinable
    public init(_ tree: OrderedTree<Vertex>) {
        self.init(_layout: tree._layout)
    }
}

extension Arborescence {
    /// The arborescence an ordered tree is, every edge from parent to child, with
    /// `children(of:)` in its order. O(1). A new graph, with its own generation and no maps.
    @inlinable
    public init(_ tree: OrderedTree<Vertex>) {
        self.init(_layout: tree._layout)
    }
}

// MARK: - Building in level order

extension _TreeLayout {
    /// The layout of a tree listed level by level: `vertices` distinct, numbered as `slots`, and
    /// edge e joining `ends[2e]` to its child `ends[2e + 1]`, children after their parents and
    /// each vertex's children consecutive and in order. The edge positions then put each parent
    /// edge before its vertex's child edges, so rows list the children in order. When the
    /// vertices are the `Int`s `0..<n` in some order, they are renumbered to their own values,
    /// and no table is kept.
    @inlinable
    package static func levelOrder(_ vertices: ContiguousArray<Vertex>, _ slots: [Vertex: Int], _ ends: [Int]) -> Self {
        let n = vertices.count
        var vertices = vertices, ends = ends, table = slots, dense = isDense(vertices)
        if !dense, Vertex.self == Int.self {
            var value = [Int](repeating: 0, count: n)
            dense = true
            for (i, v) in vertices.enumerated() {
                let x = unsafeBitCast(v, to: Int.self)
                guard UInt(bitPattern: x) < UInt(bitPattern: n) else {
                    dense = false
                    break
                }
                value[i] = x
            }
            if dense {
                // Distinct values in 0..<n: a permutation.
                for k in ends.indices { ends[k] = value[ends[k]] }
                vertices = ContiguousArray((0 ..< n).map { unsafeBitCast($0, to: Vertex.self) })
                table = [:]
            }
        }
        if !dense { (table, dense) = numbering(vertices, table: table) }
        guard let layout = Self(vertices: vertices, slots: table, dense: dense, ends: ends, root: dense ? ends.first ?? 0 : 0, oriented: true) else {
            preconditionFailure("A level-order listing is a tree")
        }
        return layout
    }
}

// MARK: - Equality, hashing, descriptions

extension _TreeLayout {
    /// The length of the row of the vertex numbered `v`: its children, and its parent edge but at
    /// the root.
    @inlinable @inline(__always)
    package func rowLength(_ v: Int) -> Int { rowOffsets[v + 1] - rowOffsets[v] }

    /// Whether the two rooted trees are the same ordered tree: equal preorders and equal child
    /// counts along them, which together determine an ordered tree. Row lengths stand for the
    /// child counts, since only the vertex first in preorder lacks a parent edge. O(n), no
    /// hashing.
    @inlinable
    package func sameOrderedTree(as other: Self) -> Bool {
        guard count == other.count else { return false }
        for i in 0 ..< count {
            let a = preorder[i], b = other.preorder[i]
            guard vertices[a] == other.vertices[b], rowLength(a) == other.rowLength(b) else { return false }
        }
        return true
    }

    /// The preorder and its row lengths.
    @inlinable
    package func hashOrdered(into hasher: inout Hasher) {
        hasher.combine(count)
        for v in preorder {
            hasher.combine(vertices[v])
            hasher.combine(rowLength(v))
        }
    }

    /// `0(1(3, 4), 2)`: each vertex then its children in parentheses, at most
    /// `GraphDescription.limit` vertices in preorder and then `…`.
    package func nestedDescription(_ label: (Int) -> String) -> String {
        var text = ""
        var previous = 0
        // One step past the limit writes `…` where the next vertex would go.
        for i in 0 ..< min(count, GraphDescription.limit + 1) {
            let v = preorder[i], d = nodes[v].depth
            if i > 0 {
                if d > previous {
                    text += "("
                } else {
                    text += String(repeating: ")", count: previous - d) + ", "
                }
            }
            text += i == GraphDescription.limit ? "…" : label(v)
            previous = d
        }
        return text + String(repeating: ")", count: previous)
    }
}

extension OrderedTree: Equatable {
    /// The same root, and the same children in the same order at every vertex. O(n).
    @inlinable
    public static func == (lhs: OrderedTree, rhs: OrderedTree) -> Bool { lhs._layout.sameOrderedTree(as: rhs._layout) }
}

extension OrderedTree: Hashable {
    @inlinable
    public func hash(into hasher: inout Hasher) { _layout.hashOrdered(into: &hasher) }
}

extension OrderedTree: Sendable where Vertex: Sendable {}

extension OrderedTree: CustomStringConvertible, CustomDebugStringConvertible {
    /// Each vertex followed by its children in parentheses, at most 16 vertices in preorder:
    /// `0(1(3, 4), 2)`.
    public var description: String { _layout.nestedDescription { GraphDescription.vertex(_layout.vertices[$0]) } }

    /// The type, the vertex count, and the nested form.
    public var debugDescription: String {
        "OrderedTree<\(Vertex.self)>(vertexCount: \(vertexCount), " + description + ")"
    }
}
