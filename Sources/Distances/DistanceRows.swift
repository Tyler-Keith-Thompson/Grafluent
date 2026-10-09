import GraphProtocols
import PriorityQueueModule

/// A graph's adjacency in index space for repeated searches: vertex `v`'s arcs are slots
/// `offsets[v] ..< offsets[v + 1]` of `targets` and `edges` (the edge's number: its offset in
/// `edges`), in row order, self-loops dropped (they are on no shortest path).
@frozen
@usableFromInline
struct _DistanceRows: Sendable {
    @usableFromInline var offsets: [Int]
    @usableFromInline var targets: [Int]
    @usableFromInline var edges: [Int]
    @usableFromInline let undirected: Bool

    @inlinable
    init(offsets: [Int], targets: [Int], edges: [Int], undirected: Bool) {
        self.offsets = offsets
        self.targets = targets
        self.edges = edges
        self.undirected = undirected
    }

    @inlinable
    var count: Int { offsets.count - 1 }

    @inlinable
    func degree(_ v: Int) -> Int { offsets[v + 1] - offsets[v] }
}

/// Copies an undirected graph's rows, without self-loops.
@frozen
@usableFromInline
struct _CopyDistanceRows: _UndirectedRowsAlgorithm {
    @inlinable
    init() {}

    @inlinable
    func run<Rows: _IncidenceRowSource>(count n: Int, edgeCount: Int, _ rows: inout Rows) -> _DistanceRows {
        var offsets = [Int](repeating: 0, count: n + 1)
        var targets: [Int] = [], edges: [Int] = []
        targets.reserveCapacity(2 * edgeCount)
        edges.reserveCapacity(2 * edgeCount)
        for v in 0 ..< n {
            for k in 0 ..< rows.count(v) {
                let w = rows.neighbor(v, k), e = rows.edge(v, k)
                precondition(UInt(bitPattern: w) < UInt(bitPattern: n) && UInt(bitPattern: e) < UInt(bitPattern: edgeCount), "A neighbor or edge index is out of range")
                if w == v { continue }
                targets.append(w)
                edges.append(e)
            }
            offsets[v + 1] = targets.count
        }
        return _DistanceRows(offsets: offsets, targets: targets, edges: edges, undirected: true)
    }
}

extension Graph {
    @inlinable
    func _distanceRows() -> _DistanceRows { _runOnUndirectedRows(_CopyDistanceRows()) }

    /// Each edge's weight by number (its offset in `edges`), read once in position order and
    /// checked: at least `.zero` and not NaN.
    @inlinable
    func _distanceWeights<W: Comparable & AdditiveArithmetic>(_ weight: (Edges.Index) -> W) -> [W] {
        var weights: [W] = []
        weights.reserveCapacity(edgeCount)
        for position in edges.indices {
            let w = weight(position)
            precondition(w >= .zero && w == w, "Edge weights must be at least zero and not NaN")
            weights.append(w)
        }
        return weights
    }

    /// The vertices by number when the graph has no vertex indices.
    @inlinable
    func _listedVertices() -> [Vertex]? { vertexIndexBound == nil ? Array(vertices) : nil }
}

extension DirectedGraph {
    /// The rows (edge numbers are offsets in `edges`), and the vertices by number when the graph
    /// has no vertex indices.
    @inlinable
    func _distanceRows() -> (rows: _DistanceRows, listed: [Vertex]?) {
        var offsets: [Int] = [0]
        var targets: [Int] = [], edges: [Int] = []
        targets.reserveCapacity(edgeCount)
        edges.reserveCapacity(edgeCount)
        // Edge numbers: the edge index, or the offset in `edges`.
        var numbers: [Edges.Index: Int] = [:]
        if edgeIndexBound == nil {
            numbers.reserveCapacity(edgeCount)
            for (k, position) in self.edges.indices.enumerated() { numbers[position] = k }
        }
        func number(_ position: Edges.Index) -> Int { edgeIndexBound != nil ? edgeIndex(of: position) : numbers[position]! }
        if let n = vertexIndexBound {
            offsets.reserveCapacity(n + 1)
            for v in 0 ..< n {
                var successors = successorIndices(ofIndex: v).makeIterator()
                for position in outEdges(ofIndex: v) {
                    guard let w = successors.next() else { preconditionFailure("successorIndices and outEdges differ in length") }
                    precondition(UInt(bitPattern: w) < UInt(bitPattern: n), "A successor index is out of range")
                    if w == v { continue }
                    targets.append(w)
                    edges.append(number(position))
                }
                precondition(successors.next() == nil, "successorIndices and outEdges differ in length")
                offsets.append(targets.count)
            }
            return (_DistanceRows(offsets: offsets, targets: targets, edges: edges, undirected: false), nil)
        }
        let listed = Array(vertices)
        var vertexNumbers: [Vertex: Int] = [:]
        vertexNumbers.reserveCapacity(listed.count)
        for (i, v) in listed.enumerated() { vertexNumbers[v] = i }
        for (i, v) in listed.enumerated() {
            for position in outEdges(of: v) {
                let w = vertexNumbers[target(ofEdgeAt: position)]!
                if w == i { continue }
                targets.append(w)
                edges.append(number(position))
            }
            offsets.append(targets.count)
        }
        return (_DistanceRows(offsets: offsets, targets: targets, edges: edges, undirected: false), listed)
    }

