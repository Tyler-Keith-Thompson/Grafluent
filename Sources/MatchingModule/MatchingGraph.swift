import GraphProtocols

/// An undirected graph in index space for the matching algorithms: the rows (each edge end in
/// `incidentEdges` order, a self-loop twice) with edge numbers (offsets in `edges`, which is the
/// order weights are read in), and each edge's ends by number.
@frozen
@usableFromInline
package struct _MatchingGraph: Sendable {
    @usableFromInline package let count: Int
    @usableFromInline package var offsets: [Int]
    @usableFromInline package var targets: [Int]
    @usableFromInline package var edges: [Int]
    @usableFromInline package var from: [Int]
    @usableFromInline package var to: [Int]

    @inlinable
    package init(count: Int, offsets: [Int], targets: [Int], edges: [Int], from: [Int], to: [Int]) {
        self.count = count
        self.offsets = offsets
        self.targets = targets
        self.edges = edges
        self.from = from
        self.to = to
    }

    @inlinable
    package var edgeCount: Int { from.count }

    /// The far end of edge `e` from `v`.
    @inlinable
    package func opposite(_ v: Int, _ e: Int) -> Int { from[e] == v ? to[e] : from[e] }
}

/// Copies the rows with edge numbers, and each edge's ends (the end met first as `from`).
@frozen
@usableFromInline
struct _CopyMatchingGraph: _UndirectedRowsAlgorithm {
    @inlinable
    init() {}

    @inlinable
    func run<Rows: _IncidenceRowSource>(count n: Int, edgeCount: Int, _ rows: inout Rows) -> _MatchingGraph {
        var offsets = [Int](repeating: 0, count: n + 1)
        var targets: [Int] = [], edges: [Int] = []
        targets.reserveCapacity(2 * edgeCount)
        edges.reserveCapacity(2 * edgeCount)
        var from = [Int](repeating: -1, count: edgeCount), to = [Int](repeating: 0, count: edgeCount)
        for v in 0 ..< n {
            for k in 0 ..< rows.count(v) {
                let w = rows.neighbor(v, k), e = rows.edge(v, k)
                precondition(UInt(bitPattern: w) < UInt(bitPattern: n) && UInt(bitPattern: e) < UInt(bitPattern: edgeCount), "A neighbor or edge index is out of range")
                targets.append(w)
                edges.append(e)
                if from[e] < 0 {
                    from[e] = v
                    to[e] = w
                }
            }
            offsets[v + 1] = targets.count
        }
        return _MatchingGraph(count: n, offsets: offsets, targets: targets, edges: edges, from: from, to: to)
    }
}

extension Graph {
    @inlinable
    package func _matchingGraph() -> _MatchingGraph { _runOnUndirectedRows(_CopyMatchingGraph()) }

    /// The positions of edges given by number (offset in `edges`), ascending numbers in, ascending
    /// positions out, in one walk.
    @inlinable
    package func _matchingPositions(ofAscendingEdgeNumbers numbers: [Int]) -> [Edges.Index] {
        var result: [Edges.Index] = []
        result.reserveCapacity(numbers.count)
        var index = edges.startIndex, offset = 0
        for k in numbers {
            while offset < k {
                edges.formIndex(after: &index)
                offset += 1
            }
            result.append(index)
        }
        return result
    }

    /// Each edge's weight by number, read once in position order, for the edges `read` selects
    /// (self-loops are never weighed); `.zero` for the others.
    @inlinable
    func _matchingWeights<W: AdditiveArithmetic>(_ graph: _MatchingGraph, _ weight: (Edges.Index) -> W, _ valid: (W) -> Bool, _ message: @autoclosure () -> String) -> [W] {
        var weights = [W](repeating: .zero, count: graph.edgeCount)
        var e = 0
        for position in edges.indices {
            if graph.from[e] != graph.to[e] {
                let w = weight(position)
                precondition(valid(w), message())
                weights[e] = w
            }
            e += 1
        }
        return weights
    }
}
