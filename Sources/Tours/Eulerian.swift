import GraphProtocols
import Walks

// MARK: - Hierholzer in index space

/// Hierholzer's walk in its stack form (Hierholzer and Wiener, "Ueber die Möglichkeit, einen
/// Linienzug ohne Wiederholung und ohne Unterbrechung zu umfahren", Mathematische Annalen 6,
/// 1873), pinned: from the top vertex take the first unused edge in its row and push its far end,
/// or, with none left, pop the vertex onto the output. One buffer holds both the stack (from the
/// front) and the output (filled from the back, so the trail comes out forward with no reversal):
/// the stack never reaches past the output, since it holds at most the edges taken minus the
/// vertices popped. `vertices` has room for m + 1 numbers and `edges` for m; returns the first
/// output slot, 0 exactly when the walk used every edge.
@inlinable
func _undirectedHierholzer<Rows: _IncidenceRowSource>(_ rows: inout Rows, count n: Int, edgeCount m: Int, start: Int, vertices: UnsafeMutablePointer<Int>, edges: UnsafeMutablePointer<Int>) -> Int {
    let cursor = UnsafeMutablePointer<Int>.allocate(capacity: n)
    cursor.initialize(repeating: 0, count: n)
    defer { cursor.deallocate() }
    // A self-loop is twice in its row and taken once: the bit stops the second end.
    let used = UnsafeMutablePointer<Bool>.allocate(capacity: m)
    used.initialize(repeating: false, count: m)
    defer { used.deallocate() }
    var top = 0, out = m
    vertices[0] = start
    while top >= 0 {
        let v = vertices[top]
        var k = cursor[v]
        let d = rows.count(v)
        var e = -1
        while k < d {
            let f = rows.edge(v, k)
            if !used[f] {
                e = f
                break
            }
            k &+= 1
        }
        if e >= 0 {
            used[e] = true
            cursor[v] = k &+ 1
            top &+= 1
            vertices[top] = rows.neighbor(v, k)
            edges[top &- 1] = e
        } else {
            cursor[v] = k
            vertices[out] = v
            // The edge that reached v moves to the output; the start has none (and, when the walk
            // missed an edge, out is still positive there).
            if top > 0 { edges[out &- 1] = edges[top &- 1] }
            out &-= 1
            top &-= 1
        }
    }
    return out &+ 1
}

/// The same on out-rows, where the cursor alone consumes each edge (edge numbers are slots).
@inlinable
func _directedHierholzer(_ offsets: UnsafeBufferPointer<Int>, _ targets: UnsafeBufferPointer<Int>, start: Int, vertices: UnsafeMutablePointer<Int>, edges: UnsafeMutablePointer<Int>) -> Int {
    let n = offsets.count - 1, m = targets.count
    let cursor = UnsafeMutablePointer<Int>.allocate(capacity: n)
    cursor.initialize(from: offsets.baseAddress!, count: n)
    defer { cursor.deallocate() }
    var top = 0, out = m
    vertices[0] = start
    while top >= 0 {
        let v = vertices[top]
        let k = cursor[v]
        if k < offsets[v &+ 1] {
            cursor[v] = k &+ 1
            top &+= 1
            vertices[top] = targets[k]
            edges[top &- 1] = k
        } else {
            vertices[out] = v
            if top > 0 { edges[out &- 1] = edges[top &- 1] }
            out &-= 1
            top &-= 1
        }
    }
    return out &+ 1
}

/// Runs a Hierholzer walk into fresh buffers and returns its numbers, or nil when it missed an
/// edge (the edges are not all in one component). `closed` drops the repeated last vertex.
@inlinable
func _collectHierholzer(edgeCount m: Int, closed: Bool, _ walk: (UnsafeMutablePointer<Int>, UnsafeMutablePointer<Int>) -> Int) -> (vertices: [Int], edges: [Int])? {
    let vertices = UnsafeMutablePointer<Int>.allocate(capacity: m + 1)
    defer { vertices.deallocate() }
    let edges = UnsafeMutablePointer<Int>.allocate(capacity: Swift.max(m, 1))
    defer { edges.deallocate() }
    guard walk(vertices, edges) == 0 else { return nil }
    return (Array(UnsafeBufferPointer(start: vertices, count: closed ? m : m + 1)), Array(UnsafeBufferPointer(start: edges, count: m)))
}

