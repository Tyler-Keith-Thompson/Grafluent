import GraphProtocols
import PriorityQueueModule

// The measures read a graph's arcs as `_CompressedRows`: in row order, with edge numbers
// (offsets in `edges`) only when they read weights. Self-loops are kept (an undirected loop
// twice, as its row lists it) for the matrix measures; the searches never cross them.

extension _CompressedRows {
    /// The reversed arcs, each source's in-arcs in increasing source index, then row order.
    @inlinable
    func transposed() -> _CompressedRows {
        let n = count
        let withEdges = !edges.isEmpty
        var start = [Int](repeating: 0, count: n + 1)
        for w in targets { start[w + 1] += 1 }
        for v in 0 ..< n { start[v + 1] += start[v] }
        var fill = start
        var reversedTargets = [Int](repeating: 0, count: targets.count)
        var reversedEdges = [Int](repeating: 0, count: edges.count)
        for v in 0 ..< n {
            for slot in offsets[v] ..< offsets[v + 1] {
                let w = targets[slot]
                reversedTargets[fill[w]] = v
                if withEdges { reversedEdges[fill[w]] = edges[slot] }
                fill[w] += 1
            }
        }
        return _CompressedRows(offsets: start, targets: reversedTargets, edges: reversedEdges)
    }

    /// The weight of each slot, from the weights by edge number.
    @inlinable
    func slotWeights<W>(_ weights: [W]) -> [W] { edges.map { weights[$0] } }
}

extension Graph {
    /// Every edge end, a loop twice; edge numbers only when `readsEdges`.
    @inlinable
    func _centralityRows(readsEdges: Bool) -> _CompressedRows {
        _runOnUndirectedRows(_CopyRows(readsEdges: readsEdges, dropsLoops: false))
    }
}

extension DirectedGraph {
    /// The rows (edge numbers only when `readsEdges`), and the vertex numbers when the graph has
    /// no vertex indices. Rows a representation lends (compressed sparse row) are copied whole.
    /// Kept rather than `_compressedRows(readsEdges:dropsLoops:)`: the shared builder made the
    /// copy from `successorIndices` about twice as slow (`pageRank()` on an `AdjacencyList` of
    /// 5·10⁵ arcs, +23%).
    @inlinable
    func _centralityRows(readsEdges: Bool) -> (rows: _CompressedRows, numbers: [Vertex: Int]?) {
        if let n = vertexIndexBound {
            if Edges.Index.self == Int.self, let rows = _withSuccessorIndexRows({ offsets, targets in
                // Slot k is the edge with index k.
                _CompressedRows(offsets: Array(offsets), targets: Array(targets), edges: readsEdges ? Array(0 ..< targets.count) : [])
            }) {
                return (rows, nil)
            }
            var offsets: [Int] = [0]
            var targets: [Int] = [], edges: [Int] = []
            offsets.reserveCapacity(n + 1)
            targets.reserveCapacity(edgeCount)
            guard readsEdges else {
                for v in 0 ..< n {
                    for w in successorIndices(ofIndex: v) {
                        precondition(UInt(bitPattern: w) < UInt(bitPattern: n), "A successor index is out of range")
                        targets.append(w)
                    }
                    offsets.append(targets.count)
                }
                return (_CompressedRows(offsets: offsets, targets: targets, edges: []), nil)
            }
            edges.reserveCapacity(edgeCount)
            let indexed = edgeIndexBound != nil
            let numbers = indexed ? [:] : _edgeNumbers()
            for v in 0 ..< n {
                var successors = successorIndices(ofIndex: v).makeIterator()
                for position in outEdges(ofIndex: v) {
                    guard let w = successors.next() else { preconditionFailure("successorIndices and outEdges differ in length") }
                    precondition(UInt(bitPattern: w) < UInt(bitPattern: n), "A successor index is out of range")
                    targets.append(w)
                    edges.append(indexed ? edgeIndex(of: position) : numbers[position]!)
                }
                precondition(successors.next() == nil, "successorIndices and outEdges differ in length")
                offsets.append(targets.count)
            }
            return (_CompressedRows(offsets: offsets, targets: targets, edges: edges), nil)
        }
        let listed = Array(vertices)
        let vertexNumbers = _vertexNumbers(listed)
        let indexed = edgeIndexBound != nil
        let numbers = !readsEdges || indexed ? [:] : _edgeNumbers()
        var offsets: [Int] = [0]
        var targets: [Int] = [], edges: [Int] = []
        offsets.reserveCapacity(listed.count + 1)
        targets.reserveCapacity(edgeCount)
        for v in listed {
            for position in outEdges(of: v) {
                targets.append(vertexNumbers[target(ofEdgeAt: position)]!)
                if readsEdges { edges.append(indexed ? edgeIndex(of: position) : numbers[position]!) }
            }
            offsets.append(targets.count)
        }
        return (_CompressedRows(offsets: offsets, targets: targets, edges: edges), vertexNumbers)
    }
}

/// A score per vertex (the README's "dense vector indexed by vertex"; JGraphT's
/// `VertexScoringAlgorithm`, igraph's scores): every centrality measure returns one.
@frozen
public struct CentralityScores<G: DirectedGraph> {
    @usableFromInline let _graph: G
    /// Vertex numbers when the graph has no vertex indices.
    @usableFromInline let _numbers: [G.Vertex: Int]?
    @usableFromInline let _scores: [Double]

    @inlinable
    init(_ graph: G, numbers: [G.Vertex: Int]?, scores: [Double]) {
        _graph = graph
        _numbers = numbers
        _scores = scores
    }

    /// The score of `vertex`. O(1) after looking it up.
    ///
    /// - Precondition: `vertex` is a vertex of the graph.
    @inlinable
    public func score(of vertex: G.Vertex) -> Double {
        if let _numbers {
            guard let v = _numbers[vertex] else { preconditionFailure("The vertex is not in the graph") }
            return _scores[v]
        }
        return _scores[_graph._requiredVertexIndex(of: vertex, "The vertex is not in the graph")]
    }

    /// The score of the vertex at `index` (its vertex index, or its position in `vertices` when the
    /// graph has no vertex indices).
    ///
    /// - Precondition: `index` is in `0..<vertexCount`.
    @inlinable
    public func score(ofIndex index: Int) -> Double {
        precondition(index >= 0 && index < _scores.count, "Vertex index out of range")
        return _scores[index]
    }

    /// Every score, in `vertices` order (by vertex index). O(1).
    @inlinable
    public var scores: [Double] { _scores }
}

/// Kleinberg's hub and authority scores, each summing to 1 (igraph's `hub_and_authority_scores`).
@frozen
public struct HubAndAuthorityScores<G: DirectedGraph> {
    /// How well each vertex points to good authorities.
    public let hubs: CentralityScores<G>
    /// How well each vertex is pointed to by good hubs.
    public let authorities: CentralityScores<G>

    @inlinable
    init(hubs: CentralityScores<G>, authorities: CentralityScores<G>) {
        self.hubs = hubs
        self.authorities = authorities
    }
}

extension CentralityScores: Sendable where G: Sendable, G.Vertex: Sendable {}
extension HubAndAuthorityScores: Sendable where G: Sendable, G.Vertex: Sendable {}
