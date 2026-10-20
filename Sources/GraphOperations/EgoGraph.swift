import GraphProtocols

/// The renumbering of an ego graph: the vertices within `radius` steps of `center` over `first`
/// and `second` rows, kept in base index order. Both arrays are empty when every vertex is kept,
/// as `_renumbering` gives them. O(n + the rows walked).
@inlinable
func _egoRenumbering<A: Sequence<Int>, B: Sequence<Int>>(
    count n: Int, center: Int, radius: Int, first: (Int) -> A, second: ((Int) -> B)?
) -> (old: [Int], new: [Int], count: Int) {
    _egoRenumbering(count: n, centers: [center], radius: radius, limit: nil, priority: { _ in 0 }, first: first, second: second)
}

/// The renumbering of an ego graph of several centers: the vertices within `radius` steps of any
/// of `centers` over `first` and `second` rows, kept in base index order, at most `limit` of them
/// when given. The centers, then each layer of the breadth-first search, are kept whole while they
/// fit; the layer that would overflow is cut to the vertices of greatest `priority`, ties to the
/// lower base index, and the search stops once the budget is full. Both arrays are empty when every vertex is kept, as
/// `_renumbering` gives them. O(n + the rows walked), plus sorting the cut layer.
@inlinable
func _egoRenumbering<A: Sequence<Int>, B: Sequence<Int>, S: Comparable>(
    count n: Int, centers: [Int], radius: Int, limit: Int?, priority: (Int) -> S, first: (Int) -> A, second: ((Int) -> B)?
) -> (old: [Int], new: [Int], count: Int) {
    precondition(radius >= 0, "The radius must not be negative")
    if let limit { precondition(limit >= 0, "The maximum vertex count must not be negative") }
    var new = [Int](repeating: -1, count: n)
    // The queue grows with the vertices found, so a small ego graph of a large graph costs no
    // O(n) queue on top of the renumbering array.
    var queue: [Int] = []
    for c in centers where new[c] < 0 {
        new[c] = 0
        queue.append(c)
    }
    var head = 0, tail = queue.count, depth = 0, start = 0
    while true {
        // The centers, then each layer, are `queue[start ..< tail]`; one over the budget is cut
        // to the vertices of greatest priority, and the search ends once the budget is full.
        if let limit, tail >= limit {
            if tail > limit {
                let room = limit - start
                var layer = Array(queue[start ..< tail])
                layer.sort { a, b in
                    let pa = priority(a), pb = priority(b)
                    return pa > pb || (pa == pb && a < b)
                }
                for w in layer[room...] { new[w] = -1 }
                tail = start + room
            }
            break
        }
        guard depth < radius, head < tail else { break }
        start = tail
        let end = tail
        while head < end {
            let v = queue[head]
            head &+= 1
            for w in first(v) where new[w] < 0 {
                new[w] = 0
                queue.append(w)
                tail &+= 1
            }
            if let second {
                for w in second(v) where new[w] < 0 {
                    new[w] = 0
                    queue.append(w)
                    tail &+= 1
                }
            }
        }
        depth &+= 1
    }
    if tail == n { return ([], [], n) }
    var old = [Int]()
    old.reserveCapacity(tail)
    for b in 0 ..< n where new[b] >= 0 {
        new[b] = old.count
        old.append(b)
    }
    return (old, new, tail)
}

/// The vertex count of a base that a subgraph view reads in index space.
@inlinable
func _viewBound(_ bound: Int?) -> Int {
    guard let n = bound else {
        preconditionFailure("The base has no vertex indices (vertexIndexBound is nil); a subgraph view needs them")
    }
    return n
}