/// What an Eulerian entry point asks for.
@frozen
@usableFromInline
enum _EulerianRequest: Sendable {
    case status
    case circuit
    case trail
}

/// The answer: the two facts (for `.status`), or the walk's numbers.
@frozen
@usableFromInline
struct _EulerianAnswer: Sendable {
    @usableFromInline var isEulerian = false
    @usableFromInline var hasTrail = false
    @usableFromInline var walk: (vertices: [Int], edges: [Int])?

    @inlinable
    init() {}
}

/// The degree facts the rules need: the vertices with edges, the first of them, and the vertex a
/// trail of a non-Eulerian graph must start at (the first odd one; the one with out − in = 1),
/// or `shape` −1 when the degrees allow no trail, 0 when they allow a circuit, 1 a trail only.
@frozen
@usableFromInline
struct _EulerianDegrees: Sendable {
    @usableFromInline var shape = 0
    @usableFromInline var first = -1
    @usableFromInline var trailStart = -1
    @usableFromInline var withEdges = 0

    @inlinable
    init() {}

    /// The start for the request (−1 for none), given `start` (−1 for the default) and whether it
    /// is the vertex a trail must start at. A balanced graph's walk may start anywhere: from a
    /// vertex without edges it uses none, and with edges present the walk is then nil.
    @inlinable
    func start(_ request: _EulerianRequest, _ start: Int, isTrailStart: Bool) -> Int {
        switch (request, shape) {
        case (_, -1), (.circuit, 1): return -1
        case (_, 0): return start < 0 ? first : start
        default: return start < 0 ? trailStart : (isTrailStart ? start : -1)
        }
    }
}

/// The Eulerian entry points on undirected rows.
@frozen
@usableFromInline
struct _UndirectedEulerian: _UndirectedRowsAlgorithm {
    @usableFromInline let request: _EulerianRequest
    @usableFromInline let start: Int

    @inlinable
    init(_ request: _EulerianRequest, start: Int) {
        self.request = request
        self.start = start
    }

    @inlinable
    var readsEdges: Bool { request != .status }

    @inlinable
    func run<Rows: _IncidenceRowSource>(count n: Int, edgeCount m: Int, _ rows: inout Rows) -> _EulerianAnswer {
        var answer = _EulerianAnswer()
        if m == 0 {
            answer.isEulerian = true
            answer.hasTrail = true
            if request == .trail, n > 0 { answer.walk = ([Swift.max(start, 0)], []) }
            return answer
        }
        var degrees = _EulerianDegrees()
        var odd = 0
        for v in 0 ..< n {
            let d = rows.count(v)
            if d > 0 {
                degrees.withEdges &+= 1
                if degrees.first < 0 { degrees.first = v }
            }
            if d & 1 != 0 {
                odd &+= 1
                if degrees.trailStart < 0 { degrees.trailStart = v }
            }
        }
        degrees.shape = odd == 0 ? 0 : odd == 2 ? 1 : -1
        if request == .status {
            guard degrees.shape >= 0 else { return answer }
            let connected = _undirectedReach(&rows, count: n, from: degrees.first) == degrees.withEdges
            answer.isEulerian = connected && degrees.shape == 0
            answer.hasTrail = connected
            return answer
        }
        let s = degrees.start(request, start, isTrailStart: start >= 0 && rows.count(start) & 1 != 0)
        guard s >= 0 else { return answer }
        answer.walk = _collectHierholzer(edgeCount: m, closed: request == .circuit) { vertices, edges in
            _undirectedHierholzer(&rows, count: n, edgeCount: m, start: s, vertices: vertices, edges: edges)
        }
        return answer
    }
}

