import GraphProtocols
import Walks

/// A tree: a connected, acyclic undirected graph with at least one vertex, so it has exactly
/// n − 1 edges, no self-loop and no parallel edges. The invariant is the type: every initializer
/// from unchecked input is failable, and a `Tree` cannot be mutated.
///
/// Vertices are numbered in `vertices` order (the vertex indices), and edges keep the order and
/// orientation they were given in, at positions `0..<n − 1` (the edge indices). Each vertex's
/// incident edges are in position order. Converting to a `RootedTree` (and from it to an
/// `Arborescence`) or a `Forest` keeps both.
///
/// A tree's unique path between two vertices is `path(from:to:)`. Equality is by vertex set and
/// edge set, as for `UndirectedAdjacencyList`.
@frozen
public struct Tree<Vertex: Hashable> {
    @usableFromInline package var _layout: _TreeLayout<Vertex>

    @inlinable
    init(_layout: _TreeLayout<Vertex>) {
        self._layout = _layout
    }

    /// The tree a graph is, keeping its vertex order and its edges at their positions; nil when
    /// the graph is not a tree (empty, disconnected, or with a cycle, a self-loop or a parallel
    /// pair). O(n + m), and O(1) when `edgeCount != vertexCount − 1`.
    @inlinable
    public init?(_ graph: some Graph<Vertex>) {
        let n = graph.vertexCount
        guard n >= 1, graph.edgeCount == n - 1, let (vertices, ends, table) = graph._treeInput() else { return nil }
        let (slots, dense) = _TreeLayout.numbering(vertices, table: table)
        guard let layout = _TreeLayout(vertices: vertices, slots: slots, dense: dense, ends: ends, root: 0) else { return nil }
        _layout = layout
    }

    /// The tree with these edges, whose vertices are exactly their endpoints, by first
    /// appearance; nil unless they form a tree. An edge written twice, in either orientation, is
    /// a parallel pair, so not a tree.
    @inlinable
    public init?(edges: some Sequence<UndirectedEdge<Vertex>>) {
        self.init(vertices: EmptyCollection(), edges: edges)
    }

    /// The tree with these vertices (duplicates dropped) and edges (endpoints missing from
    /// `vertices` added, by first appearance); nil unless they form a tree.
    @inlinable
    public init?(vertices: some Sequence<Vertex>, edges: some Sequence<UndirectedEdge<Vertex>>) {
        let (listed, slots, dense, ends) = _TreeLayout.gather(vertices: vertices, edges: edges) { ($0.u, $0.v) }
        guard !listed.isEmpty else { return nil }
        guard let layout = _TreeLayout(vertices: listed, slots: slots, dense: dense, ends: ends, root: 0) else { return nil }
        _layout = layout
    }

    /// The tree a rooted tree is, forgetting its root. O(1).
    @inlinable
    public init(_ tree: RootedTree<Vertex>) {
        _layout = tree._layout
    }

    /// The path from `source` to `target`, with the edges it takes. O(length).
    ///
    /// - Precondition: Both are vertices of the tree.
    @inlinable
    public func path(from source: Vertex, to target: Vertex) -> Path<Vertex, Int> {
        _layout._path(from: source, to: target)!
    }
}

extension _TreeLayout {
    /// The path between two vertices, as a `Path`; nil across trees.
    @inlinable
    func _path(from source: Vertex, to target: Vertex) -> Path<Vertex, Int>? {
        guard let (vs, es) = path(number(of: source), number(of: target)) else { return nil }
        return Path(_uncheckedVertices: vs.map { vertices[$0] }, edges: es)
    }
}

// MARK: - Views

extension Tree {
    /// The edges, at their positions `0..<edgeCount`.
    @frozen
    public struct Edges: RandomAccessCollection {
        @usableFromInline let _vertices: ContiguousArray<Vertex>
        @usableFromInline let _ends: [Int]

        @inlinable
        init(_vertices: ContiguousArray<Vertex>, ends: [Int]) {
            self._vertices = _vertices
            _ends = ends
        }

