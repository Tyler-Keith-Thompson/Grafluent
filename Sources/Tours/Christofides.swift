import GraphProtocols
import MatchingModule
import Walks

/// Rows held as flat arrays, for Hierholzer on the tree-and-matching multigraph.
@frozen
@usableFromInline
struct _FlatIncidenceRows: _IncidenceRowSource {
    @usableFromInline let offsets: [Int]
    @usableFromInline let targets: [Int]
    @usableFromInline let edges: [Int]

    @inlinable
    init(offsets: [Int], targets: [Int], edges: [Int]) {
        self.offsets = offsets
        self.targets = targets
        self.edges = edges
    }

    @inlinable @inline(__always)
    mutating func count(_ v: Int) -> Int { offsets[v + 1] - offsets[v] }

    @inlinable @inline(__always)
    mutating func neighbor(_ v: Int, _ k: Int) -> Int { targets[offsets[v] + k] }

    @inlinable @inline(__always)
    mutating func edge(_ v: Int, _ k: Int) -> Int { edges[offsets[v] + k] }
}

/// Christofides' order, each piece pinned: the canonical minimum spanning tree of the simple
/// graph (Prim on the matrix under the strict order (weight, edge number), whose tree is the
/// unique one Kruskal gives under it, SpanningTrees' `minimumSpanningTree(weight:)`); its
/// odd-degree vertices in vertex order; the minimum-weight perfect matching on their complete
/// graph (pairs i < j lexicographic) by MatchingModule's Galil blossom, NetworkX's
/// `min_weight_matching`; the multigraph of the tree edges in edge order, then the matched pairs
/// in pair order; Hierholzer from vertex 0; the first visit of each vertex kept.
@inlinable
func _christofidesOrder<W: SignedNumeric & Comparable>(_ matrix: _TourMatrix<W>, half: (W) -> W, valid: (W) -> Bool) -> [Int] {
    let n = matrix.n
    let d = matrix.weights, numbers = matrix.edges
    // Dense Prim from vertex 0: each outside vertex's lightest edge to the tree.
    var inTree = [Bool](repeating: false, count: n)
    var key = [W](repeating: .zero, count: n), keyEdge = [Int](repeating: -1, count: n), parent = [Int](repeating: 0, count: n)
    inTree[0] = true
    for v in 1 ..< n {
        key[v] = d[v]
        keyEdge[v] = numbers[v]
    }
    var treeEdges: [(edge: Int, u: Int, v: Int)] = []
    treeEdges.reserveCapacity(n - 1)
    var degree = [Int](repeating: 0, count: n)
    for _ in 1 ..< n {
        var best = -1
        for v in 1 ..< n where !inTree[v] {
            if best < 0 || key[v] < key[best] || (!(key[best] < key[v]) && keyEdge[v] < keyEdge[best]) { best = v }
        }
        inTree[best] = true
        treeEdges.append((keyEdge[best], parent[best], best))
        degree[best] += 1
        degree[parent[best]] += 1
        let row = best * n
        for v in 1 ..< n where !inTree[v] {
            let w = d[row + v], e = numbers[row + v]
            if w < key[v] || (!(key[v] < w) && e < keyEdge[v]) {
                key[v] = w
                keyEdge[v] = e
                parent[v] = best
            }
        }
    }
    treeEdges.sort { $0.edge < $1.edge }
    var odd: [Int] = []
    for v in 0 ..< n where degree[v] & 1 != 0 { odd.append(v) }
    // The complete graph on the odd vertices, pairs i < j lexicographic.
    let k = odd.count
    var from: [Int] = [], to: [Int] = [], pairWeights: [W] = []
    from.reserveCapacity(k * (k - 1) / 2)
    to.reserveCapacity(k * (k - 1) / 2)
    pairWeights.reserveCapacity(k * (k - 1) / 2)
    for a in 0 ..< k {
        for b in a + 1 ..< k {
            from.append(a)
            to.append(b)
            let w = d[odd[a] * n + odd[b]]
            precondition(valid(w), "A weight is infinite or larger in magnitude than greatestFiniteMagnitude / 8")
            pairWeights.append(w)
        }
    }
    let mates = _minimumWeightMatchingEdges(_MatchingGraph(count: k, from: from, to: to), pairWeights, half: half)
    // The multigraph: tree edges, then matched pairs, each appended to both ends' rows in order.
    var ends: [(Int, Int)] = treeEdges.map { ($0.u, $0.v) }
    for p in 0 ..< from.count where mates[from[p]] == p { ends.append((odd[from[p]], odd[to[p]])) }
    var offsets = [Int](repeating: 0, count: n + 1)
    for (u, v) in ends {
        offsets[u + 1] += 1
        offsets[v + 1] += 1
    }
    for v in 0 ..< n { offsets[v + 1] += offsets[v] }
    var fill = offsets
    var targets = [Int](repeating: 0, count: 2 * ends.count), edges = [Int](repeating: 0, count: 2 * ends.count)
    for (h, (u, v)) in ends.enumerated() {
        targets[fill[u]] = v
        edges[fill[u]] = h
        fill[u] += 1
        targets[fill[v]] = u
        edges[fill[v]] = h
        fill[v] += 1
    }
    var rows = _FlatIncidenceRows(offsets: offsets, targets: targets, edges: edges)
    let m = ends.count
    let walk = _collectHierholzer(edgeCount: m, closed: true) { vertices, edges in
        _undirectedHierholzer(&rows, count: n, edgeCount: m, start: 0, vertices: vertices, edges: edges)
    }!
    var order: [Int] = []
    order.reserveCapacity(n)
    var visited = [Bool](repeating: false, count: n)
    for v in walk.vertices where !visited[v] {
        visited[v] = true
        order.append(v)
    }
    return order
}

