import GraphProtocols

extension Graph {
    /// Whether the graph is a tree: at least one vertex, connected and acyclic (a self-loop and a
    /// parallel pair are cycles). Equivalent to `Tree(self) != nil`, without building one.
    ///
    /// O(1) when `edgeCount != vertexCount − 1`; otherwise one search over the rows, O(n), with a
    /// mark per vertex and a stack.
    @inlinable
    public var isTree: Bool {
        let n = vertexCount
        guard n >= 1, edgeCount == n - 1 else { return false }
        // With n − 1 edges, connected implies acyclic; a loop or a parallel pair leaves a vertex
        // out.
        return _runOnUndirectedRows(_ReachesEveryVertex())
    }
}

/// Whether a search from vertex 0 reaches every vertex.
@frozen
@usableFromInline
struct _ReachesEveryVertex: _UndirectedRowsAlgorithm {
    @inlinable
    init() {}

    @inlinable
    var readsEdges: Bool { false }

    @inlinable
    func run<Rows: _IncidenceRowSource>(count n: Int, edgeCount: Int, _ rows: inout Rows) -> Bool {
        var seen = [Bool](repeating: false, count: n)
        var stack = [0]
        seen[0] = true
        var reached = 1
        while let v = stack.popLast() {
            for k in 0 ..< rows.count(v) {
                let w = rows.neighbor(v, k)
                precondition(UInt(bitPattern: w) < UInt(bitPattern: n), "A neighbor index is out of range")
                if !seen[w] {
                    seen[w] = true
                    reached += 1
                    stack.append(w)
                }
            }
        }
        return reached == n
    }
}

extension DirectedGraph {
    /// Whether the graph is an arborescence: at least one vertex, exactly one (the root) without
    /// an incoming edge, every other with exactly one, and every vertex reachable from the root.
    /// Equivalent to `Arborescence(self) != nil`, without building one.
    ///
    /// O(1) when `edgeCount != vertexCount − 1`; otherwise O(n).
    @inlinable
    public var isArborescence: Bool {
        let n = vertexCount
        guard n >= 1, edgeCount == n - 1, let (_, ends, _) = _treeInput() else { return false }
        var incoming = [Int](repeating: 0, count: n)
        var out = [Int](repeating: 0, count: n + 1)
        for e in 0 ..< n - 1 {
            let t = ends[2 * e + 1]
            incoming[t] += 1
            if incoming[t] > 1 { return false }
            out[ends[2 * e] + 1] += 1
        }
        guard let root = incoming.firstIndex(of: 0) else { return false }
        // The out-rows, then a search from the root.
        for v in 0 ..< n { out[v + 1] += out[v] }
        var fill = out
        var targets = [Int](repeating: 0, count: n - 1)
        for e in 0 ..< n - 1 {
            targets[fill[ends[2 * e]]] = ends[2 * e + 1]
            fill[ends[2 * e]] += 1
        }
        var seen = [Bool](repeating: false, count: n)
        seen[root] = true
        var stack = [root]
        var reached = 1
        while let v = stack.popLast() {
            for k in out[v] ..< out[v + 1] where !seen[targets[k]] {
                seen[targets[k]] = true
                reached += 1
                stack.append(targets[k])
            }
        }
        return reached == n
    }
}
