import GraphProtocols

/// A directed multigraph as an ordered list of edges: an `Array` of `DirectedEdge` with graph
/// queries.
///
/// The list keeps every edge it is given, in order: parallel edges are distinct elements, and an
/// edge's position is its identity, so values that belong to the edges (weights, capacities) can
/// live in an array indexed the same way. Mutation follows `Array`: removing an edge shifts the
/// later ones down, never moving an edge out of order.
///
/// The vertices are the endpoints of the edges. An edge list has no vertex set of its own, so it
/// cannot hold an isolated vertex; conversions that need one take the vertices or a vertex count
/// separately. Graph queries scan the list, O(m), since nothing is indexed.
@frozen
public struct EdgeList<Vertex: Hashable> {
    @usableFromInline
    internal var _edges: ContiguousArray<DirectedEdge<Vertex>>

    @inlinable
    internal init(_edges: ContiguousArray<DirectedEdge<Vertex>>) {
        self._edges = _edges
    }

    /// The empty list.
    @inlinable
    public init() {
        _edges = []
    }

    /// A list of the given edges, in order, repeats included.
    @inlinable
    public init(_ edges: some Sequence<DirectedEdge<Vertex>>) {
        _edges = ContiguousArray(edges)
    }

    /// A list of parallel arrays: edge `i` goes from `sources[i]` to `targets[i]`.
    ///
    /// - Precondition: the arrays have the same length.
    @inlinable
    public init(sources: some Collection<Vertex>, targets: some Collection<Vertex>) {
        precondition(sources.count == targets.count, "\(sources.count) sources but \(targets.count) targets")
        _edges = ContiguousArray(zip(sources, targets).lazy.map { DirectedEdge(from: $0, to: $1) })
    }

    /// A list of the edges written in the builder, in order, repeats included.
    ///
    /// - Precondition: the builder lists no vertex on its own; an edge list has nowhere to keep one.
    @inlinable
    public init(@DirectedGraphBuilder<Vertex> _ content: () -> DirectedGraphBuilder<Vertex>.Content) {
        let content = content()
        precondition(content.vertices.isEmpty, "An EdgeList cannot hold an isolated vertex; list only edges")
        _edges = ContiguousArray(content.edges)
    }
}

extension EdgeList: ExpressibleByArrayLiteral {
    @inlinable
    public init(arrayLiteral elements: DirectedEdge<Vertex>...) {
        _edges = ContiguousArray(elements)
    }
}

// MARK: - Collection

extension EdgeList: RandomAccessCollection, MutableCollection, RangeReplaceableCollection {
    public typealias Element = DirectedEdge<Vertex>
    public typealias Index = Int
    public typealias Indices = Range<Int>
    public typealias SubSequence = Slice<EdgeList>

    @inlinable public var startIndex: Int { 0 }
    @inlinable public var endIndex: Int { _edges.count }
    @inlinable public var count: Int { _edges.count }
    @inlinable public var isEmpty: Bool { _edges.isEmpty }
    @inlinable public var indices: Range<Int> { 0 ..< _edges.count }

    @inlinable public func index(after i: Int) -> Int { i + 1 }
    @inlinable public func index(before i: Int) -> Int { i - 1 }

    @inlinable
    public subscript(position: Int) -> DirectedEdge<Vertex> {
        get { _edges[position] }
        _modify { yield &_edges[position] }
    }

    @inlinable
    public subscript(bounds: Range<Int>) -> Slice<EdgeList> {
        get {
            _failEarlyRangeCheck(bounds, bounds: startIndex ..< endIndex)
            return Slice(base: self, bounds: bounds)
        }
        set {
            replaceSubrange(bounds, with: newValue)
        }
        // Mutating a slice in place (`list[a..<b].sort()`) must not copy the whole list: the
        // storage moves into the slice for the duration, so the slice's base is unique.
        _modify {
            _failEarlyRangeCheck(bounds, bounds: startIndex ..< endIndex)
            let count = _edges.count
            var slice = Slice(base: EdgeList(_edges: _edges), bounds: bounds)
            _edges = []
            defer {
                let lower = slice.startIndex
                let upper = slice.endIndex
                var edges = slice.base._edges
                slice = Slice(base: EdgeList(), bounds: 0 ..< 0)
                // A slice narrowed by removeFirst or removeLast leaves base elements outside its
                // view; they are dropped, as assigning the slice back would drop them.
                edges.removeSubrange(upper ..< edges.count - (count - bounds.upperBound))
                edges.removeSubrange(bounds.lowerBound ..< lower)
                _edges = edges
            }
            yield &slice
        }
    }