        @inlinable public var startIndex: Int { 0 }
        @inlinable public var endIndex: Int { _ends.count / 2 }

        @inlinable
        public subscript(position: Int) -> UndirectedEdge<Vertex> {
            precondition(position >= 0 && position < endIndex, "Edge position out of range")
            return UndirectedEdge(_vertices[_ends[2 * position]], _vertices[_ends[2 * position + 1]])
        }
    }

    /// Vertices given by number, such as a row of neighbors; indexed from 0, as `children(of:)`.
    @frozen
    public struct Neighbors: RandomAccessCollection {
        @usableFromInline let _vertices: ContiguousArray<Vertex>
        @usableFromInline let _numbers: ArraySlice<Int>

        @inlinable
        init(_vertices: ContiguousArray<Vertex>, numbers: ArraySlice<Int>) {
            self._vertices = _vertices
            _numbers = numbers
        }

        @inlinable public var startIndex: Int { 0 }
        @inlinable public var endIndex: Int { _numbers.count }

        @inlinable
        public subscript(position: Int) -> Vertex {
            precondition(position >= 0 && position < _numbers.count, "Index out of range")
            return _vertices[_numbers[_numbers.startIndex + position]]
        }
    }
}

extension Tree.Edges: Sendable where Vertex: Sendable {}
extension Tree.Neighbors: Sendable where Vertex: Sendable {}

// MARK: - Graph

extension _TreeLayout {
    @inlinable
    func row(_ v: Int) -> Range<Int> { rowOffsets[v] ..< rowOffsets[v + 1] }

    @inlinable
    func containsEdge(_ edge: UndirectedEdge<Vertex>) -> Bool {
        guard contains(edge.u), contains(edge.v) else { return false }
        let a = number(of: edge.u), b = number(of: edge.v)
        return a != b && (nodes[a].parent == b || nodes[b].parent == a)
    }
}

extension Tree: Graph {
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

extension _TreeLayout {
    /// Equal vertex sets and equal edge sets (undirected): each edge of `self` is an edge of
    /// `other` by `other`'s parent relation. O(n), hashing each vertex once.
    @inlinable
    func sameGraph(as other: Self) -> Bool {
        guard count == other.count, edgeCount == other.edgeCount else { return false }
        if vertices == other.vertices {
            for e in 0 ..< edgeCount {
                let a = ends[2 * e], b = ends[2 * e + 1]
                guard other.nodes[a].parent == b || other.nodes[b].parent == a else { return false }
            }
            return true
        }
        var map = [Int](repeating: 0, count: count)
        for (i, v) in vertices.enumerated() {
            guard other.contains(v) else { return false }
            map[i] = other.number(of: v)
        }
        for e in 0 ..< edgeCount {
            let a = map[ends[2 * e]], b = map[ends[2 * e + 1]]
            guard other.nodes[a].parent == b || other.nodes[b].parent == a else { return false }
        }
        return true
    }

