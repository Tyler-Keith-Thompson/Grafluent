import GraphProtocols

/// A partition of a graph's vertices into components, in a documented order: a collection of
/// components, each a slice of vertices in `vertices` order, with an O(1) `component(of:)`.
///
/// It keeps a copy of the graph to look vertices up through the graph's own vertex indices, so
/// `component(of:)` hashes nothing on a graph whose indices are its vertices. The copy shares
/// storage (copy-on-write), so making it is O(1), and later changes to the original do not affect
/// the result. The cost comes later: while the result is alive, the next mutation of the original
/// copies the whole graph, as it would with any other copy. Drop the result, or keep only what
/// you need from it (`Array(components)`), before mutating the graph.
///
/// A component's slice keeps the indices of the flat storage it is cut from, as
/// `CompressedSparseRow.successors(of:)` does: use `first`, iteration or `Array(_:)`, not `[0]`.
///
/// Because its type names the graph's type, a result cannot be returned through an existential
/// `any DirectedGraph`: call it from a generic function (`some DirectedGraph`) instead.
@frozen
public struct Components<Graph: DirectedGraph>: RandomAccessCollection {
    public typealias Index = Int
    public typealias Element = ArraySlice<Graph.Vertex>
    public typealias Indices = Range<Int>

    @usableFromInline let _vertices: _DenseVertices<Graph>
    /// The component of each vertex, by vertex number.
    @usableFromInline let _labels: [Int]
    /// Every vertex, component by component; component `c` is `_members[_offsets[c] ..< _offsets[c + 1]]`.
    @usableFromInline let _members: [Graph.Vertex]
    @usableFromInline let _offsets: [Int]

    /// Components from a label per vertex number, labels in `0..<count`.
    @inlinable
    init(vertices: _DenseVertices<Graph>, labels: [Int], count: Int) {
        // Group by label, each group in increasing vertex number, which is `vertices` order:
        // count each group into the slot of the group after it, sum to get each group's start,
        // place the vertices advancing the starts to the ends, and shift the ends up a slot.
        var offsets = [Int](repeating: 0, count: count + 1)
        _members = offsets.withUnsafeMutableBufferPointer { offsets in
            labels.withUnsafeBufferPointer { labels in
                for label in labels { offsets[label + 1] += 1 }
                for c in 0 ..< count { offsets[c + 1] += offsets[c] }
                let members = [Graph.Vertex](unsafeUninitializedCapacity: labels.count) { buffer, initialized in
                    for v in 0 ..< labels.count {
                        let label = labels[v]
                        (buffer.baseAddress! + offsets[label]).initialize(to: vertices.vertex(v))
                        offsets[label] += 1
                    }
                    initialized = labels.count
                }
                var c = count
                while c > 0 {
                    offsets[c] = offsets[c - 1]
                    c -= 1
                }
                if count > 0 { offsets[0] = 0 }
                return members
            }
        }
        _vertices = vertices
        _labels = labels
        _offsets = offsets
    }

    /// Components already grouped by `_groups(labels:count:)`.
    @inlinable
    init(vertices: _DenseVertices<Graph>, labels: [Int], offsets: [Int], order: [Int]) {
        _vertices = vertices
        _labels = labels
        _members = order.map { vertices.vertex($0) }
        _offsets = offsets
    }

    @inlinable public var startIndex: Int { 0 }
    @inlinable public var endIndex: Int { _offsets.count - 1 }

    /// The vertices of the component at `position`, in `vertices` order.
    @inlinable
    public subscript(position: Int) -> ArraySlice<Graph.Vertex> {
        precondition(position >= 0 && position < endIndex, "Component position out of range")
        return _members[_offsets[position] ..< _offsets[position + 1]]
    }

    /// The position of the component containing `vertex`: O(1) after the graph's
    /// `vertexIndex(of:)`, which is free on `AdjacencyMatrix` and `CompressedSparseRow` and one
    /// hash on `AdjacencyList`; one hash for a graph without vertex indices.
    ///
    /// - Precondition: `vertex` is a vertex of the graph these components were computed from.
    @inlinable
    public func component(of vertex: Graph.Vertex) -> Int {
        let number = _vertices.number(of: vertex)
        precondition(number >= 0 && number < _labels.count, "\(vertex) is not a vertex of the graph")
        return _labels[number]
    }

    /// The position of the component containing the vertex at `index`, for algorithms working in
    /// index space.
    ///
    /// - Precondition: the graph has vertex indices, and `index` is in `0..<vertexIndexBound`.
    @inlinable
    public func component(ofIndex index: Int) -> Int {
        precondition(_vertices.isIndexed, "\(Graph.self) has no vertex indices")
        precondition(index >= 0 && index < _labels.count, "Vertex index \(index) out of range")
        return _labels[index]
    }
}

extension Components: Equatable {
    /// Whether both partitions have the same components in the same order. The graphs they were
    /// computed from are not compared.
    @inlinable
    public static func == (lhs: Components, rhs: Components) -> Bool {
        lhs._offsets == rhs._offsets && lhs._members == rhs._members
    }
}

extension Components: Sendable where Graph: Sendable, Graph.Vertex: Sendable {}

extension Components: CustomStringConvertible {
    public var description: String {
        "[" + map { "[" + $0.map { "\($0)" }.joined(separator: ", ") + "]" }.joined(separator: ", ") + "]"
    }
}