    @inlinable
    func _distanceWeights<W: Comparable & AdditiveArithmetic>(_ weight: (Edges.Index) -> W) -> [W] {
        var weights: [W] = []
        weights.reserveCapacity(edgeCount)
        for position in edges.indices {
            let w = weight(position)
            precondition(w >= .zero && w == w, "Edge weights must be at least zero and not NaN")
            weights.append(w)
        }
        return weights
    }
}

/// Breadth-first searches over `_DistanceRows`, reusing one queue and distance array.
@frozen
@usableFromInline
struct _BreadthFirstSearches {
    @usableFromInline let rows: _DistanceRows
    @usableFromInline var distance: [Int]
    @usableFromInline var queue: [Int]
    /// The slot each vertex was first reached through, when parents are recorded.
    @usableFromInline var parentSlot: [Int]

    @inlinable
    init(_ rows: _DistanceRows) {
        self.rows = rows
        distance = [Int](repeating: -1, count: rows.count)
        queue = []
        queue.reserveCapacity(rows.count)
        parentSlot = []
    }

    /// One search from `s`: the eccentricity (the last depth reached), whether every vertex was
    /// reached, and the total distance. `distance` holds the depths until the next search.
    @inlinable
    mutating func search(from s: Int, parents: Bool = false) -> (eccentricity: Int, reachedAll: Bool, total: Int) {
        for v in queue { distance[v] = -1 }
        queue.removeAll(keepingCapacity: true)
        if parents, parentSlot.isEmpty { parentSlot = [Int](repeating: -1, count: rows.count) }
        distance[s] = 0
        queue.append(s)
        var head = 0, total = 0
        while head < queue.count {
            let v = queue[head]
            head += 1
            let next = distance[v] + 1
            for slot in rows.offsets[v] ..< rows.offsets[v + 1] {
                let w = rows.targets[slot]
                if distance[w] < 0 {
                    distance[w] = next
                    total += next
                    if parents { parentSlot[w] = slot }
                    queue.append(w)
                }
            }
        }
        return (distance[queue[queue.count - 1]], queue.count == rows.count, total)
    }
}

/// Dijkstra's searches over `_DistanceRows` with weights by edge number, reusing one heap.
@frozen
@usableFromInline
struct _DijkstraSearches<W: Comparable & AdditiveArithmetic> {
    @usableFromInline let rows: _DistanceRows
    @usableFromInline let weights: [W]
    @usableFromInline var distance: [W]
    /// The round in which each vertex was reached; `round` for the current search.
    @usableFromInline var reached: [Int]
    @usableFromInline var round = 0
    @usableFromInline var heap: IndexedPriorityQueue<W>
    @usableFromInline var parentSlot: [Int]

    @inlinable
    init(_ rows: _DistanceRows, weights: [W]) {
        self.rows = rows
        self.weights = weights
        distance = [W](repeating: .zero, count: rows.count)
        reached = [Int](repeating: 0, count: rows.count)
        heap = IndexedPriorityQueue(indexBound: rows.count)
        parentSlot = []
    }

    /// One search from `s`: the eccentricity (the greatest settled distance), how many vertices
    /// were reached, and the total distance. `distance` and `reached` describe it until the next.
    @inlinable
    mutating func search(from s: Int, parents: Bool = false) -> (eccentricity: W, reachedAll: Bool, total: W) {
        round += 1
        if parents, parentSlot.isEmpty { parentSlot = [Int](repeating: -1, count: rows.count) }
        distance[s] = .zero
        reached[s] = round
        heap.insert(s, priority: .zero)
        var settled = 0
        var eccentricity = W.zero, total = W.zero
        while let (v, d) = heap.popMin() {
            settled += 1
            if d > eccentricity { eccentricity = d }
            total += d
            for slot in rows.offsets[v] ..< rows.offsets[v + 1] {
                let w = rows.targets[slot]
                let candidate = d + weights[rows.edges[slot]]
                if reached[w] != round {
                    reached[w] = round
                    distance[w] = candidate
                    if parents { parentSlot[w] = slot }
                    heap.insert(w, priority: candidate)
                } else if candidate < distance[w], heap.contains(w) {
                    distance[w] = candidate
                    if parents { parentSlot[w] = slot }
                    heap.decreasePriority(of: w, to: candidate)
                }
            }
        }
        return (eccentricity, settled == rows.count, total)
    }
}
