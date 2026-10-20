import GraphProtocols
import PriorityQueueModule
import Walks

/// A minimum cycle basis by de Pina's algorithm, as vertex and edge numbers (uncanonical) with
/// each cycle's weight, in nondecreasing weight, then length, then edge numbers.
///
/// The supports start as the unit vectors of the edges outside a breadth-first spanning forest, one
/// per dimension of the cycle space. For each support S in turn, the lightest cycle with an odd
/// number of edges in S joins the basis: it is the lightest closed walk from (u, 0) to (u, 1) in
/// the graph lifted to two copies of each vertex, an edge in S crossing between the copies, over
/// one end u of each edge in S; with positive weights that walk is a simple cycle. Every later
/// support with an odd overlap with the cycle is then replaced by its symmetric difference with
/// the support, so it stays orthogonal to the cycles chosen so far.
///
/// `weights` nil means every edge weighs 1 (searches are breadth-first); otherwise Dijkstra over
/// the weights, each finite and greater than zero.
@inlinable
func _minimumCycleBasis(_ rows: _CycleRows, edgeCount m: Int, weights: [Double]?) -> [(vertices: [Int], edges: [Int], weight: Double)] {
    let n = rows.count
    // A breadth-first forest: the edges outside it span the cycle space.
    var depth = [Int](repeating: -1, count: n)
    var isTree = [Bool](repeating: false, count: m)
    var endA = [Int](repeating: -1, count: m), endB = [Int](repeating: -1, count: m)
    var queue: [Int] = []
    queue.reserveCapacity(n)
    for root in 0 ..< n where depth[root] < 0 {
        depth[root] = 0
        queue.append(root)
        var head = queue.count - 1
        while head < queue.count {
            let v = queue[head]
            head += 1
            for slot in rows.offsets[v] ..< rows.offsets[v + 1] {
                let w = rows.targets[slot], e = rows.edges[slot]
                if endA[e] < 0 {
                    endA[e] = v
                    endB[e] = w
                }
                if depth[w] < 0 {
                    depth[w] = depth[v] + 1
                    isTree[e] = true
                    queue.append(w)
                }
            }
        }
    }
    var supports: [[Int]] = []
    for e in 0 ..< m where !isTree[e] { supports.append([e]) }
    let dimension = supports.count
    var basis: [(vertices: [Int], edges: [Int], weight: Double)] = []
    basis.reserveCapacity(dimension)
    // The lifted graph's states are 2v + parity. Per-search arrays are reset by stamp.
    var inSupport = [Bool](repeating: false, count: m)
    var stamp = [Int](repeating: 0, count: 2 * n), round = 0
    var distance = [Double](repeating: 0, count: 2 * n)
    var predecessor = [Int](repeating: -1, count: 2 * n), predecessorEdge = [Int](repeating: -1, count: 2 * n)
    var settled = [Bool](repeating: false, count: 2 * n)
    var sourceStamp = [Int](repeating: 0, count: n)
    var frontier: [Int] = []
    var heap = IndexedPriorityQueue<Double>(indexBound: 2 * n)
    for i in 0 ..< dimension {
        let support = supports[i]
        for e in support { inSupport[e] = true }
        var best = Double.infinity
        var bestVertices: [Int] = [], bestEdges: [Int] = []
        // A cycle with an odd overlap passes through an edge of the support, so through its first
        // end: those ends are the only starts needed.
        for e in support {
            let u = endA[e]
            if sourceStamp[u] != i + 1 {
                sourceStamp[u] = i + 1
                // The lightest walk from (u, 0) to (u, 1), stopped once it cannot beat `best`.
                round += 1
                let source = 2 * u, target = 2 * u + 1
                stamp[source] = round
                distance[source] = 0
                predecessor[source] = -1
                var found = false
                if let weights {
                    heap.removeAll(keepingCapacity: true)
                    heap.insert(source, priority: 0)
                    while let (s, d) = heap.popMin() {
                        if d >= best { break }
                        if s == target {
                            found = true
                            break
                        }
                        settled[s] = true
                        let v = s >> 1, parity = s & 1
                        for slot in rows.offsets[v] ..< rows.offsets[v + 1] {
                            let e = rows.edges[slot]
                            let t = 2 * rows.targets[slot] + (inSupport[e] ? parity ^ 1 : parity)
                            let nd = d + weights[e]
                            if stamp[t] != round {
                                stamp[t] = round
                                settled[t] = false
                                distance[t] = nd
                                predecessor[t] = s
                                predecessorEdge[t] = e
                                heap.insert(t, priority: nd)
                            } else if !settled[t], nd < distance[t] {
                                distance[t] = nd
                                predecessor[t] = s
                                predecessorEdge[t] = e
                                heap.decreasePriority(of: t, to: nd)
                            }
                        }
                    }
                } else {
                    frontier.removeAll(keepingCapacity: true)
                    frontier.append(source)
                    var head = 0
                    search: while head < frontier.count {
                        let s = frontier[head]
                        head += 1
                        let d = distance[s]
                        if d + 1 >= best { break }
                        let v = s >> 1, parity = s & 1
                        for slot in rows.offsets[v] ..< rows.offsets[v + 1] {
                            let e = rows.edges[slot]
                            let t = 2 * rows.targets[slot] + (inSupport[e] ? parity ^ 1 : parity)
                            if stamp[t] != round {
                                stamp[t] = round
                                distance[t] = d + 1
                                predecessor[t] = s
                                predecessorEdge[t] = e
                                if t == target {
                                    found = true
                                    break search
                                }
                                frontier.append(t)
                            }
                        }
                    }
                }
                guard found, distance[target] < best else { continue }
                best = distance[target]
                // The walk back from (u, 1) to (u, 0): vertex i leaves through edge i.
                var vertices: [Int] = [], edges: [Int] = []
                var s = target
                while s != source {
                    edges.append(predecessorEdge[s])
                    s = predecessor[s]
                    vertices.append(s >> 1)
                }
                vertices.reverse()
                edges.reverse()
                bestVertices = vertices
                bestEdges = edges
            }
        }
        for e in support { inSupport[e] = false }
        precondition(!bestEdges.isEmpty, "A support has no cycle with an odd overlap")
        basis.append((bestVertices, bestEdges, best))
        // Later supports stay orthogonal to the cycle: one with an odd overlap takes the symmetric
        // difference with this support, which the cycle overlaps oddly.
        let cycle = bestEdges.sorted()
        for j in i + 1 ..< dimension {
            let other = supports[j]
            var overlap = 0
            var a = 0, b = 0
            while a < other.count && b < cycle.count {
                if other[a] == cycle[b] {
                    overlap += 1
                    a += 1
                    b += 1
                } else if other[a] < cycle[b] {
                    a += 1
                } else {
                    b += 1
                }
            }
            guard overlap & 1 == 1 else { continue }
            var merged: [Int] = []
            merged.reserveCapacity(other.count + support.count)
            a = 0
            b = 0
            while a < other.count || b < support.count {
                if b == support.count || (a < other.count && other[a] < support[b]) {
                    merged.append(other[a])
                    a += 1
                } else if a == other.count || support[b] < other[a] {
                    merged.append(support[b])
                    b += 1
                } else {
                    a += 1
                    b += 1
                }
            }
            supports[j] = merged
        }
    }
    basis.sort { x, y in
        if x.weight != y.weight { return x.weight < y.weight }
        if x.edges.count != y.edges.count { return x.edges.count < y.edges.count }
        return x.edges.sorted().lexicographicallyPrecedes(y.edges.sorted())
    }
    return basis
}

