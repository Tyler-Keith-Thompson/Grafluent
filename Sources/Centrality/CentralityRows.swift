import GraphProtocols
import PriorityQueueModule

/// A graph's arcs in index space: vertex `v`'s out-arcs are slots `offsets[v] ..< offsets[v + 1]`
/// of `targets`, in row order, and, when the measure reads weights, of `edges` (the edge's
/// number: its offset in `edges`); `edges` is empty otherwise. Self-loops are kept (an undirected
/// loop twice, as its row lists it) for the matrix measures; the searches never cross them.
@frozen
@usableFromInline
struct _CentralityRows: Sendable {
    @usableFromInline var offsets: [Int]
    @usableFromInline var targets: [Int]
    @usableFromInline var edges: [Int]

    @inlinable
    init(offsets: [Int], targets: [Int], edges: [Int]) {
        self.offsets = offsets
        self.targets = targets
        self.edges = edges
    }

    @inlinable
    var count: Int { offsets.count - 1 }

    /// The reversed arcs, each source's in-arcs in increasing source index, then row order.
    @inlinable
    func transposed() -> _CentralityRows {
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
        return _CentralityRows(offsets: start, targets: reversedTargets, edges: reversedEdges)
    }

    /// The weight of each slot, from the weights by edge number.
    @inlinable
    func slotWeights<W>(_ weights: [W]) -> [W] { edges.map { weights[$0] } }
}

/// Copies an undirected graph's rows: every edge end, a loop twice; edge numbers only when
/// `readsEdges`.
@frozen
@usableFromInline
struct _CopyCentralityRows: _UndirectedRowsAlgorithm {
    @usableFromInline let readsEdges: Bool

    @inlinable
    init(readsEdges: Bool) { self.readsEdges = readsEdges }

    @inlinable
    func run<Rows: _IncidenceRowSource>(count n: Int, edgeCount: Int, _ rows: inout Rows) -> _CentralityRows {
        var offsets = [Int](repeating: 0, count: n + 1)
        var targets: [Int] = [], edges: [Int] = []
        targets.reserveCapacity(2 * edgeCount)
        if readsEdges { edges.reserveCapacity(2 * edgeCount) }
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
        return _CentralityRows(offsets: offsets, targets: targets, edges: edges)
    }
}

/// Each edge's weight by number, read once in position order and checked by `valid`.
@inlinable
func _readWeights<Positions: Sequence, W>(_ positions: Positions, count: Int, _ weight: (Positions.Element) -> W, _ valid: (W) -> Bool, _ message: @autoclosure () -> String) -> [W] {
    var weights: [W] = []
    weights.reserveCapacity(count)
    for position in positions {
        let w = weight(position)
        precondition(valid(w), message())
        weights.append(w)
    }
    return weights
}

/// The vertex numbers of a graph without vertex indices: positions in `listed`.
@inlinable
func _vertexNumbers<V: Hashable>(_ listed: [V]) -> [V: Int] {
    var numbers: [V: Int] = [:]
    numbers.reserveCapacity(listed.count)
    for (i, v) in listed.enumerated() { numbers[v] = i }
    return numbers
}

/// The number of `vertex`: from `numbers`, or its vertex index.
@inlinable
func _number<V>(of vertex: V, _ numbers: [V: Int]?, contains: (V) -> Bool, index: (V) -> Int) -> Int {
    if let numbers {
        guard let v = numbers[vertex] else { preconditionFailure("The vertex is not in the graph") }
        return v
    }
    precondition(contains(vertex), "The vertex is not in the graph")
    return index(vertex)
}

extension Graph {
    @inlinable
    func _centralityRows(readsEdges: Bool) -> _CentralityRows {
        _runOnUndirectedRows(_CopyCentralityRows(readsEdges: readsEdges))
    }

    /// Vertex numbers for a result: nil when the graph has vertex indices.
    @inlinable
    func _centralityNumbers() -> [Vertex: Int]? { _listedVertices().map(_vertexNumbers) }

    @inlinable
    func _centralityNumber(of vertex: Vertex, _ numbers: [Vertex: Int]?) -> Int {
        _number(of: vertex, numbers, contains: contains, index: vertexIndex(of:))
    }

    @inlinable
    func _centralityWeights<W>(_ weight: (Edges.Index) -> W, _ valid: (W) -> Bool, _ message: @autoclosure () -> String) -> [W] {
        _readWeights(edges.indices, count: edgeCount, weight, valid, message())
    }
}

extension DirectedGraph {
    /// The rows (edge numbers only when `readsEdges`), and the vertex numbers when the graph has
    /// no vertex indices. Rows a representation lends (compressed sparse row) are copied whole.
    @inlinable
    func _centralityRows(readsEdges: Bool) -> (rows: _CentralityRows, numbers: [Vertex: Int]?) {
        if let n = vertexIndexBound {
            if Edges.Index.self == Int.self, let rows = _withSuccessorIndexRows({ offsets, targets in
                // Slot k is the edge with index k.
                _CentralityRows(offsets: Array(offsets), targets: Array(targets), edges: readsEdges ? Array(0 ..< targets.count) : [])
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
                return (_CentralityRows(offsets: offsets, targets: targets, edges: []), nil)
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
            return (_CentralityRows(offsets: offsets, targets: targets, edges: edges), nil)
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
        return (_CentralityRows(offsets: offsets, targets: targets, edges: edges), vertexNumbers)
    }

    /// Each edge position's offset in `edges`.
    @inlinable
    func _edgeNumbers() -> [Edges.Index: Int] {
        var numbers: [Edges.Index: Int] = [:]
        numbers.reserveCapacity(edgeCount)
        for (k, position) in edges.indices.enumerated() { numbers[position] = k }
        return numbers
    }

    /// Vertex numbers for a result: nil when the graph has vertex indices.
    @inlinable
    func _centralityNumbers() -> [Vertex: Int]? { _listedVertices().map(_vertexNumbers) }

    @inlinable
    func _centralityNumber(of vertex: Vertex, _ numbers: [Vertex: Int]?) -> Int {
        _number(of: vertex, numbers, contains: contains, index: vertexIndex(of:))
    }

    @inlinable
    func _centralityWeights<W>(_ weight: (Edges.Index) -> W, _ valid: (W) -> Bool, _ message: @autoclosure () -> String) -> [W] {
        _readWeights(edges.indices, count: edgeCount, weight, valid, message())
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
        precondition(_graph.contains(vertex), "The vertex is not in the graph")
        return _scores[_graph.vertexIndex(of: vertex)]
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
