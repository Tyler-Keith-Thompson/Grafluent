import GraphProtocols

// Cut metrics of a vertex set S against its complement T: the cut size, volumes, conductance,
// normalized cut size and the edge, node, boundary and mixing expansions. Each is one pass over
// the edges by their end indices (over the gathered edges for a graph without vertex indices).
// `S` may list a vertex more than once; it counts once.

/// What the cut metrics need from one pass over the edges: the weight crossing between S and its
/// complement T, the volumes of both sides, the total weight, and both sides' sizes.
@frozen
@usableFromInline
struct _CutTally<W: AdditiveArithmetic> {
    /// The weight of the edges with one end in S and the other in T, each direction counted.
    @usableFromInline var cut: W = .zero
    /// The (out-)degree sum of S, a self-loop counting twice in an undirected graph.
    @usableFromInline var volume: W = .zero
    /// The (out-)degree sum of T.
    @usableFromInline var complementVolume: W = .zero
    /// Every edge's weight, self-loops included.
    @usableFromInline var total: W = .zero
    @usableFromInline var size = 0
    @usableFromInline var complementSize = 0

    @inlinable
    init() {}
}

/// Marks the vertex numbers in `s` (duplicates once), trapping on a vertex that is not in the
/// graph.
@inlinable
func _cutSideMarks<Vertex: Hashable>(_ s: some Sequence<Vertex>, count n: Int, _ number: (Vertex) -> Int) -> [Bool] {
    var marks = [Bool](repeating: false, count: n)
    for v in s { marks[number(v)] = true }
    return marks
}

/// The tally over `edges` (by edge number, positions in `edges` order), weighing each edge once.
/// A directed edge adds to the volume of its tail's side; an undirected one to the sides of
/// both ends.
@inlinable
func _cutTally<W: AdditiveArithmetic, Positions: Collection>(
    _ edges: _FlowEdges, _ inSet: [Bool], _ positions: Positions, _ weight: (Positions.Element) -> W
) -> _CutTally<W> {
    var tally = _CutTally<W>()
    _cutSideSizes(&tally, inSet)
    let directed = edges.directed
    edges.tail.withUnsafeBufferPointer { tail in
        edges.head.withUnsafeBufferPointer { head in
            inSet.withUnsafeBufferPointer { inSet in
                var e = 0
                for position in positions {
                    let w = weight(position)
                    tally.total += w
                    let a = inSet[Int(tail[e])], b = inSet[Int(head[e])]
                    if a != b { tally.cut += w }
                    if a { tally.volume += w } else { tally.complementVolume += w }
                    if !directed {
                        if b { tally.volume += w } else { tally.complementVolume += w }
                    }
                    e &+= 1
                }
            }
        }
    }
    return tally
}

/// The number of vertices with an edge from a vertex of the set (undirected: an edge to one), and
/// how many of those lie outside the set.
@inlinable
func _neighborhoodCounts(_ edges: _FlowEdges, _ inSet: [Bool]) -> (neighborhood: Int, boundary: Int) {
    var reached = [Bool](repeating: false, count: inSet.count)
    for e in 0 ..< edges.edgeCount {
        let u = Int(edges.tail[e]), v = Int(edges.head[e])
        if inSet[u] { reached[v] = true }
        if !edges.directed && inSet[v] { reached[u] = true }
    }
    var neighborhood = 0, boundary = 0
    for v in reached.indices where reached[v] {
        neighborhood += 1
        if !inSet[v] { boundary += 1 }
    }
    return (neighborhood, boundary)
}

/// The sizes of S and its complement from the marks.
@inlinable
func _cutSideSizes<W>(_ tally: inout _CutTally<W>, _ inSet: [Bool]) {
    for x in inSet where x { tally.size &+= 1 }
    tally.complementSize = inSet.count - tally.size
}

