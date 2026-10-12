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

    /// The graph on `0..<count` with edge `e` joining `from[e]` and `to[e]`, its rows in edge
    /// order (each edge appended to `from[e]`'s row, then to `to[e]`'s; a self-loop twice to one
    /// row): the rows of an adjacency list built by inserting the edges in that order. O(n + m).
    ///
    /// - Precondition: `from` and `to` are equally long, with every end in `0..<count`.
    @inlinable
    package init(count: Int, from: [Int], to: [Int]) {
        precondition(from.count == to.count, "from and to differ in length")
        var offsets = [Int](repeating: 0, count: count + 1)
        for e in 0 ..< from.count {
            precondition(UInt(bitPattern: from[e]) < UInt(bitPattern: count) && UInt(bitPattern: to[e]) < UInt(bitPattern: count), "An edge end is out of range")
            offsets[from[e] + 1] += 1
            offsets[to[e] + 1] += 1
        }
        for v in 0 ..< count { offsets[v + 1] += offsets[v] }
        var next = offsets
        var targets = [Int](repeating: 0, count: 2 * from.count), edges = [Int](repeating: 0, count: 2 * from.count)
        for e in 0 ..< from.count {
            let u = from[e], v = to[e]
            targets[next[u]] = v
            edges[next[u]] = e
            next[u] += 1
            targets[next[v]] = u
            edges[next[v]] = e
            next[v] += 1
        }
        self.init(count: count, offsets: offsets, targets: targets, edges: edges, from: from, to: to)
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
