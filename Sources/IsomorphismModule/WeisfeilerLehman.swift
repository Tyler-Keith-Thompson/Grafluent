import GraphProtocols

/// Per-vertex Weisfeiler–Leman hashes: each vertex's colour after rounds 1 … `iterations` of colour
/// refinement, as `weisfeilerLehmanSubgraphHashes(iterations:)` returns them (Shervashidze et al.
/// 2011). Equal hashes after a round mean equal colours, within one process.
public struct WeisfeilerLehmanSubgraphHashes<G> {
    @usableFromInline let graph: G
    @usableFromInline let numbers: AnyObject?
    @usableFromInline let count: Int
    /// Vertex-major: `iterations` hashes per vertex index.
    @usableFromInline let storage: [Int]
    /// The number of rounds.
    public let iterations: Int

    @inlinable
    init(graph: G, numbers: AnyObject?, count: Int, storage: [Int], iterations: Int) {
        self.graph = graph
        self.numbers = numbers
        self.count = count
        self.storage = storage
        self.iterations = iterations
    }

    /// The hashes of the vertex with index `index` (position in `vertices` for a graph without
    /// vertex indices), one per round from round 1.
    ///
    /// - Precondition: `index` is in `0..<vertexCount`.
    @inlinable
    public func hashes(ofIndex index: Int) -> ArraySlice<Int> {
        precondition(index >= 0 && index < count, "\(index) is not a vertex index of the graph")
        return storage[index * iterations ..< (index + 1) * iterations]
    }
}

extension WeisfeilerLehmanSubgraphHashes: @unchecked Sendable where G: Sendable {}

extension WeisfeilerLehmanSubgraphHashes where G: Graph {
    /// The hashes of `vertex`, one per round from round 1.
    ///
    /// - Precondition: `vertex` is a vertex of the graph.
    @inlinable
    public func hashes(of vertex: G.Vertex) -> ArraySlice<Int> {
        if let numbers = _numbers(numbers, G.Vertex.self) {
            guard let i = numbers.numbers[vertex] else { preconditionFailure("\(vertex) is not a vertex of the graph") }
            return hashes(ofIndex: i)
        }
        return hashes(ofIndex: graph._requiredVertexIndex(of: vertex, "\(vertex) is not a vertex of the graph"))
    }

    /// The hashes of `vertex`, throwing instead of trapping when it is not a vertex of the graph.
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not a vertex of the graph.
    @inlinable
    public func hashes(checked vertex: G.Vertex) throws(VertexNotFound) -> ArraySlice<Int> {
        guard graph.contains(vertex) else { throw VertexNotFound() }
        return hashes(of: vertex)
    }
}

extension WeisfeilerLehmanSubgraphHashes where G: DirectedGraph {
    /// The hashes of `vertex`, one per round from round 1.
    ///
    /// - Precondition: `vertex` is a vertex of the graph.
    @inlinable
    public func hashes(of vertex: G.Vertex) -> ArraySlice<Int> {
        if let numbers = _numbers(numbers, G.Vertex.self) {
            guard let i = numbers.numbers[vertex] else { preconditionFailure("\(vertex) is not a vertex of the graph") }
            return hashes(ofIndex: i)
        }
        return hashes(ofIndex: graph._requiredVertexIndex(of: vertex, "\(vertex) is not a vertex of the graph"))
    }

    /// The hashes of `vertex`, throwing instead of trapping when it is not a vertex of the graph.
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not a vertex of the graph.
    @inlinable
    public func hashes(checked vertex: G.Vertex) throws(VertexNotFound) -> ArraySlice<Int> {
        guard graph.contains(vertex) else { throw VertexNotFound() }
        return hashes(of: vertex)
    }
}