    @inlinable
    public mutating func swapAt(_ i: Int, _ j: Int) {
        _edges.swapAt(i, j)
    }

    @inlinable
    public mutating func replaceSubrange(_ subrange: Range<Int>, with newElements: some Collection<DirectedEdge<Vertex>>) {
        _edges.replaceSubrange(subrange, with: newElements)
    }

    @inlinable
    public mutating func reserveCapacity(_ minimumCapacity: Int) {
        _edges.reserveCapacity(minimumCapacity)
    }

    @inlinable
    public mutating func append(_ newElement: DirectedEdge<Vertex>) {
        _edges.append(newElement)
    }

    @inlinable
    public mutating func append(contentsOf newElements: some Sequence<DirectedEdge<Vertex>>) {
        _edges.append(contentsOf: newElements)
    }

    @inlinable
    @discardableResult
    public mutating func remove(at position: Int) -> DirectedEdge<Vertex> {
        _edges.remove(at: position)
    }

    @inlinable
    public mutating func removeAll(keepingCapacity keepCapacity: Bool = false) {
        _edges.removeAll(keepingCapacity: keepCapacity)
    }

    @inlinable
    public mutating func removeAll(where shouldBeRemoved: (DirectedEdge<Vertex>) throws -> Bool) rethrows {
        try _edges.removeAll(where: shouldBeRemoved)
    }

    /// The number of edges the list can hold without reallocating.
    @inlinable
    public var capacity: Int { _edges.capacity }

    /// Shares the storage, so `Array(list)` and `EdgeList(list)` do not copy.
    @inlinable
    public func _copyToContiguousArray() -> ContiguousArray<DirectedEdge<Vertex>> {
        _edges
    }

    @inlinable
    public func withContiguousStorageIfAvailable<Result>(_ body: (UnsafeBufferPointer<DirectedEdge<Vertex>>) throws -> Result) rethrows -> Result? {
        try _edges.withUnsafeBufferPointer(body)
    }

    @inlinable
    public mutating func withContiguousMutableStorageIfAvailable<Result>(
        _ body: (inout UnsafeMutableBufferPointer<DirectedEdge<Vertex>>) throws -> Result
    ) rethrows -> Result? {
        try _edges.withUnsafeMutableBufferPointer(body)
    }
}

// MARK: - Graph queries

extension EdgeList {
    /// The edges: the list itself.
    @inlinable
    public var edges: EdgeList { self }

    /// The number of edges, repeats included. O(1).
    @inlinable
    public var edgeCount: Int { _edges.count }

    /// The endpoints of the edges, each once, in order of first appearance (a source before its
    /// edge's target). O(m).
    @inlinable
    public var vertices: [Vertex] {
        var seen = Set<Vertex>()
        var vertices: [Vertex] = []
        for edge in _edges {
            if seen.insert(edge.source).inserted { vertices.append(edge.source) }
            if seen.insert(edge.target).inserted { vertices.append(edge.target) }
        }
        return vertices
    }

    /// The number of distinct endpoints. O(m).
    @inlinable
    public var vertexCount: Int {
        var seen = Set<Vertex>()
        for edge in _edges {
            seen.insert(edge.source)
            seen.insert(edge.target)
        }
        return seen.count
    }

    /// Whether `vertex` is an endpoint of some edge. O(m).
    @inlinable
    public func contains(_ vertex: Vertex) -> Bool {
        _edges.contains { $0.source == vertex || $0.target == vertex }
    }

    /// Whether `edge` is in the list. O(m).
    @inlinable
    public func contains(edge: DirectedEdge<Vertex>) -> Bool {
        _edges.contains(edge)
    }

    /// The number of copies of `edge` in the list. O(m).
    @inlinable
    public func multiplicity(of edge: DirectedEdge<Vertex>) -> Int {
        var count = 0
        for e in _edges where e == edge { count += 1 }
        return count
    }