/// The number of vertices reached from `start` (included) through the rows.
@inlinable
func _undirectedReach<Rows: _IncidenceRowSource>(_ rows: inout Rows, count n: Int, from start: Int) -> Int {
    if Rows.self == _IncidenceRows.self {
        // The representation's own rows: each row walked with one cursor.
        let stored = unsafeBitCast(rows, to: _IncidenceRows.self)
        return _storedReach(stored.neighbors, stored.neighborRows, count: n, from: start)
    }
    let seen = UnsafeMutablePointer<Bool>.allocate(capacity: n)
    seen.initialize(repeating: false, count: n)
    defer { seen.deallocate() }
    let stack = UnsafeMutablePointer<Int>.allocate(capacity: n)
    defer { stack.deallocate() }
    seen[start] = true
    stack[0] = start
    var top = 1, reached = 1
    while top > 0 {
        top &-= 1
        let v = stack[top]
        let d = rows.count(v)
        for k in 0 ..< d {
            let w = rows.neighbor(v, k)
            precondition(UInt(bitPattern: w) < UInt(bitPattern: n), "A neighbor index is out of range")
            if !seen[w] {
                seen[w] = true
                stack[top] = w
                top &+= 1
                reached &+= 1
            }
        }
    }
    return reached
}

/// `_undirectedReach` on stored rows: row v is `neighbors[rows[3v] ..< rows[3v] + rows[3v + 1]]`.
@inlinable
func _storedReach(_ neighbors: UnsafeBufferPointer<Int>, _ rows: UnsafeBufferPointer<Int>, count n: Int, from start: Int) -> Int {
    let seen = UnsafeMutablePointer<Bool>.allocate(capacity: n)
    seen.initialize(repeating: false, count: n)
    defer { seen.deallocate() }
    let stack = UnsafeMutablePointer<Int>.allocate(capacity: n)
    defer { stack.deallocate() }
    guard let base = neighbors.baseAddress else { return 1 }
    seen[start] = true
    stack[0] = start
    var top = 1, reached = 1
    while top > 0 {
        top &-= 1
        let v = stack[top]
        let first = rows[3 &* v]
        var k = first
        let end = first &+ rows[3 &* v &+ 1]
        while k < end {
            let w = base[k]
            k &+= 1
            precondition(UInt(bitPattern: w) < UInt(bitPattern: n), "A neighbor index is out of range")
            if !seen[w] {
                seen[w] = true
                stack[top] = w
                top &+= 1
                reached &+= 1
            }
        }
    }
    return reached
}

/// The directed degree facts: in-degrees by one pass over the targets.
@inlinable
func _directedEulerianDegrees(_ offsets: UnsafeBufferPointer<Int>, _ targets: UnsafeBufferPointer<Int>) -> _EulerianDegrees {
    let n = offsets.count - 1
    let balance = UnsafeMutablePointer<Int>.allocate(capacity: n)
    defer { balance.deallocate() }
    for v in 0 ..< n { balance[v] = offsets[v &+ 1] &- offsets[v] }
    let hasEdges = UnsafeMutablePointer<Bool>.allocate(capacity: n)
    defer { hasEdges.deallocate() }
    for v in 0 ..< n { hasEdges[v] = balance[v] != 0 }
    for w in targets {
        balance[w] &-= 1
        hasEdges[w] = true
    }
    var degrees = _EulerianDegrees()
    var plus = 0, minus = 0, other = 0
    for v in 0 ..< n {
        if hasEdges[v] {
            degrees.withEdges &+= 1
            if degrees.first < 0 { degrees.first = v }
        }
        switch balance[v] {
        case 0: break
        case 1:
            plus &+= 1
            degrees.trailStart = v
        case -1: minus &+= 1
        default: other &+= 1
        }
    }
    degrees.shape = other == 0 && plus == 0 && minus == 0 ? 0 : other == 0 && plus == 1 && minus == 1 ? 1 : -1
    return degrees
}

