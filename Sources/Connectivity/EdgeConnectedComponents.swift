import GraphProtocols

/// Unit-capacity flows on an undirected multigraph's rows without self-loops (`_CopyRows`, edge
/// numbers read): each edge carries at most one unit, either way, so a flow value is a number of
/// edge-disjoint paths. Flows are found one augmenting path at a time by breadth-first search in
/// the residual graph, restricted to the vertices stamped `inside`, and stop at a cap.
@frozen
@usableFromInline
struct _UnitFlows {
    @usableFromInline let rows: _CompressedRows
    /// Each edge's flow from its lesser end to its greater: −1, 0 or 1.
    @usableFromInline var flow: [Int8]
    /// The vertices that take part: `inside[v] == tag`.
    @usableFromInline var inside: [Int]
    @usableFromInline var tag = 0
    /// The last search's reach: `seen[v] == epoch`.
    @usableFromInline var seen: [Int]
    @usableFromInline var epoch = 0
    /// Each reached vertex's parent, and the slot of the arc from it.
    @usableFromInline var parent: [Int]
    @usableFromInline var via: [Int]
    @usableFromInline var queue: [Int] = []
    /// The edges the current flow has used, to clear before the next.
    @usableFromInline var used: [Int] = []

    @inlinable
    init(_ rows: _CompressedRows, edgeCount m: Int) {
        self.rows = rows
        let n = rows.count
        flow = [Int8](repeating: 0, count: m)
        inside = [Int](repeating: 0, count: n)
        seen = [Int](repeating: 0, count: n)
        parent = [Int](repeating: -1, count: n)
        via = [Int](repeating: -1, count: n)
    }

    /// Stamps `members` as the vertices that take part, all others left out.
    @inlinable
    mutating func enclose(_ members: [Int]) {
        tag += 1
        for v in members { inside[v] = tag }
    }

    /// The number of edge-disjoint s–t paths among the inside vertices, or `cap` when there are at
    /// least that many. Below the cap, the vertices `seen[v] == epoch` are the source side of a
    /// minimum cut.
    @inlinable
    mutating func maximumFlow(from s: Int, to t: Int, cap: Int) -> Int {
        for e in used { flow[e] = 0 }
        used.removeAll(keepingCapacity: true)
        var value = 0
        while value < cap {
            epoch += 1
            seen[s] = epoch
            queue.removeAll(keepingCapacity: true)
            queue.append(s)
            var head = 0
            var reached = false
            search: while head < queue.count {
                let x = queue[head]
                head += 1
                for slot in rows.offsets[x] ..< rows.offsets[x + 1] {
                    let y = rows.targets[slot]
                    guard inside[y] == tag, seen[y] != epoch else { continue }
                    let forward: Int8 = x < y ? 1 : -1
                    guard flow[rows.edges[slot]] != forward else { continue }
                    seen[y] = epoch
                    parent[y] = x
                    via[y] = slot
                    if y == t {
                        reached = true
                        break search
                    }
                    queue.append(y)
                }
            }
            guard reached else { return value }
            // Push one unit back along the parent arcs.
            var y = t
            while y != s {
                let e = rows.edges[via[y]]
                let x = parent[y]
                if flow[e] == 0 { used.append(e) }
                flow[e] += x < y ? 1 : -1
                y = x
            }
            value += 1
        }
        return value
    }

    /// Partitions `members` (stamped by `enclose`) into the classes of vertices joined by at least
    /// `k` edge-disjoint paths among the members, as a label per vertex in `labels` from `next`
    /// up. A member with fewer than `k` edges to the others is a class alone. Each flow either
    /// joins a vertex to the class of the source or splits the vertices left by a cut of fewer
    /// than `k` edges, which no pair across it can then cross with k paths: at most 2|members|
    /// flows, each O(k(n + m)).
    @inlinable
    mutating func classes(of members: [Int], k: Int, labels: inout [Int], next: inout Int) {
        var work: [(vertices: [Int], source: Int)] = []
        var rest: [Int] = []
        for v in members {
            var degree = 0
            for slot in rows.offsets[v] ..< rows.offsets[v + 1] where inside[rows.targets[slot]] == tag { degree += 1 }
            if degree < k {
                labels[v] = next
                next += 1
            } else {
                rest.append(v)
            }
        }
        if let first = rest.first { work.append((Array(rest.dropFirst()), first)) }
        while let (group, s) = work.popLast() {
            labels[s] = next
            var left = group
            var kept: [Int] = [], cut: [Int] = []
            while let t = left.popLast() {
                if maximumFlow(from: s, to: t, cap: k) >= k {
                    labels[t] = next
                    continue
                }
                kept.removeAll(keepingCapacity: true)
                cut.removeAll(keepingCapacity: true)
                for v in left {
                    if seen[v] == epoch { kept.append(v) } else { cut.append(v) }
                }
                work.append((cut, t))
                swap(&left, &kept)
            }
            next += 1
        }
    }
}