extension DirectedGraph {
    /// The ego graph of `center`: the subgraph induced on the vertices that a directed path of at
    /// most `radius` arcs reaches from `center`, `center` included, as a lazy view. It is the
    /// `inducedSubgraphView(on:)` of those vertices, numbered and positioned as there.
    ///
    /// - Parameters:
    ///   - center: The vertex the distances are measured from.
    ///   - radius: The greatest distance kept; 0 keeps `center` alone.
    /// - Returns: The view.
    /// - Complexity: O(n + the rows walked), a breadth-first search stopped after `radius` layers,
    ///   with one hash for `center`.
    /// - Precondition: `center` is a vertex, `radius >= 0`, and the graph has vertex indices.
    @inlinable
    public func egoGraphView(of center: Vertex, radius: Int = 1) -> SubgraphView<Self> {
        let n = _viewBound(vertexIndexBound)
        return _egoGraphView(count: n, center: _requiredVertexIndex(of: center, "\(center) is not a vertex of the graph"), radius: radius)
    }

    /// `egoGraphView(of:radius:)`, throwing instead of trapping when `center` is not a vertex.
    ///
    /// - Throws: `VertexNotFound` when `center` is not a vertex.
    @inlinable
    public func egoGraphView(checkedOf center: Vertex, radius: Int = 1) throws(VertexNotFound) -> SubgraphView<Self> {
        let n = _viewBound(vertexIndexBound)
        return _egoGraphView(count: n, center: try vertexIndex(checked: center), radius: radius)
    }

    @inlinable
    func _egoGraphView(count n: Int, center: Int, radius: Int) -> SubgraphView<Self> {
        let (old, new, count) = _egoRenumbering(
            count: n, center: center, radius: radius, first: { successorIndices(ofIndex: $0) },
            second: nil as ((Int) -> EmptyCollection<Int>)?)
        return SubgraphView(
            base: self, old: old, new: new, vertexCount: count, edgeTest: nil, edgeCount: nil,
            rowState: new.isEmpty ? nil : _RowState<Edges.Index>(new: new, test: nil))
    }
    /// The ego graph of several centers: the subgraph induced on the vertices a directed path of at most `radius` arcs reaches from any of `centers`,
    /// the centers included, as a lazy view. It is the `inducedSubgraphView(on:)` of those vertices,
    /// numbered and positioned as there. No centers give an empty view.
    ///
    /// - Parameters:
    ///   - centers: The vertices the distances are measured from.
    ///   - radius: The greatest distance kept; 0 keeps the centers alone.
    /// - Returns: The view.
    /// - Complexity: O(n + the rows walked), a breadth-first search from the centers stopped after
    ///   `radius` layers, with one hash per center.
    /// - Precondition: every center is a vertex, `radius >= 0`, and the graph has vertex indices.
    @inlinable
    public func egoGraphView(of centers: some Sequence<Vertex>, radius: Int = 1) -> SubgraphView<Self> {
        let n = _viewBound(vertexIndexBound)
        return _egoGraphView(count: n, centers: centers.map { _requiredVertexIndex(of: $0, "\($0) is not a vertex of the graph") }, radius: radius, limit: nil, priority: { _ in 0 })
    }

    /// `egoGraphView(of:radius:)` of several centers, throwing instead of trapping when a center is
    /// not a vertex.
    ///
    /// - Throws: `VertexNotFound` when a center is not a vertex.
    @inlinable
    public func egoGraphView(checkedOf centers: some Sequence<Vertex>, radius: Int = 1) throws(VertexNotFound) -> SubgraphView<Self> {
        let n = _viewBound(vertexIndexBound)
        var indices: [Int] = []
        for center in centers { indices.append(try vertexIndex(checked: center)) }
        return _egoGraphView(count: n, centers: indices, radius: radius, limit: nil, priority: { _ in 0 })
    }

    /// The ego graph of several centers, cut to at most `maximumVertexCount` vertices: the centers,
    /// then each layer of the breadth-first search, are kept whole while they fit, and the layer
    /// that would overflow is cut to its vertices of greatest `priority` (ties to the lower vertex
    /// index); nothing beyond that layer is kept. With a cap no layer reaches, this is
    /// `egoGraphView(of:radius:)`.
    ///
    /// - Parameters:
    ///   - centers: The vertices the distances are measured from.
    ///   - radius: The greatest distance kept; 0 keeps the centers alone.
    ///   - maximumVertexCount: The most vertices kept; 0 gives an empty view.
    ///   - priority: Ranks the vertices of the layer that is cut; greater is kept first. Called once
    ///     per vertex of that layer, and not at all when no layer is cut.
    /// - Returns: The view.
    /// - Complexity: O(n + the rows walked), plus sorting the cut layer, with one hash per center.
    /// - Precondition: every center is a vertex, `radius >= 0`, `maximumVertexCount >= 0`, and the
    ///   graph has vertex indices.
    @inlinable
    public func egoGraphView<S: Comparable>(of centers: some Sequence<Vertex>, radius: Int = 1, maximumVertexCount: Int, priority: (Vertex) -> S) -> SubgraphView<Self> {
        let n = _viewBound(vertexIndexBound)
        return _egoGraphView(count: n, centers: centers.map { _requiredVertexIndex(of: $0, "\($0) is not a vertex of the graph") }, radius: radius, limit: maximumVertexCount, priority: { priority(vertex(atIndex: $0)) })
    }

