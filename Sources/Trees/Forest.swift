import GraphProtocols
import Walks

/// A forest: an acyclic undirected graph, possibly empty, so a disjoint union of trees (an
/// isolated vertex is a one-vertex tree). `trees` lists them by least vertex, and
/// `component(of:)` says which one a vertex is in.
///
/// Vertices and edges keep the order and positions they were given in, as for `Tree`.
@frozen
public struct Forest<Vertex: Hashable> {
    @usableFromInline package var _layout: _TreeLayout<Vertex>
    /// With two or more trees: each tree's vertices and edges as runs, in the forest's order,
    /// and each vertex's offset in its tree.
    @usableFromInline var _vertexStart: [Int]
    @usableFromInline var _treeVertices: [Int]
    @usableFromInline var _edgeStart: [Int]
    @usableFromInline var _treeEdges: [Int]
    @usableFromInline var _localIndex: [Int]

    @inlinable
    init(_layout layout: _TreeLayout<Vertex>) {
        _layout = layout
        let trees = layout.roots.count
        guard trees >= 2 else {
            _vertexStart = []
            _treeVertices = []
            _edgeStart = []
            _treeEdges = []
            _localIndex = []
            return
        }
        // Counting sorts by tree: stable, so each run keeps the forest's order.
        var vertexStart = [Int](repeating: 0, count: trees + 1)
        for v in 0 ..< layout.count { vertexStart[layout.nodes[v].component + 1] += 1 }
        for t in 0 ..< trees { vertexStart[t + 1] += vertexStart[t] }
        var fill = vertexStart
        var treeVertices = [Int](repeating: 0, count: layout.count)
        var localIndex = [Int](repeating: 0, count: layout.count)
        for v in 0 ..< layout.count {
            let t = layout.nodes[v].component
            treeVertices[fill[t]] = v
            localIndex[v] = fill[t] - vertexStart[t]
            fill[t] += 1
        }
        var edgeStart = [Int](repeating: 0, count: trees + 1)
        for e in 0 ..< layout.edgeCount { edgeStart[layout.nodes[layout.ends[2 * e]].component + 1] += 1 }
        for t in 0 ..< trees { edgeStart[t + 1] += edgeStart[t] }
        fill = edgeStart
        var treeEdges = [Int](repeating: 0, count: layout.edgeCount)
        for e in 0 ..< layout.edgeCount {
            let t = layout.nodes[layout.ends[2 * e]].component
            treeEdges[fill[t]] = e
            fill[t] += 1
        }
        _vertexStart = vertexStart
        _treeVertices = treeVertices
        _edgeStart = edgeStart
        _treeEdges = treeEdges
        _localIndex = localIndex
    }

    /// The empty forest.
    @inlinable
    public init() {
        self.init(_layout: _TreeLayout(vertices: [], slots: [:], dense: true, ends: [], root: nil)!)
    }

    /// The forest a graph is, keeping its vertex order and edge positions; nil when it has a
    /// cycle (a self-loop and a parallel pair included). O(n + m).
    @inlinable
    public init?(_ graph: some Graph<Vertex>) {
        guard graph.edgeCount < max(graph.vertexCount, 1), let (vertices, ends, table) = graph._treeInput() else { return nil }
        let (slots, dense) = _TreeLayout.numbering(vertices, table: table)
        guard let layout = _TreeLayout(vertices: vertices, slots: slots, dense: dense, ends: ends, root: nil) else { return nil }
        self.init(_layout: layout)
    }

    /// The forest with these edges, whose vertices are their endpoints by first appearance.
    @inlinable
    public init?(edges: some Sequence<UndirectedEdge<Vertex>>) {
        self.init(vertices: EmptyCollection(), edges: edges)
    }

    /// The forest with these vertices (duplicates dropped) and edges (missing endpoints added, by
    /// first appearance); nil when they hold a cycle.
    @inlinable
    public init?(vertices: some Sequence<Vertex>, edges: some Sequence<UndirectedEdge<Vertex>>) {
        let (listed, slots, dense, ends) = _TreeLayout.gather(vertices: vertices, edges: edges) { ($0.u, $0.v) }
        guard let layout = _TreeLayout(vertices: listed, slots: slots, dense: dense, ends: ends, root: nil) else { return nil }
        self.init(_layout: layout)
    }

    /// The forest of one tree. O(1).
    @inlinable
    public init(_ tree: Tree<Vertex>) {
        self.init(_layout: tree._layout)
    }

    /// The trees, by least vertex: each with the forest's vertices in the forest's order and its
    /// edges in the forest's position order, renumbered from 0.
    @inlinable
    public var trees: Trees { Trees(self) }