    /// The target of every edge leaving `vertex`, in edge order, once per edge; empty when `vertex`
    /// is not an endpoint. O(m).
    @inlinable
    public func successors(of vertex: Vertex) -> [Vertex] {
        var successors: [Vertex] = []
        for edge in _edges where edge.source == vertex { successors.append(edge.target) }
        return successors
    }

    /// The source of every edge entering `vertex`, in edge order, once per edge; empty when
    /// `vertex` is not an endpoint. O(m).
    @inlinable
    public func predecessors(of vertex: Vertex) -> [Vertex] {
        var predecessors: [Vertex] = []
        for edge in _edges where edge.target == vertex { predecessors.append(edge.source) }
        return predecessors
    }

    /// The number of edges leaving `vertex`, repeats included; 0 when it is not an endpoint. O(m).
    @inlinable
    public func outDegree(of vertex: Vertex) -> Int {
        var count = 0
        for edge in _edges where edge.source == vertex { count += 1 }
        return count
    }

    /// The number of edges entering `vertex`, repeats included; 0 when it is not an endpoint. O(m).
    @inlinable
    public func inDegree(of vertex: Vertex) -> Int {
        var count = 0
        for edge in _edges where edge.target == vertex { count += 1 }
        return count
    }

    /// `outDegree(of:) + inDegree(of:)`. A self-loop counts twice. O(m).
    @inlinable
    public func degree(of vertex: Vertex) -> Int {
        var count = 0
        for edge in _edges {
            if edge.source == vertex { count += 1 }
            if edge.target == vertex { count += 1 }
        }
        return count
    }

    /// The out-degree of every endpoint, repeats included, in one O(m) pass.
    @inlinable
    public var outDegrees: [Vertex: Int] {
        var degrees: [Vertex: Int] = [:]
        for edge in _edges {
            degrees[edge.source, default: 0] += 1
            if degrees[edge.target] == nil { degrees[edge.target] = 0 }
        }
        return degrees
    }

    /// The in-degree of every endpoint, repeats included, in one O(m) pass.
    @inlinable
    public var inDegrees: [Vertex: Int] {
        var degrees: [Vertex: Int] = [:]
        for edge in _edges {
            if degrees[edge.source] == nil { degrees[edge.source] = 0 }
            degrees[edge.target, default: 0] += 1
        }
        return degrees
    }

    /// The number of copies of every distinct edge, in one O(m) pass.
    @inlinable
    public var multiplicities: [DirectedEdge<Vertex>: Int] {
        var counts: [DirectedEdge<Vertex>: Int] = [:]
        for edge in _edges { counts[edge, default: 0] += 1 }
        return counts
    }

    /// The list with every edge reversed, in the same order. O(m).
    @inlinable
    public func transposed() -> EdgeList {
        EdgeList(_edges: ContiguousArray(_edges.lazy.map { DirectedEdge(from: $0.target, to: $0.source) }))
    }
}

// MARK: - Graph mutation

extension EdgeList {
    /// Reverses every edge in place, keeping the order. O(m).
    @inlinable
    public mutating func transpose() {
        for i in _edges.indices {
            _edges[i] = DirectedEdge(from: _edges[i].target, to: _edges[i].source)
        }
    }

    /// Removes every edge leaving `vertex`, keeping the rest in order. O(m).
    ///
    /// - Returns: How many edges were removed.
    @inlinable
    @discardableResult
    public mutating func removeEdges(from vertex: Vertex) -> Int {
        guard _edges.contains(where: { $0.source == vertex }) else { return 0 }
        let before = _edges.count
        _edges.removeAll { $0.source == vertex }
        return before - _edges.count
    }

    /// Removes every edge entering `vertex`, keeping the rest in order. O(m).
    ///
    /// - Returns: How many edges were removed.
    @inlinable
    @discardableResult
    public mutating func removeEdges(to vertex: Vertex) -> Int {
        guard _edges.contains(where: { $0.target == vertex }) else { return 0 }
        let before = _edges.count
        _edges.removeAll { $0.target == vertex }
        return before - _edges.count
    }

    /// Removes the first copy of `edge`. O(m).
    ///
    /// - Returns: The removed edge, as the list stored it, or `nil` if `edge` was not in the list.
    @inlinable
    @discardableResult
    public mutating func remove(edge: DirectedEdge<Vertex>) -> DirectedEdge<Vertex>? {
        // Searched before removing, so removing an absent edge never copies shared storage.
        guard let i = _edges.firstIndex(of: edge) else { return nil }
        return _edges.remove(at: i)
    }