    /// A commutative sum of per-vertex and per-edge hashes, as `UndirectedAdjacencyList`'s.
    @inlinable
    func hashUndirected(into hasher: inout Hasher) {
        var vertexHashes = 0
        for v in vertices {
            var h = Hasher()
            h.combine(v)
            vertexHashes &+= h.finalize()
        }
        var edgeHashes = 0
        for e in 0 ..< edgeCount {
            var h = Hasher()
            h.combine(UndirectedEdge(vertices[ends[2 * e]], vertices[ends[2 * e + 1]]))
            edgeHashes &+= h.finalize()
        }
        hasher.combine(count)
        hasher.combine(edgeCount)
        hasher.combine(vertexHashes)
        hasher.combine(edgeHashes)
    }
}

extension Tree: Equatable {
    /// Equal vertex sets and equal edge sets; vertex order, edge order and orientation do not
    /// matter. O(n).
    @inlinable
    public static func == (lhs: Tree, rhs: Tree) -> Bool { lhs._layout.sameGraph(as: rhs._layout) }
}

extension Tree: Hashable {
    @inlinable
    public func hash(into hasher: inout Hasher) { _layout.hashUndirected(into: &hasher) }
}

extension Tree: Sendable where Vertex: Sendable {}

@usableFromInline
enum _TreeCodingKeys: String, CodingKey {
    case vertices
    case edges
    case root
}

extension _TreeLayout where Vertex: Encodable {
    /// The vertices, then the edges as pairs of offsets in that list.
    @inlinable
    func encode(to encoder: any Encoder, root: Int? = nil) throws {
        var container = encoder.container(keyedBy: _TreeCodingKeys.self)
        try container.encode(Array(vertices), forKey: .vertices)
        try container.encode(ends, forKey: .edges)
        if let root { try container.encode(root, forKey: .root) }
    }
}

extension _TreeLayout where Vertex: Decodable {
    /// The vertices and edge ends of an encoded tree, checked for shape; the caller re-checks
    /// the invariant.
    @inlinable
    static func decode(from decoder: any Decoder, root: Bool = false) throws -> (vertices: ContiguousArray<Vertex>, slots: [Vertex: Int], dense: Bool, ends: [Int], root: Int?) {
        let container = try decoder.container(keyedBy: _TreeCodingKeys.self)
        let vertices = ContiguousArray(try container.decode([Vertex].self, forKey: .vertices))
        let ends = try container.decode([Int].self, forKey: .edges)
        let rootOffset = root ? try container.decode(Int.self, forKey: .root) : nil
        guard ends.count.isMultiple(of: 2) else {
            throw DecodingError.dataCorruptedError(forKey: .edges, in: container, debugDescription: "Edge list has odd length")
        }
        guard ends.allSatisfy({ vertices.indices.contains($0) }) else {
            throw DecodingError.dataCorruptedError(forKey: .edges, in: container, debugDescription: "Edge endpoint out of range")
        }
        let (slots, dense) = numbering(vertices)
        guard dense || Set(vertices).count == vertices.count else {
            throw DecodingError.dataCorruptedError(forKey: .vertices, in: container, debugDescription: "Repeated vertex")
        }
        if let rootOffset, !vertices.indices.contains(rootOffset) {
            throw DecodingError.dataCorruptedError(forKey: .root, in: container, debugDescription: "Root out of range")
        }
        return (vertices, slots, dense, ends, rootOffset)
    }
}

extension Tree: Encodable where Vertex: Encodable {
    /// The vertices, then the edges by position as pairs of offsets in that list: the
    /// `UndirectedAdjacencyList` format.
    public func encode(to encoder: any Encoder) throws { try _layout.encode(to: encoder) }
}

extension Tree: Decodable where Vertex: Decodable {
    /// Decodes the `UndirectedAdjacencyList` format, and throws `DecodingError.dataCorrupted`
    /// unless it is a tree.
    public init(from decoder: any Decoder) throws {
        let (vertices, slots, dense, ends, _) = try _TreeLayout<Vertex>.decode(from: decoder)
        guard !vertices.isEmpty, let layout = _TreeLayout(vertices: vertices, slots: slots, dense: dense, ends: ends, root: 0) else {
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Not a tree"))
        }
        _layout = layout
    }
}

extension Tree: CustomStringConvertible, CustomDebugStringConvertible {
    /// The vertices and the edges, at most 16 of each: `[0, 1, 2]; [0–1, 1–2]`.
    public var description: String {
        GraphDescription.graph(vertices: vertices, vertexCount: vertexCount, edges: edges, edgeCount: edgeCount)
    }

    /// The type, the counts, and at most 16 vertices and edges.
    public var debugDescription: String {
        "Tree<\(Vertex.self)>(vertexCount: \(vertexCount), edgeCount: \(edgeCount), vertices: "
            + GraphDescription.list(vertices, count: vertexCount) { String(reflecting: $0) }
            + ", edges: "
            + GraphDescription.list(edges, count: edgeCount) { GraphDescription.edge($0) }
            + ")"
    }
}
