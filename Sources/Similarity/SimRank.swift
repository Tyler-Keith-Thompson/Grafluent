import GraphProtocols

// SimRank (Jeh and Widom 2002): s(a, a) = 1, and for a ≠ b
//
//     s(a, b) = C / (|I(a)| |I(b)|) · Σ_{i ∈ I(a)} Σ_{j ∈ I(b)} s(i, j),
//
// 0 when I(a) or I(b) is empty, where I(x) is the set of in-neighbors of x (neighbors, undirected).
// The iteration starts from the identity, and each step is two sparse passes over the n × n
// matrix (the partial sums of Lizorkin et al.): P[i][b] = Σ_{j ∈ I(b)} S[i][j], then
// S'[a][b] = C / (|I(a)| |I(b)|) · Σ_{i ∈ I(a)} P[i][b], computed for a < b and mirrored, so the
// result is exactly symmetric. It stops after the first step whose largest change is below the
// tolerance.

/// The in-neighbor sets of a directed graph's rows: each vertex's distinct sources in ascending
/// order, a self-loop's vertex included.
@inlinable
func _distinctInRows(_ rows: _CompressedRows) -> _CompressedRows {
    let n = rows.count
    var start = [Int](repeating: 0, count: n + 1)
    for w in rows.targets { start[w + 1] += 1 }
    for v in 0 ..< n { start[v + 1] += start[v] }
    var fill = start
    var sources = [Int](repeating: 0, count: rows.targets.count)
    for v in 0 ..< n {
        for slot in rows.offsets[v] ..< rows.offsets[v + 1] {
            let w = rows.targets[slot]
            sources[fill[w]] = v
            fill[w] += 1
        }
    }
    // Each row is ascending, so parallel arcs are adjacent; keep the first of each run.
    var offsets = [Int](repeating: 0, count: n + 1)
    var kept = 0
    for w in 0 ..< n {
        for slot in start[w] ..< start[w + 1] where slot == start[w] || sources[slot] != sources[slot - 1] {
            sources[kept] = sources[slot]
            kept += 1
        }
        offsets[w + 1] = kept
    }
    sources.removeLast(sources.count - kept)
    return _CompressedRows(offsets: offsets, targets: sources, edges: [])
}

/// Copies an undirected graph's neighbor sets: each vertex's distinct neighbors in first-appearance
/// row order, the vertex itself once when it has a self-loop.
@frozen
@usableFromInline
struct _CopyNeighborSets: _UndirectedRowsAlgorithm {
    @inlinable
    init() {}

    @inlinable
    var readsEdges: Bool { false }

    @inlinable
    func run<Rows: _IncidenceRowSource>(count n: Int, edgeCount: Int, _ rows: inout Rows) -> _CompressedRows {
        var offsets = [Int](repeating: 0, count: n + 1)
        var targets: [Int] = []
        targets.reserveCapacity(2 * edgeCount)
        var stamp = [Int](repeating: -1, count: n)
        for v in 0 ..< n {
            for k in 0 ..< rows.count(v) {
                let w = rows.neighbor(v, k)
                precondition(UInt(bitPattern: w) < UInt(bitPattern: n), "A neighbor index is out of range")
                if stamp[w] == v { continue }
                stamp[w] = v
                targets.append(w)
            }
            offsets[v + 1] = targets.count
        }
        return _CompressedRows(offsets: offsets, targets: targets, edges: [])
    }
}

@inlinable
func _checkSimRank(importanceFactor: Double, tolerance: Double, maxIterations: Int) {
    precondition(importanceFactor > 0 && importanceFactor < 1, "The importance factor must be between 0 and 1, exclusive")
    precondition(tolerance > 0 && tolerance.isFinite, "The tolerance must be positive and finite")
    precondition(maxIterations >= 1, "maxIterations must be at least 1")
}