/// The neighborhood and node boundary of the marked vertices from the vertices they reach.
@inlinable
func _neighborhoodCounts(reached: [Bool], _ inSet: [Bool]) -> (neighborhood: Int, boundary: Int, size: Int) {
    var neighborhood = 0, boundary = 0, size = 0
    for v in reached.indices {
        if inSet[v] { size &+= 1 }
        if reached[v] {
            neighborhood &+= 1
            if !inSet[v] { boundary &+= 1 }
        }
    }
    return (neighborhood, boundary, size)
}

extension DirectedGraph {
    @inlinable
    func _cutTally<W: AdditiveArithmetic>(_ s: some Sequence<Vertex>, _ weight: (Edges.Index) -> W) -> _CutTally<W> {
        if let n = vertexIndexBound {
            let marks = _cutSideMarks(s, count: n) { _requiredVertexIndex(of: $0, "\($0) is not a vertex of the graph") }
            return _indexedCutTally(n, marks, weight)
        }
        let (edges, vertices) = _flowEdges()
        let marks = _cutSideMarks(s, count: edges.vertexCount) { _flowNumber(of: $0, vertices) }
        return Flows._cutTally(edges, marks, self.edges.indices, weight)
    }

    /// The tally straight from the graph, without gathering the edges: over stored compressed
    /// rows when the graph lends them (slot k is position k), otherwise over `edges` in position
    /// order with each edge's end indices. `weight` is called in position order. An edge adds to
    /// the volume of its tail's side.
    @inlinable
    func _indexedCutTally<W: AdditiveArithmetic>(_ n: Int, _ marks: [Bool], _ weight: (Edges.Index) -> W) -> _CutTally<W> {
        var tally = _CutTally<W>()
        _cutSideSizes(&tally, marks)
        marks.withUnsafeBufferPointer { inSet in
            // The same three updates in each loop, written out: a nested function here would
            // capture the tally and box it.
            if Edges.Index.self == Int.self, _withSuccessorIndexRows({ offsets, targets in
                precondition(offsets.count == n + 1 && targets.count == offsets[n], "The rows do not match the edges")
                for u in 0 ..< n {
                    let a = inSet[u]
                    for slot in offsets[u] ..< offsets[u + 1] {
                        let w = weight(unsafeBitCast(slot, to: Edges.Index.self))
                        tally.total += w
                        if a != inSet[targets[slot]] { tally.cut += w }
                        if a { tally.volume += w } else { tally.complementVolume += w }
                    }
                }
                return true
            }) == true { return }
            for position in edges.indices {
                let a = inSet[sourceIndex(ofEdgeAt: position)], b = inSet[targetIndex(ofEdgeAt: position)]
                let w = weight(position)
                tally.total += w
                if a != b { tally.cut += w }
                if a { tally.volume += w } else { tally.complementVolume += w }
            }
        }
        return tally
    }

    @inlinable
    func _neighborhoodCounts(_ s: some Sequence<Vertex>) -> (neighborhood: Int, boundary: Int, size: Int) {
        if let n = vertexIndexBound {
            // Only the rows of the vertices in S are read.
            let marks = _cutSideMarks(s, count: n) { _requiredVertexIndex(of: $0, "\($0) is not a vertex of the graph") }
            var reached = [Bool](repeating: false, count: n)
            for u in 0 ..< n {
                if marks[u] { _forEachSuccessorIndex(ofIndex: u) { reached[$0] = true } }
            }
            return Flows._neighborhoodCounts(reached: reached, marks)
        }
        let (edges, vertices) = _flowEdges()
        let marks = _cutSideMarks(s, count: edges.vertexCount) { _flowNumber(of: $0, vertices) }
        let (neighborhood, boundary) = Flows._neighborhoodCounts(edges, marks)
        return (neighborhood, boundary, marks.lazy.filter { $0 }.count)
    }