/// The number of vertices reached from `start` (included) along the out-rows.
@inlinable
func _directedReach(_ offsets: UnsafeBufferPointer<Int>, _ targets: UnsafeBufferPointer<Int>, from start: Int) -> Int {
    let n = offsets.count - 1
    let seen = UnsafeMutablePointer<Bool>.allocate(capacity: n)
    seen.initialize(repeating: false, count: n)
    defer { seen.deallocate() }
    let stack = UnsafeMutablePointer<Int>.allocate(capacity: n)
    defer { stack.deallocate() }
    seen[start] = true
    stack[0] = start
    var top = 1, reached = 1
    while top > 0 {
        top &-= 1
        let v = stack[top]
        for k in offsets[v] ..< offsets[v &+ 1] {
            let w = targets[k]
            if !seen[w] {
                seen[w] = true
                stack[top] = w
                top &+= 1
                reached &+= 1
            }
        }
    }
    return reached
}

/// The Eulerian entry points on out-rows.
@inlinable
func _directedEulerian(_ offsets: UnsafeBufferPointer<Int>, _ targets: UnsafeBufferPointer<Int>, _ request: _EulerianRequest, start: Int) -> _EulerianAnswer {
    let n = offsets.count - 1, m = targets.count
    var answer = _EulerianAnswer()
    if m == 0 {
        answer.isEulerian = true
        answer.hasTrail = true
        if request == .trail, n > 0 { answer.walk = ([Swift.max(start, 0)], []) }
        return answer
    }
    let degrees = _directedEulerianDegrees(offsets, targets)
    if request == .status {
        guard degrees.shape >= 0 else { return answer }
        // With the degrees balanced (or a trail's), the vertices with edges are weakly connected
        // exactly when all are reachable from the start: the walk the degrees promise.
        let connected = _directedReach(offsets, targets, from: degrees.shape == 0 ? degrees.first : degrees.trailStart) == degrees.withEdges
        answer.isEulerian = connected && degrees.shape == 0
        answer.hasTrail = connected
        return answer
    }
    let s = degrees.start(request, start, isTrailStart: start >= 0 && start == degrees.trailStart)
    guard s >= 0 else { return answer }
    answer.walk = _collectHierholzer(edgeCount: m, closed: request == .circuit) { vertices, edges in
        _directedHierholzer(offsets, targets, start: s, vertices: vertices, edges: edges)
    }
    return answer
}

// MARK: - DirectedGraph

extension DirectedGraph {
    @inlinable
    func _eulerian(_ request: _EulerianRequest, from start: Vertex?) -> (answer: _EulerianAnswer, rows: _DirectedTourRows<Self>) {
        let rows = _directedTourRows(positions: request != .status)
        let s = start.map { _tourNumber(of: $0, rows, "\($0) is not a vertex of the graph") } ?? -1
        return (_withTourRows(rows) { offsets, targets in _directedEulerian(offsets, targets, request, start: s) }, rows)
    }

    @inlinable
    func _circuit(_ request: _EulerianRequest, from start: Vertex?) -> Circuit<Vertex, Edges.Index>? {
        let (answer, rows) = _eulerian(request, from: start)
        guard let walk = answer.walk else { return nil }
        return Circuit(_uncheckedVertices: _tourVertices(walk.vertices, rows), edges: _tourPositions(walk.edges, rows))
    }

    @inlinable
    func _trail(from start: Vertex?) -> Trail<Vertex, Edges.Index>? {
        let (answer, rows) = _eulerian(.trail, from: start)
        guard let walk = answer.walk else { return nil }
        return Trail(_uncheckedVertices: _tourVertices(walk.vertices, rows), edges: _tourPositions(walk.edges, rows))
    }