/// Weisfeiler–Leman colour refinement (Weisfeiler & Leman 1968; the hashing of Shervashidze et
/// al. 2011). Round 0 is the vertex colours (`vertexColors` hash values; 0 for all when empty);
/// round r gives each vertex a `Hasher` value of its colour and the multiset of its out-row's
/// (edge colour, neighbour colour) and, when directed, apart, its in-row's. The graph hash is a
/// `Hasher` value of the vertex count and every round's colour multiset, rounds 0 … `iterations`.
/// With `keepRounds`, also each vertex's colours after rounds 1 … `iterations`, vertex-major.
///
/// A multiset enters a `Hasher` as two sums of keyed 64-bit mixes of its elements (the key drawn
/// from `Hasher`, so per process like every value here): O(1) per element, where sorting each row
/// cost most of the time. Two additive lanes are not collision-resistant: someone who knows the
/// key can build two multisets with equal sums, and under `SWIFT_DETERMINISTIC_HASHING` the key is
/// a fixed constant. The hash is an invariant for telling graphs apart, not a security boundary.
@usableFromInline
func _weisfeilerLehman(_ graph: _IndexGraph, iterations: Int, keepRounds: Bool) -> (hash: Int, rounds: [Int]) {
    precondition(iterations >= 0, "iterations must be at least 0")
    var g = graph
    if g.isDirected { g.buildInRows() }
    let n = g.count
    var seedHasher = Hasher()
    seedHasher.combine(0x5745_4953_4645_494C)
    let seed = UInt64(bitPattern: Int64(seedHasher.finalize()))
    var colors = g.vertexColors.isEmpty ? [Int](repeating: 0, count: n) : g.vertexColors
    var next = [Int](repeating: 0, count: n)
    var rounds = keepRounds ? [Int](repeating: 0, count: n * iterations) : []
    var graphHasher = Hasher()
    graphHasher.combine(n)
    let initial = _multisetHash(colors, seed)
    graphHasher.combine(initial.0)
    graphHasher.combine(initial.1)
    let colored = g.hasEdgeColors
    let directions = g.isDirected ? 2 : 1
    for round in 0 ..< iterations {
        colors.withUnsafeBufferPointer { colors in
            next.withUnsafeMutableBufferPointer { next in
                for direction in 0 ..< directions {
                    let offsets = direction == 0 ? g.outOffsets : g.inOffsets
                    let targets = direction == 0 ? g.outTargets : g.inTargets
                    let edgeColors = direction == 0 ? g.outColors : g.inColors
                    offsets.withUnsafeBufferPointer { offsets in
                        targets.withUnsafeBufferPointer { targets in
                            edgeColors.withUnsafeBufferPointer { edgeColors in
                                for v in 0 ..< n {
                                    var a: UInt64 = 0, b: UInt64 = 0
                                    for k in offsets[v] ..< offsets[v + 1] {
                                        var key = UInt64(bitPattern: Int64(colors[targets[k]]))
                                        if colored { key = _mix(key ^ _mix(UInt64(bitPattern: Int64(edgeColors[k])) &+ seed)) }
                                        a &+= _mix(key ^ seed)
                                        b &+= _mix(key &+ 0x9E37_79B9_7F4A_7C15 ^ seed)
                                    }
                                    var hasher = Hasher()
                                    if direction == 0 {
                                        hasher.combine(colors[v])
                                    } else {
                                        hasher.combine(next[v])
                                    }
                                    hasher.combine(offsets[v + 1] - offsets[v])
                                    hasher.combine(a)
                                    hasher.combine(b)
                                    next[v] = hasher.finalize()
                                }
                            }
                        }
                    }
                }
            }
        }
        swap(&colors, &next)
        if keepRounds {
            for v in 0 ..< n { rounds[v * iterations + round] = colors[v] }
        }
        let multiset = _multisetHash(colors, seed)
        graphHasher.combine(round)
        graphHasher.combine(multiset.0)
        graphHasher.combine(multiset.1)
    }
    return (graphHasher.finalize(), rounds)
}

/// Two sums of keyed mixes of `values`: equal for equal multisets.
func _multisetHash(_ values: [Int], _ seed: UInt64) -> (UInt64, UInt64) {
    var a: UInt64 = 0, b: UInt64 = 0
    for value in values {
        let key = UInt64(bitPattern: Int64(value))
        a &+= _mix(key ^ seed)
        b &+= _mix(key &+ 0x9E37_79B9_7F4A_7C15 ^ seed)
    }
    return (a, b)
}

/// SplitMix64's finalizer.
@inline(__always)
func _mix(_ x: UInt64) -> UInt64 {
    var z = x
    z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
    z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
    return z ^ (z >> 31)
}

extension Graph {
    @inlinable
    func _weisfeilerLehmanGraph(vertexColors: [Int], edgeColors: [Int]) -> (_IndexGraph, _VertexNumbers<Vertex>?) {
        let numbers = _isomorphismNumbers()
        return (_indexGraph(numbers, vertexColors: vertexColors, edgeColors: edgeColors), numbers)
    }

    /// A hash of the graph by Weisfeiler–Leman colour refinement: isomorphic graphs hash equal;
    /// graphs that `iterations` rounds of refinement do not tell apart hash equal too (C6 and two
    /// triangles).
    ///
    /// Round 0 gives every vertex one colour; round r gives a vertex the pair of its colour and the
    /// multiset of its neighbours' colours (a self-loop counts its vertex twice, each parallel edge
    /// once). The hash covers the vertex count and the colour histogram of rounds 0 … `iterations`.
    /// Hash values come from `Hasher`: equal for equal inputs within one process, not across
    /// processes. O(iterations · (n + m)).
    ///
    /// - Precondition: `iterations >= 0`.
    @inlinable
    public func weisfeilerLehmanGraphHash(iterations: Int = 3) -> Int {
        precondition(iterations >= 0, "iterations must be at least 0")
        return _weisfeilerLehman(_weisfeilerLehmanGraph(vertexColors: [], edgeColors: []).0, iterations: iterations, keepRounds: false).hash
    }

