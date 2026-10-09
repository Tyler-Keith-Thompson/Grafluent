import GraphProtocols
import Walks

/// An arborescence: a directed tree whose edges all point away from its root, so every vertex
/// but the root has exactly one incoming edge, from its parent (NetworkX `is_arborescence`,
/// Edmonds). A `BidirectionalDirectedGraph`: `successors(of:)` are the children, `predecessors(of:)`
/// the parent (zero or one), and each edge is `DirectedEdge(from: parent, to: child)`.
///
/// It has the queries of `RootedTree`, and converts to and from one in O(1), keeping vertices,
/// edge positions and the root.
@frozen
public struct Arborescence<Vertex: Hashable> {
    @usableFromInline package var _layout: _TreeLayout<Vertex>

    @inlinable
    init(_layout: _TreeLayout<Vertex>) {
        self._layout = _layout
    }

    /// The arborescence a directed graph is, keeping its vertex order and edge positions; nil
    /// unless exactly one vertex has no incoming edge, every other has exactly one, and that root
    /// reaches every vertex. O(n + m), and O(1) when `edgeCount != vertexCount − 1`.
    @inlinable
    public init?(_ graph: some DirectedGraph<Vertex>) {
        let n = graph.vertexCount
        guard n >= 1, graph.edgeCount == n - 1, let (vertices, ends, table) = graph._treeInput() else { return nil }
        let (slots, dense) = _TreeLayout.numbering(vertices, table: table)
        guard let layout = _TreeLayout<Vertex>.arborescence(vertices: vertices, slots: slots, dense: dense, ends: ends) else { return nil }
        _layout = layout
    }

    /// The arborescence with these edges, whose vertices are their endpoints by first appearance.
    @inlinable
    public init?(edges: some Sequence<DirectedEdge<Vertex>>) {
        self.init(vertices: EmptyCollection(), edges: edges)
    }

    /// The arborescence with these vertices (duplicates dropped) and edges (missing endpoints
    /// added, by first appearance).
    @inlinable
    public init?(vertices: some Sequence<Vertex>, edges: some Sequence<DirectedEdge<Vertex>>) {
        let (listed, slots, dense, ends) = _TreeLayout.gather(vertices: vertices, edges: edges) { ($0.source, $0.target) }
        guard !listed.isEmpty else { return nil }
        guard let layout = _TreeLayout<Vertex>.arborescence(vertices: listed, slots: slots, dense: dense, ends: ends) else { return nil }
        _layout = layout
    }

    /// The rooted tree with every edge directed from parent to child. O(1).
    @inlinable
    public init(_ tree: RootedTree<Vertex>) {
        _layout = tree._layout
    }

    /// The arborescence in which each vertex's parent is `parent(v)` (see
    /// `RootedTree.init(vertices:parent:)`).
    @inlinable
    public init?<E: Error>(vertices: some Sequence<Vertex>, parent: (Vertex) throws(E) -> Vertex?) throws(E) {
        guard let layout = try _TreeLayout<Vertex>.fromParents(vertices: vertices, parent: parent) else { return nil }
        _layout = layout
    }

    @inlinable public var root: Vertex { _layout.vertices[_layout.roots[0]] }

    @inlinable
    public func parent(of vertex: Vertex) -> Vertex? {
        let p = _layout.nodes[_layout.number(of: vertex)].parent
        return p < 0 ? nil : _layout.vertices[p]
    }

    @inlinable
    public func parentEdge(of vertex: Vertex) -> Int? {
        let e = _layout.nodes[_layout.number(of: vertex)].parentEdge
        return e < 0 ? nil : e
    }

    @inlinable public func children(of vertex: Vertex) -> RootedTree<Vertex>.Children { RootedTree.Children(_layout, _layout.number(of: vertex)) }
    @inlinable public func depth(of vertex: Vertex) -> Int { _layout.nodes[_layout.number(of: vertex)].depth }
    @inlinable public var height: Int { _layout.height }
    @inlinable public var preorder: RootedTree<Vertex>.Preorder { RootedTree.Preorder(_layout, _layout.preorder.indices) }
    @inlinable public var postorder: [Vertex] { _layout.postorder() }
    @inlinable public func descendants(of vertex: Vertex) -> RootedTree<Vertex>.Preorder.SubSequence { _layout.descendants(of: vertex) }
    @inlinable public func ancestors(of vertex: Vertex) -> RootedTree<Vertex>.Ancestors { RootedTree.Ancestors(_layout, _layout.number(of: vertex)) }
    @inlinable public func isAncestor(_ a: Vertex, of b: Vertex) -> Bool { _layout.isAncestor(_layout.number(of: a), of: _layout.number(of: b)) }
    @inlinable public var rootIndex: Int { _layout.roots[0] }

