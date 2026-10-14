import GraphProtocols
import Traversal
import Walks

/// The chordality test of Tarjan and Yannakakis on a maximum cardinality search order of the
/// simple graph: the reverse of the order is a perfect elimination ordering exactly when, for
/// every vertex `v`, the neighbors visited before it other than the last of them, `f(v)`, are all
/// neighbors of `f(v)`. O(n + m).
@frozen
@usableFromInline
struct _ChordalTest {
    /// The simple graph's rows.
    @usableFromInline let rows: _CompressedRows
    /// The visit order, and each vertex's place in it.
    @usableFromInline let order: [Int]
    @usableFromInline let position: [Int]
    /// The last-visited neighbor visited before each vertex, or -1, and how many neighbors were
    /// visited before it.
    @usableFromInline let follower: [Int]
    @usableFromInline let earlierCount: [Int]
    /// The first vertex, in visit order, whose test fails: `v` with `x` visited before it and not
    /// a neighbor of `f(v)`.
    @usableFromInline let violation: (v: Int, x: Int, f: Int)?

    @inlinable
    init(_ rows: _CompressedRows) {
        let n = rows.count
        let order = _maximumCardinalityOrder(rows, start: nil)
        var position = [Int](repeating: 0, count: n)
        for (i, v) in order.enumerated() { position[v] = i }
        var follower = [Int](repeating: -1, count: n), earlierCount = [Int](repeating: 0, count: n)
        for v in 0 ..< n {
            for k in rows.offsets[v] ..< rows.offsets[v + 1] {
                let u = rows.targets[k]
                guard position[u] < position[v] else { continue }
                earlierCount[v] += 1
                if follower[v] < 0 || position[u] > position[follower[v]] { follower[v] = u }
            }
        }
        // Each requirement (u must neighbor f(v)), grouped by f(v).
        var start = [Int](repeating: 0, count: n + 1)
        for v in 0 ..< n where follower[v] >= 0 { start[follower[v] + 1] += earlierCount[v] - 1 }
        for x in 0 ..< n { start[x + 1] += start[x] }
        var fill = start
        var required = [Int](repeating: 0, count: start[n]), from = [Int](repeating: 0, count: start[n])
        for v in 0 ..< n where follower[v] >= 0 {
            let f = follower[v]
            for k in rows.offsets[v] ..< rows.offsets[v + 1] {
                let u = rows.targets[k]
                guard u != f, position[u] < position[v] else { continue }
                required[fill[f]] = u
                from[fill[f]] = v
                fill[f] += 1
            }
        }
        var stamp = [Int](repeating: -1, count: n)
        var violation: (v: Int, x: Int, f: Int)?
        for f in 0 ..< n where start[f] < start[f + 1] {
            for k in rows.offsets[f] ..< rows.offsets[f + 1] { stamp[rows.targets[k]] = f }
            for i in start[f] ..< start[f + 1] where stamp[required[i]] != f {
                let v = from[i]
                if violation == nil || position[v] < position[violation!.v] { violation = (v, required[i], f) }
            }
        }
        self.rows = rows
        self.order = order
        self.position = position
        self.follower = follower
        self.earlierCount = earlierCount
        self.violation = violation
    }

    /// A shortest path from `x` to `y` that avoids `v` and every other neighbor of `v`, or nil.
    @inlinable
    func _avoidingPath(around v: Int, from x: Int, to y: Int) -> [Int]? {
        let n = rows.count
        var banned = [Bool](repeating: false, count: n)
        banned[v] = true
        for k in rows.offsets[v] ..< rows.offsets[v + 1] { banned[rows.targets[k]] = true }
        banned[x] = false
        banned[y] = false
        var parent = [Int](repeating: -2, count: n)
        parent[x] = -1
        var queue = [x], head = 0
        while head < queue.count {
            let a = queue[head]
            head += 1
            if a == y { break }
            for k in rows.offsets[a] ..< rows.offsets[a + 1] {
                let b = rows.targets[k]
                guard !banned[b], parent[b] == -2 else { continue }
                parent[b] = a
                queue.append(b)
            }
        }
        guard parent[y] != -2 else { return nil }
        var path = [y]
        while parent[path[path.count - 1]] >= 0 { path.append(parent[path[path.count - 1]]) }
        return path.reversed()
    }

    /// A hole when the graph is not chordal: `v` and a shortest path between two of its
    /// non-adjacent neighbors that avoids its other neighbors. The failed test's own pair first,
    /// then every vertex and pair; some pair has such a path, the two sides of a hole through `v`.
    @inlinable
    func hole() -> [Int]? {
        guard let (v, x, f) = violation else { return nil }
        if let path = _avoidingPath(around: v, from: x, to: f) { return [v] + path }
        let n = rows.count
        var adjacent = [Int](repeating: -1, count: n)
        for v in 0 ..< n {
            let row = rows.offsets[v] ..< rows.offsets[v + 1]
            for i in row {
                let x = rows.targets[i]
                for k in rows.offsets[x] ..< rows.offsets[x + 1] { adjacent[rows.targets[k]] = x }
                for j in i + 1 ..< row.upperBound where adjacent[rows.targets[j]] != x {
                    if let path = _avoidingPath(around: v, from: x, to: rows.targets[j]) { return [v] + path }
                }
            }
        }
        preconditionFailure("A graph that fails the chordality test has a hole")
    }