    /// Removes every edge with `vertex` as an endpoint, keeping the rest in order. O(m).
    ///
    /// - Returns: How many edges were removed (a self-loop counts once).
    @inlinable
    @discardableResult
    public mutating func removeEdges(incidentTo vertex: Vertex) -> Int {
        guard contains(vertex) else { return 0 }
        let before = _edges.count
        _edges.removeAll { $0.source == vertex || $0.target == vertex }
        return before - _edges.count
    }
}

// MARK: - Conformances

extension EdgeList: Equatable {
    /// Equal when the edges are equal in order, as for `Array`. Order-free comparisons go through
    /// `Set`, sorting, or an `AdjacencyList`.
    @inlinable
    public static func == (lhs: EdgeList, rhs: EdgeList) -> Bool {
        lhs._edges == rhs._edges
    }
}

extension EdgeList: Hashable {
    @inlinable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(_edges)
    }
}

extension EdgeList: Sendable where Vertex: Sendable {}

extension EdgeList: Encodable where Vertex: Encodable {
    /// Encodes the endpoints as one flat array: `[s₀, t₀, s₁, t₁, …]`.
    public func encode(to encoder: any Encoder) throws {
        var endpoints: [Vertex] = []
        endpoints.reserveCapacity(2 * _edges.count)
        for edge in _edges {
            endpoints.append(edge.source)
            endpoints.append(edge.target)
        }
        // One array, rather than one element at a time, takes the encoders' fast paths.
        var container = encoder.singleValueContainer()
        try container.encode(endpoints)
    }
}

extension EdgeList: Decodable where Vertex: Decodable {
    /// Decodes a flat array of endpoints; an odd count is corrupt data.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let endpoints = try container.decode([Vertex].self)
        guard endpoints.count.isMultiple(of: 2) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "An edge list needs an even number of endpoints")
        }
        var edges = ContiguousArray<DirectedEdge<Vertex>>()
        edges.reserveCapacity(endpoints.count / 2)
        var k = 0
        while k < endpoints.count {
            edges.append(DirectedEdge(from: endpoints[k], to: endpoints[k + 1]))
            k += 2
        }
        self.init(_edges: edges)
    }
}

extension EdgeList: CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable {
    /// The vertices and the edges, at most 16 of each: `[0, 1, 2]; [0→1, 1→2]`. The same form as
    /// every other representation.
    public var description: String {
        // Only the first 16 vertices are printed, so the scan stops once a 17th is seen.
        var seen = Set<Vertex>()
        var vertices: [Vertex] = []
        for edge in _edges {
            if vertices.count > GraphDescription.limit { break }
            if seen.insert(edge.source).inserted { vertices.append(edge.source) }
            if seen.insert(edge.target).inserted { vertices.append(edge.target) }
        }
        return GraphDescription.graph(vertices: vertices, vertexCount: vertices.count, edges: _edges, edgeCount: _edges.count)
    }

    /// The type, the counts, and at most 16 vertices and edges.
    public var debugDescription: String {
        let vertices = vertices
        return "EdgeList<\(Vertex.self)>(vertexCount: \(vertices.count), edgeCount: \(_edges.count), vertices: "
            + GraphDescription.list(vertices, count: vertices.count) { String(reflecting: $0) }
            + ", edges: "
            + GraphDescription.list(_edges, count: _edges.count) { GraphDescription.edge($0) }
            + ")"
    }

    /// One child per edge, as for an `Array`.
    public var customMirror: Mirror {
        Mirror(self, unlabeledChildren: Array(_edges), displayStyle: .collection)
    }
}

// MARK: - DirectedGraph

// An edge list is not itself a `DirectedGraph`: every adjacency query is an O(m) scan, so a generic
// traversal over it would be O(n·m). Boost's `edge_list` models only `EdgeListGraph` for the same
// reason. Convert first, to an `AdjacencyList` or a `CompressedSparseRow`.

extension EdgeList {
    /// The edges of any directed graph, in the order of its `edges`.
    @inlinable
    public init(_ graph: some DirectedGraph<Vertex>) {
        self.init(graph.edges)
    }
}