    /// `weisfeilerLehmanGraphHash(iterations:)` starting from vertex colours (round 0 is
    /// `vertexColor`, read once per vertex).
    @inlinable
    public func weisfeilerLehmanGraphHash<VertexColor: Hashable>(iterations: Int = 3, vertexColor: (Vertex) -> VertexColor) -> Int {
        precondition(iterations >= 0, "iterations must be at least 0")
        let colors = vertices.map { vertexColor($0).hashValue }
        return _weisfeilerLehman(_weisfeilerLehmanGraph(vertexColors: colors, edgeColors: []).0, iterations: iterations, keepRounds: false).hash
    }

    /// `weisfeilerLehmanGraphHash(iterations:)` with vertex and edge colours: a neighbour counts
    /// with the colour of the edge to it. Each closure is read once per vertex or edge.
    @inlinable
    public func weisfeilerLehmanGraphHash<VertexColor: Hashable, EdgeColor: Hashable>(iterations: Int = 3, vertexColor: (Vertex) -> VertexColor, edgeColor: (Edges.Index) -> EdgeColor) -> Int {
        precondition(iterations >= 0, "iterations must be at least 0")
        let colors = vertices.map { vertexColor($0).hashValue }
        let edgeColors = edges.indices.map { edgeColor($0).hashValue }
        return _weisfeilerLehman(_weisfeilerLehmanGraph(vertexColors: colors, edgeColors: edgeColors).0, iterations: iterations, keepRounds: false).hash
    }

    /// Each vertex's Weisfeiler–Leman colours after rounds 1 … `iterations`, with the rounds of
    /// `weisfeilerLehmanGraphHash`. An isomorphism maps every vertex to one with the same hashes.
    ///
    /// - Precondition: `iterations >= 0`.
    @inlinable
    public func weisfeilerLehmanSubgraphHashes(iterations: Int = 3) -> WeisfeilerLehmanSubgraphHashes<Self> {
        precondition(iterations >= 0, "iterations must be at least 0")
        let (graph, numbers) = _weisfeilerLehmanGraph(vertexColors: [], edgeColors: [])
        return WeisfeilerLehmanSubgraphHashes(graph: self, numbers: numbers, count: graph.count, storage: _weisfeilerLehman(graph, iterations: iterations, keepRounds: true).rounds, iterations: iterations)
    }

    /// `weisfeilerLehmanSubgraphHashes(iterations:)` starting from vertex colours.
    @inlinable
    public func weisfeilerLehmanSubgraphHashes<VertexColor: Hashable>(iterations: Int = 3, vertexColor: (Vertex) -> VertexColor) -> WeisfeilerLehmanSubgraphHashes<Self> {
        precondition(iterations >= 0, "iterations must be at least 0")
        let (graph, numbers) = _weisfeilerLehmanGraph(vertexColors: vertices.map { vertexColor($0).hashValue }, edgeColors: [])
        return WeisfeilerLehmanSubgraphHashes(graph: self, numbers: numbers, count: graph.count, storage: _weisfeilerLehman(graph, iterations: iterations, keepRounds: true).rounds, iterations: iterations)
    }

    /// `weisfeilerLehmanSubgraphHashes(iterations:)` with vertex and edge colours.
    @inlinable
    public func weisfeilerLehmanSubgraphHashes<VertexColor: Hashable, EdgeColor: Hashable>(iterations: Int = 3, vertexColor: (Vertex) -> VertexColor, edgeColor: (Edges.Index) -> EdgeColor) -> WeisfeilerLehmanSubgraphHashes<Self> {
        precondition(iterations >= 0, "iterations must be at least 0")
        let colors = vertices.map { vertexColor($0).hashValue }
        let edgeColors = edges.indices.map { edgeColor($0).hashValue }
        let (graph, numbers) = _weisfeilerLehmanGraph(vertexColors: colors, edgeColors: edgeColors)
        return WeisfeilerLehmanSubgraphHashes(graph: self, numbers: numbers, count: graph.count, storage: _weisfeilerLehman(graph, iterations: iterations, keepRounds: true).rounds, iterations: iterations)
    }
}

extension DirectedGraph {
    @inlinable
    func _weisfeilerLehmanGraph(vertexColors: [Int], edgeColors: [Int]) -> (_IndexGraph, _VertexNumbers<Vertex>?) {
        let numbers = _isomorphismNumbers()
        return (_indexGraph(numbers, vertexColors: vertexColors, edgeColors: edgeColors), numbers)
    }