    @inlinable
    public func parent(ofIndex index: Int) -> Int? {
        let p = _layout.nodes[index].parent
        return p < 0 ? nil : p
    }

    @inlinable public func depth(ofIndex index: Int) -> Int { _layout.nodes[index].depth }

    /// The path down the edges from `source` to `target`: nil unless `source` is `target` or an
    /// ancestor of it. O(length).
    ///
    /// - Precondition: Both are vertices.
    @inlinable
    public func path(from source: Vertex, to target: Vertex) -> Path<Vertex, Int>? {
        let a = _layout.number(of: source), b = _layout.number(of: target)
        guard a == b || _layout.isAncestor(a, of: b) else { return nil }
        return _layout._path(from: source, to: target)
    }
}

extension Arborescence where Vertex == Int {
    /// The arborescence on `0..<parents.count` in which vertex `i`'s parent is `parents[i]` (see
    /// `RootedTree.init(parents:)`).
    @inlinable
    public init?(parents: [Int?]) {
        guard let layout = _TreeLayout<Int>.fromParentNumbers(parents) else { return nil }
        _layout = layout
    }
}

extension _TreeLayout {
    /// From (source, target) ends: exactly one vertex without an incoming edge, every other with
    /// one, every edge pointing away from that root, reaching every vertex.
    @inlinable
    static func arborescence(vertices: ContiguousArray<Vertex>, slots: [Vertex: Int], dense: Bool, ends: [Int]) -> Self? {
        let n = vertices.count
        guard n >= 1, ends.count == 2 * (n - 1) else { return nil }
        var incoming = [Int](repeating: 0, count: n)
        for e in 0 ..< n - 1 {
            let t = ends[2 * e + 1]
            guard UInt(bitPattern: t) < UInt(bitPattern: n) else { return nil }
            incoming[t] += 1
            if incoming[t] > 1 { return nil }
        }
        guard let root = incoming.firstIndex(of: 0) else { return nil }
        return Self(vertices: vertices, slots: slots, dense: dense, ends: ends, root: root, oriented: true)
    }
}

// MARK: - Views

extension Arborescence {
    /// The edges, at their positions, each from parent to child.
    @frozen
    public struct Edges: RandomAccessCollection {
        @usableFromInline let _layout: _TreeLayout<Vertex>

        @inlinable
        init(_ layout: _TreeLayout<Vertex>) {
            _layout = layout
        }

        @inlinable public var startIndex: Int { 0 }
        @inlinable public var endIndex: Int { _layout.edgeCount }

        @inlinable
        public subscript(position: Int) -> DirectedEdge<Vertex> {
            precondition(position >= 0 && position < endIndex, "Edge position out of range")
            let c = _layout.child(ofEdge: position)
            return DirectedEdge(from: _layout.vertices[_layout.nodes[c].parent], to: _layout.vertices[c])
        }
    }

    /// A vertex's row without its parent's entry: the positions of the edges to its children
    /// (as `OutEdges`), or the children's vertex indices (as `SuccessorIndices`).
    @frozen
    public struct OutEdges: RandomAccessCollection {
        @usableFromInline let _row: [Int]
        @usableFromInline let _start: Int
        @usableFromInline let _count: Int
        @usableFromInline let _hole: Int

        @inlinable
        init(_ layout: _TreeLayout<Vertex>, _ v: Int, _ row: [Int]) {
            _row = row
            _start = layout.rowOffsets[v]
            let hole = layout.nodes[v].parentOffset
            _count = layout.rowOffsets[v + 1] - _start - (hole < 0 ? 0 : 1)
            _hole = hole < 0 ? _count : hole
        }

        @inlinable public var startIndex: Int { 0 }
        @inlinable public var endIndex: Int { _count }

        @inlinable
        public subscript(position: Int) -> Int {
            precondition(position >= 0 && position < _count, "Index out of range")
            return _row[_start + (position < _hole ? position : position + 1)]
        }
    }

