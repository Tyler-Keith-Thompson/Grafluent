import GraphProtocols
import Walks

/// A tree with a root: an undirected `Graph` with `root`, `parent(of:)`, `children(of:)` and
/// `depth(of:)`, and the queries tree algorithms start from. The vertices, edges and their
/// positions are the tree's; the root orders `children(of:)` (each vertex's incident edges in
/// position order, without the edge to its parent) and so `preorder`.
///
/// `preorder` is the storage layout, and each subtree is an interval of it, so `descendants(of:)`
/// and `isAncestor(_:of:)` are O(1).
///
/// Equality is by vertex set, edge set and root, so two equal rooted trees can list children,
/// and so `preorder` and `postorder`, in different orders, as two equal adjacency lists can list
/// neighbors differently.
@frozen
public struct RootedTree<Vertex: Hashable> {
    @usableFromInline package var _layout: _TreeLayout<Vertex>

    @inlinable
    package init(_layout: _TreeLayout<Vertex>) {
        self._layout = _layout
    }

    /// The tree rooted at `root`. O(n), and O(1) when it is already rooted there.
    ///
    /// - Precondition: `root` is a vertex of the tree.
    @inlinable
    public init(_ tree: Tree<Vertex>, root: Vertex) {
        _layout = tree._layout.rerooted(at: tree._layout.number(of: root))
    }

    /// The tree a graph is, rooted at `root`; nil when the graph is not a tree.
    ///
    /// - Precondition: `root` is a vertex of the graph.
    @inlinable
    public init?(_ graph: some Graph<Vertex>, root: Vertex) {
        precondition(graph.contains(root), "The root is not a vertex of the graph")
        let n = graph.vertexCount
        guard n >= 1, graph.edgeCount == n - 1, let (vertices, ends, table) = graph._treeInput() else { return nil }
        let (slots, dense) = _TreeLayout.numbering(vertices, table: table)
        let r = _TreeLayout.lookup(root, vertices, slots, dense)!
        guard let layout = _TreeLayout(vertices: vertices, slots: slots, dense: dense, ends: ends, root: r) else { return nil }
        _layout = layout
    }

    /// The rooted tree an arborescence is, forgetting the edges' directions. O(1).
    @inlinable
    public init(_ arborescence: Arborescence<Vertex>) {
        _layout = arborescence._layout
    }

    /// The rooted tree with these vertices (duplicates dropped) in which each vertex's parent is
    /// `parent(v)`, and the root's is nil: one edge (parent, child) per vertex but the root, in
    /// vertex order, so `children(of:)` is in vertex order. `parent` is called once for each
    /// distinct vertex, in order, before anything is checked. Nil when no vertex or more than one
    /// has no parent, a parent is not among the vertices or is the vertex itself, or the parents
    /// make a cycle.
    @inlinable
    public init?<E: Error>(vertices: some Sequence<Vertex>, parent: (Vertex) throws(E) -> Vertex?) throws(E) {
        guard let layout = try _TreeLayout<Vertex>.fromParents(vertices: vertices, parent: parent) else { return nil }
        _layout = layout
    }

    /// The root.
    @inlinable
    public var root: Vertex { _layout.vertices[_layout.roots[0]] }

    /// The parent of `vertex`, or nil at the root. O(1).
    @inlinable
    public func parent(of vertex: Vertex) -> Vertex? {
        let p = _layout.nodes[_layout.number(of: vertex)].parent
        return p < 0 ? nil : _layout.vertices[p]
    }

    /// The position of the edge to the parent of `vertex`, or nil at the root. O(1).
    @inlinable
    public func parentEdge(of vertex: Vertex) -> Int? {
        let e = _layout.nodes[_layout.number(of: vertex)].parentEdge
        return e < 0 ? nil : e
    }

    /// The children of `vertex`, in position order of the edges to them. O(1).
    @inlinable
    public func children(of vertex: Vertex) -> Children { Children(_layout, _layout.number(of: vertex)) }

    /// The number of edges between `vertex` and the root. O(1).
    @inlinable
    public func depth(of vertex: Vertex) -> Int { _layout.nodes[_layout.number(of: vertex)].depth }

    /// The greatest depth: 0 for a single vertex.
    @inlinable
    public var height: Int { _layout.height }

    /// The vertices in preorder: the root, then each child's subtree in `children` order. O(1).
    @inlinable
    public var preorder: Preorder { Preorder(_layout, _layout.preorder.indices) }