/// The rows the k-edge-connectivity searches read: the multigraph without self-loops, with edge
/// numbers, so parallel edges count as separate paths.
@inlinable
func _loopFreeRows<G: Graph>(_ graph: G) -> _CompressedRows {
    graph._runOnUndirectedRows(_CopyRows(readsEdges: true, dropsLoops: true))
}

extension Graph {
    /// The k-edge-connected components: the classes of vertices joined pairwise by at least `k`
    /// edge-disjoint paths in the whole graph, ordered as `connectedComponents()`. Parallel edges
    /// are separate paths and self-loops count for nothing. `k = 1` gives the connected
    /// components and `k = 2` the bi-edge-connected ones, each in O(n + m); for larger k, at most
    /// 2n unit-capacity flows, each stopped after k augmenting paths: O(k n (n + m)).
    ///
    /// - Precondition: `k >= 1`.
    @inlinable
    public func kEdgeConnectedComponents(_ k: Int) -> Components<DirectedView<Self>> {
        precondition(k >= 1, "k must be positive")
        if k == 1 { return connectedComponents() }
        if k == 2 { return biEdgeConnectedComponents() }
        let rows = _loopFreeRows(self)
        let n = rows.count
        var flows = _UnitFlows(rows, edgeCount: edgeCount)
        let members = Array(0 ..< n)
        flows.enclose(members)
        var labels = [Int](repeating: -1, count: n), count = 0
        flows.classes(of: members, k: k, labels: &labels, next: &count)
        _ = _relabelByFirstAppearance(&labels, count: count)
        return Components(vertices: _DenseVertices(directedView), labels: labels, count: count)
    }

    /// The k-edge-connected subgraphs: the maximal sets of vertices whose induced subgraph is
    /// k-edge-connected (every pair joined by `k` edge-disjoint paths inside it), ordered as
    /// `connectedComponents()`. They partition the vertices, a vertex in none being a set alone.
    /// Parallel edges are separate paths and self-loops count for nothing. Each set is refined
    /// by `kEdgeConnectedComponents(_:)` of its own induced subgraph until it is one class; at
    /// most n refinements, each O(k n (n + m)). `k = 1` gives the connected components in
    /// O(n + m).
    ///
    /// - Precondition: `k >= 1`.
    @inlinable
    public func kEdgeConnectedSubgraphs(_ k: Int) -> Components<DirectedView<Self>> {
        precondition(k >= 1, "k must be positive")
        if k == 1 { return connectedComponents() }
        let rows = _loopFreeRows(self)
        let n = rows.count
        var flows = _UnitFlows(rows, edgeCount: edgeCount)
        var labels = [Int](repeating: -1, count: n), count = 0
        var scratch = [Int](repeating: -1, count: n), parts = 0
        var work = [Array(0 ..< n)]
        var groups: [[Int]] = []
        while let members = work.popLast() {
            guard members.count > 1 else {
                if let v = members.first {
                    labels[v] = count
                    count += 1
                }
                continue
            }
            flows.enclose(members)
            parts = 0
            flows.classes(of: members, k: k, labels: &scratch, next: &parts)
            if parts == 1 {
                for v in members { labels[v] = count }
                count += 1
                continue
            }
            groups = [[Int]](repeating: [], count: parts)
            for v in members { groups[scratch[v]].append(v) }
            work.append(contentsOf: groups)
        }
        _ = _relabelByFirstAppearance(&labels, count: count)
        return Components(vertices: _DenseVertices(directedView), labels: labels, count: count)
    }
}