    /// A hash of the digraph by Weisfeiler–Leman colour refinement: as on `Graph`, with a
    /// vertex's out-neighbours and in-neighbours kept apart. Isomorphic digraphs hash equal.
    /// Hash values come from `Hasher`: equal for equal inputs within one process.
    /// O(iterations · (n + m)).
    ///
    /// - Precondition: `iterations >= 0`.
    @inlinable
    public func weisfeilerLehmanGraphHash(iterations: Int = 3) -> Int {
        precondition(iterations >= 0, "iterations must be at least 0")
        return _weisfeilerLehman(_weisfeilerLehmanGraph(vertexColors: [], edgeColors: []).0, iterations: iterations, keepRounds: false).hash
    }

    /// `weisfeilerLehmanGraphHash(iterations:)` starting from vertex colours.
    @inlinable
    public func weisfeilerLehmanGraphHash<VertexColor: Hashable>(iterations: Int = 3, vertexColor: (Vertex) -> VertexColor) -> Int {
        precondition(iterations >= 0, "iterations must be at least 0")
        let colors = vertices.map { vertexColor($0).hashValue }
        return _weisfeilerLehman(_weisfeilerLehmanGraph(vertexColors: colors, edgeColors: []).0, iterations: iterations, keepRounds: false).hash
    }

    /// `weisfeilerLehmanGraphHash(iterations:)` with vertex and edge colours.
    @inlinable
    public func weisfeilerLehmanGraphHash<VertexColor: Hashable, EdgeColor: Hashable>(iterations: Int = 3, vertexColor: (Vertex) -> VertexColor, edgeColor: (Edges.Index) -> EdgeColor) -> Int {
        precondition(iterations >= 0, "iterations must be at least 0")
        let colors = vertices.map { vertexColor($0).hashValue }
        let edgeColors = edges.indices.map { edgeColor($0).hashValue }
        return _weisfeilerLehman(_weisfeilerLehmanGraph(vertexColors: colors, edgeColors: edgeColors).0, iterations: iterations, keepRounds: false).hash
    }

    /// Each vertex's Weisfeiler–Leman colours after rounds 1 … `iterations`.
    ///
    /// - Precondition: `iterations >= 0`.
    @inlinable
    public func weisfeilerLehmanSubgraphHashes(iterations: Int = 3) -> WeisfeilerLehmanSubgraphHashes<Self> {
        precondition(iterations >= 0, "iterations must be at least 0")
        let (graph, numbers) = _weisfeilerLehmanGraph(vertexColors: [], edgeColors: [])
        return WeisfeilerLehmanSubgraphHashes(graph: self, numbers: numbers, count: graph.count, storage: _weisfeilerLehman(graph, iterations: iterations, keepRounds: true).rounds, iterations: iterations)
    }

    /// `weisfeilerLehmanSubgraphHashes(iterations:)` starting from vertex colours.
    @inlinable
    public func weisfeilerLehmanSubgraphHashes<VertexColor: Hashable>(iterations: Int = 3, vertexColor: (Vertex) -> VertexColor) -> WeisfeilerLehmanSubgraphHashes<Self> {
        precondition(iterations >= 0, "iterations must be at least 0")
        let (graph, numbers) = _weisfeilerLehmanGraph(vertexColors: vertices.map { vertexColor($0).hashValue }, edgeColors: [])
        return WeisfeilerLehmanSubgraphHashes(graph: self, numbers: numbers, count: graph.count, storage: _weisfeilerLehman(graph, iterations: iterations, keepRounds: true).rounds, iterations: iterations)
    }

    /// `weisfeilerLehmanSubgraphHashes(iterations:)` with vertex and edge colours.
    @inlinable
    public func weisfeilerLehmanSubgraphHashes<VertexColor: Hashable, EdgeColor: Hashable>(iterations: Int = 3, vertexColor: (Vertex) -> VertexColor, edgeColor: (Edges.Index) -> EdgeColor) -> WeisfeilerLehmanSubgraphHashes<Self> {
        precondition(iterations >= 0, "iterations must be at least 0")
        let colors = vertices.map { vertexColor($0).hashValue }
        let edgeColors = edges.indices.map { edgeColor($0).hashValue }
        let (graph, numbers) = _weisfeilerLehmanGraph(vertexColors: colors, edgeColors: edgeColors)
        return WeisfeilerLehmanSubgraphHashes(graph: self, numbers: numbers, count: graph.count, storage: _weisfeilerLehman(graph, iterations: iterations, keepRounds: true).rounds, iterations: iterations)
    }
}