    /// `egoGraphView(of:radius:maximumVertexCount:priority:)`, throwing instead of trapping when a
    /// center is not a vertex.
    ///
    /// - Throws: `VertexNotFound` when a center is not a vertex.
    @inlinable
    public func egoGraphView<S: Comparable>(checkedOf centers: some Sequence<Vertex>, radius: Int = 1, maximumVertexCount: Int, priority: (Vertex) -> S) throws(VertexNotFound) -> SubgraphView<Self> {
        let n = _viewBound(vertexIndexBound)
        var indices: [Int] = []
        for center in centers { indices.append(try vertexIndex(checked: center)) }
        return _egoGraphView(count: n, centers: indices, radius: radius, limit: maximumVertexCount, priority: { priority(vertex(atIndex: $0)) })
    }

    @inlinable
    func _egoGraphView<S: Comparable>(count n: Int, centers: [Int], radius: Int, limit: Int?, priority: (Int) -> S) -> SubgraphView<Self> {
        let (old, new, count) = _egoRenumbering(
            count: n, centers: centers, radius: radius, limit: limit, priority: priority, first: { successorIndices(ofIndex: $0) },
            second: nil as ((Int) -> EmptyCollection<Int>)?)
        return SubgraphView(
            base: self, old: old, new: new, vertexCount: count, edgeTest: nil, edgeCount: nil,
            rowState: new.isEmpty ? nil : _RowState<Edges.Index>(new: new, test: nil))
    }
}

extension BidirectionalDirectedGraph {
    /// The ego graph of `center`, with distances measured along arcs in either direction when
    /// `undirected` is true, as on the underlying undirected graph. The view is the induced
    /// subgraph of this directed graph on those vertices, as `egoGraphView(of:radius:)` gives it.
    ///
    /// - Parameters:
    ///   - center: The vertex the distances are measured from.
    ///   - radius: The greatest distance kept; 0 keeps `center` alone.
    ///   - undirected: Whether a step may follow an arc backwards.
    /// - Returns: The view.
    /// - Complexity: O(n + the rows walked), with one hash for `center`.
    /// - Precondition: `center` is a vertex, `radius >= 0`, and the graph has vertex indices.
    @inlinable
    public func egoGraphView(of center: Vertex, radius: Int = 1, undirected: Bool) -> SubgraphView<Self> {
        let n = _viewBound(vertexIndexBound)
        return _egoGraphView(count: n, center: _requiredVertexIndex(of: center, "\(center) is not a vertex of the graph"), radius: radius, undirected: undirected)
    }

    /// `egoGraphView(of:radius:undirected:)`, throwing instead of trapping when `center` is not a
    /// vertex.
    ///
    /// - Throws: `VertexNotFound` when `center` is not a vertex.
    @inlinable
    public func egoGraphView(checkedOf center: Vertex, radius: Int = 1, undirected: Bool) throws(VertexNotFound) -> SubgraphView<Self> {
        let n = _viewBound(vertexIndexBound)
        return _egoGraphView(count: n, center: try vertexIndex(checked: center), radius: radius, undirected: undirected)
    }