    /// Whether some closed trail uses every edge exactly once: every vertex has as many edges in
    /// as out (a self-loop is one of each), and the vertices with edges are weakly connected
    /// (which, balanced, makes them strongly connected). Isolated vertices are ignored (igraph's
    /// and JGraphT's rule; NetworkX counts them), and an edgeless graph, the empty graph
    /// included, is Eulerian (igraph `igraph_is_eulerian`'s `has_cycle`).
    ///
    /// - Complexity: O(n + m): the in-degrees, then one search from the first vertex with an edge.
    @inlinable
    public var isEulerian: Bool { _eulerian(.status, from: nil).answer.isEulerian }

    /// Whether some trail uses every edge exactly once (NetworkX `has_eulerian_path`, igraph's
    /// `has_path`): the graph is Eulerian, or exactly one vertex has out − in = 1, one has
    /// in − out = 1, the rest are balanced, and the vertices with edges are weakly connected.
    /// True for every edgeless graph.
    ///
    /// - Complexity: O(n + m).
    @inlinable
    public var hasEulerianTrail: Bool { _eulerian(.status, from: nil).answer.hasTrail }

    /// An Eulerian circuit by Hierholzer's algorithm (Hierholzer and Wiener 1873), from the first
    /// vertex in `vertices` order with an edge; nil when the graph is not Eulerian or has no edges
    /// (a `Circuit` has at least one). Pinned: from the current vertex the first unused edge in
    /// `outEdges` order, in the stack form igraph's `igraph_eulerian_cycle` runs; the circuit is
    /// listed forward from that vertex. On a compressed sparse row the graph's own rows are read.
    ///
    /// - Complexity: O(n + m).
    @inlinable
    public func eulerianCircuit() -> Circuit<Vertex, Edges.Index>? { _circuit(.circuit, from: nil) }

    /// The Eulerian circuit from `start` (NetworkX `eulerian_circuit(G, source=)`): the same
    /// walk; nil also when `start` has no edges.
    ///
    /// - Precondition: `start` is a vertex of the graph.
    /// - Complexity: O(n + m).
    @inlinable
    public func eulerianCircuit(from start: Vertex) -> Circuit<Vertex, Edges.Index>? { _circuit(.circuit, from: start) }

    /// An Eulerian trail (NetworkX `eulerian_path`, igraph `igraph_eulerian_path`), or nil when
    /// there is none or the graph has no vertex. It starts at the vertex with out − in = 1, or,
    /// when the graph is Eulerian, at the first vertex with an edge (the circuit as a closed
    /// trail); it is the trivial trail at the first vertex when there are no edges. Hierholzer's
    /// walk, as `eulerianCircuit()`.
    ///
    /// - Complexity: O(n + m).
    @inlinable
    public func eulerianTrail() -> Trail<Vertex, Edges.Index>? { _trail(from: nil) }

    /// An Eulerian trail from `start`, or nil when none starts there (NetworkX
    /// `has_eulerian_path(G, source)`): `start` must be the vertex with out − in = 1, or, in an
    /// Eulerian graph, any vertex with an edge, or any vertex at all when there are no edges.
    ///
    /// - Precondition: `start` is a vertex of the graph.
    /// - Complexity: O(n + m).
    @inlinable
    public func eulerianTrail(from start: Vertex) -> Trail<Vertex, Edges.Index>? { _trail(from: start) }
}

// MARK: - Graph

extension Graph {
    @inlinable
    func _eulerian(_ request: _EulerianRequest, from start: Vertex?) -> (answer: _EulerianAnswer, numbering: _TourNumbering<Vertex>) {
        let numbering = _tourNumbering()
        let s = start.map { _tourNumber(of: $0, numbering, "\($0) is not a vertex of the graph") } ?? -1
        let answer = _runOnUndirectedRows(_UndirectedEulerian(request, start: s), vertexNumbering: numbering.isIndexed ? nil : (numbering.listed, numbering.numbers))
        return (answer, numbering)
    }

