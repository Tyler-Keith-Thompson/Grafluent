import GraphProtocols

/// A partition of a graph's vertices into communities, in canonical order: communities by their
/// least vertex (in `vertices` order), each community's vertices in `vertices` order. So two
/// partitions with the same communities are equal, whatever algorithm made them.
///
/// It keeps a copy of the graph to look vertices up through the graph's own vertex indices. The
/// copy shares storage (copy-on-write), so making it is O(1); while the result is alive, the next
/// mutation of the original copies the whole graph. Keep only what you need
/// (`Array(partition.map(Array.init))`) before mutating the graph.
///
/// A community's slice keeps the indices of the flat storage it is cut from: use `first`,
/// iteration or `Array(_:)`, not `[0]`. Because its type names the graph's type, a result cannot
/// be returned through an existential `any DirectedGraph`.
@frozen
public struct Partition<G: DirectedGraph>: RandomAccessCollection {
    public typealias Index = Int
    public typealias Element = ArraySlice<G.Vertex>
    public typealias Indices = Range<Int>

    @usableFromInline let _graph: G
    /// Vertex numbers when the graph has no vertex indices.
    @usableFromInline let _numbers: [G.Vertex: Int]?
    /// The community of each vertex, by vertex number.
    @usableFromInline let _labels: [Int]
    /// Every vertex, community by community; community `c` is `_members[_offsets[c] ..< _offsets[c + 1]]`.
    @usableFromInline let _members: [G.Vertex]
    @usableFromInline let _offsets: [Int]

    /// The partition given by any label per vertex number: communities numbered by first
    /// appearance in vertex order, which is the order of their least vertices.
    @inlinable
    init(_ graph: G, numbers: [G.Vertex: Int]?, listed: [G.Vertex]?, labels: [Int]) {
        let n = labels.count
        var renumber = [Int](repeating: -1, count: n)
        var canonical = [Int](repeating: 0, count: n)
        var count = 0
        for v in 0 ..< n {
            let label = labels[v]
            if renumber[label] < 0 {
                renumber[label] = count
                count += 1
            }
            canonical[v] = renumber[label]
        }
        var offsets = [Int](repeating: 0, count: count + 1)
        for c in canonical { offsets[c + 1] += 1 }
        for c in 0 ..< count { offsets[c + 1] += offsets[c] }
        var fill = offsets
        var order = [Int](repeating: 0, count: n)
        for v in 0 ..< n {
            order[fill[canonical[v]]] = v
            fill[canonical[v]] += 1
        }
        _graph = graph
        _numbers = numbers
        _labels = canonical
        _members = order.map { listed?[$0] ?? graph.vertex(atIndex: $0) }
        _offsets = offsets
    }

    @inlinable public var startIndex: Int { 0 }
    @inlinable public var endIndex: Int { _offsets.count - 1 }

    /// The vertices of the community at `position`, in `vertices` order.
    @inlinable
    public subscript(position: Int) -> ArraySlice<G.Vertex> {
        precondition(position >= 0 && position < endIndex, "Community position out of range")
        return _members[_offsets[position] ..< _offsets[position + 1]]
    }

    /// The position of the community containing `vertex`: O(1) after the graph's
    /// `vertexIndex(of:)` (one hash for a graph without vertex indices).
    ///
    /// - Precondition: `vertex` is a vertex of the graph.
    @inlinable
    public func community(of vertex: G.Vertex) -> Int {
        if let _numbers {
            guard let v = _numbers[vertex] else { preconditionFailure("\(vertex) is not a vertex of the graph") }
            return _labels[v]
        }
        precondition(_graph.contains(vertex), "\(vertex) is not a vertex of the graph")
        return _labels[_graph.vertexIndex(of: vertex)]
    }

    /// The position of the community containing the vertex at `index`: its vertex index, or its
    /// position in `vertices` when the graph has no vertex indices.
    ///
    /// - Precondition: `index` is in `0..<vertexCount`.
    @inlinable
    public func community(ofIndex index: Int) -> Int {
        precondition(index >= 0 && index < _labels.count, "Vertex index \(index) out of range")
        return _labels[index]
    }
}

extension Partition: Equatable {
    /// Whether both partitions have the same communities in the same order. The graphs they were
    /// computed from are not compared.
    @inlinable
    public static func == (lhs: Partition, rhs: Partition) -> Bool {
        lhs._offsets == rhs._offsets && lhs._members == rhs._members
    }
}

extension Partition: Sendable where G: Sendable, G.Vertex: Sendable {}

extension Partition: CustomStringConvertible {
    public var description: String {
        "[" + map { "[" + $0.map { "\($0)" }.joined(separator: ", ") + "]" }.joined(separator: ", ") + "]"
    }
}

/// How well a partition fits the graph (NetworkX `partition_quality`).
@frozen
public struct PartitionQuality: Hashable, Sendable {
    /// Edges with both ends in one community, over all edges (parallel copies each count, a
    /// self-loop is inside). NaN without edges.
    public var coverage: Double
    /// Vertex pairs {u, v} (ordered pairs when directed) in one community and adjacent, or in
    /// different communities and not adjacent, over all pairs; adjacency ignores parallel copies
    /// and self-loops. NaN with fewer than two vertices.
    public var performance: Double

    @inlinable
    public init(coverage: Double, performance: Double) {
        self.coverage = coverage
        self.performance = performance
    }
}