    /// The offset in `trees` of the tree containing `vertex`. O(1).
    ///
    /// - Precondition: `vertex` is a vertex of the forest.
    @inlinable
    public func component(of vertex: Vertex) -> Int { _layout.nodes[_layout.number(of: vertex)].component }

    /// The path from `source` to `target`, with the edges it takes; nil when they are in
    /// different trees. O(length).
    ///
    /// - Precondition: Both are vertices of the forest.
    @inlinable
    public func path(from source: Vertex, to target: Vertex) -> Path<Vertex, Int>? {
        _layout._path(from: source, to: target)
    }

    /// The tree at offset `t` in `trees`. O(its size).
    @inlinable
    func _tree(_ t: Int) -> Tree<Vertex> {
        if _layout.roots.count == 1 { return Tree(_layout: _layout) }
        if _vertexStart[t + 1] - _vertexStart[t] == 1 { return Tree(_layout: .single(_layout.vertices[_treeVertices[_vertexStart[t]]])) }
        var vertices = ContiguousArray<Vertex>()
        vertices.reserveCapacity(_vertexStart[t + 1] - _vertexStart[t])
        for k in _vertexStart[t] ..< _vertexStart[t + 1] { vertices.append(_layout.vertices[_treeVertices[k]]) }
        var ends: [Int] = []
        ends.reserveCapacity(2 * (_edgeStart[t + 1] - _edgeStart[t]))
        for k in _edgeStart[t] ..< _edgeStart[t + 1] {
            let e = _treeEdges[k]
            ends.append(_localIndex[_layout.ends[2 * e]])
            ends.append(_localIndex[_layout.ends[2 * e + 1]])
        }
        let (slots, dense) = _TreeLayout.numbering(vertices)
        return Tree(_layout: _TreeLayout(vertices: vertices, slots: slots, dense: dense, ends: ends, root: 0)!)
    }
}

extension Forest {
    /// The trees of a forest, by least vertex; each element is built when read.
    @frozen
    public struct Trees: RandomAccessCollection {
        @usableFromInline let _forest: Forest

        @inlinable
        init(_ forest: Forest) {
            _forest = forest
        }

        @inlinable public var startIndex: Int { 0 }
        @inlinable public var endIndex: Int { _forest._layout.roots.count }

        @inlinable
        public subscript(position: Int) -> Tree<Vertex> {
            precondition(position >= 0 && position < endIndex, "Index out of range")
            return _forest._tree(position)
        }
    }
}

extension Forest.Trees: Sendable where Vertex: Sendable {}

// MARK: - Graph

extension Forest: Graph {
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

extension Forest: Equatable {
    /// Equal vertex sets and equal edge sets. O(n).
    @inlinable
    public static func == (lhs: Forest, rhs: Forest) -> Bool { lhs._layout.sameGraph(as: rhs._layout) }
}

extension Forest: Hashable {
    @inlinable
    public func hash(into hasher: inout Hasher) { _layout.hashUndirected(into: &hasher) }
}

extension Forest: Sendable where Vertex: Sendable {}

extension Forest: Encodable where Vertex: Encodable {
    /// The `UndirectedAdjacencyList` format, as `Tree`.
    public func encode(to encoder: any Encoder) throws { try _layout.encode(to: encoder) }
}

extension Forest: Decodable where Vertex: Decodable {
    /// Throws `DecodingError.dataCorrupted` unless it is a forest.
    public init(from decoder: any Decoder) throws {
        let (vertices, slots, dense, ends, _) = try _TreeLayout<Vertex>.decode(from: decoder)
        guard let layout = _TreeLayout(vertices: vertices, slots: slots, dense: dense, ends: ends, root: nil) else {
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Not a forest"))
        }
        self.init(_layout: layout)
    }
}

extension Forest: CustomStringConvertible, CustomDebugStringConvertible {
    /// The vertices and the edges, at most 16 of each: `[0, 1, 2]; [0–1]`.
    public var description: String {
        GraphDescription.graph(vertices: vertices, vertexCount: vertexCount, edges: edges, edgeCount: edgeCount)
    }

    /// The type, the counts, the number of trees, and at most 16 vertices and edges.
    public var debugDescription: String {
        "Forest<\(Vertex.self)>(vertexCount: \(vertexCount), edgeCount: \(edgeCount), trees: \(trees.count), vertices: "
            + GraphDescription.list(vertices, count: vertexCount) { String(reflecting: $0) }
            + ", edges: "
            + GraphDescription.list(edges, count: edgeCount) { GraphDescription.edge($0) }
            + ")"
    }
}
