import GraphProtocols

/// A graph in index space for the community algorithms: each edge's ends by edge number (its
/// offset in `edges`, which is the order weights are read in), and, for undirected graphs, the rows
/// (each edge end in `incidentEdges` order, a loop twice) for label propagation's votes.
@frozen
@usableFromInline
struct _CommunityGraph: Sendable {
    @usableFromInline let count: Int
    @usableFromInline let directed: Bool
    @usableFromInline var from: [Int]
    @usableFromInline var to: [Int]
    @usableFromInline var offsets: [Int] = []
    @usableFromInline var targets: [Int] = []
    @usableFromInline var edges: [Int] = []

    @inlinable
    init(count: Int, directed: Bool, from: [Int], to: [Int]) {
        self.count = count
        self.directed = directed
        self.from = from
        self.to = to
    }

    @inlinable
    var edgeCount: Int { from.count }
}

/// Each edge's weight as `Double`, read once in position order and checked: finite, at least zero.
@inlinable
func _communityWeights<Positions: Sequence, W: BinaryFloatingPoint>(_ positions: Positions, count: Int, _ weight: (Positions.Element) -> W) -> [Double] {
    var weights: [Double] = []
    weights.reserveCapacity(count)
    for position in positions {
        let w = weight(position)
        precondition(w.isFinite && w >= 0, "Edge weights must be finite and at least zero")
        weights.append(Double(w))
    }
    return weights
}

@inlinable
func _checkResolution(_ resolution: Double) {
    precondition(resolution.isFinite && resolution >= 0, "The resolution must be finite and at least zero")
}

extension Graph {
    /// Vertex numbers when the graph has no vertex indices; nil when it has them.
    @inlinable
    func _communityNumbers() -> [Vertex: Int]? { _listedVertices().map(_vertexNumbers) }

    @inlinable
    func _communityNumber(of vertex: Vertex, _ numbers: [Vertex: Int]?) -> Int? {
        if let numbers { return numbers[vertex] }
        return contains(vertex) ? vertexIndex(of: vertex) : nil
    }

    /// Read from the index-space rows, so no vertex is hashed.
    /// Each edge's ends by edge number, the end met first in the rows as `from`.
    @inlinable
    func _communityGraph() -> _CommunityGraph {
        let (from, to) = _runOnUndirectedRows(_CopyEdgeEnds())
        return _CommunityGraph(count: vertexCount, directed: false, from: from, to: to)
    }

    /// The rows alone, for label propagation (edge numbers only when the votes are weighted).
    @inlinable
    func _labelPropagationRows(readsEdges: Bool) -> _CommunityGraph {
        let rows = _runOnUndirectedRows(_CopyRows(readsEdges: readsEdges, dropsLoops: false))
        var graph = _CommunityGraph(count: rows.count, directed: false, from: [], to: [])
        graph.offsets = rows.offsets
        graph.targets = rows.targets
        graph.edges = rows.edges
        return graph
    }

    @inlinable
    func _communityWeights<W: BinaryFloatingPoint>(_ weight: (Edges.Index) -> W) -> [Double] {
        CommunityDetection._communityWeights(edges.indices, count: edgeCount, weight)
    }
}

extension DirectedGraph {
    /// Vertex numbers when the graph has no vertex indices; nil when it has them.
    @inlinable
    func _communityNumbers() -> [Vertex: Int]? { _listedVertices().map(_vertexNumbers) }

    @inlinable
    func _communityNumber(of vertex: Vertex, _ numbers: [Vertex: Int]?) -> Int? {
        if let numbers { return numbers[vertex] }
        return contains(vertex) ? vertexIndex(of: vertex) : nil
    }

    /// Each arc's source and target by edge number: from the index-space rows when the graph has
    /// vertex indices, otherwise by looking the ends up.
    @inlinable
    func _communityGraph(_ numbers: [Vertex: Int]?) -> _CommunityGraph {
        var from = [Int](repeating: 0, count: edgeCount), to = [Int](repeating: 0, count: edgeCount)
        if let n = vertexIndexBound {
            let indexed = edgeIndexBound != nil
            let edgeNumbers = indexed ? [:] : _edgeNumbers()
            for v in 0 ..< n {
                var successors = successorIndices(ofIndex: v).makeIterator()
                for position in outEdges(ofIndex: v) {
                    guard let w = successors.next() else { preconditionFailure("successorIndices and outEdges differ in length") }
                    precondition(UInt(bitPattern: w) < UInt(bitPattern: n), "A successor index is out of range")
                    let e = indexed ? edgeIndex(of: position) : edgeNumbers[position]!
                    from[e] = v
                    to[e] = w
                }
            }
            return _CommunityGraph(count: n, directed: true, from: from, to: to)
        }
        for (e, position) in edges.indices.enumerated() {
            from[e] = numbers![source(ofEdgeAt: position)]!
            to[e] = numbers![target(ofEdgeAt: position)]!
        }
        return _CommunityGraph(count: vertexCount, directed: true, from: from, to: to)
    }

    @inlinable
    func _communityWeights<W: BinaryFloatingPoint>(_ weight: (Edges.Index) -> W) -> [Double] {
        CommunityDetection._communityWeights(edges.indices, count: edgeCount, weight)
    }
}
