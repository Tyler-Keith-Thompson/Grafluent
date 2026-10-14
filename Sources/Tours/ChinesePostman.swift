import Flows
import GraphProtocols
import MatchingModule
import PriorityQueueModule
import Walks

/// A shortest closed walk through every edge at least once: the answer to the Chinese postman
/// problem, returned by `chinesePostmanTour(weight:)`.
///
/// `walk` is closed and takes every edge of the graph, each edge once more for each time it is
/// listed in `duplicatedEdges`. Adding those copies to the graph makes it Eulerian, and `walk` is
/// an Eulerian circuit of the result.
@frozen
public struct PostmanTour<Vertex: Hashable, Edge: Hashable, Weight> {
    /// The closed walk, starting and ending at the first vertex with an edge.
    public let walk: Walk<Vertex, Edge>
    /// The edges the walk takes more than once, in `edges` order, each listed once per extra
    /// traversal. Undirected, an edge is listed at most once.
    public let duplicatedEdges: [Edge]
    /// The walk's length: every edge's weight, plus the weights of `duplicatedEdges`.
    public let weight: Weight

    @inlinable
    init(walk: Walk<Vertex, Edge>, duplicatedEdges: [Edge], weight: Weight) {
        self.walk = walk
        self.duplicatedEdges = duplicatedEdges
        self.weight = weight
    }
}

extension PostmanTour: Equatable where Weight: Equatable {}
extension PostmanTour: Hashable where Weight: Hashable {}
extension PostmanTour: Sendable where Vertex: Sendable, Edge: Sendable, Weight: Sendable {}

extension PostmanTour: CustomStringConvertible {
    /// `weight 7; walk [0, 1, 2, 1, 0]; duplicated [1]`.
    public var description: String {
        "weight \(weight); walk \(walk.vertices); duplicated \(duplicatedEdges)"
    }
}

// MARK: - Undirected, in index space

/// Dijkstra over `rows` (`_MatchingGraph`'s rows: per vertex its neighbors and edge numbers) from
/// `source`, until `target` is settled, or, with `target` −1, until `wanted` of the vertices
/// whose `rank` is at least `lowest` are. `distance` and `parentEdge` hold the settled
/// vertices' values; `stamp[v] == round` marks a vertex reached in this round, so nothing is
/// reset between rounds. A parent is replaced only by a strictly shorter path.
@inlinable
func _postmanDijkstra<W: Comparable & AdditiveArithmetic>(
    _ rows: borrowing _MatchingGraph, _ weights: UnsafeBufferPointer<W>, from source: Int, to target: Int,
    rank: UnsafeBufferPointer<Int>, lowest: Int, wanted: Int,
    queue: inout IndexedPriorityQueue<W>, distance: UnsafeMutableBufferPointer<W>, parentEdge: UnsafeMutableBufferPointer<Int>,
    stamp: UnsafeMutableBufferPointer<Int>, round: Int
) {
    queue.removeAll(keepingCapacity: true)
    queue.insert(source, priority: .zero)
    distance[source] = .zero
    parentEdge[source] = -1
    stamp[source] = round
    var left = wanted
    rows.offsets.withUnsafeBufferPointer { offsets in
        rows.targets.withUnsafeBufferPointer { targets in
            rows.edges.withUnsafeBufferPointer { edges in
                while let (v, d) = queue.popMin() {
                    if target >= 0 {
                        if v == target { return }
                    } else if rank[v] >= lowest {
                        left &-= 1
                        if left == 0 { return }
                    }
                    for k in offsets[v] ..< offsets[v &+ 1] {
                        let w = targets[k], e = edges[k]
                        let candidate = d + weights[e]
                        if stamp[w] != round {
                            stamp[w] = round
                            distance[w] = candidate
                            parentEdge[w] = e
                            queue.insert(w, priority: candidate)
                        } else if candidate < distance[w], queue.contains(w) {
                            distance[w] = candidate
                            parentEdge[w] = e
                            queue.decreasePriority(of: w, to: candidate)
                        }
                    }
                }
            }
        }
    }
}

