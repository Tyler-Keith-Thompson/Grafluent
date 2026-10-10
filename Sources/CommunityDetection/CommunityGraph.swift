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

/// Copies an undirected graph's rows, with edge numbers when `readsEdges`.
@frozen
@usableFromInline
struct _CopyCommunityRows: _UndirectedRowsAlgorithm {
    @usableFromInline let readsEdges: Bool

    @inlinable
    init(readsEdges: Bool) { self.readsEdges = readsEdges }

    @inlinable
    func run<Rows: _IncidenceRowSource>(count n: Int, edgeCount: Int, _ rows: inout Rows) -> (offsets: [Int], targets: [Int], edges: [Int]) {
        var offsets = [Int](repeating: 0, count: n + 1)
        var targets: [Int] = [], edges: [Int] = []
        targets.reserveCapacity(2 * edgeCount)
        edges.reserveCapacity(2 * edgeCount)
        for v in 0 ..< n {
            for k in 0 ..< rows.count(v) {
                let w = rows.neighbor(v, k)
                precondition(UInt(bitPattern: w) < UInt(bitPattern: n), "A neighbor index is out of range")
                targets.append(w)
                if readsEdges {
                    let e = rows.edge(v, k)
                    precondition(UInt(bitPattern: e) < UInt(bitPattern: edgeCount), "An edge index is out of range")
                    edges.append(e)
                }
            }
            offsets[v + 1] = targets.count
        }
        return (offsets, targets, edges)
    }
}

/// Each edge's ends by edge number, the end met first in the rows as `from`, without copying the
/// rows.
@frozen
@usableFromInline
struct _CopyEdgeEnds: _UndirectedRowsAlgorithm {
    @inlinable
    init() {}

    @inlinable
    func run<Rows: _IncidenceRowSource>(count n: Int, edgeCount: Int, _ rows: inout Rows) -> (from: [Int], to: [Int]) {
        var from = [Int](repeating: -1, count: edgeCount), to = [Int](repeating: 0, count: edgeCount)
        from.withUnsafeMutableBufferPointer { from in
            to.withUnsafeMutableBufferPointer { to in
                for v in 0 ..< n {
                    for k in 0 ..< rows.count(v) {
                        let e = rows.edge(v, k)
                        precondition(UInt(bitPattern: e) < UInt(bitPattern: edgeCount), "An edge index is out of range")
                        if from[e] < 0 {
                            let w = rows.neighbor(v, k)
                            precondition(UInt(bitPattern: w) < UInt(bitPattern: n), "A neighbor index is out of range")
                            from[e] = v
                            to[e] = w
                        }
                    }
                }
            }
        }
        return (from, to)
    }
}

/// The vertex numbers of a graph without vertex indices: positions in `listed`.
@inlinable
func _communityNumbers<V: Hashable>(_ listed: [V]) -> [V: Int] {
    var numbers: [V: Int] = [:]
    numbers.reserveCapacity(listed.count)
    for (i, v) in listed.enumerated() { numbers[v] = i }
    return numbers
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
    func _communityNumbers() -> [Vertex: Int]? { _listedVertices().map(CommunityDetection._communityNumbers) }

    @inlinable
    func _communityNumber(of vertex: Vertex, _ numbers: [Vertex: Int]?) -> Int? {
        if let numbers { return numbers[vertex] }
        return contains(vertex) ? vertexIndex(of: vertex) : nil
    }

    /// Each edge's ends by edge number (the end met first in the rows as `from`), and the rows when
    /// `rows`. Read from the index-space rows, so no vertex is hashed.
    /// Each edge's ends by edge number, the end met first in the rows as `from`.
    @inlinable
    func _communityGraph() -> _CommunityGraph {
        let (from, to) = _runOnUndirectedRows(_CopyEdgeEnds())
        return _CommunityGraph(count: vertexCount, directed: false, from: from, to: to)
    }

    /// The rows alone, for label propagation (edge numbers only when the votes are weighted).
    @inlinable
    func _labelPropagationRows(readsEdges: Bool) -> _CommunityGraph {
        let (offsets, targets, edges) = _runOnUndirectedRows(_CopyCommunityRows(readsEdges: readsEdges))
        var graph = _CommunityGraph(count: offsets.count - 1, directed: false, from: [], to: [])
        graph.offsets = offsets
        graph.targets = targets
        graph.edges = edges
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
    func _communityNumbers() -> [Vertex: Int]? { _listedVertices().map(CommunityDetection._communityNumbers) }

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
            var edgeNumbers: [Edges.Index: Int] = [:]
            if !indexed {
                edgeNumbers.reserveCapacity(edgeCount)
                for (k, position) in edges.indices.enumerated() { edgeNumbers[position] = k }
            }
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