    @inlinable
    func _circuit(from start: Vertex?) -> Circuit<Vertex, Edges.Index>? {
        let (answer, numbering) = _eulerian(.circuit, from: start)
        guard let walk = answer.walk else { return nil }
        return Circuit(_uncheckedVertices: _tourVertices(walk.vertices, numbering), edges: _tourPositions(walk.edges))
    }

    @inlinable
    func _trail(from start: Vertex?) -> Trail<Vertex, Edges.Index>? {
        let (answer, numbering) = _eulerian(.trail, from: start)
        guard let walk = answer.walk else { return nil }
        return Trail(_uncheckedVertices: _tourVertices(walk.vertices, numbering), edges: _tourPositions(walk.edges))
    }

    /// Whether some closed trail uses every edge exactly once: every degree is even (a self-loop
    /// counts 2) and the vertices with edges are connected. Isolated vertices are ignored
    /// (igraph's and JGraphT's rule; NetworkX counts them), and an edgeless graph, the empty
    /// graph included, is Eulerian (igraph `igraph_is_eulerian`'s `has_cycle`).
    ///
    /// - Complexity: O(n + m): the degrees from the rows, then one search when they are even.
    @inlinable
    public var isEulerian: Bool { _eulerian(.status, from: nil).answer.isEulerian }

    /// Whether some trail uses every edge exactly once (NetworkX `has_eulerian_path`, igraph's
    /// `has_path`): no or exactly two odd vertices, and the vertices with edges connected. True
    /// for every edgeless graph.
    ///
    /// - Complexity: O(n + m).
    @inlinable
    public var hasEulerianTrail: Bool { _eulerian(.status, from: nil).answer.hasTrail }

    /// An Eulerian circuit by Hierholzer's algorithm (Hierholzer and Wiener 1873), from the first
    /// vertex in `vertices` order with an edge; nil when the graph is not Eulerian or has no edges
    /// (a `Circuit` has at least one). Pinned: from the current vertex the first unused edge in
    /// `incidentEdges` order (a self-loop, twice in its row, is taken once), in the stack form
    /// igraph's `igraph_eulerian_cycle` runs; the circuit is listed forward from that vertex.
    ///
    /// - Complexity: O(n + m), with a cursor per vertex and a used bit per edge.
    @inlinable
    public func eulerianCircuit() -> Circuit<Vertex, Edges.Index>? { _circuit(from: nil) }

    /// The Eulerian circuit from `start` (NetworkX `eulerian_circuit(G, source=)`): the same
    /// walk; nil also when `start` has no edges.
    ///
    /// - Precondition: `start` is a vertex of the graph.
    /// - Complexity: O(n + m).
    @inlinable
    public func eulerianCircuit(from start: Vertex) -> Circuit<Vertex, Edges.Index>? { _circuit(from: start) }

    /// An Eulerian trail (NetworkX `eulerian_path`, igraph `igraph_eulerian_path`), or nil when
    /// there is none or the graph has no vertex. It starts at the first odd vertex in `vertices`
    /// order, or, when the graph is Eulerian, at the first vertex with an edge (the circuit as a
    /// closed trail); it is the trivial trail at the first vertex when there are no edges.
    /// Hierholzer's walk, as `eulerianCircuit()`.
    ///
    /// - Complexity: O(n + m).
    @inlinable
    public func eulerianTrail() -> Trail<Vertex, Edges.Index>? { _trail(from: nil) }

    /// An Eulerian trail from `start`, or nil when none starts there (NetworkX
    /// `has_eulerian_path(G, source)`): `start` must be one of the two odd vertices, or, in an
    /// Eulerian graph, any vertex with an edge, or any vertex at all when there are no edges.
    ///
    /// - Precondition: `start` is a vertex of the graph.
    /// - Complexity: O(n + m).
    @inlinable
    public func eulerianTrail(from start: Vertex) -> Trail<Vertex, Edges.Index>? { _trail(from: start) }
}