    @inlinable
    func _egoGraphView(count n: Int, center: Int, radius: Int, undirected: Bool) -> SubgraphView<Self> {
        let (old, new, count) = _egoRenumbering(
            count: n, center: center, radius: radius, first: { successorIndices(ofIndex: $0) },
            second: undirected ? { predecessorIndices(ofIndex: $0) } : nil)
        return SubgraphView(
            base: self, old: old, new: new, vertexCount: count, edgeTest: nil, edgeCount: nil,
            rowState: new.isEmpty ? nil : _RowState<Edges.Index>(new: new, test: nil))
    }
    /// The ego graph of several centers: the subgraph induced on the vertices within distance `radius` of any of `centers`, along arcs in either direction when `undirected` is true,
    /// the centers included, as a lazy view. It is the `inducedSubgraphView(on:)` of those vertices,
    /// numbered and positioned as there. No centers give an empty view.
    ///
    /// - Parameters:
    ///   - centers: The vertices the distances are measured from.
    ///   - radius: The greatest distance kept; 0 keeps the centers alone.
    ///   - undirected: Whether a step may follow an arc backwards.
    /// - Returns: The view.
    /// - Complexity: O(n + the rows walked), a breadth-first search from the centers stopped after
    ///   `radius` layers, with one hash per center.
    /// - Precondition: every center is a vertex, `radius >= 0`, and the graph has vertex indices.
    @inlinable
    public func egoGraphView(of centers: some Sequence<Vertex>, radius: Int = 1, undirected: Bool) -> SubgraphView<Self> {
        let n = _viewBound(vertexIndexBound)
        return _egoGraphView(count: n, centers: centers.map { _requiredVertexIndex(of: $0, "\($0) is not a vertex of the graph") }, radius: radius, limit: nil, priority: { _ in 0 }, undirected: undirected)
    }

    /// `egoGraphView(of:radius:undirected:)` of several centers, throwing instead of trapping when a center is
    /// not a vertex.
    ///
    /// - Throws: `VertexNotFound` when a center is not a vertex.
    @inlinable
    public func egoGraphView(checkedOf centers: some Sequence<Vertex>, radius: Int = 1, undirected: Bool) throws(VertexNotFound) -> SubgraphView<Self> {
        let n = _viewBound(vertexIndexBound)
        var indices: [Int] = []
        for center in centers { indices.append(try vertexIndex(checked: center)) }
        return _egoGraphView(count: n, centers: indices, radius: radius, limit: nil, priority: { _ in 0 }, undirected: undirected)
    }

    /// The ego graph of several centers, cut to at most `maximumVertexCount` vertices: the centers,
    /// then each layer of the breadth-first search, are kept whole while they fit, and the layer
    /// that would overflow is cut to its vertices of greatest `priority` (ties to the lower vertex
    /// index); nothing beyond that layer is kept. With a cap no layer reaches, this is
    /// `egoGraphView(of:radius:undirected:)`.
    ///
    /// - Parameters:
    ///   - centers: The vertices the distances are measured from.
    ///   - radius: The greatest distance kept; 0 keeps the centers alone.
    ///   - undirected: Whether a step may follow an arc backwards.
    ///   - maximumVertexCount: The most vertices kept; 0 gives an empty view.
    ///   - priority: Ranks the vertices of the layer that is cut; greater is kept first. Called once
    ///     per vertex of that layer, and not at all when no layer is cut.
    /// - Returns: The view.
    /// - Complexity: O(n + the rows walked), plus sorting the cut layer, with one hash per center.
    /// - Precondition: every center is a vertex, `radius >= 0`, `maximumVertexCount >= 0`, and the
    ///   graph has vertex indices.
    @inlinable
    public func egoGraphView<S: Comparable>(of centers: some Sequence<Vertex>, radius: Int = 1, undirected: Bool, maximumVertexCount: Int, priority: (Vertex) -> S) -> SubgraphView<Self> {
        let n = _viewBound(vertexIndexBound)
        return _egoGraphView(count: n, centers: centers.map { _requiredVertexIndex(of: $0, "\($0) is not a vertex of the graph") }, radius: radius, limit: maximumVertexCount, priority: { priority(vertex(atIndex: $0)) }, undirected: undirected)
    }