/// SimRank over the in-neighbor sets `rows`: the n × n similarities, row-major.
@inlinable
func _simRank(_ rows: _CompressedRows, importanceFactor c: Double, tolerance: Double, maxIterations: Int) throws(NoConvergence) -> [Double] {
    let n = rows.count
    guard n > 0 else { return [] }
    var similarity = [Double](repeating: 0, count: n * n)
    for a in 0 ..< n { similarity[a * n + a] = 1 }
    var partial = [Double](repeating: 0, count: n * n)
    var sums = [Double](repeating: 0, count: n)
    var change = 0.0
    for _ in 0 ..< maxIterations {
        change = rows.offsets.withUnsafeBufferPointer { offsets in
            rows.targets.withUnsafeBufferPointer { sources in
                similarity.withUnsafeMutableBufferPointer { s in
                    partial.withUnsafeMutableBufferPointer { p in
                        sums.withUnsafeMutableBufferPointer { sums in
                            // P[i][b] = Σ_{j ∈ I(b)} S[i][j].
                            for i in 0 ..< n {
                                let row = i &* n
                                for b in 0 ..< n {
                                    var total = 0.0
                                    for slot in offsets[b] ..< offsets[b &+ 1] { total += s[row &+ sources[slot]] }
                                    p[row &+ b] = total
                                }
                            }
                            // S'[a][b] for a < b, written over S (only P is read) and mirrored.
                            var largest = 0.0
                            for a in 0 ..< n {
                                let da = offsets[a &+ 1] &- offsets[a]
                                let row = a &* n
                                // A vertex without in-neighbors keeps its starting row: similar only to
                                // itself. Every pair with it is also written 0 from the other side.
                                guard da > 0 else { continue }
                                for b in a &+ 1 ..< n { sums[b] = 0 }
                                for slot in offsets[a] ..< offsets[a &+ 1] {
                                    let from = sources[slot] &* n
                                    for b in a &+ 1 ..< n { sums[b] += p[from &+ b] }
                                }
                                for b in a &+ 1 ..< n {
                                    let db = offsets[b &+ 1] &- offsets[b]
                                    let value = db == 0 ? 0 : c * sums[b] / Double(da &* db)
                                    largest = max(largest, abs(value - s[row &+ b]))
                                    s[row &+ b] = value
                                    s[b &* n &+ a] = value
                                }
                            }
                            return largest
                        }
                    }
                }
            }
        }
        if change < tolerance { return similarity }
    }
    throw NoConvergence(iterations: maxIterations, residual: change)
}

/// SimRank similarities of every pair of vertices, stored densely by vertex index.
@frozen
public struct SimRankSimilarity<G: DirectedGraph> {
    @usableFromInline let _graph: G
    /// Vertex numbers when the graph has no vertex indices.
    @usableFromInline let _numbers: [G.Vertex: Int]?
    @usableFromInline let _count: Int
    /// Row-major, `_count` × `_count`.
    @usableFromInline let _values: [Double]

    @inlinable
    init(_ graph: G, numbers: [G.Vertex: Int]?, count: Int, values: [Double]) {
        _graph = graph
        _numbers = numbers
        _count = count
        _values = values
    }

    /// The similarity of `u` and `v`, in [0, 1]: 1 when `u == v`, and equal to the similarity of `v`
    /// and `u`. O(1) after looking them up.
    ///
    /// - Precondition: `u` and `v` are vertices of the graph.
    @inlinable
    public func similarity(of u: G.Vertex, and v: G.Vertex) -> Double {
        let a = _graph._vertexNumber(of: u, _numbers, "The vertex is not in the graph")
        let b = _graph._vertexNumber(of: v, _numbers, "The vertex is not in the graph")
        return _values[a * _count + b]
    }

    /// The similarity of `u` and `v`, throwing instead of trapping when either is not a vertex of
    /// the graph.
    ///
    /// - Throws: `VertexNotFound` when `u` or `v` is not a vertex of the graph.
    @inlinable
    public func similarity(checked u: G.Vertex, and v: G.Vertex) throws(VertexNotFound) -> Double {
        guard _graph.contains(u), _graph.contains(v) else { throw VertexNotFound() }
        return similarity(of: u, and: v)
    }

    /// The similarity of the vertices at `i` and `j` (their vertex indices, or their positions in
    /// `vertices` when the graph has no vertex indices).
    ///
    /// - Precondition: `i` and `j` are in `0..<vertexCount`.
    @inlinable
    public func similarity(ofIndex i: Int, andIndex j: Int) -> Double {
        precondition(i >= 0 && i < _count && j >= 0 && j < _count, "Vertex index out of range")
        return _values[i * _count + j]
    }
}

extension SimRankSimilarity: Sendable where G: Sendable, G.Vertex: Sendable {}

