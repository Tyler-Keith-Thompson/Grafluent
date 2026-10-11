import GraphProtocols

/// The simple graph underneath an undirected graph, in index space: one edge per pair of distinct
/// adjacent vertices, self-loops dropped. Planarity depends on it alone; the embedding puts the
/// loops and the parallel copies back afterwards.
///
/// Simple edge `k` joins `ends[2k] < ends[2k + 1]` and stands for edge number `representative[k]`,
/// the first copy met in the row of its lesser end. Its rows are in increasing simple edge number.
@usableFromInline
struct _UnderlyingSimpleGraph {
    /// The vertex count `n` and the original edge count `m`.
    @usableFromInline var vertexCount: Int
    @usableFromInline var edgeCount: Int
    /// Two vertex numbers per simple edge, the lesser first.
    @usableFromInline var ends: [Int]
    /// Per simple edge, the edge number it stands for (empty when edge numbers were not read).
    @usableFromInline var representative: [Int]
    /// The rows: `rowEdges[rowStart[v] ..< rowStart[v + 1]]` are the simple edges at `v`.
    @usableFromInline var rowStart: [Int]
    @usableFromInline var rowEdges: [Int]
    /// Whether more distinct pairs exist than the reader's limit allowed.
    @usableFromInline var exceeded: Bool
    /// With the copies kept: per edge number, its simple edge, or −2 for a self-loop.
    @usableFromInline var simpleEdgeOf: [Int]
    /// With the copies kept: the self-loops, each once, in the order their rows list them, and the
    /// vertex of each.
    @usableFromInline var loops: [Int]
    @usableFromInline var loopVertex: [Int]
    /// With the copies kept: each vertex's first incident edge number, or −1.
    @usableFromInline var firstEdge: [Int]

    @usableFromInline var simpleEdgeCount: Int { ends.count / 2 }

    /// The vertex across simple edge `k` from `v`.
    @inlinable @inline(__always)
    func other(_ k: Int, _ v: Int) -> Int { ends[2 &* k] == v ? ends[2 &* k &+ 1] : ends[2 &* k] }

    /// The simple graph from a list of pairs (each lesser end first, distinct), its rows built.
    @usableFromInline
    init(vertexCount n: Int, edgeCount m: Int, ends: [Int], representative: [Int], exceeded: Bool,
         simpleEdgeOf: [Int] = [], loops: [Int] = [], loopVertex: [Int] = [], firstEdge: [Int] = []) {
        vertexCount = n
        edgeCount = m
        self.ends = ends
        self.representative = representative
        self.exceeded = exceeded
        self.simpleEdgeOf = simpleEdgeOf
        self.loops = loops
        self.loopVertex = loopVertex
        self.firstEdge = firstEdge
        // Rows by counting: each simple edge goes to both ends, in increasing edge number.
        var start = [Int](repeating: 0, count: n + 1)
        let s = ends.count / 2
        var rows = [Int](repeating: 0, count: 2 * s)
        ends.withUnsafeBufferPointer { ends in
            start.withUnsafeMutableBufferPointer { start in
                for x in ends { start[x + 1] += 1 }
                for v in 0 ..< n { start[v + 1] += start[v] }
                var fill = Array(start[0 ..< n])
                rows.withUnsafeMutableBufferPointer { rows in
                    for k in 0 ..< s {
                        let a = ends[2 * k], b = ends[2 * k + 1]
                        rows[fill[a]] = k
                        fill[a] += 1
                        rows[fill[b]] = k
                        fill[b] += 1
                    }
                }
            }
        }
        rowStart = start
        rowEdges = rows
    }

    /// The same graph plus an apex: vertex `n`, joined to every vertex. Outerplanarity is planarity
    /// of this graph.
    @usableFromInline
    func addingApex() -> _UnderlyingSimpleGraph {
        let n = vertexCount
        var withApex = ends
        withApex.reserveCapacity(ends.count + 2 * n)
        for v in 0 ..< n {
            withApex.append(v)
            withApex.append(n)
        }
        return _UnderlyingSimpleGraph(vertexCount: n + 1, edgeCount: edgeCount + n, ends: withApex, representative: [], exceeded: false)
    }
}

/// Reads an undirected graph's rows once into its underlying simple graph. Per vertex, a stamp
/// array marks the neighbours already seen from it, so a later copy of a pair is recognized in
/// O(1) without hashing; loops are set aside. Each pair becomes a simple edge at its lesser end.
///
/// `limit` is the most simple edges kept: reading stops at the first pair beyond it and reports
/// `exceeded`. `keepsCopies` also records which simple edge each edge number became, the loops,
/// and each vertex's first incident edge, for the embedding.
@usableFromInline
struct _UnderlyingSimpleGraphReader: _UndirectedRowsAlgorithm {
    @usableFromInline let limit: Int
    @usableFromInline let readsEdges: Bool
    @usableFromInline let keepsCopies: Bool

    @inlinable
    init(limit: Int, readsEdges: Bool, keepsCopies: Bool) {
        self.limit = limit
        self.readsEdges = readsEdges || keepsCopies
        self.keepsCopies = keepsCopies
    }

    @inlinable
    func run<Rows: _IncidenceRowSource>(count n: Int, edgeCount m: Int, _ rows: inout Rows) -> _UnderlyingSimpleGraph {
        var stamp = [Int](repeating: -1, count: n)
        var pairNumber = [Int](repeating: 0, count: n)
        var ends: [Int] = []
        var representative: [Int] = []
        var simpleEdgeOf = keepsCopies ? [Int](repeating: -1, count: m) : []
        var loops: [Int] = []
        var loopVertex: [Int] = []
        var firstEdge = keepsCopies ? [Int](repeating: -1, count: n) : []
        var exceeded = false
        var count = 0
        reading: for v in 0 ..< n {
            let c = rows.count(v)
            if keepsCopies && c > 0 { firstEdge[v] = rows.edge(v, 0) }
            for k in 0 ..< c {
                let w = rows.neighbor(v, k)
                // The rows may be unchecked buffers: a conformer breaking the index laws traps here
                // instead of corrupting memory.
                precondition(UInt(bitPattern: w) < UInt(bitPattern: n), "A neighbor index is out of range")
                if w < v { continue }
                if w == v {
                    if keepsCopies {
                        let e = rows.edge(v, k)
                        precondition(UInt(bitPattern: e) < UInt(bitPattern: m), "An edge index is out of range")
                        if simpleEdgeOf[e] == -1 {
                            simpleEdgeOf[e] = -2
                            loops.append(e)
                            loopVertex.append(v)
                        }
                    }
                    continue
                }
                if stamp[w] == v {
                    if keepsCopies {
                        let e = rows.edge(v, k)
                        precondition(UInt(bitPattern: e) < UInt(bitPattern: m), "An edge index is out of range")
                        simpleEdgeOf[e] = pairNumber[w]
                    }
                    continue
                }
                if count == limit {
                    exceeded = true
                    break reading
                }
                stamp[w] = v
                pairNumber[w] = count
                ends.append(v)
                ends.append(w)
                if readsEdges {
                    let e = rows.edge(v, k)
                    precondition(UInt(bitPattern: e) < UInt(bitPattern: m), "An edge index is out of range")
                    representative.append(e)
                    if keepsCopies { simpleEdgeOf[e] = count }
                }
                count += 1
            }
        }
        return _UnderlyingSimpleGraph(vertexCount: n, edgeCount: m, ends: ends, representative: representative, exceeded: exceeded,
                                      simpleEdgeOf: simpleEdgeOf, loops: loops, loopVertex: loopVertex, firstEdge: firstEdge)
    }
}
