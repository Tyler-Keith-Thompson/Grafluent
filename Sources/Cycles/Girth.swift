import GraphProtocols

extension Graph {
    /// The length of a shortest cycle, in edges: 1 when there is a self-loop, 2 when there is a
    /// pair of parallel edges; `nil` when the graph is acyclic.
    ///
    /// A breadth-first search from every vertex, never back along the edge a vertex was reached
    /// by, each edge outside the search tree closing a cycle at most as long as its two ends'
    /// depths plus one; a search stops once its depth cannot beat the best so far. O(n·m) time,
    /// O(n + m) memory.
    @inlinable
    public func girth() -> Int? {
        _girth(_runOnUndirectedRows(_CopyIncidenceRows()))
    }
}

extension DirectedGraph {
    /// The length of a shortest directed cycle, in edges: 1 when there is a self-loop, 2 when two
    /// edges run in opposite directions between a pair of vertices; `nil` when the graph is
    /// acyclic.
    ///
    /// A breadth-first search from every vertex until it returns to it, stopping once its depth
    /// cannot beat the best so far. O(n·m) time, O(n + m) memory.
    @inlinable
    public func girth() -> Int? {
        _girth(_cycleRows(withPositions: false).rows)
    }
}

@inlinable
func _girth(_ rows: _CycleRows) -> Int? {
    let n = rows.count
    for v in 0 ..< n {
        for slot in rows.offsets[v] ..< rows.offsets[v + 1] where rows.targets[slot] == v { return 1 }
    }
    // Only vertices that can be on a cycle start a search or are visited: undirected, the 2-core
    // (peel vertices of degree 1 or 0); directed, the strong components with two or more
    // vertices, each search kept inside its root's. A forest or a DAG costs O(n + m).
    var part = [Int](repeating: -1, count: n)
    if rows.undirected {
        var degree = (0 ..< n).map { rows.offsets[$0 + 1] - rows.offsets[$0] }
        var peeled = [Bool](repeating: false, count: n)
        var queue = (0 ..< n).filter { degree[$0] <= 1 }
        for v in queue { peeled[v] = true }
        var head = 0
        while head < queue.count {
            let v = queue[head]
            head += 1
            for slot in rows.offsets[v] ..< rows.offsets[v + 1] {
                let w = rows.targets[slot]
                guard !peeled[w] else { continue }
                degree[w] -= 1
                if degree[w] <= 1 {
                    peeled[w] = true
                    queue.append(w)
                }
            }
        }
        for v in 0 ..< n where !peeled[v] { part[v] = 0 }
    } else {
        _strongComponentLabels(rows, &part)
    }
    var best = Int.max
    var root = [Int](repeating: -1, count: n)
    var dist = [Int](repeating: 0, count: n)
    var parentEdge = [Int](repeating: -1, count: n)
    var queue: [Int] = []
    queue.reserveCapacity(n)
    for r in 0 ..< n where part[r] >= 0 {
        let inside = part[r]
        root[r] = r
        dist[r] = 0
        parentEdge[r] = -1
        queue.removeAll(keepingCapacity: true)
        queue.append(r)
        var head = 0
        search: while head < queue.count {
            let v = queue[head]
            head += 1
            if rows.undirected {
                // An edge outside the tree from v closes a cycle of at least 2·dist(v) + 1: one
                // back to depth dist(v) − 1 was already counted from its other end.
                if 2 * dist[v] + 1 >= best { break }
                for slot in rows.offsets[v] ..< rows.offsets[v + 1] {
                    let w = rows.targets[slot], e = rows.edges[slot]
                    if e == parentEdge[v] || part[w] != inside { continue }
                    if root[w] == r {
                        best = min(best, dist[v] + dist[w] + 1)
                    } else {
                        root[w] = r
                        dist[w] = dist[v] + 1
                        parentEdge[w] = e
                        queue.append(w)
                    }
                }
            } else {
                if dist[v] + 1 >= best { break }
                for slot in rows.offsets[v] ..< rows.offsets[v + 1] {
                    let w = rows.targets[slot]
                    if part[w] != inside { continue }
                    if w == r {
                        best = dist[v] + 1
                        break search
                    }
                    if root[w] != r {
                        root[w] = r
                        dist[w] = dist[v] + 1
                        queue.append(w)
                    }
                }
            }
        }
        if best == 2 { return 2 }
    }
    return best == .max ? nil : best
}

/// Labels each vertex in a strong component of two or more vertices with its component, and
/// leaves the others −1: Tarjan's algorithm, iteratively.
@inlinable
func _strongComponentLabels(_ rows: _CycleRows, _ labels: inout [Int]) {
    let n = rows.count
    var disc = [Int](repeating: -1, count: n)
    var low = [Int](repeating: 0, count: n)
    var stack: [Int] = []
    var frames: [(v: Int, slot: Int)] = []
    var time = 0, components = 0
    var members: [Int] = []
    for root in 0 ..< n where disc[root] < 0 {
        disc[root] = time
        low[root] = time
        time += 1
        stack.append(root)
        frames.append((root, rows.offsets[root]))
        while let top = frames.last {
            let v = top.v
            if top.slot < rows.offsets[v + 1] {
                frames[frames.count - 1].slot += 1
                let w = rows.targets[top.slot]
                if disc[w] < 0 {
                    disc[w] = time
                    low[w] = time
                    time += 1
                    stack.append(w)
                    frames.append((w, rows.offsets[w]))
                } else if low[w] >= 0 {
                    low[v] = min(low[v], disc[w])
                }
            } else {
                frames.removeLast()
                if let parent = frames.last { low[parent.v] = min(low[parent.v], low[v]) }
                if low[v] == disc[v] {
                    var size = 0
                    while true {
                        let x = stack.removeLast()
                        low[x] = -1
                        members.append(x)
                        size += 1
                        if x == v { break }
                    }
                    if size >= 2 {
                        for x in members.suffix(size) { labels[x] = components }
                        components += 1
                    }
                    members.removeLast(size)
                }
            }
        }
    }
}