extension Graph {
    /// SimRank (Jeh and Widom): two vertices are similar when their neighbors are similar.
    ///
    /// s(a, a) = 1, and for a ≠ b, s(a, b) = C / (|Γ(a)| |Γ(b)|) · Σ s(i, j) over i ∈ Γ(a) and
    /// j ∈ Γ(b), or 0 when a or b has no neighbor, where Γ(x) is the set of neighbors of x: parallel
    /// edges count once, and a vertex with a self-loop is its own neighbor. The iteration starts
    /// from s(a, b) = 0 for a ≠ b and stops after the first step whose largest change in any
    /// similarity is below `tolerance`. O(n (n + m)) per step and O(n²) memory, for n vertices and
    /// m edges.
    ///
    /// - Parameters:
    ///   - importanceFactor: C, the decay applied to each step away from the pair.
    ///   - tolerance: The largest change in any similarity that counts as converged.
    ///   - maxIterations: The most steps to take.
    /// - Returns: Every pair's similarity, symmetric, with 1 on the diagonal.
    /// - Precondition: `importanceFactor` is between 0 and 1, exclusive; `tolerance` is positive
    ///   and finite; `maxIterations` is at least 1.
    /// - Throws: `NoConvergence` when no step of the first `maxIterations` changes every
    ///   similarity by less than `tolerance`, with `maxIterations` and the last step's largest
    ///   change.
    @inlinable
    public func simRankSimilarity(importanceFactor: Double = 0.9, tolerance: Double = 1e-4, maxIterations: Int = 1000) throws(NoConvergence) -> SimRankSimilarity<DirectedView<Self>> {
        _checkSimRank(importanceFactor: importanceFactor, tolerance: tolerance, maxIterations: maxIterations)
        let numbering = _vertexNumbering()
        let rows = _runOnUndirectedRows(_CopyNeighborSets(), vertexNumbering: numbering)
        let values = try _simRank(rows, importanceFactor: importanceFactor, tolerance: tolerance, maxIterations: maxIterations)
        return SimRankSimilarity(directedView, numbers: numbering?.numbers, count: rows.count, values: values)
    }
}

extension DirectedGraph {
    /// SimRank (Jeh and Widom): two vertices are similar when the vertices pointing to them are
    /// similar.
    ///
    /// s(a, a) = 1, and for a ≠ b, s(a, b) = C / (|I(a)| |I(b)|) · Σ s(i, j) over i ∈ I(a) and
    /// j ∈ I(b), or 0 when a or b has no in-neighbor, where I(x) is the set of predecessors of x:
    /// parallel arcs count once, and a vertex with a self-loop is its own predecessor. The
    /// iteration starts from s(a, b) = 0 for a ≠ b and stops after the first step whose largest
    /// change in any similarity is below `tolerance`. O(n (n + m)) per step and O(n²) memory, for
    /// n vertices and m edges.
    ///
    /// - Parameters:
    ///   - importanceFactor: C, the decay applied to each step away from the pair.
    ///   - tolerance: The largest change in any similarity that counts as converged.
    ///   - maxIterations: The most steps to take.
    /// - Returns: Every pair's similarity, symmetric, with 1 on the diagonal.
    /// - Precondition: `importanceFactor` is between 0 and 1, exclusive; `tolerance` is positive
    ///   and finite; `maxIterations` is at least 1.
    /// - Throws: `NoConvergence` when no step of the first `maxIterations` changes every
    ///   similarity by less than `tolerance`, with `maxIterations` and the last step's largest
    ///   change.
    @inlinable
    public func simRankSimilarity(importanceFactor: Double = 0.9, tolerance: Double = 1e-4, maxIterations: Int = 1000) throws(NoConvergence) -> SimRankSimilarity<Self> {
        _checkSimRank(importanceFactor: importanceFactor, tolerance: tolerance, maxIterations: maxIterations)
        let (rows, numbering) = _compressedRows(readsEdges: false, dropsLoops: false)
        let inRows = _distinctInRows(rows)
        let values = try _simRank(inRows, importanceFactor: importanceFactor, tolerance: tolerance, maxIterations: maxIterations)
        return SimRankSimilarity(self, numbers: numbering?.numbers, count: inRows.count, values: values)
    }
}