    /// The number of edges between `s` and the other vertices, in either direction.
    ///
    /// An edge from `s` out and an edge into `s` both count. Self-loops never cross. A vertex
    /// listed twice in `s` counts once.
    ///
    /// - Complexity: O(n + m).
    /// - Precondition: every element of `s` is a vertex.
    @inlinable
    public func cutSize(of s: some Sequence<Vertex>) -> Int {
        _cutTally(s) { _ in 1 }.cut
    }

    /// The total weight of the edges between `s` and the other vertices, in either direction.
    ///
    /// `weight` is called once per edge, self-loops included, in position order.
    ///
    /// - Complexity: O(n + m).
    /// - Precondition: every element of `s` is a vertex; the sums do not overflow.
    @inlinable
    public func cutSize<W: AdditiveArithmetic>(of s: some Sequence<Vertex>, weight: (Edges.Index) -> W) -> W {
        _cutTally(s, weight).cut
    }

    /// The sum of the out-degrees of the vertices of `s`.
    ///
    /// - Complexity: O(n + m).
    /// - Precondition: every element of `s` is a vertex.
    @inlinable
    public func volume(of s: some Sequence<Vertex>) -> Int {
        _cutTally(s) { _ in 1 }.volume
    }

    /// The total weight of the edges leaving vertices of `s`, self-loops included.
    ///
    /// `weight` is called once per edge in position order.
    ///
    /// - Complexity: O(n + m).
    /// - Precondition: every element of `s` is a vertex; the sums do not overflow.
    @inlinable
    public func volume<W: AdditiveArithmetic>(of s: some Sequence<Vertex>, weight: (Edges.Index) -> W) -> W {
        _cutTally(s, weight).volume
    }

    /// The cut size of `s` over the smaller of the volumes of `s` and of its complement.
    ///
    /// A zero denominator gives infinity, or NaN when the cut is empty too.
    ///
    /// - Complexity: O(n + m).
    /// - Precondition: every element of `s` is a vertex.
    @inlinable
    public func conductance(of s: some Sequence<Vertex>) -> Double {
        let t = _cutTally(s) { _ in 1 }
        return Double(t.cut) / Double(Swift.min(t.volume, t.complementVolume))
    }

    /// The weighted cut size of `s` over the smaller of the weighted volumes of `s` and of its
    /// complement.
    ///
    /// - Complexity: O(n + m).
    /// - Precondition: every element of `s` is a vertex.
    @inlinable
    public func conductance<W: FloatingPoint>(of s: some Sequence<Vertex>, weight: (Edges.Index) -> W) -> W {
        let t = _cutTally(s, weight)
        return t.cut / Swift.min(t.volume, t.complementVolume)
    }

    /// The cut size of `s` times the sum of the reciprocals of the volumes of `s` and of its
    /// complement.
    ///
    /// A zero volume gives infinity, or NaN when the cut is empty.
    ///
    /// - Complexity: O(n + m).
    /// - Precondition: every element of `s` is a vertex.
    @inlinable
    public func normalizedCutSize(of s: some Sequence<Vertex>) -> Double {
        let t = _cutTally(s) { _ in 1 }
        return Double(t.cut) * (1 / Double(t.volume) + 1 / Double(t.complementVolume))
    }

    /// The weighted cut size of `s` times the sum of the reciprocals of the weighted volumes of
    /// `s` and of its complement.
    ///
    /// - Complexity: O(n + m).
    /// - Precondition: every element of `s` is a vertex.
    @inlinable
    public func normalizedCutSize<W: FloatingPoint>(of s: some Sequence<Vertex>, weight: (Edges.Index) -> W) -> W {
        let t = _cutTally(s, weight)
        return t.cut * (1 / t.volume + 1 / t.complementVolume)
    }