    /// `egoGraphView(of:radius:undirected:maximumVertexCount:priority:)`, throwing instead of trapping when a
    /// center is not a vertex.
    ///
    /// - Throws: `VertexNotFound` when a center is not a vertex.
    @inlinable
    public func egoGraphView<S: Comparable>(checkedOf centers: some Sequence<Vertex>, radius: Int = 1, undirected: Bool, maximumVertexCount: Int, priority: (Vertex) -> S) throws(VertexNotFound) -> SubgraphView<Self> {
        let n = _viewBound(vertexIndexBound)
        var indices: [Int] = []
        for center in centers { indices.append(try vertexIndex(checked: center)) }
        return _egoGraphView(count: n, centers: indices, radius: radius, limit: maximumVertexCount, priority: { priority(vertex(atIndex: $0)) }, undirected: undirected)
    }

    @inlinable
    func _egoGraphView<S: Comparable>(count n: Int, centers: [Int], radius: Int, limit: Int?, priority: (Int) -> S, undirected: Bool) -> SubgraphView<Self> {
        let (old, new, count) = _egoRenumbering(
            count: n, centers: centers, radius: radius, limit: limit, priority: priority, first: { successorIndices(ofIndex: $0) },
            second: undirected ? { predecessorIndices(ofIndex: $0) } : nil)
        return SubgraphView(
            base: self, old: old, new: new, vertexCount: count, edgeTest: nil, edgeCount: nil,
            rowState: new.isEmpty ? nil : _RowState<Edges.Index>(new: new, test: nil))
    }
}

extension Graph {
    /// The ego graph of `center`: the subgraph induced on the vertices within distance `radius`
    /// of `center`, `center` included, as a lazy view. It is the `inducedSubgraphView(on:)` of
    /// those vertices, numbered and positioned as there.
    ///
    /// - Parameters:
    ///   - center: The vertex the distances are measured from.
    ///   - radius: The greatest distance kept; 0 keeps `center` alone.
    /// - Returns: The view.
    /// - Complexity: O(n + the rows walked), a breadth-first search stopped after `radius` layers,
    ///   with one hash for `center`.
    /// - Precondition: `center` is a vertex, `radius >= 0`, and the graph has vertex indices.
    @inlinable
    public func egoGraphView(of center: Vertex, radius: Int = 1) -> SubgraphView<Self> {
        let n = _viewBound(vertexIndexBound)
        return _egoGraphView(count: n, center: _requiredVertexIndex(of: center, "\(center) is not a vertex of the graph"), radius: radius)
    }

    /// `egoGraphView(of:radius:)`, throwing instead of trapping when `center` is not a vertex.
    ///
    /// - Throws: `VertexNotFound` when `center` is not a vertex.
    @inlinable
    public func egoGraphView(checkedOf center: Vertex, radius: Int = 1) throws(VertexNotFound) -> SubgraphView<Self> {
        let n = _viewBound(vertexIndexBound)
        return _egoGraphView(count: n, center: try vertexIndex(checked: center), radius: radius)
    }

    @inlinable
    func _egoGraphView(count n: Int, center: Int, radius: Int) -> SubgraphView<Self> {
        let (old, new, count) = _egoRenumbering(
            count: n, center: center, radius: radius, first: { neighborIndices(ofIndex: $0) },
            second: nil as ((Int) -> EmptyCollection<Int>)?)
        return SubgraphView(
            base: self, old: old, new: new, vertexCount: count, edgeTest: nil, edgeCount: nil,
            rowState: new.isEmpty ? nil : _RowState<Edges.Index>(new: new, test: nil))
    }
    /// The ego graph of several centers: the subgraph induced on the vertices within distance `radius` of any of `centers`,
    /// the centers included, as a lazy view. It is the `inducedSubgraphView(on:)` of those vertices,
    /// numbered and positioned as there. No centers give an empty view.
    ///
    /// - Parameters:
    ///   - centers: The vertices the distances are measured from.
    ///   - radius: The greatest distance kept; 0 keeps the centers alone.
    /// - Returns: The view.
    /// - Complexity: O(n + the rows walked), a breadth-first search from the centers stopped after
    ///   `radius` layers, with one hash per center.
    /// - Precondition: every center is a vertex, `radius >= 0`, and the graph has vertex indices.
    @inlinable
    public func egoGraphView(of centers: some Sequence<Vertex>, radius: Int = 1) -> SubgraphView<Self> {
        let n = _viewBound(vertexIndexBound)
        return _egoGraphView(count: n, centers: centers.map { _requiredVertexIndex(of: $0, "\($0) is not a vertex of the graph") }, radius: radius, limit: nil, priority: { _ in 0 })
    }

