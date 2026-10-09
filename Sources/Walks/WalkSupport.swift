import GraphProtocols

// The rules and the work the five walk types share. A walk is stored as its vertices and the
// positions of the edges between them: for an open walk (Walk, Trail, Path) one more vertex than
// edges, edge i joining vertex i to vertex i + 1; for a closed one (Circuit, Cycle) as many
// vertices as edges, edge i joining vertex i to vertex (i + 1) mod n, the start not repeated.

/// What a walk type promises beyond its shape.
@frozen
@usableFromInline
struct _WalkRules {
    /// Circuit and Cycle: as many vertices as edges, at least one.
    @usableFromInline let closed: Bool
    /// Trail, Path, Circuit, Cycle: no edge position twice.
    @usableFromInline let distinctEdges: Bool
    /// Path, Cycle: no vertex twice.
    @usableFromInline let distinctVertices: Bool

    @inlinable
    init(closed: Bool, distinctEdges: Bool, distinctVertices: Bool) {
        self.closed = closed
        self.distinctEdges = distinctEdges
        self.distinctVertices = distinctVertices
    }

    @usableFromInline static var walk: Self { Self(closed: false, distinctEdges: false, distinctVertices: false) }
    @usableFromInline static var trail: Self { Self(closed: false, distinctEdges: true, distinctVertices: false) }
    // A path repeats no edge in any graph, so the rule costs nothing and lets `Trail(path)` never fail.
    @usableFromInline static var path: Self { Self(closed: false, distinctEdges: true, distinctVertices: true) }
    @usableFromInline static var circuit: Self { Self(closed: true, distinctEdges: true, distinctVertices: false) }
    @usableFromInline static var cycle: Self { Self(closed: true, distinctEdges: true, distinctVertices: true) }

    /// Whether the counts have this kind's shape.
    @inlinable
    func hasShape(vertexCount: Int, edgeCount: Int) -> Bool {
        closed ? vertexCount == edgeCount && vertexCount >= 1 : vertexCount == edgeCount + 1
    }

    /// Whether `vertices` and `edges` (of the right shape) keep the distinctness rules.
    @inlinable
    func holds<Vertex: Hashable, Edge: Hashable>(_ vertices: [Vertex], _ edges: [Edge]) -> Bool {
        if distinctEdges && !_allDistinct(edges) { return false }
        if distinctVertices && !_allDistinct(vertices) { return false }
        return true
    }

    /// The vertex the step at `i` leads to.
    @inlinable
    func next(_ i: Int, of count: Int) -> Int {
        closed && i + 1 == count ? 0 : i + 1
    }
}

/// Whether no element repeats: a pairwise scan for short arrays, which allocates nothing, and a
/// set otherwise.
@inlinable
func _allDistinct<T: Hashable>(_ items: [T]) -> Bool {
    if items.count <= 16 {
        for i in items.indices {
            for j in items.index(after: i) ..< items.endIndex where items[i] == items[j] { return false }
        }
        return true
    }
    return Set(items).count == items.count
}

extension DirectedGraph {
    /// Whether every vertex is one of the graph's and edge i goes from vertex i to the next.
    ///
    /// - Precondition: every edge is a position in `edges`.
    @inlinable
    func _walks(_ vertices: [Vertex], _ edges: [Edges.Index], _ rules: _WalkRules) -> Bool {
        guard vertices.allSatisfy({ contains($0) }) else { return false }
        let all = self.edges
        guard edges.allSatisfy({ all.startIndex <= $0 && $0 < all.endIndex }) else { return false }
        for (i, e) in edges.enumerated() where source(ofEdgeAt: e) != vertices[i] || target(ofEdgeAt: e) != vertices[rules.next(i, of: vertices.count)] {
            return false
        }
        return true
    }