    /// The cut size of `s` over the size of the smaller side, `s` or its complement.
    ///
    /// A side with no vertices gives infinity or NaN.
    ///
    /// - Complexity: O(n + m).
    /// - Precondition: every element of `s` is a vertex.
    @inlinable
    public func edgeExpansion(of s: some Sequence<Vertex>) -> Double {
        let t = _cutTally(s) { _ in 1 }
        return Double(t.cut) / Double(Swift.min(t.size, t.complementSize))
    }

    /// The weighted cut size of `s` over the size of the smaller side.
    ///
    /// - Complexity: O(n + m).
    /// - Precondition: every element of `s` is a vertex.
    @inlinable
    public func edgeExpansion<W: FloatingPoint>(of s: some Sequence<Vertex>, weight: (Edges.Index) -> W) -> W {
        let t = _cutTally(s, weight)
        return t.cut / W(Swift.min(t.size, t.complementSize))
    }

    /// The cut size of `s` over twice the number of edges.
    ///
    /// A graph without edges gives NaN.
    ///
    /// - Complexity: O(n + m).
    /// - Precondition: every element of `s` is a vertex.
    @inlinable
    public func mixingExpansion(of s: some Sequence<Vertex>) -> Double {
        let t = _cutTally(s) { _ in 1 }
        return Double(t.cut) / Double(2 * t.total)
    }

    /// The weighted cut size of `s` over twice the total weight of the edges.
    ///
    /// - Complexity: O(n + m).
    /// - Precondition: every element of `s` is a vertex.
    @inlinable
    public func mixingExpansion<W: FloatingPoint>(of s: some Sequence<Vertex>, weight: (Edges.Index) -> W) -> W {
        let t = _cutTally(s, weight)
        return t.cut / (t.total + t.total)
    }

    /// The number of successors of the vertices of `s`, counted once each and including those in
    /// `s`, over the number of vertices in `s`.
    ///
    /// An empty `s` gives NaN.
    ///
    /// - Complexity: O(n + m).
    /// - Precondition: every element of `s` is a vertex.
    @inlinable
    public func nodeExpansion(of s: some Sequence<Vertex>) -> Double {
        let c = _neighborhoodCounts(s)
        return Double(c.neighborhood) / Double(c.size)
    }

    /// The number of vertices outside `s` with an edge from `s` (the node boundary) over the
    /// number of vertices in `s`.
    ///
    /// An empty `s` gives NaN.
    ///
    /// - Complexity: O(n + m).
    /// - Precondition: every element of `s` is a vertex.
    @inlinable
    public func boundaryExpansion(of s: some Sequence<Vertex>) -> Double {
        let c = _neighborhoodCounts(s)
        return Double(c.boundary) / Double(c.size)
    }
}

extension Graph {
    @inlinable
    func _cutTally<W: AdditiveArithmetic>(_ s: some Sequence<Vertex>, _ weight: (Edges.Index) -> W) -> _CutTally<W> {
        if let n = vertexIndexBound {
            let marks = _cutSideMarks(s, count: n) { _requiredVertexIndex(of: $0, "\($0) is not a vertex of the graph") }
            return _indexedCutTally(n, marks, weight)
        }
        let (edges, vertices) = _flowEdges()
        let marks = _cutSideMarks(s, count: edges.vertexCount) { _flowNumber(of: $0, vertices) }
        return Flows._cutTally(edges, marks, self.edges.indices, weight)
    }

    /// The tally straight from the graph, without gathering the edges: over `edges` in position
    /// order with each edge's end indices. `weight` is called in position order. An edge adds to
    /// the volumes of both ends' sides, so a self-loop adds twice to its vertex's.
    @inlinable
    func _indexedCutTally<W: AdditiveArithmetic>(_ n: Int, _ marks: [Bool], _ weight: (Edges.Index) -> W) -> _CutTally<W> {
        var tally = _CutTally<W>()
        _cutSideSizes(&tally, marks)
        marks.withUnsafeBufferPointer { inSet in
            for position in edges.indices {
                let (u, v) = endpointIndices(ofEdgeAt: position)
                let a = inSet[u], b = inSet[v]
                let w = weight(position)
                tally.total += w
                if a != b { tally.cut += w }
                if a { tally.volume += w } else { tally.complementVolume += w }
                if b { tally.volume += w } else { tally.complementVolume += w }
            }
        }
        return tally
    }