/// The undirected Chinese postman tour (Edmonds and Johnson, "Matching, Euler tours and the
/// Chinese postman", Mathematical Programming 5, 1973) in index space: edge `e` joins `from[e]`
/// and `to[e]` with weight `weights[e]`. Returns the closed walk's vertex and edge numbers and
/// the duplicated edges (ascending), or nil when there is no edge or the edges are not connected.
///
/// The odd vertices in vertex order; Dijkstra from each to the later ones; the minimum-weight
/// perfect matching on their complete graph (pairs a < b lexicographic) by MatchingModule's
/// blossom algorithm; each matched pair's shortest path (Dijkstra from its first vertex), its
/// edges toggled in a duplicate bit, so an edge on two paths is not duplicated (the two copies
/// would only add weight, and dropping them keeps every degree's parity); Hierholzer from the
/// first vertex with an edge, over the rows of the edges in edge order followed by the duplicates
/// in edge order. `check(k, d)` vets each odd pair's distance for the matching, `k` the number
/// of odd vertices.
@inlinable
func _undirectedPostman<W: SignedNumeric & Comparable>(
    count n: Int, from: [Int], to: [Int], weights: [W], half: (W) -> W, check: (Int, W) -> Void
) -> (vertices: [Int], edges: [Int], duplicated: [Int])? {
    let m = from.count
    guard m > 0 else { return nil }
    let rows = _MatchingGraph(count: n, from: from, to: to)
    var first = -1, withEdges = 0
    var odd: [Int] = []
    var rank = [Int](repeating: -1, count: n)
    for v in 0 ..< n {
        let d = rows.offsets[v + 1] - rows.offsets[v]
        if d > 0 {
            withEdges += 1
            if first < 0 { first = v }
        }
        if d & 1 != 0 {
            rank[v] = odd.count
            odd.append(v)
        }
    }
    var flat = _FlatIncidenceRows(offsets: rows.offsets, targets: rows.targets, edges: rows.edges)
    guard _undirectedReach(&flat, count: n, from: first) == withEdges else { return nil }
    let k = odd.count
    var duplicate = [Bool](repeating: false, count: m)
    if k > 0 {
        var queue = IndexedPriorityQueue<W>(indexBound: n)
        var distance = [W](repeating: .zero, count: n)
        var parentEdge = [Int](repeating: -1, count: n)
        var stamp = [Int](repeating: -1, count: n)
        // The complete graph on the odd vertices, pairs a < b lexicographic, weighed by distance.
        let pairs = k * (k - 1) / 2
        var pairFrom: [Int] = [], pairTo: [Int] = [], pairWeights: [W] = []
        pairFrom.reserveCapacity(pairs)
        pairTo.reserveCapacity(pairs)
        pairWeights.reserveCapacity(pairs)
        weights.withUnsafeBufferPointer { weights in
            rank.withUnsafeBufferPointer { rank in
                distance.withUnsafeMutableBufferPointer { distance in
                    parentEdge.withUnsafeMutableBufferPointer { parentEdge in
                        stamp.withUnsafeMutableBufferPointer { stamp in
                            for a in 0 ..< k - 1 {
                                // Odd vertices a ... k − 1 (a itself, popped first, included).
                                _postmanDijkstra(rows, weights, from: odd[a], to: -1, rank: rank, lowest: a, wanted: k - a, queue: &queue,
                                                 distance: distance, parentEdge: parentEdge, stamp: stamp, round: a)
                                for b in a + 1 ..< k {
                                    let d = distance[odd[b]]
                                    check(k, d)
                                    pairFrom.append(a)
                                    pairTo.append(b)
                                    pairWeights.append(d)
                                }
                            }
                            let mates = _minimumWeightMatchingEdges(_MatchingGraph(count: k, from: pairFrom, to: pairTo), pairWeights, half: half)
                            for p in 0 ..< pairFrom.count where mates[pairFrom[p]] == p {
                                let s = odd[pairFrom[p]], t = odd[pairTo[p]]
                                // Round numbers past the first searches' 0 ..< k − 1.
                                _postmanDijkstra(rows, weights, from: s, to: t, rank: rank, lowest: 0, wanted: 0, queue: &queue,
                                                 distance: distance, parentEdge: parentEdge, stamp: stamp, round: k + p)
                                var v = t
                                while v != s {
                                    let e = parentEdge[v]
                                    duplicate[e].toggle()
                                    v = from[e] == v ? to[e] : from[e]
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    var duplicated: [Int] = []
    for e in 0 ..< m where duplicate[e] { duplicated.append(e) }
    var allFrom = from, allTo = to
    for e in duplicated {
        allFrom.append(from[e])
        allTo.append(to[e])
    }
    let total = allFrom.count
    let multigraph = _MatchingGraph(count: n, from: allFrom, to: allTo)
    var multi = _FlatIncidenceRows(offsets: multigraph.offsets, targets: multigraph.targets, edges: multigraph.edges)
    guard var walk = _collectHierholzer(edgeCount: total, closed: false, { vertices, edges in
        _undirectedHierholzer(&multi, count: n, edgeCount: total, start: first, vertices: vertices, edges: edges)
    }) else { preconditionFailure("The postman multigraph is not Eulerian") }
    for i in 0 ..< walk.edges.count where walk.edges[i] >= m { walk.edges[i] = duplicated[walk.edges[i] - m] }
    return (walk.vertices, walk.edges, duplicated)
}

extension Graph {
    @inlinable
    func _chinesePostmanTour<W: SignedNumeric & Comparable>(
        _ weight: (Edges.Index) -> W, half: (W) -> W, check: (Int, W) -> Void
    ) -> PostmanTour<Vertex, Edges.Index, W>? {
        let numbering = _tourNumbering()
        let n = numbering.isIndexed ? vertexIndexBound! : numbering.listed.count
        let (from, to) = _runOnUndirectedRows(_CopyEdgeEnds(), vertexNumbering: numbering.isIndexed ? nil : (numbering.listed, numbering.numbers))
        var weights: [W] = []
        weights.reserveCapacity(from.count)
        var total = W.zero
        for position in edges.indices {
            let w = weight(position)
            _checkTourWeight(w)
            precondition(w >= .zero, "A weight is negative")
            weights.append(w)
            total += w
        }
        guard let tour = _undirectedPostman(count: n, from: from, to: to, weights: weights, half: half, check: check) else { return nil }
        for e in tour.duplicated { total += weights[e] }
        let walk = Walk(_uncheckedVertices: _tourVertices(tour.vertices, numbering), edges: _tourPositions(tour.edges))
        return PostmanTour(walk: walk, duplicatedEdges: _tourPositions(tour.duplicated), weight: total)
    }

    /// The shortest closed walk through every edge at least once (the Chinese postman problem),
    /// by Edmonds and Johnson's algorithm, or nil when the graph has no edge or its edges are not
    /// all connected. Isolated vertices are ignored.
    ///
    /// The odd-degree vertices are paired by a minimum-weight perfect matching on their shortest
    /// distances (Dijkstra, then `minimumWeightMatching`'s blossom algorithm on their complete
    /// graph, pairs i < j lexicographic in `vertices` order), and each matched pair's shortest
    /// path is duplicated, except an edge on two of the paths. The walk is Hierholzer's, as
    /// `eulerianCircuit()` takes it, from the first vertex with an edge, on the multigraph of the
    /// edges in position order followed by the duplicated ones in position order, each vertex's
    /// row in that order (a self-loop twice). Parallel edges and self-loops are edges to walk. `weight` is called once per edge, in position order, before any work.
    ///
    /// - Parameter weight: The length of the edge at a position.
    /// - Returns: The tour, the edges it duplicates and its weight; nil when there is none.
    /// - Precondition: no weight is negative; the tour's weight fits in `W`. When `W` is a
    ///   `FixedWidthInteger`, with k odd-degree vertices, every distance d between two of them
    ///   satisfies k · (2 · d + 1) ≤ `W.max / 8` (the matching's bound), checked as each distance is
    ///   found.
    /// - Complexity: O(k (n + m) log n) for the searches and O(k³) for the matching, with k the
    ///   number of odd-degree vertices; O(n + m + k²) memory.
    @inlinable
    public func chinesePostmanTour<W: SignedInteger>(weight: (Edges.Index) -> W) -> PostmanTour<Vertex, Edges.Index, W>? {
        var maximum: W?
        if let fixed = W.self as? any FixedWidthInteger.Type { maximum = W(exactly: fixed.max) }
        return _chinesePostmanTour(weight, half: { $0 / 2 }) { k, d in
            guard let maximum else { return }
            // k · (2 · d + 1) ≤ W.max / 8 as d ≤ (⌊(W.max / 8) / k⌋ − 1) / 2, formed without overflow.
            let quotient = W(exactly: k).map { maximum / 8 / $0 } ?? 0
            precondition(quotient > 0 && d <= (quotient - 1) / 2, "A distance is too large for the matching: k · (2 · distance + 1) must be at most W.max / 8")
        }
    }

    /// The Chinese postman tour with floating-point weights, as the integer overload.
    ///
    /// - Precondition: no weight is negative, NaN or infinite; every distance d between two of the
    ///   k odd-degree vertices satisfies k · (2 · d + 1) ≤ `greatestFiniteMagnitude / 8`.
    /// - Complexity: O(k (n + m) log n + k³).
    @inlinable
    public func chinesePostmanTour<W: FloatingPoint>(weight: (Edges.Index) -> W) -> PostmanTour<Vertex, Edges.Index, W>? {
        _chinesePostmanTour(weight, half: { $0 / 2 }) { k, d in
            precondition(d <= (W.greatestFiniteMagnitude / 8 / W(k) - 1) / 2, "A distance is too large for the matching: k · (2 · distance + 1) must be at most greatestFiniteMagnitude / 8")
        }
    }
}

// MARK: - Directed

extension DirectedGraph {
    /// The shortest closed walk along every edge at least once, in its direction (the directed
    /// Chinese postman problem), by minimum-cost flow (Edmonds and Johnson 1973), or nil when the
    /// graph has no edge or the vertices with edges are not strongly connected. Isolated vertices
    /// are ignored.
    ///
    /// Each vertex with more edges in than out sends the difference, at each edge's weight per
    /// copy, to the vertices with more out than in: `minimumCostFlow(supply:capacity:cost:)`
    /// (the network simplex) on the graph, every edge's capacity the total imbalance. An edge's
    /// flow is the number of times it is duplicated. The walk is Hierholzer's on the out-rows,
    /// each vertex's out-edges in position order followed by their copies in position order, from
    /// the first vertex with an edge. Self-loops are walked once and never duplicated. `weight` is
    /// called once per edge, in position order, before any work.
    ///
    /// - Parameter weight: The length of the edge at a position.
    /// - Returns: The tour, the edges it duplicates (each once per extra copy) and its weight; nil
    ///   when there is none.
    /// - Precondition: no weight is negative, and every weight fits in `Int`; the total imbalance
    ///   times the sum of the weights fits in `Int` (the flow's cost bound); the tour's weight
    ///   fits in `W`.
    /// - Complexity: the network simplex on n vertices and m edges, plus O(n + m + the
    ///   duplicates) for the walk.
    @inlinable
    public func chinesePostmanTour<W: SignedInteger>(weight: (Edges.Index) -> W) -> PostmanTour<Vertex, Edges.Index, W>? {
        let numbering = _directedTourNumbering()
        let indexed = numbering.isIndexed
        let n = indexed ? vertexIndexBound! : numbering.listed.count
        let m = edgeCount
        var tail: [Int] = [], head: [Int] = [], weights: [W] = [], positions: [Edges.Index] = []
        tail.reserveCapacity(m)
        head.reserveCapacity(m)
        weights.reserveCapacity(m)
        positions.reserveCapacity(m)
        var supply = [Int](repeating: 0, count: n)
        // The first vertex with an edge: the least tail, which is the least end whenever there is a
        // tour (strongly connected, every vertex with an edge has one out).
        var first = n
        for position in edges.indices {
            let s = indexed ? sourceIndex(ofEdgeAt: position) : numbering.numbers[source(ofEdgeAt: position)]!
            let t = indexed ? targetIndex(ofEdgeAt: position) : numbering.numbers[target(ofEdgeAt: position)]!
            precondition(UInt(bitPattern: s) < UInt(bitPattern: n) && UInt(bitPattern: t) < UInt(bitPattern: n), "A vertex index is out of range")
            let w = weight(position)
            precondition(w >= 0, "A weight is negative")
            tail.append(s)
            head.append(t)
            weights.append(w)
            positions.append(position)
            supply[s] -= 1
            supply[t] += 1
            first = Swift.min(first, s)
        }
        guard !positions.isEmpty else { return nil }
        let count = positions.count
        var imbalance = 0
        for b in supply where b > 0 { imbalance += b }
        var copies = [Int](repeating: 0, count: count)
        if imbalance > 0 {
            let edgeNumbers = edgeIndexBound == nil ? _edgeNumbers() : [:]
            let flow = minimumCostFlow(
                supply: { supply[_vertexNumber(of: $0, indexed ? nil : numbering.numbers, "")] },
                capacity: { _ in imbalance },
                cost: { position -> Int in
                    let e = edgeNumbers.isEmpty ? edgeIndex(of: position) : edgeNumbers[position]!
                    guard let w = Int(exactly: weights[e]) else { preconditionFailure("A weight does not fit in Int") }
                    return w
                })
            guard let flow else { return nil }
            for e in 0 ..< count { copies[e] = flow.flow(ofEdgeAt: positions[e]) }
        }
        // The out-rows: each vertex's edges in edge order, then their copies in edge order.
        var offsets = [Int](repeating: 0, count: n + 1)
        for e in 0 ..< count { offsets[tail[e] + 1] += 1 + copies[e] }
        for v in 0 ..< n { offsets[v + 1] += offsets[v] }
        let total = offsets[n]
        var fill = offsets
        var targets = [Int](repeating: 0, count: total), slotEdge = [Int](repeating: 0, count: total)
        for e in 0 ..< count {
            targets[fill[tail[e]]] = head[e]
            slotEdge[fill[tail[e]]] = e
            fill[tail[e]] += 1
        }
        for e in 0 ..< count {
            for _ in 0 ..< copies[e] {
                targets[fill[tail[e]]] = head[e]
                slotEdge[fill[tail[e]]] = e
                fill[tail[e]] += 1
            }
        }
        let walk = offsets.withUnsafeBufferPointer { offsets in
            targets.withUnsafeBufferPointer { targets in
                _collectHierholzer(edgeCount: total, closed: false) { vertices, edges in
                    _directedHierholzer(offsets, targets, start: first, vertices: vertices, edges: edges)
                }
            }
        }
        guard let walk else { return nil }
        var length = W.zero
        var duplicated: [Edges.Index] = []
        for e in 0 ..< count {
            length += weights[e]
            for _ in 0 ..< copies[e] {
                length += weights[e]
                duplicated.append(positions[e])
            }
        }
        return PostmanTour(walk: Walk(_uncheckedVertices: _tourVertices(walk.vertices, numbering), edges: walk.edges.map { positions[slotEdge[$0]] }),
                           duplicatedEdges: duplicated, weight: length)
    }
}
