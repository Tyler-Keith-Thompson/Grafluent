import GraphProtocols

/// The simple graph underlying an undirected graph, in index space: each vertex's distinct other
/// neighbors in first-appearance row order (self-loops dropped, parallel copies merged), as flat
/// rows. Every Cliques algorithm reads this, so a multigraph means its simple graph.
@frozen
@usableFromInline
struct _SimpleRows: Sendable {
    @usableFromInline var offsets: [Int]
    @usableFromInline var neighbors: [Int]

    @inlinable
    init(offsets: [Int], neighbors: [Int]) {
        self.offsets = offsets
        self.neighbors = neighbors
    }

    @inlinable
    var count: Int { offsets.count - 1 }

    @inlinable
    func degree(_ v: Int) -> Int { offsets[v + 1] - offsets[v] }
}

/// Copies the rows once, dropping loops and repeats with a stamp per vertex.
@frozen
@usableFromInline
struct _CopySimpleRows: _UndirectedRowsAlgorithm {
    @inlinable
    init() {}

    @inlinable
    var readsEdges: Bool { false }

    @inlinable
    func run<Rows: _IncidenceRowSource>(count n: Int, edgeCount: Int, _ rows: inout Rows) -> _SimpleRows {
        var offsets = [Int](repeating: 0, count: n + 1)
        var neighbors: [Int] = []
        neighbors.reserveCapacity(2 * edgeCount)
        var stamp = [Int](repeating: -1, count: n)
        for v in 0 ..< n {
            for k in 0 ..< rows.count(v) {
                let w = rows.neighbor(v, k)
                precondition(UInt(bitPattern: w) < UInt(bitPattern: n), "A neighbor index is out of range")
                if w == v || stamp[w] == v { continue }
                stamp[w] = v
                neighbors.append(w)
            }
            offsets[v + 1] = neighbors.count
        }
        return _SimpleRows(offsets: offsets, neighbors: neighbors)
    }
}

extension Graph {
    @inlinable
    func _simpleRows() -> _SimpleRows { _runOnUndirectedRows(_CopySimpleRows()) }

    /// The number of `vertex`, without vertex indices by its position in `listed`.
    @inlinable
    func _cliqueNumber(of vertex: Vertex, _ listed: [Vertex]?) -> Int {
        precondition(contains(vertex), "The vertex is not in the graph")
        if let listed { return listed.firstIndex(of: vertex)! }
        return vertexIndex(of: vertex)
    }
}

/// Batagelj–Zaversnik's core decomposition, O(n + m): the core numbers and the removal order
/// (each vertex has at most its core number of neighbors after it). Vertices are bucketed by
/// degree, stable in index order; each removed vertex lowers its later neighbors, taken in row
/// order, moving each to the front of its bucket first.
@inlinable
func _cores(_ rows: _SimpleRows) -> (core: [Int], order: [Int]) {
    let n = rows.count
    guard n > 0 else { return ([], []) }
    var degree = (0 ..< n).map { rows.degree($0) }
    let maxDegree = degree.max()!
    var bin = [Int](repeating: 0, count: maxDegree + 1)
    for d in degree { bin[d] += 1 }
    var start = 0
    for d in 0 ... maxDegree {
        let count = bin[d]
        bin[d] = start
        start += count
    }
    var vert = [Int](repeating: 0, count: n), pos = [Int](repeating: 0, count: n)
    var fill = bin
    for v in 0 ..< n {
        pos[v] = fill[degree[v]]
        vert[pos[v]] = v
        fill[degree[v]] += 1
    }
    for i in 0 ..< n {
        let v = vert[i]
        for k in rows.offsets[v] ..< rows.offsets[v + 1] {
            let u = rows.neighbors[k]
            guard degree[u] > degree[v] else { continue }
            let du = degree[u], pu = pos[u]
            let pw = bin[du], w = vert[pw]
            if u != w {
                pos[u] = pw
                vert[pu] = w
                pos[w] = pu
                vert[pw] = u
            }
            bin[du] += 1
            degree[u] -= 1
        }
    }
    return (degree, vert)
}