    @inlinable
    func _neighborhoodCounts(_ s: some Sequence<Vertex>) -> (neighborhood: Int, boundary: Int, size: Int) {
        if let n = vertexIndexBound {
            // Only the rows of the vertices in S are read.
            let marks = _cutSideMarks(s, count: n) { _requiredVertexIndex(of: $0, "\($0) is not a vertex of the graph") }
            var reached = [Bool](repeating: false, count: n)
            for u in 0 ..< n {
                if marks[u] { _forEachNeighborIndex(ofIndex: u) { reached[$0] = true } }
            }
            return Flows._neighborhoodCounts(reached: reached, marks)
        }
        let (edges, vertices) = _flowEdges()
        let marks = _cutSideMarks(s, count: edges.vertexCount) { _flowNumber(of: $0, vertices) }
        let (neighborhood, boundary) = Flows._neighborhoodCounts(edges, marks)
        return (neighborhood, boundary, marks.lazy.filter { $0 }.count)
    }

    /// The number of edges with one end in `s` and the other outside it.
    ///
    /// Self-loops never cross. A vertex listed twice in `s` counts once.
    ///
    /// - Complexity: O(n + m).
    /// - Precondition: every element of `s` is a vertex.
    @inlinable
    public func cutSize(of s: some Sequence<Vertex>) -> Int {
        _cutTally(s) { _ in 1 }.cut
    }

    /// The total weight of the edges with one end in `s` and the other outside it.
    ///
    /// `weight` is called once per edge, self-loops included, in position order.
    ///
    /// - Complexity: O(n + m).
    /// - Precondition: every element of `s` is a vertex; the sums do not overflow.
    @inlinable
    public func cutSize<W: AdditiveArithmetic>(of s: some Sequence<Vertex>, weight: (Edges.Index) -> W) -> W {
        _cutTally(s, weight).cut
    }

    /// The sum of the degrees of the vertices of `s`, a self-loop counting 2.
    ///
    /// - Complexity: O(n + m).
    /// - Precondition: every element of `s` is a vertex.
    @inlinable
    public func volume(of s: some Sequence<Vertex>) -> Int {
        _cutTally(s) { _ in 1 }.volume
    }

    /// The sum of the weighted degrees of the vertices of `s`: each edge's weight once per end in
    /// `s`, so a self-loop's twice.
    ///
    /// `weight` is called once per edge in position order.
    ///
    /// - Complexity: O(n + m).
    /// - Precondition: every element of `s` is a vertex; the sums do not overflow.
    @inlinable
    public func volume<W: AdditiveArithmetic>(of s: some Sequence<Vertex>, weight: (Edges.Index) -> W) -> W {
        _cutTally(s, weight).volume
    }

    /// The cut size of `s` over the smaller of the volumes of `s` and of its complement.
    ///
    /// A zero denominator gives infinity, or NaN when the cut is empty too.
    ///
    /// - Complexity: O(n + m).
    /// - Precondition: every element of `s` is a vertex.
    @inlinable
    public func conductance(of s: some Sequence<Vertex>) -> Double {
        let t = _cutTally(s) { _ in 1 }
        return Double(t.cut) / Double(Swift.min(t.volume, t.complementVolume))
    }

    /// The weighted cut size of `s` over the smaller of the weighted volumes of `s` and of its
    /// complement.
    ///
    /// - Complexity: O(n + m).
    /// - Precondition: every element of `s` is a vertex.
    @inlinable
    public func conductance<W: FloatingPoint>(of s: some Sequence<Vertex>, weight: (Edges.Index) -> W) -> W {
        let t = _cutTally(s, weight)
        return t.cut / Swift.min(t.volume, t.complementVolume)
    }