    /// The maximal cliques: each vertex with its neighbors visited before it, unless a vertex
    /// visited later has exactly those and it as its earlier neighbors. In visit order of the
    /// vertex each is found at, each in increasing vertex order.
    ///
    /// - Precondition: `violation == nil`.
    @inlinable
    func cliques() -> [[Int]] {
        let n = rows.count
        var dominated = [Bool](repeating: false, count: n)
        for w in 0 ..< n where follower[w] >= 0 && earlierCount[w] == earlierCount[follower[w]] + 1 {
            dominated[follower[w]] = true
        }
        var cliques: [[Int]] = []
        for v in order where !dominated[v] {
            var clique = [v]
            for k in rows.offsets[v] ..< rows.offsets[v + 1] where position[rows.targets[k]] < position[v] {
                clique.append(rows.targets[k])
            }
            clique.sort()
            cliques.append(clique)
        }
        return cliques
    }
}

extension Graph {
    @inlinable
    func _chordalTest() -> _ChordalTest { _ChordalTest(_simpleRows()) }

    /// Whether the graph is chordal: every cycle of four or more vertices has a chord (an edge
    /// joining two of its vertices that are not consecutive on it). Read on the simple graph:
    /// self-loops and parallel copies change nothing.
    ///
    /// - Complexity: O(n + m): a maximum cardinality search and Tarjan and Yannakakis's test of
    ///   its reverse as a perfect elimination ordering.
    @inlinable
    public var isChordal: Bool { _chordalTest().violation == nil }

    /// A perfect elimination ordering, or `nil` when the graph is not chordal: an order of the
    /// vertices in which each vertex's neighbors later in the order are all neighbors of one
    /// another. It is the reverse of `maximumCardinalitySearch()`.
    ///
    /// - Complexity: O(n + m).
    @inlinable
    public func perfectEliminationOrdering() -> [Vertex]? {
        let test = _chordalTest()
        guard test.violation == nil else { return nil }
        let listed = _listedVertices()
        return test.order.reversed().map { _vertex(number: $0, listed) }
    }

    /// A hole, or `nil` when the graph is chordal: a chordless cycle of four or more vertices, the
    /// witness that the graph is not chordal. It starts at its least vertex in `vertices` order
    /// and leaves it through the lesser of its two edges there; between two vertices it takes
    /// the first edge in `incidentEdges` order of the earlier one on the cycle.
    ///
    /// - Complexity: O(n + m) to test, then a breadth-first search for the failed test's pair of
    ///   vertices, which finds the hole whenever it lies around them; otherwise one per vertex
    ///   and pair of its non-adjacent neighbors until one does, O(n·Δ²·(n + m)) at most.
    @inlinable
    public func findHole() -> Cycle<Vertex, Edges.Index>? {
        guard var numbers = _chordalTest().hole() else { return nil }
        let least = numbers.indices.min { numbers[$0] < numbers[$1] }!
        numbers = Array(numbers[least...] + numbers[..<least])
        let listed = _listedVertices()
        var vertices = numbers.map { _vertex(number: $0, listed) }
        func edge(_ a: Vertex, _ b: Vertex) -> Edges.Index {
            incidentEdges(of: a).first { oppositeVertex(to: a, acrossEdgeAt: $0) == b }!
        }
        var edges = vertices.indices.map { edge(vertices[$0], vertices[($0 + 1) % vertices.count]) }
        if edges[edges.count - 1] < edges[0] {
            vertices = [vertices[0]] + vertices[1...].reversed()
            edges = vertices.indices.map { edge(vertices[$0], vertices[($0 + 1) % vertices.count]) }
        }
        return Cycle(_uncheckedVertices: vertices, edges: edges)
    }

    /// The maximal cliques of a chordal graph, or `nil` when the graph is not chordal: at most n
    /// of them, each a vertex with its neighbors before it in `maximumCardinalitySearch()`, in
    /// the order of that search, each clique's vertices in `vertices` order. An isolated vertex
    /// is a clique of one.
    ///
    /// - Complexity: O(n + m).
    @inlinable
    public func chordalGraphCliques() -> [[Vertex]]? {
        let test = _chordalTest()
        guard test.violation == nil else { return nil }
        let listed = _listedVertices()
        return test.cliques().map { $0.map { _vertex(number: $0, listed) } }
    }

    /// The treewidth of a chordal graph, one less than its largest clique, or `nil` when the graph
    /// is not chordal; −1 for the empty graph.
    ///
    /// - Complexity: O(n + m).
    @inlinable
    public func chordalGraphTreewidth() -> Int? {
        let test = _chordalTest()
        guard test.violation == nil else { return nil }
        var largest = 0
        for v in 0 ..< test.rows.count { largest = Swift.max(largest, test.earlierCount[v] + 1) }
        return largest - 1
    }
}