    /// The vertices in postorder: each child's subtree in `children` order, then the vertex. O(n).
    @inlinable
    public var postorder: [Vertex] { _layout.postorder() }

    /// The vertices below `vertex`, in preorder, without it: a slice of `preorder`. O(1).
    @inlinable
    public func descendants(of vertex: Vertex) -> Preorder.SubSequence { _layout.descendants(of: vertex) }

    /// The vertices above `vertex`, parent first, up to the root; empty at the root.
    @inlinable
    public func ancestors(of vertex: Vertex) -> Ancestors { Ancestors(_layout, _layout.number(of: vertex)) }

    /// Whether `a` is an ancestor of `b`: strictly above it, as `ancestors(of: b).contains(a)`.
    /// O(1).
    @inlinable
    public func isAncestor(_ a: Vertex, of b: Vertex) -> Bool { _layout.isAncestor(_layout.number(of: a), of: _layout.number(of: b)) }

    /// The path from `source` to `target`, with the edges it takes: up to their meeting vertex,
    /// then down. It does not depend on the root. O(length).
    ///
    /// - Precondition: Both are vertices of the tree.
    @inlinable
    public func path(from source: Vertex, to target: Vertex) -> Path<Vertex, Int> {
        _layout._path(from: source, to: target)!
    }

    /// The root's vertex index.
    @inlinable
    public var rootIndex: Int { _layout.roots[0] }

    /// The vertex index of the parent of the vertex at `index`, or nil at the root.
    @inlinable
    public func parent(ofIndex index: Int) -> Int? {
        let p = _layout.nodes[index].parent
        return p < 0 ? nil : p
    }

    /// The depth of the vertex at `index`.
    @inlinable
    public func depth(ofIndex index: Int) -> Int { _layout.nodes[index].depth }
}

extension RootedTree where Vertex == Int {
    /// The rooted tree on `0..<parents.count` in which vertex `i`'s parent is `parents[i]`, and
    /// the root's is nil. Nil unless exactly one entry is nil, every other is in range and not
    /// the vertex itself, and there is no cycle.
    @inlinable
    public init?(parents: [Int?]) {
        guard let layout = _TreeLayout<Int>.fromParentNumbers(parents) else { return nil }
        _layout = layout
    }
}

// MARK: - Building from parents

extension _TreeLayout {
    @inlinable
    static func fromParents<E: Error>(vertices listed: some Sequence<Vertex>, parent: (Vertex) throws(E) -> Vertex?) throws(E) -> Self? {
        var vertices = ContiguousArray<Vertex>()
        var slots: [Vertex: Int] = [:]
        for v in listed where slots[v] == nil {
            slots[v] = vertices.count
            vertices.append(v)
        }
        var parents = [Int](repeating: -1, count: vertices.count)
        for (i, v) in vertices.enumerated() {
            guard let p = try parent(v) else { continue }
            guard let k = slots[p] else { return nil }
            parents[i] = k
        }
        let (table, dense) = numbering(vertices, table: slots)
        return fromParents(vertices: vertices, slots: table, dense: dense, parents: parents)
    }

    /// From parent numbers (−1 for the root). Nil unless exactly one root, no self-parent, no
    /// cycle.
    @inlinable
    package static func fromParents(vertices: ContiguousArray<Vertex>, slots: [Vertex: Int], dense: Bool, parents: [Int]) -> Self? {
        var root = -1
        var ends: [Int] = []
        ends.reserveCapacity(2 * max(vertices.count - 1, 0))
        for (v, p) in parents.enumerated() {
            if p < 0 {
                guard root < 0 else { return nil }
                root = v
            } else {
                guard p != v else { return nil }
                ends.append(p)
                ends.append(v)
            }
        }
        guard root >= 0 else { return nil }
        return Self(vertices: vertices, slots: slots, dense: dense, ends: ends, root: root)
    }
}

extension _TreeLayout where Vertex == Int {
    @inlinable
    static func fromParentNumbers(_ parents: [Int?]) -> Self? {
        let n = parents.count
        var numbers = [Int](repeating: -1, count: n)
        for (i, p) in parents.enumerated() {
            guard let p else { continue }
            guard p >= 0, p < n else { return nil }
            numbers[i] = p
        }
        return fromParents(vertices: ContiguousArray(0 ..< n), slots: [:], dense: true, parents: numbers)
    }
}