    /// The children's vertex indices.
    public typealias SuccessorIndices = OutEdges

    /// One `Int` or none: the edge from the parent, or (as `PredecessorIndices`) the parent's
    /// index; empty at the root.
    @frozen
    public struct InEdges: RandomAccessCollection {
        @usableFromInline let _value: Int

        /// Empty when `value` is negative.
        @inlinable
        init(_ value: Int) {
            _value = value
        }

        @inlinable public var startIndex: Int { 0 }
        @inlinable public var endIndex: Int { _value < 0 ? 0 : 1 }

        @inlinable
        public subscript(position: Int) -> Int {
            precondition(position == 0 && _value >= 0, "Index out of range")
            return _value
        }
    }

    /// The parent's index, or nothing at the root.
    public typealias PredecessorIndices = InEdges

    /// The parent, or nothing at the root.
    @frozen
    public struct Predecessors: RandomAccessCollection {
        @usableFromInline let _vertex: Vertex?

        @inlinable
        init(_ vertex: Vertex?) {
            _vertex = vertex
        }

        @inlinable public var startIndex: Int { 0 }
        @inlinable public var endIndex: Int { _vertex == nil ? 0 : 1 }

        @inlinable
        public subscript(position: Int) -> Vertex {
            precondition(position == 0, "Index out of range")
            return _vertex!
        }
    }
}

extension Arborescence.Edges: Sendable where Vertex: Sendable {}
extension Arborescence.OutEdges: Sendable {}
extension Arborescence.InEdges: Sendable {}
extension Arborescence.Predecessors: Sendable where Vertex: Sendable {}

// MARK: - BidirectionalDirectedGraph

extension Arborescence: BidirectionalDirectedGraph {
    public typealias Successors = RootedTree<Vertex>.Children

    @inlinable public var vertices: ContiguousArray<Vertex> { _layout.vertices }
    @inlinable public var edges: Edges { Edges(_layout) }
    @inlinable public var vertexCount: Int { _layout.count }
    @inlinable public var edgeCount: Int { _layout.edgeCount }

    @inlinable public func successors(of vertex: Vertex) -> Successors { RootedTree.Children(_layout, _layout.number(of: vertex)) }
    @inlinable public func outEdges(of vertex: Vertex) -> OutEdges { OutEdges(_layout, _layout.number(of: vertex), _layout.rowEdges) }

    @inlinable
    public func source(ofEdgeAt position: Int) -> Vertex {
        precondition(position >= 0 && position < _layout.edgeCount, "Edge position out of range")
        return _layout.vertices[_layout.nodes[_layout.child(ofEdge: position)].parent]
    }

    @inlinable
    public func target(ofEdgeAt position: Int) -> Vertex {
        precondition(position >= 0 && position < _layout.edgeCount, "Edge position out of range")
        return _layout.vertices[_layout.child(ofEdge: position)]
    }

    @inlinable public func contains(_ vertex: Vertex) -> Bool { _layout.contains(vertex) }

    @inlinable
    public func contains(edge: DirectedEdge<Vertex>) -> Bool {
        guard _layout.contains(edge.source), _layout.contains(edge.target) else { return false }
        return _layout.nodes[_layout.number(of: edge.target)].parent == _layout.number(of: edge.source)
    }

    @inlinable public func outDegree(of vertex: Vertex) -> Int { OutEdges(_layout, _layout.number(of: vertex), _layout.rowEdges).count }

    @inlinable public var vertexIndexBound: Int? { _layout.count }
    @inlinable public func vertexIndex(of vertex: Vertex) -> Int { _layout.number(of: vertex) }
    @inlinable public func vertex(atIndex index: Int) -> Vertex { _layout.vertices[index] }
    @inlinable public func successorIndices(ofIndex index: Int) -> SuccessorIndices { OutEdges(_layout, index, _layout.rowNeighbors) }
    @inlinable public func outEdges(ofIndex index: Int) -> OutEdges { OutEdges(_layout, index, _layout.rowEdges) }
    @inlinable public var edgeIndexBound: Int? { _layout.edgeCount }
    @inlinable public func edgeIndex(of position: Int) -> Int { position }

    /// The parent's index, or nothing at the root.
    @inlinable
    public func predecessorIndices(ofIndex index: Int) -> PredecessorIndices { InEdges(_layout.nodes[index].parent) }