    /// Edges joining the consecutive vertices, each the first in `outEdges` order, unused when
    /// the rules forbid repeats; nil when a pair has none.
    @inlinable
    func _pickEdges(_ vertices: [Vertex], _ rules: _WalkRules) -> [Edges.Index]? {
        guard !vertices.isEmpty, vertices.allSatisfy({ contains($0) }) else { return nil }
        let steps = rules.closed ? vertices.count : vertices.count - 1
        var picked: [Edges.Index] = []
        picked.reserveCapacity(steps)
        var used = Set<Edges.Index>()
        for i in 0 ..< steps {
            let to = vertices[rules.next(i, of: vertices.count)]
            guard let e = outEdges(of: vertices[i]).first(where: { target(ofEdgeAt: $0) == to && (!rules.distinctEdges || !used.contains($0)) }) else { return nil }
            if rules.distinctEdges { used.insert(e) }
            picked.append(e)
        }
        return picked
    }
}

extension Graph {
    /// Whether every vertex is one of the graph's and edge i joins vertex i and the next.
    ///
    /// - Precondition: every edge is a position in `edges`.
    @inlinable
    func _walks(_ vertices: [Vertex], _ edges: [Edges.Index], _ rules: _WalkRules) -> Bool {
        guard vertices.allSatisfy({ contains($0) }) else { return false }
        let all = self.edges
        guard edges.allSatisfy({ all.startIndex <= $0 && $0 < all.endIndex }) else { return false }
        for (i, e) in edges.enumerated() where self.edges[e] != UndirectedEdge(vertices[i], vertices[rules.next(i, of: vertices.count)]) {
            return false
        }
        return true
    }

    /// As `DirectedGraph._pickEdges`, from `incidentEdges` order.
    @inlinable
    func _pickEdges(_ vertices: [Vertex], _ rules: _WalkRules) -> [Edges.Index]? {
        guard !vertices.isEmpty, vertices.allSatisfy({ contains($0) }) else { return nil }
        let steps = rules.closed ? vertices.count : vertices.count - 1
        var picked: [Edges.Index] = []
        picked.reserveCapacity(steps)
        var used = Set<Edges.Index>()
        for i in 0 ..< steps {
            let from = vertices[i], to = vertices[rules.next(i, of: vertices.count)]
            guard let e = incidentEdges(of: from).first(where: { oppositeVertex(to: from, acrossEdgeAt: $0) == to && (!rules.distinctEdges || !used.contains($0)) }) else { return nil }
            if rules.distinctEdges { used.insert(e) }
            picked.append(e)
        }
        return picked
    }
}

/// Whether two closed walks are the same up to rotation: since their edges are distinct, only
/// the rotation that lines up the first edge can match. O(n).
@inlinable
func _equalUpToRotation<Vertex: Equatable, Edge: Equatable>(_ lv: [Vertex], _ le: [Edge], _ rv: [Vertex], _ re: [Edge]) -> Bool {
    let n = lv.count
    guard n == rv.count else { return false }
    guard n > 0, let k = le.firstIndex(of: re[0]) else { return n == 0 }
    for i in 0 ..< n {
        let j = k + i < n ? k + i : k + i - n
        if lv[j] != rv[i] || le[j] != re[i] { return false }
    }
    return true
}

/// A hash invariant under rotation: the count and the wrapping sum of one hash per edge, as
/// `Set`'s hash is invariant under order. Equal values have equal edges, so hashing the edges
/// alone keeps the hash consistent with `==`, at half the cost of hashing each step.
@inlinable
func _hashUpToRotation<Vertex: Hashable, Edge: Hashable>(_ vertices: [Vertex], _ edges: [Edge], into hasher: inout Hasher) {
    hasher.combine(vertices.count)
    var sum: UInt = 0
    for e in edges {
        var step = Hasher()
        step.combine(e)
        sum &+= UInt(bitPattern: step.finalize())
    }
    hasher.combine(sum)
}

/// `[0, 1, 2]`, as `Array` writes it, at most 16 items.
func _describe<Vertex>(_ vertices: [Vertex]) -> String {
    GraphDescription.list(vertices, count: vertices.count) { GraphDescription.vertex($0) }
}

/// `Path(vertices: [0, 1, 2], edges: [3, 5])`.
func _debugDescribe<Vertex, Edge>(_ name: String, _ vertices: [Vertex], _ edges: [Edge]) -> String {
    "\(name)(vertices: \(_describe(vertices)), edges: \(GraphDescription.list(edges, count: edges.count) { String(reflecting: $0) }))"
}

@usableFromInline
enum _WalkCodingKeys: String, CodingKey {
    case vertices, edges
}
