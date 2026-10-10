import GraphProtocols

/// Whether no non-loop row entry joins two equal colours (`colors` by vertex number).
@frozen
@usableFromInline
struct _ProperColoringCheck: _UndirectedRowsAlgorithm {
    @usableFromInline let colors: [Int]

    @inlinable
    init(colors: [Int]) { self.colors = colors }

    @inlinable
    var readsEdges: Bool { false }

    @inlinable
    func run<Rows: _IncidenceRowSource>(count n: Int, edgeCount: Int, _ rows: inout Rows) -> Bool {
        for v in 0 ..< n {
            let c = colors[v]
            for k in 0 ..< rows.count(v) {
                let w = rows.neighbor(v, k)
                precondition(UInt(bitPattern: w) < UInt(bitPattern: n), "A neighbor index is out of range")
                if w != v && colors[w] == c { return false }
            }
        }
        return true
    }
}

/// Whether the edges at each vertex have distinct colours (`colors` by edge number, already
/// dense in `0..<bound`); a self-loop's two ends are one edge. A stamp per colour holds the vertex
/// and the edge that last took it.
@frozen
@usableFromInline
struct _ProperEdgeColoringCheck: _UndirectedRowsAlgorithm {
    @usableFromInline let colors: [Int]
    @usableFromInline let bound: Int

    @inlinable
    init(colors: [Int], bound: Int) {
        self.colors = colors
        self.bound = bound
    }

    @inlinable
    func run<Rows: _IncidenceRowSource>(count n: Int, edgeCount m: Int, _ rows: inout Rows) -> Bool {
        var owner = [Int](repeating: -1, count: bound), holder = [Int](repeating: -1, count: bound)
        for v in 0 ..< n {
            for k in 0 ..< rows.count(v) {
                let e = rows.edge(v, k)
                precondition(UInt(bitPattern: e) < UInt(bitPattern: m), "An edge index is out of range")
                let c = colors[e]
                if owner[c] == v {
                    if holder[c] != e { return false }
                    continue
                }
                owner[c] = v
                holder[c] = e
            }
        }
        return true
    }
}

extension Graph {
    /// Whether `color` gives the two ends of every edge different colours (NetworkX `is_coloring`,
    /// igraph `igraph_is_vertex_coloring`). Self-loops are ignored, as the colourings ignore them
    /// (NetworkX's `is_coloring` is false on any loop). Any Ints count as colours, not only
    /// `0..<k`. `color` is called once per vertex, in `vertices` order. O(n + m).
    @inlinable
    public func isColoring(_ color: (Vertex) -> Int) -> Bool {
        var colors: [Int] = []
        colors.reserveCapacity(vertexCount)
        for v in vertices { colors.append(color(v)) }
        return _runOnUndirectedRows(_ProperColoringCheck(colors: colors))
    }

    /// Whether every two edges with a common end have different colours: parallel edges, which
    /// share both ends, and a self-loop and any other edge at its vertex (igraph
    /// `igraph_is_edge_coloring`). Any Ints count as colours. `color` is called once per edge, in
    /// `edges` order. O(n + m), plus one hash per edge when the colours are not small
    /// non-negative numbers.
    @inlinable
    public func isEdgeColoring(_ color: (Edges.Index) -> Int) -> Bool {
        let m = edgeCount
        var colors: [Int] = []
        colors.reserveCapacity(m)
        var low = 0, high = -1
        for position in edges.indices {
            let c = color(position)
            colors.append(c)
            low = min(low, c)
            high = max(high, c)
        }
        var bound = high + 1
        if low < 0 || high >= 2 * m + 1 {
            var dense: [Int: Int] = [:]
            for i in colors.indices {
                if let c = dense[colors[i]] {
                    colors[i] = c
                } else {
                    dense[colors[i]] = dense.count
                    colors[i] = dense.count - 1
                }
            }
            bound = dense.count
        }
        return _runOnUndirectedRows(_ProperEdgeColoringCheck(colors: colors, bound: bound))
    }
}