    /// The cut size of `s` times the sum of the reciprocals of the volumes of `s` and of its
    /// complement.
    ///
    /// A zero volume gives infinity, or NaN when the cut is empty.
    ///
    /// - Complexity: O(n + m).
    /// - Precondition: every element of `s` is a vertex.
    @inlinable
    public func normalizedCutSize(of s: some Sequence<Vertex>) -> Double {
        let t = _cutTally(s) { _ in 1 }
        return Double(t.cut) * (1 / Double(t.volume) + 1 / Double(t.complementVolume))
    }

    /// The weighted cut size of `s` times the sum of the reciprocals of the weighted volumes of
    /// `s` and of its complement.
    ///
    /// - Complexity: O(n + m).
    /// - Precondition: every element of `s` is a vertex.
    @inlinable
    public func normalizedCutSize<W: FloatingPoint>(of s: some Sequence<Vertex>, weight: (Edges.Index) -> W) -> W {
        let t = _cutTally(s, weight)
        return t.cut * (1 / t.volume + 1 / t.complementVolume)
    }

    /// The cut size of `s` over the size of the smaller side, `s` or its complement.
    ///
    /// A side with no vertices gives infinity or NaN.
    ///
    /// - Complexity: O(n + m).
    /// - Precondition: every element of `s` is a vertex.
    @inlinable
    public func edgeExpansion(of s: some Sequence<Vertex>) -> Double {
        let t = _cutTally(s) { _ in 1 }
        return Double(t.cut) / Double(Swift.min(t.size, t.complementSize))
    }

    /// The weighted cut size of `s` over the size of the smaller side.
    ///
    /// - Complexity: O(n + m).
    /// - Precondition: every element of `s` is a vertex.
    @inlinable
    public func edgeExpansion<W: FloatingPoint>(of s: some Sequence<Vertex>, weight: (Edges.Index) -> W) -> W {
        let t = _cutTally(s, weight)
        return t.cut / W(Swift.min(t.size, t.complementSize))
    }

    /// The cut size of `s` over twice the number of edges.
    ///
    /// A graph without edges gives NaN.
    ///
    /// - Complexity: O(n + m).
    /// - Precondition: every element of `s` is a vertex.
    @inlinable
    public func mixingExpansion(of s: some Sequence<Vertex>) -> Double {
        let t = _cutTally(s) { _ in 1 }
        return Double(t.cut) / Double(2 * t.total)
    }

    /// The weighted cut size of `s` over twice the total weight of the edges.
    ///
    /// - Complexity: O(n + m).
    /// - Precondition: every element of `s` is a vertex.
    @inlinable
    public func mixingExpansion<W: FloatingPoint>(of s: some Sequence<Vertex>, weight: (Edges.Index) -> W) -> W {
        let t = _cutTally(s, weight)
        return t.cut / (t.total + t.total)
    }

    /// The number of neighbors of the vertices of `s`, counted once each and including those in
    /// `s`, over the number of vertices in `s`.
    ///
    /// An empty `s` gives NaN.
    ///
    /// - Complexity: O(n + m).
    /// - Precondition: every element of `s` is a vertex.
    @inlinable
    public func nodeExpansion(of s: some Sequence<Vertex>) -> Double {
        let c = _neighborhoodCounts(s)
        return Double(c.neighborhood) / Double(c.size)
    }

    /// The number of vertices outside `s` adjacent to a vertex of `s` (the node boundary) over
    /// the number of vertices in `s`.
    ///
    /// An empty `s` gives NaN.
    ///
    /// - Complexity: O(n + m).
    /// - Precondition: every element of `s` is a vertex.
    @inlinable
    public func boundaryExpansion(of s: some Sequence<Vertex>) -> Double {
        let c = _neighborhoodCounts(s)
        return Double(c.boundary) / Double(c.size)
    }
}
