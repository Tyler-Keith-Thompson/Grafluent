import GraphProtocols

/// A matching in an undirected graph: edges no two of which share an endpoint, as positions in the
/// graph's `edges`, with the sum of their weights (JGraphT's `Matching`). Never contains a
/// self-loop.
///
/// It keeps a copy of the graph to look vertices up (copy-on-write: O(1) to make; while the result
/// is alive, the next mutation of the original copies the graph). The positions are the graph's,
/// valid until it is mutated.
@frozen
public struct Matching<G: Graph, Weight: Comparable & AdditiveArithmetic> {
    @usableFromInline let _graph: G
    /// Vertex numbers when the graph has no vertex indices.
    @usableFromInline let _numbers: [G.Vertex: Int]?
    @usableFromInline let _listed: [G.Vertex]?
    /// Each vertex's mate by number, −1 when free.
    @usableFromInline let _mate: [Int]
    /// Each vertex's matched edge, as its offset in `edges`, −1 when free.
    @usableFromInline let _slot: [Int]

    /// The matched edges, ascending (in `edges` order).
    public let edges: [G.Edges.Index]

    /// The sum of the matched edges' weights in `edges` order; `edges.count` for the unweighted
    /// entry points.
    public let weight: Weight

    /// A matching from each vertex's matched edge number (−1 when free); the weight summed in edge
    /// order from `weights` by edge number, or `count` of the edge count when nil.
    @inlinable
    init(_ graph: G, listed: [G.Vertex]?, structure: _MatchingGraph, mateEdge: [Int], weights: [Weight]?, count: (Int) -> Weight = { _ in preconditionFailure("A weighted matching needs weights") }) {
        let n = structure.count
        var matched = [Bool](repeating: false, count: structure.edgeCount)
        var mate = [Int](repeating: -1, count: n)
        for v in 0 ..< n where mateEdge[v] >= 0 {
            let e = mateEdge[v]
            matched[e] = true
            mate[v] = structure.opposite(v, e)
        }
        var numbers: [Int] = []
        var slot = [Int](repeating: -1, count: n)
        for e in 0 ..< structure.edgeCount where matched[e] {
            slot[structure.from[e]] = numbers.count
            slot[structure.to[e]] = numbers.count
            numbers.append(e)
        }
        var total = Weight.zero
        if let weights {
            for e in numbers { total += weights[e] }
        } else {
            total = count(numbers.count)
        }
        _graph = graph
        _listed = listed
        if let listed {
            var table: [G.Vertex: Int] = [:]
            table.reserveCapacity(listed.count)
            for (i, v) in listed.enumerated() { table[v] = i }
            _numbers = table
        } else {
            _numbers = nil
        }
        _mate = mate
        _slot = slot
        edges = graph._matchingPositions(ofAscendingEdgeNumbers: numbers)
        weight = total
    }

    /// Whether every vertex is matched (true for the empty graph). O(1).
    @inlinable
    public var isPerfect: Bool { 2 * edges.count == _mate.count }

    @inlinable
    func _number(of vertex: G.Vertex) -> Int {
        if let _numbers {
            guard let v = _numbers[vertex] else { preconditionFailure("\(vertex) is not a vertex of the graph") }
            return v
        }
        precondition(_graph.contains(vertex), "\(vertex) is not a vertex of the graph")
        return _graph.vertexIndex(of: vertex)
    }

    /// The vertex matched to `vertex`, or nil when it is free. O(1) after the graph's
    /// `vertexIndex(of:)`.
    ///
    /// - Precondition: `vertex` is a vertex of the graph.
    @inlinable
    public func mate(of vertex: G.Vertex) -> G.Vertex? {
        let m = _mate[_number(of: vertex)]
        return m < 0 ? nil : (_listed?[m] ?? _graph.vertex(atIndex: m))
    }

    /// The matched edge at `vertex` (among parallel copies, the one in `edges`), or nil when free.
    ///
    /// - Precondition: `vertex` is a vertex of the graph.
    @inlinable
    public func matchedEdge(of vertex: G.Vertex) -> G.Edges.Index? {
        let s = _slot[_number(of: vertex)]
        return s < 0 ? nil : edges[s]
    }

    /// The mate of the vertex at `index` (its vertex index, or its position in `vertices` when the
    /// graph has no vertex indices), by the same numbering; nil when free.
    ///
    /// - Precondition: `index` is in `0..<vertexCount`.
    @inlinable
    public func mate(ofIndex index: Int) -> Int? {
        precondition(index >= 0 && index < _mate.count, "Vertex index \(index) out of range")
        let m = _mate[index]
        return m < 0 ? nil : m
    }
}

extension Matching: Equatable {
    /// The same edges and weight; the graphs are not compared.
    @inlinable
    public static func == (lhs: Matching, rhs: Matching) -> Bool { lhs.edges == rhs.edges && lhs.weight == rhs.weight }
}

extension Matching: Hashable where Weight: Hashable {
    @inlinable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(edges)
        hasher.combine(weight)
    }
}

extension Matching: Sendable where G: Sendable, G.Vertex: Sendable, G.Edges.Index: Sendable, Weight: Sendable {}

extension Matching: CustomStringConvertible {
    /// `{a–b, c–d}`: the matched edges in `edges` order.
    public var description: String {
        "{" + edges.map { position in
            let e = _graph.edges[position]
            return "\(e.u)–\(e.v)"
        }.joined(separator: ", ") + "}"
    }
}