// MARK: - Queries

extension _TreeLayout {
    @inlinable
    func postorder() -> [Vertex] {
        // post(v) = pre(v) + size(v) − 1 − depth(v): the vertices before v in postorder are its
        // descendants and the vertices before it in preorder that are not its ancestors (in a
        // forest too, where every root has depth 0).
        let n = count
        return [Vertex](unsafeUninitializedCapacity: n) { buffer, initialized in
            for v in 0 ..< n {
                let node = nodes[v]
                (buffer.baseAddress! + node.preorderPosition + node.size - 1 - node.depth).initialize(to: vertices[v])
            }
            initialized = n
        }
    }

    @inlinable
    func descendants(of vertex: Vertex) -> Slice<RootedTree<Vertex>.Preorder> {
        let v = number(of: vertex)
        let start = nodes[v].preorderPosition
        return RootedTree.Preorder(self, preorder.indices)[(start + 1) ..< (start + nodes[v].size)]
    }
}

extension RootedTree {
    /// The children of a vertex: its row without the edge to its parent.
    @frozen
    public struct Children: RandomAccessCollection {
        @usableFromInline let _vertices: ContiguousArray<Vertex>
        @usableFromInline let _neighbors: [Int]
        @usableFromInline let _start: Int
        @usableFromInline let _count: Int
        /// The offset of the parent edge in the row, or `_count` (past the end) at a root.
        @usableFromInline let _hole: Int

        @inlinable
        init(_ layout: _TreeLayout<Vertex>, _ v: Int) {
            _vertices = layout.vertices
            _neighbors = layout.rowNeighbors
            _start = layout.rowOffsets[v]
            let hole = layout.nodes[v].parentOffset
            _count = layout.rowOffsets[v + 1] - _start - (hole < 0 ? 0 : 1)
            _hole = hole < 0 ? _count : hole
        }

        @inlinable public var startIndex: Int { 0 }
        @inlinable public var endIndex: Int { _count }

        @inlinable
        public subscript(position: Int) -> Vertex {
            precondition(position >= 0 && position < _count, "Index out of range")
            return _vertices[_neighbors[_start + (position < _hole ? position : position + 1)]]
        }
    }

    /// The vertices in preorder.
    @frozen
    public struct Preorder: RandomAccessCollection {
        @usableFromInline let _vertices: ContiguousArray<Vertex>
        @usableFromInline let _order: [Int]
        @usableFromInline let _range: Range<Int>

        @inlinable
        init(_ layout: _TreeLayout<Vertex>, _ range: Range<Int>) {
            _vertices = layout.vertices
            _order = layout.preorder
            _range = range
        }

        @inlinable public var startIndex: Int { _range.lowerBound }
        @inlinable public var endIndex: Int { _range.upperBound }

        @inlinable
        public subscript(position: Int) -> Vertex {
            precondition(_range.contains(position), "Index out of range")
            return _vertices[_order[position]]
        }
    }

    /// The vertices above one, parent first.
    @frozen
    public struct Ancestors: Sequence, IteratorProtocol {
        @usableFromInline let _vertices: ContiguousArray<Vertex>
        @usableFromInline let _nodes: [_TreeNode]
        @usableFromInline var _current: Int

        @inlinable
        init(_ layout: _TreeLayout<Vertex>, _ v: Int) {
            _vertices = layout.vertices
            _nodes = layout.nodes
            _current = v
        }

        @inlinable
        public mutating func next() -> Vertex? {
            let p = _nodes[_current].parent
            guard p >= 0 else { return nil }
            _current = p
            return _vertices[p]
        }

        @inlinable
        public var underestimatedCount: Int { _nodes[_current].parent < 0 ? 0 : 1 }
    }
}

extension RootedTree.Children: Sendable where Vertex: Sendable {}
extension RootedTree.Preorder: Sendable where Vertex: Sendable {}
extension RootedTree.Ancestors: Sendable where Vertex: Sendable {}

// MARK: - Graph

extension RootedTree: Graph {
    public typealias Edges = Tree<Vertex>.Edges
    public typealias Neighbors = Tree<Vertex>.Neighbors

    @inlinable public var vertices: ContiguousArray<Vertex> { _layout.vertices }
    @inlinable public var edges: Edges { Edges(_vertices: _layout.vertices, ends: _layout.ends) }
    @inlinable public var vertexCount: Int { _layout.count }
    @inlinable public var edgeCount: Int { _layout.edgeCount }