    /// `egoGraphView(of:radius:)` of several centers, throwing instead of trapping when a center is
    /// not a vertex.
    ///
    /// - Throws: `VertexNotFound` when a center is not a vertex.
    @inlinable
    public func egoGraphView(checkedOf centers: some Sequence<Vertex>, radius: Int = 1) throws(VertexNotFound) -> SubgraphView<Self> {
        let n = _viewBound(vertexIndexBound)
        var indices: [Int] = []
        for center in centers { indices.append(try vertexIndex(checked: center)) }
        return _egoGraphView(count: n, centers: indices, radius: radius, limit: nil, priority: { _ in 0 })
    }

    /// The ego graph of several centers, cut to at most `maximumVertexCount` vertices: the centers,
    /// then each layer of the breadth-first search, are kept whole while they fit, and the layer
    /// that would overflow is cut to its vertices of greatest `priority` (ties to the lower vertex
    /// index); nothing beyond that layer is kept. With a cap no layer reaches, this is
    /// `egoGraphView(of:radius:)`.
    ///
    /// - Parameters:
    ///   - centers: The vertices the distances are measured from.
    ///   - radius: The greatest distance kept; 0 keeps the centers alone.
    ///   - maximumVertexCount: The most vertices kept; 0 gives an empty view.
    ///   - priority: Ranks the vertices of the layer that is cut; greater is kept first. Called once
    ///     per vertex of that layer, and not at all when no layer is cut.
    /// - Returns: The view.
    /// - Complexity: O(n + the rows walked), plus sorting the cut layer, with one hash per center.
    /// - Precondition: every center is a vertex, `radius >= 0`, `maximumVertexCount >= 0`, and the
    ///   graph has vertex indices.
    @inlinable
    public func egoGraphView<S: Comparable>(of centers: some Sequence<Vertex>, radius: Int = 1, maximumVertexCount: Int, priority: (Vertex) -> S) -> SubgraphView<Self> {
        let n = _viewBound(vertexIndexBound)
        return _egoGraphView(count: n, centers: centers.map { _requiredVertexIndex(of: $0, "\($0) is not a vertex of the graph") }, radius: radius, limit: maximumVertexCount, priority: { priority(vertex(atIndex: $0)) })
    }

    /// `egoGraphView(of:radius:maximumVertexCount:priority:)`, throwing instead of trapping when a
    /// center is not a vertex.
    ///
    /// - Throws: `VertexNotFound` when a center is not a vertex.
    @inlinable
    public func egoGraphView<S: Comparable>(checkedOf centers: some Sequence<Vertex>, radius: Int = 1, maximumVertexCount: Int, priority: (Vertex) -> S) throws(VertexNotFound) -> SubgraphView<Self> {
        let n = _viewBound(vertexIndexBound)
        var indices: [Int] = []
        for center in centers { indices.append(try vertexIndex(checked: center)) }
        return _egoGraphView(count: n, centers: indices, radius: radius, limit: maximumVertexCount, priority: { priority(vertex(atIndex: $0)) })
    }

    @inlinable
    func _egoGraphView<S: Comparable>(count n: Int, centers: [Int], radius: Int, limit: Int?, priority: (Int) -> S) -> SubgraphView<Self> {
        let (old, new, count) = _egoRenumbering(
            count: n, centers: centers, radius: radius, limit: limit, priority: priority, first: { neighborIndices(ofIndex: $0) },
            second: nil as ((Int) -> EmptyCollection<Int>)?)
        return SubgraphView(
            base: self, old: old, new: new, vertexCount: count, edgeTest: nil, edgeCount: nil,
            rowState: new.isEmpty ? nil : _RowState<Edges.Index>(new: new, test: nil))
    }
}