extension Graph {
    /// A minimum cycle basis (de Pina 1995): `edgeCount - vertexCount + c` cycles, for c
    /// components, independent over GF(2) and spanning the cycle space, with the fewest edges in
    /// total of any such basis. Self-loops and parallel edges are supported: a loop is a cycle of
    /// its own, and two copies of an edge form a cycle of length 2. Each cycle starts at its least
    /// vertex in `vertices` order and leaves it through the lesser of its two edges there; the
    /// cycles come in nondecreasing length, then by their edge positions. Ties between equally
    /// short cycles are broken by the rows' order.
    ///
    /// - Returns: The cycles of the basis.
    /// - Complexity: O(N (n + m) · k) for N = m − n + c and k the number of search starts, at most
    ///   2m per basis cycle; each search is a breadth-first search on two copies of the graph
    ///   that stops as soon as it cannot beat the shortest cycle found so far.
    @inlinable
    public func minimumCycleBasis() -> [Cycle<Vertex, Edges.Index>] {
        let (rows, positions) = _cycleRows()
        let listed = _listedVertices()
        return _minimumCycleBasis(rows, edgeCount: edgeCount, weights: nil).map { vs, es, _ in
            let (vertices, edges) = _canonicalCycle(vs, es, undirected: true)
            return _cycle(vertices, edges, listed, positions)
        }
    }

    /// A minimum-weight cycle basis (de Pina 1995): `edgeCount - vertexCount + c` cycles, for c
    /// components, independent over GF(2) and spanning the cycle space, of the least total weight
    /// of any such basis. `weight` is called once per edge, in position order. Each cycle starts
    /// at its least vertex in `vertices` order and leaves it through the lesser of its two edges
    /// there; the cycles come in nondecreasing weight, then length, then by their edge positions.
    ///
    /// - Parameter weight: Each edge's weight, finite and greater than zero.
    /// - Returns: The cycles of the basis.
    /// - Complexity: O(N (n + m) log n · k) for N = m − n + c and k the number of search starts,
    ///   at most m per basis cycle; each search is Dijkstra on two copies of the graph that stops
    ///   as soon as it cannot beat the lightest cycle found so far.
    /// - Precondition: every weight is finite and greater than zero.
    @inlinable
    public func minimumCycleBasis<W: BinaryFloatingPoint>(weight: (Edges.Index) -> W) -> [Cycle<Vertex, Edges.Index>] {
        var weights: [Double] = []
        weights.reserveCapacity(edgeCount)
        for position in edges.indices {
            let w = weight(position)
            precondition(w.isFinite && w > 0, "Edge weights must be finite and greater than zero")
            weights.append(Double(w))
        }
        let (rows, positions) = _cycleRows()
        let listed = _listedVertices()
        return _minimumCycleBasis(rows, edgeCount: edgeCount, weights: weights).map { vs, es, _ in
            let (vertices, edges) = _canonicalCycle(vs, es, undirected: true)
            return _cycle(vertices, edges, listed, positions)
        }
    }
}