    /// The position of the edge from the parent, or nothing at the root.
    @inlinable
    public func inEdges(ofIndex index: Int) -> InEdges {
        let node = _layout.nodes[index]
        return InEdges(node.parent < 0 ? -1 : node.parentEdge)
    }

    @inlinable
    public func predecessors(of vertex: Vertex) -> Predecessors {
        let p = _layout.nodes[_layout.number(of: vertex)].parent
        return Predecessors(p < 0 ? nil : _layout.vertices[p])
    }

    @inlinable public func inEdges(of vertex: Vertex) -> InEdges { inEdges(ofIndex: _layout.number(of: vertex)) }
    @inlinable public func inDegree(of vertex: Vertex) -> Int { _layout.nodes[_layout.number(of: vertex)].parent < 0 ? 0 : 1 }
}

// MARK: - Equality, hashing, coding, descriptions

extension _TreeLayout {
    /// The (parent, child) ends of every edge, at its position.
    @inlinable
    func orientedEnds() -> [Int] {
        var result = [Int](repeating: 0, count: ends.count)
        for e in 0 ..< edgeCount {
            let c = child(ofEdge: e)
            result[2 * e] = nodes[c].parent
            result[2 * e + 1] = c
        }
        return result
    }
}

extension Arborescence: Equatable {
    /// Equal vertex sets and equal sets of directed edges (which fixes the root). O(n).
    @inlinable
    public static func == (lhs: Arborescence, rhs: Arborescence) -> Bool {
        let l = lhs._layout, r = rhs._layout
        guard l.count == r.count else { return false }
        var map = [Int](repeating: 0, count: l.count)
        for (i, v) in l.vertices.enumerated() {
            guard r.contains(v) else { return false }
            map[i] = r.number(of: v)
        }
        for c in 0 ..< l.count where l.nodes[c].parent >= 0 {
            guard r.nodes[map[c]].parent == map[l.nodes[c].parent] else { return false }
        }
        return true
    }
}

extension Arborescence: Hashable {
    @inlinable
    public func hash(into hasher: inout Hasher) {
        var vertexHashes = 0
        for v in _layout.vertices {
            var h = Hasher()
            h.combine(v)
            vertexHashes &+= h.finalize()
        }
        var edgeHashes = 0
        for edge in edges {
            var h = Hasher()
            h.combine(edge)
            edgeHashes &+= h.finalize()
        }
        hasher.combine(vertexCount)
        hasher.combine(vertexHashes)
        hasher.combine(edgeHashes)
    }
}

extension Arborescence: Sendable where Vertex: Sendable {}

extension Arborescence: Encodable where Vertex: Encodable {
    /// The vertices, then the edges by position as (source, target) offsets in that list: the
    /// `AdjacencyList` format.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: _TreeCodingKeys.self)
        try container.encode(Array(_layout.vertices), forKey: .vertices)
        try container.encode(_layout.orientedEnds(), forKey: .edges)
    }
}

extension Arborescence: Decodable where Vertex: Decodable {
    /// Throws `DecodingError.dataCorrupted` unless it is an arborescence.
    public init(from decoder: any Decoder) throws {
        let (vertices, slots, dense, ends, _) = try _TreeLayout<Vertex>.decode(from: decoder)
        guard let layout = _TreeLayout<Vertex>.arborescence(vertices: vertices, slots: slots, dense: dense, ends: ends) else {
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Not an arborescence"))
        }
        _layout = layout
    }
}

extension Arborescence: CustomStringConvertible, CustomDebugStringConvertible {
    /// The vertices and the edges, at most 16 of each: `[0, 1, 2]; [0→1, 0→2]`.
    public var description: String {
        GraphDescription.graph(vertices: vertices, vertexCount: vertexCount, edges: edges, edgeCount: edgeCount)
    }

    /// The type, the counts, the root, and at most 16 vertices and edges.
    public var debugDescription: String {
        "Arborescence<\(Vertex.self)>(vertexCount: \(vertexCount), edgeCount: \(edgeCount), root: \(String(reflecting: root)), vertices: "
            + GraphDescription.list(vertices, count: vertexCount) { String(reflecting: $0) }
            + ", edges: "
            + GraphDescription.list(edges, count: edgeCount) { GraphDescription.edge($0) }
            + ")"
    }
}