extension Graph {
    @inlinable
    func _christofidesTour<W: SignedNumeric & Comparable>(_ weight: (Edges.Index) -> W, half: (W) -> W, valid: (W) -> Bool) -> Cycle<Vertex, Edges.Index>? {
        let numbering = _tourNumbering()
        let n = numbering.isIndexed ? vertexIndexBound! : numbering.listed.count
        guard n >= 3 else { return nil }
        let matrix = _completeTourMatrix(weight, numbering)
        return _tourCycle(_christofidesOrder(matrix, half: half, valid: valid), matrix, numbering)
    }

    /// Christofides' tour (Christofides, "Worst-case analysis of a new heuristic for the
    /// travelling salesman problem", Report 388, Carnegie Mellon University, 1976; found
    /// independently by Serdyukov, 1978): the canonical minimum spanning tree (weight, then
    /// position: SpanningTrees' `minimumSpanningTree(weight:)`, by Prim on the dense matrix), a
    /// minimum-weight perfect matching on its odd-degree vertices (MatchingModule's
    /// `minimumWeightMatching`, Galil's blossom), an Eulerian circuit of their union by Hierholzer
    /// from the first vertex, shortcut to the first visit of each vertex (NetworkX
    /// `christofides`, JGraphT `ChristofidesThreeHalvesApproxMetricTSP`, LEMON `ChristofidesTsp`).
    /// Each piece is pinned, so the tour is: the matching is on the complete graph of the odd
    /// vertices in `vertices` order (pairs i < j lexicographic), and the circuit's multigraph
    /// lists the tree edges by position, then the matched pairs in that order. At most 3/2 × the
    /// shortest tour when the weights satisfy the triangle inequality (not checked).
    ///
    /// Tours read the simple graph, as `nearestNeighborTour(weight:)` documents; nil below three
    /// vertices.
    ///
    /// - Precondition: the graph is complete; the sum along a tour fits in `W`. When `W` is a
    ///   `FixedWidthInteger`, every non-loop edge's weight satisfies n · (2 · |weight| + 1) ≤
    ///   `W.max / 8` (the matching's bound), checked as each weight is read, so a weight beyond it
    ///   traps even on an edge the matching never sees; an arbitrary-precision integer has no bound.
    /// - Complexity: O(n³): the matching on up to n vertices; the tree O(n²).
    @inlinable
    public func christofidesTour<W: SignedInteger>(weight: (Edges.Index) -> W) -> Cycle<Vertex, Edges.Index>? {
        // The matching's bound, n · (2 · |w| + 1) ≤ W.max / 8, checked on every weight read when W
        // has a maximum: |w| ≤ (⌊(W.max / 8) / n⌋ − 1) / 2, formed without overflow.
        var limit: W?
        if let fixed = W.self as? any FixedWidthInteger.Type, let maximum = W(exactly: fixed.max) {
            let n = W(Swift.max(vertexCount, 1))
            limit = (maximum / 8 / n - 1) / 2
        }
        return _christofidesTour({ (position: Edges.Index) -> W in
            let w = weight(position)
            if let limit { precondition(w <= limit && w >= -limit, "A weight is too large for the matching: n · (2 · |weight| + 1) must be at most W.max / 8") }
            return w
        }, half: { $0 / 2 }, valid: { _ in true })
    }

    /// Christofides' tour with floating-point weights, as the integer overload, on the matching's
    /// floating-point path.
    ///
    /// - Precondition: the graph is complete; no weight is NaN or infinite; n · (2 · |weight| + 1)
    ///   ≤ `greatestFiniteMagnitude / 8`.
    /// - Complexity: O(n³).
    @inlinable
    public func christofidesTour<W: FloatingPoint>(weight: (Edges.Index) -> W) -> Cycle<Vertex, Edges.Index>? {
        _christofidesTour(weight, half: { $0 / 2 }, valid: { $0.isFinite && $0.magnitude <= .greatestFiniteMagnitude / 8 })
    }
}