    @inlinable
    public func neighbors(of vertex: Vertex) -> Neighbors {
        Neighbors(_vertices: _layout.vertices, numbers: _layout.rowNeighbors[_layout.row(_layout.number(of: vertex))])
    }

    @inlinable
    public func incidentEdges(of vertex: Vertex) -> ArraySlice<Int> { _layout.rowEdges[_layout.row(_layout.number(of: vertex))] }

    @inlinable
    public func oppositeVertex(to vertex: Vertex, acrossEdgeAt position: Int) -> Vertex {
        let v = _layout.number(of: vertex)
        let a = _layout.ends[2 * position], b = _layout.ends[2 * position + 1]
        precondition(a == v || b == v, "The vertex is not an endpoint of the edge")
        return _layout.vertices[a == v ? b : a]
    }

    @inlinable public func degree(of vertex: Vertex) -> Int { _layout.row(_layout.number(of: vertex)).count }
    @inlinable public func contains(_ vertex: Vertex) -> Bool { _layout.contains(vertex) }
    @inlinable public func contains(edge: UndirectedEdge<Vertex>) -> Bool { _layout.containsEdge(edge) }

    @inlinable public var vertexIndexBound: Int? { _layout.count }
    @inlinable public func vertexIndex(of vertex: Vertex) -> Int { _layout.number(of: vertex) }
    @inlinable public func vertex(atIndex index: Int) -> Vertex { _layout.vertices[index] }
    @inlinable public func neighborIndices(ofIndex index: Int) -> ArraySlice<Int> { _layout.rowNeighbors[_layout.row(index)] }
    @inlinable public var edgeIndexBound: Int? { _layout.edgeCount }
    @inlinable public func edgeIndex(of position: Int) -> Int { position }
    @inlinable public func incidentEdges(ofIndex index: Int) -> ArraySlice<Int> { _layout.rowEdges[_layout.row(index)] }
    @inlinable public func incidentEdgeIndices(ofIndex index: Int) -> ArraySlice<Int> { _layout.rowEdges[_layout.row(index)] }
}

// MARK: - Equality, hashing, coding, descriptions

extension RootedTree: Equatable {
    /// Equal vertex sets, equal edge sets and equal roots. O(n).
    @inlinable
    public static func == (lhs: RootedTree, rhs: RootedTree) -> Bool {
        lhs.root == rhs.root && lhs._layout.sameGraph(as: rhs._layout)
    }
}

extension RootedTree: Hashable {
    @inlinable
    public func hash(into hasher: inout Hasher) {
        _layout.hashUndirected(into: &hasher)
        hasher.combine(root)
    }
}

extension RootedTree: Sendable where Vertex: Sendable {}

extension RootedTree: Encodable where Vertex: Encodable {
    /// `Tree`'s format plus the root's offset in the vertex list.
    public func encode(to encoder: any Encoder) throws { try _layout.encode(to: encoder, root: rootIndex) }
}

extension RootedTree: Decodable where Vertex: Decodable {
    /// Throws `DecodingError.dataCorrupted` unless it is a tree with its root among the vertices.
    public init(from decoder: any Decoder) throws {
        let (vertices, slots, dense, ends, root) = try _TreeLayout<Vertex>.decode(from: decoder, root: true)
        guard let layout = _TreeLayout(vertices: vertices, slots: slots, dense: dense, ends: ends, root: root) else {
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Not a tree"))
        }
        _layout = layout
    }
}

extension RootedTree: CustomStringConvertible, CustomDebugStringConvertible {
    /// The vertices and the edges, at most 16 of each, then the root: `[0, 1, 2]; [0–1, 1–2]; root 0`.
    public var description: String {
        GraphDescription.graph(vertices: vertices, vertexCount: vertexCount, edges: edges, edgeCount: edgeCount)
            + "; root " + GraphDescription.vertex(root)
    }

    /// The type, the counts, the root, and at most 16 vertices and edges.
    public var debugDescription: String {
        "RootedTree<\(Vertex.self)>(vertexCount: \(vertexCount), edgeCount: \(edgeCount), root: \(String(reflecting: root)), vertices: "
            + GraphDescription.list(vertices, count: vertexCount) { String(reflecting: $0) }
            + ", edges: "
            + GraphDescription.list(edges, count: edgeCount) { GraphDescription.edge($0) }
            + ")"
    }
}
